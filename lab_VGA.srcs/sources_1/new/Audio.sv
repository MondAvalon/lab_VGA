module Audio (
    input       clk,           // 系统时钟100MHz
    input       start,         // 开始播放信号
    input       rstn,          // 复位信号(低电平有效)     
    input [2:0] speed_control, // 速度控制

    output reg audio_pwm  // 音频输出
);
  reg [24:1] timer_count;  // 定时器计数
  reg [24:1] timer_period;  // 定时周期
  reg        timer_clk;  // 定时器时钟

  // 根据速度设置定时周期
  always @(posedge clk, negedge rstn)
    if (~rstn) timer_period <= 3125000;
    else if (speed_control == 2) timer_period <= 1562500;  // 加速
    else timer_period <= 3125000;  // 正常速度

  // 定时器时钟生成
  always @(posedge clk, negedge rstn)
    if (~rstn) begin
      timer_clk   <= 0;
      timer_count <= timer_period;
    end else if (timer_count == 0) begin
      timer_clk   <= ~timer_clk;
      timer_count <= timer_period;
    end else begin
      timer_count <= timer_count - 1;
    end

  // 音乐状态计数器
  reg [8:1] music_state;
  always @(posedge timer_clk, negedge rstn)
    if (~rstn) music_state <= 0;
    else if (start) music_state <= music_state + 1;

  // 音高查找表
  reg [5:1] music_note;
  always @(*)
    if (start)
      case (music_state)
        0: music_note = 17;
        1: music_note = 17;
        2: music_note = 17;
        3: music_note = 17;
        4: music_note = 14;
        5: music_note = 14;
        6: music_note = 15;
        7: music_note = 15;

        8:  music_note = 16;
        9:  music_note = 16;
        10: music_note = 17;
        11: music_note = 16;
        12: music_note = 15;
        13: music_note = 15;
        14: music_note = 14;
        15: music_note = 14;

        16: music_note = 13;
        17: music_note = 13;
        18: music_note = 13;
        19: music_note = 13;
        20: music_note = 13;
        21: music_note = 13;
        22: music_note = 15;
        23: music_note = 15;

        24: music_note = 17;
        25: music_note = 17;
        26: music_note = 17;
        27: music_note = 17;
        28: music_note = 16;
        29: music_note = 16;
        30: music_note = 15;
        31: music_note = 15;

        32: music_note = 14;
        33: music_note = 14;
        34: music_note = 14;
        35: music_note = 14;
        36: music_note = 14;
        37: music_note = 14;
        38: music_note = 15;
        39: music_note = 15;

        40: music_note = 16;
        41: music_note = 16;
        42: music_note = 16;
        43: music_note = 16;
        44: music_note = 17;
        45: music_note = 17;
        46: music_note = 17;
        47: music_note = 17;

        48: music_note = 15;
        49: music_note = 15;
        50: music_note = 15;
        51: music_note = 15;
        52: music_note = 13;
        53: music_note = 13;
        54: music_note = 13;
        55: music_note = 13;

        56: music_note = 13;
        57: music_note = 13;
        58: music_note = 13;
        59: music_note = 13;
        60: music_note = 13;
        61: music_note = 13;
        62: music_note = 13;
        63: music_note = 13;

        64: music_note = 0;
        65: music_note = 0;
        66: music_note = 16;
        67: music_note = 16;
        68: music_note = 16;
        69: music_note = 16;
        70: music_note = 18;
        71: music_note = 18;

        72: music_note = 20;
        73: music_note = 20;
        74: music_note = 20;
        75: music_note = 20;
        76: music_note = 19;
        77: music_note = 19;
        78: music_note = 18;
        79: music_note = 18;

        80: music_note = 17;
        81: music_note = 17;
        82: music_note = 17;
        83: music_note = 17;
        84: music_note = 17;
        85: music_note = 17;
        86: music_note = 15;
        87: music_note = 15;

        88: music_note = 17;
        89: music_note = 17;
        90: music_note = 17;
        91: music_note = 17;
        92: music_note = 16;
        93: music_note = 16;
        94: music_note = 15;
        95: music_note = 15;

        96:  music_note = 14;
        97:  music_note = 14;
        98:  music_note = 14;
        99:  music_note = 14;
        100: music_note = 14;
        101: music_note = 14;
        102: music_note = 15;
        103: music_note = 15;

        104: music_note = 16;
        105: music_note = 16;
        106: music_note = 16;
        107: music_note = 16;
        108: music_note = 17;
        109: music_note = 17;
        110: music_note = 17;
        111: music_note = 17;

        112: music_note = 15;
        113: music_note = 15;
        114: music_note = 15;
        115: music_note = 15;
        116: music_note = 13;
        117: music_note = 13;
        118: music_note = 13;
        119: music_note = 13;

        120: music_note = 13;
        121: music_note = 13;
        122: music_note = 13;
        123: music_note = 13;
        124: music_note = 0;
        125: music_note = 0;
        126: music_note = 0;
        127: music_note = 0;

        128: music_note = 10;
        129: music_note = 10;
        130: music_note = 10;
        131: music_note = 10;
        132: music_note = 10;
        133: music_note = 10;
        134: music_note = 10;
        135: music_note = 10;

        136: music_note = 8;
        137: music_note = 8;
        138: music_note = 8;
        139: music_note = 8;
        140: music_note = 8;
        141: music_note = 8;
        142: music_note = 8;
        143: music_note = 8;

        144: music_note = 9;
        145: music_note = 9;
        146: music_note = 9;
        147: music_note = 9;
        148: music_note = 9;
        149: music_note = 9;
        150: music_note = 9;
        151: music_note = 9;

        152: music_note = 7;
        153: music_note = 7;
        154: music_note = 7;
        155: music_note = 7;
        156: music_note = 7;
        157: music_note = 7;
        158: music_note = 7;
        159: music_note = 7;

        160: music_note = 8;
        161: music_note = 8;
        162: music_note = 8;
        163: music_note = 8;
        164: music_note = 8;
        165: music_note = 8;
        166: music_note = 8;
        167: music_note = 8;

        168: music_note = 6;
        169: music_note = 6;
        170: music_note = 6;
        171: music_note = 6;
        172: music_note = 6;
        173: music_note = 6;
        174: music_note = 6;
        175: music_note = 6;

        176: music_note = 30;  //5.5
        177: music_note = 30;  //5.5
        178: music_note = 30;  //5.5
        179: music_note = 30;  //5.5
        180: music_note = 30;  //5.5
        181: music_note = 30;  //5.5
        182: music_note = 30;  //5.5
        183: music_note = 30;  //5.5

        184: music_note = 7;
        185: music_note = 7;
        186: music_note = 7;
        187: music_note = 7;
        188: music_note = 0;
        189: music_note = 0;
        190: music_note = 0;
        191: music_note = 0;

        192: music_note = 10;
        193: music_note = 10;
        194: music_note = 10;
        195: music_note = 10;
        196: music_note = 10;
        197: music_note = 10;
        198: music_note = 10;
        199: music_note = 10;

        200: music_note = 8;
        201: music_note = 8;
        202: music_note = 8;
        203: music_note = 8;
        204: music_note = 8;
        205: music_note = 8;
        206: music_note = 8;
        207: music_note = 8;

        208: music_note = 9;
        209: music_note = 9;
        210: music_note = 9;
        211: music_note = 9;
        212: music_note = 9;
        213: music_note = 9;
        214: music_note = 9;
        215: music_note = 9;

        216: music_note = 7;
        217: music_note = 7;
        218: music_note = 7;
        219: music_note = 7;
        220: music_note = 7;
        221: music_note = 7;
        222: music_note = 7;
        223: music_note = 7;

        224: music_note = 8;
        225: music_note = 8;
        226: music_note = 8;
        227: music_note = 8;
        228: music_note = 10;
        229: music_note = 10;
        230: music_note = 10;
        231: music_note = 10;

        232: music_note = 13;
        233: music_note = 13;
        234: music_note = 13;
        235: music_note = 13;
        236: music_note = 13;
        237: music_note = 13;
        238: music_note = 13;
        239: music_note = 13;
        240: music_note = 31;  //12.5
        241: music_note = 31;  //12.5
        242: music_note = 31;  //12.5
        243: music_note = 31;  //12.5
        244: music_note = 31;  //12.5
        245: music_note = 31;  //12.5
        246: music_note = 31;  //12.5
        247: music_note = 31;  //12.5
        248: music_note = 0;
        249: music_note = 0;
        250: music_note = 0;
        251: music_note = 0;
        252: music_note = 0;
        253: music_note = 0;
        254: music_note = 0;
        255: music_note = 0;
        default: music_note = 0;
      endcase
    else music_note = 0;

  // 音频频率查找表
  reg [27:1] freq_divider;
  always @(*) begin
    case (music_note)
      0: freq_divider = 0;
      1: freq_divider = 100000000 / 261;  // C4 (中央C) 低do
      2: freq_divider = 100000000 / 293;  // D4 低re
      3: freq_divider = 100000000 / 329;  // E4 低mi
      4: freq_divider = 100000000 / 349;  // F4 低fa
      5: freq_divider = 100000000 / 392;  // G4 低so
      6: freq_divider = 100000000 / 440;  // A4 低la
      7: freq_divider = 100000000 / 499;  // B4 低si
      8: freq_divider = 100000000 / 523;  // C5 中do
      9: freq_divider = 100000000 / 587;  // D5 中re
      10: freq_divider = 100000000 / 659;  // E5 中mi
      11: freq_divider = 100000000 / 698;  // F5 中fa
      12: freq_divider = 100000000 / 784;  // G5 中so
      13: freq_divider = 100000000 / 880;  // A5 中la
      14: freq_divider = 100000000 / 998;  // B5 中si
      15: freq_divider = 100000000 / 1046;  // C6 高do
      16: freq_divider = 100000000 / 1174;  // D6 高re
      17: freq_divider = 100000000 / 1318;  // E6 高mi
      18: freq_divider = 100000000 / 1396;  // F6 高fa
      19: freq_divider = 100000000 / 1568;  // G6 高so
      20: freq_divider = 100000000 / 1760;  // A6 高la
      21: freq_divider = 100000000 / 1976;  // B6 高si
      30: freq_divider = 100000000 / 415;  // G#4 低so# 
      31: freq_divider = 100000000 / 831;  // G#5 中so#
      default: freq_divider = 0;
    endcase
  end

  // 音频波形生成
  reg [27:1] wave_counter;  // 波形计数器
  reg [27:1] curr_freq;  // 当前频率 
  always @(posedge clk, negedge rstn) begin
    if (~rstn) begin
      audio_pwm <= 0;
      wave_counter <= 0;
    end else begin
      curr_freq <= freq_divider;
      if (freq_divider == 0 || curr_freq != freq_divider) begin
        if (freq_divider == 0) begin
          audio_pwm <= 0;
        end
        if (curr_freq != freq_divider) begin
          wave_counter <= 0;
        end
      end else begin
        if (wave_counter == freq_divider - 1) wave_counter <= 0;
        else wave_counter <= wave_counter + 1;

        if (wave_counter == 0) audio_pwm <= 1;
        if (wave_counter == freq_divider / 256)  // 占空比控制音量
          audio_pwm <= 0;
      end
    end
  end

endmodule
