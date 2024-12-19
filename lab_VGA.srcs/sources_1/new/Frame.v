//获取VGA信号的同步信号，根据游戏对象的坐标与优先级等生成一个固定的分辨率的图像
module FrameGenerator #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
) (
    input clk,
    input pclk,
    input frame_clk,
    input rstn,

    //input in-game x, y, priority, color 
    output reg [ADDR_WIDTH-1:0] render_addr,

    // output VGA signal
    input [ADDR_WIDTH-1:0] raddr,
    output [11:0] rdata
);

  wire [$clog2(H_LENGTH)-1:0] render_x;
  wire [$clog2(V_LENGTH)-1:0] render_y;
  assign render_x = render_addr % H_LENGTH;
  assign render_y = render_addr / H_LENGTH;
  // wire [ADDR_WIDTH-1:0] render_addr;
  // assign render_addr = render_y * H_LENGTH + render_x;

  reg is_generating_frame;
  reg scroll_enabled;

  reg vram_we;  //写使能
  reg [ADDR_WIDTH-1:0] vram_addr;
  reg [11:0] vram_rgb;

  initial begin
    render_addr = 0;
    is_generating_frame = 0;
    vram_we = 0;
    scroll_enabled = 0;
  end

  always @(posedge frame_clk) begin
    if (!rstn) is_generating_frame <= 0;
    else is_generating_frame <= 1;
  end

  // always @(posedge clk) begin
  //   if (!rstn) begin
  //     vram_we <= 0;
  //     render_addr <= 0;
  //     generating <= 0;

  //   end else if (generating) begin
  //     if (render_addr < H_LENGTH * V_LENGTH - 1) begin
  //       render_addr <= render_addr + 1;
  //     end else begin
  //       render_addr <= 0;
  //     end

  //     vram_we   <= 1;
  //     vram_addr <= render_addr;  // 由坐标生成需要写入vram的地址

  //     // in-game object color update logic
  //     vram_rgb  <= gameover_rgb;


  //   end else begin
  //     render_addr <= 0;
  //     vram_we <= 0;
  //   end
  // end

  //测试写入vram
  always @(posedge clk) begin
    if (!rstn) begin
      vram_we <= 0;
      render_addr <= 0;
      is_generating_frame <= 0;
    end else begin
      if (render_addr < H_LENGTH * V_LENGTH - 1) begin
        render_addr <= render_addr + 1;
      end else begin
        render_addr <= 0;
      end

      vram_we   <= 1;
      vram_addr <= render_addr;  // 由坐标生成需要写入vram的地址
      vram_rgb <= (render_addr % 2) ? 12'h0 : 12'hFFF;
    end
  end

  vram_bram vram_inst (
      .clka (clk),
      .wea  (vram_we),
      .addra(vram_addr),
      .dina (vram_rgb),

      .clkb (clk),
      .addrb(raddr),
      .doutb(rdata)
  );

  background #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) background_inst (
      .clk(clk),
      .frame_clk(frame_clk),
      .rstn(rstn),
      .enable_scroll(scroll_enabled),
      .addr(render_addr),  //读取rom中的数据的地址
      .n(1),  //每n个frame_clk
      .rgb(background_rgb)
  );

  Rom_Gameover gameover (
      .clka(clk),  // input wire clka
      .addra(render_addr),  // input wire [14 : 0] addra
      .douta(gameover_rgb)  // output wire [11 : 0] douta
  );

endmodule
