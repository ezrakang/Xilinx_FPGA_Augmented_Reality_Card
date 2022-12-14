`timescale 1ns / 1ps
`default_nettype none

module zbuffer_tb;
  logic clk;
  logic rst;

  logic valid_in;
  logic [30:0] pixel_in;

  logic valid_out;
  logic [11:0] pixel_addr_out;
  logic [9:0] pixel_out;
  
  logic [30:0] pixel_in_arr [7:0];
  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  zbuffer #(
    .SIZE(64),
    .WIDTH(9)
  ) uut (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .pixel_in(pixel_in),
    .valid_out(valid_out),
    .pixel_addr(pixel_addr_out),
    .pixel_out(pixel_out)
  );

  always begin
    #10;
    clk = !clk;
  end

  initial begin
    $dumpfile("zbuffer.vcd");
    $dumpvars(0, zbuffer_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    //set test pixel_in values
    pixel_in_arr[0] = 31'h00000001;
    pixel_in_arr[1] = 31'h04000002;
    pixel_in_arr[2] = 31'h08000003;
    pixel_in_arr[3] = 31'h06000004;
    pixel_in_arr[4] = 31'h00100005;
    pixel_in_arr[5] = 31'h03000006;
    pixel_in_arr[6] = 31'h04100007;
    pixel_in_arr[7] = 31'h05001008;
    #20;
    rst = 1;
    #20;
    rst = 0;

    $display("test 1: test valid depth");
    valid_in = 1;
    pixel_in = 28'h0000001;
    
    for (int i=0; i<4; i=i+1) begin
      #20;
      valid_in = 0;
      $display("valid out ", valid_out);
      $display("pixel out ", pixel_out);
      $display("pixel_addr out ", pixel_addr_out);
    end

    rst = 1;
    #20;
    rst = 0;
    $display("test 2: almost full throughput valids");
    for (int i=0; i<8; i=i+1) begin
      if (i != 5) begin
        valid_in = 1;
        pixel_in = pixel_in_arr[i];
      end else begin
        valid_in = 0;
      end
      $display("valid out ", valid_out);
      $display("pixel out ", pixel_out);
      $display("pixel_addr out ", pixel_addr_out);
      #20;
    end
    for (int i=0; i<5; i=i+1) begin
      valid_in = 0;
      $display("valid out ", valid_out);
      $display("pixel out ", pixel_out);
      $display("pixel_addr out ", pixel_addr_out);
      #20;
    end

    $display("test 3: no reset, test pixel with higher depth (should not pull up valid");
    valid_in = 1;
    pixel_in = 31'h0500A008;
    #60;
    $display("valid out ", valid_out);

    #80;

    $display("finishing sim"); 
    $finish;
  end
endmodule //zbuffer_tb

`default_nettype wire



