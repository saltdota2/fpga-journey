`default_nettype none
`timescale 1ns/1ps

module reduction_tree #(
    parameter int unsigned N     = 16,   // число входов (степень двойки)
    parameter int unsigned WIDTH = 8    // ширина одного входа
) (
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire  [WIDTH-1:0]           data_i [N],
    output logic [WIDTH+$clog2(N)-1:0] result_o
);

    localparam int unsigned LEVELS = $clog2(N);      // 8 → 3
    localparam int unsigned OUT_W  = WIDTH + LEVELS; // запас на рост суммы

    // Проверка параметров
    initial begin
        if (N < 2)     $fatal(1, "N must be >= 2");
        if (N & (N-1)) $fatal(1, "N must be a power of 2");
    end

    // Промежуточные значения.
    // stage[0]      — входы (расширенные до OUT_W)
    // stage[LEVELS] — результат, используется только элемент [0]
    logic [OUT_W-1:0] stage [LEVELS+1][N];

    // Уровень 0: загрузка входов с расширением ширины
    genvar k;
    generate
        for (k = 0; k < N; k++) begin : g_input
            assign stage[0][k] = OUT_W'(data_i[k]);
        end
    endgenerate

    // Дерево: LEVELS уровней сложения с регистрами
    genvar lvl, idx;
    generate
        for (lvl = 0; lvl < LEVELS; lvl++) begin : g_level
            for (idx = 0; idx < (N >> (lvl+1)); idx++) begin : g_node
                always_ff @(posedge clk) begin
                    if (!rst_n)
                        stage[lvl+1][idx] <= '0;
                    else
                        stage[lvl+1][idx] <= stage[lvl][idx] + stage[lvl][idx + (N >> (lvl+1))];
                end
            end
        end
    endgenerate

    assign result_o = stage[LEVELS][0];

endmodule

`default_nettype wire