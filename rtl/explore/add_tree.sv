
`timescale 1ns/1ps

module add_tree(
    input  logic        clk,
    input  logic [15:0] a, b, c, d,
    output logic [17:0] sum
);
    logic [15:0] a_q, b_q, c_q, d_q;

    logic [16:0] s1;
    logic [17:0] s2;
    always_ff @(posedge clk) begin
        a_q <= a;  b_q <= b;  c_q <= c;  d_q <= d;
        s1  <= a_q + b_q;
        s2  <= s1  + c_q;
        sum <= s2  + d_q;
    end
endmodule
