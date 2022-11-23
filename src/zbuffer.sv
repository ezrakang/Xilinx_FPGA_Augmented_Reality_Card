`timescale 1ns / 1ps
`default_nettype none

module zbuffer#(
      parameter SIZE = 64,
      parameter WIDTH = 6
) (
      input wire clk,
      input wire rst,
      input wire valid_in,
      input wire [27:0] pixel_in,

      input wire valid_out,
      output logic [$clog2(SIZE*SIZE)-1:0] pixel_addr,
      output logic [9:0] pixel_out
);

  logic [$clog2(SIZE*SIZE)-1:0] addr;
  
      
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(WIDTH),
    .RAM_DEPTH(SIZE*SIZE),
    .INIT_FILE()
    z_buffer (
    .addra(addr),
    .clka(clk),
    .wea(valid_pixel_rotate),
    .dina(pixel_rotate),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(),
    //Read Side (65 MHz)
    .addrb(pixel_addr_out),
    .dinb(16'b0),
    .clkb(clk_65mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(frame_buff)
  );






endmodule

`default_nettype wire
