
`timescale 1ns/1ps

module wide_mux (
    input  logic       clk,
    input  logic [2:0] sel,
    input  logic [7:0] in0, in1, in2, in3, in4, in5, in6, in7,
    output logic [7:0] y
);
    logic [7:0] mux_out;

    always_comb begin
        case (sel)
            3'd0:    mux_out = in0;
            3'd1:    mux_out = in1;
            3'd2:    mux_out = in2;
            3'd3:    mux_out = in3;
            3'd4:    mux_out = in4;
            3'd5:    mux_out = in5;
            3'd6:    mux_out = in6;
            3'd7:    mux_out = in7;
            default: mux_out = '0;
        endcase
    end

    always_ff @(posedge clk) y <= mux_out;
endmodule

