`timescale 1ns / 1ps
`default_nettype none

`define V1X 54:49
`define V1Y 48:43
`define V2X 42:37
`define V2Y 36:31
`define V3X 30:25
`define V3Y 24:19
`define MAXZ 18:10

module rasterize(
      input wire clk,
      input wire rst,
      input wire valid_in,
      input wire [54:0] model_in,

      output logic busy_out,
      output logic valid,
      output logic [30:0] pixel_out);

  localparam WAITING = 0;
  localparam RASTERIZE = 1;

  assign busy_out = valid_in || state;

  //E_i where indices are {B, A}
  logic signed [6:0] E_1 [1:0];
  logic signed [6:0] E_2 [1:0];
  logic signed [6:0] E_3 [1:0];
  logic signed [11:0] E_1C, E_2C, E_3C;
  logic signed [5:0] x_1, x_2, x_3, y_1, y_2, y_3;
  logic signed [5:0] x_min, x_max, y_min, y_max;

  logic signed [13:0] area;

  always_comb begin
    x_1 = $signed(model_in[`V1X]);
    x_2 = $signed(model_in[`V2X]);
    x_3 = $signed(model_in[`V3X]);
    y_1 = $signed(model_in[`V1Y]);
    y_2 = $signed(model_in[`V2Y]);
    y_3 = $signed(model_in[`V3Y]);
            
    x_min = ($signed(x_1) > $signed(x_2)) ? ($signed(x_2) > $signed(x_3) ? $signed(x_3) : $signed(x_2)) : ($signed(x_1) > $signed(x_3) ? $signed(x_3) : $signed(x_1));
    y_min = ($signed(y_1) > $signed(y_2)) ? ($signed(y_2) > $signed(y_3) ? $signed(y_3) : $signed(y_2)) : ($signed(y_1) > $signed(y_3) ? $signed(y_3) : $signed(y_1));
    x_max = ($signed(x_1) > $signed(x_2)) ? ($signed(x_1) > $signed(x_3) ? $signed(x_1) : $signed(x_3)) : ($signed(x_2) > $signed(x_3) ? $signed(x_2) : $signed(x_3));
    y_max = ($signed(y_1) > $signed(y_2)) ? ($signed(y_1) > $signed(y_3) ? $signed(y_1) : $signed(y_3)) : ($signed(y_2) > $signed(y_3) ? $signed(y_2) : $signed(y_3));
    //e1 uses v1, v2
    E_1[0] = $signed(model_in[`V1Y]) - $signed(model_in[`V2Y]); //e1a
    E_1[1] = $signed(model_in[`V2X]) - $signed(model_in[`V1X]); //e1b
    E_1C = ($signed(model_in[`V1X]) * $signed(model_in[`V2Y])) - ($signed(model_in[`V2X]) * $signed(model_in[`V1Y]));
    //e2 uses v2, v3
    E_2[0] = $signed(model_in[`V2Y]) - $signed(model_in[`V3Y]);
    E_2[1] = $signed(model_in[`V3X]) - $signed(model_in[`V2X]);
    E_2C = ($signed(model_in[`V2X]) * $signed(model_in[`V3Y])) - ($signed(model_in[`V3X]) * $signed(model_in[`V2Y]));
    //e3 uses v3, v1
    E_3[0] = $signed(model_in[`V3Y]) - $signed(model_in[`V1Y]);
    E_3[1] = $signed(model_in[`V1X]) - $signed(model_in[`V3X]);
    E_3C = ($signed(model_in[`V3X]) * $signed(model_in[`V1Y])) - ($signed(model_in[`V1X]) * $signed(model_in[`V3Y]));

    area = $signed($signed(E_1C) + $signed(E_2C) + $signed(E_3C));
  end

  logic signed [15:0] check_1;
  logic signed [15:0] check_2;
  logic signed [15:0] check_3;
 
  always_comb begin
    check_1 = $signed(($signed(E1[0])*$signed(x_curr)) + ($signed(E1[1])*$signed(y_curr)) + $signed(E1C));
    check_2 = $signed(($signed(E2[0])*$signed(x_curr)) + ($signed(E2[1])*$signed(y_curr)) + $signed(E2C));
    check_3 = $signed(($signed(E3[0])*$signed(x_curr)) + ($signed(E3[1])*$signed(y_curr)) + $signed(E3C));
  end

  logic [5:0] x;
  logic [5:0] y;
  logic signed [5:0] y_flipped;
  always_comb begin
      y_flipped = $signed(~(y_curr)+'sd1);

      x = $signed(x_curr) + 'sd32;
      y = $signed(y_flipped) + 'sd32;
  end

  logic state;
  logic signed [6:0] E1 [1:0];
  logic signed [6:0] E2 [1:0];
  logic signed [6:0] E3 [1:0];
  logic signed [11:0] E1C, E2C, E3C;
  logic signed [5:0] x_curr, y_curr;
  logic signed [5:0] xmin, xmax, ymin, ymax;
  logic [8:0] z;
  logic [9:0] color;
 

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 0;
      valid <= 0;
      x_curr <= 0;
      y_curr <= 0;
      xmin <= 0;
      xmax <= 0;
      ymin <= 0;
      ymax <= 0;
      color <= 0;
      z <= 0;
      E1C <= 0;
      E2C <= 0;
      E3C <= 0;
      for (int i=0; i<2; i=i+1) begin
        E1[i] <= 0;
        E2[i] <= 0;
        E3[i] <= 0;
      end
    end else begin
      case (state)
        WAITING: begin
          if (valid_in) begin
            if (area == 0) begin
              //malformed triangle
              state <= WAITING;
            end else if (area < 0) begin
              E1[0] <= (~($signed(E_1[0]))) + 'sd1;
              E1[1] <= (~($signed(E_1[1]))) + 'sd1;
              E1C <= (~($signed(E_1C))) + 'sd1;
              E2[0] <= (~($signed(E_2[0]))) + 'sd1;
              E2[1] <= (~($signed(E_2[1]))) + 'sd1;
              E2C <= (~($signed(E_2C))) + 'sd1;
              E3[0] <= (~($signed(E_3[0]))) + 'sd1;
              E3[1] <= (~($signed(E_3[1]))) + 'sd1;
              E3C <= (~($signed(E_3C))) + 'sd1;
              state <= RASTERIZE;
            end else begin
              E1[0] <= E_1[0];
              E1[1] <= E_1[1];
              E1C <= E_1C;
              E2[0] <= E_2[0];
              E2[1] <= E_2[1];
              E2C <= E_2C;
              E3[0] <= E_3[0];
              E3[1] <= E_3[1];
              E3C <= E_3C;
              state <= RASTERIZE;
            end
            x_curr <= x_min;
            y_curr <= y_min;
            xmin <= x_min;
            xmax <= x_max;
            ymin <= y_min;
            ymax <= y_max;
            z <= model_in[`MAXZ];
            color <= model_in[9:0];
          end
          valid <= 0;
        end
        RASTERIZE: begin
          if (check_1 >= 0 && check_2 >= 0 && check_3 >= 0) begin
            valid <= 1;
            pixel_out <= {x, y, z, color};
          end else begin
            valid <= 0;
          end
          if (x_curr == xmax && y_curr == ymax) begin
            state <= WAITING;
          end else if (x_curr == xmax) begin
            x_curr <= xmin;
            y_curr <= $signed(y_curr) + 'sd1;
          end else begin
            x_curr <= $signed(x_curr) + 'sd1;
          end
        end
        default: begin
          state <= WAITING;
        end
      endcase
    end
  end
endmodule

`default_nettype wire
