// 控制器模块
module Controllor #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
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
  wire [11:0] rdata;
  wire [ADDR_WIDTH-1:0] raddr;
  wire [ADDR_WIDTH-1:0] render_addr;
  wire [1:0] game_state;

  wire left, right, shoot, space;


  // 像素时钟
  pclk pixel_clock_inst (
      .clk_out1(pclk),
      .reset   (~rstn),
      //   .locked  (locked),
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
      .btnd(BTND),

      .left (left),
      .right(right),
      .shoot(shoot),
      .space(space)
  );

  // 游戏逻辑
  Game game_logic_inst (
      .clk(clk),
      .frame_clk(VGA_VS),
      .rstn(rstn),
      .render_addr(render_addr),
      .left(left),
      .right(right),
      .shoot(shoot),
      .space(space),

      // output in-game object x, y, priority, color
      .game_state(game_state)

  );

  // 帧生成
  FrameGenerator #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) frame_gen_inst (
      .clk(clk),
      .frame_clk(VGA_VS),
      .rstn(rstn),

      //input in-game .x, .y, .priority, .color
      .game_state (game_state),
      .render_addr(render_addr),

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

