// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   Singleport-RAM
//
//                                 Copyright (C) 2007-2009 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps



// Singleport-RAM
module jelly_ram_singleport
		#(
			parameter	ADDR_WIDTH   = 8,
			parameter	DATA_WIDTH   = 8,
			parameter	MEM_SIZE     = (1 << ADDR_WIDTH),
			parameter	RAM_TYPE     = "block",
			parameter	DOUT_REGS    = 0,
			parameter	MODE         = "WRITE_FIRST",
			
			parameter	FILLMEM      = 0,
			parameter	FILLMEM_DATA = 0,
			parameter	READMEMB     = 0,
			parameter	READMEMH     = 0,
			parameter	READMEM_FILE = ""
		)
		(
			input	wire						clk,
			input	wire						en,
			input	wire						regcke,
			input	wire						we,
			input	wire	[ADDR_WIDTH-1:0]	addr,
			input	wire	[DATA_WIDTH-1:0]	din,
			output	wire	[DATA_WIDTH-1:0]	dout
		);
	
	// memory
	(* ram_style = RAM_TYPE *)
	reg		[DATA_WIDTH-1:0]	mem	[0:MEM_SIZE-1];
	
	reg		[DATA_WIDTH-1:0]	tmp_dout;
	
	generate
	if ( MODE == "WRITE_FIRST" ) begin
		// write first
		always @ ( posedge clk ) begin
			if ( en ) begin
				if ( we ) begin
					mem[addr] <= din;
				end
				
				if ( we ) begin
					tmp_dout <= din;
				end
				else begin
					tmp_dout <= mem[addr];
				end
			end
		end
	end
	else begin
		// read first
		always @ ( posedge clk ) begin
			if ( en ) begin
				if ( we ) begin
					mem[addr] <= din;
				end
				tmp_dout <= mem[addr];
			end
		end
	end
	
	// DOUT FF insert
	if ( DOUT_REGS ) begin
		reg		[DATA_WIDTH-1:0]	reg_dout;
		always @(posedge clk) begin
			if ( regcke ) begin
				reg_dout <= tmp_dout;
			end
		end
		assign dout = reg_dout;
	end
	else begin
		assign dout = tmp_dout;
	end
	endgenerate
	
	
`ifndef ALTERA
	// initialize
	integer	i;
	initial begin
		if ( FILLMEM ) begin
			for ( i = 0; i < MEM_SIZE; i = i + 1 ) begin
				mem[i] = FILLMEM_DATA;
			end
		end
		
		if ( READMEMB ) begin
			$readmemb(READMEM_FILE, mem);
		end
		if ( READMEMH ) begin
			$readmemh(READMEM_FILE, mem);
		end
	end
`endif
	
endmodule


// End of file
