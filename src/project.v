`default_nettype none

module tt_um_ucl_display (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 1=output, 0=input)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Set unused bidir IOs as inputs
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Optional: Slow down clock to ~1 Hz using a counter 
    // Assuming a 10 MHz system clock from the TT board
    reg [23:0] clk_divider;
    wire slow_tick = (clk_divider == 24'd2 - 1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_divider <= 24'b0;
        end else if (slow_tick) begin
            clk_divider <= 24'b0;
        end else begin
            clk_divider <= clk_divider + 1'b1;
        end
    end

    // 3-bit state counter (cycles 0 to 7)
    reg [2:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 3'b000;
        end else if (slow_tick) begin
            state <= state + 1'b1;
        end
    end

    // Map 3-bit state to 7-segment display: {dp, g, f, e, d, c, b, a}
    reg [7:0] seg_decoder;

    always @(*) begin
        case (state)
            3'b000: seg_decoder = 8'b00111110; // 'U'
            3'b001: seg_decoder = 8'b00111001; // 'C'
            3'b010: seg_decoder = 8'b00111000; // 'L'
            3'b011: seg_decoder = 8'b00000000; //  Blank
            3'b100: seg_decoder = 8'b01011011; // '2'
            3'b101: seg_decoder = 8'b00111111; // '0'
            3'b110: seg_decoder = 8'b01011011; // '2'
            3'b111: seg_decoder = 8'b00000111; // '7'
            default: seg_decoder = 8'b00000000;
        endcase
    end

    // Output pattern to Tiny Tapeout output pins
    assign uo_out = seg_decoder;

endmodule
