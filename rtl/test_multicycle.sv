`timescale 1ns/1ps
`default_nettype none


module test_multicycle (
    input  wire         clk,
    input  wire         rst_n,
    input  wire  [15:0] a, b,
    output logic [31:0] result
);
    logic [31:0] slow_result;
    logic [1:0]  phase;

    // Медленное вычисление, результат нужен раз в 4 такта
    always_comb slow_result = a * b + a - b;   // намеренно длинный путь

    always_ff @(posedge clk) begin
        if (!rst_n) phase <= '0;
        else        phase <= phase + 1'b1;
    end

    always_ff @(posedge clk) begin
        if (phase == 2'd3) result <= slow_result;   // забираем раз в 4 такта
    end
endmodule

`default_nettype wire