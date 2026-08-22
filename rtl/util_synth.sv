`timescale 1ns/1ps
`default_nettype none
`include "pkg_util.sv"

module util_synth (
    input  wire        clk,
    input  wire  [7:0] d_i,
    output logic [7:0] gray_o,
    output logic [7:0] bin_o,
    output logic       onehot_o,
    output logic [3:0] first_o,
    output logic [3:0] ones_o
);
    always_ff @(posedge clk) begin
        gray_o   <= bin2gray(d_i);
        bin_o    <= gray2bin(d_i);
        onehot_o <= onehot_check(d_i);
        first_o  <= priority_encoder(d_i);
        ones_o   <= count_ones(d_i);
    end
endmodule

`default_nettype wire