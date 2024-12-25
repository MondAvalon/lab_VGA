`timescale 1ns/1ps
module SingleStair#(
    parameter H_LENGTH  = 200, //宽度
    parameter V_LENGTH  = 150,  //高度
    parameter NUM = 0
)(
    input clk,
    input frame_clk,
    input rstn,
    input enable_scroll,    //借用一下，实现暂停功能
    // input [3:0]   num,             // 台阶数字编号
    input [7:0] n,         // 每n个frame_clk更新一次offset，图片向下滚动速度为每秒72/n个像素,即刷新率

    output reg [$clog2(H_LENGTH)-1:0] loc_x, //x位置
    output reg [$clog2(V_LENGTH)-1:0] loc_y, //y位置
    output reg [1:0] mark //台阶分类
); 
wire [7:0] count_y;  // 计数器
reg signed [31:0] randnum=NUM*32'h12345678;  // 随机数种子

always @(posedge frame_clk) begin
    randnum <= {randnum[30:0], randnum[0] ^ randnum[1] ^ randnum[2] ^ randnum[3]};
end

// 在每个frame_clk上升沿更新计数器和偏移量
always @(posedge frame_clk) begin
    if(!rstn) begin
        loc_x <= NUM * 11;
        loc_y <= 10;
        mark <= 0;
    end else begin
        if (loc_y > 145) begin
            loc_x <= (100 + randnum % 70);
            loc_y <= 10;
            mark <= (1 + randnum % 2);
        end
        else begin
        if (count_y == 0) begin  // 计数器为零，y轴移动
            loc_y <= loc_y + 1;
        end
        end
    end
end

Counter #(
    .WIDTH      (8),
    .RESET_VALUE(0)
) counter_y (// 每个frame_clk计数器减1
  .clk       (frame_clk),
  .rstn      (rstn),
  .load_value(n - 1),
  .enable    (enable_scroll),
  .count     (count_y)
);

initial begin //初始化
    loc_x = NUM * 11;
    loc_y = 10;
    // finish <= 0;
    mark = 1;
end

endmodule
