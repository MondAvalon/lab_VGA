module TOP (
    input CLK100MHZ,   // 100_000_000 MHz
    input CPU_RESETN,
    input PS2_CLK,
    input PS2_DATA,
    input BTNC,BTNL,BTNR,BTNU,BTND,

    output VGA_HS,
    output VGA_VS,
    output [3 : 0] VGA_R,
    output [3 : 0] VGA_G,
    output [3 : 0] VGA_B,
    output AUD_PWM,
    output AUD_SD,
    output [15:0] LED
);

  localparam H_LENGTH = 200;
  localparam V_LENGTH = 150;
  localparam ADDR_WIDTH = 15;

  wire [10:0] key_event;
  wire [127:0] key_state;

  // Keyboard
//   Keyboard keyboard (
//       .clk(CLK100MHZ),
//       .rstn(CPU_RESETN),
//       .ps2_c(PS2_CLK),
//       .ps2_d(PS2_DATA),
//       .key_event(key_event)
//   );

  //Audio
  Audio audio (
      .clk(CLK100MHZ),
      .rstn(CPU_RESETN),
      .start(1),
      .speed_control(0),

      .audio_pwm(AUD_PWM)
  );

  assign AUD_SD = 1'b1;

  //Controllor
  Controllor #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) controllor (
      .clk(CLK100MHZ),
      .rstn(CPU_RESETN),
      .key_event(key_event),
      .key_state(key_state),
      .btnc(BTNC),
      .btnl(BTNL),
      .btnr(BTNR),
      .btnu(BTNU),
      .btnd(BTND),

      .LED(LED),
      .VGA_R(VGA_R),
      .VGA_G(VGA_G),
      .VGA_B(VGA_B),
      .VGA_HS(VGA_HS),
      .VGA_VS(VGA_VS)
  );

endmodule
