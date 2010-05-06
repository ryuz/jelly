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
module jelly_vector_reg
		#(
			parameter	PORT_NUM    = 8,
			parameter	REG_NUM     = 8,
			parameter	INDEX_WIDTH = 4,
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
			parameter	STAGE7_REG = 1
		)
		(
			input	wire								clk,
			input	wire								cke,
			input	wire								reset,
			
			input	wire	[PORT_NUM-1:0]				valid,
			input	wire	[PORT_NUM-1:0]				port,
			input	wire	[PORT_NUM*INDEX_WIDTH-1:0]	index,
			input	wire	[PORT_NUM*WE_WIDTH-1:0]		we,
			input	wire	[PORT_NUM*ADDR_WIDTH-1:0]	addr,
			input	wire	[PORT_NUM*DATA_WIDTH-1:0]	din,
			output	wire	[PORT_NUM*DATA_WIDTH-1:0]	dout	
		);
	
	// stage 0
	wire	[PORT_NUM-1:0]				stage0_in_valid;
	wire	[PORT_NUM-1:0]				stage0_in_port;
	wire	[PORT_NUM*INDEX_WIDTH-1:0]	stage0_in_index;
	wire	[PORT_NUM*WE_WIDTH-1:0]		stage0_in_we;
	wire	[PORT_NUM*ADDR_WIDTH-1:0]	stage0_in_addr;
	wire	[PORT_NUM*DATA_WIDTH-1:0]	stage0_in_din;
	
	wire	[PORT_NUM-1:0]				stage0_out_valid;
	wire	[PORT_NUM-1:0]				stage0_out_port;
	wire	[PORT_NUM*INDEX_WIDTH-1:0]	stage0_out_index;
	wire	[PORT_NUM*WE_WIDTH-1:0]		stage0_out_we;
	wire	[PORT_NUM*ADDR_WIDTH-1:0]	stage0_out_addr;
	wire	[PORT_NUM*DATA_WIDTH-1:0]	stage0_out_din;
	
	assign stage0_in_valid = valid;
	assign stage0_in_port  = port;
	assign stage0_in_index = index;
	assign stage0_in_we    = we;
	assign stage0_in_addr  = addr;
	assign stage0_in_din   = din;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(PORT_NUM*(1+1+INDEX_WIDTH+WE_WIDTH+ADDR_WIDTH+DATA_WIDTH)),
				.REG		(STAGE0_REG)
			)
		i_pipeline_ff_stage0
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
                
				.in_data	({stage0_in_valid,  stage0_in_port,  stage0_in_index,  stage0_in_we,  stage0_in_addr,  stage0_in_din}),
				.out_data	({stage0_out_valid, stage0_out_port, stage0_out_index, stage0_out_we, stage0_out_addr, stage0_out_din})		
			);
	
	// stage 3
	wire	[2*REG_NUM-1:0]				stage3_out_valid;
	wire	[2*REG_NUM*WE_WIDTH-1:0]	stage3_out_we;
	wire	[2*REG_NUM*ADDR_WIDTH-1:0]	stage3_out_addr;
	wire	[2*REG_NUM*DATA_WIDTH-1:0]	stage3_out_din;
		
	// cross bar
	localparam	CROSSBAR_INDEX_WIDTH = 1 + INDEX_WIDTH;
	localparam	CROSSBAR_DATA_WIDTH  = WE_WIDTH + ADDR_WIDTH + DATA_WIDTH;
	
	wire	[PORT_NUM-1:0]							crossbar_in_valid;
	wire	[PORT_NUM*CROSSBAR_INDEX_WIDTH-1:0]		crossbar_in_index;
	wire	[PORT_NUM*CROSSBAR_DATA_WIDTH-1:0]		crossbar_in_data;
	wire	[2*REG_NUM-1:0]							crossbar_out_valid;
	wire	[2*REG_NUM*CROSSBAR_DATA_WIDTH-1:0]		crossbar_out_data;

	jelly_crossbar
			#(
				.DATA_WIDTH			(32),
				.SRC_NUM			(PORT_NUM),
				.DST_NUM			(2*REG_NUM),
				.SRC_INDEX_WIDTH	(CROSSBAR_INDEX_WIDTH),
				.DST_INDEX_WIDTH	(16),
				.STAGE0_REG			(STAGE1_REG),
				.STAGE1_REG			(STAGE2_REG),
				.STAGE2_REG			(STAGE3_REG)
			)
		i_crossbar
			(
				.clk				(clk),
				.cke0				(cke),
				.cke1				(cke),
				.cke2				(cke),
				.reset				(reset),
				
				.in_valid			(crossbar_in_valid),
				.in_dst_index		(crossbar_in_index),
				.in_data			(crossbar_in_data),
			
				.out_valid			(crossbar_out_valid),
				.out_src_index		(),
				.out_data			(crossbar_out_data)
			);
	
	genvar	i;
	generate
	for ( i = 0; i < PORT_NUM; i = i + 1 ) begin : crossbar_in
		assign crossbar_in_index[i*CROSSBAR_INDEX_WIDTH +: CROSSBAR_INDEX_WIDTH] =
				{
					stage0_out_port[i],
					stage0_out_index[i*INDEX_WIDTH +: INDEX_WIDTH]
				};
		assign crossbar_in_data[i*CROSSBAR_DATA_WIDTH +: CROSSBAR_DATA_WIDTH]  =
				{
					stage0_in_we[i*WE_WIDTH +: WE_WIDTH],
					stage0_in_addr[i*ADDR_WIDTH +: ADDR_WIDTH],
					stage0_in_din[i*DATA_WIDTH +: DATA_WIDTH]
				};
	end
	
	for ( i = 0; i < 2*REG_NUM; i = i + 1 ) begin : crossbar_out
		assign stage3_out_valid[i] = crossbar_out_valid[i];
		assign {
					stage3_out_we[i*WE_WIDTH +: WE_WIDTH],
					stage3_out_addr[i*ADDR_WIDTH +: ADDR_WIDTH],
					stage3_out_din[i*DATA_WIDTH +: DATA_WIDTH]
				} = crossbar_out_data[i*CROSSBAR_DATA_WIDTH +: CROSSBAR_DATA_WIDTH];
	end
	endgenerate
	
	
	// stage 6
	wire	[PORT_NUM-1:0]				stage6_out_port;
	wire	[PORT_NUM*INDEX_WIDTH-1:0]	stage6_out_index;
	wire	[REG_NUM*DATA_WIDTH-1:0]	stage6_out_port0_dout;
	wire	[REG_NUM*DATA_WIDTH-1:0]	stage6_out_port1_dout;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(PORT_NUM*(1+INDEX_WIDTH)),
				.REG		(STAGE1_REG+STAGE2_REG+STAGE3_REG+STAGE4_REG+STAGE5_REG+STAGE6_REG)
			)
		i_pipeline_ff_stage3
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
                
				.in_data	({stage0_out_port, stage0_out_index}),
				.out_data	({stage6_out_port, stage6_out_index})		
			);		
	
	generate
	for ( i = 0; i < REG_NUM; i = i + 1 ) begin : dpram
		jelly_dpram_32x512
				#(
					.PORT0_INPUT_REG	(STAGE4_REG),
					.PORT0_MEMORY_REG	(STAGE5_REG),
					.PORT0_OUTPUT_REG	(STAGE6_REG),
					.PORT1_INPUT_REG	(STAGE4_REG),
					.PORT1_MEMORY_REG	(STAGE5_REG),
					.PORT1_OUTPUT_REG	(STAGE6_REG)
				)
			i_dpram_32x512
				(
					.port0_clk			(clk),
					.port0_cke0			(cke),
					.port0_cke1			(cke),
					.port0_cke2			(cke),
					.port0_reset		(reset),			
					.port0_valid		(stage3_out_valid[i]),
					.port0_we			(stage3_out_we[i*WE_WIDTH +: WE_WIDTH]),
					.port0_addr			(stage3_out_addr[i*ADDR_WIDTH +: ADDR_WIDTH]),
					.port0_din			(stage3_out_din[i*DATA_WIDTH +: DATA_WIDTH]),
					.port0_dout			(stage6_out_port0_dout[i*DATA_WIDTH +: DATA_WIDTH]),
					
					.port1_clk			(clk),
					.port1_cke0			(cke),
					.port1_cke1			(cke),
					.port1_cke2			(cke),
					.port1_reset		(reset),
					.port1_valid		(stage3_out_valid[REG_NUM+i]),
					.port1_we			(stage3_out_we[(REG_NUM+i)*WE_WIDTH +: WE_WIDTH]),
					.port1_addr			(stage3_out_addr[(REG_NUM+i)*ADDR_WIDTH +: ADDR_WIDTH]),
					.port1_din			(stage3_out_din[(REG_NUM+i)*DATA_WIDTH +: DATA_WIDTH]),
					.port1_dout			(stage6_out_port1_dout[i*DATA_WIDTH +: DATA_WIDTH])
				);
	end
	endgenerate
	
	// stage7
	wire	[PORT_NUM*DATA_WIDTH-1:0]	stage7_in_dout;
	wire	[PORT_NUM*DATA_WIDTH-1:0]	stage7_out_dout;
	generate
	for ( i = 0; i < PORT_NUM; i = i + 1 ) begin : out_mux
		jelly_multiplexer
				#(
					.SEL_WIDTH		(1+INDEX_WIDTH),
					.NUM			(2*REG_NUM),
					.OUT_WIDTH		(DATA_WIDTH)
				)
			i_multiplexer_output
				(
					.endian			(1'b0),
					.sel			({stage6_out_port[i], stage6_out_index[i*INDEX_WIDTH +: INDEX_WIDTH]}),
					.din			({stage6_out_port1_dout, stage6_out_port0_dout}),
					.dout			(stage7_in_dout[i*DATA_WIDTH +: DATA_WIDTH])
				);
	end
	endgenerate
	
	jelly_pipeline_ff
			#(
				.WIDTH		(PORT_NUM*DATA_WIDTH),
				.REG		(1)
			)
		i_pipeline_ff_stage7
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
                
				.in_data	(stage7_in_dout),
				.out_data	(stage7_out_dout)		
			);
	
	assign dout = stage7_out_dout;
	
endmodule


`default_nettype wire


// end of file
