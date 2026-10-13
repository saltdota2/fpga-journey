`timescale 1ns/1ps
`default_nettype none

module fifo_async #(
    parameter int unsigned WIDTH  = 32,
    parameter int unsigned DEPTH  = 16,     // степень двойки, >= 4
    parameter int unsigned STAGES = 2       // ступеней синхронизатора, >= 2
) (
    // Домен записи
    input  wire              clk_w,
    input  wire              rst_w_n,
    input  wire              wr_en_i,
    input  wire [WIDTH-1:0]  wr_data_i,
    output logic             full_o,
 
    // Домен чтения
    input  wire              clk_r,
    input  wire              rst_r_n,
    input  wire              rd_en_i,
    output logic [WIDTH-1:0] rd_data_o,
    output logic             empty_o
);
 
    localparam int unsigned ADDR_W = $clog2(DEPTH);
    localparam int unsigned PTR_W  = ADDR_W + 1;
 
    // -------------------------------------------------------------------------
    // Проверка параметров (на этапе elaboration)
    // -------------------------------------------------------------------------
    if (WIDTH < 1) begin : g_chk_width
        $error("fifo_async: WIDTH must be >= 1 (got %0d)", WIDTH);
    end
    if (DEPTH < 4 || (DEPTH & (DEPTH - 1)) != 0) begin : g_chk_depth
        $error("fifo_async: DEPTH must be a power of two and >= 4 (got %0d)", DEPTH);
    end
    if (STAGES < 2) begin : g_chk_stages
        $error("fifo_async: STAGES must be >= 2 (got %0d)", STAGES);
    end
 
    // -------------------------------------------------------------------------
    // Память (simple dual port)
    // -------------------------------------------------------------------------
    logic [WIDTH-1:0] mem [DEPTH];
 
    // -------------------------------------------------------------------------
    // Домен записи
    // -------------------------------------------------------------------------
    logic [PTR_W-1:0] wbin_q,  wbin_d;
    logic [PTR_W-1:0] wgray_q, wgray_d;
    logic [PTR_W-1:0] rgray_in_w;          // rd gray, синхронизированный в clk_w
    logic             full_d;
    logic             wr_en;
 
    assign wr_en = wr_en_i & ~full_o;
 
    always_comb begin
        wbin_d  = wbin_q + PTR_W'(wr_en);
        wgray_d = (wbin_d >> 1) ^ wbin_d;
        // full: gray-указатели равны, кроме двух старших бит (они инвертированы)
        full_d  = (wgray_d == {~rgray_in_w[PTR_W-1:PTR_W-2], rgray_in_w[PTR_W-3:0]});
    end
 
    always_ff @(posedge clk_w) begin
        if (!rst_w_n) begin
            wbin_q  <= '0;
            wgray_q <= '0;
            full_o  <= 1'b0;
        end else begin
            wbin_q  <= wbin_d;
            wgray_q <= wgray_d;
            full_o  <= full_d;
        end
    end
 
    // Запись в память — без сброса, чтобы вывелось в BRAM
    always_ff @(posedge clk_w) begin
        if (wr_en) mem[wbin_q[ADDR_W-1:0]] <= wr_data_i;
    end
 
    // -------------------------------------------------------------------------
    // Домен чтения
    // -------------------------------------------------------------------------
    logic [PTR_W-1:0] rbin_q,  rbin_d;
    logic [PTR_W-1:0] rgray_q, rgray_d;
    logic [PTR_W-1:0] wgray_in_r;          // wr gray, синхронизированный в clk_r
    logic             empty_d;
    logic             rd_en;
 
    assign rd_en = rd_en_i & ~empty_o;
 
    always_comb begin
        rbin_d  = rbin_q + PTR_W'(rd_en);
        rgray_d = (rbin_d >> 1) ^ rbin_d;
        empty_d = (rgray_d == wgray_in_r);
    end
 
    always_ff @(posedge clk_r) begin
        if (!rst_r_n) begin
            rbin_q  <= '0;
            rgray_q <= '0;
            empty_o <= 1'b1;
        end else begin
            rbin_q  <= rbin_d;
            rgray_q <= rgray_d;
            empty_o <= empty_d;
        end
    end
 
    // Синхронное чтение — без сброса, чтобы вывелось в BRAM
    always_ff @(posedge clk_r) begin
        if (rd_en) rd_data_o <= mem[rbin_q[ADDR_W-1:0]];
    end
 
    // -------------------------------------------------------------------------
    // Синхронизаторы (CDC)
    // -------------------------------------------------------------------------
    // wr gray -> домен чтения
    (* ASYNC_REG = "TRUE" *) logic [STAGES-1:0][PTR_W-1:0] wgray_sync;
 
    always_ff @(posedge clk_r) begin
        if (!rst_r_n) begin
            wgray_sync <= '0;
        end else begin
            wgray_sync[0] <= wgray_q;
            for (int i = 1; i < STAGES; i++) wgray_sync[i] <= wgray_sync[i-1];
        end
    end
    assign wgray_in_r = wgray_sync[STAGES-1];
 
    // rd gray -> домен записи
    (* ASYNC_REG = "TRUE" *) logic [STAGES-1:0][PTR_W-1:0] rgray_sync;
 
    always_ff @(posedge clk_w) begin
        if (!rst_w_n) begin
            rgray_sync <= '0;
        end else begin
            rgray_sync[0] <= rgray_q;
            for (int i = 1; i < STAGES; i++) rgray_sync[i] <= rgray_sync[i-1];
        end
    end
    assign rgray_in_w = rgray_sync[STAGES-1];
 
endmodule
`default_nettype wire

