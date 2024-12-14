module microphone(
   input      clk,
   input      rst,
   output reg led,
   input      sd_sw,   // a switch to control the amplifier
   
   // Port to microphone
   output reg MIC_CLK,
   input      MIC_DATA,
   output reg MIC_LR_SEL,
   
   // Port to mono audio output
   output reg AUD_PWM,
   output reg AUD_SD
);
// Generate 2.5MHz to MIC_CLK, and rising edge detection
reg [7:0] MIC_CLK_count;
reg       MIC_CLK_d;
wire      MIC_CLK_posedge;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        MIC_CLK <= 1'b0;
        MIC_CLK_count <= 8'd0;
    end
    else if(MIC_CLK_count < 8'd19) begin
        MIC_CLK_count <= MIC_CLK_count + 8'd1;
    end
    else begin
        MIC_CLK <= ~MIC_CLK;
        MIC_CLK_count <= 8'd0;
    end
end

always @(posedge clk) begin
    MIC_CLK_d <= MIC_CLK;
end
assign MIC_CLK_posedge = ({MIC_CLK_d, MIC_CLK}==2'b01) ? 1'b1 : 1'b0;
// PWM counter increase every rising edge of MIC_CLK
// period is 128
genvar i;
reg [7:0] PDM_counter;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        PDM_counter <= 8'd0;
    end
    else if(MIC_CLK_posedge) begin
        if(PDM_counter == 8'd127) begin
            PDM_counter <= 8'd0;
        end
        else begin
            PDM_counter <= PDM_counter + 8'd1;
        end
    end
end

// ten counters control, start by floor(12.8*i)
localparam [8*10-1:0] PWM_thresh_counter_start = 
{8'd115, 8'd102, 8'd89, 8'd76, 8'd64, 
8'd51, 8'd38, 8'd25, 8'd12, 8'd0};

reg [7:0] PWM_thresh_counter[9:0];
generate
    for(i=0; i<10; i=i+1) begin : PWM_COUNTERS
        always @(posedge clk or posedge rst) begin
            if(rst) begin
                PWM_thresh_counter[i] <= 8'd0;
            end
            else if(MIC_CLK_posedge && (PDM_counter == PWM_thresh_counter_start[8*i+7:8*i])) begin
                PWM_thresh_counter[i] <= (MIC_DATA) ? 8'd1 : 8'd0;
            end
            else if(MIC_CLK_posedge) begin
                PWM_thresh_counter[i] <= (MIC_DATA) ? PWM_thresh_counter[i] + 8'd1 : PWM_thresh_counter[i];
            end
        end
    end
endgenerate
reg [15:0] PWM_count;
reg [15:0] led_threshold;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        PWM_count <= 16'd0;
        led_threshold <= 16'h0;
        MIC_LR_SEL <= 1'b0;
    end
    else begin
        PWM_count <= (PWM_count == 16'd5119) ? 16'd0 : PWM_count + 16'd1;
        case(PWM_count)
        16'd0    : begin led_threshold <= {6'h0, PWM_thresh_counter[0], 2'b00}; end
        16'd480  : begin led_threshold <= {6'h0, PWM_thresh_counter[1], 2'b00}; end
        16'd1000 : begin led_threshold <= {6'h0, PWM_thresh_counter[2], 2'b00}; end
        16'd1520 : begin led_threshold <= {6'h0, PWM_thresh_counter[3], 2'b00}; end
        16'd2040 : begin led_threshold <= {6'h0, PWM_thresh_counter[4], 2'b00}; end
        16'd2560 : begin led_threshold <= {6'h0, PWM_thresh_counter[5], 2'b00}; end
        16'd3040 : begin led_threshold <= {6'h0, PWM_thresh_counter[6], 2'b00}; end
        16'd3560 : begin led_threshold <= {6'h0, PWM_thresh_counter[7], 2'b00}; end
        16'd4080 : begin led_threshold <= {6'h0, PWM_thresh_counter[8], 2'b00}; end
        16'd4600 : begin led_threshold <= {6'h0, PWM_thresh_counter[9], 2'b00}; end
        endcase
        MIC_LR_SEL <= 1'b0;
    end
end
// Drive led based on MIC_DATA, by generating PWM wave
reg [15:0] led_count;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        led_count <= 16'd0;
    end
    else if(led_count < 16'd512) begin
        led_count <= led_count + 16'd1;
    end
    else begin
        led_count <= 16'd0;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        led <= 1'b0;
    end
    else begin
        if(led_count<led_threshold) begin
            led <= 1'b1;
        end
        else begin
            led <= 1'b0;
        end
    end
end
// Audio output drive, directly use the PWM above
always @(posedge clk or posedge rst) begin
    if(rst) begin
        AUD_SD <= 1'b0;
        AUD_PWM <= 1'b0;
    end
    else begin
        AUD_SD <= sd_sw;
        AUD_PWM <= led;
    end
end

endmodule

