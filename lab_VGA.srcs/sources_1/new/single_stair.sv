`timescale 1ns/1ps
module SingleStair#(
    parameter H_LENGTH  = 200, //宽度
    parameter V_LENGTH  = 150,  //高度
    parameter NUM = 0
)(
    input clk,
    input frame_clk,
    input rstn,
    input [1:0] game_state,
    input enable_scroll,    //借用一下，实现暂停功能
    // input [3:0]   num,             // 台阶数字编号
    input [7:0] n,         // 每n个frame_clk更新一次offset，图片向下滚动速度为每秒72/n个像素,即刷新率
    input signed [$clog2(V_LENGTH)-1:0] v,

    output reg [$clog2(H_LENGTH)-1:0] loc_x, //x位置
    output reg [$clog2(V_LENGTH)-1:0] loc_y, //y位置
    output reg [1:0] mark //台阶分类，00为不显示，01为普通台阶，10为特殊台阶
); 
wire [7:0] count_y;  // 计数器
reg  [7:0] x_offset;  // x轴偏移量
reg signed [7:0] generate_cd;  // 生成台阶的计数器
reg signed [31:0] randnum;
localparam X_INIT = 16 + (NUM * 997)%(H_LENGTH-32);
localparam Y_INIT = 2 + (NUM * 997)%(V_LENGTH-2);

always @(posedge frame_clk) begin
    randnum <= {randnum[30:0], randnum[31]^randnum[27]};
end

// 在每个frame_clk上升沿更新计数器和偏移量
always @(posedge frame_clk) begin
    if(!rstn) begin
        loc_x <= X_INIT;
        loc_y <= Y_INIT;
        mark <= 0;
    end else if(game_state==2'b01) begin
        if (loc_y > 146) begin
            loc_x <= 100 + randnum[31:4] % 71;
            loc_y <= 3;
            mark <= 0;
            generate_cd <= randnum[29:2] % 987;
        end else if (count_y == 0) begin  // 计数器为零，y轴移动
            loc_y <= loc_y + v;
            if(mark == 2'b10) begin
                if(x_offset < 60) begin
                    loc_x <= loc_x + 1;
                    x_offset <= x_offset + 1;
                end else if(x_offset < 120) begin
                    loc_x <= loc_x - 1;
                    x_offset <= x_offset + 1;
                    if(loc_x<16)begin
                        loc_x <= 16;
                    end
                end else begin
                    x_offset <= 0;
                end
            end
            if (generate_cd > 0) begin
                generate_cd <= generate_cd - v;
            end else if (mark == 0) begin
                generate_cd <= 0;
                mark <= 1 + randnum[30];
                loc_y <= 3;
            end
        end
    end else begin
        loc_x <= X_INIT;
        loc_y <= Y_INIT;
        mark <= 1;
        generate_cd <= 0;
        x_offset <= 0;
    end
end

Counter #(
    .WIDTH      (8),
    .RESET_VALUE(0)
) counter_y (// 每个frame_clk计数器减1
  .clk       (frame_clk),
  .rstn      (rstn),
  .load_value(n - 1),
  .enable    (enable_scroll),
  .count     (count_y)
);

initial begin //初始化
    loc_x = X_INIT;
    loc_y = Y_INIT;
    mark = 1;
    randnum = NUM * 32'h01234567;
    generate_cd = 0;
    x_offset = 0;
end

endmodule
