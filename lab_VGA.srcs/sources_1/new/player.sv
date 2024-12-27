// 自机模块
module Player #(
    parameter ADDR_WIDTH = 15,
    parameter DIV_Y = 60,
    parameter SPEED_X = 4,
    parameter signed BUNCE_V = -22,  //回弹初速度
    // parameter G_CONST = 1,  //重力加速度
    parameter addr_x = 100,  //输入起始中心x坐标
    parameter addr_y = 60,  //输入起始中心y坐标
    parameter H_LENGTH = 200,  //宽度
    parameter V_LENGTH = 150  //高度
) (
    input clk,
    input frame_clk,
    input rstn,
    // input [127:0] key_state,
    input left,
    input right,
    input shoot,
    input enable_scroll,  //借用一下，实现暂停功能
    input [2:0] collision,  //碰撞信号
    input [7:0] n_count,         // 每n个frame_clk更新一次offset，物体向下滚动速度为每秒72/n个像素,即刷新率

    output reg [$clog2(H_LENGTH)-1:0] loc_x,  //x位置
    output [$clog2(V_LENGTH)-1:0] loc_y,  //y位置
    output reg [1:0] player_anime_state,  //玩家动画状态
    output reg signed [$clog2(V_LENGTH):0] speed_y,  //相对背景的y速度
    output signed [$clog2(V_LENGTH):0] speed_y_out  //相对屏幕的y速度
);
  localparam X_WHITH = 30;  //物体宽
  localparam Y_WHITH = 36;  //物体长

  reg arrow_x;  //判断左右移动方向，取1为右，0为左
  reg [3:0] speed_x;
  reg [4:0] ani_count = 0;  //计数器
  reg [1:0] ani_state_buf;
  reg signed [$clog2(V_LENGTH):0] signed_loc_y;
  assign loc_y = signed_loc_y[$clog2(V_LENGTH)] ? 0 : signed_loc_y[$clog2(V_LENGTH)-1:0];

  assign speed_y_out = (speed_y[$clog2(V_LENGTH)] && signed_loc_y < DIV_Y) ? 0 : speed_y;
  // 在每个frame_clk上升沿更新计数器和偏移量
  always @(posedge frame_clk) begin
    if (!rstn) begin
      loc_x <= addr_x;
      signed_loc_y <= addr_y;
      //   Speed_y <= 0;
      player_anime_state <= 0;
    end else begin
      if (!n_count) begin  // 计数器为零，移动
        signed_loc_y <= signed_loc_y + (speed_y_out >>> 1);

        if (arrow_x) begin
          if (loc_x > (H_LENGTH - 20)) begin
            loc_x <= 20;
          end else begin
            loc_x <= (loc_x + speed_x);
          end
        end else begin
          if (loc_x < 20) begin
            loc_x <= (H_LENGTH - 20);
          end else begin
            loc_x <= (loc_x - speed_x);
          end
        end
        // Speed_y <= speed_y;
      end

      if (shoot) begin
        player_anime_state <= 3;
      end else if (!ani_count) begin
        case (ani_state_buf)
          0: begin
            player_anime_state <= 0;
            ani_state_buf <= 1;
          end
          1: begin
            player_anime_state <= 1;
            ani_state_buf <= 2;
          end
          2: begin
            player_anime_state <= 2;
            ani_state_buf <= 3;
          end
          3: begin
            player_anime_state <= 1;
            ani_state_buf <= 0;
          end
        endcase
      end
    end
  end

  always @(posedge frame_clk) begin
    if (!rstn) begin
      ani_count <= 0;
    end else begin
      ani_count <= ani_count == 30 ? 0 : ani_count + 1;
    end
  end

  //更新当前x方向速度，根据键盘输入key_state确定左右
  always @(posedge frame_clk) begin
    if (!rstn) begin
      speed_x <= 0;
      arrow_x <= 0;
    end else begin
      speed_x <= 0;
      if (right) begin  //键盘输入
        speed_x <= SPEED_X;
        arrow_x <= 1;
      end else if (left) begin
        speed_x <= SPEED_X;
        arrow_x <= 0;
      end
    end
  end

  //更新当前y方向速度，根据collision确定碰撞
  always @(posedge frame_clk) begin
    if (!rstn) begin
      speed_y <= 0;
    end else begin
      if ((collision[1] || (signed_loc_y > V_LENGTH - 20)) && speed_y > 0) begin
        // speed_y <= -speed_y;
        speed_y <= BUNCE_V;
      end else if (!n_count) begin
        if (speed_y == 14) begin
          speed_y <= speed_y;
        end else begin
          speed_y <= speed_y + 1;
        end
      end
    end
  end

  initial begin  //初始化
    loc_x <= addr_x;
    signed_loc_y <= addr_y;
    arrow_x <= 0;
    speed_x <= 0;
    speed_y <= 0;
    player_anime_state <= 0;
    // Speed_y <= 0;
  end

endmodule
