module cdc_top (
    input  wire  clk_a,
    input  wire  clk_b,
    input  wire  rst_n,
    input  wire  sig_a,      // генерируется в домене A
    output logic sig_b       // используется в домене B
);
    logic sig_a_reg;

    always_ff @(posedge clk_a) begin
        if (!rst_n) sig_a_reg <= 1'b0;
        else        sig_a_reg <= sig_a;
    end

    sync_2ff #(.STAGES(2)) u_sync (
        .clk     (clk_b),
        .rst_n   (rst_n),
        .async_i (sig_a_reg),
        .sync_o  (sig_b)
    );
endmodule