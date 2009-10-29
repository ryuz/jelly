// ---------------------------------------------------------------------------
//  Common components
//   Singleport-RAM
//
//                                 Copyright (C) 2007-2009 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps



// Singleport-RAM
(* ram_style = "block" *)
module jelly_ram_singleport
		#(
			parameter							ADDR_WIDTH   = 8,
			parameter							DATA_WIDTH   = 8,
			parameter							MEM_SIZE     = (1 << ADDR_WIDTH),
			parameter							WRITE_FIRST  = 0,
			parameter							INIT_DOUT    = 0,
			
			parameter							FILLMEM      = 0,
			parameter							FILLMEM_DATA = 0,
			parameter							READMEMB     = 0,
			parameter							READMEMH     = 0,
			parameter	[128*8:1]				READMEM_FIlE = ""
		)
		(
			input	wire						clk,
			input	wire						reset,
			input	wire						en,
			input	wire						we,
			input	wire	[ADDR_WIDTH-1:0]	addr,
			input	wire	[DATA_WIDTH-1:0]	din,
			output	reg		[DATA_WIDTH-1:0]	dout
		);
	
	// memory
	reg		[DATA_WIDTH-1:0]	mem	[0:MEM_SIZE-1];
	
	
	generate
	if ( WRITE_FIRST ) begin
		// write first
		always @ ( posedge clk ) begin
			if ( en ) begin
				if ( we ) begin
					mem[addr] <= din;
				end
				
				if ( reset ) begin
					dout <= INIT_DOUT;
				end
				else begin
					if ( we ) begin
						dout <= din;
					end
					else begin
						dout <= mem[addr];
					end
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
				
				if ( reset ) begin
					dout <= INIT_DOUT;
				end
				else begin
					dout <= mem[addr];
				end
			end
		end
	end
	endgenerate
	
	// initialize
	integer	i;
	initial begin
		if ( FILLMEM ) begin
			for ( i = 0; i < MEM_SIZE; i = i + 1 ) begin
				mem[i] = FILLMEM_DATA;
			end
		end

		if ( READMEMB ) begin
			$readmemb(READMEM_FIlE, mem);
		end
		if ( READMEMH ) begin
			$readmemh(READMEM_FIlE, mem);
		end
	end
		
endmodule


// End of file
