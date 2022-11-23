`timescale 1ns / 1ps
`default_nettype none

module sine_table_tb;
  logic clk;
  logic rst;

  logic [8:0] id;
  logic signed [15:0] data;
  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  sine_table #(
    .ROM_DEPTH(90),
    .ROM_WIDTH(8),
    .ADDRW(9)
  ) uut (
    .id(id),
    .rst(rst),
    .clk(clk),
    .data(data)
  );

  always begin
    #10;
    clk = !clk;
  end

  initial begin
    $dumpfile("sine_table.vcd");
    $dumpvars(0, sine_table_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #20;
    rst = 1;
    #20;
    rst = 0;

    $display("test 1: sin(30) should be 128");
    id = 30;
    #60;
    $display("checking data out");
    $display("data top half ", data[15:8]);
    $display("data bottom half ", data[7:0]);
    
    $display("test 2: sin(60) should be 222");
    id = 60;
    #60;
    $display("checking data out");
    $display("%b", data[7:0]);
    $display("data top half ", data[15:8]);
    $display("data bottom half ", data[7:0]);
    
    $display("test 3: sin(90) should be ");
    id = 90;
    #60;
    $display("checking data out");
    $display("%b", data[7:0]);
    $display("data top half ", data[15:8]);
    $display("data bottom half ", data[7:0]);
    
    $display("test 4: sin(225)");
    id = 225;
    #60;
    $display("checking data out");
    $display("top half %b", data[15:8]);
    $display("bottom half %b", data[7:0]);
    $display("data top half ", data[15:8]);
    $display("data bottom half ", data[7:0]);

    $display("finishing sim"); 
    $finish;
  end
endmodule //sine_table_tb

`default_nettype wire



