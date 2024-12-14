//获取VGA信号的同步信号，根据游戏对象的坐标与优先级等生成一个固定的分辨率的图像
module FrameGenerator #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
) (
    input clk,
    input pclk,
    input rstn,
    input [ADDR_WIDTH-1:0] read_addr,  //读vram地址，转换为坐标

    output [3 : 0] r,
    output [3 : 0] g,
    output [3 : 0] b
);

wire [$clog2(H_LENGTH)-1:0] x;
wire [$clog2(V_LENGTH)-1:0] y;

assign x = read_addr % H_LENGTH;
assign y = read_addr / H_LENGTH;




endmodule
