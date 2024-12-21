//获取VGA信号的同步信号，根据游戏对象的坐标与优先级等生成一个固定的分辨率的图像
module FrameGenerator #(
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

  reg [$clog2(H_LENGTH)-1:0] render_x;
  reg [$clog2(V_LENGTH)-1:0] render_y;

  wire [$clog2(H_LENGTH)-1:0] player_x_leftup, player_x_rightdown;
  wire [$clog2(V_LENGTH)-1:0] player_y_leftup, player_y_rightdown;
  assign player_x_leftup = player_x - 14;
  assign player_x_rightdown = player_x + 15;
  assign player_y_leftup = player_y - 17;
  assign player_y_rightdown = player_y + 18;

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

  reg [1:0] player_anime_state;
  reg [4:0] render_state;
  reg [6:0] object_y;  // 高128
  reg [7:0] object_x;  // 宽256
  wire [ADDR_WIDTH-1:0] object_addr;
  wire [11:0] object_rgb;
  wire object_alpha;

  assign render_addr = render_y * H_LENGTH + render_x;
  assign object_addr = {object_y, object_x};

  // 显示坐标常量
  parameter [7:0] SCORE_X_RENDER[0:3] = {8'd0, 8'd10, 8'd20, 8'd30};
  parameter SCORE_Y_RENDER = 0;
  parameter [7:0] HIGH_SCORE_X_RENDER[0:3] = {8'd0, 8'd10, 8'd20, 8'd30};
  parameter HIGH_SCORE_Y_RENDER = 0;

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
  parameter NUM_LENGTH = 10;  // 10*10，一共4个数字显示分数

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
      .clka (ram_clk),
      .wea  (vram_we),
      .addra(render_addr-1),
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
      .clk(ram_clk),
      .frame_clk(generation_begin),
      .rstn(rstn),
      .scroll_enabled(1),
      .addr(render_addr),  //读取rom中的数据的地址
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

  PulseSync #(1) ps (  //frame_clk上升沿
      .sync_in  (frame_clk),
      .clk      (clk),
      .pulse_out(generation_begin)
  );

  initial begin
    render_x = 0;
    render_y = 0;
    scroll_enabled = 0;
    vram_we = 0;
    // vram_addr = 0;
    vram_rgb = 0;
    player_anime_state = 0;
    render_state = IDLE;
    // object_y = 0;
    // object_x = 0;
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
      scroll_enabled <= 0;
      vram_we <= 0;
      //   vram_addr <= 0;
      vram_rgb <= 0;
      player_anime_state <= 0;
      render_state <= IDLE;
      // object_y <= 0;
      // object_x <= 0;
    end else begin
      case (render_state)
        IDLE: begin
          if (generation_begin) begin
            render_state <= RENDER_BACKGROUND;
            vram_we <= 1;
            render_x <= 0;
            render_y <= 0;
            if (game_state == GAME_MENU) vram_rgb <= menu_rgb;
            else if (game_state == GAME_PLAYING) vram_rgb <= background_rgb;
            else if (game_state == GAME_OVER) vram_rgb <= gameover_rgb;
          end else begin
            render_state <= IDLE;
            vram_we <= 0;
            render_x <= 0;
            render_y <= 0;
            vram_rgb <= 0;
          end
        end
        RENDER_BACKGROUND: begin
          vram_rgb<=game_state == GAME_MENU ? menu_rgb : (game_state == GAME_PLAYING ? background_rgb : gameover_rgb);

          if (render_x == H_LENGTH - 1) begin
            if (render_y == V_LENGTH - 1) begin  //完成全部背景的渲染
              if (game_state == GAME_MENU || game_state == GAME_OVER) begin
                render_state <= RENDER_HIGH_SCORE;
                render_x <= HIGH_SCORE_X_RENDER[score_digit];
                render_y <= HIGH_SCORE_Y_RENDER;
                // object_x <= NUM_X_ROM[high_score[15:12]];
                // object_y <= NUM_Y_ROM;
              end else if (game_state == GAME_PLAYING) begin
                render_state <= RENDER_SCORE;
                render_x <= SCORE_X_RENDER[score_digit];
                render_y <= SCORE_Y_RENDER;
                // object_x <= NUM_X_ROM[score[15:12]];
                // object_y <= NUM_Y_ROM;
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
          if (render_x == SCORE_X_RENDER[score_digit] + NUM_LENGTH - 1) begin
            if (render_y == SCORE_Y_RENDER + NUM_LENGTH - 1) begin  // 完成一个数字渲染
              if (score_digit == 3) begin  // 完成所有数字
                render_state <= RENDER_PLAYER;
                score_digit <= 0;
                render_x <= player_x_leftup;
                render_y <= player_y_leftup;
              end else begin  // 进入下一个数字
                render_x <= SCORE_X_RENDER[score_digit+1];
                render_y <= SCORE_Y_RENDER;
                score_digit <= score_digit + 1;
              end
            end else begin  // 下一行
              render_y <= render_y + 1;
              render_x <= SCORE_X_RENDER[score_digit];
            end
          end else begin  // 下一列
            render_x <= render_x + 1;
          end
          vram_rgb <= object_alpha ? object_rgb : game_state == GAME_MENU ? menu_rgb : gameover_rgb;
          // vram_rgb <= object_rgb;
        end
        RENDER_HIGH_SCORE: begin
          if (render_x == HIGH_SCORE_X_RENDER[score_digit] + NUM_LENGTH - 1) begin
            if (render_y == HIGH_SCORE_Y_RENDER + NUM_LENGTH - 1) begin  // 完成一个数字渲染
              if (score_digit == 3) begin  // 完成所有数字
                render_state <= IDLE;
                score_digit  <= 0;
              end else begin  // 进入下一个数字
                render_x <= HIGH_SCORE_X_RENDER[score_digit+1];
                render_y <= HIGH_SCORE_Y_RENDER;
                score_digit <= score_digit + 1;
                vram_rgb <= background_rgb;
              end
            end else begin  // 下一行
              render_y <= render_y + 1;
              render_x <= HIGH_SCORE_X_RENDER[score_digit];
            end
          end else begin  // 下一列
            render_x <= render_x + 1;
          end
          vram_rgb <= object_alpha ? object_rgb : game_state == GAME_MENU ? menu_rgb : gameover_rgb;
          // vram_rgb <= object_rgb;
        end
        RENDER_PLAYER: begin
          if (render_x == player_x_rightdown) begin
            if (render_y == player_y_rightdown) begin
              render_state <= IDLE;
            end else begin
              render_x <= player_x_leftup;
              render_y <= render_y + 1;
            end
          end else begin
            render_x <= render_x + 1;
          end
          vram_rgb <= object_alpha ? object_rgb : background_rgb;
          // vram_rgb <= object_rgb;
        end
      endcase
    end
  end

  // // 在FrameGenerator中实例化
  // RenderHelper #(
  //     .SPRITE_WIDTH (NUM_LENGTH),
  //     .SPRITE_HEIGHT(NUM_LENGTH)
  // ) num_render_helper (
  //     .render_x(render_x),
  //     .render_y(render_y),
  //     .sprite_base_x(NUM_X_ROM[current_digit]),
  //     .sprite_base_y(NUM_Y_ROM),
  //     .pos_x(SCORE_X_RENDER[score_digit]),
  //     .pos_y(SCORE_Y_RENDER),
  //     .object_x(num_x),
  //     .object_y(num_y)
  // );

  // RenderHelper #(
  //     .SPRITE_WIDTH (30),
  //     .SPRITE_HEIGHT(36)
  // ) player_render_helper (
  //     .render_x(render_x),
  //     .render_y(render_y),
  //     .sprite_base_x(PLAYER_X_ROM[player_anime_state]),
  //     .sprite_base_y(PLAYER_Y_ROM),
  //     .pos_x(player_x_leftup),
  //     .pos_y(player_y_leftup),
  //     .object_x(player_x),
  //     .object_y(player_y)
  // );

  always @(*) begin
    if (render_state == RENDER_SCORE || render_state == RENDER_HIGH_SCORE) begin
      object_x = NUM_X_ROM[current_digit] + render_x - SCORE_X_RENDER[score_digit];
      object_y = NUM_Y_ROM + render_y - SCORE_Y_RENDER;
    end else if (render_state == RENDER_PLAYER) begin
      object_x = PLAYER_X_ROM[player_anime_state] + render_x - player_x_leftup;
      object_y = PLAYER_Y_ROM + render_y - player_y_leftup;
    end
  end

endmodule
