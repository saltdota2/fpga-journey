`default_nettype none
`timescale 1ns/1ps
`include "reduction_chain.sv"

module reduction_chain_harness #(
    parameter int unsigned N     = 16,
    parameter int unsigned WIDTH = 8
) (
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire  [N*WIDTH-1:0]         data_flat_i,
    output logic [WIDTH+$clog2(N)-1:0] result_o
);
    localparam int unsigned OUT_W = WIDTH + $clog2(N);

    (* dont_touch = "true" *) logic [WIDTH-1:0] data_q [N];
    (* dont_touch = "true" *) logic [OUT_W-1:0] result_q;

    logic [OUT_W-1:0] sum_w;

    always_ff @(posedge clk) begin
        for (int i = 0; i < N; i++)
            data_q[i] <= !rst_n ? '0 : data_flat_i[i*WIDTH +: WIDTH];
    end

    reduction_chain #(.N(N), .WIDTH(WIDTH)) u_dut (
        .clk      (clk),
        .data_i   (data_q),
        .result_o (sum_w)
    );

    always_ff @(posedge clk) begin
        if (!rst_n) result_q <= '0;
        else        result_q <= sum_w;
    end

    assign result_o = result_q;
endmodule