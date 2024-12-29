`timescale 1ns/1ps
// 台阶模块,提供特定位置台阶的查询
module Stairs#(
    parameter H_LENGTH  = 200, //宽度
    parameter V_LENGTH  = 150,  //高度
    parameter MAX_STAIR = 10
)(
    input clk,
    input frame_clk,
    input rstn,
    input [1:0] game_state,
    input enable_scroll,   //借用一下，实现暂停功能
    input [7:0] n,         // 每n个frame_clk更新一次offset，图片向下滚动速度为每秒72/n个像素,即刷新率
    input signed [$clog2(V_LENGTH)-1:0] v,

    output [$clog2(H_LENGTH)-1:0] state_x [MAX_STAIR], //x位置
    output [$clog2(V_LENGTH)-1:0] state_y [MAX_STAIR],  //y位置
    output [1:0]               state_mark [MAX_STAIR]
); 

genvar i;
generate
    for (i = 0; i < MAX_STAIR; i++) begin : single_stairs
        SingleStair #(
            .NUM(i)
        ) single (
            .clk(clk),
            .frame_clk(frame_clk),
            .rstn(rstn),
            .game_state(game_state),
            .n(n),
            .v(v),
            .enable_scroll(enable_scroll),
            .loc_x(state_x[i]),
            .loc_y(state_y[i]),
            .mark(state_mark[i])
        );
    end
endgenerate

endmodule