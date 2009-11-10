// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    block sram interface
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



module jelly_jbus_to_ram
		#(
			parameter	ADDR_WIDTH  = 12,
			parameter	DATA_WIDTH  = 32,
			parameter	SEL_WIDTH   = (DATA_WIDTH / 8)
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			// jelly bus
			input	wire						jbus_en,
			input	wire	[ADDR_WIDTH-1:0]	jbus_addr,
			input	wire	[DATA_WIDTH-1:0]	jbus_wdata,
			output	wire	[DATA_WIDTH-1:0]	jbus_rdata,
			input	wire						jbus_we,
			input	wire	[SEL_WIDTH-1:0]		jbus_sel,
			input	wire						jbus_valid,
			output	wire						jbus_ready,
			
			// ram
			output	wire						ram_en,
			output	wire						ram_we,
			output	wire	[ADDR_WIDTH-1:0]	ram_addr,
			output	wire	[DATA_WIDTH-1:0]	ram_wdata,
			input	wire	[DATA_WIDTH-1:0]	ram_rdata
		);
	
	// write control
	reg							reg_we;
	reg		[ADDR_WIDTH-1:0]	reg_addr;
	reg		[SEL_WIDTH-1:0]		reg_sel;
	reg		[DATA_WIDTH-1:0]	reg_wdata;
	always @( posedge clk ) begin
		if ( reset ) begin
			reg_we    <= 1'b0;
			reg_sel   <= {SEL_WIDTH{1'bx}};
			reg_wdata <= {DATA_WIDTH{1'bx}};
		end
		else begin
			if ( jbus_en & jbus_ready ) begin
				reg_we    <= jbus_valid & jbus_we;
				reg_addr  <= jbus_addr;
				reg_sel   <= jbus_sel;
				reg_wdata <= jbus_wdata;
			end
			else begin
				reg_we    <= 1'b0; 
			end
		end
	end
	
	// write mask
	function [DATA_WIDTH-1:0] make_write_mask;
	input	[SEL_WIDTH-1:0]	sel;
	integer					i, j;
	begin
		for ( i = 0; i < SEL_WIDTH; i = i + 1 ) begin
			for ( j = 0; j < 8; j = j + 1 ) begin
				make_write_mask[i*8 + j] = sel[i];
			end
		end
	end
	endfunction
	
	wire	[DATA_WIDTH-1:0]	write_mask;
	assign write_mask = make_write_mask(reg_sel);
	
	assign jbus_rdata = ram_rdata;
	assign jbus_ready = !(jbus_valid & reg_we);
	
	assign ram_en     = (jbus_en & jbus_valid) | reg_we;
	assign ram_we     = reg_we;
	assign ram_addr   = reg_we ? reg_addr : jbus_addr;
	assign ram_wdata  = (ram_rdata & ~write_mask) | (reg_wdata & write_mask);
	
endmodule


// end of file
