module keyboard_test_top (
    input             CLK100MHZ,     // 系统时钟
    input             CPU_RESETN,    // 复位信号,低有效 
    inout             PS2_CLK,       // USB键盘时钟线
    inout             PS2_DATA,      // USB键盘数据线
    output CA,CB,CC,CD,CE,CF,CG,DP,  // 数码管显示
    output [7:0]     AN,            // 数码管位选
    output reg [15:0] LED            // LED输出,16个LED
);

  // PS2数据信号
  wire ps2_state;

  // 例化USB键盘控制器
  Keyboard keyboard_inst (
    .clk(CLK100MHZ),  // 系统时钟
    .rst_n(CPU_RESETN),  // 复位信号
    .ps2k_clk(PS2_CLK),  // USB键盘时钟线
    .ps2k_data(PS2_DATA),  // USB键盘数据线
    .ps2_state(ps2_state),  // 键盘当前状态
    .sm_seg({CG,CF,CE,CD,CC,CB,CA,DP}),  // 数码管显示
    .sm_bit({AN[0],AN[1]})  // 数码管位选
  );


endmodule
