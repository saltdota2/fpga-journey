`default_nettype none
`timescale 1ns/1ps

module reset_sync #(
    parameter int unsigned STAGES = 2
) (
    input wire   clk,
    input wire   rst_async_n,
    output logic rst_sync_n
);
    initial begin
        if(STAGES < 2)  $fatal(1, "reset_sync: STAGES must be >= 2, got %0d", STAGES);
    end

    (* ASYNC_REG = "TRUE" *) logic [STAGES-1:0] sync_ff;

    always_ff @(posedge clk, negedge rst_async_n) begin
        if(!rst_async_n)
            sync_ff <= '0;
        else
            sync_ff <= {sync_ff[STAGES-2:0], 1'b1};
    end

    assign rst_sync_n = sync_ff[STAGES-1];

`ifndef SYNTHESIS
    always @(negedge rst_async_n) begin
        #1ps;
        if(rst_sync_n !== 1'b0)
            $error("async assert failed: rst_sync_n=%b", rst_sync_n);
    end

    property p_hold_while_async;
        @(posedge clk)
        !rst_async_n |-> !rst_sync_n;
    endproperty
    a_hold_while_async: assert property(p_hold_while_async)
        else $error("rst_sync_n = %b while rst_async_n active", rst_sync_n);

    logic [STAGES-1:0] async_hist = '0;
    always_ff @(posedge clk) async_hist <= {async_hist[STAGES-2:0], rst_async_n};

    property p_deassert_after_stages;
        @(posedge clk) (rst_async_n && (&async_hist)) |-> rst_sync_n;
    endproperty
    a_deassert_after_stages: assert property (p_deassert_after_stages)
        else $error("rst_sync_n did not deassert after %0d cycles", STAGES);

    property p_no_early_deassert;
        @(posedge clk) $rose(rst_sync_n) |-> (&async_hist);
    endproperty
    a_no_early_deassert: assert property (p_no_early_deassert)
        else $error("rst_sync_n deasserted too early");

`endif
endmodule
`default_nettype wire

