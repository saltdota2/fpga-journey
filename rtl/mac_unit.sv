`timescale 1ns/1ps
`default_nettype none

module mac_unit #(
    parameter int unsigned STAGES = 1    // 1, 2, 4
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_i,
    input  wire  [15:0] a_i,
    input  wire  [15:0] b_i,
    input  wire  [31:0] c_i,
    output logic        valid_o,
    output logic [31:0] result_o
);
    initial begin
        if((STAGES != 1) && (STAGES != 2) && (STAGES != 4))
            $error("STAGES must be only 1, 2, 4");
    end

    logic [STAGES-1:0] valid_pipe;

    always_ff @(posedge clk) begin  
        if(!rst_n) begin
            valid_pipe <= '0;
        end else begin
            valid_pipe[0] <= valid_i;
            for(int i = 1; i < STAGES; i++)
                valid_pipe[i] <= valid_pipe[i-1];
        end 
    end

    assign valid_o = valid_pipe[STAGES-1];

    if(STAGES == 1) begin : g_st1

        always_ff @(posedge clk) begin
            if(!rst_n)
                result_o <= '0;
            else
                result_o <= a_i * b_i + c_i;
        end

    end else if(STAGES == 2) begin : g_st2
        logic [31:0] mul_q, c_q;

        always_ff @(posedge clk) begin 
            if(!rst_n) begin
                c_q   <= '0;
                mul_q <= '0;
            end
            else begin
                mul_q <= a_i * b_i;
                c_q   <= c_i;
            end
        end 

        always_ff @(posedge clk) begin
            if(!rst_n) 
                result_o <= '0;
            else
                result_o <= mul_q + c_q;
        end 

    end else if(STAGES == 4) begin : g_st4
        logic [15:0] a_q, b_q;
        logic [31:0] mul_q, sum_q;
        logic [31:0] c_q1, c_q2;

        //stage 1
        always_ff @(posedge clk) begin
            if(!rst_n) begin 
                a_q  <= '0;
                b_q  <= '0;
                c_q1 <= '0;
            end else begin
                a_q  <= a_i;
                b_q  <= b_i;
                c_q1 <= c_i;
            end
        end

        //stage 2
        always_ff @(posedge clk) begin
            if(!rst_n) begin 
                mul_q <= '0;
                c_q2  <= '0;
            end else begin 
                mul_q <= a_q * b_q;
                c_q2  <= c_q1;
            end
        end

        //stage 3
        always_ff @(posedge clk) begin
            if(!rst_n)
                sum_q <= '0;
            else
                sum_q <= mul_q + c_q2;
        end

        //stage 4
        always_ff @(posedge clk) begin
            if(!rst_n) 
                result_o <= '0;
            else
                result_o <= sum_q;
        end
    end

endmodule

`default_nettype wire