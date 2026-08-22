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