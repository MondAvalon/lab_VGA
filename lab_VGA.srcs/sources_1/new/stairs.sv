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
    output reg [$clog2(H_LENGTH)-1:0] loc_x, //x位置
    output reg [$clog2(V_LENGTH)-1:0] loc_y  //y位置
); 
wire [3:0] count_1;
wire [6:0] num;
wire [3:0] count;  // 计数器
wire [$clog2(H_LENGTH)-1:0] state_x [3:0];  // state[00,$clog2(H_LENGTH)-1,$clog2(V_LENGTH)-1] 状态数组，定义一共16块台阶的状态和坐标，“00”表示空闲，“01”第一类台阶，以此类推
wire [$clog2(V_LENGTH)-1:0] state_y [3:0];
wire [1:0] state_mark [3:0];

always @(posedge clk) begin
    loc_x<=state_x[loc];
    loc_y<=state_y[loc];
    Stair_state<=state_mark[loc];
end

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

SingleStair single1 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(1),
    .loc_x(state_x[1]),
    .loc_y(state_y[1]),
    .mark(state_mark[1])
);

SingleStair single2 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(2),
    .loc_x(state_x[2]),
    .loc_y(state_y[2]),
    .mark(state_mark[2])
);

SingleStair single3 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(3),
    .loc_x(state_x[3]),
    .loc_y(state_y[3]),
    .mark(state_mark[3])
);

SingleStair single4 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(4),
    .loc_x(state_x[4]),
    .loc_y(state_y[4]),
    .mark(state_mark[4])
);

SingleStair single5 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(5),
    .loc_x(state_x[5]),
    .loc_y(state_y[5]),
    .mark(state_mark[5])
);

SingleStair single6 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(6),
    .loc_x(state_x[6]),
    .loc_y(state_y[6]),
    .mark(state_mark[6])
);

SingleStair single7 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(7),
    .loc_x(state_x[7]),
    .loc_y(state_y[7]),
    .mark(state_mark[7])
);

SingleStair single8 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(8),
    .loc_x(state_x[8]),
    .loc_y(state_y[8]),
    .mark(state_mark[8])
);

SingleStair single9 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(9),
    .loc_x(state_x[9]),
    .loc_y(state_y[9]),
    .mark(state_mark[9])
);

SingleStair single10 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(10),
    .loc_x(state_x[10]),
    .loc_y(state_y[10]),
    .mark(state_mark[10])
);

SingleStair single11 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(11),
    .loc_x(state_x[11]),
    .loc_y(state_y[11]),
    .mark(state_mark[11])
);

SingleStair single12 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(12),
    .loc_x(state_x[12]),
    .loc_y(state_y[12]),
    .mark(state_mark[12])
);

SingleStair single13 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(13),
    .loc_x(state_x[13]),
    .loc_y(state_y[13]),
    .mark(state_mark[13])
);

SingleStair single14 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(14),
    .loc_x(state_x[14]),
    .loc_y(state_y[14]),
    .mark(state_mark[14])
);

SingleStair single15 (
    .clk(clk),
    .frame_clk(frame_clk),
    .enable_scroll(enable_scroll),
    .n(n),
    .num(15),
    .loc_x(state_x[15]),
    .loc_y(state_y[15]),
    .mark(state_mark[15])
);


initial begin //初始化
    loc_x<=0;
    loc_y<=0;
    Stair_state<=0;
end

endmodule