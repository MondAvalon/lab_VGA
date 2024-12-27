module GameInput (
    input btnc,
    btnl,
    btnr,
    btnu,
    btnd,
    input key_valid,
    input [7:0] key_asci,

    output reg left,
    output reg right,
    output reg shoot,
    output reg space
);

  // assign left  = ps2_data == 8'h1C && (ps2_valid);  //A
  // assign right = ps2_data == 8'h23 && (ps2_valid);  //D
  // assign shoot = ps2_data == 8'h3B && (ps2_valid);  //J
  // assign space = ps2_data == 8'h29 && (ps2_valid);  //Space

  // always @(*) begin
  //   left  = btnl;
  //   right = btnr;
  //   shoot = btnu;
  //   space = btnc;
  // end

  always @(*) begin
    left  = ((key_asci == 8'h1C) && key_valid)||btnl;  //A
    right = ((key_asci == 8'h23) && key_valid)||btnr;  //D
    shoot = ((key_asci == 8'h3B) && key_valid)||btnu;  //J
    space = ((key_asci == 8'h29) && key_valid)||btnc;  //Space
  end

endmodule
