`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire btnc, //reset
  
  input wire [7:0] ja, //lower 8 bits from camera
  input wire [2:0] jb, //upper 3 bits from camera

  output logic jbclk,
  output logic jblock,

  output logic [3:0] vga_r, vga_g, vga_b,
  output logic vga_hs, vga_vs
  );

  logic sys_rst;
  assign sys_rst = btnc;

  logic clk_65mhz;

  clk_wiz_lab3 clk_gen(
    .clk_in1(clk_100mhz),
    .clk_out1(clk_65mhz)); //after frame buffer everything on clk_65mhz

  //generate vga signals
  logic [10:0] hcount;
  logic [9:0] vcount;
  logic vsync;
  logic hsync;
  logic blank;
  vga vga(
    .pixel_clk_in(clk_65mhz),
    .hcount_out(hcount),
    .vcount_out(vcount),
    .vsync_out(vsync),
    .hsync_out(hsync),
    .blank_out(blank)
  );

  //testing 3d render output, centered on screen
  //camera_loc into a3d_to_2d
  //temporay logic to control camera location via buttons
  logic [29:0] camera_loc;
  logic camera_loc_valid_in;
  assign camera_loc_valid_in = 1;
  //camera loc
  assign camera_loc = 30'b000110101000001000001000000000;

  logic model_out_valid;
  logic [54:0] model_out;
  a3d_to_2d #(
      .SIZE(1),
      .MODEL_FILE("basic_model.mem"),
      .ADDRW(1)
  ) a3d_to_2d (
      .clk(clk_65mhz),
      .rst(sys_rst),
      .valid_in(camera_loc_valid_in),
      .camera_loc(camera_loc),
      .valid_out(model_out_valid),
      .model_out(model_out)
  ); 

  //model_out into rasterize
  logic rasterize_valid;
  logic [30:0] pixel_out;

  rasterize raster (
      .clk(clk_65mhz),
      .rst(sys_rst),
      .valid_in(model_out_valid),
      .model_in(model_out),
      .valid(rasterize_valid),
      .pixel_out(pixel_out)
  );

  //pixels out from rasterize into zbuffer
  logic zbuffer_valid_out;
  logic [11:0] pixel_addr;
  logic [9:0] pixel_color_out;

  zbuffer #(
      .SIZE(64),
      .WIDTH(9)
  ) zbuffer (
      .clk(clk_65mhz),
      .rst(sys_rst),
      .valid_in(rasterize_valid),
      .pixel_in(pixel_out),
      .valid_out(zbuffer_valid_out),
      .pixel_addr(pixel_addr),
      .pixel_out(pixel_color_out)
  );

  //decide pixel out
  //x_com = 512, y_com = 384 for now
  logic [12:0] model_addr;
  logic [11:0] display_out;
  always_comb begin
    model_addr = (hcount - 11'd480) + ((vcount - 10'd352) * 64);
    if (hcount >= 11'd480 && hcount <= 11'd544 && vcount >= 10'd352 && vcount <= 10'd416) begin
      display_out = {color_out[9:7], 1'b0, color_out[6:0], 1'b0};
    end else begin
      display_out = 12'h800;
    end
  end

  logic douta;
  logic [9:0] color_out;
  xilinx_true_dual_port_read_first_clock_ram #(
    .RAM_WIDTH(10),
    .RAM_DEPTH(4096),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE()
  ) model_color_bram (
    .addra(pixel_addr), //color write in
    .addrb(model_addr), //render access addr
    .dina(pixel_color_out), //color data in
    .dinb(1'b0), 
    .clka(clk_65mhz),
    .wea(zbuffer_valid_out), 
    .web(1'b0),
    .ena(1'b1),
    .enb(1'b1),
    .rsta(sys_rst),
    .rstb(sys_rst),
    .regcea(1'b0),
    .regceb(1'b1),
    .douta(douta),
    .doutb(color_out)
  );

  assign vga_r = blank ? 0 : display_out[11:8];
  assign vga_g = blank ? 0 : display_out[7:4];
  assign vga_b = blank ? 0 : display_out[3:0];

  assign vga_hs = ~(hsync);
  assign vga_vs = ~(vsync);


endmodule


`default_nettype wire
