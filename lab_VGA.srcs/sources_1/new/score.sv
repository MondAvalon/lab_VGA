// 分数统计
module Score (
    input clk,
    input frame_clk,
    input rstn,
    input [1:0] game_state,
    input [7:0] n_count,
    input [7:0] v,

    output reg [15:0] score,
    output reg [15:0] high_score
);

  // wire [7:0] count;  // 计数器
  reg [13:0] score_dec;
  reg [13:0] high_score_dec;

  initial begin
    score = 16'h0000;
    score_dec = 14'd0;
    high_score = 16'h0000;
  end

  // 测试计分逻辑
  always @(posedge frame_clk) begin
    if (!rstn) begin
      score_dec <= 14'd0;
    end else if (!n_count) begin
      case (game_state)
        2'b01: begin
          score_dec <= score_dec + (v >>> 1);
          if (score_dec + (v >>> 1) > 14'd9999) begin
            score_dec <= 14'd9999;
          end
        end
        default: begin
          score_dec <= 14'd0;
        end
      endcase
    end
  end

  always @(*) begin
    score[3:0]   = score_dec % 10;
    score[7:4]   = (score_dec / 10) % 10;
    score[11:8]  = (score_dec / 100) % 10;
    score[15:12] = (score_dec / 1000) % 10;

    high_score[3:0]   = high_score_dec % 10;
    high_score[7:4]   = (high_score_dec / 10) % 10;
    high_score[11:8]  = (high_score_dec / 100) % 10;
    high_score[15:12] = (high_score_dec / 1000) % 10;
  end

  always @(posedge clk) begin
    if (!rstn) begin
      high_score_dec <= 14'd0;
    end else if (score_dec > high_score_dec) begin
      high_score_dec <= score_dec;
    end
  end

  // Counter #(8, 255) counter (  // 每个frame_clk计数器减1
  //     .clk       (frame_clk),
  //     .rstn      (rstn),
  //     .load_value(n - 1),
  //     .enable    (1),
  //     .count     (count)
  // );
endmodule
