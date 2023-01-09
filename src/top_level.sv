`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz, //clock @ 100 mhz
  input wire [15:0] sw, //switches
  input wire btnc, //btnc (used for reset)
  input wire btnl, //btnc (used for reset)

  input wire [7:0] ja, //lower 8 bits of data from camera
  input wire [2:0] jb, //upper three bits from camera (return clock, vsync, hsync)
  output logic jbclk,  //signal we provide to camera
  output logic jblock, //signal for resetting camera

  output logic [15:0] led, //just here for the funs

  output logic [3:0] vga_r, vga_g, vga_b,
  output logic vga_hs, vga_vs,
  output logic [7:0] an,
  output logic caa,cab,cac,cad,cae,caf,cag

  );

  //system reset switch linking
  logic sys_rst; //global system reset
  assign sys_rst = btnc; //just done to make sys_rst more obvious
  assign led = sw; //switches drive LED (change if you want)

  /* Video Pipeline */
  logic clk_65mhz; //65 MHz clock line

  //vga module generation signals:
  logic [10:0] hcount;    // pixel on current line
  logic [9:0] vcount;     // line number
  logic hsync, vsync, blank; //control signals for vga
  logic hsync_t, vsync_t, blank_t; //control signals out of transform


  //camera module: (see datasheet)
  logic cam_clk_buff, cam_clk_in; //returning camera clock
  logic vsync_buff, vsync_in; //vsync signals from camera
  logic href_buff, href_in; //href signals from camera
  logic [7:0] pixel_buff, pixel_in; //pixel lines from camera
  logic [15:0] cam_pixel; //16 bit 565 RGB image from camera
  logic valid_pixel; //indicates valid pixel from camera
  logic frame_done; //indicates completion of frame from camera

  //rotate module:
  logic valid_pixel_rotate;  //indicates valid rotated pixel
  logic [15:0] pixel_rotate; //rotated 565 rotate pixel
  logic [16:0] pixel_addr_in; //address of rotated pixel in 240X320 memory

  //values  of frame buffer:
  logic [16:0] pixel_addr_out; //
  logic [15:0] frame_buff; //output of scale module

  // output of scale module
  logic [15:0] full_pixel;//mirrored and scaled 565 pixel

  //output of rgb to ycrcb conversion:
  logic [9:0] y; //[2:0]; //ycrcb conversion of full pixel (NEW)
  logic [9:0] cr; //[2:0]; //ycrcb conversion of full pixel (NEW)
  logic [9:0] cb; //[2:0]; //ycrcb conversion of full pixel (NEW)

  //output of threshold module:
  logic mask; //Whether or not thresholded pixel is 1 or 0
  logic [3:0] sel_channel; //selected channels four bit information intensity
  //sel_channel could contain any of the six color channels depend on selection

  //Center of Mass variables
  logic [10:0] x_com, x_com_calc, x_angle_com_calc, x_angle_com; //long term x_com and output from module, resp
  logic [9:0] y_com, y_com_calc, y_angle_com_calc, y_angle_com; //long term y_com and output from module, resp
  logic new_com; //used to know when to update x_com and y_com ...
  //using x_com_calc and y_com_calc values

  //output of image sprite
  //Output of sprite that should be centered on Center of Mass (x_com, y_com):
  logic [11:0] com_sprite_pixel;

  //Crosshair value hot when hcount,vcount== (x_com, y_com)
  logic crosshair;

  //vga_mux output:
  logic [11:0] mux_pixel; //final 12 bit information from vga multiplexer
  //goes right into RGB of output for video render

  //Generate 65 MHz:
  clk_wiz_lab3 clk_gen(
    .clk_in1(clk_100mhz),
    .clk_out1(clk_65mhz)); //after frame buffer everything on clk_65mhz


  //Clock domain crossing to synchronize the camera's clock
  //to be back on the 65MHz system clock, delayed by a clock cycle.
  always_ff @(posedge clk_65mhz) begin
    cam_clk_buff <= jb[0]; //sync camera
    cam_clk_in <= cam_clk_buff;
    vsync_buff <= jb[1]; //sync vsync signal
    vsync_in <= vsync_buff;
    href_buff <= jb[2]; //sync href signal
    href_in <= href_buff;
    pixel_buff <= ja; //sync pixels
    pixel_in <= pixel_buff;
  end

  //Controls and Processes Camera information
  camera camera_m(
    //signal generate to camera:
    .clk_65mhz(clk_65mhz),
    .jbclk(jbclk),
    .jblock(jblock),
    //returned information from camera:
    .cam_clk_in(cam_clk_in),
    .vsync_in(vsync_in),
    .href_in(href_in),
    .pixel_in(pixel_in),
    //output framed info from camera for processing:
    .pixel_out(cam_pixel),
    .pixel_valid_out(valid_pixel),
    .frame_done_out(frame_done));

  //NEW FOR LAB 04B (START)----------------------------------------------
  logic [15:0] pixel_data_rec; // pixel data from recovery module
  logic [10:0] hcount_rec; //hcount from recovery module
  logic [9:0] vcount_rec; //vcount from recovery module
  logic  data_valid_rec; //single-cycle (65 MHz) valid data from recovery module

  //recovers hcount and vcount from camera module:
  //generates data and a valid signal on 65 MHz
  recover recover_m (
    .cam_clk_in(cam_clk_in),
    .valid_pixel_in(valid_pixel),
    .pixel_in(cam_pixel),



    .frame_done_in(frame_done),

    .system_clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .pixel_out(pixel_data_rec),
    .data_valid_out(data_valid_rec),
    .hcount_out(hcount_rec),
    .vcount_out(vcount_rec));



  //new rotate module only on 65 MHz:
  //same as old one, but this one runs on 65 MHz with valid signal as
  //opposed to old one that ran on 16.67 MHz.
  rotate2 rotate_m(
    .clk_in(clk_65mhz),
    .hcount_in(hcount_rec),
    .vcount_in(vcount_rec),
    .data_valid_in(data_valid_rec),
    .pixel_in(pixel_data_rec),
    .pixel_out(pixel_rotate),
    .pixel_addr_out(pixel_addr_in),
    .data_valid_out(valid_pixel_rotate));

  //NEW FOR LAB 04B (END)----------------------------------------------

  //Generate VGA timing signals:
  vga vga_gen(
    .pixel_clk_in(clk_65mhz),
    .hcount_out(hcount),
    .vcount_out(vcount),
    .hsync_out(hsync),
    .vsync_out(vsync),
    .blank_out(blank));

  //Thresholder: Takes in the full RGB and YCrCb information and
  //based on upper and lower bounds masks
  //module has 0 cycle latency
  threshold(.sel_in(sw[5:3]),
  .r_in(full_pixel_pipe[2][15:12]), //TODO: needs to use pipelined signal (PS5)
  .g_in(full_pixel_pipe[2][10:7]),  //TODO: needs to use pipelined signal (PS5)
  .b_in(full_pixel_pipe[2][4:1]),   //TODO: needs to use pipelined signal (PS5)
  .lower_bound_in(sw[12:10]),
  .upper_bound_in(sw[15:13]),
  .mask_out(mask),
  .channel_out(sel_channel)
  );

  //Two Clock Frame Buffer:
  //Data written on 16.67 MHz (From camera)
  //Data read on 65 MHz (start of video pipeline information)
  //Latency is 2 cycles.
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(16),
    .RAM_DEPTH(320*240))
    frame_buffer (
    //Write Side (65MHz)
    .addra(pixel_addr_in),
    .clka(clk_65mhz),
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

  //Based on current hcount and vcount as well as
  //scaling and mirror information requests correct pixel
  //from BRAM (on 65 MHz side).
  //latency: 2 cycles
  //IMPORTANT: this module is "start" of Output pipeline
  //hcount and vcount are fine here.
  //however latency in the image information starts to build up starting here
  //and we need to make sure to continue to use screen location information
  //that is "delayed" the right amount of cycles!
  //AS A RESULT, most downstream modules after this will need to use appropriately
  //pipelined versions of hcount, vcount, hsync, vsync, blank as needed
  //these The pipelining of these stages will need to be determined
  //for CHECKOFF 3!
  address_picker addr_pick(
    .clk_in(clk_65mhz),
    .hcount_in(hcount),
    .vcount_in(vcount),
    .pixel_addr_out(pixel_addr_out)
  );

  //Based on hcount and vcount as well as scaling
  //gate the release of frame buffer information
  //Latency: 0
  scale scale_m(
    .hcount_in(hcount_pipe[3]), //TODO: needs to use pipelined signal (PS2)
    .vcount_in(vcount_pipe[3]), //TODO: needs to use pipelined signal (PS2)
    .frame_buff_in(frame_buff),
    .cam_out(full_pixel)
    );



  logic [8:0] angle_guess;
  logic valid_angle, angle_new_com;
  logic [3:0] ang_ten_out;
  logic [1:0] ang_hun_out;

  angle_checker ang_check (.clk_in(clk_65mhz),
                       .rst_in(btnc),
                       .x_in(x_angle_com),
                       .y_in(y_angle_com),
                       .x_com(x_com),
                       .y_com(y_com),
                       //.r_in(com_pixel_out[15:12]),//////
                       //.g_in(com_pixel_out[10:7]),///////
                       //.b_in(com_pixel_out[4:1]),///////
                       .valid_in(angle_new_com),
                       .angle(angle_guess),
                       .valid_out(valid_angle),
                       .tens_output(ang_ten_out),
                       .hundreds_output(ang_hun_out));

  logic signed [6:0] rendering_x, rendering_y;
  logic [6:0] rendering_z;
  theta_to_xy convert (
    .angle(angle_guess),
    .true_x_out(rendering_x),
    .true_y_out(rendering_y),
    .true_z_out(rendering_z)
  );


  lab04_ssc mssc(.clk_in(clk_65mhz),
               .rst_in(btnc),
               .val_in_tens(ang_ten_out),
               .val_in_huns(ang_hun_out),
               .cat_out({cag, caf, cae, cad, cac, cab, caa}),
               .an_out(an));


  logic [15:0] com_pixel_out;
  logic [10:0] hcount_com;
  logic [9:0] vcount_com;


  //Center of Mass:
  center_of_mass com_m(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_in(hcount_pipe[6]),  //TODO: needs to use pipelined signal! (PS3)
    .y_in(vcount_pipe[6]), //TODO: needs to use pipelined signal! (PS3)
    .valid_in(mask),
    .tabulate_in((hcount_pipe[6]==0 && vcount_pipe[6]==0)),
    .x_out(x_com_calc),
    .y_out(y_com_calc),
    .hcount_out(hcount_com),
    .vcount_out(vcount_com),
    .valid_out(new_com),
    .pixel_info(full_pixel_pipe[2]),
    .pixel_through(com_pixel_out));

    center_of_mass angle_com(.clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_in(hcount_pipe[6]),  //TODO: needs to use pipelined signal! (PS3)
    .y_in(vcount_pipe[6]), //TODO: needs to use pipelined signal! (PS3)
    .valid_in(full_pixel_pipe[2][10:8] < 4 && full_pixel_pipe[2][9:7] > 1 && full_pixel_pipe[2][15:13] < 3 && full_pixel_pipe[2][4:2] < 3),
    .tabulate_in((hcount_pipe[6]==0 && vcount_pipe[6]==0)),
    .x_out(x_angle_com_calc),
    .y_out(y_angle_com_calc),
    //.hcount_out(hcount_com),
    //.vcount_out(vcount_com),
    .valid_out(angle_new_com),
    .pixel_info(0)
    //.pixel_through(com_pixel_out)
    );

  //update center of mass x_com, y_com based on new_com signal
  always_ff @(posedge clk_65mhz)begin
    if (sys_rst)begin
      x_com <= 0;
      y_com <= 0;
      x_angle_com <= 0;
      y_angle_com <= 0;
    end if(new_com)begin
      x_com <= (x_com > 50 + x_com_calc)? x_com_calc : ((x_com < x_com_calc - 50)?  x_com_calc:x_com );
      y_com <= (y_com > 50 + y_com_calc)? y_com_calc : ((y_com < y_com_calc - 50)?  y_com_calc:y_com );
      x_angle_com <= x_angle_com_calc;
      y_angle_com <= y_angle_com_calc;
    end
  end

  //Create Crosshair patter on center of mass:
  //0 cycle latency

 assign crosshair = (((vcount_pipe[2]==y_com)||(hcount_pipe[2]==x_com))&&(x_com>5 && y_com>5));
  //assign crosshair = (((vcount_pipe[2]==y_angle_com)||(hcount_pipe[2]==x_angle_com))&&(x_com>5 && y_com>5));

  //VGA MUX:
  //latency 0 cycles (combinational-only module)
  //module decides what to draw on the screen:
  // sw[7:6]:
  //    00: 444 RGB image
  //    01: GrayScale of Selected Channel (Y, R, etc...)
  //    10: Masked Version of Selected Channel
  //    11: Chroma Image with Mask in 6.205 Pink
  // sw[9:8]:
  //    00: Nothing
  //    01: green crosshair on center of mass
  //    10: image sprite on top of center of mass



  //    11: all pink screen (for VGA functionality testing)
  vga_mux (.sel_in(sw[9:6]),
  .camera_pixel_in({full_pixel_pipe[2][15:12],full_pixel_pipe[2][10:7],full_pixel_pipe[2][4:1]}), //TODO: needs to use pipelined signal(PS5)
  .camera_y_in(y[9:6]),
  .channel_in(sel_channel),
  .thresholded_pixel_in(mask),
  .crosshair_in(crosshair_pipe[3]), //TODO: needs to use pipelined signal (PS4)
  .pixel_out(mux_pixel)
  );

  //blankig logic.
  //latency 1 cycle
  

  //Registers

  //Register for hcount and vcount(PS1, PS2, PS3)
  logic [10:0] hcount_pipe [6:0];
  logic [9:0] vcount_pipe [6:0];
  always_ff @(posedge clk_65mhz)begin
    hcount_pipe[0] <= hcount;
    vcount_pipe[0] <= vcount;
    for (int i=1; i<7; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
      vcount_pipe[i] <= vcount_pipe[i-1];
    end
  end


  //Register for blank, hsync, vsync (PS6, PS7)
  logic hsync_pipe [7:0];
  logic vsync_pipe [7:0];
  logic blank_pipe [7:0];
  always_ff @(posedge clk_65mhz)begin
    hsync_pipe[0] <= hsync;
    vsync_pipe[0] <= vsync;
    blank_pipe[0] <= blank;
    for (int i=1; i<8; i = i+1)begin
      hsync_pipe[i] <= hsync_pipe[i-1];
      vsync_pipe[i] <= vsync_pipe[i-1];
      blank_pipe[i] <= blank_pipe[i-1];
    end
  end

  logic crosshair_pipe [3:0];
  always_ff @(posedge clk_65mhz)begin
    crosshair_pipe[0] <= crosshair;
    for (int i=1; i<4; i = i+1)begin
      crosshair_pipe[i] <= crosshair_pipe[i-1];
    end
  end

  logic [15:0] full_pixel_pipe [2:0];
  always_ff @(posedge clk_65mhz)begin
    full_pixel_pipe[0] <= full_pixel;
    for (int i=1; i<3; i = i+1)begin
      full_pixel_pipe[i] <= full_pixel_pipe[i-1];
    end
  end

  //start rendering pipeline

  logic [29:0] camera_loc;
  logic camera_loc_valid_in;
  assign camera_loc_valid_in = valid_angle;
  assign camera_loc = {angle_guess, rendering_x, rendering_y, rendering_z};


  logic model_out_valid;
  logic [54:0] model_out;
  logic raster_busy_in;
  a3d_to_2d #(
      .SIZE(4),
      .MODEL_FILE("pyramid.mem"),
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

  //x_com, y_com
  //scaling 4x
  logic [12:0] model_addr;
  logic [11:0] display_out;
  always_ff @(posedge clk_65mhz) begin
    if ((vcount >= 10'd768) && (vcount <= 10'd772)) begin
      model_addr <= clear_addr;
    end else begin
      model_addr <= (((hcount-(x_com-128))>>2) + 64*(((vcount-(y_com-128))>>2)));
    end
  end


  always_comb begin
    //clearing logic
    if ((vcount >= 10'd768) && (vcount <= 10'd772)) begin
      clear_addr = hcount + ((vcount-10'd768)*11'd1343);
      clear_data = 1;
    end else begin
      clear_data = 0;
      clear_addr = 0;
      display_out = {color_out[9:7], 1'b0, color_out[6:0], 1'b0};
    end
  end

  




  //get pixel out
  always_ff @(posedge clk_65mhz)begin
    if (hcount >= (x_com-128) && hcount <= (x_com+128) && vcount >= (y_com-128) && vcount <= (y_com+128)) begin
      vga_r <= color_out ? display_out[11:8] : mux_pixel[11:8];
      vga_g <= color_out ? display_out[7:4] : mux_pixel[7:4];
      vga_b <= color_out ? display_out[3:0] : mux_pixel[3:0];

    end else begin
      vga_r <= ~blank_pipe[6]?mux_pixel[11:8]:0; //TODO: needs to use pipelined signal (PS6)
      vga_g <= ~blank_pipe[6]?mux_pixel[7:4]:0;  //TODO: needs to use pipelined signal (PS6)
      vga_b <= ~blank_pipe[6]?mux_pixel[3:0]:0;  //TODO: needs to use pipelined signal (PS6)
    end
  end

  assign vga_hs = ~hsync_pipe[7];  //TODO: needs to use pipelined signal (PS7)
  assign vga_vs = ~vsync_pipe[7];  //TODO: needs to use pipelined signal (PS7)

endmodule




`default_nettype wire
