`timescale 1ns / 1ps
`default_nettype none

module address_picker(
  input wire clk_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  output logic [16:0] pixel_addr_out);
  
  logic [10:0] hcount_pip;
  logic [9:0] vcount_pip;
  always_ff @(posedge clk_in) begin
    vcount_pip <= vcount_in;
    hcount_pip <= hcount_in;
    pixel_addr_out <= ((hcount_pip>>3) + (hcount_pip>>2)) + 240*((vcount_pip>>3) + (vcount_pip>>2));
  end

endmodule

`default_nettype none
