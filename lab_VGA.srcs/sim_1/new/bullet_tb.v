`timescale 1ns / 1ps

module tb_single_stair();

// 参数定义
localparam H_LENGTH = 200;
localparam V_LENGTH = 150;

// 信号定义
reg clk;
// reg frame_clk;
reg enable_scroll;
reg [7:0] n;
reg rstn;
wire [$clog2(H_LENGTH)-1:0] loc_x;
wire [$clog2(V_LENGTH)-1:0] loc_y;
wire [1:0] mark;

// 实例化被测模块
SingleStair #(
    .H_LENGTH(H_LENGTH),
    .V_LENGTH(V_LENGTH),
    .NUM(0)
) dut (
    .clk(clk),
    .frame_clk(clk),
    .rstn(rstn),
    .enable_scroll(enable_scroll),
    .n(n),
    .loc_x(loc_x),
    .loc_y(loc_y),
    .mark(mark)
);

// 时钟生成
initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz时钟
end

// initial begin
//     frame_clk = 0;
//     forever #6944 frame_clk = ~frame_clk;  // ~72Hz帧时钟
// end

// 测试激励
initial begin
    // 初始化
    enable_scroll = 1;
    n = 8'd2;
    rstn = 1;
end

// 监视输出
//initial begin
//    $monitor("Time=%0t enable_scroll=%b num=%d n=%d loc_x=%d loc_y=%d mark=%d",
//             $time, enable_scroll, num, n, loc_x, loc_y, mark);
//end

endmodule