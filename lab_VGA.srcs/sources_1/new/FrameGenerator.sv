//获取VGA信号的同步信号，根据游戏对象的坐标与优先级等生成一个固定的分辨率的图像
module FrameGenerator #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150,
    parameter MAX_BULLET = 5
) (
    input ram_clk,
    input clk,
    input frame_clk,
    input rstn,

    //input in-game x, y
    input [1:0] game_state,
    input scroll_enabled,
    input [7:0] n,
    output [ADDR_WIDTH-1:0] render_addr,
    output reg [3:0] stair_index,
    output reg [$clog2(MAX_BULLET)-1:0] bullet_index,
    input [15:0] score,
    input [15:0] high_score,
    input [$clog2(H_LENGTH)-1:0] player_x,
    input [$clog2(V_LENGTH)-1:0] player_y,
    input [$clog2(H_LENGTH)-1:0] boss_x,
    input [$clog2(V_LENGTH)-1:0] boss_y,
    input [$clog2(H_LENGTH)-1:0] bullet_x,
    input [$clog2(V_LENGTH)-1:0] bullet_y,
    input [$clog2(H_LENGTH)-1:0] stair_x,
    input [$clog2(V_LENGTH)-1:0] stair_y,

    // output VGA signal
    input [ADDR_WIDTH-1:0] raddr,
    output [11:0] rdata
);

  typedef enum {
    GAME_MENU,
    GAME_PLAYING,
    GAME_OVER
  } game_state_t;

  typedef enum {
    IDLE,
    RENDER_BACKGROUND,
    RENDER_SCORE,
    RENDER_HIGH_SCORE,
    RENDER_STAIR,
    RENDER_PUDDING,
    RENDER_OBSTACLE,
    RENDER_BULLET,
    RENDER_BOSS,
    RENDER_PLAYER,
    RENDER_FLAN
  } render_state_t;

  reg [$clog2(H_LENGTH)-1:0] render_x;
  reg [$clog2(V_LENGTH)-1:0] render_y;

  wire [$clog2 (H_LENGTH)-1:0] player_x_left, player_x_right;
  wire [$clog2 (H_LENGTH)-1:0] flan_x_left, flan_x_right;
  wire [$clog2 (H_LENGTH)-1:0] boss_x_left, boss_x_right;
  wire [$clog2 (H_LENGTH)-1:0] bullet_x_left, bullet_x_right;
  wire [$clog2 (H_LENGTH)-1:0] stair_x_left, stair_x_right;

  wire [$clog2 (V_LENGTH)-1:0] player_y_up, player_y_down;
  wire [$clog2 (V_LENGTH)-1:0] flan_y_up, flan_y_down;
  wire [$clog2 (V_LENGTH)-1:0] boss_y_up, boss_y_down;
  wire [$clog2 (V_LENGTH)-1:0] bullet_y_up, bullet_y_down;
  wire [$clog2 (V_LENGTH)-1:0] stair_y_up, stair_y_down;

  assign player_x_left = player_x - 14;
  assign player_x_right = player_x + 15;
  assign player_y_up = player_y - 17;
  assign player_y_down = player_y + 18;
  assign boss_x_left = boss_x - 46;
  assign boss_x_right = boss_x + 47;
  assign boss_y_up = boss_y - 17;
  assign boss_y_down = boss_y + 18;
  assign bullet_x_left = bullet_x - 4;
  assign bullet_x_right = bullet_x + 4;
  assign bullet_y_up = bullet_y - 11;
  assign bullet_y_down = bullet_y + 12;
  assign stair_x_left = stair_x - 14;
  assign stair_x_right = stair_x + 15;
  assign stair_y_up = stair_y - 1;
  assign stair_y_down = stair_y + 2;

  assign flan_x_left = player_x + 20;
  assign flan_x_right = player_x + 49;
  assign flan_y_up = player_y - 17;
  assign flan_y_down = player_y + 18;

  wire generation_begin;

  reg vram_we;  //写使能
  reg [ADDR_WIDTH-1:0] vram_addr;
  reg [11:0] vram_rgb;
  wire [11:0] menu_rgb;
  wire [11:0] background_rgb;
  wire [11:0] gameover_rgb;

  reg [1:0] player_anime_state;
  render_state_t render_state, next_render_state;
  reg [6:0] object_y;  // 高128
  reg [7:0] object_x;  // 宽256
  wire [ADDR_WIDTH-1:0] object_addr;
  wire [11:0] object_rgb;
  wire object_alpha;

  assign render_addr = render_y * H_LENGTH + render_x;
  assign object_addr = {object_y, object_x};

  wire [ADDR_WIDTH-1:0] render_addr_next = render_addr + 1;

  // 显示坐标常量
  localparam X_MAX = H_LENGTH - 1;
  localparam Y_MAX = V_LENGTH - 1;
  localparam [7:0] SCORE_POS_X[0:3] = {8'd0, 8'd10, 8'd20, 8'd30};
  localparam SCORE_POS_Y = 140;
  localparam [7:0] HIGH_SCORE_POS_X[0:3] = {8'd0, 8'd10, 8'd20, 8'd30};
  localparam HIGH_SCORE_POS_Y = 140;
  localparam [7:0] SCORE_POS_X_MAX[0:3] = {8'd9, 8'd19, 8'd29, 8'd39};
  localparam SCORE_POS_Y_MAX = 149;
  localparam [7:0] HIGH_SCORE_POS_X_MAX[0:3] = {8'd9, 8'd19, 8'd29, 8'd39};
  localparam HIGH_SCORE_POS_Y_MAX = 149;

  // 游戏对象ROM坐标常量
  // 数字0-9的ROM坐标
  localparam [7:0] NUM_X_ROM[0:9] = {
    8'd0, 8'd10, 8'd20, 8'd30, 8'd40, 8'd50, 8'd60, 8'd70, 8'd80, 8'd90
  };
  localparam NUM_Y_ROM = 36;
  // 玩家坐标
  localparam [7:0] PLAYER_X_ROM[0:2] = {8'd0, 8'd30, 8'd60};
  localparam PLAYER_Y_ROM = 0;
  // boss坐标
  localparam BOSS_X_ROM = 150;
  localparam BOSS_Y_ROM = 0;
  // 子弹坐标
  localparam BULLET_X_ROM = 100;
  localparam BULLET_Y_ROM = 36;
  // 障碍物坐标
  localparam [7:0] OBSTACLE_X_ROM[0:4] = {8'd0, 8'd16, 8'd32, 8'd48, 8'd64};
  localparam OBSTACLE_Y_ROM = 46;
  // 布丁道具坐标
  localparam PUDDING_X_ROM = 109;
  localparam PUDDING_Y_ROM = 36;
  // 残机道具坐标
  localparam ONEUP_X_ROM = 80;
  localparam ONEUP_Y_ROM = 46;
  // 平台坐标
  localparam [7:0] STAIR_X_ROM[0:1] = {8'd0, 8'd30};
  localparam STAIR_Y_ROM = 62;

  reg [1:0] score_digit;  // 当前渲染第几位数字(0-3)
  reg [1:0] next_score_digit;  // 下一个渲染的数字位数
  reg [3:0] current_digit;  // 当前渲染的数字值

  // 读取分数当前位数字
  always @(*) begin
    case (score_digit)
      0: current_digit = (render_state ^ RENDER_SCORE) ? high_score[15:12] : score[15:12];
      1: current_digit = (render_state ^ RENDER_SCORE) ? high_score[11:8] : score[11:8];
      2: current_digit = (render_state ^ RENDER_SCORE) ? high_score[7:4] : score[7:4];
      3: current_digit = (render_state ^ RENDER_SCORE) ? high_score[3:0] : score[3:0];
      default: current_digit = 0;
    endcase
  end

  // 读取贴图的坐标
  always @(*) begin
    case (render_state)
      RENDER_SCORE, RENDER_HIGH_SCORE: begin
        object_x = NUM_X_ROM[current_digit] + render_x - SCORE_POS_X[score_digit];
        object_y = NUM_Y_ROM + render_y - SCORE_POS_Y;
      end
      RENDER_PLAYER: begin
        object_x = PLAYER_X_ROM[player_anime_state] + render_x - player_x_left;
        object_y = PLAYER_Y_ROM + render_y - player_y_up;
      end
      RENDER_BOSS: begin
        object_x = BOSS_X_ROM + render_x - boss_x_left;
        object_y = BOSS_Y_ROM + render_y - boss_y_up;
      end
      RENDER_BULLET: begin
        object_x = BULLET_X_ROM + render_x - bullet_x_left;
        object_y = BULLET_Y_ROM + render_y - bullet_y_up;
      end
      default: begin
        object_x = 0;
        object_y = 0;
      end
    endcase
  end

  // 渲染状态机转换
  always @(posedge clk) begin
    if (~rstn) begin
      render_state <= IDLE;
      score_digit  <= 0;
    end else begin
      render_state <= next_render_state;
      score_digit  <= next_score_digit;
    end
  end

  // 渲染状态机转换
  always @(*) begin
    case (render_state)
      IDLE: begin
        next_render_state = generation_begin ? RENDER_BACKGROUND : IDLE;
      end
      RENDER_BACKGROUND: begin
        next_render_state = (!(render_x ^ X_MAX) && !(render_y ^ Y_MAX)) ? 
                            (((game_state ^ GAME_MENU) && (game_state ^ GAME_OVER)) ? RENDER_SCORE: RENDER_HIGH_SCORE) : 
                            RENDER_BACKGROUND;
      end
      RENDER_SCORE: begin
        next_render_state = !(render_x ^ SCORE_POS_X_MAX[3]) && !(render_y ^ SCORE_POS_Y_MAX) ? 
                              RENDER_BULLET : RENDER_SCORE;
        next_score_digit = !(render_x ^ SCORE_POS_X_MAX[score_digit]) && !(render_y ^ SCORE_POS_Y_MAX) ? 
                            (!(render_x ^ SCORE_POS_X_MAX[3]) ? 0 : score_digit + 1) : 
                            score_digit;
      end
      RENDER_HIGH_SCORE: begin
        next_render_state = !(render_x ^ HIGH_SCORE_POS_X_MAX[3]) && !(render_y ^ HIGH_SCORE_POS_Y_MAX) ? 
                            IDLE : 
                            RENDER_HIGH_SCORE;
        next_score_digit = !(render_x ^ HIGH_SCORE_POS_X_MAX[score_digit]) && !(render_y ^ HIGH_SCORE_POS_Y_MAX) ? 
                            (!(render_x ^ HIGH_SCORE_POS_X_MAX[3]) ? 0 : score_digit + 1) : 
                            score_digit;
      end
      RENDER_BULLET: begin
        next_render_state = !(render_x ^ bullet_x_right) && !(render_y ^ bullet_y_down) ? 
                            RENDER_PLAYER : 
                            RENDER_BULLET;
      end
      RENDER_PLAYER: begin
        next_render_state = !(render_x ^ player_x_right) && !(render_y ^ player_y_down) ? RENDER_BOSS : RENDER_PLAYER;
      end
      RENDER_BOSS: begin
        next_render_state = !(render_x ^ boss_x_right) && !(render_y ^ boss_y_down) ? IDLE : RENDER_BOSS;
      end
      default: begin
        next_render_state = IDLE;
        next_score_digit  = 0;
      end
    endcase
  end

  // 渲染状态机
  always @(posedge clk) begin
    if (~rstn) begin
      render_x <= 0;
      render_y <= 0;
      vram_we <= 0;
      vram_addr <= 0;
      vram_rgb <= 0;
      player_anime_state <= 0;
      // next_render_state <= IDLE;
    end else begin
      vram_addr <= render_addr;
      case (render_state)
        IDLE: begin
          vram_we  <= 0;
          render_x <= -1;
          render_y <= 0;
          vram_rgb <= 0;
        end
        RENDER_BACKGROUND: begin
          vram_we <= 1;
          vram_rgb <= ((game_state^GAME_MENU))?((game_state^GAME_PLAYING)?gameover_rgb:background_rgb ):menu_rgb;

          if (!(render_x ^ X_MAX)) begin
            if (!(render_y ^ Y_MAX)) begin  //完成全部背景的渲染
              if (!((game_state ^ GAME_MENU) && (game_state ^ GAME_OVER))) begin
                // next_render_state <= RENDER_HIGH_SCORE;
                render_x <= HIGH_SCORE_POS_X[0];
                render_y <= HIGH_SCORE_POS_Y;
              end else if (!(game_state ^ GAME_PLAYING)) begin
                // next_render_state <= RENDER_SCORE;
                render_x <= SCORE_POS_X[0];
                render_y <= SCORE_POS_Y;
              end
            end else begin  //完成一行的渲染
              render_y <= render_y + 1;
              render_x <= 0;
            end
          end else begin
            render_x <= render_x + 1;
          end
        end
        RENDER_SCORE: begin
          vram_we  <= 1;
          vram_rgb <= object_alpha ? object_rgb : background_rgb;
          // vram_rgb <= object_rgb;
          if (!(render_x ^ SCORE_POS_X_MAX[score_digit])) begin
            if (!(render_y ^ SCORE_POS_Y_MAX)) begin  // 完成一个数字渲染
              if (!(score_digit ^ 3)) begin  // 完成所有数字
                // next_render_state <= RENDER_BULLET;
                // score_digit <= 0;
                render_x <= bullet_x_left;
                render_y <= bullet_y_up;
              end else begin  // 进入下一个数字
                // render_x <= SCORE_POS_X[score_digit+1];
                render_x <= render_x + 1;
                render_y <= SCORE_POS_Y;
                // score_digit <= score_digit + 1;
              end
            end else begin  // 下一行
              render_y <= render_y + 1;
              render_x <= SCORE_POS_X[score_digit];
            end
          end else begin  // 下一列
            render_x <= render_x + 1;
          end
        end
        RENDER_HIGH_SCORE: begin
          vram_rgb <= object_alpha ? object_rgb : game_state == GAME_MENU ? menu_rgb : gameover_rgb;
          vram_we <= 1;
          // vram_rgb <= object_rgb;
          if (!(render_x ^ HIGH_SCORE_POS_X_MAX[score_digit])) begin
            if (!(render_y ^ HIGH_SCORE_POS_Y_MAX)) begin  // 完成一个数字渲染
              if (!(score_digit ^ 3)) begin  // 完成所有数字
                // next_render_state <= IDLE;
                // score_digit <= 0;
              end else begin  // 进入下一个数字
                // render_x <= HIGH_SCORE_POS_X[score_digit+1];
                render_x <= render_x + 1;
                render_y <= HIGH_SCORE_POS_Y;
                // score_digit <= score_digit + 1;
              end
            end else begin  // 下一行
              render_y <= render_y + 1;
              render_x <= HIGH_SCORE_POS_X[score_digit];
            end
          end else begin  // 下一列
            render_x <= render_x + 1;
          end
        end
        RENDER_BULLET: begin
          vram_we  <= 1;
          vram_rgb <= object_alpha ? object_rgb : background_rgb;
          if (!(render_x ^ bullet_x_right)) begin
            if (!(render_y ^ bullet_y_down)) begin
              if (bullet_index == MAX_BULLET - 1) begin
                // All bullets rendered, move to player
                render_x <= player_x_left;
                render_y <= player_y_up;
                bullet_index <= 0;
              end else begin
                // Move to next bullet
                bullet_index <= bullet_index + 1;
                render_x <= bullet_x_left;
                render_y <= bullet_y_up;
              end
            end else begin
              render_x <= bullet_x_left;
              render_y <= render_y + 1;
            end
          end else begin
            render_x <= render_x + 1;
          end
        end
        RENDER_PLAYER: begin
          vram_we  <= 1;
          // vram_rgb <= object_alpha ? object_rgb : background_rgb;
          vram_rgb <= object_rgb;
          if (!(render_x ^ player_x_right)) begin
            if (!(render_y ^ player_y_down)) begin
              // next_render_state <= RENDER_BOSS;
              render_x <= boss_x_left;
              render_y <= boss_y_up;
            end else begin
              render_x <= player_x_left;
              render_y <= render_y + 1;
            end
          end else begin
            render_x <= render_x + 1;
          end
        end
        RENDER_BOSS: begin
          vram_we  <= 1;
          vram_rgb <= object_alpha ? object_rgb : background_rgb;
          // vram_rgb <= object_rgb;
          if (!(render_x ^ boss_x_right)) begin
            if (!(render_y ^ boss_y_down)) begin
              // next_render_state <= IDLE;
              render_x <= 0;
              render_y <= 0;
            end else begin
              render_x <= boss_x_left;
              render_y <= render_y + 1;
            end
          end else begin
            render_x <= render_x + 1;
          end
        end
      endcase
    end
  end


  vram_bram vram_inst (
      .clka (clk),
      .wea  (vram_we),
      .addra(vram_addr),
      .dina (vram_rgb),

      .clkb (ram_clk),
      .addrb(raddr),
      .doutb(rdata)
  );

  background #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) background_inst (
      .clk(clk),
      .frame_clk(generation_begin),
      .rstn(rstn),
      .scroll_enabled(scroll_enabled),
      .addr(render_addr_next + 2),  //读取rom中的数据的地址
      .n(n),  //每n个frame_clk
      .v(1),
      .rgb(background_rgb)
  );

  Rom_Menu menu (
      .clka(clk),  // input wire clka
      .addra(render_addr_next),  // input wire [14 : 0] addra
      .douta(menu_rgb)  // output wire [11 : 0] douta
  );

  Rom_Gameover gameover (
      .clka(clk),  // input wire clka
      .addra(render_addr_next),  // input wire [14 : 0] addra
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

  PulseSync #(1) ps (  //frame_clk上升沿
      .sync_in  (frame_clk),
      .clk      (clk),
      .pulse_out(generation_begin)
  );

  initial begin
    render_x = 0;
    render_y = 0;
    vram_we = 0;
    vram_addr = 0;
    vram_rgb = 0;
    player_anime_state = 0;
    render_state = IDLE;
    next_render_state = IDLE;
    score_digit = 0;
    next_score_digit = 0;
    current_digit = 0;
    object_y = 0;
    object_x = 0;
  end

endmodule
