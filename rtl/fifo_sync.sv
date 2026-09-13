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
        if ((DEPTH & (DEPTH - 1)) != '0)    $fatal(1, "DEPTH must be power of 2, got %0d", DEPTH);
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

    
    assign almost_full_o = (count >= CNT_W'(ALMOST_FULL_TH));

    //=========================================================
    // Различающаяся часть: как читаем и что видит внешний мир
    //=========================================================
    generate
        if (FWFT) begin : g_fwft

            logic out_valid, do_rd_q, full_q;

            always_ff @(posedge clk) begin
                if(!rst_n)
                    full_q <= '0;
                else if(((count + 1'b1) == CNT_W'(DEPTH)) && (do_wr && !do_rd))
                    full_q <= 1'b1;
                else if(do_rd && !do_wr)
                    full_q <= '0;
            end

            always_ff @(posedge clk) begin
                if(!rst_n) 
                    do_rd_q <= '0;
                else if(do_wr && !do_rd)
                    do_rd_q <= 1'b1;
                else if((count == CNT_W'(1)) && (!do_wr && do_rd))
                    do_rd_q <= '0;
            end
            // Читаем из памяти, когда есть что и есть куда
            assign do_rd = do_rd_q && (!out_valid || rd_en_i);

            always_ff @(posedge clk) begin
                if (!rst_n)                       out_valid <= 1'b0;
                else if (do_rd)                   out_valid <= 1'b1;
                else if (rd_en_i && out_valid)    out_valid <= 1'b0;
            end

            assign full_o         = full_q;
            assign empty_o        = !out_valid;
            assign rd_data_o      = mem_dout;
            assign count_o        = count + CNT_W'(out_valid);
            assign almost_empty_o = (count_o <= CNT_W'(ALMOST_EMPTY_TH));

        end
        else begin : g_std
            logic empty_q;
            always_ff @(posedge clk) begin
                if(!rst_n)
                    empty_q <= 1'b1;
                else if(do_wr && !do_rd)
                    empty_q <= '0;
                else if ((count == CNT_W'(1)) && (!do_wr && do_rd))
                    empty_q <= 1'b1;
            end
            assign do_rd          = rd_en_i && !empty_o;
            assign empty_o        = empty_q;
            assign rd_data_o      = mem_dout;
            assign count_o        = count;
            assign almost_empty_o = (count <= CNT_W'(ALMOST_EMPTY_TH));
            assign full_o        = count[CNT_W-1];

        end
    endgenerate

`ifndef SYNTHESIS
    property p_dont_write_when_full;
        @(posedge clk) disable iff (!rst_n) 
        full_o |->  (do_wr == '0);
    endproperty
    a_dont_write_when_full: assert property(p_dont_write_when_full)
        else $error("fifo write when full");


    property p_dont_read_when_empty;
        @(posedge clk) disable iff (!rst_n) 
        empty_o |->  (do_rd == '0);
    endproperty
    a_read_when_empty: assert property(p_dont_read_when_empty)
        else $error("fifo read when empty");


    property p_count_less_than_depth;
        @(posedge clk) disable iff (!rst_n)
        count_o <= CNT_W'(DEPTH);
    endproperty
    a_count_less_depth: assert property(p_count_less_than_depth)
        else $error("count > CNT_W'(DEPTH)");


    property p_full_not_empty;
        @(posedge clk) disable iff (!rst_n)
        !(full_o && empty_o);
    endproperty
    a_full_not_empty: assert property(p_full_not_empty)
        else $error("full = empty");

    
    property p_empty_iff_zero;
        @(posedge clk) disable iff (!rst_n)
        empty_o == (count_o == '0);
    endproperty
    a_empty_iff_zero: assert property (p_empty_iff_zero)
        else $error("empty inconsistent with count=%0d", count);

    property p_full_iff_depth;
        @(posedge clk) disable iff (!rst_n)
        full_o == (count_o == CNT_W'(DEPTH));
    endproperty
    a_full_iff_depth: assert property (p_full_iff_depth)
        else $error("full inconsistent with count=%0d", count);

    
    property p_only_write;
        @(posedge clk) disable iff (!rst_n)
        (do_wr && !do_rd) |=> (count_o == $past(count_o) + 1'b1);
    endproperty
    a_only_write: assert property(p_only_write)
        else $error("count did not increment after write");

    
    property p_write_read;
        @(posedge clk) disable iff (!rst_n)
        (do_wr && do_rd) |=> (count_o == $past(count_o));
    endproperty
    a_write_read: assert property(p_write_read)
        else $error("count didnt work correct when wr + rd");
    

    property p_count_dec;
        @(posedge clk) disable iff (!rst_n)
        (do_rd && !do_wr) |=> (count == $past(count) - 1'b1);
    endproperty
    a_count_dec: assert property (p_count_dec)
        else $error("count did not decrement");


    // Cover
    c_full_reached:  cover property (@(posedge clk) full_o);
    c_empty_reached: cover property (@(posedge clk) empty_o);
    c_wr_when_full:  cover property (@(posedge clk) full_o && wr_en_i);
    c_rd_when_empty: cover property (@(posedge clk) empty_o && rd_en_i);
    c_simultaneous:  cover property (@(posedge clk) do_wr && do_rd);

`endif
endmodule

`default_nettype wire