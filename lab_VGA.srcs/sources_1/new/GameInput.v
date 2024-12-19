module GameInput (
    input [7:0] ps2_data,
    input ps2_valid,
    input btnc,
    btnl,
    btnr,
    btnu,
    btnd,

    output reg left,
    output reg right,
    output reg shoot,
    output reg space
);

  // assign left  = ps2_data == 8'h1C && (ps2_valid);  //A
  // assign right = ps2_data == 8'h23 && (ps2_valid);  //D
  // assign shoot = ps2_data == 8'h3B && (ps2_valid);  //J
  // assign space = ps2_data == 8'h29 && (ps2_valid);  //Space

  always @(*) begin
    left  = btnl;
    right = btnr;
    shoot = btnu;
    space = btnc;
  end

endmodule
