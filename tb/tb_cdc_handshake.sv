`timescale 1ns/1ps
`include "rtl/reset_sync.sv"

module tb_cdc_handshake;
    localparam int unsigned WIDTH = 32;
    logic               clk_src, clk_dst;
    logic               rst_n, rst_dst_n;
    logic               valid_i;
    logic   [WIDTH-1:0] data_i;
    logic   [WIDTH-1:0] data_o;
    logic               valid_o;
    logic               ready_o;

    reset_sync rst_dst(.clk(clk_dst), .rst_async_n(rst_n), .rst_sync_n(rst_dst_n));

    int errors = 0;

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
        #2.3;
        forever #7.3 clk_dst = ~clk_dst;
    end

    task automatic do_reset();
        rst_n   = 1'b0;
        valid_i = 1'b0;
        data_i  = '0;
        repeat(5) @(posedge clk_src);
        #1;
        rst_n   = 1'b1;
        wait (rst_dst_n);
        @(posedge clk_src)
        #1;
    endtask

    logic[WIDTH-1:0] model [$];

    task automatic reset_all();
        do_reset();
        model.delete();
    endtask

    task automatic send_data(input logic [WIDTH-1:0] d);
            valid_i = 1'b1;
            data_i = d;
            do @(posedge clk_src); while(!ready_o);
            model.push_back(d);
            #1;
            valid_i = 1'b0;
    endtask

    initial begin : watchdog
        #1ms;
        $error("TIMEOUT");
        $finish;
    end : watchdog

    initial begin : monitor
        logic [WIDTH-1:0] exp;
        forever begin
            @(posedge clk_dst);
            if(rst_dst_n && valid_o) begin
                if(model.size() == 0) begin
                    $error("valid_o without send: data_o = %0h", data_o);
                    errors++;
                end else begin
                    exp = model.pop_front();
                    if (data_o !== exp) begin
                        $error("expected %0h, got %0h", exp, data_o);
                        errors++;
                    end
                end
            end
        end
    end : monitor

    initial begin
        reset_all();
        for(int i = 0; i < 100; i++)
            send_data(WIDTH'($urandom()));
        repeat(50) @(posedge clk_dst);

        if (model.size() != 0) begin
            $error("потеряно %0d посылок", model.size());
            errors += model.size();
        end

        if (errors > 0) $display("=== FAIL: %0d errors ===", errors);
        else            $display("=== PASS ===");
        $finish;
    end
endmodule