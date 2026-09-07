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

    // Clock divider: set to trigger every 2 cycles for browser simulation
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

    // Counter needs to count up to state 15 (4 bits: 0 to 15) for longer text
    reg [3:0] state;

    // Maximum sequence length based on active mode
    wire [3:0] max_state = (ui_in[2]) ? 4'd15 : 4'd8;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 4'b0000;
        end else if (slow_tick && ui_in[0]) begin // Advances ONLY when UI_IN[0] is ON
            if (state >= max_state)
                state <= 4'b0000;
            else
                state <= state + 1'b1;
        end
    end

    // Map state to 7-segment display: {dp, g, f, e, d, c, b, a}
    reg [7:0] seg_decoder;

    always @(*) begin
        if (ui_in[2]) begin
            // Mode 3: "Ezekiel WAS HERE" (16 states)
            case (state)
                4'b0000: seg_decoder = 8'b01111001; // 'E'
                4'b0001: seg_decoder = 8'b01011011; // 'z'
                4'b0010: seg_decoder = 8'b01111001; // 'e'
                4'b0011: seg_decoder = 8'b01110100; // 'k'
                4'b0100: seg_decoder = 8'b00110000; // 'i'
                4'b0101: seg_decoder = 8'b01111001; // 'e'
                4'b0110: seg_decoder = 8'b00111000; // 'l'
                4'b0111: seg_decoder = 8'b00000000; // Blank
                4'b1000: seg_decoder = 8'b00111110; // 'W' (rendered as U)
                4'b1001: seg_decoder = 8'b01110111; // 'A'
                4'b1010: seg_decoder = 8'b01101101; // 'S'
                4'b1011: seg_decoder = 8'b00000000; // Blank
                4'b1100: seg_decoder = 8'b01110110; // 'H'
                4'b1101: seg_decoder = 8'b01111001; // 'E'
                4'b1110: seg_decoder = 8'b01010000; // 'r'
                4'b1111: seg_decoder = 8'b01111001; // 'E'
                default: seg_decoder = 8'b00000000;
            endcase
        end else if (ui_in[1]) begin
            // Mode 2: Flash 'A' and '.'
            if (state[0]) begin
                seg_decoder = 8'b01110111; // 'A'
            end else begin
                seg_decoder = 8'b10000000; // '.'
            end
        end else begin
            // Mode 1: Normal UCL sequence
            case (state)
                4'b0000: seg_decoder = 8'b00111110; // 'U'
                4'b0001: seg_decoder = 8'b00111001; // 'C'
                4'b0010: seg_decoder = 8'b00111000; // 'L'
                4'b0011: seg_decoder = 8'b00000000; // Blank
                4'b0100: seg_decoder = 8'b01011011; // '2'
                4'b0101: seg_decoder = 8'b00111111; // '0'
                4'b0110: seg_decoder = 8'b01011011; // '2'
                4'b0111: seg_decoder = 8'b00000111; // '7'
                4'b1000: seg_decoder = 8'b01111000; // Smiley Face ☺
                default: seg_decoder = 8'b00000000;
            endcase
        end
    end

    // Output pattern to Tiny Tapeout output pins
    assign uo_out = seg_decoder;

endmodule
