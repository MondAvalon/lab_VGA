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

    output reg [18:0] Stair_state //特定台阶编号的台阶状态 
); 
wire [7:0] count_y;
wire [6:0] find;
wire [3:0] count;  // 计数器
reg  [3:0] state [18:0];// state[00,H_LENGTH,V_LENGTH] 状态数组，定义一共16块台阶的状态和坐标，“00”表示空闲，“01”第一类台阶，以此类推

// 在每个frame_clk上升沿更新台阶状态
always @(posedge frame_clk) begin
    if (rstn) begin
        
    end
    if (count_y == 0) begin  // 计数器为零，y轴移动
        
        Stair_state <= state;
    end
end

Counter #(4, 31) counter_y (// 每个clk计数器减1
  .clk       (frame_clk),
  .rstn      (rstn),
  .load_value(n - 1),
  .enable    (enable_scroll),
  .count     (count_y)
);

always @(posedge_clk) begin //遍历各台阶状态
    
end

initial begin //初始化
    state <= 0;
end
endmodule
