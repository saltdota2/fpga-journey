`timescale 1ns/1ps
`default_nettype none
// Feeds data/fir_in.hex with random valid gaps, compares with data/fir_expected.hex bit by bit,
// writes the RTL output to data/fir_out_rtl.hex.  Run with +PV=<valid %>.
module tb_fir_lp;
    localparam int unsigned N = 4000;

    logic aclk = 1'b0, aresetn = 1'b0;
    logic s_valid = 1'b0, m_valid;
    logic signed [15:0] s_data = '0, m_data;
    logic [15:0] x_mem [N];
    logic [15:0] y_mem [N];
    int unsigned pv;

    fir_lp dut (
        .aclk, .aresetn,
        .s_axis_tvalid(s_valid), .s_axis_tdata(s_data),
        .m_axis_tvalid(m_valid), .m_axis_tdata(m_data)
    );

    initial forever #5 aclk = ~aclk;

    // Source: next sample from the file, with random pauses
    int unsigned sent = 0;
    always_ff @(posedge aclk) begin
        if (aresetn) begin
            if (sent < N && $urandom_range(99) < pv) begin
                s_valid <= 1'b1;
                s_data  <= x_mem[sent];
                sent    <= sent + 1;
            end else begin
                s_valid <= 1'b0;
            end
        end
    end

    // Sink: compare every output with the model
    int unsigned rcvd = 0, errs = 0, fd;
    always_ff @(posedge aclk) begin
        if (aresetn && m_valid) begin
            if (m_data !== y_mem[rcvd]) begin
                errs <= errs + 1;
                if (errs < 5) $display("[%0t] sample %0d: got %0d, expected %0d",
                                       $time, rcvd, m_data, $signed(y_mem[rcvd]));
            end
            $fwrite(fd, "%04h\n", m_data);
            rcvd <= rcvd + 1;
        end
    end

    initial begin
        if (!$value$plusargs("PV=%d", pv)) pv = 100;
        $readmemh("C:/fir_task/fir_task/data/fir_in.hex", x_mem);
        $readmemh("C:/fir_task/fir_task/data/fir_expected.hex", y_mem);
        fd = $fopen("C:/fir_task/fir_task/data/fir_out_rtl.hex", "w");
        repeat (3) @(posedge aclk);
        aresetn = 1'b1;
        wait (rcvd == N || $time > 100_000_000);
        $fclose(fd);
        $display("PV=%0d: outputs=%0d of %0d, errors=%0d -> %s", pv, rcvd, N, errs,
                 (rcvd == N && errs == 0) ? "PASS" : "FAIL");
        $finish;
    end
endmodule
`default_nettype wire
