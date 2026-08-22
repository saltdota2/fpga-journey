`default_nettype none
`timescale 1ns/1ps

module add_chain (
    input  wire         clk,
    input  wire  [15:0] a,
    input  wire  [15:0] b,
    input  wire  [15:0] c,
    input  wire  [15:0] d,
    output logic [17:0] sum
);
    logic [15:0] a_q, b_q, c_q, d_q;

    always_ff @(posedge clk) begin
        a_q <= a;  b_q <= b;  c_q <= c;  d_q <= d;
        sum <= a_q + b_q + c_q + d_q;
    end
endmodule

`default_nettype wire