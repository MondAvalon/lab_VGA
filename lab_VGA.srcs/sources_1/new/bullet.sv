module bullet #(
    parameter ADDR_WIDTH = 15,
    parameter signed V_SPEED = -4,  //子弹速度
    parameter H_LENGTH = 200,  //画布宽度
    parameter V_LENGTH = 150  //画布高度
) (
    input clk,
    input frame_clk,
    input rstn,
    input [$clog2(H_LENGTH)-1:0] player_x,  //玩家位置
    input [$clog2(H_LENGTH)-1:0] player_y,
    input [$clog2(H_LENGTH)-1:0] enemy_x,  //敌人位置
    input [$clog2(H_LENGTH)-1:0] enemy_y,
    input shoot,  //是否发射子弹
    input collision,  //是否碰撞
    input enable,
    input index,  //子弹编号

    output [$clog2(H_LENGTH)-1:0] x_out,  //子弹位置
    output [$clog2(H_LENGTH)-1:0] y_out,
    output display  //子弹是否存在
);
  localparam X_WHITH = 9;  //物体宽
  localparam Y_WHITH = 24;  //物体长
  localparam MAX_BULLET = 5;  //最大子弹数

  reg [$clog2(H_LENGTH)-1:0] x[MAX_BULLET];  //子弹位置
  reg [$clog2(H_LENGTH)-1:0] y[MAX_BULLET];
  reg display_buf[MAX_BULLET];  //子弹是否存在

  assign x_out   = x[index];
  assign y_out   = y[index];
  assign display = display_buf[index];

  always @(posedge clk) begin
    if (~rstn) begin
      for (int i = 0; i < MAX_BULLET; i = i + 1) begin
        x[i] <= 0;
        y[i] <= 0;
        display_buf[i] <= 0;
      end
    end else begin
      if (enable) begin
        if (shoot) begin
          display_buf[index] <= 1;
          x[index] <= player_x + X_WHITH / 2;
          y[index] <= player_y;
        end
        if (display_buf[index]) begin
          y[index] <= y[index] + V_SPEED;
          if (y[index] < 0) begin
            display_buf[index] <= 0;
          end
        end
      end
    end
  end


endmodule
