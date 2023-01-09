`timescale 1ns / 1ps
`default_nettype none

module theta_to_xy (
        input wire [8:0] angle,
        output logic signed [6:0] true_x_out,
        output logic signed [6:0] true_y_out,
        output logic signed [6:0] true_z_out);

assign true_z_out = 'sd0;

always_comb begin
  case(angle)
      0: true_y_out = 0;
      10: true_y_out = 'sd5;
      20: true_y_out = 'sd10;
      30: true_y_out = 'sd16;
      40: true_y_out = 'sd21;
      50: true_y_out = 'sd26;
      60: true_y_out = 'sd32;
      70: true_y_out = 'sd37;
      80: true_y_out = 'sd43;
      90: true_y_out = 'sd48;
      100: true_y_out = 'sd43;
      110: true_y_out = 'sd37;
      120: true_y_out = 'sd32;
      130: true_y_out = 'sd26;
      140: true_y_out = 'sd21;
      150: true_y_out = 'sd16;
      160: true_y_out = 'sd10;
      170: true_y_out = 'sd5;
      180: true_y_out = 0;
      190: true_y_out = -'sd5;
      200: true_y_out = -'sd10;
      210: true_y_out = -'sd16;
      220: true_y_out = -'sd21;
      230: true_y_out = -'sd26;
      240: true_y_out = -'sd32;
      250: true_y_out = -'sd37;
      260: true_y_out = -'sd43;
      270: true_y_out = -'sd48;
      280: true_y_out = -'sd43;
      290: true_y_out = -'sd37;
      300: true_y_out = -'sd32;
      310: true_y_out = -'sd26;
      320: true_y_out = -'sd21;
      330: true_y_out = -'sd16;
      340: true_y_out = -'sd10;
      350: true_y_out = -'sd5;
  default: true_y_out = 0;
  endcase

  if (angle <= 90) true_x_out = $signed(48) - true_y_out;
  else if (angle > 90 && angle <= 180) true_x_out = true_y_out + $signed(-'sd48);
  else if (angle > 180 && angle <= 270) true_x_out = $signed(-'sd48) - true_y_out;
  else true_x_out = $signed(48) + true_y_out;
end

endmodule

`default_nettype wire
