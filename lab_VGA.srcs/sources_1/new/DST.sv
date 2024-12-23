// 递减计数器模块
module Counter #(
    parameter WIDTH       = 16,
    parameter RESET_VALUE = 0
) (
    input [    0 : 0] clk,
    input [    0 : 0] rstn,        //复位使能
    input [WIDTH-1:0] load_value,  //置数
    input [    0 : 0] enable,      //计数使能信号

    output reg [WIDTH-1:0] count  //计数输出
);
  always @(posedge clk) begin
    if (!rstn) count <= RESET_VALUE;
    else if (enable) begin
      if (count == 0) count <= load_value;
      else count <= count - 1;
    end else count <= count;
  end
endmodule

module DisplaySyncTiming (
    input [0 : 0] rstn,  //复位信号,低有效
    input [0 : 0] pclk,

    output reg [0 : 0] h_enable,  //水平显示有效
    output reg [0 : 0] v_enable,  //垂直显示有效
    output reg [0 : 0] h_sync,    //行同步
    output reg [0 : 0] v_sync     //场同步
);

  localparam H_SYNC_WIDTH = 119;  //水平同步脉冲宽度
  localparam H_BACK_PORCH = 63;  //水平后肩
  localparam H_DISPLAY = 799;  //水平显示
  localparam H_FRONT_PORCH = 55;  //水平前肩

  localparam V_SYNC_WIDTH = 5;  //垂直同步脉冲宽度
  localparam V_BACK_PORCH = 22;  //垂直后肩
  localparam V_DISPLAY = 599;  //垂直显示
  localparam V_FRONT_PORCH = 36;  //垂直前肩

  localparam STATE_SYNC = 2'b00;
  localparam STATE_BACK_PORCH = 2'b01;
  localparam STATE_DISPLAY = 2'b10;
  localparam STATE_FRONT_PORCH = 2'b11;

  reg  [ 0 : 0] v_enable_counter;  //垂直计数器使能

  reg  [ 1 : 0] h_state;
  reg  [ 1 : 0] v_state;

  reg  [15 : 0] h_load_value;
  reg  [15 : 0] v_load_value;

  wire [15 : 0] h_count;
  wire [15 : 0] v_count;

  Counter #(16, H_SYNC_WIDTH) h_counter( //每个时钟周期计数器增加1，表示扫描一个像素
      .clk       (pclk),
      .rstn      (rstn),
      .load_value(h_load_value),
      .enable    (1'b1),

      .count(h_count)
  );

  Counter #(16, V_SYNC_WIDTH) v_counter( //每行扫描完计数器增加1，表示扫描一行像素点
      .clk       (pclk),
      .rstn      (rstn),
      .load_value(v_load_value),
      .enable    (v_enable_counter),

      .count(v_count)
  );

  always @(*) begin
    case (h_state)
      STATE_SYNC: begin
        h_load_value = H_BACK_PORCH;
        h_sync = 1;
        h_enable = 0;
      end
      STATE_BACK_PORCH: begin
        h_load_value = H_DISPLAY;
        h_sync = 0;
        h_enable = 0;
      end
      STATE_DISPLAY: begin
        h_load_value = H_FRONT_PORCH;
        h_sync = 0;
        h_enable = 1;
      end
      STATE_FRONT_PORCH: begin
        h_load_value = H_SYNC_WIDTH;
        h_sync = 0;
        h_enable = 0;
      end
    endcase
    case (v_state)
      STATE_SYNC: begin
        v_load_value = V_BACK_PORCH;
        v_sync = 1;
        v_enable = 0;
      end
      STATE_BACK_PORCH: begin
        v_load_value = V_DISPLAY;
        v_sync = 0;
        v_enable = 0;
      end
      STATE_DISPLAY: begin
        v_load_value = V_FRONT_PORCH;
        v_sync = 0;
        v_enable = 1;
      end
      STATE_FRONT_PORCH: begin
        v_load_value = V_SYNC_WIDTH;
        v_sync = 0;
        v_enable = 0;
      end
    endcase
  end

  always @(posedge pclk) begin
    if (!rstn) begin
      h_state <= STATE_SYNC;
      v_state <= STATE_SYNC;
      v_enable_counter <= 1'b0;
    end else begin
      if (h_count == 0) begin
        h_state <= h_state + 2'b01;
        if (h_state == STATE_FRONT_PORCH) begin
          v_enable_counter <= 0;
          if (v_count == 0) v_state <= v_state + 2'b01;
        end else v_enable_counter <= 0;
      end else if (h_count == 1) begin
        if (h_state == STATE_FRONT_PORCH) //如果水平计数器前肩计数到1，表示当前行扫描完，在下一个时钟周期垂直计数器开始计数
          v_enable_counter <= 1;
        else v_enable_counter <= 0;
      end else v_enable_counter <= 0;
    end
  end
endmodule
