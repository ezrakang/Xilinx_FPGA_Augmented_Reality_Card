`timescale 1ns / 1ps
`default_nettype none

`define V1 63:46
`define V2 45:36
`define V3 25:7

`define CZ 0:6
`define CY 7:12
`define CX 13:18
`define theta 19:27

module 3d_to_2d(
      input wire clk,
      input wire rst,
      input wire valid_in,
      input wire [63:0] model_in,
      input wire [27:0] camera_loc,

      output logic valid,
      output logic [63:0] model_out);

  localparam WAIT = 0;
  localparam MULTIPLY = 1;
  localparam DIVIDE = 2;

  logic [1:0] state;
  //v[0] = x, y, z
  logic signed [5:0] v1 [2:0];
  logic signed [5:0] v2 [2:0];
  logic signed [5:0] v3 [2:0];

  logic [7:0] sin_theta;
  logic [7:0] cos_theta;
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

  divider5 #(
    .WIDTH(32)
  ) divider (
    .clk_in(clk),
    .rst_in(rst),
    .dividend_in(dividend),
    .divisor_in(divisor_in),
    .data_valid_in((divide_valid),
    .quotient_out(quotient),
    .remainder_out(remainder),
    .data_valid_out(div_valid_out),
    .error_out(error),
    .busy_out(0)
  )

  always_comb begin
    //get x,y,z relative to camera for each vertex
    v1[0] = $signed(model_in[63:58]) - $signed(camera_loc[`CX]);
    v1[1] = $signed(model_in[57:52]) - $signed(camera_loc[`CY]);
    v1[2] = $signed(model_in[51:46] - $signed(camera_loc[`CZ]);
   
    v2[0] = $signed(model_in[45:40]) - $signed(camera_loc[`CX]);
    v2[1] = $signed(model_in[39:34]) - $signed(camera_loc[`CY]);
    v2[2] = $signed(model_in[33:28] - $signed(camera_loc[`CZ]);
    
    v3[0] = $signed(model_in[27:22]) - $signed(camera_loc[`CX]);
    v3[1] = $signed(model_in[21:16]) - $signed(camera_loc[`CY]);
    v3[2] = $signed(model_in[15:10] - $signed(camera_loc[`CZ]);

    //get the thetas
    sin_theta = camera_loc[27:19];
    cos_theta = 9'd450 - camera_loc[27:19];
  end

  logic [1:0] hold;
  logic signed [15:0] sin_value;
  logic signed [15:0] cos_value;

  logic signed [7:0] v1_mul [2:0];
  logic signed [7:0] v2_mul [2:0];
  logic signed [7:0] v3_mul [2:0];

  always_ff @(posedge clk) begin
    if (rst) begin
      hold <= 0;
      addr <= 0;
      sine_out <= 0;
      state <= WAIT;
      sin_value <= 0;
      cos_value <= 0;
      v1_mul <= 0;
      v2_mul <= 0;
      v3_mul <= 0;
    end else begin
      case (state)
        WAIT: begin
          if (valid_in) begin
            addr <= sin_theta;
            state <= MULTIPLY;
            hold <= 3;
          end
        end
        MULTIPLY: begin
          if (hold > 0) begin
            addr <= (hold == 3) ? cos_theta : 0;
            sin_value <= (hold == 2) ? sine_out : 0;
            cos_value <= (hold == 1) ? sine_out : 0;
            hold <= hold-1;
          end else begin
            v1_mul[0] <= (($signed({8'($signed(v1[0])), 8'b0}) * $signed((~sin_value + 1))) + ($signed({8'($signed(v1[1])), 8'b0}) * $signed(cos_value)))[15:8];
            v1_mul[1] <= $signed(v1[2]); 
            v1_mul[2] <= (($signed({8'($signed(v1[0])), 8'b0}) * $signed((~cos_value + 1))) + ($signed({8'($signed(v1[1])), 8'b0}) * $signed((~sin_value + 1))))[15:8];
            
            v2_mul[0] <= (($signed({8'($signed(v2[0])), 8'b0}) * $signed((~sin_value + 1))) + ($signed({8'($signed(v2[1])), 8'b0}) * $signed(cos_value)))[15:8];
            v2_mul[1] <= $signed(v2[2]); 
            v2_mul[2] <= (($signed({8'($signed(v2[0])), 8'b0}) * $signed((~cos_value + 1))) + ($signed({8'($signed(v2[1])), 8'b0}) * $signed((~sin_value + 1))))[15:8];

            v3_mul[0] <= (($signed({8'($signed(v3[0])), 8'b0}) * $signed((~sin_value + 1))) + ($signed({8'($signed(v3[1])), 8'b0}) * $signed(cos_value)))[15:8];
            v3_mul[1] <= $signed(v3[2]); 
            v3_mul[2] <= (($signed({8'($signed(v3[0])), 8'b0}) * $signed((~cos_value + 1))) + ($signed({8'($signed(v3[1])), 8'b0}) * $signed((~sin_value + 1))))[15:8];

            state <= DIVIDE;
          end
        end
        DIVIDE: begin
          
        end
        default:
          state <= WAITING;
        end
    end    


  end



endmodule


`default_nettype wire
