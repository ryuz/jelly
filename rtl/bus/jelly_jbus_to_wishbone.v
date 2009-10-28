// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// Jelly bus to WISHBONE bus bridge
module jelly_jbus_to_wishbone
		#(
			parameter							ADDR_WIDTH   = 30,
			parameter							DATA_SIZE    = 2,  				// 0:8bit, 1:16bit, 2:32bit ...
			parameter							DATA_WIDTH   = (8 << DATA_SIZE),
			parameter							SEL_WIDTH    = (DATA_WIDTH / 8)
		)
		(
			// system
			input	wire						reset,
			input	wire						clk,
			
			// slave port (jelly bus)
			input	wire						jbus_slave_en,
			input	wire						jbus_slave_we,
			input	wire	[SEL_WIDTH-1:0]		jbus_slave_sel,
			input	wire	[ADDR_WIDTH-1:0]	jbus_slave_addr,
			input	wire	[DATA_WIDTH-1:0]	jbus_slave_wdata,
			output	reg		[DATA_WIDTH-1:0]	jbus_slave_rdata,
			output	wire						jbus_slave_ready,
			
			// master port (WISHBONE bus)
			output	wire	[ADDR_WIDTH-1:0]	wb_master_adr_o,
			input	wire	[DATA_WIDTH-1:0]	wb_master_dat_i,
			output	wire	[DATA_WIDTH-1:0]	wb_master_dat_o,
			output	wire						wb_master_we_o,
			output	wire	[SEL_WIDTH-1:0]		wb_master_sel_o,
			output	wire						wb_master_stb_o,
			input	wire						wb_master_ack_i
		);
	
	
	always @ ( posedge clk ) begin
		if ( reset ) begin
			jbus_slave_rdata <= {DATA_WIDTH{1'bx}};
		end
		else begin
			if ( jbus_slave_ready ) begin
				jbus_slave_rdata <= wb_master_dat_i;
			end
		end
	end
	
	assign wb_master_adr_o  = jbus_slave_addr;
	assign wb_master_dat_o  = jbus_slave_wdata;
	assign wb_master_we_o   = jbus_slave_we;
	assign wb_master_sel_o  = jbus_slave_sel;
	assign wb_master_stb_o  = jbus_slave_en;
	
	assign jbus_slave_ready = !wb_master_stb_o | wb_master_ack_i;
	
endmodule

