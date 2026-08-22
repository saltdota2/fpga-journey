
`timescale 1ns/1ps

module mult_dsp (
    input  logic               clk,
    input  logic signed [15:0] a,
    input  logic signed [15:0] b,
    output logic signed [31:0] prod
);
    logic signed [15:0] a_q, b_q;

    always_ff @(posedge clk) begin
        a_q  <= a;
        b_q  <= b;
        prod <= a_q * b_q;
    end
endmodule


