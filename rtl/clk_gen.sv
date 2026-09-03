module clk_gen (
    input  wire  clk_in,      // 100 МГц с платы
    input  wire  rst_n,
    output logic clk_100,     // 100 МГц через MMCM
    output logic clk_50,      // 50 МГц
    output logic locked
);

    logic clk_100_raw, clk_50_raw;
    logic clk_fb, clk_fb_buf;

    MMCME2_BASE #(
        .CLKIN1_PERIOD    (10.000),
        .CLKFBOUT_MULT_F  (10.000),
        .DIVCLK_DIVIDE    (1),
        .CLKOUT0_DIVIDE_F (10.000),
        .CLKOUT1_DIVIDE   (20)
    ) u_mmcm (
        .CLKIN1 (clk_in),
        .CLKFBIN(clk_fb_buf),
        .CLKFBOUT(clk_fb),
        .CLKOUT0(clk_100_raw),
        .CLKOUT1(clk_50_raw),
        .LOCKED (locked),
        .RST(!rst_n),
        .PWRDWN(1'b0)
    );

    BUFG u_fb  (.I(clk_fb),      .O(clk_fb_buf));
    BUFG u_c0  (.I(clk_100_raw), .O(clk_100));
    BUFG u_c1  (.I(clk_50_raw),  .O(clk_50));
endmodule