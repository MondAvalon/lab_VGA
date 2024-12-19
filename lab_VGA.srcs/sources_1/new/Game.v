module Game #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
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

    output reg [1:0] game_state  //游戏状态
    // output in-game object x, y, priority

);

  // 状态机测试代码，需要具体修改
  // Game state definitions
  localparam GAME_MENU = 2'b00;
  localparam GAME_PLAYING = 2'b01;
  localparam GAME_OVER = 2'b10;

  reg [1:0] next_game_state;

  // State machine sequential logic
  always @(posedge clk or negedge rstn) begin
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
          if (space) begin
            next_game_state <= GAME_PLAYING;
          end else begin
            next_game_state <= GAME_MENU;
          end
        end
        GAME_PLAYING: begin
          if (shoot) begin
            next_game_state <= GAME_OVER;
          end else begin
            next_game_state <= GAME_PLAYING;
          end
        end
        GAME_OVER: begin
          if (space) begin
            next_game_state <= GAME_MENU;
          end else begin
            next_game_state <= GAME_OVER;
          end
        end
      endcase
    end
  end

  // Game object definitions
  localparam OBJ_BACKGROUND = 2'b00;
  localparam OBJ_PLAYER = 2'b01;
  localparam OBJ_BULLET = 2'b10;
  localparam OBJ_STAIR = 2'b11;
  localparam OBJ_OBSTACLE = 3'b100;
  localparam OBJ_PUDDING = 3'b101;
  localparam OBJ_BOSS = 3'b110;

  reg [2:0] obj_type;
  reg [2:0] next_obj_type;

  // State machine sequential logic
  always @(posedge frame_clk) begin
    if (!rstn) begin
      obj_type <= OBJ_BACKGROUND;
    end else begin
      obj_type <= next_obj_type;
    end
  end

  // Game object logic
  always @(posedge frame_clk) begin
    if (!rstn) begin
      next_obj_type <= OBJ_BACKGROUND;
    end else begin
      case (game_state)
        GAME_MENU: begin
          next_obj_type <= OBJ_BACKGROUND;
        end
        GAME_PLAYING: begin
          next_obj_type <= OBJ_PLAYER;
        end
        GAME_OVER: begin
          next_obj_type <= OBJ_BACKGROUND;
        end
      endcase
    end
  end

endmodule
