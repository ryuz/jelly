// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


// Jelly bus to WISHBONE bus bridge
module jelly_jbus_decoder
		#(
			parameter	SLAVE_ADDR_WIDTH   = 30,
			parameter	SLAVE_DATA_SIZE    = 2,  				// 0:8bit, 1:16bit, 2:32bit ...
			parameter	SLAVE_DATA_WIDTH   = (8 << SLAVE_DATA_SIZE),
			parameter	SLAVE_SEL_WIDTH    = (SLAVE_DATA_WIDTH / 8),
			
			parameter	DEC_ADDR_WIDTH     = SLAVE_ADDR_WIDTH
		)
		(
			// system
			input	wire							reset,
			input	wire							clk,
			
			// decode address
			input	wire	[SLAVE_ADDR_WIDTH-1:0]	addr_mask,
			input	wire	[SLAVE_ADDR_WIDTH-1:0]	addr_value,
			
			// slave port (jelly bus)
			input	wire							jbus_slave_en,
			input	wire	[SLAVE_ADDR_WIDTH-1:0]	jbus_slave_addr,
			input	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_slave_wdata,
			output	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_slave_rdata,
			input	wire							jbus_slave_we,
			input	wire	[SLAVE_SEL_WIDTH-1:0]	jbus_slave_sel,
			input	wire							jbus_slave_valid,
			output	wire							jbus_slave_ready,
			
			// master port (jelly bus)
			output	wire							jbus_master_en,
			output	wire	[SLAVE_ADDR_WIDTH-1:0]	jbus_master_addr,
			output	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_master_wdata,
			input	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_master_rdata,
			output	wire							jbus_master_we,
			output	wire	[SLAVE_SEL_WIDTH-1:0]	jbus_master_sel,
			output	wire							jbus_master_valid,
			input	wire							jbus_master_ready,
			
			// decoded port (jelly bus)
			output	wire							jbus_decode_en,
			output	wire	[DEC_ADDR_WIDTH-1:0]	jbus_decode_addr,
			output	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_decode_wdata,
			input	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_decode_rdata,
			output	wire							jbus_decode_we,
			output	wire	[SLAVE_SEL_WIDTH-1:0]	jbus_decode_sel,
			output	wire							jbus_decode_valid,
			input	wire							jbus_decode_ready
		);
	
	
	wire	sw;
	assign	sw = ((jbus_slave_addr & addr_mask) == addr_value);
	
	wire	read_ready;
	reg		read_sw;
	
	reg		read_busy;
	always @ ( posedge clk ) begin
		if ( reset ) begin
			read_busy <= 1'b0;
			read_sw   <= 1'bx;
		end
		else begin
			if ( jbus_slave_en & !jbus_slave_we & jbus_slave_valid & jbus_slave_ready ) begin
				read_busy <= 1'b1;
				read_sw   <= sw;
			end
			else if ( jbus_slave_en & jbus_slave_ready ) begin
				read_busy <= 1'b0;
				read_sw   <= 1'bx;
			end
		end
	end
	assign read_ready = read_busy ? (read_sw ? jbus_decode_ready : jbus_master_ready) : 1'b1;
	
	assign jbus_master_en    = jbus_slave_en & read_ready;
	assign jbus_master_addr  = jbus_slave_addr;
	assign jbus_master_wdata = jbus_slave_wdata; 
	assign jbus_master_we    = jbus_slave_we;
	assign jbus_master_sel   = jbus_slave_sel;
	assign jbus_master_valid = jbus_slave_valid & !sw;
	
	assign jbus_decode_en    = jbus_slave_en & read_ready;
	assign jbus_decode_addr  = jbus_slave_addr; 
	assign jbus_decode_wdata = jbus_slave_wdata; 
	assign jbus_decode_we    = jbus_slave_we;
	assign jbus_decode_sel   = jbus_slave_sel;
	assign jbus_decode_valid = jbus_slave_valid & sw;
	
	assign jbus_slave_rdata = read_sw ? jbus_decode_rdata : jbus_master_rdata;
	assign jbus_slave_ready = (sw ? jbus_decode_ready : jbus_master_ready) & read_ready;
	
endmodule

