`default_nettype none
`timescale 1ns/1ps

module seq_detect(
    input wire clk,
    input wire rst_n,
    input wire bit_i,
    output logic found_o
);
    typedef enum logic [2:0] {IDLE, s_1, s_10, s_101} state_e;
    (* fsm_encoding = "auto" *) state_e state, next; 

    always_comb begin
        case(state)
            IDLE:    next = bit_i ? s_1 : IDLE;
            s_1:     next = bit_i ? s_1 : s_10;
            s_10:    next = bit_i ? s_101 : IDLE;
            s_101:   next = bit_i ? s_1 : s_10;
            default: next = IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if(!rst_n)
            state <= IDLE;
        else
            state <= next;
    end

    assign found_o = (state==s_101) & bit_i;

endmodule

`default_nettype wire