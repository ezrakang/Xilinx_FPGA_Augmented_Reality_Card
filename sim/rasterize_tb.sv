`timescale 1ns / 1ps
`default_nettype none

module rasterize_tb;
  logic clk;
  logic rst;

  logic valid_in;
  logic [54:0] model_in;

  logic valid_out;
  logic [30:0] pixel_out;
  logic [11:0] valid_cnt;
  logic [15:0] cycle_cnt;
  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */
  logic rasterize_busy;
  rasterize uut (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .model_in(model_in),
    .valid(valid_out),
    .busy_out(rasterize_busy),
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
    model_in = 55'b000_0000_1000_0010_0001_1000_0110_0001_1000_0000_1010_0000_0100_0000;
    for (int i=0; i<1100; i=i+1) begin
      #20;
      valid_in = 0;
      if (i%5 == 0) begin
        $display("valid out ", valid_out);
        $display("pixel out ", pixel_out);
      end
    end
    $display("VALID COUNT ", valid_cnt);
    $display("CYCLE COUNT ", cycle_cnt);
    #80;

    $display("finishing sim"); 
    $finish;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      valid_cnt <= 0;
      cycle_cnt <= 0;
    end else begin
      valid_cnt <= valid_out ? valid_cnt + 1 : valid_cnt;
      cycle_cnt <= rasterize_busy ? cycle_cnt + 1 : cycle_cnt;
    end
  end

endmodule //sine_table_tb

`default_nettype wire
