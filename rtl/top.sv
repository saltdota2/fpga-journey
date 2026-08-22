`default_nettype none
`timescale 1ns/1ps

interface vr_if;
    logic        valid;
    logic        ready;
    logic [31:0] data;

    modport src (output valid, input  ready, output data);
    modport dst (input  valid, output ready, input  data);
endinterface


module producer (vr_if.src bus, input wire clk, input wire rst_n);
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            bus.valid <= 1'b0;
            bus.data  <= '0;
        end
        else begin
            bus.valid <= 1'b1;
            if (bus.valid && bus.ready)
                bus.data <= bus.data + 1'b1;
        end
    end
endmodule


module consumer (vr_if.dst bus, input wire clk, input wire rst_n);
    always_ff @(posedge clk) begin
        if (!rst_n) bus.ready <= 1'b0;
        else        bus.ready <= 1'b1;
    end
endmodule


module top (
    input  wire         clk,
    input  wire         rst_n,
    output logic [31:0] count_o
);
    vr_if bus();

    producer u_prod (.bus(bus.src), .clk(clk), .rst_n(rst_n));
    consumer u_cons (.bus(bus.dst), .clk(clk), .rst_n(rst_n));

    assign count_o = bus.data;
endmodule

`default_nettype wire
