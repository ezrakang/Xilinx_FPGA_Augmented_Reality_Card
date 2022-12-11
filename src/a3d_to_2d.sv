`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module a3d_to_2d #(
      parameter SIZE=4,
      parameter MODEL_FILE="model.mem",
      parameter ADDRW=$clog2(SIZE)
      )(
      input wire clk,
      input wire rst,
      input wire valid_in,
      input wire [29:0] camera_loc,

      output logic valid_out,
      output logic [54:0] model_out);

  logic [ADDRW-1:0] addr_in;
  logic [63:0] model_in;
  
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(64),                       // Specify RAM data width
    .RAM_DEPTH(SIZE),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(MODEL_FILE)          // Specify name/location of RAM initialization file if using one (leave blank if not)
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
  logic signed [15:0] cos_val;
  logic signed [15:0] sin_val;

  assign theta_cos = 9'd360 - camera_loc[29:21];
  assign theta_sin = 9'd90 + camera_loc[29:21];
  
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
    v1[0] = $signed(model_in[63:58]);
    v1[1] = $signed(model_in[57:52]);
    v1[2] = $signed(model_in[51:46]);
   
    v2[0] = $signed(model_in[45:40]);
    v2[1] = $signed(model_in[39:34]);
    v2[2] = $signed(model_in[33:28]);
    
    v3[0] = $signed(model_in[27:22]);
    v3[1] = $signed(model_in[21:16]);
    v3[2] = $signed(model_in[15:10]);

    camera_pos[0] = $signed(camera_loc[20:14]);
    camera_pos[1] = $signed(camera_loc[13:7]);
    camera_pos[2] = $signed(camera_loc[6:0]); 
  end

  logic signed [7:0] v1_sub [2:0];
  logic signed [7:0] v2_sub [2:0];
  logic signed [7:0] v3_sub [2:0];

  subtract sub (
    .v1(v1),
    .v2(v2),
    .v3(v3),
    .cam_pos(camera_pos_pipe[2]),
    .v1_out(v1_sub),
    .v2_out(v2_sub),
    .v3_out(v3_sub)
  );
 
  logic signed [8:0] v1_mul [2:0];
  logic signed [8:0] v2_mul [2:0];
  logic signed [8:0] v3_mul [2:0];

  multiply mul (
    .v1(v1_sub_pipe),
    .v2(v2_sub_pipe),
    .v3(v3_sub_pipe),
    .sin_val(sin_pipe[1]),
    .cos_val(cos_pipe[1]),
    .v1_out(v1_mul),
    .v2_out(v2_mul),
    .v3_out(v3_mul)
  );

  logic [8:0] x_y [5:0];
  logic [8:0] z [2:0];
  logic [8:0] z_max;
  logic [5:0] negate;

  always_comb begin
    x_y[0] = (v1_mul_pipe[0][8]) ? (~v1_mul_pipe[0]+1) : v1_mul_pipe[0];
    x_y[1] = (v1_mul_pipe[1][8]) ? (~v1_mul_pipe[1]+1) : v1_mul_pipe[1];
    x_y[2] = (v2_mul_pipe[0][8]) ? (~v2_mul_pipe[0]+1) : v2_mul_pipe[0];
    x_y[3] = (v2_mul_pipe[1][8]) ? (~v2_mul_pipe[1]+1) : v2_mul_pipe[1];
    x_y[4] = (v3_mul_pipe[0][8]) ? (~v3_mul_pipe[0]+1) : v3_mul_pipe[0];
    x_y[5] = (v3_mul_pipe[1][8]) ? (~v3_mul_pipe[1]+1) : v3_mul_pipe[1];

    z[0] = (v1_mul_pipe[2] < 1) ? 1: v1_mul_pipe[2];
    z[1] = (v2_mul_pipe[2] < 1) ? 1: v2_mul_pipe[2];
    z[2] = (v3_mul_pipe[2] < 1) ? 1: v3_mul_pipe[2];

    //negate = {v1x, v1y, v2x, v2y, v3x, v3y}
    negate = {v1_mul_pipe[0][8], v1_mul_pipe[1][8], v2_mul_pipe[0][8], v2_mul_pipe[1][8],
              v3_mul_pipe[0][8], v3_mul_pipe[1][8]};

    z_max = (z[0] > z[1]) ? ((z[0] > z[2]) ? z[0] : z[2]) : ((z[1] > z[2]) ? z[1] : z[2]);

  end

  logic [8:0] divide_out [5:0];
 
  divider_top #(
    .SIZE(6),
    .WIDTH(9)
  ) divider (
    .clk(clk),
    .rst(rst),
    .dividend(x_y),
    .divisor(z),
    .quotient(divide_out)
  );

  logic [8:0] negate_divide [5:0];
  always_comb begin
    negate_divide[0] = ~(divide_out[0])+1;
    negate_divide[1] = ~(divide_out[1])+1;
    negate_divide[2] = ~(divide_out[2])+1;
    negate_divide[3] = ~(divide_out[3])+1;
    negate_divide[4] = ~(divide_out[4])+1;
    negate_divide[5] = ~(divide_out[5])+1;
  end



  logic valid_pipe [6:0];
  logic signed [6:0] camera_pos_pipe [2:0][2:0];
  logic [9:0] color [4:0];
  logic signed [15:0] sin_pipe [1:0];
  logic signed [15:0] cos_pipe [1:0];
  logic signed [7:0] v1_sub_pipe [2:0];
  logic signed [7:0] v2_sub_pipe [2:0];
  logic signed [7:0] v3_sub_pipe [2:0];
  logic signed [8:0] v1_mul_pipe [2:0];
  logic signed [8:0] v2_mul_pipe [2:0];
  logic signed [8:0] v3_mul_pipe [2:0];
  logic [8:0] z_max_pipe [2:0];
  logic [5:0] negate_pipe [2:0];
 
  always_ff @(posedge clk) begin
    if (rst) begin
      for(int i=0; i<3; i=i+1) begin
        camera_pos_pipe[i][0] <= 0;
        camera_pos_pipe[i][1] <= 0;
        camera_pos_pipe[i][2] <= 0;

        v1_sub_pipe[i] <= 0;
        v2_sub_pipe[i] <= 0;
        v3_sub_pipe[i] <= 0;
        v1_mul_pipe[i] <= 0;
        v2_mul_pipe[i] <= 0;
        v3_mul_pipe[i] <= 0;
        z_max_pipe[i] <= 0;
        negate_pipe[i] <= 0;
      end
      for (int i=0; i<7; i=i+1) begin
        valid_pipe[i] <= 0;
      end
      for (int i=0; i<5; i=i+1) begin
        color[i] <= 0;
      end
      sin_pipe[0] <= 0;
      sin_pipe[1] <= 0;
      cos_pipe[0] <= 0;
      cos_pipe[1] <= 0;
    end else begin
      //TODO add rasterize busy_out to pause pipelines
      
      if (valid_in) begin
        if (addr_in < SIZE-1) begin
          addr_in <= addr_in+1;
        end else begin
          addr_in <= 0;
        end
      end

      //pipeline valid
      valid_pipe[0] <= valid_in; 
      for (int i=1; i<7; i=i+1) begin
        valid_pipe[i] <= valid_pipe[i-1];
      end

      //pipeline camera_pos
      camera_pos_pipe[0][0] <= camera_pos[0];
      camera_pos_pipe[0][1] <= camera_pos[1];
      camera_pos_pipe[0][2] <= camera_pos[2];

      for (int i=0; i<3; i=i+1) begin
        camera_pos_pipe[1][i] <= camera_pos_pipe[0][i];
        camera_pos_pipe[2][i] <= camera_pos_pipe[1][i];
      end

      //pipeline model color
      color[0] <= model_in[9:0];
      for (int i=1; i<5; i=i+1) begin
        color[i] <= color[i-1];
      end

      //pipeline sin and cos vals
      sin_pipe[0] <= sin_val;
      sin_pipe[1] <= sin_pipe[0];
      cos_pipe[0] <= cos_val;
      cos_pipe[1] <= cos_pipe[0];

      //pipeline sub stage
      for (int i=0; i<3; i=i+1) begin
        v1_sub_pipe[i] <= v1_sub[i];
        v2_sub_pipe[i] <= v2_sub[i];
        v3_sub_pipe[i] <= v3_sub[i];

      //pipeline mul stage
        v1_mul_pipe[i] <= v1_mul[i];
        v2_mul_pipe[i] <= v2_mul[i];
        v3_mul_pipe[i] <= v3_mul[i];
      end 
      
      //pipeline negate pipe
      negate_pipe[0] <= negate;
      negate_pipe[1] <= negate_pipe[0];
      negate_pipe[2] <= negate_pipe[1];

      //pipeline z_max
      z_max_pipe[0] <= z_max;
      z_max_pipe[1] <= z_max_pipe[0];
      z_max_pipe[2] <= z_max_pipe[1];
    
      valid_out <= valid_pipe[6];
      
      //build model out
      //model_out[8:0] <= v2_mul_pipe[0];
      //model_out[17:9] <= v2_mul_pipe[1];
      //model_out[26:18] <= v2_mul_pipe[2];
      model_out[9:0] <= color[4];
      model_out[18:10] <= z_max_pipe[2];
      model_out[54:49] <= negate_pipe[2][5] ? negate_divide[0][5:0] : divide_out[0][5:0]; //v1x
      model_out[48:43] <= negate_pipe[2][4] ? negate_divide[1][5:0] : divide_out[1][5:0]; //v1y 
      model_out[43:37] <= negate_pipe[2][3] ? negate_divide[2][5:0] : divide_out[2][5:0]; //v2x
      model_out[36:31] <= negate_pipe[2][2] ? negate_divide[3][5:0] : divide_out[3][5:0]; //v2y
      model_out[30:25] <= negate_pipe[2][1] ? negate_divide[4][5:0] : divide_out[4][5:0]; //v3x
      model_out[24:19] <= negate_pipe[2][0] ? negate_divide[5][5:0] : divide_out[5][5:0]; //v3y

    end
  end

endmodule

`default_nettype wire
