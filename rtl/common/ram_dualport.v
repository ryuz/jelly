// ---------------------------------------------------------------------------
//  Common components
//   Dualport-RAM
//
//                                 Copyright (C) 2007-2008 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// Dualport-RAM
module ram_dualport
		#(
			parameter							DATA_WIDTH = 8,
			parameter							ADDR_WIDTH = 8,
			parameter							MEM_SIZE   = (1 << ADDR_WIDTH)
		)
		(
			// port0
			input	wire						clk0,
			input	wire						en0,
			input	wire						we0,
			input	wire	[ADDR_WIDTH-1:0]	addr0,
			input	wire	[DATA_WIDTH-1:0]	din0,
			output	reg		[DATA_WIDTH-1:0]	dout0,
			
			// port1
			input	wire						clk1,
			input	wire						en1,
			input	wire						we1,
			input	wire	[ADDR_WIDTH-1:0]	addr1,
			input	wire	[DATA_WIDTH-1:0]	din1,
			output	reg		[DATA_WIDTH-1:0]	dout1
		);
	
	// memory
	reg		[DATA_WIDTH-1:0]	mem	[0:MEM_SIZE-1];
	
	
	// port0
	always @ ( posedge clk0 ) begin
		if ( en0 ) begin
			if ( we0 ) begin
				mem[addr0] <= din0;
			end
			dout0 <= mem[addr0];
		end
	end
	
	// port1
	always @ ( posedge clk1 ) begin
		if ( en1 ) begin
			if ( we1 ) begin
				mem[addr1] <= din1;
			end
			dout1 <= mem[addr1];
		end
	end
	
endmodule


// End of file
