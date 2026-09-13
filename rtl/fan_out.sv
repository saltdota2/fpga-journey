module fan_out #(parameter int unsigned N = 200) (
    input  wire  clk,
    input  wire  rst_n,
    input  wire  d_i,
    input  wire  [N-1:0] data_i,
    output logic [N-1:0] q_o
);
    (* DONT_TOUCH = "true" *) logic [7:0] enable;
    always_ff @(posedge clk) enable <= 8'(d_i);


    always_ff @(posedge clk) begin
        for (int i = 0; i < N; i++) begin
            if (enable[i%8]) q_o[i] <= data_i[i];
        end
    end
endmodule