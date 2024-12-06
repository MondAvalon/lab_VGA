module DisplayUnit #(
    parameter ADDR_WIDTH = 15,
    parameter H_LENGTH   = 200,
    parameter V_LENGTH   = 150
) (
    input rstn,
    input pclk,
    input [11:0] rdata,

    output                  hs,
    output                  vs,
    output [ADDR_WIDTH-1:0] raddr,
    output [          11:0] rgb_out
);

  // 内部连线
  wire h_enable;
  wire v_enable;

  // 实例化DisplaySyncTiming同步时序模块
  DisplaySyncTiming dst (
      .rstn(rstn),
      .pclk(pclk),
      .h_enable(h_enable),
      .v_enable(v_enable),
      .h_sync(hs),
      .v_sync(vs)
  );

  // 实例化DisplayDataProcessor数据处理模块
  DisplayDataProcessor #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .H_LENGTH  (H_LENGTH),
      .V_LENGTH  (V_LENGTH)
  ) ddp (
      .h_enable(h_enable),
      .v_enable(v_enable),
      .rstn(rstn),
      .pclk(pclk),
      .read_data(rdata),
      .rgb_out(rgb_out),
      .read_addr(raddr)
  );

endmodule
