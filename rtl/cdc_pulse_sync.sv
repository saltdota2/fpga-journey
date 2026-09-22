`timescale 1ns/1ps
`default_nettype none

module cdc_pulse_sync #(
    parameter int unsigned STAGES = 2,
    parameter int unsigned kt     = 2  
) (
    // Домен источника
    input  wire  clk_src,
    input  wire  rst_src_n,
    input  wire  pulse_i,

    // Домен приёмника
    input  wire  clk_dst,
    input  wire  rst_dst_n,
    output logic pulse_o
);

    // --- Домен источника: событие переключает toggle ---
    logic toggle_src;
    always_ff @(posedge clk_src) begin
        if (!rst_src_n)   toggle_src <= 1'b0;
        else if (pulse_i) toggle_src <= ~toggle_src;
    end

    // --- Домен приёмника: синхронизация + детектор фронта ---
    (* ASYNC_REG = "TRUE" *) logic [STAGES:0] sync_dst;

    always_ff @(posedge clk_dst) begin
        if (!rst_dst_n) sync_dst <= '0;
        else            sync_dst <= {sync_dst[STAGES-1:0], toggle_src};
    end

    // Любое изменение toggle = событие
    assign pulse_o = sync_dst[STAGES] ^ sync_dst[STAGES-1];

`ifndef SYNTHESIS

localparam int unsigned MIN_GAP = 2 * Kt;

property p_pulse_one_cycle;
    @(posedge clk_dst) disable iff(!rst_dst_n)
    pulse_o |=> !pulse_o;
endproperty
a_pulse_one_cycle: assert property(p_pulse_one_cycle)
    else $error("pulse_o stayed high more than one cycle");



int unsigned gap_cnt;
always_ff @(posedge clk_src) begin
    if(!rst_src_n) gap_cnt <= MIN_GAP;
    else if(pulse_i) gap_cnt <= 0S;
    else if(gap_cnt<MIN_GAP) gap_cnt <= gap_cnt + 1;
end

property p_pulse_spacing;
    @(posedge clk_src) disable iff(!rst_src_n)
    pulse_i |-> (gap_cnt >= MIN_GAP);
endproperty

m_pulse_spacing: assume property (p_pulse_spacing)
    else $error("pusle_i too often");

`endif
endmodule

`default_nettype wire