//задержка 8 тактов до выхода(1такт запись на линию, 1 такт предсумирование, 1 такт умножение, 4 стадии сумирования в дереве, 1такт округление)
//16 умножителей
//исходная 16 бит. предсумматор + 1 бит, умножитель 16+17 = 33бита, дерево на каждом этапе + 1 в итоге +4 бита = 37, после округления снова 16.

`timescale 1ns/1ps
`default_nettype none

module fir_lp(
    input wire                 aclk,
    input wire                 aresetn,
    input wire                 s_axis_tvalid,
    input wire signed   [15:0] s_axis_tdata,
    output logic               m_axis_tvalid,
    output logic signed [15:0] m_axis_tdata
);

`include "fir_lp_coeffs.svh"

    logic signed [15:0] shiftreg [31];
    logic signed [16:0] pre_sum [16];
    logic signed [32:0] mult[16];
    logic signed [33:0] sum_stage0[8];
    logic signed [34:0] sum_stage1[4];
    logic signed [35:0] sum_stage2[2];
    logic signed [36:0] sum_stage3;

    logic signed [37:0] rounded;
    logic signed [22:0] shifted;
    logic        [7:0]  flag_valid;

    always_ff @(posedge aclk) begin
        if(!aresetn)
            flag_valid <= '0;
        else 
            flag_valid <= {flag_valid[6:0], s_axis_tvalid};
    end

    //сдвиговый регистр скользяших
    always_ff @(posedge aclk) begin
        if(!aresetn) 
            for(int i = 0; i < 31; i++)
                shiftreg[i] <= '0;
        else if(s_axis_tvalid) begin
            for(int i = 30; i > 0; i--)
                shiftreg[i] <= shiftreg[i-1];
            shiftreg[0] <= s_axis_tdata;
        end
    end

    //предсумматор
    always_ff @(posedge aclk) begin
        for(int i = 0; i < 15; i++) begin
            pre_sum[i] <= shiftreg[i] + shiftreg[30-i];
        end
        pre_sum[15] <= 17'(shiftreg[15]);
    end

    //умножитель
    always_ff @(posedge aclk) begin
        for(int i = 0; i <= 15; i++) begin
            mult[i] <= pre_sum[i] * COEFF[i];
        end
    end

    //дерево сумматоров
    always_ff @(posedge aclk) begin
        for(int i = 0; i < 16; i+=2) begin
            sum_stage0[i/2] <= mult[i] + mult[i+1];
        end
    end

    always_ff @(posedge aclk) begin
        for(int i = 0; i < 8; i+=2) begin
            sum_stage1[i/2] <= sum_stage0[i] + sum_stage0[i+1];
        end
    end

    always_ff @(posedge aclk) begin
        for(int i = 0; i < 4; i+=2) begin
            sum_stage2[i/2] <= sum_stage1[i] + sum_stage1[i+1];
        end
    end

    always_ff @(posedge aclk) begin
        sum_stage3 <= sum_stage2[0] + sum_stage2[1];
    end

    //округление Q7.30 -> Q1.15
    assign rounded = 38'(sum_stage3) + 38'sd16384;
    assign shifted = rounded[37:15];

    logic [14:0] unused_bits;
    assign unused_bits = rounded[14:0];

    always_ff @(posedge aclk) begin
        if(shifted > 23'sd32767)       m_axis_tdata <= 16'sd32767;
        else if(shifted < -23'sd32768) m_axis_tdata <= -16'sd32768;
        else                           m_axis_tdata <= shifted[15:0];
    end

    assign m_axis_tvalid = flag_valid[7];
endmodule

`default_nettype wire