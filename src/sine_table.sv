`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module sine_table #(
    parameter ROM_DEPTH=64,  // number of entries in sine ROM for 0° to 90°
    parameter ROM_WIDTH=8,   // width of sine ROM data in bits
    //parameter ROM_FILE="",   // sine table file to populate ROM
    parameter ADDRW=$clog2(4*ROM_DEPTH)  // full circle is 0° to 360°
    ) (
    input  wire logic [ADDRW-1:0] id,  // table ID to lookup
    input wire rst,
    input wire clk,
    output      logic signed [2*ROM_WIDTH-1:0] data  // answer (fixed-point)
    );

  // sine table ROM: 0°-90°
  logic [$clog2(ROM_DEPTH)-1:0] tab_id;
  logic [ROM_WIDTH-1:0] tab_data;

//  rom_async #(
//      .WIDTH(ROM_WIDTH),
//      .DEPTH(ROM_DEPTH),
//      .INIT_F(ROM_FILE)
//  ) sine_rom (
//      .addr(tab_id),
//      .data(tab_data)
//  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(ROM_WIDTH),                       // Specify RAM data width
    .RAM_DEPTH(ROM_DEPTH),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(sine_table.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) sine_rom (
    .addra(tab_id),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(tab_data)      // RAM output data, width determined from RAM_WIDTH
  );


  logic [1:0] quad;  // quadrant we're in: I, II, III, IV
  always_comb begin
      quad[1] = id > 179 ? 1 : 0;
      quad[0] = (((id > 179) && (id<270)) || (id < 90)) ? 0 : 1;
     // quad = id[ADDRW-1:ADDRW-2];
      case (quad)
          2'b00: tab_id = id[ADDRW-3:0];                //  I:    0° to  90°
          2'b01: tab_id = 2*ROM_DEPTH - id[ADDRW-3:0];  // II:   90° to 180°
          2'b10: tab_id = id[ADDRW-3:0] - 2*ROM_DEPTH;  // III: 180° to 270°
          2'b11: tab_id = 4*ROM_DEPTH - id[ADDRW-3:0];  // IV:  270° to 360°
      endcase
  end

  always_comb begin
      if (id == ROM_DEPTH) begin  // sin(90°) = +1.0
          data = {{ROM_WIDTH-1{1'b0}}, 1'b1, {ROM_WIDTH{1'b0}}};
      end else if (id == 3*ROM_DEPTH) begin  // sin(270°) = -1.0
          data = {{ROM_WIDTH{1'b1}}, {ROM_WIDTH{1'b0}}};
      end else begin
          if (quad[1] == 0) begin  // positive in quadrant I and II
              data = {{ROM_WIDTH{1'b0}}, tab_data};
          end else begin
              data = {2*ROM_WIDTH{1'b0}} - {{ROM_WIDTH{1'b0}}, tab_data};
          end
      end
  end
endmodule

`default_nettype wire
