module keyboard_test_top (
    input             CLK100MHZ,     // 系统时钟
    input             CPU_RESETN,    // 复位信号,低有效 
    inout             PS2_CLK,       // USB键盘时钟线
    inout             PS2_DATA,      // USB键盘数据线
    input             UART_RXD_OUT,
    input             UART_RTS,
    output            UART_TXD_IN,
    output            UART_CTS,
    output reg [15:0] LED            // LED输出,16个LED
);

  // PS2数据信号
  wire ps2_valid;
  wire [7:0] ps2_data;

  // 例化USB键盘控制器
  Keyboard keyboard_inst (
      .clk        (CLK100MHZ),     // 修改为CLK100MHZ
      .rst        (!CPU_RESETN),   // 修改为!CPU_RESETN,因为CPU_RESETN是低有效
      .USB_CLOCK  (PS2_CLK),       // 修改为PS2_CLK
      .USB_DATA   (PS2_DATA),      // 修改为PS2_DATA 
      .RXD        (UART_RXD_OUT),
      .TXD        (UART_TXD_IN),
      .CTS        (UART_CTS),
      .RTS        (UART_RTS),
      .PS2_valid  (ps2_valid),
      .PS2_data_in(ps2_data)
  );

  // LED控制逻辑 
  always @(posedge CLK100MHZ or negedge CPU_RESETN) begin  // 修改时钟和复位条件
    if (!CPU_RESETN) begin  // 修改为低有效复位
      LED <= 16'h0000;
    end else if (ps2_valid) begin
      case (ps2_data)
        8'h1C:   LED[0] <= 1'b1;  // A键
        8'h1B:   LED[1] <= 1'b1;  // S键
        8'h23:   LED[2] <= 1'b1;  // D键
        8'h2B:   LED[3] <= 1'b1;  // F键
        8'h34:   LED[4] <= 1'b1;  // G键
        8'h33:   LED[5] <= 1'b1;  // H键
        8'h3B:   LED[6] <= 1'b1;  // J键
        8'h42:   LED[7] <= 1'b1;  // K键
        8'h4B:   LED[8] <= 1'b1;  // L键
        8'h15:   LED[9] <= 1'b1;  // Q键
        8'h1D:   LED[10] <= 1'b1;  // W键
        8'h24:   LED[11] <= 1'b1;  // E键
        8'h2D:   LED[12] <= 1'b1;  // R键
        8'h2C:   LED[13] <= 1'b1;  // T键
        8'h35:   LED[14] <= 1'b1;  // Y键
        8'h3C:   LED[15] <= 1'b1;  // U键
        8'hF0:   LED <= 16'h0000;  // 按键释放码
        default: LED <= LED;
      endcase
    end
  end

endmodule
