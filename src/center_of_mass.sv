`timescale 1ns / 1ps
`default_nettype none

module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,

                        input wire [15:0] pixel_info,
                        output logic [15:0] pixel_through,
                         output logic [10:0] hcount_out,
                         output logic [9:0] vcount_out,

                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);

  //your design here!
  logic [9:0] y_main;
  logic [10:0] x_main;
  logic [32:0] x_total, y_total, mass;
  logic x_valid, y_valid, x_was_valid, y_was_valid, valid_in_prior;

  assign hcount_out = (valid_out)? x_in:0;
  assign vcount_out = (valid_out)? y_in:0;
  assign pixel_through = (valid_out)? pixel_info:0;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      mass <= 0;
      x_out <= 0;
      y_out <= 0;
      x_total <= 0;
      y_total <= 0;
      valid_out <= 0;
      x_was_valid <= 0;
      y_was_valid <= 0;
      valid_in_prior <= 0;
    end else begin
      if (valid_in) valid_in_prior = 1; 
      if (x_in == 0 && y_in == 0) begin
        //New Frame restarts
        x_total <= (valid_in)? x_in: 0;
        y_total <= (valid_in)? y_in: 0;
        mass <= (valid_in) ? 1 : 0;
        x_out <= 0;
        y_out <= 0;
        valid_out <= 0;
        x_was_valid <= 0;
        y_was_valid <= 0;
      end else begin
        if (x_valid) x_was_valid = 1;
        if (y_valid) y_was_valid = 1;
        valid_out <= (x_was_valid && y_was_valid) && (valid_in_prior);

        x_total <= (valid_in) ? x_in + x_total : x_total;
        y_total <= (valid_in) ? y_in + y_total : y_total;
        mass <= (valid_in) ? mass + 1 : mass;

        y_out <= (y_valid) ? y_main : y_out;
        x_out <= (x_valid) ? x_main : x_out;
      end
    end
    end

divider x_divider(.clk_in(clk_in), .rst_in(rst_in), .dividend_in(x_total), .divisor_in(mass), .data_valid_in(tabulate_in), .quotient_out(x_main), .data_valid_out(x_valid));
divider y_divider(.clk_in(clk_in), .rst_in(rst_in), .dividend_in(y_total), .divisor_in(mass), .data_valid_in(tabulate_in), .quotient_out(y_main), .data_valid_out(y_valid));

endmodule


`default_nettype wire
