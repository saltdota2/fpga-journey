`timescale 1ns/1ps
`default_nettype none

module mac_harness #(
    parameter int unsigned STAGES = 4
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_i,
    input  wire  [15:0] a_i,
    input  wire  [15:0] b_i,
    input  wire  [31:0] c_i,
    output logic        valid_o,
    output logic [31:0] result_o
);
    logic        valid_q;
    logic [15:0] a_q, b_q;
    logic [31:0] c_q;
    logic        v_mid;
    logic [31:0] r_mid;

    // входные регистры
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_q <= '0; a_q <= '0; b_q <= '0; c_q <= '0;
        end else begin
            valid_q <= valid_i; a_q <= a_i; b_q <= b_i; c_q <= c_i;
        end
    end

    mac_unit #(.STAGES(STAGES)) u_mac (
        .clk(clk), .rst_n(rst_n),
        .valid_i(valid_q), .a_i(a_q), .b_i(b_q), .c_i(c_q),
        .valid_o(v_mid), .result_o(r_mid)
    );

    // выходные регистры
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= '0; result_o <= '0;
        end else begin
            valid_o <= v_mid; result_o <= r_mid;
        end
    end
endmodule

`default_nettype wire