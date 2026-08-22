`timescale 1ns/1ps

module latch_lab(
    input logic sel,
    input logic d,
    input logic e,
    output logic q
);

    always_comb begin
        q = sel ? d : e;
    end
endmodule
