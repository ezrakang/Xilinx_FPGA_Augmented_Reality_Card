`timescale 1ns / 1ps
`default_nettype none

module multiply(
      input wire signed [7:0] v1 [2:0],
      input wire signed [7:0] v2 [2:0],
      input wire signed [7:0] v3 [2:0],
      input wire signed [15:0] sin_val,
      input wire signed [15:0] cos_val,

      output logic signed [13:0] v1_out [2:0],
      output logic signed [13:0] v2_out [2:0],
      output logic signed [13:0] v3_out [2:0]
      );

  logic signed [31:0] vals [11:0];
  logic signed [16:0] vals2 [5:0];

  logic signed [16:0] vals3 [5:0];
  logic signed [21:0] shifted_vals [5:0];
  always_comb begin
    vals[2] = $signed({v1[0], 8'b0}) * $signed(sin_val);
    vals[3] = $signed({v1[1], 8'b0}) * $signed(cos_val);
    vals[0] = $signed({v1[0], 8'b0}) * $signed(cos_val);
    vals[1] = $signed({v1[1], 8'b0}) * $signed(~sin_val+1);
    vals[6] = $signed({v2[0], 8'b0}) * $signed(sin_val);
    vals[7] = $signed({v2[1], 8'b0}) * $signed(cos_val);
    vals[4] = $signed({v2[0], 8'b0}) * $signed(cos_val);
    vals[5] = $signed({v2[1], 8'b0}) * $signed(~sin_val+1);
    vals[10] = $signed({v3[0], 8'b0}) * $signed(sin_val);
    vals[11] = $signed({v3[1], 8'b0}) * $signed(cos_val);
    vals[8] = $signed({v3[0], 8'b0}) * $signed(cos_val);
    vals[9] = $signed({v3[1], 8'b0}) * $signed(~sin_val+1);

    vals2[0] = $signed(vals[0][23:8]) + $signed(vals[1][23:8]);
    vals2[1] = $signed(vals[2][23:8]) + $signed(vals[3][23:8]);
    vals2[2] = $signed(vals[4][23:8]) + $signed(vals[5][23:8]);
    vals2[3] = $signed(vals[6][23:8]) + $signed(vals[7][23:8]);
    vals2[4] = $signed(vals[8][23:8]) + $signed(vals[9][23:8]);
    vals2[5] = $signed(vals[10][23:8]) + $signed(vals[11][23:8]);

    //TODO round?
    vals3[0] = vals2[1][16] ? ~vals2[0]+1 : vals2[0];
    vals3[1] = vals2[1][16] ? ~vals2[1]+1 : vals2[1];
    vals3[2] = vals2[3][16] ? ~vals2[2]+1 : vals2[2];
    vals3[3] = vals2[3][16] ? ~vals2[3]+1 : vals2[3];
    vals3[4] = vals2[5][16] ? ~vals2[4]+1 : vals2[4];
    vals3[5] = vals2[5][16] ? ~vals2[5]+1 : vals2[5];

    //multiply x and y by 32 for scaling
    shifted_vals[0] <= vals3[0] <<< 5;
    shifted_vals[1] <= v1[2] <<< 5;
    shifted_vals[2] <= vals3[2] <<< 5;
    shifted_vals[3] <= v2[2] <<< 5;
    shifted_vals[4] <= vals3[4] <<< 5;
    shifted_vals[5] <= v3[2] <<< 5;


    v1_out[0] = shifted_vals[0][21:8];
    v1_out[1] = shifted_vals[1][21:8];
    v1_out[2] = vals3[1];

    v2_out[0] = shifted_vals[2][21:8];
    v2_out[1] = shifted_vals[3][21:8]; 
    v2_out[2] = vals3[3];

    v3_out[0] = shifted_vals[4][21:8];
    v3_out[1] = shifted_vals[5][21:8]; 
    v3_out[2] = vals3[5];
  end
endmodule

`default_nettype wire
