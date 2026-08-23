`timescale 1ns/1ps


module tb_util_pkg;
    import util_pkg::*;
    
    initial begin
        logic[7:0] b, g, b_back;
        int errors = 0;

        for(int i = 0; i < 256; i++) begin
            b = i[7:0];
            g = bin2gray(b);
            b_back = gray2bin(g);

            if(b !== b_back) begin
                $error("Roundtrip failed: bin=%02h gray=%02h back=%02h", b, g, b_back);
                errors++;
            end
        end

        for (int i = 0; i < 255; i++) begin
            logic [7:0] g1, g2;
            g1 = bin2gray(i[7:0]);
            g2 = bin2gray(i[7:0] + 8'd1);
            if ($countones(g1 ^ g2) != 1) begin
                $error("Gray property violated at %0d: %02h -> %02h", i, g1, g2);
                errors++;
            end
        end
                
        if (errors == 0) $display("PASS: all checks OK");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end
endmodule