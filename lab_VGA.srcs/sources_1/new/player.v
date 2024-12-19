// 自机模块
module Player #(
    parameter ADDR_WIDTH = 15,
    parameter BUNCE_V = -5,  //回弹初速度
    parameter G_CONST = 1,  //重力加速度
    parameter X_WHITH = 30,  //物体宽
    parameter Y_WHITH = 36,  //物体长
    parameter H_LENGTH  = 200,
    parameter V_LENGTH  = 150
)(
    input clk,
    input frame_clk,
    input rstn,
    input [ADDR_WIDTH-1:0] addr,
    input [127:0] key_state,
    input collision,
    input [7:0] n,         // 每n个frame_clk更新一次offset，图片向下滚动速度为每秒72/n个像素,即刷新率

    output reg [11:0] rgb

    );
reg  [7:0] speed_x; 
reg  [7:0] speed_y;
reg  [ADDR_WIDTH-1:0] offset; 
wire [7:0] count_x;  // 计数器
wire [7:0] count_y;  // 计数器

// 在每个frame_clk上升沿更新计数器和偏移量
always @(posedge frame_clk) begin
    if (!rstn) begin
      offset <= 60;
    end 
    else begin
      if (count_y == 0&&enable_scroll) begin  // 当计数达到0时，更新offset
        offset <= (offset + H_LENGTH) % (H_LENGTH * V_LENGTH);
      end
      if (count_x == 0&&enable_scroll) begin  
        offset <= (offset + V_LENGTH) % (H_LENGTH * V_LENGTH);
      end
    end
end

//更新当前x方向速度，根据键盘输入key_state确定左右
always @(posedge frame_clk) begin
    speed_x <= 0;
    if (key_state[1]) begin//键盘输入（具体输入信号未完成）
        speed_x <= 10;
    end
    else if (key_state[0]) begin
        speed_x <= -10;
    end
end

//更新当前y方向速度，根据collision确定碰撞
always @(posedge frame_clk) begin
    speed_y <= speed_y + G_CONST;
    if (collision) begin
        speed_y <= BUNCE_V;
    end
end

Counter #(8, 255) counter_x (// 每个frame_clk计数器减1
  .clk       (frame_clk),
  .rstn      (rstn),
  .load_value(n - speed_x),
  .enable    (enable_scroll),
  .count     (count_x)
);

Counter #(8, 255) counter_y (// 每个frame_clk计数器减1
  .clk       (frame_clk),
  .rstn      (rstn),
  .load_value(n - speed_y),
  .enable    (enable_scroll),
  .count     (count_y)
);


//显示模块
Rom replay (

);

initial begin
    offset <= 60;
  end

endmodule
