// 敌机模块
module Mob #(
    parameter SPEED_X = 2,
    parameter H_LENGTH  = 200, //宽度
    parameter V_LENGTH  = 150  //高度
)(
    input clk,
    input frame_clk,
    input enable_scroll,    //借用一下，实现暂停功能
    input [7:0] n,         // 每n个frame_clk更新一次offset，图片向下滚动速度为每秒72/n个像素,即刷新率

    output reg [H_LENGTH-1:0] loc_x, //x位置
    output reg [V_LENGTH-1:0] loc_y,  //y位置
    output reg finish //触底信号
);
reg  arrow; //判断左右移动方向，取1为左,取0为右 
wire [7:0] count_x;  // 计数器
wire [7:0] count_y;  // 计数器

// 在每个frame_clk上升沿更新计数器和偏移量
always @(posedge frame_clk) begin
    if (count_y == 0) begin  // 计数器为零，y轴移动
        loc_y <= loc_y + 1;
    end
    if (count_x == 0) begin  // 计数器为零，x轴移动
        if (arrow) begin
            loc_x <= loc_x + SPEED_X;
        end
        else begin
            loc_x <= loc_x - SPEED_X;
        end
    end
end

always @(posedge frame_clk) begin //触左右壁、触底
    if (loc_y == (V_LENGTH-1)) begin
        finish <= 1;
    end
    if ((loc_x == H_LENGTH-1) || (loc_x == 1)) begin
        arrow <= ~arrow;
    end
end

Counter #(8, 255) counter_x (// 每个frame_clk计数器减1
  .clk       (frame_clk),
  .rstn      (rstn),
  .load_value(n - 1),
  .enable    (enable_scroll),
  .count     (count_x)
);

Counter #(8, 255) counter_y (// 每个frame_clk计数器减1
  .clk       (frame_clk),
  .rstn      (rstn),
  .load_value(n - 1),
  .enable    (enable_scroll),
  .count     (count_y)
);

initial begin //初始化
    loc_x <= (100 + $random % 70);
    loc_y <= 0;
    arrow <= 0;
    finish <= 0;
end
endmodule
