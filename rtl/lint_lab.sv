`default_nettype none

module lint_lab(
    input logic [1:0] sel2,
    input logic ads,
    output logic [3:0] y
);
    always_comb begin
        case (sel2)
            2'b00: y = 4'd1;
            2'b01: y = 4'd2;
            2'b10: y = 4'd3;
            default: y = 4'd0;
        endcase
    end
endmodule

`default_nettype wire

