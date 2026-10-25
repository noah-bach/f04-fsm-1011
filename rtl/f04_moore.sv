`timescale 1ns/1ps
`default_nettype none

module f04_moore (
    input  wire clk,
    input  wire rst_n,
    input  wire ena,
    input  wire bit_in,
    output wire detect,
    output wire [3:0] state_debug
);
    localparam [2:0] S0 = 3'd0, S1 = 3'd1, S2 = 3'd2,
                     S3 = 3'd3, S4 = 3'd4;
    reg [2:0] state, next_state;

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
            S3: next_state = bit_in ? S4 : S2;
            S4: next_state = bit_in ? S1 : S2;
            default: next_state = S0;
        endcase
    end

    // Pure state decode in this core. The top masks outputs when inactive.
    assign detect = (state == S4);
    // A four-pin debug value does not imply four state flip-flops.
    assign state_debug = {1'b0, state};
endmodule

`default_nettype wire
