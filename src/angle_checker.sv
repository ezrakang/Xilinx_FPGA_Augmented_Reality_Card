`timescale 1ns / 1ps
`default_nettype none

module angle_checker (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire [10:0] x_com,
                         input wire [9:0] y_com,
                         //input wire [3:0] r_in,
                         //input wire [3:0] g_in,
                         //input wire [3:0] b_in,
                         input wire valid_in,
                         output logic [8:0] angle,
                         output logic valid_out,
                         output logic [3:0] tens_output,
                         output logic [1:0] hundreds_output);

  //your design here!
  logic [9:0] y_angle_com;
  logic [20:0] y_corr, x_corr;
  logic [10:0] x_angle_com;
  logic [32:0] main_ratio;
  logic valid_in_prior, x_dir, y_dir, valid_ratio, zero, loading, new_com, init;


  assign zero = (y_corr > 57 * x_corr)? 1:0;

    always_ff @(posedge clk_in) begin
    if (rst_in) begin
        y_corr <= 0;
        x_corr <= 0;
        valid_in_prior <= 0;
        x_dir <= 0;
        y_dir <= 0;
      
    end else begin
        if (valid_in) begin
            x_corr <= (x_in > x_com)? x_in - x_com: x_com - x_in;
            y_corr <= (y_in > y_com)? (y_in - y_com)*10: (y_com - y_in)*10;
            x_dir <= (x_in >= x_com)? 0:1;
            y_dir <= (y_in >= y_com)? 1:0;
           
            end 
        end 
           
                if (y_corr > 0 || x_corr > 0) begin
                    valid_in_prior <= (y_corr > 57 * x_corr)? 0:1;
                end else valid_in_prior <= 0;
           
            
        end

  //end

divider ratio_find(.clk_in(clk_in), .rst_in(rst_in), .dividend_in({1'b0, y_corr}), .divisor_in(x_corr), .data_valid_in(valid_in_prior), .quotient_out(main_ratio), .data_valid_out(valid_ratio));


logic [3:0] tens_o;
logic [1:0] hundreds_o;

always_comb begin
    if (main_ratio <= 2) angle_n = 80;
    else if (main_ratio > 2 && main_ratio <= 4) angle_n = 70;
    else if (main_ratio > 4 && main_ratio <= 6) angle_n = 60;
    else if (main_ratio > 6 && main_ratio <= 9) angle_n = 50;
    else if (main_ratio > 9 && main_ratio <= 12) angle_n = 40;
    else if (main_ratio > 12 && main_ratio <= 18) angle_n = 30;
    else if (main_ratio > 18 && main_ratio <= 28) angle_n = 20;
    else if (main_ratio > 28 && main_ratio <= 57) angle_n = 10;
    else if (zero) angle_n = 0;
    else angle_n = 0;
end

logic [8:0] angle_n;

always_comb begin
    if (zero || valid_ratio) begin
        if (x_dir && y_dir) angle = 180 + angle_n;
        else if (~x_dir && y_dir) angle = 180 - angle_n;
        else if (x_dir && ~y_dir) angle = 360 - angle_n;
        else if (~x_dir && ~y_dir) angle = angle_n;
        else angle = angle_n;
        valid_out = 1;
    end else begin
        valid_out = 0;
    end
end

logic [12:0] testy;
always_comb begin
    if (angle >= 100 && angle <= 200) hundreds_output = 1;
    else if (angle > 200 && angle <= 300) hundreds_output = 2;
    else if (angle > 300) hundreds_output = 3;
    else hundreds_output = 0;

    testy = angle - hundreds_output*100;
    
    case(testy)
        0: tens_output = 0;
        10: tens_output = 1;
        20: tens_output = 2;
        30: tens_output = 3;
        40: tens_output = 4;
        50: tens_output = 5;
        60: tens_output = 6;
        70: tens_output = 7;
        80: tens_output = 8;
        90: tens_output = 9;
        default: tens_output = 0;
    endcase
end
 
endmodule


`default_nettype wire
