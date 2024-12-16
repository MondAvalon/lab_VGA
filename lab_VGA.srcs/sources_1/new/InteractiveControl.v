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

    output [3 : 0] VGA_R,
    output [3 : 0] VGA_G,
    output [3 : 0] VGA_B,
    output VGA_HS,
    output VGA_VS
);
  wire pclk;
  wire [11:0] rdata;
  wire [ADDR_WIDTH-1:0] raddr;


  // 像素时钟
  pclk pclk_inst (
      .clk_out1(pclk),
      .reset   (~rstn),
      //   .locked  (locked),
      .clk_in1 (clk)
  );

  // 游戏逻辑
  Game game (
      .clk(clk),
      .frame_clk(VGA_VS),
      .rstn(rstn),
      .key_event(key_event),
      .key_state(key_state)

      // output in-game object x, y, priority, color
  );

  // 帧生成
  FrameGenerator #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) frame (
      .clk(clk),
      .frame_clk(VGA_VS),
      .rstn(rstn),
      .raddr(raddr),
      //in-game .x, .y, .priority, .color


      .rdata (rdata)
  );

// 显示
DisplayUnit #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .H_LENGTH  (H_LENGTH),
    .V_LENGTH  (V_LENGTH)
) du (
    .rstn(rstn),
    .pclk(pclk),
    .rdata(rdata),

    .raddr(raddr),
    .hs(VGA_HS),
    .vs(VGA_VS),
    .rgb_out({VGA_R, VGA_G, VGA_B})
);


endmodule

