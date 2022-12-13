`timescale 1ns / 1ps
`default_nettype none

module divider_top #(
      parameter SIZE=6,
      parameter WIDTH=14
      ) (
      input wire clk,
      input wire rst,
      input wire pause,
      input wire [WIDTH-1:0] dividend [SIZE-1:0],
      input wire [WIDTH-1:0] divisor [SIZE/2-1:0],
      output logic [WIDTH-1:0] quotient [SIZE-1:0]
      );
  

  logic [WIDTH-1:0] valid_out; 
  //logic [WIDTH-1:0] remainder_out;

  generate 
    genvar i;
    for (i=0; i<SIZE; i=i+1) begin
      divider #(
        .WIDTH(WIDTH)
      ) divide (
        .clk_in(clk),
        .rst_in(rst),
        .pause(pause),
        .dividend_in(dividend[i]),
        .divisor_in(divisor[i/2]),
        .data_valid_in(1'b1),
        .quotient_out(quotient[i]),
        //.remainder_out(remainder_out[i]),
        .data_valid_out(valid_out[i]) 
      );
    end
  endgenerate

endmodule

`default_nettype wire
