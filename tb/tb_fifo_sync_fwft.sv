`timescale 1ns/1ps

module tb_fifo_sync_fwft;

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
    fifo_sync #(.WIDTH(WIDTH), .DEPTH(DEPTH), .FWFT(1'b1)) dut (
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
    logic [WIDTH-1:0] model [$];      // reference model

    task automatic reset_all();
        do_reset();
        model.delete();
    endtask

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

    task automatic push_and_pop(input logic [WIDTH-1:0] d, output logic [WIDTH-1:0] q);
        wr_en = 1'b1;  rd_en = 1'b1;
        wr_data = d;  
        @(posedge clk)
        #1ns;
        q = rd_data; 
        wr_en = 1'b0;  rd_en = 1'b0;
    endtask


    
    
    // Проверка одного значения
    task automatic check(input logic [31:0] got,
                         input logic [31:0] exp,
                         input string            what);
        if (got !== exp) begin
            $error("%s: expected %0h, got %0h", what, exp, got);
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
        $error("Data mismatch: expected %0h, got %0h", exp, got);
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

    task automatic push_pop_m(input logic [WIDTH-1:0] d);
        logic [WIDTH-1:0] got, exp;

        if (empty || full) begin
            $error("push_pop_m: precondition failed (empty=%b full=%b)", empty, full);
            errors++;
            return;
        end

        exp = model.pop_front();
        push_and_pop(d, got);
        model.push_back(d);

        if (got !== exp) begin
            $error("Simultaneous rd/wr data mismatch: expected %02h, got %02h", exp, got);
            errors++;
        end
    endtask

    task automatic test_reset_state();

    $display("---test_reset_state---");
    do_reset();
    check_count();

    endtask


    task automatic test_fill_to_full();

    $display("---test_fill_to_full---");
    reset_all();

    for(int i = 0; i < DEPTH; i++) begin
        push_m(8'h10 + 8'(i));
        check_count();
    end

    if (full !== 1'b1) begin
        $error("full not asserted at count=%0d", count);
        errors++;
    end

    endtask


    task automatic test_fill_then_drain();
        $display("--- test_fill_then_drain ---");
        reset_all();

        // заполнить
        for (int i = 0; i < DEPTH; i++) begin
            push_m(8'h10 + 8'(i));
            check_count();
        end

        // опустошить
        for (int i = 0; i < DEPTH; i++) begin
            pop_m();
            check_count();
        end

        if (empty !== 1'b1) begin
            $error("empty not asserted after draining");
            errors++;
        end
    endtask

    task automatic test_write_when_full();
        int cnt_before;
        $display("---test_write_when_full---");
        reset_all();

        for (int i = 0; i <DEPTH; i++) begin
            push_m(8'h9 + 8'(i));
        end
        check_count();

        if (full !== 1'b1) begin
            $error("full not asserted after %0d writes", DEPTH);
            errors++;
        end

        cnt_before = 32'(count);

        push(8'h77);
        
        if(32'(count) !== cnt_before) begin
            $error("count changed on write-to-full %0d -> %0d", cnt_before, count);
            errors++;
        end

        if(overflow !== 1'b1) begin
            $error("overflow not asserted on write-to-full");
            errors++;
        end

        for(int i = 0; i < DEPTH; i++) begin
            pop_m();
        end

    endtask

    task automatic test_read_when_empty();
        logic [WIDTH-1:0] junk;
        $display("---test_read_when_empty---");
        reset_all();

        if(empty !== 1'b1) begin
            $error("not empty after reset");
            errors++;
        end

        pop(junk);
        
        if(32'(count) !== 32'b0) begin
            $error("count non-zero after read-from-empty: %0d (underflow wrap?)", count);
            errors++;
        end

        if(underflow !== 1'b1) begin
            $error("underflow not assreted");
            errors++;
        end

    push_m(8'hA1);
    check_count();
    pop_m();

    endtask

    task automatic test_simultaneous();
        int cnt_before;
        $display("--- test_simultaneous ---");
        reset_all();

        // Наполнить наполовину
        for (int i = 0; i < DEPTH/2; i++) begin
            push_m(8'h40 + 8'(i));
        end
        check_count();

        cnt_before = 32'(count);

        // Серия одновременных операций — count не должен меняться
        for (int i = 0; i < DEPTH; i++) begin
            push_pop_m(8'h80 + 8'(i));
            if (32'(count) !== cnt_before) begin
                $error("count changed on simultaneous rd/wr: %0d -> %0d (iter %0d)", cnt_before, count, i);
                errors++;
            end
        end

    check_count();

        // Вычитать остаток, сверяя с моделью
        while (model.size() > 0) begin
            pop_m();
        end

    endtask

    
    task automatic test_wraparound();
        $display("---test_wraparound---");
        reset_all();

        for(int i = 0; i < DEPTH; i++) begin
            push_m(8'(i));
            pop_m();
            check_count();
        end
    endtask


    //=========================================================
    // Тест
    //=========================================================
    logic [WIDTH-1:0] d;

    initial begin
        test_reset_state();
        test_fill_to_full();
        test_fill_then_drain();
        test_write_when_full();
        test_read_when_empty();
        test_simultaneous();
        test_wraparound();

        repeat(5) @(posedge clk);
        if (errors == 0) $display("=== PASS ===");
        else             $display("=== FAIL: %0d errors ===", errors);
        $finish;
    end

endmodule
