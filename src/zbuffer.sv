`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module zbuffer#(
      parameter SIZE = 64,
      parameter WIDTH = 9
) (
      input wire clk,
      input wire rst,
      input wire valid_in,
      input wire [30:0] pixel_in,

      output wire valid_out,
      output logic [$clog2(SIZE*SIZE)-1:0] pixel_addr,
      output logic [9:0] pixel_out
);

  logic [$clog2(SIZE*SIZE)-1:0] addr;
  logic [8:0] depth_out;
  logic write_ena;
  logic [8:0] depth_in;
  logic data_outb;

  assign addr = (pixel_in[30:25] + pixel_in[24:19]*SIZE);
      
  xilinx_true_dual_port_read_first_clock_ram #(
    .RAM_WIDTH(WIDTH),
    .RAM_DEPTH(SIZE*SIZE),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(zbuffer_table.mem))
  ) z_buffer (
    //read side
    .addra(addr_pipe[0]),
    .clka(clk),
    .wea(1'b0),
    .dina(1'b0),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst),
    .douta(depth_out),
    //write side
    .addrb(pixel_addr),
    .dinb(depth_in),
    .web(write_ena),
    .enb(1'b1),
    .rstb(rst),
    .regceb(1'b1),
    .doutb(data_outb)
  );

  assign valid_out = (valid_pipe[2] && (depth_pipe[2] < depth_out));
  assign write_ena = valid_out;
  assign pixel_addr = addr_pipe[2];
  assign pixel_out = color_pipe[2];
  assign depth_in = depth_pipe[2];

  logic [5:0] depth_pipe [2:0];
  logic [9:0] color_pipe [2:0];
  logic [2:0] valid_pipe;
  logic [$clog2(SIZE*SIZE)-1:0] addr_pipe [2:0];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i=0; i<2; i=i+1) begin
        depth_pipe[i] <= 0;
        color_pipe[i] <= 0;
        valid_pipe[i] <= 0;
        addr_pipe[i] <= 0;
      end
    end else begin
      //pipeline incoming depths and color
      for (int i=1; i<3; i=i+1) begin
        depth_pipe[i] <= depth_pipe[i-1];
        color_pipe[i] <= color_pipe[i-1];
        valid_pipe[i] <= valid_pipe[i-1];
        addr_pipe[i] <= addr_pipe[i-1];
      end
      
      depth_pipe[0] <= pixel_in[15:10]; 
      color_pipe[0] <= pixel_in[9:0];
      valid_pipe[0] <= valid_in;
      addr_pipe[0] <= addr;
    end
  end

endmodule

`default_nettype wire
