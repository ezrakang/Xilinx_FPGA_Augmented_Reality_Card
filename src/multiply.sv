`timescale 1ns / 1ps
`default_nettype none

module multiply(
      input wire signed [7:0] v1 [2:0],
      input wire signed [7:0] v2 [2:0],
      input wire signed [7:0] v3 [2:0],
      input wire signed [15:0] sin_val,
      input wire signed [15:0] cos_val,

      output logic signed [8:0] v1_out [2:0],
      output logic signed [8:0] v2_out [2:0],
      output logic signed [8:0] v3_out [2:0]
      );

  logic signed [31:0] vals [11:0];
  logic signed [17:0] vals2 [5:0];

  always_comb begin
    vals[0] = $signed({v1[0], 8'b0}) * $signed(~sin_val+1);
    vals[1] = $signed({v1[1], 8'b0}) * $signed(~cos_val+1);
    vals[2] = $signed({v1[0], 8'b0}) * $signed(cos_val);
    vals[3] = $signed({v1[1], 8'b0}) * $signed(~sin_val+1);
    vals[4] = $signed({v2[0], 8'b0}) * $signed(~sin_val+1);
    vals[5] = $signed({v2[1], 8'b0}) * $signed(~cos_val+1);
    vals[6] = $signed({v2[0], 8'b0}) * $signed(cos_val);
    vals[7] = $signed({v2[1], 8'b0}) * $signed(~sin_val+1);
    vals[8] = $signed({v3[0], 8'b0}) * $signed(~sin_val+1);
    vals[9] = $signed({v3[1], 8'b0}) * $signed(~cos_val+1);
    vals[10] = $signed({v3[0], 8'b0}) * $signed(cos_val);
    vals[11] = $signed({v3[1], 8'b0}) * $signed(~sin_val+1);

    vals2[0] = $signed(vals[0][24:7]) + $signed(vals[1][24:7]);
    vals2[1] = $signed(vals[2][24:7]) + $signed(vals[3][24:7]);
    vals2[2] = $signed(vals[4][24:7]) + $signed(vals[5][24:7]);
    vals2[3] = $signed(vals[6][24:7]) + $signed(vals[7][24:7]);
    vals2[4] = $signed(vals[8][24:7]) + $signed(vals[9][24:7]);
    vals2[5] = $signed(vals[10][24:7]) + $signed(vals[11][24:7]);

    //TODO round?
    v1_out[0] = vals2[0][17:9];
    v1_out[1] = $signed(v1[2]);
    v1_out[2] = vals2[1][17:9];

    v2_out[0] = vals2[2][17:9];
    v2_out[1] = $signed(v2[2]);
    v2_out[2] = vals2[3][17:9];

    v3_out[0] = vals2[4][17:9];
    v3_out[1] = $signed(v3[2]);
    v3_out[2] = vals2[5][17:9];
  end
endmodule

`default_nettype wire
