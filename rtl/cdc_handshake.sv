`timescale 1ns/1ps
`default_nettype none

module cdc_handshake #(
    parameter int unsigned WIDTH  = 32,
    parameter int unsigned STAGES = 2
) (
    //Домен источника
    input wire               clk_src,
    input wire               rst_src_n,
    input wire   [WIDTH-1:0] data_i,
    input wire               valid_i,
    output logic             ready_o,
    
    //Домен приемника
    input wire               clk_dst,
    input wire               rst_dst_n,
    output logic [WIDTH-1:0] data_o,
    output logic             valid_o
);

    logic [WIDTH-1:0] data_q;
    logic             start;
    logic             req_pulse;
    logic             ack_pulse;

    assign start = valid_i && ready_o;
    
    //Домен источника
    always_ff @(posedge clk_src) begin
        if(!rst_src_n) begin
            ready_o <= 1'b1;
            data_q  <= '0;
        end
        else if(start) begin
            ready_o <= '0;
            data_q  <= data_i;
        end  
        else if(ack_pulse) begin
            ready_o <= 1'b1;
        end
    end

    //запрос А -> B
    cdc_pulse_sync #(.STAGES(STAGES)) u_req(
        .clk_src(clk_src), 
        .rst_src_n(rst_src_n), 
        .pulse_i(start), 
        .clk_dst(clk_dst), 
        .rst_dst_n(rst_dst_n), 
        .pulse_o(req_pulse)
    );

    //Домен приемника
    always_ff @(posedge clk_dst) begin
        if(!rst_dst_n) begin
            data_o  <= '0;
            valid_o <= '0;
        end
        else begin
            if(req_pulse) data_o  <= data_q;
            valid_o <= req_pulse;
        end
    end

    //подтверждение B -> A
    cdc_pulse_sync #(.STAGES(STAGES)) u_ack(
        .clk_src(clk_dst), 
        .rst_src_n(rst_dst_n), 
        .pulse_i(req_pulse), 
        .clk_dst(clk_src), 
        .rst_dst_n(rst_src_n), 
        .pulse_o(ack_pulse)
    );

`ifndef SYNTHESIS

    property p_valid_o_one_beat;
    @(posedge clk_dst) disable iff(!rst_dst_n)
    valid_o |=> !valid_o;
    endproperty
    a_valid_o_one_beat: assert property(p_valid_o_one_beat)
        else $error("valid_o active more time than one beat");
    
    property p_ready_fall_correct;
    @(posedge clk_src) disable iff(!rst_src_n)
    (valid_i && ready_o) |=> !ready_o;
    endproperty
    a_ready_fall_correct: assert property(p_ready_fall_correct)
        else $error("ready_o dont fall in correct time");

    property p_data_stable_while_not_ready;
    @(posedge clk_src) disable iff(!rst_src_n)
    !ready_o |=> $stable(data_q);
    endproperty
    a_data_stable_while_not_ready: assert property(p_data_stable_while_not_ready)
        else $error("data_q changed while ready_o = 0");
    
    property p_ready_didnt_rise_without_ack;
    @(posedge clk_src) disable iff(!rst_src_n)
    $rose(ready_o) |-> $past(ack_pulse);
    endproperty
    a_ready_didnt_rise_without_ack: assert property(p_ready_didnt_rise_without_ack)
        else $error("ready_o rose without ack_pulse");
`endif

endmodule

`default_nettype wire
