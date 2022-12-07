`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module 3d_to_2d #(
      parameter SIZE=4,
      parameter MODEL_FILE="model.mem",
      parameter ADDRW=$clog2(SIZE)
      )(
      input wire clk,
      input wire rst,
      input wire valid_in,
      input wire [29:0] camera_loc

      output logic valid_out,
      output logic [63:0] model_out);

  logic [ADDRW-1:0] addr_in;
  logic [63:0] model_in;
  
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(64),                       // Specify RAM data width
    .RAM_DEPTH(SIZE),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(MODEL_FILE))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) model_ram (
    .addra(addr_in),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(model_in)      // RAM output data, width determined from RAM_WIDTH
  );

  logic [8:0] theta_cos;
  logic [8:0] theta_sin;
  logic [7:0] cos_val;
  logic [7:0] sin_val;

  assign theta_cos = 9'd450 - camera_loc[29:21];
  assign theta_sin = camera_loc[29:21];
  
  sine_table #(
    .ROM_DEPTH(90),
    .ROM_WIDTH(8),
    .ADDRW(9)
  ) sin (
    .id(theta_sin),
    .rst(rst),
    .clk(clk),
    .data(sin_val)
  );

  sine_table #(
    .ROM_DEPTH(90),
    .ROM_WIDTH(8),
    .ADDRW(9)
  ) cos (
    .id(theta_cos),
    .rst(rst),
    .clk(clk),
    .data(cos_val)
  );

  logic signed [5:0] v1 [2:0];
  logic signed [5:0] v2 [2:0];
  logic signed [5:0] v3 [2:0];
  logic signed [6:0] camera_pos [2:0];

  always_comb begin
    v1[0] = $signed(model_in[63:58])
    v1[1] = $signed(model_in[57:52])
    v1[2] = $signed(model_in[51:46]) 
   
    v2[0] = $signed(model_in[45:40])
    v2[1] = $signed(model_in[39:34])
    v2[2] = $signed(model_in[33:28])
    
    v3[0] = $signed(model_in[27:22])
    v3[1] = $signed(model_in[21:16])
    v3[2] = $signed(model_in[15:10])

    camera_pos[0] = camera_loc[20:14];
    camera_pos[1] = camera_loc[13:7];
    camera_pos[2] = camera_loc[6:0]; 
  end

  logic signed [7:0] v1_sub [2:0];
  logic signed [7:0] v2_sub [2:0];
  logic signed [7:0] v3_sub [2:0];

  subtract (
    .v1(v1),
    .v2(v2),
    .v3(v3),
    .cam_pos(camera_pos)
    .v1_out(v1_sub),
    .v2_out(v2_sub),
    .v3_out(v3_sub)
  )
 
  

 
  always_ff @(posedge clk) begin

  end

endmodule

`default_nettype wire
