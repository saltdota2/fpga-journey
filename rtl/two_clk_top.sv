`timescale 1ns/1ps
`default_nettype none
`include "clk_gen.sv"
`include "sync_2ff.sv"

module two_clk_top(
    input wire clk,
    input wire rst_n,
    output logic [7:0] cnt_100_o,
    output logic [7:0] cnt_50_o,
    output logic       synced_o 
);  

    logic clk_100, clk_50, locked;

    clk_gen u_gen(
        .clk_in(clk), 
        .rst_n(rst_n), 
        .clk_100(clk_100), 
        .clk_50(clk_50), 
        .locked(locked)
    );

    always_ff @(posedge clk_100) begin
        if(!locked) cnt_100_o <= '0;
        else        cnt_100_o <= cnt_100_o + 1'b1;
    end

    always_ff @(posedge clk_50) begin
        if(!locked) cnt_50_o <= '0;
        else        cnt_50_o <= cnt_50_o + 1'b1;
    end

    sync_2ff #(.STAGES(2)) u_sync (
        .clk(clk_50),
        .rst_n(rst_n),
        .async_i(cnt_100_o[7]),
        .sync_o(synced_o)
    );

endmodule



`default_nettype wire