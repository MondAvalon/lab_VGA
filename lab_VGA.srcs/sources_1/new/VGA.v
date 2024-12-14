module VGA #(
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150,
    parameter ADDR_WIDTH = 15
) (
    input [14 : 0] waddr,  // 写地址，修改位宽为15位
    input [11 : 0] wdata,  // 写数据，修改位宽为12位(RGB444)
    input [ 0 : 0] we,     // 写使能
    input [ 0 : 0] clk,
    input [ 0 : 0] rstn,   // 复位信号,低有效

    output [ADDR_WIDTH-1:0] raddr,  // 读地址
    output [0 : 0] hs,  // 水平显示同步
    output [0 : 0] vs,  // 垂直显示同步
    output [3 : 0] r,
    output [3 : 0] g,
    output [3 : 0] b
);

  wire        pclk;
  //   wire        locked;

  // 添加缺失的信号定义
  reg         ena = 1'b1;  // 端口A使能信号
  reg         enb = 1'b1;  // 端口B使能信号

  wire [11:0] rdata;  // 读出的数据
  wire [11:0] rgb_out;  // RGB输出信号

  // RGB输出逻辑
  assign r = rgb_out[11:8];
  assign g = rgb_out[7:4];
  assign b = rgb_out[3:0];

  pclk pclk_inst (
      .clk_out1(pclk),
      .reset   (~rstn),
      //   .locked  (locked),
      .clk_in1 (clk)
  );

  vram_bram vram_inst (
      .clka (clk),
      .ena  (ena),
      .wea  (we),
      .addra(waddr),
      .dina (wdata),
      .douta(),
      .clkb (pclk),
      .enb  (enb),
      .web  (1'b0),
      .addrb(raddr),
      .dinb (12'b0),
      .doutb(rdata)
  );

  DisplayUnit #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) du (
      .rstn(rstn),
      .pclk(pclk),
      .rdata(rdata),
      .hs(hs),
      .vs(vs),
      .raddr(raddr),
      .rgb_out(rgb_out)
  );

endmodule
