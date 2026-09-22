`timescale 1ns/1ps

module tb_reset_sync;

    logic clk, rst_async_n,  rst_sync_n;

    reset_sync #(.STAGES(3)) dut(.clk(clk), .rst_async_n(rst_async_n), .rst_sync_n(rst_sync_n));

    initial begin 
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin 
        #1;
        rst_async_n = 1'b1;
        #20;
        rst_async_n = 1'b0;
        #10;
        rst_async_n = 1'b1;
        #10;
        rst_async_n = 1'b0;
        #10;
        rst_async_n = 1'b1;
        #40;
        $finish; 
    end

         
endmodule