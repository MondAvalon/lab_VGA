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
  wire generation_begin;
  reg scroll_enabled;

  reg vram_we;  //写使能
  reg [ADDR_WIDTH-1:0] vram_addr;
  reg [11:0] vram_rgb;
  wire [11:0] menu_rgb;
  wire [11:0] background_rgb;
  wire [11:0] gameover_rgb;

  // Game state definitions
  localparam GAME_MENU = 2'b00;
  localparam GAME_PLAYING = 2'b01;
  localparam GAME_OVER = 2'b10;

  reg [1:0] game_state;
  reg [1:0] next_game_state;

  // State machine sequential logic
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      game_state <= GAME_MENU;
    end else begin
      game_state <= next_game_state;
    end
  end

  // // State machine combinational logic
  // always @(*) begin
  //   next_game_state = game_state;
  //   case (game_state)
  //     GAME_MENU: begin
  //       if (start_button) // Add start_button input if needed
  //         next_game_state = GAME_PLAYING;
  //     end
  //     GAME_PLAYING: begin
  //       if (player_dead) // Add player_dead input if needed
  //         next_game_state = GAME_OVER;
  //     end
  //     GAME_OVER: begin
  //       if (reset_button) // Add reset_button input if needed
  //         next_game_state = GAME_MENU;
  //     end
  //     default: next_game_state = GAME_MENU;
  //   endcase
  // end

  initial begin
    render_addr = 0;
    vram_we = 0;
    scroll_enabled = 1;
    game_state = GAME_MENU;
    next_game_state = GAME_MENU;
  end

  always @(posedge clk) begin
    if (!rstn) begin
      render_addr <= 0;
      vram_we <= 0;
      vram_addr <= 0;
      vram_rgb <= 0;
    end else if (generation_begin) begin
      is_generating_frame <= 1;
    end else if (is_generating_frame) begin
      if (render_addr < H_LENGTH * V_LENGTH - 1) begin
        render_addr <= render_addr + 1;
      end else begin
        render_addr <= 0;
        is_generating_frame <= 0;
      end

      vram_we   <= 1;
      vram_addr <= render_addr;  // 由坐标生成需要写入vram的地址

      // in-game object color update logic
      vram_rgb  <= background_rgb;
      // case (game_state)
      //   GAME_MENU: begin
      //     vram_rgb <= menu_rgb;
      //   end
      //   GAME_PLAYING: begin
      //     vram_rgb <= background_rgb;
      //   end
      //   GAME_OVER: begin
      //     vram_rgb <= gameover_rgb;
      //   end
      //   default: vram_rgb <= 12'h0;
      // endcase
    end else begin
      render_addr <= 0;
      vram_we <= 0;
      vram_addr <= 0;
      vram_rgb <= 0;
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
      .frame_clk(generation_begin),
      .rstn(rstn),
      .scroll_enabled(1),
      .addr(render_addr),  //读取rom中的数据的地址
      .n(6),  //每n个frame_clk
      .rgb(background_rgb)
  );

  Rom_Menu menu (
      .clka(clk),  // input wire clka
      .addra(render_addr),  // input wire [14 : 0] addra
      .douta(menu_rgb)  // output wire [11 : 0] douta
  );

  Rom_Gameover gameover (
      .clka(clk),  // input wire clka
      .addra(render_addr),  // input wire [14 : 0] addra
      .douta(gameover_rgb)  // output wire [11 : 0] douta
  );

  PulseSync #(1) ps (  //frame_clk上升沿
      .sync_in  (frame_clk),
      .clk      (clk),
      .pulse_out(generation_begin)
  );

endmodule
