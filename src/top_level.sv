`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire btnc, //reset
  input wire btnl,
  
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
    .clk_out1(clk_65mhz));

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
  logic left;
  debouncer #() db (.clk_in(clk_65mhz), .rst_in(sys_rst), .dirty_in(btnl), .clean_out(left));

  logic [2:0] sel_angle;
  logic prev;
  always_ff @(posedge clk_65mhz) begin
    prev <= left;
    if (left && !(prev)) begin
      sel_angle <= sel_angle +1;
    end
  end

  logic [8:0] angle;
  always_comb begin
    case (sel_angle)
      0: angle = 0;
      1: angle = 40;
      2: angle = 90;
      3: angle = 130;
      4: angle = 180;
      5: angle = 220;
      6: angle = 270;
      7: angle = 360;
      default: angle = 0;
    endcase
  end

  logic signed [6:0] x, y, z;
  theta_to_xy(
    .angle(angle),
    .true_x_out(x),
    .true_y_out(y),
    .true_z_out(z)
  );


  logic [29:0] camera_loc;
  logic camera_loc_valid_in;
  always_ff @(posedge clk_65mhz) begin
    if (sys_rst) begin
      camera_loc_valid_in <= 0;
    end else begin
      camera_loc_valid_in <= !(camera_loc_valid_in);
    end
  end
  //camera loc
  //assign camera_loc = 30'b00_0000_0000_1111_1100_0000_0000_0000; //theta=0, x=63, y=0, z=0
  //assign camera_loc = 30'b000000000_0110010_0000000_0000000; //theta=0, x=50, y=0, z=0
  //assign camera_loc = 30'b010110100_1001110_0000000_0000000; //theta=180, x=50, y=0, z=0
  assign camera_loc = {angle, x, y, z};

  logic model_out_valid;
  logic [54:0] model_out;
  logic raster_busy_in;
  a3d_to_2d #(
      .SIZE(2),
      .MODEL_FILE("two_tri.mem"),
      .ADDRW()
  ) a3d_to_2d (
      .clk(clk_65mhz),
      .rst(sys_rst),
      .raster_busy(raster_busy_in),
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
      .busy_out(raster_busy_in),
      .valid(rasterize_valid),
      .pixel_out(pixel_out)
  );

  //pixels out from rasterize into zbuffer
  logic zbuffer_valid_out;
  logic [11:0] pixel_addr;
  logic [9:0] pixel_color_out;

  logic clear_data;
  logic [12:0] clear_addr;

  zbuffer #(
      .SIZE(64),
      .WIDTH(9)
  ) zbuffer (
      .clk(clk_65mhz),
      .rst(sys_rst),
      .valid_in(rasterize_valid),
      .pixel_in(pixel_out),
      .clear_z(clear_data),
      .clear_addr(clear_addr),
      .valid_out(zbuffer_valid_out),
      .pixel_addr(pixel_addr),
      .pixel_out(pixel_color_out)
  );

  //decide pixel out
  //scren size 1024x768
  //x_com = 256, y_com = 384 for now
  logic [12:0] model_addr;
  logic [11:0] display_out;
  always_comb begin
    if ((vcount >= 10'd768) && (vcount <= 10'd772)) begin
      clear_addr = hcount + ((vcount-10'd768)*11'd1343);
      model_addr = clear_addr;
      clear_data = 1;
    end else begin
      clear_data = 0;
      clear_addr = 0;
      model_addr = (hcount - 11'd224) + ((vcount - 10'd352) * 64);
      if (hcount >= 11'd224 && hcount <= 11'd288 && vcount >= 10'd352 && vcount <= 10'd416) begin
        display_out = {color_out[9:7], 1'b0, color_out[6:0], 1'b0};
      end else begin
        display_out = 12'h800;
      end
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
    .dinb(10'b0), //clear data in RAM 
    .clka(clk_65mhz),
    .wea(zbuffer_valid_out), 
    .web(clear_data),
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
