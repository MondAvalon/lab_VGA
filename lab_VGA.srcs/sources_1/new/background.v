module background #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
) (
    input clk,
    input frame_clk,
    input rstn,
    input enable_scroll,
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] n,         // 每n个frame_clk更新一次offset，图片向下滚动速度为每秒72/n个像素

    output [11:0] rgb
);

  wire [ADDR_WIDTH-1:0] scroll_addr;
  reg [ADDR_WIDTH-1:0] offset;  // 偏移量
  wire [7:0] count;  // 计数器

  // 在每个frame_clk上升沿偏移量
  always @(posedge frame_clk) begin
    if (!rstn) begin
      offset <= 0;
    end else begin
      if (count == 0&&enable_scroll) begin  // 当计数达到0时，更新offset
        offset <= (offset + H_LENGTH) % (H_LENGTH * V_LENGTH);
      end
    end
  end

  assign scroll_addr = addr + offset;

  Rom_Background background (
      .clka (clk),
      .addra(addr),
      .douta(rgb)
  );

  Counter #(8, 255) counter (// 每个frame_clk计数器减1
      .clk       (frame_clk),
      .rstn      (rstn),
      .load_value(n - 1),
      .enable    (enable_scroll),
      .count     (count)
  );

  initial begin
    offset <= 0;
  end

endmodule
