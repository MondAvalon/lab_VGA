// 自机模块
module Player #(
    parameter ADDR_WIDTH = 15,
    parameter SPEED_X = 2,
    parameter signed BUNCE_V = -3,  //回弹初速度
    parameter G_CONST = 1,  //重力加速度
    parameter addr_x = 100,  //输入起始中心x坐标
    parameter addr_y = 75,  //输入起始中心y坐标
    parameter H_LENGTH  = 200, //宽度
    parameter V_LENGTH  = 150  //高度
)(
    input clk,
    input frame_clk,
    input rstn,
    input [127:0] key_state,
    input enable_scroll,    //借用一下，实现暂停功能
    input [2:0] collision ,       //碰撞信号
    input [7:0] n_count,         // 每n个frame_clk更新一次offset，物体向下滚动速度为每秒72/n个像素,即刷新率

    output reg [$clog2(H_LENGTH)-1:0] loc_x, //x位置
    output reg [$clog2(V_LENGTH)-1:0] loc_y,  //y位置
    output reg [1:0] player_anime_state, //玩家动画状态
    output reg [$clog2(V_LENGTH)-1:0] Speed_y
);
parameter X_WHITH = 30;  //物体宽
parameter Y_WHITH = 36;  //物体长

reg  arrow; //判断左右移动方向，取1为左,取0为右
reg  [3:0] speed_x;
reg signed [$clog2(V_LENGTH)-1:0] speed_y;
// wire [7:0] count; //计数器

// 在每个frame_clk上升沿更新计数器和偏移量
always @(posedge frame_clk) begin
    if (!rstn) begin
        loc_x <= addr_x;
        loc_y <= addr_y;
        Speed_y <= 0;
        arrow <= 0;
        speed_x <= 0;
        speed_y <= 0;
        player_anime_state <= 0;
    end 
    else begin
      if (n_count == 0) begin  // 计数器为零，移动
        loc_y <= loc_y + speed_y;
      
      
        if (arrow) begin
            loc_x <= (loc_x + speed_x) % H_LENGTH;
        end
        else begin
            loc_x <= (loc_x - speed_x) % H_LENGTH;
        end
        Speed_y <= speed_y;
      end
    end
end

//更新当前x方向速度，根据键盘输入key_state确定左右
always @(posedge frame_clk) begin
    speed_x <= 0;
    if (key_state[1]) begin//键盘输入（具体输入信号未完成）
        speed_x <= SPEED_X;
        arrow <= 1;
    end
    else if (key_state[0]) begin
        speed_x <= SPEED_X;
        arrow <= 0;
    end
end

//更新当前y方向速度，根据collision确定碰撞
always @(posedge frame_clk) begin
    if ((collision[1] == 1'b1)|| (loc_y>V_LENGTH-16 && ~speed_y[$clog2(V_LENGTH)-1])) begin
        speed_y <= -speed_y;
    end else if(n_count == 0) begin
        if (speed_y == 10) begin
            speed_y <= speed_y;
        end else begin
            speed_y <= speed_y + G_CONST;
        end
    end
end

// Counter #(8, 255) counter (// 每个frame_clk计数器减1
//   .clk       (frame_clk),
//   .rstn      (rstn),
//   .load_value(n - 1),
//   .enable    (enable_scroll),
//   .count     (count)
// );


initial begin //初始化
    loc_x <= addr_x;
    loc_y <= addr_y;
    arrow <= 0;
    speed_x <= 0;
    speed_y <= 0;
    player_anime_state <= 0;
    Speed_y <= 0;
end

endmodule
