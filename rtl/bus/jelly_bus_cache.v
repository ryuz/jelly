// ---------------------------------------------------------------------------
//  Jelly -- The computing system for Spartan-3 Starter Kit
//
//                                 Copyright (C) 2008-2009 by Ryuji Fuchikami 
//                                 http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly_bus_cahce
		#(
			parameter	LINE_WORDS        = 2,		// 2^n (0:1words, 1:2words, 2:4words ...)
			parameter	ARRAY_SIZE        = 8,		// 2^n (1:2lines, 2:4lines 3:8lines ...)
			
			parameter	SLAVE_ADDR_WIDTH  = 24,
			parameter	SLAVE_DATA_SIZE   = 2,		// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			parameter	SLAVE_DATA_WIDTH  = (8 << SLAVE_DATA_SIZE),
			parameter	SLAVE_BLS_WIDTH   = (1 << SLAVE_DATA_SIZE),
			
			parameter	MASTER_ADDR_WIDTH = SLAVE_ADDR_WIDTH - CACHE_LINE_WORDS,
			parameter	MASTER_DATA_SIZE  = SLAVE_DATA_SIZE + CACHE_LINE_WORDS,
			parameter	MASTER_DATA_WIDTH = (8 << MASTER_DATA_SIZE),
			parameter	MASTER_BLS_WIDTH  = (1 << MASTER_DATA_SIZE),
						
			parameter	CACHE_OFFSET_WIDTH = CACHE_LINE_WORDS,
			parameter	CACHE_INDEX_WIDTH  = CACHE_ARRAY_SIZE,
			parameter	CACHE_TAGADR_WIDTH = SLAVE_ADDR_WIDTH - (CACHE_INDEX_WIDTH + CACHE_OFFSET_WIDTH),
			parameter	CACHE_DATA_WIDTH   = MASTER_DATA_WIDTH;

			parameter	RAM_ADDR_WIDTH     = CACHE_ARRAY_SIZE;
			parameter	RAM_DATA_WIDTH     = 1 + CACHE_TAGADR_WIDTH + CACHE_DATA_WIDTH
		)
		(
			// system
			input	wire							clk,
			input	wire							reset,
			
			// slave port
			input	wire							jbus_slave_en,
			input	wire							jbus_slave_we,
			input	wire	[SLAVE_ADDR_WIDTH-1:0]	jbus_slave_addr,
			input	wire	[SLAVE_BLS_WIDTH-1:0]	jbus_slave_bls,
			input	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_slave_wdata,
			output	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_slave_rdata,
			output	wire							jbus_slave_ready,
			
			// master port
			output	wire							jbus_master_en,
			output	wire							jbus_master_we,
			output	wire	[MASTER_ADDR_WIDTH-1:0]	jbus_master_addr,
			output	wire	[MASTER_BLS_WIDTH-1:0]	jbus_master_bls,
			output	wire	[MASTER_DATA_WIDTH-1:0]	jbus_master_wdata,
			input	wire	[MASTER_DATA_WIDTH-1:0]	jbus_master_rdata,
			input	wire							jbus_master_ready,

			// ram port
			output	wire							ram_en,
			output	wire							ram_we,
			output	wire	[RAM_ADDR_WIDTH-1:0]	ram_addr,
			output	wire	[RAM_DATA_WIDTH-1:0]	ram_wdata,
			input	wire	[RAM_DATA_WIDTH-1:0]	ram_rdata
		);
	
	
	// tag&data RAM assign
	wire								ram_write_valid;
	wire	[CACHE_TAGADR_WIDTH-1:0]	ram_write_tagadr;
	wire	[CACHE_DATA_WIDTH-1:0]		ram_write_data;
	assign ram_wdata = {ram_write_valid, ram_write_tagadr, ram_write_data};
	
	wire								ram_read_valid;
	wire	[CACHE_TAGADR_WIDTH-1:0]	ram_read_tagadr;
	wire	[CACHE_DATA_WIDTH-1:0]		ram_read_data;
	assign ram_read_data   = jbus_master_rdata[CACHE_DATA_WIDTH-1:0];
	assign ram_read_tagadr = jbus_master_rdata[CACHE_DATA_WIDTH +: CACHE_TAGADR_WIDTH];
	assign ram_read_valid  = jbus_master_rdata[RAM_DATA_WIDTH-1];
	
	// slave address assign
	wire	[CACHE_OFFSET_WIDTH-1:0]	jbus_slave_offset;
	wire	[CACHE_INDEX_WIDTH-1:0]		jbus_slave_index;
	wire	[CACHE_TAGADR_WIDTH-1:0]	jbus_slave_tagadr;
	assign jbus_slave_offset = jbus_slave_addr[0                                      +: CACHE_OFFSET_WIDTH];
	assign jbus_slave_index  = jbus_slave_addr[CACHE_OFFSET_WIDTH                     +: CACHE_INDEX_WIDTH];
	assign jbus_slave_tagadr = jbus_slave_addr[CACHE_OFFSET_WIDTH + CACHE_INDEX_WIDTH +: CACHE_TAGADR_WIDTH];
	
	
	// slave input
	reg									reg_slave_en;
	reg									reg_slave_we;
	reg		[CACHE_OFFSET_WIDTH-1:0]	reg_slave_offset;
	reg		[CACHE_INDEX_WIDTH-1:0]		reg_slave_index;
	reg		[CACHE_TAGADR_WIDTH-1:0]	reg_slave_tagadr;
	reg		[SLAVE_BLS_WIDTH-1:0]		reg_slave_bls;
	reg		[SLAVE_DATA_WIDTH-1:0]		reg_slave_wdata;
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_slave_en     <= 1'b0;
			reg_slave_we     <= 1'bx;
			reg_slave_offset <= {CACHE_OFFSET_WIDTH{1'bx}};
			reg_slave_index  <= {CACHE_INDEX_WIDTH{1'bx}};
			reg_slave_tagadr <= {CACHE_TAGADR_WIDTH{1'bx}};	
			reg_slave_bls    <= {SLAVE_BLS_WIDTH{1'bx}};
			reg_slave_wdata  <= {SLAVE_DATA_WIDTH{1'bx}};
		end
		else begin
			if ( jbus_slave_en & jbus_slave_ready ) begin
				reg_slave_en     <= jbus_slave_en;
				reg_slave_we     <= jbus_slave_we;
				reg_slave_offset <= jbus_slave_offset;
				reg_slave_index  <= jbus_slave_index;
				reg_slave_tagadr <= jbus_slave_tagadr;
				reg_slave_bls    <= jbus_slave_bls;
				reg_slave_wdata  <= jbus_slave_wdata;
			end
		end            
	end
	
	wire	cache_hit;
	wire	cache_read_miss;
	wire	cache_write_hit;
	assign cache_hit       = (reg_slave_tagadr == ram_read_tagadr);
	assign cache_read_miss = reg_slave_en & !reg_slave_we & !cache_hit;
	assign cache_write_hit = reg_slave_en & reg_slave_we & cache_hit;
	
	parameter	[1:0]	STATE_IDLE = 2'b00, STATE_READ_MISS = 2'b01, STATE_WRITE_MISS = 2'b10;
	
	reg		[1:0]	reg_state;
	reg		[1:0]	next_state;
	
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_state <= STATE_IDLE;
		end
		else begin
			reg_state <= next_state;
		end
	end
	
	always @* begin
		next_state = reg_state;
		case ( next_state )
		STATE_READ_HIT:
			begin
				if ( reg_slave_en & !reg_slave_we & !cache_hit )
			end
			
			
		endcase
	end
	
		
endmodule


// end of file
