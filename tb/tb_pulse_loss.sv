`timescale 1ns/1ps

module tb_pulse_loss;

    logic clk_fast, clk_slow, rst_n,  pulse, pulse_sync;

    initial begin
        clk_fast = 1'b0;
        forever #5 clk_fast = ~clk_fast;
    end

    initial begin
        clk_slow = 1'b0;
        forever #25 clk_slow = ~clk_slow;
    end
    
    cdc_pulse_sync u_cdc(
        .clk_src(clk_slow),
        .rst_src_n(rst_n),
        .pulse_i(pulse),
        .clk_dst(clk_fast),
        .rst_dst_n(rst_n),
        .pulse_o(pulse_sync)
    );

    int cnt_sent, cnt_recv;

    // Генерация импульсов в быстром домене
    always_ff @(posedge clk_fast) begin
        if (!rst_n) begin
            pulse    <= 1'b0;
            cnt_sent <= 0;
        end
        else begin
            if (cnt_sent < 100 && !pulse && ($urandom_range(99) < 20)) begin
                pulse    <= 1'b1;
                cnt_sent <= cnt_sent + 1;
            end
            else begin
                pulse <= 1'b0;
            end
        end
    end

    logic pulse_sync_d;
    always_ff @(posedge clk_slow) begin
        if (!rst_n) begin
            pulse_sync_d <= 1'b0;
            cnt_recv     <= 0;
        end
        else begin
            pulse_sync_d <= pulse_sync;
            if (pulse_sync && !pulse_sync_d)
                cnt_recv <= cnt_recv + 1;
        end
    end

    initial begin
        rst_n = 1'b0;
        repeat (10) @(posedge clk_slow);
        rst_n = 1'b1;

        wait (cnt_sent == 100);
        repeat (20) @(posedge clk_slow);

        $display("=====================================");
        $display(" sent:     %0d", cnt_sent);
        $display(" received: %0d", cnt_recv);
        $display(" lost:     %0d (%0.1f%%)",
                 cnt_sent - cnt_recv,
                 100.0 * (cnt_sent - cnt_recv) / cnt_sent);
        $display("=====================================");
        $finish;
    end
        
    initial begin
        #100us;
        $error("TIMEOUT");
        $finish;
    end

endmodule
    