`timescale 1ns/1ps

module led_blink #(
    parameter int unsigned CLK_FREQ_HZ = 100_000_000,
    parameter int unsigned BLINK_HZ    = 1
) (
    input logic clk,
    input logic rst_n,
    output logic led
);

    localparam int unsigned HALF_PERIOD = CLK_FREQ_HZ / (2*BLINK_HZ);
    localparam int unsigned CNT_W       = $clog2(HALF_PERIOD);

    logic [CNT_W-1 : 0] cnt;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            cnt <= '0;
            led <= 1'b0;
        end
        else if(cnt == HALF_PERIOD[CNT_W-1:0] - 1) begin
            cnt <= '0;
            led <= ~led;
        end
        else begin
            cnt <= cnt + 1'b1;
        end
    end

endmodule

