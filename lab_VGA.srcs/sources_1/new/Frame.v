//获取VGA信号的同步信号，根据游戏对象的坐标与优先级等生成一个固定的分辨率的图像
module FrameGenerator_old #(
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

  // wire [$clog2(H_LENGTH)-1:0] render_x;
  // wire [$clog2(V_LENGTH)-1:0] render_y;
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
  // 分数显示左上角坐标
  localparam [31:0] SCORE_X_RENDER = {8'd0, 8'd10, 8'd20, 8'd30};
  localparam SCORE_Y_RENDER = 140;
  localparam [31:0] HI_SCORE_X_RENDER = {8'd0, 8'd10, 8'd20, 8'd30};
  localparam HI_SCORE_Y_RENDER = 130;

  // 游戏对象ROM坐标常量
  // 数字0-9的ROM坐标
  localparam NUM_X_ROM = 0;
  localparam NUM_Y_ROM = 36;
  // 玩家坐标
  localparam PLAYER_1_X_ROM = 0;
  localparam PLAYER_2_X_ROM = 30;
  localparam PLAYER_3_X_ROM = 60;
  localparam PLAYER_Y_ROM = 0;

  // 尺寸常量
  // 数字像素尺寸
  localparam SCORE_LENGTH = 10;  // 10*10，一共4个数字显示分数

  // Game state definitions
  localparam GAME_MENU = 2'b00;
  localparam GAME_PLAYING = 2'b01;
  localparam GAME_OVER = 2'b10;

  // 渲染状态机
  localparam RENDER_BACKGROUND = 0;
  localparam RENDER_SCORE_0 = 2;
  localparam RENDER_SCORE_1 = 3;
  localparam RENDER_SCORE_2 = 4;
  localparam RENDER_SCORE_3 = 5;
  localparam RENDER_PLAYER = 6;
  localparam RENDER_STAIR = 7;
  localparam RENDER_OBSTACLE = 8;
  localparam RENDER_PUDDING = 9;
  localparam RENDER_BOSS = 10;
  localparam RENDER_BULLET = 11;
  localparam RENDER_GAMEOVER = 12;
  localparam RENDER_HI_SCORE_0 = 13;
  localparam RENDER_HI_SCORE_1 = 14;
  localparam RENDER_HI_SCORE_2 = 15;
  localparam RENDER_HI_SCORE_3 = 16;


  initial begin
    render_x <= 0;
    render_y <= 0;
    vram_we = 0;
    scroll_enabled = 1;
    is_generating_frame = 0;
    render_state = RENDER_BACKGROUND;
    player_ani_state = 0;
  end

  always @(posedge clk) begin
    if (!rstn) begin
      render_x  <= 0;
      render_y  <= 0;
      vram_we   <= 0;
      vram_addr <= 0;
      vram_rgb  <= 0;
    end else if (generation_begin) begin
      is_generating_frame <= 1;
    end else if (is_generating_frame) begin
      // if (render_addr < H_LENGTH * V_LENGTH - 1) begin
      //   render_addr <= render_addr + 1;
      // end else begin
      //   render_addr <= 0;
      //   is_generating_frame <= 0;
      // end

      vram_we   <= 1;
      vram_addr <= render_addr;  // 由坐标生成需要写入vram的地址

      // in-game object color update logic
      case (game_state)
        GAME_MENU: begin
          case (render_state)
            RENDER_BACKGROUND: begin
              if (render_x == H_LENGTH - 1) begin
                render_x <= 0;
                if (render_y == V_LENGTH - 1) begin
                  render_state <= RENDER_HI_SCORE_0;
                  render_x <= HI_SCORE_X_RENDER[31:24];
                  render_y <= HI_SCORE_Y_RENDER;
                  object_y <= NUM_Y_ROM;
                  object_x <= NUM_X_ROM + high_score[15:12] * SCORE_LENGTH;
                end else begin
                  render_y <= render_y + 1;
                end
              end else begin
                render_x <= render_x + 1;
              end
              vram_rgb <= menu_rgb;
            end
            RENDER_HI_SCORE_0: begin
              if (render_x == HI_SCORE_X_RENDER[31:24] + SCORE_LENGTH - 1) begin
                render_x <= HI_SCORE_X_RENDER[31:24];
                if (render_y == HI_SCORE_Y_RENDER + SCORE_LENGTH - 1) begin
                  render_state <= RENDER_HI_SCORE_1;
                  render_x <= HI_SCORE_X_RENDER[23:16];
                  render_y <= HI_SCORE_Y_RENDER;
                  object_y <= NUM_Y_ROM;
                  object_x <= NUM_X_ROM + high_score[11:8] * SCORE_LENGTH;
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
                vram_rgb <= menu_rgb;
              end
            end
            RENDER_HI_SCORE_1: begin
              if (render_x == HI_SCORE_X_RENDER[23:16] + SCORE_LENGTH - 1) begin
                render_x <= HI_SCORE_X_RENDER[23:16];
                if (render_y == HI_SCORE_Y_RENDER + SCORE_LENGTH - 1) begin
                  render_state <= RENDER_HI_SCORE_2;
                  render_x <= HI_SCORE_X_RENDER[15:8];
                  render_y <= HI_SCORE_Y_RENDER;
                  object_y <= NUM_Y_ROM;
                  object_x <= NUM_X_ROM + high_score[7:4] * SCORE_LENGTH;
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
                vram_rgb <= menu_rgb;
              end
            end
            RENDER_HI_SCORE_2: begin
              if (render_x == HI_SCORE_X_RENDER[15:8] + SCORE_LENGTH - 1) begin
                render_x <= HI_SCORE_X_RENDER[15:8];
                if (render_y == HI_SCORE_Y_RENDER + SCORE_LENGTH - 1) begin
                  render_state <= RENDER_HI_SCORE_3;
                  render_x <= HI_SCORE_X_RENDER[7:0];
                  render_y <= HI_SCORE_Y_RENDER;
                  object_y <= NUM_Y_ROM;
                  object_x <= NUM_X_ROM + high_score[3:0] * SCORE_LENGTH;
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
                vram_rgb <= menu_rgb;
              end
            end
            RENDER_HI_SCORE_3: begin
              if (render_x == HI_SCORE_X_RENDER[7:0] + SCORE_LENGTH - 1) begin
                render_x <= HI_SCORE_X_RENDER[7:0];
                if (render_y == HI_SCORE_Y_RENDER + SCORE_LENGTH - 1) begin
                  render_state <= RENDER_BACKGROUND;
                  render_y <= 0;
                  render_x <= 0;
                  object_y <= 0;
                  object_x <= 0;
                  is_generating_frame <= 0;
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
                vram_rgb <= menu_rgb;
              end
            end
          endcase
        end
        GAME_PLAYING: begin
          case (render_state)
            RENDER_BACKGROUND: begin
              // if (render_addr == H_LENGTH * V_LENGTH - 1) begin
              //   render_state <= RENDER_SCORE_0;
              //   render_x <= SCORE_X_RENDER[31:24];
              //   render_y <= SCORE_Y_RENDER;
              //   object_y <= NUM_Y_ROM;
              //   object_x <= NUM_X_ROM+score[15:12]*SCORE_LENGTH;
              // end else begin
              //   vram_rgb <= background_rgb;
              //   render_addr <= render_addr + 1;
              // end
              vram_rgb <= background_rgb;
              if (render_x == H_LENGTH - 1) begin
                render_x <= 0;
                if (render_y == V_LENGTH - 1) begin
                  render_state <= RENDER_SCORE_0;
                  render_x <= SCORE_X_RENDER[31:24];
                  render_y <= SCORE_Y_RENDER;
                  object_y <= NUM_Y_ROM;
                  object_x <= NUM_X_ROM + score[15:12] * SCORE_LENGTH;
                end else begin
                  render_y <= render_y + 1;
                end
              end else begin
                render_x <= render_x + 1;
              end
            end
            RENDER_SCORE_0: begin
              if (render_x == SCORE_X_RENDER[31:24] + SCORE_LENGTH - 1) begin
                render_x <= SCORE_X_RENDER[31:24];
                if (render_y == SCORE_Y_RENDER + SCORE_LENGTH - 1) begin
                  render_state <= RENDER_SCORE_1;
                  render_x <= SCORE_X_RENDER[23:16];
                  render_y <= SCORE_Y_RENDER;
                  object_y <= NUM_Y_ROM;
                  object_x <= NUM_X_ROM + score[11:8] * SCORE_LENGTH;
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
                vram_rgb <= background_rgb;
              end
            end
            RENDER_SCORE_1: begin
              if (render_x == SCORE_X_RENDER[23:16] + SCORE_LENGTH - 1) begin
                render_x <= SCORE_X_RENDER[23:16];
                if (render_y == SCORE_Y_RENDER + SCORE_LENGTH - 1) begin
                  render_state <= RENDER_SCORE_2;
                  render_y <= SCORE_Y_RENDER;
                  render_x <= SCORE_X_RENDER[15:8];
                  object_y <= NUM_Y_ROM;
                  object_x <= NUM_X_ROM + score[7:4] * SCORE_LENGTH;
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
                vram_rgb <= background_rgb;
              end
            end
            RENDER_SCORE_2: begin
              if (render_x == SCORE_X_RENDER[15:8] + SCORE_LENGTH - 1) begin
                render_x <= SCORE_X_RENDER[15:8];
                if (render_y == SCORE_Y_RENDER + SCORE_LENGTH - 1) begin
                  render_state <= RENDER_SCORE_3;
                  render_y <= SCORE_Y_RENDER;
                  render_x <= SCORE_X_RENDER[7:0];
                  object_y <= NUM_Y_ROM;
                  object_x <= NUM_X_ROM + score[3:0] * SCORE_LENGTH;
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
                vram_rgb <= background_rgb;
              end
            end
            RENDER_SCORE_3: begin
              if (render_x == SCORE_X_RENDER[7:0] + SCORE_LENGTH - 1) begin
                render_x <= SCORE_X_RENDER[7:0];
                if (render_y == SCORE_Y_RENDER + SCORE_LENGTH - 1) begin
                  render_state <= RENDER_PLAYER;
                  render_y <= player_y_leftup;
                  render_x <= player_x_leftup;
                  object_y <= PLAYER_Y_ROM;
                  object_x <= PLAYER_1_X_ROM;
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
                vram_rgb <= background_rgb;
              end
            end
            RENDER_PLAYER: begin
              if (render_x == player_x_rightdown) begin
                render_x <= player_x_leftup;
                if (render_y == player_y_rightdown) begin
                  render_state <= RENDER_BACKGROUND;
                  render_y <= 0;
                  render_x <= 0;
                  object_y <= 0;
                  object_x <= 0;
                  is_generating_frame <= 0;
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
                vram_rgb <= background_rgb;
              end
            end
            default: begin
              vram_rgb <= 0;
            end
          endcase
        end
        GAME_OVER: begin
          vram_rgb <= gameover_rgb;
        end
        default: vram_rgb <= vram_rgb;
      endcase
    end else begin
      vram_we   <= 0;
      vram_addr <= 0;
      vram_rgb  <= 0;
      render_x  <= 0;
      render_y  <= 0;
    end
  end

  vram_bram vram_inst (
      .clka (clk),
      .wea  (vram_we),
      .addra(vram_addr - 1),
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

endmodule
