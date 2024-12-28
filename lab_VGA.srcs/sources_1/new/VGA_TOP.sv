module TOP (
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
    output [15:0] LED,
    output CA,
    CB,
    CC,
    CD,
    CE,
    CF,
    CG,
    DP,
    output reg [7:0] AN
);

  localparam H_LENGTH = 200;
  localparam V_LENGTH = 150;
  localparam ADDR_WIDTH = 15;

  wire [1:0] game_state;
  // wire [7:0] key_asci;
  // wire key_valid;
  // wire [1:0] sm_bit;
  wire up, down, left, right, space, shoot,r;

  //   Keyboard(暂时弃置)
  // Keyboard keyboard (
  //     .clk(CLK100MHZ),
  //     .rst_n(CPU_RESETN),
  //     .ps2k_clk(PS2_CLK),
  //     .ps2k_data(PS2_DATA),
  //     .ps2_state(key_valid),
  //     .ps2_byte(key_asci),
  //     .sm_bit(sm_bit),
  //     .sm_seg({CA, CB, CC, CD, CE, CF, CG, DP})
  // );

  //新版键盘输入
  KeyboardOutput keyboard_inst(
    .clk(CLK100MHZ),
    .rstn(CPU_RESETN),
    .ps2_clk(PS2_CLK),
    .ps2_data(PS2_DATA),
    .a(left),
    .d(right),
    .j(shoot),
    .r(r),
    .up(up),
    .down(down),
    // .left(left),
    // .right(right),
    .space(space)
  );

  // Decode sm_bit to AN
  // always_comb begin
  //   case (sm_bit)
  //     2'b00:   AN = 8'b11111110;
  //     2'b01:   AN = 8'b11111101;
  //     2'b10:   AN = 8'b11111011;
  //     2'b11:   AN = 8'b11110111;
  //     default: AN = 8'b11111111;
  //   endcase
  // end

  //music
  Music music_inst (
      .clk(CLK100MHZ),
      .rstn(CPU_RESETN),
      .start(1),
      .speedup(0),
      .song(game_state),
      .volume(1),
      .G(AUD_SD),
      .B(AUD_PWM)
  );

  //Controllor
  Controllor #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) controllor_inst (
      .clk(CLK100MHZ),
      .rstn(CPU_RESETN),
      // .key_asci(key_asci),//键盘输入(暂时弃置)
      // .key_valid(key_valid),//键盘输入使能(暂时弃置)
      .btnc(BTNC),
      .btnl(BTNL),
      .btnr(BTNR),
      .btnu(BTNU),
      .btnd(BTND),
      .Right(right),
      .Left(left),
      .Shoot(shoot),
      .Space(space),
      .R(r),

      .LED(LED),
      .VGA_R(VGA_R),
      .VGA_G(VGA_G),
      .VGA_B(VGA_B),
      .VGA_HS(VGA_HS),
      .VGA_VS(VGA_VS),
      .game_state(game_state),
      .clk_o()
  );

endmodule
