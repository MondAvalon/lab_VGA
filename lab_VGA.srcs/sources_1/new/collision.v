module Collision #(  //player交互
    parameter ADDR_WIDTH = 15,
    parameter X_WHITH = 30,  //物体宽
    parameter Y_WHITH = 36,  //物体长
    parameter H_LENGTH  = 200, //宽度
    parameter V_LENGTH  = 150,  //高度
)(
    input clk,
    input frame_clk,
    input rstn,

    input [$clog2(H_LENGTH)-1:0] player_x, //player
    input [$clog2(V_LENGTH)-1:0] player_y, 
    input [$clog2(V_LENGTH)-1:0] Speed_y,
    
    output [1:0]  collision//"11"表示触底，"10"表示碰到敌机，"01"表示正常碰到台阶反弹，"00"表示不碰撞
);
reg [3:0] count;
wire [$clog2(H_LENGTH)-1:0] stair_x;
wire [$clog2(V_LENGTH)-1:0] stair_y; 

always @(posedge clk) begin //
     
end

always @(posedge frame_clk) begin

end

Counter #(4, 31) counter_y (// 每个clk计数器减1
  .clk       (clk),
  .rstn      (rstn),
  .load_value(1000),
  .enable    (1),
  .count     (count)
);

Stairs stair (

);

initial begin        //初始化
    count <= 0;
    stair_x <= 0;
    stair_y <= 0;
end

endmodule