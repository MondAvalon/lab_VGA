module Game #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
) (
    input clk,
    input rstn,
    input frame_clk,
    input [ADDR_WIDTH-1:0] render_addr,//渲染坐标/地址

    // 游戏键盘输入
    input left,
    input right,
    input shoot,
    input space

    // output in-game object x, y, priority, color
    // output [11:0] background_rgb
);

// background #(
//     .ADDR_WIDTH(ADDR_WIDTH),
//     .H_LENGTH(H_LENGTH),
//     .V_LENGTH(V_LENGTH)
// ) background_inst (
//     .clk(clk),
//     .frame_clk(frame_clk),
//     .rstn(rstn),
//     .enable(1),
//     .enable_scroll(0),
//     .addr(render_addr),
//     .n(1),
//     .rgb(background_rgb)
// );
endmodule
