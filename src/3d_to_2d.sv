`timescale 1ns / 1ps
`default_nettype none

`define V1 63:46
`define V2 45:36
`define V3 25:7

`define Z 0:6
`define Y 7:12
`define X 13:18
`define theta 19:27

module 3d_to_2d(
      input wire clk,
      input wire rst,
      input wire valid_in,
      input wire [63:0] model_in,
      input wire [27:0] camera_loc,

      output logic valid,
      output logic model_out);

  logic [17:0] v1;
  logic [17:0] v2;
  logic [17:0] v3;

  logic [7:0] addr;
  logic signed [15:0] sine_out;

  sine_table #(
    .ROM_DEPTH(64),
    .ROM_WIDTH(8),
    .ADDRW(8)
  ) sine_lookup (
    .id(addr),
    .rst(rst),
    .clk(clk),
    .data(sine_out)
  )

 
  always_comb begin

  end



endmodule


`default_nettype wire
