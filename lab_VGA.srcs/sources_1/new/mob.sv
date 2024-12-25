// 敌机模块
module Mob #(
    parameter SPEED_X  = 1,
    parameter H_LENGTH = 200,  //宽度
    parameter V_LENGTH = 150   //高度
) (
    input clk,
    input frame_clk,
    input rstn,
    input enable_scroll,  //借用一下，实现暂停功能
    input [7:0] n_count,         // 每n个frame_clk更新一次offset，图片向下滚动速度为每秒72/n个像素,即刷新率
    input bullet_collision,  //碰撞信号

    output reg [$clog2(H_LENGTH)-1:0] loc_x,  //x位置
    output reg [$clog2(V_LENGTH)-1:0] loc_y,  //y位置
    output reg [9:0] HP,  //生命值
    output reg display
);
  reg arrow;  //判断左右移动方向

  // 在每个frame_clk上升沿更新计数器和偏移量
  always @(posedge frame_clk) begin
    if (!n_count) begin  // 计数器为零,移动
      // loc_y <= loc_y + 1;

      if (arrow) begin
        if (loc_x > (H_LENGTH - 20)) begin
          loc_x <= H_LENGTH - 20;
          arrow <= 0;
        end else begin
          loc_x <= loc_x + SPEED_X;
          arrow <= 1;
        end
      end else begin
        if (loc_x < 20) begin
          loc_x <= 20;
          arrow <= 1;
        end else begin
          loc_x <= loc_x - SPEED_X;
          arrow <= 0;
        end
      end
    end
  end

  // always @(posedge frame_clk) begin //触左右壁、触底
  //     if (loc_y == ($clog2(V_LENGTH)-1)) begin
  //         finish <= 1;
  //     end
  //     if ((loc_x == $clog2(H_LENGTH)-1) || (loc_x == 1)) begin
  //         arrow <= ~arrow;
  //     end
  // end

  initial begin  //初始化
    loc_x <= 100;
    loc_y <= 19;
    arrow <= 0;
    HP <= 10'd1023;
  end
endmodule
