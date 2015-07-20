// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



module jelly_wishbone_slave_model
		#(
			parameter	ADR_WIDTH = 12,
			parameter	DAT_SIZE  = 2,		// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			parameter	DAT_WIDTH = (8 << DAT_SIZE),
			parameter	SEL_WIDTH = (1 << DAT_SIZE),
			parameter	MEM_WIDTH = (1 << ADR_WIDTH),
			parameter	RAND_BUSY = 1
		)
		(
			// system
			input	wire						clk,
			input	wire						reset,

			// wishbone
			input	wire	[ADR_WIDTH-1:0]		wb_slave_adr_i,
			output	wire	[DAT_WIDTH-1:0]		wb_slave_dat_o,
			input	wire	[DAT_WIDTH-1:0]		wb_slave_dat_i,
			input	wire						wb_slave_we_i,
			input	wire	[SEL_WIDTH-1:0]		wb_slave_sel_i,
			input	wire						wb_slave_stb_i,
			output	wire						wb_slave_ack_o			
		);
	
	generate
	genvar	i;
	for ( i = 0; i < SEL_WIDTH; i = i + 1 ) begin : bls
		reg		[7:0]	mem		[0:MEM_WIDTH-1];
		always @( posedge clk ) begin
			if ( wb_slave_stb_i & wb_slave_ack_o ) begin
				if ( wb_slave_we_i ) begin
					if ( wb_slave_sel_i[i] ) begin
						mem[wb_slave_adr_i] <= wb_slave_dat_i[i*8 +: 8];
					end
				end
			end
		end
		
		assign wb_slave_dat_o[i*8 +: 8] = (wb_slave_stb_i & !wb_slave_we_i & wb_slave_ack_o) ? mem[wb_slave_adr_i] : 8'hxx;
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
	
	assign wb_slave_ack_o = wb_slave_stb_i & (RAND_BUSY & rand);
	
	
endmodule


// end of file
