`timescale 1ns / 1ps

module Stairs_tb();
    // 参数定义
    parameter H_LENGTH = 200;
    parameter V_LENGTH = 150;
    
    // 输入信号定义
    reg clk;
    reg frame_clk; 
    reg rstn;
    reg enable_scroll;
    reg [7:0] n;
    
    // 输出信号
    wire [$clog2(H_LENGTH)-1:0] state_x [16];
    wire [$clog2(V_LENGTH)-1:0] state_y [16];
    wire [1:0] state_mark [16];
    
    // 实例化被测模块
    Stairs #(
        .H_LENGTH(H_LENGTH),
        .V_LENGTH(V_LENGTH)
    ) dut (
        .clk(clk),
        .frame_clk(frame_clk),
        .rstn(rstn),
        .enable_scroll(enable_scroll),
        .n(n),
        .state_x(state_x),
        .state_y(state_y),
        .state_mark(state_mark)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    initial begin
        frame_clk = 0;
        forever #6944 frame_clk = ~frame_clk;  // ~72Hz
    end
    
    // 测试激励
    initial begin
        // 初始化
        rstn = 0;
        enable_scroll = 0;
        n = 8'd1;
        
        // 等待100ns
        #100;
        
        // 释放复位
        rstn = 1;
        
        // 测试滚动功能
        enable_scroll = 1;
        #10000;
    end

endmodule