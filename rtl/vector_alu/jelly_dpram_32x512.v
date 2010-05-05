// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    MIPS like CPU core
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale       1ns / 1ps
`default_nettype none


// pipeline flip-flop
module jelly_dpram_32x512
		#(
			parameter ADDR_WIDTH       = 9,
			parameter DATA_WIDTH       = 32,
			
			parameter PORT0_INPUT_REG  = 0,
			parameter PORT0_MEMORY_REG = 1,
			parameter PORT0_OUTPUT_REG = 0,
			parameter PORT1_INPUT_REG  = 0,
			parameter PORT1_MEMORY_REG = 1,
			parameter PORT1_OUTPUT_REG = 0
		)
		(
			input	wire						port0_clk,
			input	wire						port0_enable,
			input	wire						port0_reset,
			input	wire						port0_valid,
			input	wire						port0_we,
			input	wire	[ADDR_WIDTH-1:0]	port0_addr,
			input	wire	[DATA_WIDTH-1:0]	port0_din,
			output	wire	[DATA_WIDTH-1:0]	port0_dout,
			
			input	wire						port1_clk,
			input	wire						port1_enable,
			input	wire						port1_reset,
			input	wire						port1_valid,
			input	wire						port1_we,
			input	wire	[ADDR_WIDTH-1:0]	port1_addr,
			input	wire	[DATA_WIDTH-1:0]	port1_din,
			output	wire	[DATA_WIDTH-1:0]	port1_dout
		);
	
	
	// input
	wire						port0_in_valid;
	wire						port0_in_we;
	wire	[ADDR_WIDTH-1:0]	port0_in_addr;
	wire	[DATA_WIDTH-1:0]	port0_in_din;
	jelly_pipeline_ff
			#(
				.WIDTH		(1+1+ADDR_WIDTH+DATA_WIDTH),
				.REG		(PORT0_INPUT_REG)
			)
		i_pipeline_ff_port0_input
			(
				.reset		(port0_reset),
				.enable		(port0_enable),
				.clk		(port0_clk),
					
				.in_data	({port0_valid,  port0_we, port0_addr, port0_din}),
				.out_data	({port0_in_valid, port0_in_we, port0_in_addr, port0_in_din})		
			);
	
	wire						port1_in_valid;
	wire						port1_in_we;
	wire	[ADDR_WIDTH-1:0]	port1_in_addr;
	wire	[DATA_WIDTH-1:0]	port1_in_din;
	jelly_pipeline_ff
			#(
				.WIDTH		(1+1+ADDR_WIDTH+DATA_WIDTH),
				.REG		(PORT1_INPUT_REG)
			)
		i_pipeline_ff_port1_input
			(
				.reset		(port1_reset),
				.enable		(port1_enable),
				.clk		(port1_clk),
					
				.in_data	({port1_valid,  port1_we, port1_addr, port1_din}),
				.out_data	({port1_in_valid, port1_in_we, port1_in_addr, port1_in_din})		
			);
	
	
	// output
	wire	[DATA_WIDTH-1:0]	port0_out_dout;
	wire	[DATA_WIDTH-1:0]	port1_out_dout;		jelly_pipeline_ff
			#(
				.WIDTH		(DATA_WIDTH),
				.REG		(PORT0_OUTPUT_REG)
			)
		i_pipeline_ff_port0_output
			(
				.reset		(port0_reset),
				.enable		(port0_enable),
				.clk		(port0_clk),
					
				.in_data	(port0_out_dout),
				.out_data	(port0_dout)
			);
		
	jelly_pipeline_ff
			#(
				.WIDTH		(DATA_WIDTH),
				.REG		(PORT1_OUTPUT_REG)
			)
		i_pipeline_ff_port1_output
			(
				.reset		(port1_reset),
				.enable		(port1_enable),
				.clk		(port1_clk),
					
				.in_data	(port1_out_dout),
				.out_data	(port1_dout)
			);
	
	
	// memory
`ifdef USE_RAMB36
	RAMB36
			#(
				.SIM_MODE				("SAFE"),
				.DOA_REG				((PORT0_OUTPUT_REG > 0)),
				.DOB_REG				((PORT1_OUTPUT_REG > 0)),
				.INIT_A					(36'h000000000),
				.INIT_B					(36'h000000000),
				.RAM_EXTENSION_A		("NONE"),
				.RAM_EXTENSION_B		("NONE"),
				.READ_WIDTH_A			(36),
				.READ_WIDTH_B			(36),
				.SIM_COLLISION_CHECK	("ALL"),
				.SRVAL_A				(36'h000000000),
				.SRVAL_B				(36'h000000000),
				.WRITE_MODE_A			("WRITE_FIRST"),
				.WRITE_MODE_B			("WRITE_FIRST"),
				.WRITE_WIDTH_A			(36),
				.WRITE_WIDTH_B			(36)
			)
		i_ramb36
			(
				.CASCADEOUTLATA			(),
				.CASCADEOUTLATB			(),
				.CASCADEOUTREGA			(),
				.CASCADEOUTREGB			(),
				.DOA					(port0_out_dout), 
				.DOB					(port1_out_dout),
				.DOPA					(),
				.DOPB					(),
				.ADDRA					({1'b0, port0_in_addr, 5'b00000}),
				.ADDRB					({1'b0, port1_in_addr, 5'b00000}),
				.CASCADEINLATA			(1'b0),
				.CASCADEINLATB			(1'b0),
				.CASCADEINREGA			(1'b0),
				.CASCADEINREGB			(1'b0),
				.CLKA					(port0_clk),
				.CLKB					(port1_clk),
				.DIA					(port0_in_din),
				.DIB					(port1_in_din),
				.DIPA					(4'b0000),
				.DIPB					(4'b0000),
				.ENA					(port0_in_valid & port0_enable),
				.ENB					(port1_in_valid & port1_enable),
				.REGCEA					(port0_enable),
				.REGCEB					(port1_enable),
				.SSRA					(port0_reset),
				.SSRB					(port1_reset),
				.WEA					({4{port0_in_we}}),
				.WEB					({4{port1_in_we}})
			);

`else
	wire	[DATA_WIDTH-1:0]	port0_out_dout;
	wire	[DATA_WIDTH-1:0]	port1_out_dout;	
	jelly_ram_dualport
			#(
				.ADDR_WIDTH	(9),
				.DATA_WIDTH	(32),
				.MEM_SIZE	(512)
			)
		i_ram_dualport
			(
				.clk0		(port0_clk),
				.en0		(port0_in_valid & port0_enable),
				.we0		(port0_in_we),
				.addr0		(port0_in_addr),
				.din0		(port0_in_din),
				.dout0		(port0_out_dout),
				
				.clk1		(port1_clk),
				.en1		(port1_in_valid & port1_enable),
				.we1		(port1_in_we),
				.addr1		(port1_in_addr),
				.din1		(port1_in_din),
				.dout1		(port1_out_dout)
			);
`endif

endmodule


/*

`ifdef USE_RAMB16BWER

// pipeline flip-flop
module jelly_dpram_32x512
		#(
			parameter PORT0_REG = 1,
			parameter PORT1_REG = 1
		)
		(
			input	wire					port0_reset,			
			input	wire					port0_clk,
			input	wire					port0_en,
			input	wire					port0_we,
			input	wire	[8:0]			port0_addr,
			input	wire	[31:0]			port0_din,
			output	wire	[31:0]			port0_dout,
			
			input	wire					port1_reset,			
			input	wire					port1_clk,
			input	wire					port1_en,
			input	wire					port1_we,
			input	wire	[8:0]			port1_addr,
			input	wire	[31:0]			port1_din,
			output	wire	[31:0]			port1_dout
		);
	
	
	RAMB16BWER
			#(
				.DATA_WIDTH_A		(36),
				.DATA_WIDTH_B		(36),	
				.DOA_REG			(PORT0_REG),
				.DOB_REG			(PORT1_REG),
				.EN_RSTRAM_A		("TRUE"),
				.EN_RSTRAM_B		("TRUE"),
				.INIT_A				(36'h0),
				.INIT_B				(36'h0),
				.INIT_FILE			("NONE"),
				.RSTTYPE			("SYNC"),
				.RST_PRIORITY_A		("CE"),
				.RST_PRIORITY_B		("CE"),
				.SIM_COLLISION_CHECK("ALL"),
				.SRVAL_A			(36'h0),
				.SRVAL_B			(36'h0),
				.WRITE_MODE_A		("WRITE_FIRST"),
				.WRITE_MODE_B		("WRITE_FIRST")
			)
		i_ramb16bwer
			(
				.DOA				(port0_dout),
				.DOB				(port1_dout),
				.DOPA				(),
				.DOPB				(),
				
				.ADDRA				({port0_addr, 5'b00000}),
				.ADDRB				({port1_addr, 5'b00000}),
				.CLKA				(port0_clk),
				.CLKB				(port1_clk),
				.DIA				(port0_din),
				.DIB				(port1_din),
				.DIPA				(4'b0000),
				.DIPB				(4'b0000),
				.ENA				(port0_en),
				.ENB				(port1_en),
				.REGCEA				(port0_en),
				.REGCEB				(port1_en),
				.RSTA				(port0_reset),
				.RSTB				(port1_reset),
				.WEA				({4{port0_we}}),
				.WEB				({4{port1_we}})
			);
	
endmodule

`else

// pipeline flip-flop
module jelly_dpram_32x512
		#(
			parameter ADDR_WIDTH       = 9,
			parameter DATA_WIDTH       = 32,
			
			parameter PORT0_INPUT_REG  = 0,
			parameter PORT0_OUTPUT_REG = 0,
			parameter PORT1_INPUT_REG  = 0,
			parameter PORT1_OUTPUT_REG = 0
		)
		(
			input	wire						port0_clk,
			input	wire						port0_enable,
			input	wire						port0_reset,
			input	wire						port0_valid,
			input	wire						port0_we,
			input	wire	[ADDR_WIDTH-1:0]	port0_addr,
			input	wire	[DATA_WIDTH-1:0]	port0_din,
			output	wire	[DATA_WIDTH-1:0]	port0_dout,
			
			input	wire						port1_clk,
			input	wire						port1_enable,
			input	wire						port1_reset,
			input	wire						port1_valid,
			input	wire						port1_we,
			input	wire	[ADDR_WIDTH-1:0]	port1_addr,
			input	wire	[DATA_WIDTH-1:0]	port1_din,
			output	wire	[DATA_WIDTH-1:0]	port1_dout
		);
		
	// input
	wire						port0_in_valid;
	wire						port0_in_we;
	wire	[ADDR_WIDTH-1:0]	port0_in_addr;
	wire	[DATA_WIDTH-1:0]	port0_in_din;
	jelly_pipeline_ff
			#(
				.WIDTH		(1+1+ADDR_WIDTH+DATA_WIDTH),
				.REG		(PORT0_INPUT_REG)
			)
		i_pipeline_ff_port0_input
			(
				.reset		(port0_reset),
				.enable		(port0_enable),
				.clk		(port0_clk),
					
				.in_data	({port0_valid,  port0_we, port0_addr, port0_din}),
				.out_data	({port0_in_valid, port0_in_we, port0_in_addr, port0_in_din})		
			);
		
	wire						port1_in_valid;
	wire						port1_in_we;
	wire	[ADDR_WIDTH-1:0]	port1_in_addr;
	wire	[DATA_WIDTH-1:0]	port1_in_din;
	jelly_pipeline_ff
			#(
				.WIDTH		(1+1+ADDR_WIDTH+DATA_WIDTH),
				.REG		(PORT1_INPUT_REG)
			)
		i_pipeline_ff_port1_input
			(
				.reset		(port1_reset),
				.enable		(port1_enable),
				.clk		(port1_clk),
					
				.in_data	({port1_valid,  port1_we, port1_addr, port1_din}),
				.out_data	({port1_in_valid, port1_in_we, port1_in_addr, port1_in_din})		
			);
	
	
	// memory
	wire	[DATA_WIDTH-1:0]	port0_out_dout;
	wire	[DATA_WIDTH-1:0]	port1_out_dout;	
	jelly_ram_dualport
			#(
				.ADDR_WIDTH	(9),
				.DATA_WIDTH	(32),
				.MEM_SIZE	(512)
			)
		i_ram_dualport
			(
				.clk0		(port0_clk),
				.en0		(port0_in_valid & port0_enable),
				.we0		(port0_in_we),
				.addr0		(port0_in_addr),
				.din0		(port0_in_din),
				.dout0		(port0_out_dout),
				
				.clk1		(port1_clk),
				.en1		(port1_in_valid & port1_enable),
				.we1		(port1_in_we),
				.addr1		(port1_in_addr),
				.din1		(port1_in_din),
				.dout1		(port1_out_dout)
			);
	
			
	// output
	jelly_pipeline_ff
			#(
				.WIDTH		(DATA_WIDTH),
				.REG		(PORT0_OUTPUT_REG)
			)
		i_pipeline_ff_port0_output
			(
				.reset		(port0_reset),
				.enable		(port0_enable),
				.clk		(port0_clk),
					
				.in_data	(port0_out_dout),
				.out_data	(port0_dout)
			);
		
	jelly_pipeline_ff
			#(
				.WIDTH		(DATA_WIDTH),
				.REG		(PORT1_OUTPUT_REG)
			)
		i_pipeline_ff_port1_output
			(
				.reset		(port1_reset),
				.enable		(port1_enable),
				.clk		(port1_clk),
					
				.in_data	(port1_out_dout),
				.out_data	(port1_dout)
			);

endmodule

`endif
*/


`default_nettype wire


// end of file
