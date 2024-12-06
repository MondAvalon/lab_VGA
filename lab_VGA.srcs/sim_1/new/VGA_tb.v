`timescale 1ns / 1ps

module VGA_tb ();
  // 参数定义
  parameter H_LENGTH = 200;
  parameter V_LENGTH = 150;
  parameter ADDR_WIDTH = 15;
  parameter CLK_PERIOD = 10;  // 100MHz时钟

  // 信号声明
  reg         clk;
  reg         rstn;
  reg  [14:0] waddr;
  reg  [11:0] wdata;
  reg         we;

  wire        hs;
  wire        vs;
  wire [ 3:0] r;
  wire [ 3:0] g;
  wire [ 3:0] b;

  // 实例化VGA模块
  VGA #(
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH),
      .ADDR_WIDTH(ADDR_WIDTH)
  ) vga_inst (
      .clk(clk),
      .rstn(rstn),
      .waddr(waddr),
      .wdata(wdata),
      .we(we),
      .hs(hs),
      .vs(vs),
      .r(r),
      .g(g),
      .b(b)
  );

  // 时钟生成
  initial begin
    clk = 0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  // 测试激励
  initial begin
    // 初始化
    rstn = 0;
    waddr = 0;
    wdata = 0;
    we = 0;

    // 等待100ns后释放复位
    #100 rstn = 1;

    // 测试内存写入
    #100;
    // 写入红色像素
    we = 1;
    waddr = 15'h0000;
    wdata = 12'hF00;  // 红色
    #20;

    // 写入绿色像素
    waddr = 15'h0001;
    wdata = 12'h0F0;  // 绿色
    #20;

    // 写入蓝色像素
    waddr = 15'h0002;
    wdata = 12'h00F;  // 蓝色
    #20;

    waddr = 15'h0003;
    wdata = 12'hFFF;  // 白色
    #20;

    // 禁止写入
    we = 0;

  end

  // 监控信号
  initial begin
    $monitor("Time=%0t rstn=%b hs=%b vs=%b r=%h g=%h b=%h", $time, rstn, hs, vs, r, g, b);
  end

  // 生成波形文件
  initial begin
    $dumpfile("vga_test.vcd");
    $dumpvars(0, VGA_tb);
  end

endmodule
