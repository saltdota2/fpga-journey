`timescale 1ns/1ps
`default_nettype none

module cdc_pulse_sync #(
    parameter int unsigned STAGES = 2
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

property p_pulse_one_cycle;
    @(posedge clk_dst) disable iff (!rst_dst_n)
    pulse_o |=> !pulse_o;
endproperty
a_pulse_one_cycle: assert property (p_pulse_one_cycle)
    else $error("pulse_o stayed high more than one cycle");

// Новый импульс разрешён, только когда предыдущий toggle
// полностью прошёл синхронизатор
property p_pulse_spacing;
    @(posedge clk_src) disable iff (!rst_src_n || !rst_dst_n)
    pulse_i |-> (toggle_src == sync_dst[STAGES]);
endproperty
m_pulse_spacing: assume property (p_pulse_spacing)
    else $error("pulse_i too often: previous event still in flight");

`endif
endmodule

`default_nettype wire