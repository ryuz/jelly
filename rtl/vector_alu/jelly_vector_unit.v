// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    MIPS like CPU core
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale       1ns / 1ps
`default_nettype none


// Arithmetic Logic Unit
module jelly_vector_unit
		#(
			parameter	PORT_NUM    = 2,
			parameter	REG_NUM     = 8,
			parameter	INDEX_WIDTH = 3,
			parameter	WE_WIDTH    = 1,
			parameter	ADDR_WIDTH  = 9,
			parameter	DATA_WIDTH  = 32,
			
			parameter	STAGE0_REG = 1,
			parameter	STAGE1_REG = 1,
			parameter	STAGE2_REG = 1,
			parameter	STAGE3_REG = 1,
			parameter	STAGE4_REG = 1,
			parameter	STAGE5_REG = 1,
			parameter	STAGE6_REG = 1,
			parameter	STAGE7_REG = 1,
			parameter	STAGE8_REG = 1
		)
		(
			input	wire				clk,
			input	wire				cke,
			input	wire				reset,
			
			input	wire	[31:2]		wb_adr_i,
			input	wire	[31:0]		wb_dat_i,
			output	wire	[31:0]		wb_dat_o,
			input	wire	[3:0]		wb_sel_i,
			input	wire				wb_we_i,
			input	wire				wb_stb_i,
			output	wire				wb_ack_o
		);
	
	
	
	
	
	
	
endmodule


`default_nettype wire


// end of file
