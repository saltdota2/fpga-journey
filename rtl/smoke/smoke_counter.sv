`timescale 1ns/1ps

module smoke_counter(
    input logic clk,
    input logic reset,
    output logic q
);

    always_ff @(posedge clk, posedge reset) begin
        if(reset)
            q <= 0;
        else
            q <= q + 1;
    end

endmodule
....

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
