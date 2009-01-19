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
			parameter							DATA_WIDTH  = 8,
			parameter							ADDR_WIDTH  = 8,
			parameter							MEM_SIZE    = (1 << ADDR_WIDTH),
			parameter							WRITE_FIRST = 0
		)
		(
			input	wire						clk,
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
					dout      <= din;
				end
				else begin
					dout <= mem[addr];
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
				dout <= mem[addr];
			end
		end
	end
	endgenerate
	
endmodule


// End of file
