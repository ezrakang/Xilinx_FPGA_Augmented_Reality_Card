`timescale 1ns / 1ps
`default_nettype none

module scale(
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [15:0] frame_buff_in,
  output logic [15:0] cam_out
);
  //YOUR DESIGN HERE!
  logic in_image;
  always_comb begin
        in_image = (hcount_in < 640) && (vcount_in < 853);
  end

  assign cam_out = in_image? frame_buff_in: 0;
endmodule


`default_nettype wire
