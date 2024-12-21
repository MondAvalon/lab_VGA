// module RenderHelper #(
//     parameter SPRITE_WIDTH  = 10,   // 贴图宽度
//     parameter SPRITE_HEIGHT = 10,   // 贴图高度
//     parameter ADDR_WIDTH    = 15,   // ROM地址宽度
//     parameter H_LENGTH      = 200,  // 水平分辨率
//     parameter V_LENGTH      = 150   // 垂直分辨率
// ) (
//     input [$clog2(H_LENGTH)-1:0] render_x,       // 当前渲染x坐标
//     input [$clog2(V_LENGTH)-1:0] render_y,       // 当前渲染y坐标
//     input [                 8:0] sprite_base_x,  // 贴图在ROM中的基准x坐标
//     input [      ADDR_WIDTH-1:8] sprite_base_y,  // 贴图在ROM中的基准y坐标
//     input [$clog2(H_LENGTH)-1:0] pos_x,          // 要渲染到的目标位置x
//     input [$clog2(V_LENGTH)-1:0] pos_y,          // 要渲染到的目标位置y

//     output [           8:0] object_x,  // ROM中的x坐标
//     output [ADDR_WIDTH-1:8] object_y   // ROM中的y坐标
// );

// //   wire [$clog2(H_LENGTH)-1:0] rel_x;
// //   wire [$clog2(V_LENGTH)-1:0] rel_y;

// //   assign rel_x = render_x - pos_x;
// //   assign rel_y = render_y - pos_y;
//   assign object_x = sprite_base_x + render_x - pos_x;
//   assign object_y = sprite_base_y + render_y - pos_y;

// endmodule
