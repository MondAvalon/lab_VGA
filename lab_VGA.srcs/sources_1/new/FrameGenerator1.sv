module FrameGenerator_bak #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
) (
    input ram_clk,
    input clk,
    input frame_clk,
    input rstn,

    //input in-game x, y, priority, color 
    input [1:0] game_state,
    output [ADDR_WIDTH-1:0] render_addr,
    input [15:0] score,
    input [15:0] high_score,
    input [$clog2(H_LENGTH)-1:0] player_x,
    input [$clog2(V_LENGTH)-1:0] player_y,

    // output VGA signal
    input [ADDR_WIDTH-1:0] raddr,
    output [11:0] rdata
);

  wire frame_start;
  wire [11:0] menu_rgb;
  wire [11:0] background_rgb;
  wire [11:0] gameover_rgb;
  wire [11:0] object_rgb;
  wire object_alpha;
  wire [ADDR_WIDTH-1:0] object_addr;
  reg [6:0] object_y;  // 高128
  reg [7:0] object_x;  // 宽256
  reg [1:0] current_score_digit;  // 当前渲染第几位数字(0-3)
  reg [1:0] next_score_digit;  // 下一个要渲染的数字位数
  reg [3:0] digit;  // 当前渲染的数字值(0-9)
  reg vram_we;
  reg [ADDR_WIDTH-1:0] vram_addr;
  reg [11:0] vram_data;
  reg [1:0] player_anime_state = 2'b00;

  // -----------------------------
  // 1. State Definition
  // -----------------------------
  // Game states
  localparam [1:0] GAME_MENU = 2'b00;  // Initial or pause state
  localparam [1:0] GAME_PLAYING = 2'b01;  // Normal gameplay
  localparam [1:0] GAME_OVER = 2'b10;  // Game over state

  typedef enum logic [3:0] {
    S_IDLE = 4'd0,
    S_RENDER_BG,
    S_RENDER_PLAYER,
    S_RENDER_HIGH_SCORE,
    S_RENDER_SCORE,
    S_DONE
  } render_state_t;

  // -----------------------------
  // 2. State Registers
  // -----------------------------
  render_state_t current_state, next_state;

  // -----------------------------
  // 3. Rendering Coordinates
  // -----------------------------
  reg [$clog2(H_LENGTH)-1:0] x;
  reg [$clog2(V_LENGTH)-1:0] y;
  assign render_addr = y * H_LENGTH + x;


  // 这里仅举例示意，实际需要根据游戏对象的坐标等进行计算
  // 例如：score_x_left, score_x_right, player_x_left, player_x_right 等
  localparam [$clog2(H_LENGTH)-1:0] X_MAX = H_LENGTH - 1;
  localparam [$clog2(V_LENGTH)-1:0] Y_MAX = V_LENGTH - 1;
  parameter [7:0] SCORE_POS_X[0:3] = {8'd0, 8'd10, 8'd20, 8'd30};
  parameter SCORE_POS_Y = 0;
  parameter [7:0] SCORE_POS_X_MAX[0:3] = {8'd9, 8'd19, 8'd29, 8'd39};
  parameter SCORE_POS_Y_MAX = 9;
  parameter [7:0] NUM_SPRITE_X[0:9] = {
    8'd0, 8'd10, 8'd20, 8'd30, 8'd40, 8'd50, 8'd60, 8'd70, 8'd80, 8'd90
  };
  parameter NUM_SPRITE_Y = 36;
  parameter [7:0] PLAYER_SPRITE_X[0:2] = {8'd0, 8'd30, 8'd60};
  parameter PLAYER_SPRITE_Y = 0;
  wire player_x_left = player_x - 14;
  wire player_x_right = player_x + 15;
  wire player_y_up = player_y - 17;
  wire player_y_down = player_y + 18;

  // -----------------------------
  // 4. Synchronous State Update
  // -----------------------------
  always @(posedge clk) begin
    if (!rstn) begin
      current_state <= S_IDLE;
    end else begin
      current_state <= next_state;
      current_score_digit <= next_score_digit;
    end
  end

  // -----------------------------
  // 5. Combinational Next-State Logic
  // -----------------------------
  always @(*) begin
    case (current_state)
      S_IDLE: begin
        // 当接收到新一帧的开始信号后，进入绘制背景状态
        if (frame_start) begin
          next_state = S_RENDER_BG;
        end
      end

      S_RENDER_BG: begin
        // 当背景全部渲染完成后，进入绘制分数等其它对象
        if ((x == X_MAX) && (y == Y_MAX)) begin
          // 根据当前游戏状态可选择下一个子状态
          next_state = game_state == GAME_PLAYING ? S_RENDER_SCORE : S_RENDER_HIGH_SCORE;
        end
      end

      S_RENDER_HIGH_SCORE: begin
        if (x == SCORE_POS_X_MAX[current_score_digit] && y == SCORE_POS_Y_MAX) begin
          if (current_score_digit == 3) begin
            next_state = S_DONE;
            next_score_digit = 0;
          end else begin
            next_state = S_RENDER_HIGH_SCORE;
            next_score_digit = current_score_digit + 1;
          end
        end
      end

      S_RENDER_SCORE: begin
        // 例如当分数渲染完毕后，进入绘制玩家、子弹、Boss等其它元素
        if (x == SCORE_POS_X_MAX[current_score_digit] && y == SCORE_POS_Y_MAX) begin
          if (current_score_digit == 3) begin
            next_state = S_RENDER_PLAYER;
            next_score_digit = 0;
          end else begin
            next_state = S_RENDER_SCORE;
            next_score_digit = current_score_digit + 1;
          end
        end
      end

      S_RENDER_PLAYER: begin
        // 当玩家渲染完后，进入完成状态
        if (x == player_x_right && y == player_y_down) begin
          next_state = S_DONE;
        end
      end

      S_DONE: begin
        // 一帧渲染结束，可以回到空闲等待下一帧
        // 或者直接回到 S_IDLE
        next_state = S_IDLE;
      end

      default: next_state = S_IDLE;
    endcase
  end

  // -----------------------------
  // 6. Datapath & Coordinate Control
  // -----------------------------
  always @(posedge clk) begin
    if (!rstn) begin
      x         <= 0;
      y         <= 0;
      vram_we   <= 0;
      vram_addr <= 0;
      vram_data <= 12'h0;
    end else begin
      case (current_state)
        S_IDLE: begin
          // 等待下一次 frame_start
          // 不再写VRAM
          vram_we <= 0;
          x       <= 0;
          y       <= 0;
        end

        S_RENDER_BG: begin
          // 写VRAM，渲染背景
          vram_we <= 1;
          vram_addr <= render_addr;
          // 根据当前状态/坐标计算背景像素
          vram_data <= game_state == GAME_MENU ? menu_rgb : (game_state == GAME_PLAYING ? background_rgb : gameover_rgb);

          // 坐标遍历
          if (x == X_MAX) begin
            if (y == Y_MAX) begin
              x <= SCORE_POS_X[current_score_digit];
              y <= SCORE_POS_Y;
            end else begin
              x <= 0;
              y <= y + 1;
            end
          end else begin
            x <= x + 1;
          end
        end

        S_RENDER_HIGH_SCORE: begin
          // 写VRAM，渲染高分
          vram_we   <= 1;
          vram_addr <= render_addr;
          vram_data <= object_alpha ? object_rgb : vram_data;

          if (x == SCORE_POS_X_MAX[current_score_digit]) begin
            if (y == SCORE_POS_Y_MAX) begin
              x <= SCORE_POS_X[current_score_digit+1];
              y <= SCORE_POS_Y;
            end else begin
              x <= SCORE_POS_X[current_score_digit];
              y <= y + 1;
            end
          end else begin
            x <= x + 1;
          end
        end

        S_RENDER_SCORE: begin
          // 写VRAM，渲染分数
          vram_we <= 1;
          vram_addr <= render_addr;
          vram_data <= object_alpha ? object_rgb : vram_data;

          if (x == SCORE_POS_X_MAX[current_score_digit]) begin
            if (y == SCORE_POS_Y_MAX) begin
              x <= current_score_digit == 3 ? player_x_left : SCORE_POS_X[current_score_digit+1];
              y <= SCORE_POS_Y;
            end else begin
              x <= SCORE_POS_X[current_score_digit];
              y <= y + 1;
            end
          end else begin
            x <= x + 1;
          end
        end

        S_RENDER_PLAYER: begin
          // 写VRAM，渲染玩家
          vram_we <= 1;
          vram_addr <= render_addr;
          // 根据坐标计算玩家图案的像素
          // vram_data <= object_alpha ? object_rgb : vram_data;
          vram_data <= object_rgb;

          // 同样，根据玩家图案大小移动 (x, y)
          if (x == player_x_right) begin
            if (y == player_y_down) begin
              x <= 0;
              y <= 0;
            end else begin
              x <= player_x_left;
              y <= y + 1;
            end
          end else begin
            x <= x + 1;
          end
        end

        S_DONE: begin
          // 一帧渲染结束，停止写VRAM或保持某个状态
          vram_we <= 0;
        end
      endcase
    end
  end



  always @(*) begin
    case (current_score_digit)
      0: digit = current_state == S_RENDER_SCORE ? score[15:12] : high_score[15:12];
      1: digit = current_state == S_RENDER_SCORE ? score[11:8] : high_score[11:8];
      2: digit = current_state == S_RENDER_SCORE ? score[7:4] : high_score[7:4];
      3: digit = current_state == S_RENDER_SCORE ? score[3:0] : high_score[3:0];
    endcase
  end

  always @(*) begin
    if (current_state == S_RENDER_SCORE || current_state == S_RENDER_HIGH_SCORE) begin
      object_x = NUM_SPRITE_X[digit] + x - SCORE_POS_X[current_score_digit];
      object_y = NUM_SPRITE_Y + y - SCORE_POS_Y;
    end else if (current_state == S_RENDER_PLAYER) begin
      object_x = PLAYER_SPRITE_X[player_anime_state] + x - player_x_left;
      object_y = PLAYER_SPRITE_Y + y - player_y_up;
    end
  end

  PulseSync #(1) ps (  //frame_clk上升沿
      .sync_in  (frame_clk),
      .clk      (clk),
      .pulse_out(frame_start)
  );

  vram_bram vram_inst (
      .clka (ram_clk),
      .wea  (vram_we),
      .addra(vram_addr),
      .dina (vram_data),

      .clkb (ram_clk),
      .addrb(raddr),
      .doutb(rdata)
  );

  background #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) background_inst (
      .clk(ram_clk),
      .frame_clk(frame_start),
      .rstn(rstn),
      .scroll_enabled(1),
      .addr(render_addr),
      .n(6),  //每n个frame_clk
      .rgb(background_rgb)
  );

  Rom_Menu menu (
      .clka(ram_clk),  // input wire clka
      .addra(render_addr),  // input wire [14 : 0] addra
      .douta(menu_rgb)  // output wire [11 : 0] douta
  );

  Rom_Gameover gameover (
      .clka(ram_clk),  // input wire clka
      .addra(render_addr),  // input wire [14 : 0] addra
      .douta(gameover_rgb)  // output wire [11 : 0] douta
  );

  // 256x128
  Rom_Item objects (
      .clka(ram_clk),  // input wire clka
      .addra({object_y, object_x}),  // input wire [14 : 0] addra
      .douta(object_rgb)  // output wire [11 : 0] douta
  );

  // 256x128
  Rom_Item_alpha objects_alpha (
      .clka(ram_clk),  // input wire clka
      .addra({object_y, object_x}),  // input wire [14 : 0] addra
      .douta(object_alpha)  // output wire [0 : 0] douta
  );
endmodule
