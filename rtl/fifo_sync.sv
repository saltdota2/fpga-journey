`timescale 1ns/1ps
`default_nettype none

module fifo_sync #(
    parameter int unsigned WIDTH = 32,
    parameter int unsigned DEPTH = 1024,
    parameter bit          FWFT  = 1'b1,
    parameter int unsigned ALMOST_FULL_TH  = DEPTH - 2,
    parameter int unsigned ALMOST_EMPTY_TH = 2
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    wr_en_i,
    input  wire  [WIDTH-1:0]       wr_data_i,
    output logic                   full_o,
    output logic                   almost_full_o,
    input  wire                    rd_en_i,
    output logic [WIDTH-1:0]       rd_data_o,
    output logic                   empty_o,
    output logic                   almost_empty_o,
    output logic [$clog2(DEPTH):0] count_o,
    output logic                   overflow_o,
    output logic                   underflow_o
);

    localparam int unsigned PTR_W = $clog2(DEPTH);
    localparam int unsigned CNT_W = $clog2(DEPTH) + 1;

    initial begin
        if (DEPTH < 2)              $fatal(1, "DEPTH must be >= 2, got %0d", DEPTH);
        if (DEPTH & (DEPTH - 1))    $fatal(1, "DEPTH must be power of 2, got %0d", DEPTH);
        if (ALMOST_FULL_TH > DEPTH) $fatal(1, "ALMOST_FULL_TH > DEPTH");
    end

    logic [WIDTH-1:0] mem [DEPTH];
    logic [PTR_W-1:0] wr_ptr, rd_ptr;
    logic [CNT_W-1:0] count;
    logic             do_wr, do_rd;
    logic [WIDTH-1:0] mem_dout;

    //=========================================================
    // Общая часть: память, указатели, счётчик, флаги записи
    //=========================================================
    assign do_wr = wr_en_i && !full_o;

    always_ff @(posedge clk) begin
        if (do_wr) mem[wr_ptr] <= wr_data_i;
    end

    always_ff @(posedge clk) begin
        if (do_rd) mem_dout <= mem[rd_ptr];
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end
        else begin
            if (do_wr) wr_ptr <= wr_ptr + 1'b1;
            if (do_rd) rd_ptr <= rd_ptr + 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n)                count <= '0;
        else if (do_wr && !do_rd)  count <= count + 1'b1;
        else if (do_rd && !do_wr)  count <= count - 1'b1;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            overflow_o  <= 1'b0;
            underflow_o <= 1'b0;
        end
        else begin
            overflow_o  <= wr_en_i && full_o;
            underflow_o <= rd_en_i && empty_o;
        end
    end

    assign full_o        = (count == CNT_W'(DEPTH));
    assign almost_full_o = (count >= CNT_W'(ALMOST_FULL_TH));

    //=========================================================
    // Различающаяся часть: как читаем и что видит внешний мир
    //=========================================================
    generate
        if (FWFT) begin : g_fwft

            logic out_valid;

            // Читаем из памяти, когда есть что и есть куда
            assign do_rd = (count != '0) && (!out_valid || rd_en_i);

            always_ff @(posedge clk) begin
                if (!rst_n)                       out_valid <= 1'b0;
                else if (do_rd)                   out_valid <= 1'b1;
                else if (rd_en_i && out_valid)    out_valid <= 1'b0;
            end

            assign empty_o        = !out_valid;
            assign rd_data_o      = mem_dout;
            assign count_o        = count + CNT_W'(out_valid);
            assign almost_empty_o = (count_o <= CNT_W'(ALMOST_EMPTY_TH));

        end
        else begin : g_std

            assign do_rd          = rd_en_i && !empty_o;
            assign empty_o        = (count == '0);
            assign rd_data_o      = mem_dout;
            assign count_o        = count;
            assign almost_empty_o = (count <= CNT_W'(ALMOST_EMPTY_TH));

        end
    endgenerate

endmodule

`default_nettype wire