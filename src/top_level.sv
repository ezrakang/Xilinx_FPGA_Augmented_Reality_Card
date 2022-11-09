`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire btnc, //reset
  
  input wire [7:0] ja, //lower 8 bits from camera
  input wire [2:0] jb, //upper 3 bits from camera

  output logic jbclk,
  output logic jblock,

  output logic [3:0] vga_r, vga_g, vga_b

  );

  logic sys_rst;
  assign sys_rst = btnc;

  logic clk_65mhz;

  clk_wiz_lab3 clk_gen(
    .clk_in1(clk_100mhz),
    .clk_out1(clk_65mhz)); //after frame buffer everything on clk_65mhz





endmodule


`default_nettype wire
