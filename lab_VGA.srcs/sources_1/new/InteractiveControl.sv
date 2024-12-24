// 控制器模块
module Controllor #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150,
    parameter MAX_BULLET = 5
) (
    input clk,
    input rstn,
    input [10:0] key_event,
    input [127:0] key_state,
    input [7:0] ps2_data,
    input ps2_valid,
    input btnc,
    btnl,
    btnr,
    btnu,
    btnd,

    output [3 : 0] VGA_R,
    output [3 : 0] VGA_G,
    output [3 : 0] VGA_B,
    output VGA_HS,
    output VGA_VS
);
  wire pclk;
  wire clk_25mhz;
  wire clk_5mhz;
  wire [11:0] rdata;
  wire [ADDR_WIDTH-1:0] raddr;
  wire [ADDR_WIDTH-1:0] render_addr;
  wire [1:0] game_state;
  wire [15:0] score;
  wire [15:0] high_score;
  wire left, right, shoot, space;
  wire enable_scroll;
  wire [7:0] n;
  wire [$clog2(H_LENGTH)-1:0] player_x;
  wire [$clog2(V_LENGTH)-1:0] player_y;
  wire [$clog2(H_LENGTH)-1:0] boss_x;
  wire [$clog2(V_LENGTH)-1:0] boss_y;
  wire [$clog2(H_LENGTH)-1:0] bullet_x;
  wire [$clog2(V_LENGTH)-1:0] bullet_y;
  wire [$clog2(MAX_BULLET)-1:0] bullet_index;
  wire bullet_display;

  reg clk_72hz = 0;
  reg [15:0] counter_72hz = 0;
  localparam DIVIDER_72HZ = 16'd34722;  // 5MHz / 72Hz / 2

  always @(posedge clk_5mhz) begin
    if (!rstn) begin
      counter_72hz <= 0;
      clk_72hz <= 0;
    end else begin
      if (counter_72hz >= DIVIDER_72HZ - 1) begin
        counter_72hz <= 0;
        clk_72hz <= ~clk_72hz;
      end else begin
        counter_72hz <= counter_72hz + 1;
      end
    end
  end

  // 像素时钟
  pclk pixel_clock_inst (
      .clk_out1(pclk),
      .clk_out2(clk_25mhz),
      .clk_out3(clk_5mhz),
      .reset   (~rstn),
      .locked  (),
      .clk_in1 (clk)
  );

  // 游戏输入
  GameInput game_input_inst (
      .ps2_data(ps2_data),
      .ps2_valid(ps2_valid),
      .btnc(btnc),
      .btnl(btnl),
      .btnr(btnr),
      .btnu(btnu),
      .btnd(btnd),

      .left (left),
      .right(right),
      .shoot(shoot),
      .space(space)
  );

  // 游戏逻辑
  Game game_inst (
      .clk(pclk),
      .frame_clk(VGA_VS),
      .rstn(rstn),
      .render_addr(render_addr),
      .left(left),
      .right(right),
      .shoot(shoot),
      .space(space),

      // output in-game object x, y, priority, color
      .game_state(game_state),
      .bullet_lookup_i(bullet_index),
      .score(score),
      .high_score(high_score),
      .enable_scroll(enable_scroll),
      .n(n),
      .player_x(player_x),
      .player_y(player_y),
      .enemy_x(boss_x),
      .enemy_y(boss_y),
      .bullet_x(bullet_x),
      .bullet_y(bullet_y),
      .bullet_display(bullet_display)
  );

  // 帧生成
  FrameGenerator #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) frame_gen_inst (
      .ram_clk(clk),
      .clk(pclk),
      .frame_clk(VGA_VS),
      .rstn(rstn),

      //input in-game .x, .y, .priority, .color
      .game_state(game_state),
      .bullet_index(bullet_index),
      .scroll_enabled(enable_scroll),
      .n(n),
      .render_addr(render_addr),
      .score(score),
      .high_score(high_score),
      .player_x(player_x),
      .player_y(player_y),
      .boss_x(boss_x),
      .boss_y(boss_y),
      .bullet_x(bullet_x),
      .bullet_y(bullet_y),
      .bullet_display(bullet_display),
      .raddr(raddr),
      .rdata(rdata)
  );

  // 显示
  DisplayUnit #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) display_unit_inst (
      .rstn (rstn),
      .pclk (pclk),
      .rdata(rdata),

      .raddr(raddr),
      .hs(VGA_HS),
      .vs(VGA_VS),
      .rgb_out({VGA_R, VGA_G, VGA_B})
  );


endmodule

