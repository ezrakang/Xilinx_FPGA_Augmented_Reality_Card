`timescale 1ns / 1ps
`default_nettype none

module multiply_tb;
  logic clk;
  logic rst;

  logic signed [7:0] v1 [2:0];
  logic signed [7:0] v2 [2:0];
  logic signed [7:0] v3 [2:0];
  logic signed [15:0] sin_val;
  logic signed [15:0] cos_val;

  logic signed [8:0] v1_out [2:0];
  logic signed [8:0] v2_out [2:0];
  logic signed [8:0] v3_out [2:0];
  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  multiply uut (
    .v1(v1),
    .v2(v2),
    .v3(v3),
    .sin_val(sin_val),
    .cos_val(cos_val),
    .v1_out(v1_out),
    .v2_out(v2_out),
    .v3_out(v3_out)
  );

  always begin
    #10;
    clk = !clk;
  end

  initial begin
    $dumpfile("multiply.vcd");
    $dumpvars(0, multiply_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #20;
    rst = 1;
    #20;
    rst = 0;

    $display("test 1:");
    v1[0] = -8'sd2;
    v1[1] = 8'sd8;
    v1[2] = 8'sd3;
    v2[0] = -8'sd2;
    v2[1] = 8'sd2;
    v2[2] = -8'sd3;
    v3[0] = 8'sd9;
    v3[1] = 8'sd0;
    v3[2] = -8'sd7;
    sin_val = 16'sb0000_0000_1100_0000;
    cos_val = 16'sb0000_0000_1010_0000;

    $display("v1[0] ", v1_out[0]);

    #80; 
    $display("finishing sim"); 
    $finish;
  end
endmodule //sine_table_tb

`default_nettype wire



