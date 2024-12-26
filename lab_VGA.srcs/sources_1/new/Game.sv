module Game #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH = 200,
    parameter V_LENGTH = 150,
    parameter MAX_BULLET = 5,
    parameter MAX_STAIR = 10,
    parameter X_WHITH = 30,  //物体宽
    parameter Y_WHITH = 36,  //物体高
    parameter STAIR_X = 30,  //台阶宽
    parameter STAIR_Y = 4,  //台阶高
    parameter MOB_X = 70,  //敌机宽
    parameter MOB_Y = 20  //敌机高
) (
    input clk,
    input rstn,
    input frame_clk,
    // input [ADDR_WIDTH-1:0] render_addr,  //渲染坐标/地址

    // 游戏键盘输入
    input left,
    input right,
    input shoot,
    input space,

    output reg        [                 1:0] game_state,                      //游戏状态
    // output in-game object x, y, priority
    //    input      [$clog2(MAX_BULLET)-1:0] bullet_lookup_i,
    output            [                15:0] score,
    output            [                15:0] high_score,
    output reg                               enable_scroll,
    output reg        [                 7:0] n,
    output reg signed [$clog2(V_LENGTH)-1:0] bg_v,
    output            [$clog2(H_LENGTH)-1:0] player_x,
    output            [$clog2(V_LENGTH)-1:0] player_y,
    // output            [$clog2(V_LENGTH)-1:0] player_y_out,
    output            [                 1:0] player_anime_state,
    output            [$clog2(H_LENGTH)-1:0] enemy_x,
    output            [$clog2(V_LENGTH)-1:0] enemy_y,
    output                                   enemy_display,
    output            [$clog2(H_LENGTH)-1:0] bullet_x          [MAX_BULLET],
    output            [$clog2(V_LENGTH)-1:0] bullet_y          [MAX_BULLET],
    output                                   bullet_display    [MAX_BULLET],
    output            [$clog2(H_LENGTH)-1:0] stair_x           [ MAX_STAIR],
    output            [$clog2(V_LENGTH)-1:0] stair_y           [ MAX_STAIR],
    output            [                 1:0] stair_display     [ MAX_STAIR]
);

  wire [7:0] n_count;

  // test
  // assign enemy_x = 100;
  // assign enemy_y = 20;

  // wire player_x_left = player_x - 14;
  // wire player_x_right = player_x + 15;
  // wire player_y_up = player_y - 17;
  wire player_y_down = player_y + 18;
  // wire enemy_x_left = enemy_x - 46;
  // wire enemy_x_right = enemy_x + 47;
  // wire enemy_y_up = enemy_y - 17;
  // wire enemy_y_down = enemy_y + 18;
  // assign stair_display = {1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2};
  // assign stair_x = {20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170};
  // assign stair_y = {10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 10, 20};

  reg  [2:0]  collision;//"1XX"表示触底或碰到敌机失败，"010"表示加速台阶，"011"表示正常碰到台阶反弹，"00X"表示不碰撞
  wire signed [$clog2(V_LENGTH):0] speed_y;  //返回player速度
  // wire arrow_y;  //返回player方向 1为下降，0为上升

  always @(posedge frame_clk) begin  //触底、敌机碰撞、台阶碰撞
    collision <= 3'b000;
    if (speed_y > 0) begin  //台阶
      for (int i = 0; i < MAX_STAIR; i = i + 1) begin
        if ((player_y_down > (stair_y[i] - 7))       && (player_y_down < (stair_y[i] + 3))&&
            (player_x > (stair_x[i]-STAIR_X/2)) && (player_x < (stair_x[i]+STAIR_X/2))) begin
          if (stair_display[i] == 2'b10) begin //判断台阶种类，目前只有一种特殊台阶
            collision <= 3'b011;
          end else if (stair_display[i] == 2'b01) begin
            collision <= 3'b010;
          end
        end
      end
    end

    // if (((player_y+Y_WHITH/2)==(enemy_y-MOB_Y))&&((player_x-X_WHITH/2)==(enemy_x+MOB_X))) begin //敌机逻辑左上
    //   collision[2] <= 1;
    // end
    // if (((player_y+Y_WHITH/2)==(enemy_y-MOB_Y))&&((player_x+X_WHITH/2)==(enemy_x-MOB_X))) begin //敌机逻辑右上
    //   collision[2] <= 1;
    // end
    // if (((player_y-Y_WHITH/2)==(enemy_y+MOB_Y))&&((player_x-X_WHITH/2)==(enemy_x+MOB_X))) begin //敌机逻辑左下
    //   collision[2] <= 1;
    // end
    // if (((player_y-Y_WHITH/2)==(enemy_y+MOB_Y))&&((player_x+X_WHITH/2)==(enemy_x-MOB_X))) begin //敌机逻辑右下
    //   collision[2] <= 1;
    // end
    // if (player_y == (V_LENGTH - 15)) begin  //触底逻辑
    //   collision[2] <= 1;
    // end
    if (collision) begin
      collision <= 3'b000;
    end
  end

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
          if (collision[2]) begin
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

  // 如果玩家y坐标小于100，则bg_v等于-speed_y，player_y_out等于100
  // assign bg_v = (player_y < 100) ? -speed_y : 0;
  // assign player_y_out = (player_y < 100) ? 100 : player_y;

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
      .collision(collision),
      .n_count(n_count),

      .loc_x(player_x),
      .loc_y(player_y),
      .player_anime_state(player_anime_state),
      .speed_y(speed_y)
      // .arrow_y(arrow_y)
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

  Stairs #(
      .H_LENGTH (H_LENGTH),
      .V_LENGTH (V_LENGTH),
      .MAX_STAIR(MAX_STAIR)
  ) stairs_inst (
      .clk(clk),
      .frame_clk(frame_clk),
      .rstn(rstn),
      .enable_scroll(enable_scroll),
      .n(n),
      .v(bg_v),
      .state_x(stair_x),
      .state_y(stair_y),
      .state_mark(stair_display)
  );

  Mob mob_inst (
      .clk(clk),
      .frame_clk(frame_clk),
      .rstn(rstn),
      .enable_scroll(enable_scroll),
      .n_count(n_count),
      .bullet_collision(bullet_inst.collision),

      .loc_x  (enemy_x),
      .loc_y  (enemy_y),
      .display(enemy_display)
  );

  Counter #(8, 255) counter (  // 每个frame_clk计数器减1
      .clk       (frame_clk),
      .rstn      (rstn),
      .load_value(n - 1),
      .enable    (enable_scroll),
      .count     (n_count)
  );

  // Counter #(8, 255) counter_player (  // 每个frame_clk计数器减1
  //     .clk       (frame_clk),
  //     .rstn      (rstn),
  //     .load_value(n - 1),
  //     .enable    (1),
  //     .count     ()
  // );

  initial begin
    enable_scroll = 1;
    n = 3;
    bg_v = 1;
    collision = 0;
  end

endmodule
