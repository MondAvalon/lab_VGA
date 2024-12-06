// 检测sync_in信号的上升沿，并输出一个同步脉冲
module PulseSync #(
    parameter WIDTH = 1
) (
    input  sync_in,
    input  clk,
    output pulse_out
);
  reg sync_in_d;

  always @(posedge clk) begin
    sync_in_d <= sync_in;
  end

  assign pulse_out = sync_in & ~sync_in_d;  // 检测sync_in的上升沿
endmodule

//实现显示数据处理功能，将画布与显示屏适配，从而产生色彩信息。
//DisplayDataProcessor和DisplaySyncTiming共同构成DisplayUnit显示单元
module DisplayDataProcessor #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
) (
    input        h_enable,  //水平显示使能
    input        v_enable,  //垂直显示使能  
    input        rstn,      //复位信号,低有效
    input        pclk,      //像素时钟
    input [11:0] read_data, //读取的像素数据

    output reg [          11:0] rgb_out,   //RGB输出
    output reg [ADDR_WIDTH-1:0] read_addr  //读地址
);

  localparam total_pixels = H_LENGTH * V_LENGTH;  // 总像素数

  reg [1:0] scale_x;  //水平方向4倍缩放计数
  reg [1:0] scale_y;  //垂直方向4倍缩放计数
  reg [1:0] next_scale_x;
  reg [1:0] next_scale_y;

  always @(*) begin
    scale_x = next_scale_x;
    scale_y = next_scale_y;
  end

  wire pixel_end;  //像素结束标志

  PulseSync #(1) ps (  //取enable下降沿
      .sync_in  (~(h_enable & v_enable)),
      .clk      (pclk),
      .pulse_out(pixel_end)
  );

  always @(posedge pclk) begin  //可能慢一个周期，改h_enable,v_enable即可
    if (!rstn) begin
      next_scale_x <= 0;
      next_scale_y <= 3;
      rgb_out <= 0;
      read_addr <= 0;
    end else if (h_enable && v_enable) begin
      rgb_out <= read_data;  // 直接显示当前像素数据
      if (scale_x == 2'b11) begin
        read_addr <= read_addr + 1;
      end
      next_scale_x <= scale_x + 1;
    end else if (pixel_end) begin  //enable下降沿
      rgb_out <= 0;

      if (scale_y != 2'b11) begin
        read_addr <= read_addr - H_LENGTH;
      end else if (read_addr == total_pixels) begin
        read_addr <= 0;
      end

      next_scale_y <= scale_y + 1;
    end else rgb_out <= 0;
  end
endmodule
