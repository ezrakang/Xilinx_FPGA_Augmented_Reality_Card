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
  logic signed [15:0] vals2 [5:0];

  logic signed [15:0] vals3 [2:0];
  logic signed [20:0] shifted_vals [5:0];
  logic signed [12:0] shifted_vals1 [2:0];
  logic signed [20:0] shifted_vals2 [2:0];
  always_comb begin
    vals[0] = $signed({v1[0], 8'b0}) * $signed(~sin_val+1);
    vals[1] = $signed({v1[1], 8'b0}) * $signed(cos_val);
    vals[2] = $signed({v1[0], 8'b0}) * $signed(cos_val);
    vals[3] = $signed({v1[1], 8'b0}) * $signed(sin_val);
    vals[4] = $signed({v2[0], 8'b0}) * $signed(~sin_val+1);
    vals[5] = $signed({v2[1], 8'b0}) * $signed(cos_val);
    vals[6] = $signed({v2[0], 8'b0}) * $signed(cos_val);
    vals[7] = $signed({v2[1], 8'b0}) * $signed(sin_val);
    vals[8] = $signed({v3[0], 8'b0}) * $signed(~sin_val+1);
    vals[9] = $signed({v3[1], 8'b0}) * $signed(cos_val);
    vals[10] = $signed({v3[0], 8'b0}) * $signed(cos_val);
    vals[11] = $signed({v3[1], 8'b0}) * $signed(sin_val);

    vals2[0] = $signed($signed(vals[0][23:8]) + $signed(vals[1][23:8]));
    vals2[1] = $signed($signed(vals[2][23:8]) + $signed(vals[3][23:8]));
    vals2[2] = $signed($signed(vals[4][23:8]) + $signed(vals[5][23:8]));
    vals2[3] = $signed($signed(vals[6][23:8]) + $signed(vals[7][23:8]));
    vals2[4] = $signed($signed(vals[8][23:8]) + $signed(vals[9][23:8]));
    vals2[5] = $signed($signed(vals[10][23:8]) + $signed(vals[11][23:8]));

    //TODO round?
    //invert z
    vals3[0] = $signed(~vals2[1]+1); //v1z
    vals3[1] = $signed(~vals2[3]+1); //v2z
    vals3[2] = $signed(~vals2[5]+1); //v3z

    //multiply x and y by 32 for scaling
    shifted_vals1[0] = $signed(v1[2] <<< 3'd5); //v1y
    shifted_vals1[1] = $signed(v2[2] <<< 3'd5); //v2y
    shifted_vals1[2] = $signed(v3[2] <<< 3'd5); //v3y
    
    shifted_vals2[0] = $signed(vals2[0] <<< 3'd5); //v1x
    shifted_vals2[1] = $signed(vals2[2] <<< 3'd5); //v2x
    shifted_vals2[2] = $signed(vals2[4] <<< 3'd5); //v3x

    //v1_out[0] = $signed(shifted_vals2[0][13:0]);
    //v1_out[1] = $signed(shifted_vals1[0]);
    //v1_out[2] = $signed(vals3[0][15:8]);

    //v2_out[0] = $signed(shifted_vals2[1][13:0]);
    //v2_out[1] = $signed(shifted_vals1[1]); 
    //v2_out[2] = $signed(vals3[1][15:8]);

    //v3_out[0] = $signed(shifted_vals2[2][13:0]);
    //v3_out[1] = $signed(shifted_vals1[2]); 
    //v3_out[2] = $signed(vals3[2][15:8]);

    v1_out[0] = $signed(vals2[0][15:8]);
    v1_out[1] = $signed(v1[2]);
    v1_out[2] = $signed(vals3[0][15:8]);
    v2_out[0] = $signed(vals2[2][15:8]);
    v2_out[1] = $signed(v2[2]);
    v2_out[2] = $signed(vals3[1][15:8]);
    v3_out[0] = $signed(vals2[4][15:8]);
    v3_out[1] = $signed(v3[2]);
    v3_out[2] = $signed(vals3[2][15:8]);


  end
endmodule

`default_nettype wire
