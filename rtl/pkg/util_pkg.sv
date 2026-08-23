`timescale 1ns/1ps

package util_pkg;

    localparam int unsigned WIDTH = 8;

function automatic logic [WIDTH-1:0] bin2gray (input logic [WIDTH-1:0] bin);
    return bin ^ (bin >> 1);
endfunction

function automatic logic [WIDTH-1:0] gray2bin (input logic [WIDTH-1:0] gray);
    logic [WIDTH-1:0] bin;
    bin[WIDTH-1] = gray[WIDTH-1];
    for(int i = WIDTH-2; i >= 0; i--)
        bin[i] = bin[i+1] ^ gray[i];
    return bin;
endfunction

function automatic logic onehot_check (input logic [WIDTH-1:0] x);
    return ((x!=0) && ((x & (x-1)) == 0));
endfunction

function automatic logic [$clog2(WIDTH):0] priority_encoder (input logic [WIDTH-1:0] d);
    logic [$clog2(WIDTH):0] dx;
    dx = ($clog2(WIDTH)+1)'(WIDTH);
    for(int i = WIDTH-1; i >= 0; i--)
        if(d[i]) dx = i[$clog2(WIDTH):0];
    return dx;
endfunction

function automatic logic [$clog2(WIDTH):0] count_ones (input logic [WIDTH-1:0] d);
    logic [$clog2(WIDTH):0] c;
    c = '0;
    for(int i = 0; i < WIDTH; i++)
        if(d[i]) c++;
    return c;
endfunction

endpackage

