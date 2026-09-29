`timescale 1ns/1ps
`default_nettype none

module top_cdc_handshake #(
    parameter int unsigned WIDTH  = 32,
    parameter int unsigned STAGES = 2
) (
    //Домен источника
    input wire               clk_src,
    input wire               rst_n,
    input wire   [WIDTH-1:0] data_i,
    input wire               valid_i,
    output logic             ready_o,
    
    //Домен приемника
    input wire               clk_dst,
    output logic [WIDTH-1:0] data_o,
    output logic             valid_o
);

logic rst_dst_n, rst_src_n;

reset_sync u_rst_src (.clk(clk_src), .rst_async_n(rst_n), .rst_sync_n(rst_src_n));
reset_sync u_rst_dst (.clk(clk_dst), .rst_async_n(rst_n), .rst_sync_n(rst_dst_n));


cdc_handshake  #(
    .WIDTH(WIDTH),
    .STAGES(STAGES)
) u_hs(
    //Домен источника
    .clk_src(clk_src),
    .rst_src_n(rst_src_n),
    .data_i(data_i),
    .valid_i(valid_i),
    .ready_o(ready_o),
    
    //Домен приемника
    .clk_dst(clk_dst),
    .rst_dst_n(rst_dst_n),
    .data_o(data_o),
    .valid_o(valid_o)
);

endmodule
`default_nettype wire