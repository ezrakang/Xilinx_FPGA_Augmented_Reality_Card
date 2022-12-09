`timescale 1ns / 1ps
`default_nettype none

module subtract(
      input wire signed [5:0] v1 [2:0],
      input wire signed [5:0] v2 [2:0],
      input wire signed [5:0] v3 [2:0],
      input wire signed [6:0] cam_pos [2:0],

      output logic signed [7:0] v1_out [2:0],
      output logic signed [7:0] v2_out [2:0],
      output logic signed [7:0] v3_out [2:0]
      );

  always_comb begin
    for (int i=0; i<3; i=i+1) begin
      v1_out[i] = $signed(v1[i]) - $signed(cam_pos[i]);
      v2_out[i] = $signed(v2[i]) - $signed(cam_pos[i]);
      v3_out[i] = $signed(v3[i]) - $signed(cam_pos[i]);
    end
  end
endmodule

`default_nettype wire
