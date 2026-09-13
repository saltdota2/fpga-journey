`default_nettype none
`timescale 1ns/1ps

module reduction_chain #(
    parameter int unsigned N      = 16,
    parameter int unsigned WIDTH  = 8,
    parameter int unsigned STAGES = 16    // 1, 2, 4, 8, 16
) (
    input  wire                        clk,
    input  wire  [WIDTH-1:0]           data_i [N],
    output logic [WIDTH+$clog2(N)-1:0] result_o
);
    localparam int unsigned OUT_W = WIDTH + $clog2(N);
    localparam int unsigned CUT   = N / STAGES;   // сумматоров на стадию

    if ((N % STAGES) != 0)
        $error("N must be divisible by STAGES");

    logic [OUT_W-1:0] chain [N];

    assign chain[0] = data_i[0];

    for (genvar i = 1; i < N; i++) begin : g_chain
        if (i % CUT == 0) begin : g_reg
            always_ff @(posedge clk)
                chain[i] <= chain[i-1] + data_i[i];
        end else begin : g_comb
            assign chain[i] = chain[i-1] + data_i[i];
        end
    end

    assign result_o = chain[N-1];

endmodule

`default_nettype wire