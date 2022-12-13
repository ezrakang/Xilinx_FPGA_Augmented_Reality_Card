`timescale 1ns / 1ps
`default_nettype none

module divider #(parameter WIDTH = 14) (input wire clk_in,
                input wire rst_in,
                input wire[WIDTH-1:0] dividend_in,
                input wire[WIDTH-1:0] divisor_in,
                input wire data_valid_in,
                input wire pause,

                output logic[WIDTH-1:0] quotient_out,
                //output logic[WIDTH-1:0] remainder_out,
                output logic data_valid_out
                //output logic error_out,
                //output logic busy_out);
                );

  logic [13:0] p[13:0]; //32 stages
  logic [13:0] dividend [13:0];
  logic [13:0] divisor [13:0];
  logic data_valid [13:0];

  assign data_valid_out = data_valid[13];
  assign quotient_out = dividend[13];
  //assign remainder_out = p[8];

  always @(*) begin
    data_valid[0] = data_valid_in;
    divisor[0] = divisor_in;
    if ({13'b0,dividend_in[13]}>=divisor_in[13:0])begin
      p[0] = {13'b0,dividend_in[13]} - divisor_in[13:0];
      dividend[0] = {dividend_in[12:0],1'b1};
    end else begin
      p[0] = {13'b0,dividend_in[13]};
      dividend[0] = {dividend_in[12:0],1'b0};
    end
    for (int i=2; i<14; i=i+2)begin
      data_valid[i] = data_valid[i-1];
      if ({p[i-1][12:0],dividend[i-1][13]}>=divisor[i-1][13:0])begin
        p[i] = {p[i-1][12:0],dividend[i-1][13]} - divisor[i-1][13:0];
        dividend[i] = {dividend[i-1][12:0],1'b1};
      end else begin
        p[i] = {p[i-1][12:0],dividend[i-1][13]};
        dividend[i] = {dividend[i-1][12:0],1'b0};
      end
      divisor[i] = divisor[i-1];
    end
  end

  always_ff @(posedge clk_in)begin
   // if (rst_in) begin
   //   for (int i=0; i<9; i=i+1) begin
   //     p[i] <= 0;
   //     dividend[i] <= 0;
   //     divisor[i] <= 0;
   //     data_valid[i] <= 0;
   //   end
   // end else begin
    if (!(pause)) begin
      for (int i=1; i<14; i=i+2)begin
        data_valid[i] <= data_valid[i-1];
        if ({p[i-1][12:0],dividend[i-1][13]}>=divisor[i-1][13:0])begin
          p[i] <= {p[i-1][12:0],dividend[i-1][13]} - divisor[i-1][13:0];
          dividend[i] <= {dividend[i-1][12:0],1'b1};
        end else begin
          p[i] <= {p[i-1][12:0],dividend[i-1][13]};
          dividend[i] <= {dividend[i-1][12:0],1'b0};
        end
        divisor[i] <= divisor[i-1];
      end
    end
   end
  //end
endmodule

`default_nettype wire
