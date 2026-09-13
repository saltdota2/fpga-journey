`timescale 1ns/1ps
`default_nettype none

module pkt_filter #(
    parameter int unsigned N_RULES = 16,
    parameter int unsigned WIDTH   = 32
) (
    input  wire               clk,
    input  wire               rst_n,

    input  wire               valid_i,
    input  wire  [WIDTH-1:0]  addr_i,
    input  wire  [7:0]        type_i,
    input  wire  [15:0]       len_i,

    output logic              valid_o,
    output logic              match_o,
    output logic [3:0]        rule_id_o,
    output logic [WIDTH-1:0]  addr_o
);

    // Таблица правил (конфигурируется извне, здесь — константы)
    logic [WIDTH-1:0] rule_addr_lo [N_RULES];
    logic [WIDTH-1:0] rule_addr_hi [N_RULES];
    logic [7:0]       rule_type    [N_RULES];
    logic [15:0]      rule_len_min [N_RULES];

    initial begin
        for (int i = 0; i < N_RULES; i++) begin
            rule_addr_lo[i] = WIDTH'(i * 4096);
            rule_addr_hi[i] = WIDTH'(i * 4096 + 2048);
            rule_type[i]    = 8'(i + 1);
            rule_len_min[i] = 16'(64 + i * 16);
        end
    end

    logic [N_RULES-1:0] hit;
    logic [3:0]         first_hit;
    logic               any_hit;
    logic [1:0]         valid_i_q;

    always_ff @(posedge clk) begin
        if(!rst_n)
            valid_i_q <= '0;
        else
            valid_i_q <= {valid_i_q[0], valid_i};
    end



    // Проверка всех правил параллельно
    always_ff @(posedge clk) begin
        if (!rst_n)
                hit <= '0;
        else
            for (int i = 0; i < N_RULES; i++) begin
                hit[i] <= (addr_i >= rule_addr_lo[i])
                    && (addr_i <= rule_addr_hi[i])
                    && (type_i == rule_type[i])
                    && (len_i  >= rule_len_min[i]);
            end
    end

    // Приоритетный шифратор: первое сработавшее правило
    logic [3:0] first_hit_c;
    logic       any_hit_c;

    always_comb begin
        first_hit_c = '0;
        any_hit_c   = 1'b0;
        for (int i = N_RULES-1; i >= 0; i--) begin
            if (hit[i]) begin
                first_hit_c = 4'(i);      // blocking, в always_comb
                any_hit_c   = 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            first_hit <= '0;
            any_hit   <= 1'b0;
        end
        else begin
            first_hit <= first_hit_c;
            any_hit   <= any_hit_c;
        end
    end

    logic              valid_q, match_q;
    logic [3:0]        rule_id_q;
    logic [WIDTH-1:0]  addr_q;
    logic [1:0][WIDTH-1:0] addr_i_q;

    always_ff @(posedge clk) begin
        if(!rst_n)
            addr_i_q <= '0;
        else
            addr_i_q <= {addr_i_q[0], addr_i};
    end

    assign valid_o   = valid_i_q[1];
    assign match_o   = any_hit;
    assign rule_id_o = first_hit;
    assign addr_o    = addr_i_q[1];


endmodule

`default_nettype wire