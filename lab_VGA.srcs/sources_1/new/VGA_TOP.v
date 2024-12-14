module VGA_TOP (
    input [0 : 0] CLK100MHZ,  // 100_000_000 MHz
    input [0 : 0] CPU_RESETN,

    output [0 : 0] VGA_HS,
    output [0 : 0] VGA_VS,
    output [3 : 0] VGA_R,
    output [3 : 0] VGA_G,
    output [3 : 0] VGA_B
);

  localparam H_LENGTH = 200;
  localparam V_LENGTH = 150;
  localparam ADDR_WIDTH = 15;

  reg [14:0] waddr;
  reg [11:0] wdata;  //RGB
  reg we;

  VGA #(
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH),
      .ADDR_WIDTH(ADDR_WIDTH)
  ) vga_inst (
      .waddr(waddr),
      .wdata(wdata),
      .we(we),
      .clk(CLK100MHZ),
      .rstn(CPU_RESETN),

      .hs(VGA_HS),
      .vs(VGA_VS),
      .r (VGA_R),
      .g (VGA_G),
      .b (VGA_B)
  );

  //1秒计数器
  reg [31:0] count;
  Counter #(32, 100_000_000) counter_inst (
      .clk(CLK100MHZ),
      .rstn(CPU_RESETN),
      .load_value(100_000_000),
      .enable(1'b1),
      .count(count)
  );

  always @(posedge CLK100MHZ) begin
    //每秒更新一次颜色


  end


endmodule
