`timescale 1ns / 1ps
`default_nettype none

module rasterize_tb;
  logic clk;
  logic rst;

  logic valid_in;
  logic [63:0] model_in;

  logic valid_out;
  logic [27:0] pixel_out;
  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  rasterize uut (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .model_in(model_in),
    .valid(valid_out),
    .pixel_out(pixel_out)
  );

  always begin
    #10;
    clk = !clk;
  end

  initial begin
    $dumpfile("rasterize.vcd");
    $dumpvars(0, rasterize_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #20;
    rst = 1;
    #20;
    rst = 0;

    $display("test 1:");
    valid_in = 1;
    model_in = 64'h0410C21000C10003;
    for (int i=0; i<10; i=i+1) begin
      #20;
      valid_in = 0;
      $display("valid out ", valid_out);
      $display("pixel out ", pixel_out);
    end
    #80;

    $display("finishing sim"); 
    $finish;
  end
endmodule //sine_table_tb

`default_nettype wire



