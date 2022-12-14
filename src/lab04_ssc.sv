`timescale 1ns / 1ps
`default_nettype none

module lab04_ssc #(parameter COUNT_TO = 100000)
                                (   input wire         clk_in,
                                    input wire         rst_in,
                                    input wire [3:0]  val_in_tens,
                                    input wire [1:0]  val_in_huns,
                                    output logic[6:0]   cat_out,
                                    output logic[7:0]   an_out
                                 );

  logic[7:0]      segment_state;
  logic[31:0]     segment_counter;
  logic [6:0]     led_out;

  logic [6:0] symbol_cat [2:0];

  assign cat_out = ~led_out;
  assign an_out = ~segment_state;

  always_comb begin
    case(val_in_huns)
      0: symbol_cat[2] = 7'b0111111; 
      1: symbol_cat[2] = 7'b0000110; 
      2: symbol_cat[2] = 7'b1011011; 
      3: symbol_cat[2] = 7'b1001111; 
      default: symbol_cat[2] = 7'b0000000; //null
    endcase
  end

  always_comb begin
    case(val_in_tens)
      0: symbol_cat[1] = 7'b0111111; 
      1: symbol_cat[1] = 7'b0000110; 
      2: symbol_cat[1] = 7'b1011011; 
      3: symbol_cat[1] = 7'b1001111;
      4: symbol_cat[1] = 7'b1100110; 
      5: symbol_cat[1] = 7'b1101101; 
      6: symbol_cat[1] = 7'b1111101; 
      7: symbol_cat[1] = 7'b0000111;
      8: symbol_cat[1] = 7'b1111111;
      9: symbol_cat[1] = 7'b1100111; 
      default: symbol_cat[1] = 7'b0000000; //null
    endcase
  end

  assign symbol_cat[0] = 7'b0111111;

  always_comb begin
    case(segment_state)
      8'b0000_0001:   led_out = symbol_cat[0];
      8'b0000_0010:   led_out = symbol_cat[1];
      8'b0000_0100:   led_out = symbol_cat[2];
      8'b0000_1000:   led_out = 7'b0000000;
      8'b0001_0000:   led_out = 7'b1001000; // = 
      8'b0010_0000:   led_out = 7'b1101111; // g
      8'b0100_0000:   led_out = 7'b1010100; // n
      8'b1000_0000:   led_out = 7'b1110111; // A
      default:        led_out = 7'b0000000;
    endcase
  end
  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      segment_state <= 8'b0000_0001;
      segment_counter <= 32'b0;
    end else begin
      if (segment_counter == COUNT_TO)begin
          segment_counter <= 32'd0;
          segment_state <= {segment_state[6:0],segment_state[7]};
      end else begin
          segment_counter <= segment_counter +1;
      end
    end
  end
endmodule //seven_segment_controller


`default_nettype wire
