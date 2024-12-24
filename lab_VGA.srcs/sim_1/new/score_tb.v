`timescale 1ns/1ps

module Counter_tb();
    // 参数定义
    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;
    parameter RESET_VALUE = 0;

    // 信号声明
    reg clk;
    reg rstn;
    reg [WIDTH-1:0] load_value;
    reg enable;
    wire [WIDTH-1:0] count;

    // 实例化被测模块
    Counter #(
        .WIDTH(WIDTH),
        .RESET_VALUE(RESET_VALUE)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .load_value(load_value),
        .enable(enable),
        .count(count)
    );

    // 时钟生成
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // 测试激励
    initial begin
        // 初始化信号
        rstn = 0;
        load_value = 16'd10;
        enable = 0;
        
        // 测试复位
        #(CLK_PERIOD*2);
        rstn = 1;
        
        // 测试载入功能
        enable = 1;
        #(CLK_PERIOD*2);
        
        // 等待计数完成
        #(CLK_PERIOD*15);
        
        // 禁用计数
        enable = 0;
        #(CLK_PERIOD*2);
        
        // 更改载入值并重新使能
        load_value = 16'd5;
        enable = 1;
        #(CLK_PERIOD*10);
        
        $finish;
    end

    // 监控输出
    initial begin
        $monitor("Time=%0t rstn=%b enable=%b load_value=%d count=%d",
                 $time, rstn, enable, load_value, count);
    end

endmodule