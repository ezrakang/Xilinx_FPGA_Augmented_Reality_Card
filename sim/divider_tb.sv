`timescale 1ns / 1ps
`default_nettype none

module divider_tb;
  logic clk;
  logic rst;

  logic valid_in;
  logic [8:0] dividend;
  logic [8:0] divisor;


  logic [8:0] quotient;
  logic [8:0] remainder;
  logic error_out;
  logic busy_out;
  logic valid_out;

  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  divider #(
    .WIDTH(9)
  ) uut (
    .clk_in(clk),
    .rst_in(rst),
    .dividend_in(dividend),
    .divisor_in(divisor),
    .data_valid_in(valid_in),
    .quotient_out(quotient),
    .remainder_out(remainder),
    .data_valid_out(valid_out)
    //.error_out(error_out),
    //.busy_out(busy_out)
  );

  always begin
    #10;
    clk = !clk;
  end

  initial begin
    $dumpfile("divider.vcd");
    $dumpvars(0, divider_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #20;
    rst = 1;
    #20;
    rst = 0;

    $display("test 1: simple test 64/3");
    valid_in = 1;
    dividend = 9'd64;
    divisor = 9'd40;
    #20;

    dividend = 9'd40;
    divisor = 9'd4;
    #20;


    for (int i=0; i<15; i=i+1) begin
      valid_in = 0;
      $display("valid out ", valid_out);
      $display("quotient out ", quotient);
      #20;
    end
    #80;

    $display("finishing sim"); 
    $finish;
  end
endmodule //sine_table_tb

`default_nettype wire



