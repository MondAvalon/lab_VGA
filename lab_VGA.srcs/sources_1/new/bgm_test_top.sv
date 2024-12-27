module MUSIC_TOP (
    input CLK100MHZ,   // 100_000_000 MHz
    input CPU_RESETN,
    input PS2_CLK,
    input PS2_DATA,
    input BTNC,
    BTNL,
    BTNR,
    BTNU,
    BTND,

    output VGA_HS,
    output VGA_VS,
    output [3 : 0] VGA_R,
    output [3 : 0] VGA_G,
    output [3 : 0] VGA_B,
    output AUD_PWM,
    output AUD_SD,
    output [15:0] LED
);
  Music audio (
      .clk(CLK100MHZ),
      .rstn(CPU_RESETN),
      .start(1),
      .speedup(0),
      .song(2'd1),
      .volume(0),
      .G(AUD_SD),
      .B(AUD_PWM)
  );

endmodule
