`timescale 1ns / 1ps
`default_nettype none

module divider_top #(
      parameter SIZE=6,
      parameter WIDTH=9
      ) (
      input wire rst,
      input wire clk,
      input wire [WIDTH-1:0] dividend [SIZE-1:0],
      input wire [WIDTH-1:0] divisor [SIZE/2:0],
      output logic [WIDTH-1:0] quotient [SIZE-1:0]
      );

  logic valid_out [SIZE-1:0];

  generate 
    genvar i;
    genvar j;
    for (i=0; i<SIZE; i=i+1) begin
      for (j=0; j<SIZE/2; j=j+1) begin
        divider #(
          .WIDTH(WIDTH)
        ) divide (
          .clk_in(clk),
          .rst_in(rst),
          .dividend_in(dividend[i]),
          .divisor_in(divisor[j]),
          .data_valid_in(1'b1),
          .quotient_out(quotient[i]),
          .data_valid_out(valid_out[i]) 
        )
      end
    end
  endgenerate

endmodule

`default_nettype wire
