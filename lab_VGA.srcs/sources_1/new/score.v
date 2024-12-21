// 分数统计
module Score (
    input clk,
    input frame_clk,
    input rstn,
    input [1:0] game_state,

    output reg [15:0] score,
    output reg [15:0] high_score
);
  initial begin
    score = 16'h0000;
    high_score = 16'h0000;
  end

  // 测试计分逻辑
  always @(posedge frame_clk) begin
    if (!rstn) begin
      score <= 16'h0000;
      //   high_score <= 16'h0000;
    end else begin
      case (game_state)
        2'b01: begin
          if (score[3:0] == 4'h9) begin
            score[3:0] <= 4'h0;
            if (score[7:4] == 4'h9) begin
              score[7:4] <= 4'h0;
              if (score[11:8] == 4'h9) begin
                score[11:8] <= 4'h0;
                if (score[15:12] == 4'h9) begin
                  score[15:12] <= 4'h0;
                end else begin
                  score[15:12] <= score[15:12] + 4'h1;
                end
              end else begin
                score[11:8] <= score[11:8] + 4'h1;
              end
            end else begin
              score[7:4] <= score[7:4] + 4'h1;
            end
          end else begin
            score[3:0] <= score[3:0] + 4'h1;
          end
        end
        2'b10: begin
          if (score > high_score) begin
            high_score <= score;
          end
          score <= 16'h0000;
        end
      endcase
    end
  end
endmodule
