module BGM_FAIL (
    input clk,
    input start,
    input rstn,
    input wire [15:0] frac,
    input [2:0] speedup,
    output reg B
);
  reg [26:1] t;
  reg [26:1] total;
  reg clk_out;
  reg [10:0] state;
  reg [8:1] m;

  always @(posedge clk, negedge rstn)
    if (~rstn) total <= 3125000 * 3;
    // else if(speedup==1) total<=3125000;
    else if (speedup == 2) total <= 3125000;
    else total <= 3125000 * 3;

  always @(posedge clk, negedge rstn)
    if (~rstn) begin
      clk_out <= 0;
      t <= total;
    end else if (t == 0) begin
      clk_out <= ~clk_out;
      t <= total;
    end else begin
      t <= t - 1;
    end

  always @(posedge clk_out, negedge rstn)
    if (~rstn) state <= 0;
    else if (start) begin
      if (state != 54) state <= state + 1;
      else state <= 0;
    end

  always @(*)
    if (start)
      case (state)  //《失败结算（马里奥）》
        0: m = 24;
        1: m = 24;
        2: m = 0;
        3: m = 0;
        4: m = 19;
        5: m = 19;
        6: m = 0;
        7: m = 0;
        8: m = 16;
        9: m = 16;
        10: m = 16;
        11: m = 16;
        12: m = 21;
        13: m = 21;
        14: m = 23;
        15: m = 23;
        16: m = 21;
        17: m = 21;
        18: m = 20; 
        19: m = 20;
        20: m = 0;
        21: m = 22;
        22: m = 22;
        23: m = 0;
        24: m = 20;
        25: m = 20;
        26: m = 20;
        27: m = 16;
        28: m = 14;
        29: m = 16;
        30: m = 20;
        31: m = 20;
        32: m = 20;
        33: m = 20;
        34: m = 20;
        35: m = 20;
        36: m = 20;

        37: m = 0;
        38: m = 0;
        39: m = 0;
        40: m = 0;
        41: m = 0;
        42: m = 0;
        43: m = 0;
        44: m = 0;
        45: m = 0;
        46: m = 0;
        47: m = 0;
        48: m = 0;
        49: m = 0;
        50: m = 0;
        51: m = 0;
        52: m = 0;
        53: m = 0;
        54: m = 0;
        
        default: m = 0;
      endcase
    else m = 0;

  reg [27:1] q;
  always @(*) begin
    case (m)
      7'd0:  q = 0;  // 0
      7'd1:  q = 28'd100000000 / 139;  // C#3/Db3
      7'd2:  q = 28'd100000000 / 147;  // D3
      7'd3:  q = 28'd100000000 / 156;  // D#3/Eb3
      7'd4:  q = 28'd100000000 / 165;  // E3
      7'd5:  q = 28'd100000000 / 175;  // F3
      7'd6:  q = 28'd100000000 / 185;  // F#3/Gb3
      7'd7:  q = 28'd100000000 / 196;  // G3
      7'd8:  q = 28'd100000000 / 208;  // G#3/Ab3
      7'd9:  q = 28'd100000000 / 220;  // A3
      7'd10: q = 28'd100000000 / 233;  // A#3/Bb3
      7'd11: q = 28'd100000000 / 247;  // B3

      7'd12: q = 28'd100000000 / 262;  // C4
      7'd13: q = 28'd100000000 / 277;  // C#4/Db4
      7'd14: q = 28'd100000000 / 294;  // D4
      7'd15: q = 28'd100000000 / 311;  // D#4/Eb4
      7'd16: q = 28'd100000000 / 330;  // E4
      7'd17: q = 28'd100000000 / 349;  // F4
      7'd18: q = 28'd100000000 / 370;  // F#4/Gb4
      7'd19: q = 28'd100000000 / 392;  // G4
      7'd20: q = 28'd100000000 / 415;  // G#4/Ab4
      7'd21: q = 28'd100000000 / 440;  // A4
      7'd22: q = 28'd100000000 / 466;  // A#4/Bb4
      7'd23: q = 28'd100000000 / 494;  // B4

      7'd24: q = 28'd100000000 / 523;  // C5
      7'd25: q = 28'd100000000 / 554;  // C#5/Db5
      7'd26: q = 28'd100000000 / 587;  // D5
      7'd27: q = 28'd100000000 / 622;  // D#5/Eb5
      7'd28: q = 28'd100000000 / 659;  // E5
      7'd29: q = 28'd100000000 / 698;  // F5
      7'd30: q = 28'd100000000 / 740;  // F#5/Gb5
      7'd31: q = 28'd100000000 / 784;  // G5
      7'd32: q = 28'd100000000 / 831;  // G#5/Ab5
      7'd33: q = 28'd100000000 / 880;  // A5
      7'd34: q = 28'd100000000 / 932;  // A#5/Bb5
      7'd35: q = 28'd100000000 / 988;  // B5

      7'd36: q = 28'd100000000 / 1047;  // C6
      7'd37: q = 28'd100000000 / 1109;  // C#6/Db6
      7'd38: q = 28'd100000000 / 1175;  // D6
      7'd39: q = 28'd100000000 / 1245;  // D#6/Eb6
      7'd40: q = 28'd100000000 / 1319;  // E6
      7'd41: q = 28'd100000000 / 1397;  // F6
      7'd42: q = 28'd100000000 / 1480;  // F#6/Gb6
      7'd43: q = 28'd100000000 / 1568;  // G6
      7'd44: q = 28'd100000000 / 1661;  // G#6/Ab6
      7'd45: q = 28'd100000000 / 1760;  // A6
      7'd46: q = 28'd100000000 / 1865;  // A#6/Bb6
      7'd47: q = 28'd100000000 / 1976;  // B6

      7'd48:   q = 28'd100000000 / 2093;  // C7
      default: q = 0;
    endcase
  end

  reg [27:1] p;
  reg [27:1] tt;
  always @(posedge clk, negedge rstn) begin
    if (~rstn) begin
      B <= 0;
      p <= 0;
    end else begin
      tt <= q;
      if (q == 0 || tt != q) begin
        if (q == 0) begin
          B <= 0;
        end
        if (tt != q) begin
          p <= 0;
        end
      end else begin
        if (p == q - 1) p <= 0;
        else p <= p + 1;
        if (p == 0) B <= 1;
        if (p == q / frac) B <= 0;  //占空比控制音量
      end
    end
  end
endmodule
