
`timescale 1ns/1ps
`default_nettype none

function automatic logic [7:0] bin2gray (input logic [7:0] bin);
    return bin ^ (bin >> 1);
endfunction

function automatic logic [7:0] gray2bin (input logic [7:0] gray);
    logic [7:0] bin;
    bin[7] = gray[7];
    for(int i = 6; i >= 0; i--)
        bin[i] = bin[i+1] ^ gray[i];
    return bin;
endfunction

function automatic logic onehot_check (input logic [7:0] x);
    return ((x!=0) && ((x & (x-1)) == 0));
endfunction

function automatic logic [3:0]priority_encoder (input logic [7:0] d);
    logic [3:0] dx;
    dx = 4'd8;
    for(int i = 7; i >= 0; i--)
        if(d[i]) dx = i[3:0];
    return dx;
endfunction

function automatic logic [3:0] count_ones (input logic [7:0] d);
    logic [3:0] c;
    c = '0;
    for(int i = 0; i < 8; i++)
        if(d[i]) c++;
    return c;
endfunction

`default_nettype wire