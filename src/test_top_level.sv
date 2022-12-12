`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire btnc, //reset
  input wire btnu,
  
  input wire [7:0] ja, //lower 8 bits from camera
  input wire [2:0] jb, //upper 3 bits from camera

  output logic jbclk,
  output logic jblock,

  output logic [15:0] led,
  output logic [7:0] an,
  output logic caa,cab,cac,cad,cae,caf,cag,

  output logic [3:0] vga_r, vga_g, vga_b
  );

  logic sys_rst;
  assign sys_rst = btnc;

  logic clk_65mhz;

  clk_wiz_lab3 clk_gen(
    .clk_in1(clk_100mhz),
    .clk_out1(clk_65mhz)); //after frame buffer everything on clk_65mhz

  logic up;
  debouncer db1 (
        .rst_in(btnc),
        .clk_in(clk_65mhz),
        .dirty_in(btnu),
        .clean_out(up)
        );


  //testing multiply on hardware
  /*
  logic signed [7:0] v1 [2:0];
  logic signed [7:0] v2 [2:0];
  logic signed [7:0] v3 [2:0];
  logic signed [15:0] sin_val;
  logic signed [15:0] cos_val;
  logic signed [8:0] v1_out [2:0];
  logic signed [8:0] v2_out [2:0];
  logic signed [8:0] v3_out [2:0];
  logic [8:0] display;
  always_comb begin
    v1[0] = -8'sd3;
    v1[1] = -8'sd3;
    v1[2] = -8'sd1;
    v2[0] = -8'sd3;
    v2[1] = 8'sd1;
    v2[2] = -8'sd1;
    v3[0] = -8'sd3;
    v3[1] = -8'sd1;
    v3[2] = 8'sd1;
    

    sin_val = 16'sb0000_0000_1011_0101;
    cos_val = 16'sb1111_1111_0100_1011;
   
    case (control)
      0: display = v1_out[0]; 
      1: display = v1_out[1]; 
      2: display = v1_out[2]; 
      3: display = v2_out[0]; 
      4: display = v2_out[1]; 
      5: display = v2_out[2]; 
      6: display = v3_out[0]; 
      7: display = v3_out[1]; 
      8: display = v3_out[2]; 
      default: display = 0; 
    endcase
  end
 
  multiply mul (
          .v1(v1),
          .v2(v2),
          .v3(v3),
          .sin_val(sin_val),
          .cos_val(cos_val),
          .v1_out(v1_out),
          .v2_out(v2_out),
          .v3_out(v3_out)
  );
  

  //controlling what number to display
  logic [3:0] control;
  logic prev_press;
  always_ff @(posedge clk_65mhz) begin
    prev_press <= up;
    if (up && !(prev_press)) begin
      if (control > 8) begin
        control <= 0;
      end else begin
        control <= control+1;
      end
    end
  end
  */
  

  //testing divide_top
  /*
  logic [8:0] dividend [5:0];
  logic [8:0] divisor [2:0];
  logic [8:0] quotient [5:0];

  logic [8:0] display;
  logic [3:0] control;
  always_comb begin
    dividend[0] = 9'd20;
    dividend[1] = 9'd20;
    dividend[2] = 9'd17;
    dividend[3] = 9'd17;
    dividend[4] = 9'd1;
    dividend[5] = 9'd1;
  
    divisor[0] = 9'd5;
    divisor[1] = 9'd2;
    divisor[2] = 9'd1;

    case (control)
      0: display = quotient[0];
      1: display = quotient[1];
      2: display = quotient[2];
      3: display = quotient[3];
      4: display = quotient[4];
      5: display = quotient[5];
      default: display = 0; 
    endcase
  end

  divider_top #(
    .SIZE(6),
    .WIDTH(9)
  ) divide (
    .clk(clk_65mhz),
    .rst(btnc),
    .dividend(dividend),
    .divisor(divisor),
    .quotient(quotient)
  );
  */

  //individual divider test
  /*
  logic [8:0] divid;
  logic [8:0] divis; 
  logic [8:0] remain;
  assign divid = 9'd20;
  assign divis = 9'd5;

  logic valid_out;

  divider #(
      .WIDTH(9)
    ) d (
    .clk_in(clk_65mhz),
    .rst_in(btnc),
    .dividend_in(divid),
    .divisor_in(divis),
    .data_valid_in(1'b1),
    .quotient_out(quo),
    .remainder_out(remain),
    .data_valid_out(valid_out)
    );
  */

  //testing subtract
  /*
  logic signed [5:0] v1 [2:0];
  logic signed [5:0] v2 [2:0];
  logic signed [5:0] v3 [2:0];
  logic signed [6:0] cam_pos [2:0];
  logic signed [7:0] v1_out [2:0];
  logic signed [7:0] v2_out [2:0];
  logic signed [7:0] v3_out [2:0];

  logic [3:0] control;
  logic [7:0] display;
  always_comb begin
    v1[0] = 6'sd9;
    v2[1] = -6'sd30;
    v3[2] = 6'sd15;

    cam_pos[0] = 7'sd15;
    cam_pos[1] = -7'sd4;
    cam_pos[2] = 7'sd6;
 
    case (control)
      0: display = v1_out[0]; 
      1: display = v1_out[1]; 
      2: display = v1_out[2]; 
      3: display = v2_out[0]; 
      4: display = v2_out[1]; 
      5: display = v2_out[2]; 
      6: display = v3_out[0]; 
      7: display = v3_out[1]; 
      8: display = v3_out[2]; 
      default: display = 0; 
    endcase
  end

  subtract sub(
    .v1(v1),
    .v2(v2),
    .v3(v3),
    .cam_pos(cam_pos),
    .v1_out(v1_out),
    .v2_out(v2_out),
    .v3_out(v3_out)
    );
  */

  //testing 3d_to_2d
  logic [29:0] camera_loc;
  logic valid_in;
  logic valid_out;
  logic [54:0] model_out;

  logic [27:0] display;
  logic [3:0] control;
  always_comb begin
    camera_loc = 30'b000101101000001100000110000001;
    valid_in = 1;

    case (control)
      0: display = model_out[27:0];
      1: display = {1'b0, model_out[54:28]};
      default: display = 28'd42;
    endcase
  end

  a3d_to_2d #(
      .SIZE(1),
      .MODEL_FILE("basic_model.mem"),
      .ADDRW(1)
  ) a3d_to_2d (
      .clk(clk_65mhz),
      .rst(btnc),
      .valid_in(valid_in),
      .camera_loc(camera_loc),
      .valid_out(valid_out),
      .model_out(model_out)
  );
  

  logic prev_press;
  always_ff @(posedge clk_65mhz) begin
    prev_press <= up;
    if (up && !(prev_press)) begin
      if (control > 0) begin
        control <= 0;
      end else begin
        control <= control+1;
      end
    end
  end

  //seven segment controller
  seven_segment_controller ssc(.clk_in(clk_65mhz),
               .rst_in(btnc),
               .val_in({control, display}),
               .cat_out({cag, caf, cae, cad, cac, cab, caa}),
               .an_out(an));


endmodule


`default_nettype wire
