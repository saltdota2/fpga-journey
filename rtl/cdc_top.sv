`timescale 1ns/1ps
`default_nettype none
 
//=========================================================
// Учебный топ: два независимых клока, одно пересечение
// доменов через cdc_pulse_sync.
//
// Входы и выходы заведены через регистры, чтобы все пути
// внутри были reg->reg и анализ не утонул в I/O.
//=========================================================
module cdc_top #(
    parameter int unsigned STAGES = 2,
    parameter int unsigned CNT_W  = 16
) (
    // домен A (быстрый)
    input  wire              clk_a,
    input  wire              rst_a_n,
    input  wire              ev_i,
 
    // домен B (медленный)
    input  wire              clk_b,
    input  wire              rst_b_n,
    output logic [CNT_W-1:0] cnt_o
);
 
    //-----------------------------------------------------
    // Домен A: из уровня на входе делаем однотактный импульс
    //-----------------------------------------------------
    logic ev_q, pulse_a;
 
    always_ff @(posedge clk_a) begin
        if (!rst_a_n) begin
            ev_q    <= 1'b0;
            pulse_a <= 1'b0;
        end
        else begin
            ev_q    <= ev_i;
            pulse_a <= ev_i & ~ev_q;
        end
    end
 
    //-----------------------------------------------------
    // Единственное пересечение доменов во всём дизайне
    //-----------------------------------------------------
    logic pulse_b;
 
    cdc_pulse_sync #(.STAGES(STAGES)) u_cdc (
        .clk_src   (clk_a),
        .rst_src_n (rst_a_n),
        .pulse_i   (pulse_a),
        .clk_dst   (clk_b),
        .rst_dst_n (rst_b_n),
        .pulse_o   (pulse_b)
    );
 
    //-----------------------------------------------------
    // Домен B: считаем принятые события
    //-----------------------------------------------------
    logic [CNT_W-1:0] cnt_q;
 
    always_ff @(posedge clk_b) begin
        if (!rst_b_n)     cnt_q <= '0;
        else if (pulse_b) cnt_q <= cnt_q + 1'b1;
    end
 
    assign cnt_o = cnt_q;
 
endmodule
 
`default_nettype wire