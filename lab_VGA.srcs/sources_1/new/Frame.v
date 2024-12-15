//获取VGA信号的同步信号，根据游戏对象的坐标与优先级等生成一个固定的分辨率的图像
module FrameGenerator #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
) (
    input clk,
    input frame_clk,
    input rstn,
    input [ADDR_WIDTH-1:0] raddr,
    //input in-game x, y, priority, color 

    output [11:0] rdata
);

  reg [$clog2(H_LENGTH)-1:0] render_x;
  reg [$clog2(V_LENGTH)-1:0] render_y;
  wire [ADDR_WIDTH-1:0] waddr;
  reg [11:0] wdata;
  reg we;  //写使能
  reg generating;

  initial begin
    render_x   = 0;
    render_y   = 0;
    generating = 0;
  end

  vram_bram vram_inst (
      .clka (clk),
      .ena  (1'b1),
      .wea  (we),
      .addra(waddr),
      .dina (wdata),

      .clkb (clk),
      .enb  (1'b1),
      .addrb(raddr),
      .doutb(rdata)
  );

  assign waddr = render_y * H_LENGTH + render_x; // 由坐标生成需要写入vram的地址

  always @(posedge frame_clk) begin
      generating <= 1;
  end

  always @(posedge clk) begin
    if (!rstn) begin
      render_x   <= 0;
      render_y   <= 0;
      generating <= 0;
    end else if (generating) begin
      render_x <= render_x + 1;
      if (render_x == H_LENGTH - 1) begin
        render_x <= 0;
        render_y <= render_y + 1;
        if (render_y == V_LENGTH - 1) begin
          render_y   <= 0;
          generating <= 0;
        end
      end
    end else begin
      render_x   <= render_x;
      render_y   <= render_y;
      generating <= generating;
    end
  end

  always @(posedge clk) begin
    if (!rstn) begin
      we    <= 0;
      wdata <= 0;
    end else if (generating) begin
      we    <= 1;
      // in-game object color update logic
      // wdata <= in-game object color;


    end else begin
      we    <= 0;
      wdata <= 0;
    end
  end


endmodule
