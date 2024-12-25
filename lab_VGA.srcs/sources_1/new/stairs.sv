`timescale 1ns/1ps
// 台阶模块,提供特定位置台阶的查询
module Stairs#(
    parameter H_LENGTH  = 200, //宽度
    parameter V_LENGTH  = 150  //高度
)(
    input clk,
    input frame_clk,
    input rstn,
    // input [3:0] loc,        //台阶编号
    input enable_scroll,   //借用一下，实现暂停功能
    input [7:0] n,         // 每n个frame_clk更新一次offset，图片向下滚动速度为每秒72/n个像素,即刷新率

    // output reg [1:0] Stair_state, //特定台阶编号的台阶状态
    // output reg [$clog2(H_LENGTH)-1:0] loc_x, //x位置
    // output reg [$clog2(V_LENGTH)-1:0] loc_y  //y位置
    output [$clog2(H_LENGTH)-1:0] state_x [16], //x位置
    output [$clog2(V_LENGTH)-1:0] state_y [16],  //y位置
    output [1:0]               state_mark [16]
); 
// wire [$clog2(H_LENGTH)-1:0] state_x [3:0];  // state[00,$clog2(H_LENGTH)-1,$clog2(V_LENGTH)-1] 状态数组，定义一共16块台阶的状态和坐标，“00”表示空闲，“01”第一类台阶，以此类推
// wire [$clog2(V_LENGTH)-1:0] state_y [3:0];
// wire [1:0] state_mark [3:0];

// always @(*) begin
//     loc_x=state_x[loc];
//     loc_y=state_y[loc];
//     Stair_state=state_mark[loc];
// end

genvar i;
generate
    for (i = 0; i < 16; i++) begin : single_stairs
        SingleStair #(
            .NUM(i)
        ) single (
            .clk(clk),
            .frame_clk(frame_clk),
            .rstn(rstn),
            .n(n),
            .enable_scroll(enable_scroll),
            .loc_x(state_x[i]),
            .loc_y(state_y[i]),
            .mark(state_mark[i])
        );
    end
endgenerate

endmodule