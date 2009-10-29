// ---------------------------------------------------------------------------
//  Jelly -- The computing system for Spartan-3 Starter Kit
//
//                                 Copyright (C) 2008-2009 by Ryuji Fuchikami 
//                                 http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly_bus_cahce
		#(
			parameter	LINE_SIZE         = 2,		// 2^n (0:1words, 1:2words, 2:4words ...)
			parameter	ARRAY_SIZE        = 8,		// 2^n (1:2lines, 2:4lines 3:8lines ...)
			parameter	LINE_WORDS        = (1 << LINE_SIZE),
			
			parameter	SLAVE_ADDR_WIDTH  = 24,
			parameter	SLAVE_DATA_SIZE   = 2,		// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			parameter	SLAVE_DATA_WIDTH  = (8 << SLAVE_DATA_SIZE),
			parameter	SLAVE_BLS_WIDTH   = (1 << SLAVE_DATA_SIZE),
			
			parameter	MASTER_ADDR_WIDTH = SLAVE_ADDR_WIDTH - LINE_SIZE,
			parameter	MASTER_DATA_SIZE  = SLAVE_DATA_SIZE + LINE_SIZE,
			parameter	MASTER_DATA_WIDTH = (8 << MASTER_DATA_SIZE),
			parameter	MASTER_BLS_WIDTH  = (1 << MASTER_DATA_SIZE),
						
			parameter	CACHE_OFFSET_WIDTH = LINE_SIZE,
			parameter	CACHE_INDEX_WIDTH  = ARRAY_SIZE,
			parameter	CACHE_TAGADR_WIDTH = SLAVE_ADDR_WIDTH - (CACHE_INDEX_WIDTH + CACHE_OFFSET_WIDTH),
			parameter	CACHE_DATA_WIDTH   = MASTER_DATA_WIDTH,

			parameter	RAM_ADDR_WIDTH     = CACHE_INDEX_WIDTH,
			parameter	RAM_DATA_WIDTH     = 1 + CACHE_TAGADR_WIDTH + CACHE_DATA_WIDTH
		)
		(
			// system
			input	wire							clk,
			input	wire							reset,
			input	wire							endian,
			
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
	assign ram_read_data   = ram_rdata[CACHE_DATA_WIDTH-1:0];
	assign ram_read_tagadr = ram_rdata[CACHE_DATA_WIDTH +: CACHE_TAGADR_WIDTH];
	assign ram_read_valid  = ram_rdata[RAM_DATA_WIDTH-1];
	
	
	// slave address assign
	wire	[CACHE_OFFSET_WIDTH-1:0]	jbus_slave_offset;
	wire	[CACHE_INDEX_WIDTH-1:0]		jbus_slave_index;
	wire	[CACHE_TAGADR_WIDTH-1:0]	jbus_slave_tagadr;
	assign jbus_slave_offset = jbus_slave_addr[0                                      +: CACHE_OFFSET_WIDTH];
	assign jbus_slave_index  = jbus_slave_addr[CACHE_OFFSET_WIDTH                     +: CACHE_INDEX_WIDTH];
	assign jbus_slave_tagadr = jbus_slave_addr[CACHE_OFFSET_WIDTH + CACHE_INDEX_WIDTH +: CACHE_TAGADR_WIDTH];
	
	
	// slave input
	reg									reg_slave_re;
	reg									reg_slave_we;
	reg		[CACHE_OFFSET_WIDTH-1:0]	reg_slave_offset;
	reg		[CACHE_INDEX_WIDTH-1:0]		reg_slave_index;
	reg		[CACHE_TAGADR_WIDTH-1:0]	reg_slave_tagadr;
	reg		[SLAVE_BLS_WIDTH-1:0]		reg_slave_bls;
	reg		[SLAVE_DATA_WIDTH-1:0]		reg_slave_wdata;
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_slave_re     <= 1'b0;
			reg_slave_we     <= 1'b0;
			reg_slave_offset <= {CACHE_OFFSET_WIDTH{1'bx}};
			reg_slave_index  <= {CACHE_INDEX_WIDTH{1'bx}};
			reg_slave_tagadr <= {CACHE_TAGADR_WIDTH{1'bx}};	
			reg_slave_bls    <= {SLAVE_BLS_WIDTH{1'bx}};
			reg_slave_wdata  <= {SLAVE_DATA_WIDTH{1'bx}};
		end
		else begin
			if ( /*jbus_slave_en &*/ jbus_slave_ready ) begin
				reg_slave_re     <= jbus_slave_en & !jbus_slave_we;
				reg_slave_we     <= jbus_slave_en & jbus_slave_we;
				reg_slave_offset <= jbus_slave_offset;
				reg_slave_index  <= jbus_slave_index;
				reg_slave_tagadr <= jbus_slave_tagadr;
				reg_slave_bls    <= jbus_slave_bls;
				reg_slave_wdata  <= jbus_slave_wdata;
			end
		end
	end
	
	// hit test
	wire	cache_hit;
	wire	cache_read_miss;
	wire	cache_write_hit;
	reg		reg_write_hit_end;
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_write_hit_end <= 1'b0;
		end
		else begin
			if ( reg_write_hit_end ) begin
				if ( jbus_master_ready ) begin
					reg_write_hit_end <= 1'b0;
				end
			end
			else begin
				reg_write_hit_end <= cache_write_hit;
			end
		end
	end
	
	assign cache_hit       = ram_read_valid & (reg_slave_tagadr == ram_read_tagadr);
	assign cache_read_miss = reg_slave_re & !cache_hit;
	assign cache_write_hit = reg_slave_we & cache_hit & !reg_write_hit_end;
	
	
	// cahce read
	wire	[SLAVE_DATA_WIDTH-1:0]	cache_rdata;
	jelly_multiplexer
			#(
				.SEL_WIDTH		(CACHE_OFFSET_WIDTH),
				.OUT_WIDTH		(SLAVE_DATA_WIDTH)
			)
		i_multiplexer
			(
				.endian			(endian),
				.sel			(reg_slave_offset),
				.din			(ram_read_data),
				.dout			(cache_rdata)
			);
	
	// write bls
	wire	[MASTER_BLS_WIDTH-1:0]		write_bls;
	wire	[MASTER_DATA_WIDTH-1:0]		write_data_mask;
	wire	[MASTER_DATA_WIDTH-1:0]		write_data;
	
	jelly_demultiplexer
			#(
				.SEL_WIDTH		(CACHE_OFFSET_WIDTH),
				.IN_WIDTH		(SLAVE_BLS_WIDTH)
			)
		i_demultiplexer_bls
			(
				.endian			(endian),
				.sel			(reg_slave_offset),
				.din			(reg_slave_bls),
				.dout			(write_bls)
			);
	
	jelly_deselector
			#(
				.SEL_WIDTH		(MASTER_BLS_WIDTH),
				.IN_WIDTH		(8)
			)
		i_deselector_bls_mask
			(
				.sel			(write_bls),
				.din			(8'hff),
				.dout			(write_data_mask)
			);
	
	assign write_data = {LINE_WORDS{reg_slave_wdata}};
	
	
	// read end monitor
	wire			read_end;
	reg				reg_read_busy;
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_read_busy <= 1'b0;
		end
		else begin
			if ( jbus_slave_ready ) begin
				reg_read_busy <= jbus_master_en & !jbus_master_we;
			end
		end
	end
	assign read_end  = reg_read_busy & jbus_master_ready;
	
	
	// master output
	reg									reg_master_en;
	reg									reg_master_we;
	reg		[MASTER_ADDR_WIDTH-1:0]		reg_master_addr;
	reg		[MASTER_BLS_WIDTH-1:0]		reg_master_bls;
	reg		[MASTER_DATA_WIDTH-1:0]		reg_master_wdata;
	
	reg									reg_master_read;
	
	wire								jbus_master_busy;
	assign jbus_master_busy = (jbus_master_en & !jbus_master_ready) | reg_master_read;
	
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_master_en    <= 1'b0;
			reg_master_we    <= 1'bx;
			reg_master_addr  <= {MASTER_ADDR_WIDTH{1'bx}};
			reg_master_bls   <= {MASTER_BLS_WIDTH{1'bx}};
			reg_master_wdata <= {MASTER_DATA_WIDTH{1'bx}};
			reg_master_read  <= 1'b0;
		end
		else begin
			if ( !jbus_master_busy ) begin
				reg_master_read <= cache_read_miss;
			end
			else if ( read_end ) begin
				reg_master_read <= 1'b0;
			end
			
			if ( !jbus_master_busy ) begin
				reg_master_en    <= (reg_slave_we & !reg_write_hit_end) | cache_read_miss;
				reg_master_we    <= reg_slave_we;
				reg_master_addr  <= {reg_slave_tagadr, reg_slave_index};
				reg_master_bls   <= write_bls;
				reg_master_wdata <= {LINE_WORDS{reg_slave_wdata}};
			end
			else begin
				if ( jbus_master_ready ) begin
					reg_master_en <= 1'b0;
				end
				if ( read_end ) begin
					reg_master_read  <= 1'b0;
				end
			end
		end
	end
	
	assign jbus_master_en    = reg_master_en;
	assign jbus_master_we    = reg_master_we;
	assign jbus_master_addr  = reg_master_addr;
	assign jbus_master_bls   = reg_master_bls;
	assign jbus_master_wdata = reg_master_wdata;
	
	assign ram_en            = read_end | cache_write_hit | (jbus_slave_en & jbus_slave_ready);
	assign ram_we            = read_end | cache_write_hit;
	assign ram_addr          = ram_we ? reg_slave_index : jbus_slave_index;
	assign ram_write_valid   = 1'b1;
	assign ram_write_tagadr  = reg_slave_tagadr;
	assign ram_write_data    = read_end ? jbus_master_rdata : ((write_data_mask & write_data) | (~write_data_mask & ram_read_data));
	
	assign jbus_slave_rdata  = cache_rdata;
	assign jbus_slave_ready  = !((reg_master_en & !jbus_master_ready) | cache_read_miss | cache_write_hit);
	
endmodule


// end of file
