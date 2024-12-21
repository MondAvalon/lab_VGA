// 分数统计
module Score(
    input clk,
    input frame_clk,
    input rstn,
    input [1:0] game_state,

    output reg [15:0] score,
    output reg [15:0] high_score
    );
    initial begin
        score = 16'h1234;
        high_score = 16'h7890;
    end
endmodule
