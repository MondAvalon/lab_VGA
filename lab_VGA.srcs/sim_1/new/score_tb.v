`timescale 1ns / 1ps

module Score_tb();
    // 定义测试信号
    reg clk;
    reg frame_clk;
    reg rstn;
    reg [1:0] game_state;
    wire [15:0] score;
    wire [15:0] high_score;

    // 实例化被测试模块
    Score score_inst (
        .clk(clk),
        .frame_clk(frame_clk),
        .rstn(rstn),
        .game_state(game_state),
        .score(score),
        .high_score(high_score)
    );

    // 时钟生成
    always #5 clk = ~clk;
    always #20 frame_clk = ~frame_clk;

    // 测试过程
    initial begin
        // 初始化信号
        clk = 0;
        frame_clk = 0;
        rstn = 0;
        game_state = 2'b00;
        
        // 等待100ns后释放复位
        #100;
        rstn = 1;
        
        // 测试计分功能
        game_state = 2'b01;
        
        // 等待足够长时间观察计分
        #2000;
        
        // 测试复位功能
        rstn = 0;
        #100;
        rstn = 1;
        
        // 测试数字进位
        // 通过连续的frame_clk让score增加到9999
        #5000;
        
        // 结束仿真
        #100;
        $finish;
    end
    
    // 监控输出
    initial begin
        $monitor("Time=%0t rstn=%b game_state=%b score=%h high_score=%h", 
                 $time, rstn, game_state, score, high_score);
    end

endmodule
