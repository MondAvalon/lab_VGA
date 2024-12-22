// 台阶模块,提供特定位置台阶的查询
module Stairs#(
    parameter H_LENGTH  = 200, //宽度
    parameter V_LENGTH  = 150  //高度
)(
    input clk,
    input frame_clk,
    input rstn,
    input [3:0] loc,        //台阶编号
    input enable_scroll,   //借用一下，实现暂停功能
    input [7:0] n,         // 每n个frame_clk更新一次offset，图片向下滚动速度为每秒72/n个像素,即刷新率

    output reg [1:0] Stair_state, //特定台阶编号的台阶状态
    output reg [H_LENGTH-1:0] loc_x, //x位置
    output reg [V_LENGTH-1:0] loc_y  //y位置
); 
wire [3:0] count_1;
wire [6:0] num;
wire [3:0] count;  // 计数器
wire [H_LENGTH:0] state_x [3:0];  // state[00,H_LENGTH,V_LENGTH] 状态数组，定义一共16块台阶的状态和坐标，“00”表示空闲，“01”第一类台阶，以此类推
wire [V_LENGTH:0] state_y [3:0];
wire [1:0] state_mark [3:0];

SingleStair single0 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(0),
    .loc_x(state_x[0]),
    .loc_y(state_y[0]),
    .mark(state_mark[0])
);

initial begin //初始化
    loc_x<=0;
    loc_y<=0;
    Stair_state<=0;
end

endmodule