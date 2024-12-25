module Game #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150,
    parameter MAX_BULLET = 5
) (
    input clk,
    input rstn,
    input frame_clk,
    input [ADDR_WIDTH-1:0] render_addr,  //渲染坐标/地址

    // 游戏键盘输入
    input left,
    input right,
    input shoot,
    input space,

    output reg [                 1:0] game_state,                  //游戏状态
    // output in-game object x, y, priority
    //    input      [$clog2(MAX_BULLET)-1:0] bullet_lookup_i,
    output     [                15:0] score,
    output     [                15:0] high_score,
    output reg                        enable_scroll,
    output reg [                 7:0] n,
    output     [$clog2(H_LENGTH)-1:0] player_x,
    output     [$clog2(V_LENGTH)-1:0] player_y,
    output     [                 1:0] player_anime_state,
    output     [$clog2(H_LENGTH)-1:0] enemy_x,
    output     [$clog2(V_LENGTH)-1:0] enemy_y,
    output     [$clog2(H_LENGTH)-1:0] bullet_x      [MAX_BULLET],
    output     [$clog2(V_LENGTH)-1:0] bullet_y      [MAX_BULLET],
    output                            bullet_display[MAX_BULLET],
    output     [$clog2(H_LENGTH)-1:0] stair_x       [        16],
    output     [$clog2(V_LENGTH)-1:0] stair_y       [        16],
    output     [                 1:0] stair_display [        16]
);

  // wire [$clog2(H_LENGTH)-1:0] next_player_x;
  // wire [$clog2(V_LENGTH)-1:0] next_player_y;
  // wire [$clog2(H_LENGTH)-1:0] next_enemy_x;
  // wire [$clog2(V_LENGTH)-1:0] next_enemy_y;
  // wire [$clog2(H_LENGTH)-1:0] next_bullet_x;
  // wire [$clog2(V_LENGTH)-1:0] next_bullet_y;
  wire [7:0] n_count;

  // test
  assign enemy_x = 100;
  assign enemy_y = 20;
  // assign stair_display = {1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2};
  // assign stair_x = {20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170};
  // assign stair_y = {10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 10, 20};



  // 状态机测试代码，需要具体修改
  // Game state definitions
  localparam GAME_MENU = 2'b00;
  localparam GAME_PLAYING = 2'b01;
  localparam GAME_OVER = 2'b10;

  reg [1:0] next_game_state;

  always @(posedge clk) begin
    if (!rstn) begin
      game_state <= GAME_MENU;
    end else begin
      game_state <= next_game_state;
    end
  end

  // always @(posedge clk) begin
  //   if (!rstn) begin

  //   end
  // end

  // 状态机切换逻辑
  always @(posedge frame_clk) begin
    if (!rstn) begin
      next_game_state <= GAME_MENU;
    end else begin
      case (game_state)
        GAME_MENU: begin
          if (left) begin
            next_game_state <= GAME_PLAYING;
          end else begin
            next_game_state <= GAME_MENU;
          end
        end
        GAME_PLAYING: begin
          if (space) begin
            next_game_state <= GAME_OVER;
          end else begin
            next_game_state <= GAME_PLAYING;
          end
        end
        GAME_OVER: begin
          if (right) begin
            next_game_state <= GAME_MENU;
          end else begin
            next_game_state <= GAME_OVER;
          end
        end
      endcase
    end
  end

  Score score_inst (
      .clk(clk),
      .frame_clk(frame_clk),
      .rstn(rstn),
      .game_state(game_state),
      .n_count(n_count),

      .score(score),
      .high_score(high_score)
  );

  Player player_inst (
      .clk(clk),
      .frame_clk(frame_clk),
      .rstn(rstn),
      .left(left),
      .right(right),
      .shoot(shoot),
      .enable_scroll(enable_scroll),
      .collision(0),
      .n_count(counter_player.count),

      .loc_x(player_x),
      .loc_y(player_y),
      .player_anime_state(player_anime_state)
  );

  Bullet #(
      .MAX_BULLET(MAX_BULLET)
  ) bullet_inst (
      .clk(clk),
      .frame_clk(frame_clk),
      .rstn(rstn),
      //      .enable(!(game_state^GAME_PLAYING)),
      .shoot(shoot),
      .player_x(player_x),
      .player_y(player_y),
      .enemy_x(enemy_x),
      .enemy_y(enemy_y),
      .n_count(n_count),
      //      .lookup_i(bullet_lookup_i),

      .collision(),
      .x(bullet_x),
      .y(bullet_y),
      .display(bullet_display)
  );

  Stairs stairs_inst (
      .clk(clk),
      .frame_clk(frame_clk),
      .rstn(rstn),
      .enable_scroll(enable_scroll),
      .n(n),
      .state_x(stair_x),
      .state_y(stair_y),
      .state_mark(stair_display)
  );

  Counter #(8, 255) counter (  // 每个frame_clk计数器减1
      .clk       (frame_clk),
      .rstn      (rstn),
      .load_value(n - 1),
      .enable    (enable_scroll),
      .count     (n_count)
  );

  Counter #(8, 255) counter_player (  // 每个frame_clk计数器减1
      .clk       (frame_clk),
      .rstn      (rstn),
      .load_value(n),
      .enable    (1),
      .count     ()
  );

  initial begin
    enable_scroll = 1;
    n = 3;
  end

endmodule
