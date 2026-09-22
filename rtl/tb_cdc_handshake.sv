`timescale 1ns/1ps

module tb_cdc_handshake;
    localparam int unsigned WIDTH = 32;
    logic               clk_src, clk_dst 
    logic               rst_n, rst_dst_n;
    logic               valid_i;
    logic   [WIDTH-1:0] data_i;
    logic   [WIDTH-1:0] data_o;
    logic               valid_o;
    logic               ready_o;

    reset_sync rst_dst(.clk(clk_dst), .rst_async_n(rst_n), .rst_sync_n(rst_dst_n));

    cdc_handshake dut(
    .clk_src(clk_src),
    .rst_src_n(rst_n),
    .data_i(data_i),
    .valid_i(valid_i),
    .ready_o(ready_o),
    .clk_dst(clk_dst),
    .rst_dst_n(rst_dst_n),
    .data_o(data_o),
    .valid_o(valid_o)
    );

    initial begin
        clk_src = 1'b0;
        forever #5 clk_src = ~clk_src;
    end

    initial begin
        clk_dst = 1'b0;
        forever #10 clk_src = ~clk_src;
    end

    task automatic do_reset();
        rst_n   = 1'b0;
        valid_i = 1'b0;
        data_i  = 1'b0;
        repeat(5) @(posedge clk_src)
        #1;
        rst_n   = 1'b1;
        @(posedge clk_src)
        #1;
    task automatic send_data()
