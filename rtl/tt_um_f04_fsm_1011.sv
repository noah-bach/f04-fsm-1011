`timescale 1ns/1ps
`default_nettype none

module tt_um_f04_fsm_1011 (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire ena,
    input  wire clk,
    input  wire rst_n
);
    wire mealy_raw, moore_raw;
    wire [3:0] moore_state;
    wire active = rst_n && ena;

    f04_mealy u_mealy (
        .clk(clk), .rst_n(rst_n), .ena(ena),
        .bit_in(uio_in[0]), .detect(mealy_raw)
    );
    f04_moore u_moore (
        .clk(clk), .rst_n(rst_n), .ena(ena),
        .bit_in(uio_in[0]), .detect(moore_raw),
        .state_debug(moore_state)
    );

    // Required F04 pin mapping. Debug remains observable during a pause.
    assign uo_out[0] = active && mealy_raw;
    assign uo_out[1] = active && moore_raw;
    assign uo_out[5:2] = moore_state;
    assign uo_out[7:6] = 2'b00;
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;  // All bidirectional pins are inputs.
    // ui_in and uio_in[7:1] intentionally do not affect the detector.
endmodule

`default_nettype wire
