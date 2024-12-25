module MUSIC(
    input clk,
    input start,
    input rstn,//低电平触发
    input [6:0]volume,//音量
    input [2:0]song,  //选歌 （开始界面、运行界面、胜利界面、失败界面）     
    input [2:0]speedup, //倍速
    output reg B,//当前播放的音频信号（某一首歌的音频）对应AUD_PWM
    output reg G//AUD_SD，使能信号，默认为1
);
reg [15:0]  var2;//中间量，传递音量信号
always @(*) begin
    case (volume)
        7'd0: var2 = 8192; 
        7'd10: var2 = 4196;  
        7'd20: var2 = 2048; 
        7'd30: var2 = 1024;  
        7'd40: var2 = 512;   
        7'd50: var2 = 256;  
        7'd60: var2 = 128;   
        7'd70: var2 = 64;   
        7'd80: var2 = 32;    
        7'd90: var2 = 16;   
        7'd100: var2 = 8;   
        default: var2 = 1024;
    endcase
end

wire [15:0] frac;
assign frac = var2;
initial begin
    G = 1'b1;
end

wire menu,bgm,fail,win;
reg begin_bgm,bgm_bgm,bgm_fail,bgm_win;
bgm BGM(
    .clk(clk),
    .start(start),
    .rstn(bgm_bgm),
    .frac(frac),      
    .speedup(speedup),
    .B(bgm)
    );
BGM_BEGIN beginbgm(
    .clk(clk),
    .start(start),
    .rstn(begin_bgm),
    .frac(frac),      
    .speedup(speedup),
    .B(menu)
    );
fail FAIL(
    .clk(clk),
    .start(start),
    .rstn(bgm_fail),
    .frac(frac),      
    .speedup(speedup),
    .B(fail)
    );
BGM_WIN WIN(
    .clk(clk),
    .start(start),
    .rstn(bgm_win),
    .frac(frac),      
    .speedup(speedup),
    .B(win)
);
always @(posedge clk) begin
    case (song)
        2'd0: begin
            B<=menu;
            bgm_bgm<=0;
            bgm_fail<=0;
            begin_bgm<=1;
            bgm_win<=0;
        end 
        2'd1: begin
            B<=bgm;
            bgm_bgm<=1;
            begin_bgm<=0;
            bgm_fail<=0;
            bgm_win<=0;
        end  
        2'd2: begin
            B<=fail;
            bgm_bgm<=0;
            begin_bgm<=0;
            bgm_fail<=1;
            bgm_win<=0;
        end
        2'd3:begin
            B<=win;
            bgm_bgm<=0;
            begin_bgm<=0;
            bgm_fail<=0;
            bgm_win<=1;
        end  
        default:;
    endcase
end
endmodule