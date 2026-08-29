`timescale 1ns/1ps

module tb_fifo_sync;

    localparam int unsigned WIDTH = 8;
    localparam int unsigned DEPTH = 8;
    localparam time         TCLK  = 10ns;

    logic                   clk, rst_n;
    logic                   wr_en, rd_en;
    logic [WIDTH-1:0]       wr_data, rd_data;
    logic                   full, empty, almost_full, almost_empty;
    logic [$clog2(DEPTH):0] count;
    logic                   overflow, underflow;

    int errors = 0;

    //=========================================================
    // DUT
    //=========================================================
    fifo_sync #(.WIDTH(WIDTH), .DEPTH(DEPTH), .FWFT(1'b0)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en_i(wr_en), .wr_data_i(wr_data),
        .full_o(full), .almost_full_o(almost_full),
        .rd_en_i(rd_en), .rd_data_o(rd_data),
        .empty_o(empty), .almost_empty_o(almost_empty),
        .count_o(count), .overflow_o(overflow), .underflow_o(underflow)
    );

    //=========================================================
    // Клок
    //=========================================================
    initial begin
        clk = 1'b0;
        forever #(TCLK/2) clk = ~clk;
    end

    //=========================================================
    // Таймаут — защита от зависания
    //=========================================================
    initial begin
        #(1000 * TCLK);
        $error("TIMEOUT");
        $finish;
    end

    //=========================================================
    // Задачи-помощники
    //=========================================================
    task automatic do_reset();
        rst_n   = 1'b0;
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        wr_data = '0;
        repeat (5) @(posedge clk);
        #1ns;
        rst_n = 1'b1;
        @(posedge clk);
        #1ns;
    endtask

    task automatic push(input logic [WIDTH-1:0] d);
        wr_en   = 1'b1;
        wr_data = d;
        @(posedge clk);
        #1ns;
        wr_en   = 1'b0;
    endtask

    task automatic pop(output logic [WIDTH-1:0] d);
        rd_en = 1'b1;
        @(posedge clk);
        #1ns;
        rd_en = 1'b0;
        d     = rd_data;
    endtask


    logic [WIDTH-1:0] model [$];      // reference model
    
    // Проверка одного значения
    task automatic check(input logic [31:0] got,
                         input logic [31:0] exp,
                         input string            what);
        if (got !== exp) begin
            $error("%s: expected %02h, got %02h", what, exp, got);
            errors++;
        end
    endtask


    // Записать и запомнить в модели
task automatic push_m(input logic [WIDTH-1:0] d);
    if (full) begin
        $error("push_m: FIFO full, cannot write");
        errors++;
        return;
    end
    push(d);
    model.push_back(d);
endtask

// Прочитать и сверить с моделью
task automatic pop_m();
    logic [WIDTH-1:0] got, exp;
    if (empty) begin
        $error("pop_m: FIFO empty, cannot read");
        errors++;
        return;
    end
    exp = model.pop_front();
    pop(got);
    if (got !== exp) begin
        $error("Data mismatch: expected %02h, got %02h", exp, got);
        errors++;
    end
endtask

// Сверить count с моделью
task automatic check_count();
    int model_size;
    model_size = model.size();

    if (32'(count) !== 32'(model_size)) begin
        $error("Count mismatch: model=%0d, dut=%0d", model_size, count);
        errors++;
    end
    if (empty !== (model_size == 0)) begin
        $error("Empty mismatch: model_size=%0d, dut_empty=%0b", model_size, empty);
        errors++;
    end
    if (full !== (model_size == DEPTH)) begin
        $error("Full mismatch: model_size=%0d, dut_full=%0b", model_size, full);
        errors++;
    end
endtask
    //=========================================================
    // Тест
    //=========================================================
    logic [WIDTH-1:0] d;

    initial begin
        do_reset();
        check_count();

        // Заполнить целиком
        for (int i = 0; i < DEPTH; i++) begin
            push_m(8'h10 + i[7:0]);
            check_count();
        end

        // Опустошить
        for (int i = 0; i < DEPTH; i++) begin
            pop_m();
            check_count();
        end

        if (errors == 0) $display("=== PASS ===");
        else             $display("=== FAIL: %0d errors ===", errors);
        $finish;
    end

endmodule
