module Bullet #(
    parameter ADDR_WIDTH = 15,
    parameter signed V_SPEED = -4,  //子弹速度
    parameter H_LENGTH = 200,  //画布宽度
    parameter V_LENGTH = 150,  //画布高度
    parameter MAX_BULLET = 5,  //最大子弹数
    parameter COLLISION_THRESHOLD = 21  // 曼哈顿距离碰撞阈值
) (
    input clk,
    input frame_clk,
    input rstn,
    input [$clog2(H_LENGTH)-1:0] player_x,  //玩家位置
    input [$clog2(H_LENGTH)-1:0] player_y,
    input [$clog2(H_LENGTH)-1:0] enemy_x,  //敌人位置
    input [$clog2(H_LENGTH)-1:0] enemy_y,
    input shoot,  //是否发射子弹
    input enable,
    input [7:0] n_count,
    input [$clog2(MAX_BULLET)-1:0] lookup_i,  //子弹编号

    output [$clog2(H_LENGTH)-1:0] x_out,  //子弹中心坐标
    output [$clog2(H_LENGTH)-1:0] y_out,
    output display_out,  //子弹是否存在
    output reg [$clog2(MAX_BULLET)-1:0] collision  //是否碰撞
);
  //   localparam X_WHITH = 9;  //物体宽
  //   localparam Y_WHITH = 24;  //物体长


  //   reg [$clog2(H_LENGTH)-1:0] x           [MAX_BULLET];  //子弹中心坐标
  //   reg [$clog2(H_LENGTH)-1:0] y           [MAX_BULLET];
  //   reg                        display     [MAX_BULLET];  //子弹是否存在

  reg [$clog2(H_LENGTH)-1:0] x      [MAX_BULLET];
  reg [$clog2(H_LENGTH)-1:0] y      [MAX_BULLET];
  reg                        display[MAX_BULLET];

  assign x_out = x[lookup_i];
  assign y_out = y[lookup_i];
  assign display_out = display[lookup_i];

  //   always @(posedge frame_clk) begin
  //     if (!rstn) begin
  //       for (int i = 0; i < MAX_BULLET; i = i + 1) begin
  //         x[i] <= 0;
  //         y[i] <= 0;
  //         display[i] <= 0;
  //       end
  //     end else begin
  //       for (int i = 0; i < MAX_BULLET; i = i + 1) begin
  //         x[i] <= x[i];
  //         y[i] <= y[i];
  //         display[i] <= display[i];
  //       end
  //     end
  //   end

  always @(posedge frame_clk) begin
    for (int i = 0; i < MAX_BULLET; i = i + 1) begin
      x[i] <= x[i];
      y[i] <= y[i];
      display[i] <= display[i];
      collision[i] <= 0;

      // 使用曼哈顿距离检测碰撞
      if (display[i]) begin
        if (((x[i] > enemy_x ? x[i] - enemy_x : enemy_x - x[i]) + 
             (y[i] > enemy_y ? y[i] - enemy_y : enemy_y - y[i])) <= COLLISION_THRESHOLD) begin
          display[i]   <= 0;  // 发生碰撞,子弹消失
          collision[i] <= 1;
        end
      end
    end

    if (enable && shoot) begin
      for (int i = 0; i < MAX_BULLET; i = i + 1) begin
        if (!display[i]) begin
          x[i] <= player_x;
          y[i] <= player_y;
          display[i] <= 1;
          break;
        end
      end
    end
  end

  always @(posedge frame_clk) begin
    if (!rstn) begin
      for (int i = 0; i < MAX_BULLET; i = i + 1) begin
        y[i] <= 0;
      end
    end else begin
      for (int i = 0; i < MAX_BULLET; i = i + 1) begin
        if (display[i]) begin
          y[i] <= y[i] + V_SPEED;
        end
      end
    end
  end

  initial begin
    for (int i = 0; i < MAX_BULLET; i = i + 1) begin
      x[i] = 0;
      y[i] = 0;
      display[i] = 0;
    end
  end

endmodule
