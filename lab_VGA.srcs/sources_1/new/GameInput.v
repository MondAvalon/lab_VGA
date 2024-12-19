module GameInput (
    input [7:0] ps2_data,
    input ps2_valid,
    input BTNC,
    BTNL,
    BTNR,
    BTNU,
    BTND,

    output left,
    output right,
    output shoot,
    output space
);

  // assign left  = ps2_data == 8'h1C && (ps2_valid);  //A
  // assign right = ps2_data == 8'h23 && (ps2_valid);  //D
  // assign shoot = ps2_data == 8'h3B && (ps2_valid);  //J
  // assign space = ps2_data == 8'h29 && (ps2_valid);  //Space

  assign left  = BTNL;
  assign right = BTNR;
  assign shoot = BTNU;
  assign space = BTNC;

endmodule
