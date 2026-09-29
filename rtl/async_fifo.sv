`timescale 1ns/1ps
`default_nettype none

module async_fifo #(
    parameter int unsigned WIDTH = 32,
    parameter int unsigned DEPTH = 1024,
    parameter int unsigned ALMOST_EMPTY_TH = 4,
    parameter int unsigned ALMOST_FULL_TH  = DEPTH - 4
) (
    input wire               clk_src,
    input wire               rst_n,
    input wire               wr_en_i,
    input wire   [WIDTH-1:0] wr_data_i,
    output logic             full_o,
    output logic             almost_full_o,
    input wire               clk_dst,
    input wire               rd_en_i,
    output logic [WIDTH-1:0] rd_data_o,
    output logic             empty_o,
    output logic             almost_empty_o,
    output logic             overflow_o,
    output logic             underflow_o
);  
    localparam int unsigned PTR_W = $clog2(DEPTH);
    logic [WIDTH-1:0] mem [DEPTH];
    logic [WIDTH-1:0] mem_dout;
    logic [PTR_W:0] wr_ptr, rd_ptr;
    logic [PTR_W:0] wr_ptr_gray, rd_ptr_gray;

    logic rst_src_n, rst_dst_n;

    //ресет с ассинхронным сбросом и синхронным поднятием
    reset_sync rst_src(.clk(clk_src), .rst_async_n(rst_n), .rst_sync_n(rst_src_n));
    reset_sync rst_dst(.clk(clk_dst), .rst_async_n(rst_n), .rst_sync_n(rst_dst_n));

    logic do_rd, do_wr;


    //выполнить запись/чтение если не полон/пуст
    assign do_rd = rd_en_i && !empty_o;
    assign do_wr = wr_en_i && !full_o;

    always_ff @(posedge clk_src) begin
        if(!rst_src_n) begin
            wr_ptr      <= '0;
            wr_ptr_gray <= '0;
        end
        else if(do_wr) begin
             wr_ptr <= wr_ptr + 1'b1;
             wr_ptr_gray <= (wr_ptr + 1'b1) ^ ((wr_ptr + 1'b1) >> 1);
        end
    end

    always_ff @(posedge clk_dst) begin
        if(!rst_dst_n) begin
            rd_ptr <= '0;
            rd_ptr_gray <= '0;
        end
        else if(do_rd) begin
            rd_ptr <= rd_ptr + 1'b1;
            rd_ptr <= (rd_ptr + 1'b1) ^ ((rd_ptr + 1'b1) >> 1);
        end
    end

    always_ff @(posedge clk_src) begin 
        if(do_wr) mem[wr_ptr] <= wr_data_i;
    end

    always_ff @(posedge clk_dst) begin
        if(do_rd) mem_dout <= mem[rd_ptr];
    end

    assign rd_data_o = mem_dout;

