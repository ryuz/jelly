// ---------------------------------------------------------------------------
//  Common components
//   Singleport-RAM
//
//                                 Copyright (C) 2007-2009 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps



// Singleport-RAM
module ram_singleport_xilinx
		#(
			parameter							DATA_WIDTH  = 8,
			parameter							ADDR_WIDTH  = 8,
			parameter							MEM_SIZE    = (1 << ADDR_WIDTH),
			parameter							WRITE_FIRST = 0,
			parameter							ARCHITECTURE = "Spartan-3"
		)
		(
			input	wire						clk,
			input	wire						en,
			input	wire						we,
			input	wire	[ADDR_WIDTH-1:0]	addr,
			input	wire	[DATA_WIDTH-1:0]	wdata,
			output	reg		[DATA_WIDTH-1:0]	rdata
		);
	
	parameter	WRITE_MODE = "WRITE_FIRST";
	
	generate
	genvar	i;
	genvar	j;
	if ( DATA_WIDTH <= 1 ) begin
		for ( i = 0; i*16384 < MEM_SIZE; i = i+1 ) begin : s1
			RAMB16_S1
					#(
						.WRITE_MODE		(WRITE_MODE)
					)
				i_ramb16_s1
					(
						.DO				(rdata[0:0]),
						.ADDR			(addr[13:0]),
						.CLK			(clk),
						.DI				(wdata[0:0]),
						.EN				(en & ((addr >> 14) == i)),
						.SSR			(1'b0),
						.WE				(we)
					);
		end
	end
	if ( DATA_WIDTH <= 8 ) begin
		for ( i = 0; i*16384 < MEM_SIZE; i = i+1 ) begin : s1
			RAMB16_S1
					#(
						.WRITE_MODE		(WRITE_MODE)
					)
				i_ramb16_s1
					(
						.DO				(rdata[0:0]),
						.ADDR			(addr[13:0]),
						.CLK			(clk),
						.DI				(wdata[0:0]),
						.EN				(en & ((addr >> 14) == i)),
						.SSR			(1'b0),
						.WE				(we)
					);
		end
	end
	
	
	RAMB16_S2
	RAMB16_S4
	RAMB16_S9
	RAMB16_S18
	RAMB16_S36
	
	
	
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
