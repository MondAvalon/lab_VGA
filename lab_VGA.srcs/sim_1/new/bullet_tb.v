module Bullet_tb ();

  // 参数定义
  localparam ADDR_WIDTH = 15;
  localparam V_SPEED = 2;
  localparam H_LENGTH = 200;
  localparam V_LENGTH = 150;
  localparam MAX_BULLET = 5;
  localparam COLLISION_THRESHOLD = 20;

  // 时钟和复位信号
  reg clk;
  reg frame_clk;
  reg rstn;

  // 输入信号
  reg [$clog2(H_LENGTH)-1:0] player_x;
  reg [$clog2(H_LENGTH)-1:0] player_y;
  reg [$clog2(H_LENGTH)-1:0] enemy_x;
  reg [$clog2(H_LENGTH)-1:0] enemy_y;
  reg shoot;
  reg [7:0] n_count;
  reg [$clog2(MAX_BULLET)-1:0] lookup_i;

  // 输出信号
  wire [$clog2(H_LENGTH)-1:0] x_out;
  wire [$clog2(H_LENGTH)-1:0] y_out;
  wire display_out;
  wire [$clog2(MAX_BULLET)-1:0] collision;

  // 实例化被测模块
  Bullet #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .V_SPEED(V_SPEED),
      .H_LENGTH(H_LENGTH),
      .V_LENGTH(V_LENGTH),
      .MAX_BULLET(MAX_BULLET),
      .COLLISION_THRESHOLD(COLLISION_THRESHOLD)
  ) u_bullet (
      .clk(clk),
      .frame_clk(frame_clk),
      .rstn(rstn),
      .player_x(player_x),
      .player_y(player_y),
      .enemy_x(enemy_x),
      .enemy_y(enemy_y),
      .shoot(shoot),
      .n_count(n_count),
      .lookup_i(lookup_i),
      .x_out(x_out),
      .y_out(y_out),
      .display_out(display_out),
      .collision(collision)
  );

  // 时钟生成
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    frame_clk = 0;
    forever #20 frame_clk = ~frame_clk;
  end

  // 测试激励
  initial begin
    // 初始化
    rstn = 0;
    player_x = 100;
    player_y = 120;
    enemy_x = 100;
    enemy_y = 20;
    shoot = 0;
    n_count = 0;
    lookup_i = 0;

    // 等待5个时钟周期后释放复位
    #100;
    rstn = 1;

    // 测试发射子弹
    #40;
    shoot = 1;

  end
  // 在现有的 initial 块之后添加以下代码
  initial begin
    // 初始化 lookup_i
    lookup_i = 0;

    // 等待复位完成
    #100;

    // 循环切换 lookup_i
    forever begin
      #40;  // 每40个时间单位切换一次
      lookup_i = (lookup_i + 1) % MAX_BULLET;
    end
  end

  // 监视关键信号
  initial begin
    $monitor("Time=%0t lookup_i=%0d x_out=%0d y_out=%0d display_out=%0b collision=%0b", $time,
             lookup_i, x_out, y_out, display_out, collision);
  end

endmodule
