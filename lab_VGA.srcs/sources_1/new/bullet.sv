module Bullet #(
    parameter ADDR_WIDTH = 15,
    parameter signed V_SPEED = 3,  //子弹速度
    parameter H_LENGTH = 200,  //画布宽度
    parameter V_LENGTH = 150,  //画布高度
    parameter MAX_BULLET = 5,  //最大子弹数
    parameter COLLISION_THRESHOLD = 20  // 曼哈顿距离碰撞阈值
) (
    input clk,
    input frame_clk,
    input rstn,
    input [$clog2(H_LENGTH)-1:0] player_x,  //玩家位置
    input [$clog2(V_LENGTH)-1:0] player_y,
    input [$clog2(H_LENGTH)-1:0] enemy_x,  //敌人位置
    input [$clog2(V_LENGTH)-1:0] enemy_y,
    input shoot,  //是否发射子弹
    // input enable,
    input [7:0] n_count,
    // input [$clog2(MAX_BULLET)-1:0] lookup_i,  //子弹编号

    // output [$clog2(H_LENGTH)-1:0] x_out,  //子弹中心坐标
    // output [$clog2(H_LENGTH)-1:0] y_out,
    // output display_out,  //子弹是否存在
    output reg [$clog2(H_LENGTH)-1:0] x        [MAX_BULLET],
    output reg [$clog2(V_LENGTH)-1:0] y        [MAX_BULLET],
    output reg                        display  [MAX_BULLET],
    output reg                        collision               //是否碰撞
);



  // assign x_out = x[lookup_i];
  // assign y_out = y[lookup_i];
  // assign display_out = display[lookup_i];
  // assign x_out = 100;
  // assign y_out = 50;
  // assign display_out = 1;

  reg [7:0] shoot_cd;

  always_ff @(posedge frame_clk) begin
    if (!rstn) begin
      shoot_cd  <= 0;
      collision <= 0;
      for (int i = 0; i < MAX_BULLET; i = i + 1) begin
        x[i] <= 0;
        y[i] <= 0;
        display[i] <= 0;
      end
    end else begin
      // 冷却时间更新
      if (shoot_cd > 0) shoot_cd <= shoot_cd - 1;
      else if (shoot) shoot_cd <= 25;

      // 重置碰撞状态
      collision <= 0;

      // 子弹状态更新
      for (int i = 0; i < MAX_BULLET; i = i + 1) begin
        if (display[i]) begin
          // 更新位置
          y[i] <= n_count ? y[i] : y[i] - V_SPEED;  //n_count为0时更新位置

          // 碰撞检测和边界检测
          if (y[i] < 10 || ((x[i] > enemy_x ? x[i] - enemy_x : enemy_x - x[i]) + 
                       (y[i] > enemy_y ? y[i] - enemy_y : enemy_y - y[i])) <= COLLISION_THRESHOLD) begin
            display[i] <= 0;
            if ((x[i] > enemy_x ? x[i] - enemy_x : enemy_x - x[i]) + 
                           (y[i] > enemy_y ? y[i] - enemy_y : enemy_y - y[i]) <= COLLISION_THRESHOLD) begin
              collision <= 1;
            end
          end
        end
      end

      // 发射新子弹
      if (shoot && !shoot_cd) begin
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
  end

  //   initial begin
  //     for (int i = 0; i < MAX_BULLET; i = i + 1) begin
  //       x[i] = 0;
  //       y[i] = 0;
  //       display[i] = 0;
  //       collision = 0;
  //     end
  //   end

endmodule
