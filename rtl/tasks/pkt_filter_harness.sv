`timescale 1ns/1ps
`default_nettype none
`include "pkt_filter.sv"

module pkt_filter_harness (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [31:0] addr_i,
    input  wire [7:0]  type_i,
    input  wire [15:0] len_i,
    output logic       valid_o,
    output logic       match_o,
    output logic [3:0] rule_id_o,
    output logic [31:0] addr_o
);
    logic        v_q, m_w, v_w;
    logic [31:0] a_q, a_w;
    logic [7:0]  t_q;
    logic [15:0] l_q;
    logic [3:0]  r_w;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            v_q <= '0; a_q <= '0; t_q <= '0; l_q <= '0;
        end else begin
            v_q <= valid_i; a_q <= addr_i; t_q <= type_i; l_q <= len_i;
        end
    end

    pkt_filter u_filter (
        .clk(clk), .rst_n(rst_n),
        .valid_i(v_q), .addr_i(a_q), .type_i(t_q), .len_i(l_q),
        .valid_o(v_w), .match_o(m_w), .rule_id_o(r_w), .addr_o(a_w)
    );

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= '0; match_o <= '0; rule_id_o <= '0; addr_o <= '0;
        end else begin
            valid_o <= v_w; match_o <= m_w; rule_id_o <= r_w; addr_o <= a_w;
        end
    end
endmodule

`default_nettype wire