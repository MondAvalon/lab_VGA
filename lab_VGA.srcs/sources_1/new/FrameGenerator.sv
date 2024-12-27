//获取VGA信号的同步信号，根据游戏对象的坐标与优先级等生成一个固定的分辨率的图像
module FrameGenerator #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH = 200,
    parameter V_LENGTH = 150,
    parameter MAX_BULLET = 5,
    parameter MAX_STAIR = 10,
    parameter MAX_HP = 20
) (
    input ram_clk,
    input rom_clk,
    input clk,
    input frame_clk,
    input rstn,

    //input in-game x, y
    input        [                 1:0] game_state,
    input                               scroll_enabled,
    input        [                 7:0] n,
    input signed [$clog2(V_LENGTH)-1:0] v,
    input        [                15:0] score,
    input        [                15:0] high_score,
    input        [$clog2(H_LENGTH)-1:0] player_x,
    input        [$clog2(V_LENGTH)-1:0] player_y,
    input        [                 1:0] player_anime_state,
    input        [$clog2(H_LENGTH)-1:0] boss_x,
    input        [$clog2(V_LENGTH)-1:0] boss_y,
    input                               boss_display,
    input        [                 9:0] boss_HP,
    input        [$clog2(H_LENGTH)-1:0] bullet_x          [MAX_BULLET],
    input        [$clog2(V_LENGTH)-1:0] bullet_y          [MAX_BULLET],
    input                               bullet_display    [MAX_BULLET],
    input        [$clog2(H_LENGTH)-1:0] stair_x           [ MAX_STAIR],
    input        [$clog2(V_LENGTH)-1:0] stair_y           [ MAX_STAIR],
    input        [                 1:0] stair_display     [ MAX_STAIR],

    // output VGA signal
    input [ADDR_WIDTH-1:0] raddr,
    output [11:0] rdata
);

  localparam X_MAX = H_LENGTH - 1;
  localparam Y_MAX = V_LENGTH - 1;

  // typedef enum {
  //   GAME_MENU,
  //   GAME_PLAYING,
  //   GAME_OVER,
  //   GAME_WIN
  // } game_state_t;
  localparam GAME_MENU = 2'b00;
  localparam GAME_PLAYING = 2'b01;
  localparam GAME_OVER = 2'b10;
  localparam GAME_WIN = 2'b11;

  typedef enum {
    IDLE,
    RENDER_BACKGROUND,
    RENDER_STAIR,
    RENDER_BULLET,
    RENDER_BOSS,
    RENDER_PLAYER,
    RENDER_WIN,
    RENDER_BACKGROUND_1,
    RENDER_BOSS_HP,
    RENDER_SCORE,
    RENDER_HIGH_SCORE,
    RENDER_FLAN
  } render_state_t;

  reg [$clog2(H_LENGTH)-1:0] render_x;
  reg [$clog2(V_LENGTH)-1:0] render_y;
  reg [$clog2(H_LENGTH)-1:0] render_x_prev;
  reg [$clog2(V_LENGTH)-1:0] render_y_prev;

  wire [$clog2 (H_LENGTH)-1:0] player_x_left, player_x_right;
  wire [$clog2 (H_LENGTH)-1:0] flan_x_left, flan_x_right;
  wire [$clog2 (H_LENGTH)-1:0] boss_x_left, boss_x_right;
  wire [$clog2 (H_LENGTH)-1:0] bullet_x_left, bullet_x_right;
  // wire [$clog2 (H_LENGTH)-1:0] next_bullet_x_left, next_bullet_x_right;
  wire [$clog2 (H_LENGTH)-1:0] stair_x_left, stair_x_right;

  wire [$clog2 (V_LENGTH)-1:0] player_y_up, player_y_down;
  wire [$clog2 (V_LENGTH)-1:0] flan_y_up, flan_y_down;
  wire [$clog2 (V_LENGTH)-1:0] boss_y_up, boss_y_down;
  wire [$clog2 (V_LENGTH)-1:0] bullet_y_up, bullet_y_down;
  // wire [$clog2 (V_LENGTH)-1:0] next_bullet_y_up, next_bullet_y_down;
  wire [$clog2 (V_LENGTH)-1:0] stair_y_up, stair_y_down;

  reg [$clog2(MAX_BULLET)-1:0] bullet_index;
  reg [3:0] stair_index;

  assign player_x_left = player_x - 14;
  assign player_x_right = player_x + 15;
  assign player_y_up = player_y - 17;
  assign player_y_down = player_y + 18;
  assign boss_x_left = boss_x - 46;
  assign boss_x_right = boss_x + 47;
  assign boss_y_up = boss_y - 17;
  assign boss_y_down = boss_y + 18;

  assign flan_x_left = player_x - 14;
  assign flan_x_right = player_x + 15;
  assign flan_y_up = player_y - 52;
  assign flan_y_down = player_y - 17;

  assign bullet_x_left = bullet_x[bullet_index] - 4;
  assign bullet_x_right = bullet_x[bullet_index] + 4;
  assign bullet_y_up = bullet_y[bullet_index] - 7;
  assign bullet_y_down = bullet_y[bullet_index] + 16;
  assign bullet_x_left = bullet_x[bullet_index] - 4;
  assign bullet_x_right = bullet_x[bullet_index] + 4;
  assign bullet_y_up = bullet_y[bullet_index] - 7;
  assign bullet_y_down = bullet_y[bullet_index] + 16;
  wire [$clog2(H_LENGTH)-1:0] bullet_x_left_next = bullet_x[bullet_index+1] - 4;
  wire [$clog2(V_LENGTH)-1:0] bullet_y_up_next = bullet_y[bullet_index+1] - 7;

  assign stair_x_left = stair_x[stair_index] - 14;
  assign stair_x_right = stair_x[stair_index] + 15;
  assign stair_y_up = stair_y[stair_index] - 1;
  assign stair_y_down = stair_y[stair_index] + 2;
  wire [$clog2(H_LENGTH)-1:0] stair_x_left_next = stair_x[stair_index+1] - 14;
  wire [$clog2(V_LENGTH)-1:0] stair_y_up_next = stair_y[stair_index+1] - 1;

  wire generation_begin;

  reg vram_we;  //写使能
  reg [ADDR_WIDTH-1:0] vram_addr;
  reg [11:0] vram_rgb;
  wire [11:0] menu_rgb;
  wire [11:0] background_rgb;  //背景
  wire [11:0] background_rgb_1;  //前景
  wire background_alpha_1;
  wire [11:0] gameover_rgb;
  wire win_alpha;

  // reg [1:0] player_anime_state;
  render_state_t render_state, next_render_state;
  reg  [           6:0] object_y;  // 高128
  reg  [           7:0] object_x;  // 宽256
  wire [ADDR_WIDTH-1:0] object_addr;
  // reg [ADDR_WIDTH-1:0] object_addr_prev;
  wire [          11:0] object_rgb;
  wire                  object_alpha;

  wire [ADDR_WIDTH-1:0] render_addr;
  assign render_addr = render_y * H_LENGTH + render_x;
  assign object_addr = {object_y, object_x};
  // always @(posedge clk) begin
  //   if (~rstn) begin
  //     object_addr_prev <= 0;
  //   end else begin
  //     object_addr_prev <= object_addr;
  //   end
  // end

  wire [ADDR_WIDTH-1:0] render_addr_next = render_addr + 1;

  // 显示坐标常量

  localparam ADDR_MAX = H_LENGTH * V_LENGTH - 1;
  localparam [7:0] SCORE_POS_X[0:3] = {8'd1, 8'd11, 8'd21, 8'd31};
  localparam SCORE_POS_Y = 140;
  localparam [7:0] SCORE_POS_X_MAX[0:3] = {8'd10, 8'd20, 8'd30, 8'd40};
  localparam SCORE_POS_Y_MAX = 149;

  // 游戏对象ROM坐标常量
  // 数字0-9的ROM坐标
  localparam [7:0] NUM_X_ROM[0:9] = {
    8'd0, 8'd10, 8'd20, 8'd30, 8'd40, 8'd50, 8'd60, 8'd70, 8'd80, 8'd90
  };
  localparam NUM_Y_ROM = 36;
  // 玩家坐标
  localparam [7:0] PLAYER_X_ROM[0:3] = {8'd0, 8'd30, 8'd60, 8'd90};
  localparam PLAYER_Y_ROM = 0;
  // boss坐标
  localparam BOSS_X_ROM = 150;
  localparam BOSS_Y_ROM = 0;
  // 子弹坐标
  localparam BULLET_X_ROM = 100;
  localparam BULLET_Y_ROM = 36;
  // 障碍物坐标
  localparam [7:0] OBSTACLE_X_ROM[0:4] = {8'd0, 8'd16, 8'd32, 8'd48, 8'd64};
  localparam OBSTACLE_Y_ROM = 46;
  // 布丁道具坐标
  localparam PUDDING_X_ROM = 109;
  localparam PUDDING_Y_ROM = 36;
  // 残机道具坐标
  localparam ONEUP_X_ROM = 80;
  localparam ONEUP_Y_ROM = 46;
  // 平台坐标
  localparam [7:0] STAIR_X_ROM[2:1] = {8'd0, 8'd30};
  localparam STAIR_Y_ROM = 62;
  // 芙兰朵露坐标
  localparam FLAN_X_ROM = 120;
  localparam FLAN_Y_ROM = 0;


  reg [1:0] score_digit;  // 当前渲染第几位数字(0-3)
  reg [1:0] next_score_digit;  // 下一个渲染的数字位数
  reg [3:0] current_digit;  // 当前渲染的数字值

  // 读取分数当前位数字
  always @(*) begin
    case (score_digit)
      0: current_digit = (render_state ^ RENDER_SCORE) ? high_score[15:12] : score[15:12];
      1: current_digit = (render_state ^ RENDER_SCORE) ? high_score[11:8] : score[11:8];
      2: current_digit = (render_state ^ RENDER_SCORE) ? high_score[7:4] : score[7:4];
      3: current_digit = (render_state ^ RENDER_SCORE) ? high_score[3:0] : score[3:0];
      default: current_digit = 0;
    endcase
  end

  // 读取贴图的坐标
  always @(*) begin
    case (render_state)
      RENDER_SCORE, RENDER_HIGH_SCORE: begin
        object_x = NUM_X_ROM[current_digit] + render_x - SCORE_POS_X[score_digit];
        object_y = NUM_Y_ROM + render_y - SCORE_POS_Y;
      end
      RENDER_PLAYER: begin
        object_x = PLAYER_X_ROM[player_anime_state] + render_x - player_x_left;
        object_y = PLAYER_Y_ROM + render_y - player_y_up;
      end
      RENDER_BOSS: begin
        object_x = BOSS_X_ROM + render_x - boss_x_left;
        object_y = BOSS_Y_ROM + render_y - boss_y_up;
      end
      RENDER_BULLET: begin
        object_x = BULLET_X_ROM + render_x - bullet_x_left;
        object_y = BULLET_Y_ROM + render_y - bullet_y_up;
      end
      RENDER_STAIR: begin
        object_x = STAIR_X_ROM[stair_display[stair_index]] + render_x - stair_x_left;
        object_y = STAIR_Y_ROM + render_y - stair_y_up;
      end
      RENDER_FLAN: begin
        object_x = FLAN_X_ROM + render_x - flan_x_left;
        object_y = FLAN_Y_ROM + render_y - flan_y_up;
      end
      default: begin
        object_x = 0;
        object_y = 0;
      end
    endcase
  end

  always @(posedge clk) begin
    if (~rstn) begin
      render_x_prev <= 0;
      render_y_prev <= 0;
    end else begin
      render_x_prev <= render_x;
      render_y_prev <= render_y;
    end

  end

  // reg [$clog2(MAX_BULLET)-1:0] next_bullet_index;

  // 渲染状态机转换
  always @(posedge clk) begin
    if (~rstn) begin
      render_state <= IDLE;
      // score_digit  <= 0;
      // bullet_index <= 0;
    end else begin
      render_state <= next_render_state;
      // score_digit  <= next_score_digit;
      // bullet_index <= next_bullet_index;
    end
  end

  // 渲染状态机转换
  always @(*) begin
    case (render_state)
      IDLE: begin
        next_render_state = generation_begin ? RENDER_BACKGROUND : IDLE;
      end
      RENDER_BACKGROUND: begin
        // next_render_state = (!(render_x ^ X_MAX) && !(render_y ^ Y_MAX)) ? 
        //                     (((game_state ^ GAME_MENU) && (game_state ^ GAME_OVER)) ? RENDER_STAIR: RENDER_HIGH_SCORE) : 
        //                     RENDER_BACKGROUND;
        if (!(render_x ^ X_MAX) && !(render_y ^ Y_MAX)) begin
          case (game_state)
            GAME_PLAYING: next_render_state = RENDER_STAIR;
            GAME_WIN: next_render_state = RENDER_FLAN;
            default: next_render_state = RENDER_HIGH_SCORE;
          endcase
        end else begin
          next_render_state = RENDER_BACKGROUND;
        end
      end
      RENDER_STAIR: begin
        next_render_state = (!(render_x ^ stair_x_right) && 
                             !(render_y ^ stair_y_down) && 
                             stair_index==MAX_STAIR-1) ? 
                            RENDER_BULLET : 
                            RENDER_STAIR;
      end
      RENDER_BULLET: begin
        next_render_state = (!(render_x ^ bullet_x_right) &&
                             !(render_y ^ bullet_y_down) && 
                             bullet_index==MAX_BULLET-1) ? 
                            RENDER_PLAYER : 
                            RENDER_BULLET;
        // if (render_x == bullet_x_right && render_y == bullet_y_down) begin
        //   if (bullet_index == MAX_BULLET-1) next_bullet_index = 0;
        //   else next_bullet_index = bullet_index + 1;
        // end
      end
      RENDER_PLAYER: begin
        // next_render_state = !(render_x ^ player_x_right) && !(render_y ^ player_y_down) ? RENDER_BOSS : RENDER_PLAYER;
        if (!(render_x ^ player_x_right) && !(render_y ^ player_y_down)) begin
          case (game_state)
            GAME_PLAYING: next_render_state = RENDER_BOSS;
            GAME_WIN: next_render_state = RENDER_WIN;
          endcase
        end else begin
          next_render_state = RENDER_PLAYER;
        end
      end
      RENDER_WIN: begin
        next_render_state = (!(render_x ^ X_MAX) && !(render_y ^ Y_MAX)) ? IDLE : RENDER_WIN;
      end
      RENDER_BOSS: begin
        next_render_state = (!(render_x ^ boss_x_right) && !(render_y ^ boss_y_down)) ? RENDER_BACKGROUND_1 : RENDER_BOSS;
      end
      RENDER_BACKGROUND_1: begin
        next_render_state = (!(render_x ^ X_MAX) && !(render_y ^ Y_MAX)) ? RENDER_BOSS_HP : RENDER_BACKGROUND_1;
      end
      RENDER_BOSS_HP: begin
        next_render_state = (!(render_x ^ X_MAX) && !(render_y ^ 1)) ? RENDER_SCORE : RENDER_BOSS_HP;
      end
      RENDER_SCORE: begin
        next_render_state = (!(render_x ^ SCORE_POS_X_MAX[3]) && !(render_y ^ SCORE_POS_Y_MAX)) ? 
                              IDLE : 
                              RENDER_SCORE;
        // next_score_digit = !(render_x ^ SCORE_POS_X_MAX[score_digit]) && !(render_y ^ SCORE_POS_Y_MAX) ? 
        //                     (!(render_x ^ SCORE_POS_X_MAX[3]) ? 0 : score_digit + 1) : 
        //                     score_digit;
      end
      RENDER_HIGH_SCORE: begin
        next_render_state = (!(render_x ^ SCORE_POS_X_MAX[3]) && !(render_y ^ SCORE_POS_Y_MAX)) ? 
                            IDLE : 
                            RENDER_HIGH_SCORE;
        // next_score_digit = !(render_x ^ SCORE_POS_X_MAX[score_digit]) && !(render_y ^ SCORE_POS_Y_MAX) ? 
        //                     (!(render_x ^ SCORE_POS_X_MAX[3]) ? 0 : score_digit + 1) : 
        //                     score_digit;
      end
      RENDER_FLAN: begin
        next_render_state = !(render_x ^ flan_x_right) && !(render_y ^ flan_y_down) ? RENDER_PLAYER : RENDER_FLAN;
      end
      default: begin
        next_render_state = IDLE;
        // next_score_digit  = 0;
      end
    endcase
  end

  // 渲染状态机
  always @(posedge clk) begin
    if (~rstn) begin
      render_x  <= 0;
      render_y  <= 0;
      vram_we   <= 0;
      vram_addr <= 0;
      vram_rgb  <= 0;
      // next_render_state <= IDLE;
    end else begin
      vram_addr <= render_addr;
      case (render_state)
        IDLE: begin
          vram_we  <= 0;
          render_x <= -1;
          render_y <= 0;
          vram_rgb <= 0;
        end
        RENDER_BACKGROUND: begin
          vram_we <= 1;
          score_digit <= 0;
          // vram_rgb <= ((game_state^GAME_MENU))?((game_state^GAME_PLAYING)?gameover_rgb:background_rgb ):menu_rgb;
          case (game_state)
            GAME_PLAYING, GAME_WIN: vram_rgb <= background_rgb;
            GAME_MENU: vram_rgb <= menu_rgb;
            GAME_OVER: vram_rgb <= gameover_rgb;
            default: vram_rgb <= 0;
          endcase

          if (!(render_x ^ X_MAX)) begin
            if (!(render_y ^ Y_MAX)) begin  //完成全部背景的渲染
              // if (!((game_state ^ GAME_MENU) && (game_state ^ GAME_OVER))) begin
              //   // next_render_state <= RENDER_HIGH_SCORE;
              //   render_x <= SCORE_POS_X[0];
              //   render_y <= SCORE_POS_Y;
              // end else if (!(game_state ^ GAME_PLAYING)) begin
              //   // next_render_state <= RENDER_STAIR;
              //   render_x <= stair_x_left;
              //   render_y <= stair_y_up;
              // end
              case (game_state)
                GAME_PLAYING: begin
                  // next_render_state <= RENDER_STAIR;
                  render_x <= stair_x_left;
                  render_y <= stair_y_up;
                end
                GAME_WIN: begin
                  // next_render_state <= RENDER_FLAN;
                  render_x <= flan_x_left;
                  render_y <= flan_y_up;
                end
                default: begin
                  // next_render_state <= RENDER_HIGH_SCORE;
                  render_x <= SCORE_POS_X[0];
                  render_y <= SCORE_POS_Y;
                end
              endcase
            end else begin  //完成一行的渲染
              render_y <= render_y + 1;
              render_x <= 0;
            end
          end else begin
            render_x <= render_x + 1;
          end
        end
        RENDER_STAIR: begin
          vram_we <= object_alpha && stair_display[stair_index];
          vram_rgb <= object_rgb;
          score_digit <= 0;
          if (!(render_x ^ stair_x_right)) begin
            if (!(render_y ^ stair_y_down)) begin
              if (!(stair_index ^ MAX_STAIR - 1)) begin  // 全部台阶渲染完成
                // next_render_state <= RENDER_BULLET;
                render_x <= bullet_x_left;
                render_y <= bullet_y_up;
                stair_index <= 0;
              end else begin  // 下一个台阶
                stair_index <= stair_index + 1;
                render_x <= stair_x_left_next;
                render_y <= stair_y_up_next;
              end
            end else begin  //下一行
              render_x <= stair_x_left;
              render_y <= render_y + 1;
            end
          end else begin
            render_x <= render_x + 1;
          end
        end
        RENDER_BULLET: begin
          vram_we <= object_alpha && bullet_display[bullet_index];
          vram_rgb <= object_rgb;
          score_digit <= 0;
          if (!(render_x ^ bullet_x_right)) begin
            if (!(render_y ^ bullet_y_down)) begin
              if (!(bullet_index ^ (MAX_BULLET - 1))) begin  // 全部子弹渲染完成
                // next_render_state <= RENDER_PLAYER;
                render_x <= player_x_left;
                render_y <= player_y_up;
                bullet_index <= 0;
              end else begin  // 下一个子弹
                bullet_index <= bullet_index + 1;
                render_x <= bullet_x_left_next;
                render_y <= bullet_y_up_next;
              end
            end else begin  //下一行
              render_x <= bullet_x_left;
              render_y <= render_y + 1;
            end
          end else begin
            render_x <= render_x + 1;
          end
        end
        RENDER_PLAYER: begin
          vram_we <= object_alpha;
          vram_rgb <= object_rgb;
          score_digit <= 0;
          if (!(render_x ^ player_x_right)) begin
            if (!(render_y ^ player_y_down)) begin
              // next_render_state <= RENDER_BOSS;
              render_x <= boss_x_left;
              render_y <= boss_y_up;
              if (game_state == GAME_WIN) begin
                render_x <= 0;
                render_y <= 0;
              end
            end else begin
              render_x <= player_x_left;
              render_y <= render_y + 1;
            end
          end else begin
            render_x <= render_x + 1;
          end
        end
        RENDER_WIN: begin
          vram_we <= win_alpha;
          vram_rgb <= 12'hfff;
          score_digit <= 0;
          if (!(render_x ^ X_MAX)) begin
            if (!(render_y ^ Y_MAX)) begin  //完成全部的渲染
              // next_render_state <= IDLE
              render_x <= 0;
              render_y <= 0;
            end else begin  //完成一行的渲染
              render_y <= render_y + 1;
              render_x <= 0;
            end
          end else begin
            render_x <= render_x + 1;
          end
        end
        RENDER_BOSS: begin
          vram_we <= object_alpha && boss_display;
          vram_rgb <= object_rgb;
          score_digit <= 0;
          if (!(render_x ^ boss_x_right)) begin
            if (!(render_y ^ boss_y_down)) begin
              // next_render_state <= RENDER_BACKGROUND_1;
              render_x <= 0;
              render_y <= 0;
            end else begin
              render_x <= boss_x_left;
              render_y <= render_y + 1;
            end
          end else begin
            render_x <= render_x + 1;
          end
        end
        RENDER_BACKGROUND_1: begin
          vram_we <= background_alpha_1;
          vram_rgb <= background_rgb_1;
          score_digit <= 0;
          // if (!(render_x ^ X_MAX)) begin
          //   if (!(render_y ^ Y_MAX)) begin  //完成全部背景的渲染
          //     // next_render_state <= RENDER_SCORE;
          //     // render_x <= SCORE_POS_X[0];
          //     // render_y <= SCORE_POS_Y;

          //     // next_render_state <= RENDER_BOSS_HP;
          //     render_x <= 0;
          //     render_y <= 0;
          //   end else begin  //完成一行的渲染
          //     render_y <= render_y + 1;
          //     render_x <= 0;
          //   end
          // end else begin
          //   render_x <= render_x + 1;
          // end
          if (render_x < X_MAX) begin
            render_x <= render_x + 1;
          end else begin
            if (render_y < Y_MAX) begin
              render_y <= render_y + 1;
              render_x <= 0;
            end else begin
              // next_render_state <= RENDER_BOSS_HP;
              render_y <= 0;
              render_x <= 0;
            end
          end
        end
        RENDER_BOSS_HP: begin
          vram_we <= ((boss_HP * H_LENGTH) / MAX_HP) > render_x;
          // vram_we <= 0;
          vram_rgb <= 12'h0f0;
          score_digit <= 0;
          // if (!(render_x ^ X_MAX)) begin
          //   if (!(render_y ^ 1)) begin  //完成全部的渲染
          //     // next_render_state <= RENDER_SCORE;
          //     render_x <= SCORE_POS_X[0];
          //     render_y <= SCORE_POS_Y;
          //   end else begin  //完成一行的渲染
          //     render_y <= render_y + 1;
          //     render_x <= 0;
          //   end
          // end else begin
          //   render_x <= render_x + 1;
          // end
          if (render_x < X_MAX) begin
            render_x <= render_x + 1;
          end else begin
            if (render_y < 1) begin
              render_y <= render_y + 1;
              render_x <= 0;
            end else begin
              // next_render_state <= RENDER_SCORE;
              render_y <= SCORE_POS_Y;
              render_x <= SCORE_POS_X[0];
            end
          end
        end
        RENDER_SCORE: begin
          vram_rgb <= object_rgb;
          vram_we  <= object_alpha;
          if (!(render_x ^ SCORE_POS_X_MAX[score_digit])) begin
            if (!(render_y ^ SCORE_POS_Y_MAX)) begin  // 完成一个数字渲染
              if (!(score_digit ^ 3)) begin  // 完成所有数字
                // next_render_state <= IDLE;
                render_x <= 0;
                render_y <= 0;
                score_digit <= 0;
              end else begin  // 进入下一个数字
                // render_x <= SCORE_POS_X[score_digit+1];
                render_x <= render_x + 1;
                render_y <= SCORE_POS_Y;
                score_digit <= score_digit + 1;
              end
            end else begin  // 下一行
              render_y <= render_y + 1;
              render_x <= SCORE_POS_X[score_digit];
            end
          end else begin  // 下一列
            render_x <= render_x + 1;
          end
        end
        RENDER_HIGH_SCORE: begin
          vram_rgb <= object_rgb;
          vram_we  <= object_alpha;
          if (!(render_x ^ SCORE_POS_X_MAX[score_digit])) begin
            if (!(render_y ^ SCORE_POS_Y_MAX)) begin  // 完成一个数字渲染
              if (!(score_digit ^ 3)) begin  // 完成所有数字
                // next_render_state <= IDLE;
                score_digit <= 0;
                render_x <= 0;
                render_y <= 0;
              end else begin  // 进入下一个数字
                // render_x <= SCORE_POS_X[score_digit+1];
                render_x <= render_x + 1;
                render_y <= SCORE_POS_Y;
                score_digit <= score_digit + 1;
              end
            end else begin  // 下一行
              render_y <= render_y + 1;
              render_x <= SCORE_POS_X[score_digit];
            end
          end else begin  // 下一列
            render_x <= render_x + 1;
          end
        end
        RENDER_FLAN: begin
          vram_we <= object_alpha;
          vram_rgb <= object_rgb;
          score_digit <= 0;
          if (render_x < X_MAX) begin
            render_x <= render_x + 1;
          end else begin
            if (render_y < Y_MAX) begin
              render_y <= render_y + 1;
              render_x <= 0;
            end else begin
              // next_render_state <= RENDER_PLAYER;
              render_y <= player_y_up;
              render_x <= player_x_left;
            end
          end
        end
      endcase
    end
  end


  vram_bram vram_inst (
      .clka (clk),
      .wea  (vram_we),
      .addra(vram_addr),
      .dina (vram_rgb),

      .clkb (ram_clk),
      .addrb(raddr),
      .doutb(rdata)
  );

  background #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) background_inst (
      .clk(rom_clk),
      .frame_clk(frame_clk),
      .rstn(rstn),
      .scroll_enabled(scroll_enabled),
      .addr(render_addr),  //读取rom中的数据的地址
      .n(n),  //每n个frame_clk
      .v(v),  //每次滚动的像素数
      .rgb_0(background_rgb),
      .rgb_1(background_rgb_1),
      .alpha_1(background_alpha_1)
  );

  Rom_Menu menu (
      .clka(clk),  // input wire clka
      .addra(render_addr_next),  // input wire [14 : 0] addra
      .douta(menu_rgb)  // output wire [11 : 0] douta
  );

  Rom_Gameover gameover (
      .clka(clk),  // input wire clka
      .addra(render_addr_next),  // input wire [14 : 0] addra
      .douta(gameover_rgb)  // output wire [11 : 0] douta
  );

  Rom_Win_alpha your_instance_name (
      .clka(clk),  // input wire clka
      .addra(render_addr_next),  // input wire [14 : 0] addra
      .douta(win_alpha)  // output wire [11 : 0] douta
  );

  // 256x128
  Rom_Item objects (
      .clka(rom_clk),  // input wire clka
      .addra(object_addr),  // input wire [14 : 0] addra
      .douta(object_rgb)  // output wire [11 : 0] douta
  );

  // 256x128
  Rom_Item_alpha objects_alpha (
      .clka(rom_clk),  // input wire clka
      .addra(object_addr),  // input wire [14 : 0] addra
      .douta(object_alpha)  // output wire [0 : 0] douta
  );

  PulseSync #(1) ps (  //frame_clk上升沿
      .sync_in  (frame_clk),
      .clk      (clk),
      .pulse_out(generation_begin)
  );

  initial begin
    render_x = 0;
    render_y = 0;
    vram_we = 0;
    vram_addr = 0;
    vram_rgb = 0;
    render_state = IDLE;
    next_render_state = IDLE;
    score_digit = 0;
    next_score_digit = 0;
    current_digit = 0;
    object_y = 0;
    object_x = 0;
    bullet_index = 0;
    // next_bullet_index = 0;
  end

endmodule
