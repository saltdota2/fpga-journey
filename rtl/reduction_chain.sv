`default_nettype none
`timescale 1ns/1ps

module reduction_chain #(
    parameter int unsigned N     = 16,
    parameter int unsigned WIDTH = 8
) (
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire  [WIDTH-1:0]           data_i [N],
    output logic [WIDTH+$clog2(N)-1:0] result_o
);
    localparam int unsigned OUT_W = WIDTH + $clog2(N);

    logic [OUT_W-1:0] chain [N];

    // первый элемент — просто вход
    always_ff @(posedge clk) chain[0] <= OUT_W'(data_i[0]);

    genvar i;
    generate
        for (i = 1; i < N; i++) begin : g_chain
            always_ff @(posedge clk)
            chain[i] <= chain[i-1] + OUT_W'(data_i[i]);
        end
    endgenerate

    assign result_o = chain[N-1];

endmodule

`default_nettype wire