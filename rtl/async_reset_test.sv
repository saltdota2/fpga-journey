`default_nettype none
`timescale 1ns/1ps
`include "reset_sync.sv"

module async_reset_test(
    input wire clk,
    input wire rst_async_n,
    output logic [3:0] cnt_o,
    output logic state_o
);
    logic reset_async_n;
    reset_sync inst1 (.clk(clk), .rst_async_n(rst_async_n), .rst_sync_n(reset_async_n));
     
    logic [3:0] cnt;
    typedef enum logic [1:0] {s0, s1, s2, s3} states;
    states state, next_state;

    always_comb begin
        case(state)
            s0: next_state = (cnt > 3) ? s1 : s0;
            s1: next_state = (cnt > 7) ? s2 : s1;
            s2: next_state = (cnt > 11) ? s3 : s2;
            s3: next_state = (cnt == 15) ? s0 : s3;
            default: next_state = s0;
        endcase
    end

    
    always_ff @(posedge clk, negedge reset_async_n)
        if(!reset_async_n) state <= s0;
        else               state <= next_state;

    always_ff @(posedge clk, negedge reset_async_n) begin
        if(!reset_async_n) cnt <= '0;
        else               cnt <= cnt + 1'b1;
    end

    assign cnt_o = cnt;
    assign state_o = (state == s3);
endmodule

`default_nettype wire
