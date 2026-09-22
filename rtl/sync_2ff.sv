`timescale 1ns/1ps
`default_nettype none

module sync_2ff #(
    parameter int unsigned STAGES = 2
) (
    input  wire  clk,
    input  wire  rst_n,
    input  wire  async_i,
    output logic sync_o
);
    if (STAGES < 2)  begin : chk_stages
        $error("sync_2ff: STAGES must be > 2, got %0d", STAGES);
    end

    (* ASYNC_REG = "TRUE" *) logic [STAGES-1:0] sync_ff;

    always_ff @(posedge clk) begin
        if (!rst_n) sync_ff <= '0;
        else        sync_ff <= {sync_ff[STAGES-2:0], async_i};
    end

    assign sync_o = sync_ff[STAGES-1];

endmodule
`default_nettype wire
