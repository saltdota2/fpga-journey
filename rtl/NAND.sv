module NAND(
    input wire a,
    input wire b,
    output logic nand_o
);
assign nand_o = ~(a & b);
endmodule 