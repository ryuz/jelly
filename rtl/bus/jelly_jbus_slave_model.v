// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


module jbus_slave_model
		#(
			parameter	ADDR_WIDTH = 12,
			parameter	DATA_SIZE  = 2,		// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			parameter	DATA_WIDTH = (8 << DATA_SIZE),
			parameter	BLS_WIDTH  = (1 << DATA_SIZE),
			parameter	MEM_WIDTH  = (1 << ADDR_WIDTH)
		)
		(
			// system
			input	wire						clk,
			input	wire						reset,
			
			// slave port
			input	wire						jbus_slave_en,
			input	wire						jbus_slave_we,
			input	wire	[ADDR_WIDTH-1:0]	jbus_slave_addr,
			input	wire	[BLS_WIDTH-1:0]		jbus_slave_bls,
			input	wire	[DATA_WIDTH-1:0]	jbus_slave_wdata,
			output	reg		[DATA_WIDTH-1:0]	jbus_slave_rdata,
			output	wire						jbus_slave_ready
		);
	
	generate
	genvar	i;
	for ( i = 0; i < BLS_WIDTH; i = i + 1 ) begin : bls
		reg		[7:0]	mem		[0:MEM_WIDTH-1];
		always @( posedge clk ) begin
			if ( jbus_slave_en & jbus_slave_ready ) begin
				if ( jbus_slave_we ) begin
					if ( jbus_slave_bls[i] ) begin
						mem[jbus_slave_addr] <= jbus_slave_wdata[i*8 +: 8];
					end
					jbus_slave_rdata[i*8 +: 8] <= 8'hxx;
				end
				else begin
					jbus_slave_rdata[i*8 +: 8] <= mem[jbus_slave_addr];
				end
			end
		end
	end
	endgenerate

	wire	rand;
	jelly_rand_gen
		i_rand_gen
			(
				.clk		(clk),
				.reset		(reset),
				.seed		(16'h1234),
				.out		(rand)
			);
//	assign jbus_slave_ready = rand;
	assign jbus_slave_ready = 1'b1;
	
	
endmodule


// end of file
