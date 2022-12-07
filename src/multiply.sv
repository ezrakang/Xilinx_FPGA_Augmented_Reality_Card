`timescale 1ns / 1ps
`default_nettype none

module multiply(
      input signed wire [7:0] v1 [2:0],
      input signed wire [7:0] v2 [2:0],
      input signed wire [7:0] v3 [2:0],
      input signed wire [15:0] sin_val,
      input signed wire [15:0] cos_val,

      output signed logic [8:0] v1_out [2:0],
      output signed logic [8:0] v2_out [2:0],
      output signed logic [8:0] v3_out [2:0]
      )

  output signed logic [16:0] vals [11:0]

  always_comb begin
    vals[0] = $signed({v1[0], 8'b0}) * $signed(~sin_val+1);
    vals[1] = $signed({v1[1], 8'b0}) * $signed(cos_val);
    vals[2] = $signed({v1[0], 8'b0}) * $signed(~cos_val+1);
    vals[3] = $signed({v1[1], 8'b0}) * $signed(~sin_val+1);
    vals[4] = $signed({v2[0], 8'b0}) * $signed(~sin_val+1);
    vals[5] = $signed({v2[1], 8'b0}) * $signed(cos_val);
    vals[6] = $signed({v2[0], 8'b0}) * $signed(~cos_val+1);
    vals[7] = $signed({v2[1], 8'b0}) * $signed(~sin_val+1);
    vals[8] = $signed({v3[0], 8'b0}) * $signed(~sin_val+1);
    vals[9] = $signed({v3[1], 8'b0}) * $signed(cos_val);
    vals[10] = $signed({v3[0], 8'b0}) * $signed(~cos_val+1);
    vals[11] = $signed({v3[1], 8'b0}) * $signed(~sin_val+1);

    v1_out[0] = $signed(vals[0]) + $signed(vals[1]);
    v1_out[1] = $signed(v1[2]);
    v1_out[2] = $signed(vals[2]) + $signed(vals[3]);

    v2_out[0] = $signed(vals[4]) + $signed(vals[5]);
    v2_out[1] = $signed(v2[2]);
    v2_out[2] = $signed(vals[6]) + $signed(vals[7]);

    v3_out[0] = $signed(vals[8]) + $signed(vals[9]);
    v3_out[1] = $signed(v3[2]);
    v3_out[2] = $signed(vals[10]) + $signed(vals[11]);
  end
endmodule

`default_nettype wire
