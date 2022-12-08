`timescale 1ns / 1ps
`default_nettype none

module divider_top_tb;
  logic clk;
  logic rst;

  logic [8:0] dividend [5:0];
  logic [8:0] divisor [2:0];

  logic [8:0] quotient [5:0];

  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  divider_top #(
    .SIZE(6),
    .WIDTH(9)
  ) uut (
    .clk(clk),
    .rst(rst),
    .dividend(dividend),
    .divisor(divisor),
    //.data_valid_in(valid_in),
    .quotient(quotient)
    //.remainder_out(remainder),
    //.data_valid_out(valid_out)
    //.error_out(error_out),
    //.busy_out(busy_out)
  );

  always begin
    #10;
    clk = !clk;
  end

  initial begin
    $dumpfile("divider_top.vcd");
    $dumpvars(0, divider_top_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #20;
    rst = 1;
    #20;
    rst = 0;

    $display("test 1: simple test 64/3, 20/3, 41/1, 1/1, 18/7, 50/7");
    dividend[0] = 9'd64;
    dividend[1] = 9'd20;
    dividend[2] = 9'd41;
    dividend[3] = 9'd1;
    dividend[4] = 9'd18;
    dividend[5] = 9'd50;
    divisor[0] = 9'd3;
    divisor[1] = 9'd1;
    divisor[2] = 9'd7;
    #40;

    for (int i=0; i<10; i=i+1) begin
      $display("64/3 ", quotient[0]);
      $display("20/3 ", quotient[1]);
      $display("41/1 ", quotient[2]);
      $display("1/1 ", quotient[3]);
      $display("18/7 ", quotient[4]);
      $display("50/7 ", quotient[5]);
      #20;
    end
    #80;

    $display("finishing sim"); 
    $finish;
  end
endmodule //sine_table_tb

`default_nettype wire



