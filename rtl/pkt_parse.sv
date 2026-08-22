`default_nettype none
`timescale 1ns/1ps

typedef struct packed {
    logic [7:0]  a;
    logic [15:0] b;
    logic [31:0] c;
} data_t;

module pkt_parse (
    input  wire   clk,
    input  data_t d_i,
    output data_t d_o
);
    always_ff @(posedge clk) d_o <= d_i;
endmodule

`default_nettype wire