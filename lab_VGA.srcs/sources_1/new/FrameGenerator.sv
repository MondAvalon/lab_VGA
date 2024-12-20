//获取VGA信号的同步信号，根据游戏对象的坐标与优先级等生成一个固定的分辨率的图像
module FrameGenerator #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
) (
    input clk,
    input pclk,
    input frame_clk,
    input rstn,

    //input in-game x, y, priority, color 
    input [1:0] game_state,
    output [ADDR_WIDTH-1:0] render_addr,
    input [15:0] score,
    input [15:0] high_score,

    // output VGA signal
    input [ADDR_WIDTH-1:0] raddr,
    output [11:0] rdata
);

  reg [$clog2(H_LENGTH)-1:0] render_x;
  reg [$clog2(V_LENGTH)-1:0] render_y;

  wire [$clog2(H_LENGTH)-1:0] player_x, player_x_leftup, player_x_rightdown;
  wire [$clog2(V_LENGTH)-1:0] player_y, player_y_leftup, player_y_rightdown;
  assign player_x_leftup = player_x - 14;
  assign player_x_rightdown = player_x + 15;
  assign player_y_leftup = player_y - 17;
  assign player_y_rightdown = player_y + 18;

  reg is_generating_frame;
  wire generation_begin;
  reg scroll_enabled;

  reg vram_we;  //写使能
  reg [ADDR_WIDTH-1:0] vram_addr;
  reg [11:0] vram_rgb;
  wire [11:0] menu_rgb;
  wire [11:0] background_rgb;
  wire [11:0] gameover_rgb;
  wire [11:0] player_rgb;
  wire [11:0] bullet_rgb;
  wire [11:0] stair_rgb;
  wire [11:0] obstacle_rgb;
  wire [11:0] pudding_rgb;
  wire [11:0] boss_rgb;

  reg [1:0] player_ani_state;
  reg [4:0] render_state;
  reg [ADDR_WIDTH-1:8] object_y;  // 高128
  reg [8:0] object_x;  // 宽256
  wire [ADDR_WIDTH-1:0] object_addr;
  wire [11:0] object_rgb;
  wire object_alpha;

  assign render_addr = render_y * H_LENGTH + render_x;
  assign object_addr = {object_y, object_x};

  // 显示坐标常量
  parameter [7:0] SCORE_X_RENDER[0:3] = {8'd0, 8'd10, 8'd20, 8'd30};
  parameter SCORE_Y_RENDER = 140;
  parameter [7:0] HIGH_SCORE_X_RENDER[0:3] = {8'd0, 8'd10, 8'd20, 8'd30};
  parameter HIGH_SCORE_Y_RENDER = 130;

  // 游戏对象ROM坐标常量
  // 数字0-9的ROM坐标
  parameter [7:0] NUM_X_ROM[0:9] = {
    8'd0, 8'd10, 8'd20, 8'd30, 8'd40, 8'd50, 8'd60, 8'd70, 8'd80, 8'd90
  };
  parameter NUM_Y_ROM = 36;
  // 玩家坐标
  parameter [7:0] PLAYER_X_ROM[0:2] = {8'd0, 8'd30, 8'd60};
  parameter PLAYER_Y_ROM = 0;

  // 尺寸常量
  // 数字像素尺寸
  parameter SCORE_LENGTH = 10;  // 10*10，一共4个数字显示分数

  typedef enum {
    GAME_MENU,
    GAME_PLAYING,
    GAME_OVER
  } GameState;

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
    RENDER_PLAYER
  } RenderState;

  vram_bram vram_inst (
      .clka (clk),
      .wea  (vram_we),
      .addra(render_addr),
      .dina (vram_rgb),

      .clkb (clk),
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
      .scroll_enabled(1),
      .addr(render_addr),  //读取rom中的数据的地址
      .n(6),  //每n个frame_clk
      .rgb(background_rgb)
  );

  Rom_Menu menu (
      .clka(clk),  // input wire clka
      .addra(render_addr),  // input wire [14 : 0] addra
      .douta(menu_rgb)  // output wire [11 : 0] douta
  );

  Rom_Gameover gameover (
      .clka(clk),  // input wire clka
      .addra(render_addr),  // input wire [14 : 0] addra
      .douta(gameover_rgb)  // output wire [11 : 0] douta
  );

  // 256x128
  Rom_Item objects (
      .clka(clk),  // input wire clka
      .addra({object_y, object_x}),  // input wire [14 : 0] addra
      .douta(object_rgb)  // output wire [11 : 0] douta
  );

  // 256x128
  Rom_Item_alpha objects_alpha (
      .clka(clk),  // input wire clka
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
    is_generating_frame = 0;
    scroll_enabled = 0;
    vram_we = 0;
    // vram_addr = 0;
    vram_rgb = 0;
    player_ani_state = 0;
    render_state = IDLE;
    object_y = 0;
    object_x = 0;
  end

  reg  [1:0] score_digit;  // 当前渲染第几位数字(0-3)
  wire [3:0] current_digit;  // 当前渲染的数字值

  assign current_digit = (render_state == RENDER_SCORE) ? 
                        score[15-score_digit*4-1 -: 4] : 
                        high_score[15-score_digit*4-1 -: 4];


  always @(posedge clk) begin
    if (~rstn) begin
      render_x <= 0;
      render_y <= 0;
      is_generating_frame <= 0;
      scroll_enabled <= 0;
      vram_we <= 0;
      //   vram_addr <= 0;
      vram_rgb <= 0;
      player_ani_state <= 0;
      render_state <= IDLE;
      object_y <= 0;
      object_x <= 0;
    end else if (generation_begin) begin
      is_generating_frame <= 1;
    end
    case (render_state)
      IDLE: begin
        if (is_generating_frame) begin
          render_state <= RENDER_BACKGROUND;
          vram_we <= 1;
          render_x <= 0;
          render_y <= 0;
          vram_rgb <= background_rgb;
        end else begin
          render_state <= IDLE;
          vram_we <= 0;
          render_x <= 0;
          render_y <= 0;
          vram_rgb <= 0;
        end
      end
      RENDER_BACKGROUND: begin
        case (game_state)
          GAME_MENU: begin
            vram_rgb <= menu_rgb;
          end
          GAME_PLAYING: begin
            vram_rgb <= background_rgb;
          end
          GAME_OVER: begin
            vram_rgb <= gameover_rgb;
          end
        endcase
        if (render_x == H_LENGTH - 1) begin
          render_x <= 0;
          if (render_y == V_LENGTH - 1) begin
            render_y <= 0;
            if (game_state == GAME_MENU || game_state == GAME_OVER) begin
              render_state <= RENDER_HIGH_SCORE;
              render_x <= HIGH_SCORE_X_RENDER[0];
              render_y <= HIGH_SCORE_Y_RENDER;
              object_x <= NUM_X_ROM[high_score[15:12]];
              object_y <= NUM_Y_ROM;
            end else if (game_state == GAME_PLAYING) begin
              render_state <= RENDER_SCORE;
              render_x <= SCORE_X_RENDER[0];
              render_y <= SCORE_Y_RENDER;
              object_x <= NUM_X_ROM[score[15:12]];
              object_y <= NUM_Y_ROM;
            end else begin
              render_state <= IDLE;
            end
          end else begin
            render_y <= render_y + 1;
          end
        end else begin
          render_x <= render_x + 1;
        end
      end
      RENDER_SCORE, RENDER_HIGH_SCORE: begin
        if (render_x == SCORE_X_RENDER[score_digit] + SCORE_LENGTH - 1) begin
          render_x <= SCORE_X_RENDER[score_digit];
          if (render_y == SCORE_Y_RENDER + SCORE_LENGTH - 1) begin
            render_y <= SCORE_Y_RENDER;
            if (score_digit == 3) begin  //完成全部4个数字的渲染
              render_state <= IDLE;
              render_x <= 0;
              render_y <= 0;
              score_digit <= 0;
            end else begin
              score_digit <= score_digit + 1;
              render_y <= (render_state == RENDER_SCORE) ? SCORE_Y_RENDER : HIGH_SCORE_Y_RENDER;
              object_y <= NUM_Y_ROM;
              object_x <= NUM_X_ROM[current_digit];
            end
          end else begin
            render_y <= render_y + 1;
            object_y <= object_y + 1;
          end
        end else begin
          render_x <= render_x + 1;
          object_x <= object_x + 1;
        end
        if (object_alpha) begin
          vram_rgb <= object_rgb;
        end else begin
          vram_rgb <= (render_state == RENDER_SCORE) ? menu_rgb : background_rgb;
        end
      end
    endcase
  end

endmodule
