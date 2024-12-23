//module Collision_ #(  //player交互
//    parameter ADDR_WIDTH = 15,
//    parameter X_WHITH = 30,  //物体款宽
//    parameter Y_WHITH = 36,  //物体高
//    parameter STAIR_X = 30,  //台阶宽
//    parameter STAIR_Y = 4,   //台阶高
//    parameter MOB_X = 70,  //敌机宽
//    parameter MOB_Y = 20,  //敌机高
//    parameter H_LENGTH  = 200, //宽度
//    parameter V_LENGTH  = 150  //高度
//)(
//    input clk,
//    input frame_clk,
//    input rstn,

//    input [5:0] num, //状态编号[5:0], [1:0]表示碰撞的种类(到时候用clk遍历)，[3:0]对应可碰台阶的编号

//    input [$clog2(H_LENGTH)-1:0] player_x, //player
//    input [$clog2(V_LENGTH)-1:0] player_y, 
//    input [$clog2(V_LENGTH)-1:0] Speed_y,
    
//    output [2:0]  collision//"1XX"表示触底或碰到敌机失败，"011"表示加速台阶，"010"表示正常碰到台阶反弹，"00X"表示不碰撞
//);
reg [$clog2(H_LENGTH)-1:0] stair_x;
reg [$clog2(V_LENGTH)-1:0] stair_y;
reg [3:0] count_co ;  //用来遍历台阶的，输入stair模块中使用，返回在stair_x、stair_y上
reg [1:0] Stair_state;

reg [$clog2(H_LENGTH)-1:0] mob_x;
reg [$clog2(V_LENGTH)-1:0] mob_y;

reg  [$clog2(H_LENGTH)-1:0] player_x;
reg  [$clog2(V_LENGTH)-1:0] player_y;
reg  signed [$clog2(V_LENGTH)-1:0] Speed_y;
reg  [2:0]  collision//"1XX"表示触底或碰到敌机失败，"010"表示加速台阶，"011"表示正常碰到台阶反弹，"00X"表示不碰撞

always @(posedge frame_clk) begin //敌机逻辑
    collision <= 0;
    if (((player_y+Y_WHITH/2)==(mob_y-MOB_Y))&&((player_x-X_WHITH/2)==(mob_x+MOB_X))) begin //敌机逻辑左上
        collision [2] <= 1;
    end
    if (((player_y+Y_WHITH/2)==(mob_y-MOB_Y))&&((player_x+X_WHITH/2)==(mob_x-MOB_X))) begin //敌机逻辑右上
        collision [2] <= 1;
    end
    if (((player_y-Y_WHITH/2)==(mob_y+MOB_Y))&&((player_x-X_WHITH/2)==(mob_x+MOB_X))) begin //敌机逻辑左下
        collision [2] <= 1;
    end
    if (((player_y-Y_WHITH/2)==(mob_y+MOB_Y))&&((player_x+X_WHITH/2)==(mob_x-MOB_X))) begin //敌机逻辑右下
        collision [2] <= 1;
    end
    if (player_y == (V_LENGTH-15)) begin //触底逻辑
        collision [2] <= 1;
    end
end

always @(posedge clk) begin //台阶遍历
    if (Speed_y > 0) begin
        if (((player_y+Y_WHITH/2)==(stair_y-STAIR_Y))) begin
            if (((player_x+X_WHITH/2)>(stair_x-STAIR_X))&&((player_x-X_WHITH/2)<(stair_x+STAIR_X))) begin
                if (Stair_state == 2'b10) begin //判断台阶种类，目前只有一种特殊台阶
                    collision [0] <= 2'b11;
                end 
                else if (Stair_state == 2'b01) begin
                    collision [0] <= 2'b10;
                end
            end
        end
    end
end

Counter #(4, 31) counter_collision (// 每个clk计数器减1,用于遍历16个台阶
  .clk       (clk),
  .rstn      (rstn),
  .load_value(1000),
  .enable    (1),
  .count     (count_co)
);

initial begin        //初始化
    count_co <= 0;
    collision <= 0;
end

endmodule