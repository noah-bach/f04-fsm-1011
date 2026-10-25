`timescale 1ns/1ps
`default_nettype none

module f04_mealy (
    input  wire clk,
    input  wire rst_n,
    input  wire ena,
    input  wire bit_in,
    output wire detect
);
    // Logical binary codes; these are not measured synthesized FF counts.
    localparam [1:0] S0 = 2'd0, S1 = 2'd1, S2 = 2'd2, S3 = 2'd3;
    reg [1:0] state, next_state;

    // Synchronous active-low reset, with reset priority over enable.
    always @(posedge clk) begin
        if (!rst_n)
            state <= S0;
        else if (ena)
            state <= next_state;
    end

    always @* begin
        next_state = S0;
        case (state)
            S0: next_state = bit_in ? S1 : S0;
            S1: next_state = bit_in ? S1 : S2;
            S2: next_state = bit_in ? S3 : S0;
            S3: next_state = bit_in ? S1 : S2;
            default: next_state = S0;
        endcase
    end

    // Raw Mealy output. Interpret a detection at the accepting clock edge.
    // The combinational level can change between edges.
    assign detect = (state == S3) && bit_in;
endmodule

`default_nettype wire
