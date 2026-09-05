`timescale 1ns/1ps
`default_nettype none
`include "sync_2ff.sv"

module async_top (
    input  wire        clk_a,
    input  wire        clk_b,
    input  wire        rst_n,
    output logic [7:0] cnt_a_o,
    output logic [7:0] cnt_b_o,
    output logic       synced_o
);
    logic synced_q;

    always_ff @(posedge clk_a) begin
        if (!rst_n) cnt_a_o <= '0;
        else        cnt_a_o <= cnt_a_o + 1'b1;
    end

    sync_2ff #(.STAGES(2)) u_sync (
        .clk     (clk_b),
        .rst_n   (rst_n),
        .async_i (cnt_a_o[7]),
        .sync_o  (synced_o)
    );

    always_ff @(posedge clk_b) begin
        if (!rst_n) begin
            synced_q <= 1'b0;
            cnt_b_o  <= '0;
        end else begin
            synced_q <= synced_o;
            if (synced_o && !synced_q) cnt_b_o <= cnt_b_o + 1'b1;
        end
    end
endmodule

`default_nettype wire