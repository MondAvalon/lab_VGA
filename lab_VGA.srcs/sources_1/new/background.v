module background #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
) (
    input clk,
    input frame_clk,
    input rstn,
    input scroll_enabled,
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] n,  // 每n个frame_clk更新一次offset，速度分母
    input signed [$clog2(V_LENGTH)-1:0] v,  //速度分子

    output reg [11:0] rgb
);

  reg [ADDR_WIDTH-1:0] scroll_addr;
  reg [ADDR_WIDTH-1:0] scroll_addr_1;  // 前景滚动地址
  reg [ADDR_WIDTH-1:0] offset;  // 偏移量
  reg [ADDR_WIDTH-1:0] offset_1;
  wire [7:0] count;  // 计数器
  // wire [7:0] count_1;  // 前景计数器
  wire alpha_1;
  wire [11:0] rgb_0;
  wire [11:0] rgb_1;
  wire signed [$clog2(V_LENGTH)-1:0] v_1 = v + 1;

  // 使用参数预计算常量值
  localparam MAX_OFFSET = H_LENGTH * V_LENGTH;

  // 在每个frame_clk上升沿更新偏移量
  always @(posedge frame_clk) begin
    if (!rstn) begin
      offset <= 0;
    end else if (scroll_enabled && ~count) begin
      if (offset + H_LENGTH * v >= MAX_OFFSET) offset <= offset + H_LENGTH * v - MAX_OFFSET;
      else offset <= offset + H_LENGTH * v;

      if (offset_1 + H_LENGTH * v_1 >= MAX_OFFSET)
        offset_1 <= offset_1 + H_LENGTH * v_1 - MAX_OFFSET;
      else offset_1 <= offset_1 + H_LENGTH * v_1;

    end
  end

  // 滚动地址计算
  // assign scroll_addr = (addr >= offset) ? (addr - offset) : (MAX_OFFSET - (offset - addr));
  always @(posedge clk) begin
    if (!rstn) begin
      scroll_addr   <= 0;
      scroll_addr_1 <= 0;
    end else if (scroll_enabled) begin
      scroll_addr   <= (addr >= offset) ? (addr - offset) : (MAX_OFFSET - (offset - addr));
      scroll_addr_1 <= (addr >= offset_1) ? (addr - offset_1) : (MAX_OFFSET - (offset_1 - addr));
    end
  end

  // assign rgb = alpha_1 ? rgb_1 : rgb_0;
  always @(posedge clk) begin
    if (!rstn) begin
      rgb <= 0;
    end else begin
      rgb <= alpha_1 ? rgb_1 : rgb_0;
    end
  end

  Rom_Background background (
      .clka (clk),
      .addra(scroll_addr),
      .douta(rgb_0)
  );

  Rom_Background_1 background_1 (
      .clka(clk),  // input wire clka
      .addra(scroll_addr_1),  // input wire [14 : 0] addra
      .douta(rgb_1)  // output wire [11 : 0] douta
  );

  Rom_Background_1_alpha your_instance_name (
      .clka(clk),  // input wire clka
      .addra(scroll_addr_1),  // input wire [14 : 0] addra
      .douta(alpha_1)  // output wire [11 : 0] douta
  );

  Counter #(8, 0) counter (  // 每个frame_clk计数器减1
      .clk       (frame_clk),
      .rstn      (rstn),
      .load_value(n - 1),
      .enable    (1),
      .count     (count)
  );

  // Counter #(8, 0) counter_1 (  // 每个frame_clk计数器减1
  //     .clk       (frame_clk),
  //     .rstn      (rstn),
  //     .load_value(n - 1),
  //     .enable    (1),
  //     .count     (count_1)
  // );

  initial begin
    offset   <= 0;
    offset_1 <= 0;
  end

endmodule
