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

    // 5-bit state counter (cycles up to 22 states)
    reg [4:0] state;

    // Set sequence length dynamically based on input selection
    reg [4:0] max_state;
    always @(*) begin
        if (ui_in[3])
            max_state = 5'd22; // "I STUCK IN PCB. HELP PLS" (23 characters: 0 to 22)
        else if (ui_in[2])
            max_state = 5'd15; // "Ezekiel WAS HERE" (16 characters: 0 to 15)
        else
            max_state = 5'd8;  // "UCL 2027? ☺" (9 characters: 0 to 8)
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 5'b00000;
        end else if (slow_tick && ui_in[0]) begin // Advances ONLY when UI_IN[0] is ON
            if (state >= max_state)
                state <= 5'b00000;
            else
                state <= state + 1'b1;
        end
    end

    // Map state to 7-segment display: {dp, g, f, e, d, c, b, a}
    reg [7:0] seg_decoder;

    always @(*) begin
        if (ui_in[3]) begin
            // Mode 4: "I STUCK IN PCB. HELP PLS"
            case (state)
                5'd0:  seg_decoder = 8'b00110000; // 'I'
                5'd1:  seg_decoder = 8'b00000000; // Blank
                5'd2:  seg_decoder = 8'b01101101; // 'S'
                5'd3:  seg_decoder = 8'b00000111; // 'T'
                5'd4:  seg_decoder = 8'b00111110; // 'U'
                5'd5:  seg_decoder = 8'b00111001; // 'C'
                5'd6:  seg_decoder = 8'b01110100; // 'K'
                5'd7:  seg_decoder = 8'b00000000; // Blank
                5'd8:  seg_decoder = 8'b00110000; // 'I'
                5'd9:  seg_decoder = 8'b01010100; // 'n'
                5'd10: seg_decoder = 8'b00000000; // Blank
                5'd11: seg_decoder = 8'b01110011; // 'P'
                5'd12: seg_decoder = 8'b00111001; // 'C'
                5'd13: seg_decoder = 8'b01111100; // 'b'
                5'd14: seg_decoder = 8'b10000000; // '.'
                5'd15: seg_decoder = 8'b00000000; // Blank
                5'd16: seg_decoder = 8'b01110110; // 'H'
                5'd17: seg_decoder = 8'b01111001; // 'E'
                5'd18: seg_decoder = 8'b00111000; // 'L'
                5'd19: seg_decoder = 8'b01110011; // 'P'
                5'd20: seg_decoder = 8'b00000000; // Blank
                5'd21: seg_decoder = 8'b01110011; // 'P'
                5'd22: seg_decoder = 8'b00111000; // 'L'
                5'd23: seg_decoder = 8'b01101101; // 'S'
                default: seg_decoder = 8'b00000000;
            endcase
        end else if (ui_in[2]) begin
            // Mode 3: "Ezekiel WAS HERE"
            case (state[3:0])
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
                4'b1100: seg_decoder = 8'b01110116; // 'H'
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
            case (state[3:0])
                4'b0000: seg_decoder = 8'b00111110; // 'U'
                4'b0001: seg_decoder = 8'b00111001; // 'C'
                4'b0010: seg_decoder = 8'b00111000; // 'L'
                4'b0011: seg_decoder = 8'b00000000; // Blank
                4'b0100: seg_decoder = 8'b01011011; // '2'
                4'b0101: seg_decoder = 8'b00111111; // '0'
                4'b0110: seg_decoder = 8'b01011011; // '2'
                4'b0111: seg_decoder = 8'b00000111; // '7'
                4'b1000: seg_decoder = 8'b01111100; // Smiley Face ☺
                default: seg_decoder = 8'b00000000;
            endcase
        end
    end

    // Output pattern to Tiny Tapeout output pins
    assign uo_out = seg_decoder;

endmodule
