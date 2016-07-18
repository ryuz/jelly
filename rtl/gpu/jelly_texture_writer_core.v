// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// FIFO
module jelly_texture_writer_core
		#(
			parameter	COMPONENT_NUM        = 3,
			parameter	COMPONENT_DATA_WIDTH = 8,
			
			parameter	S_AXI4S_DATA_WIDTH   = COMPONENT_NUM * COMPONENT_DATA_WIDTH,
			
			parameter	M_AXI4_ID_WIDTH      = 6,
			parameter	M_AXI4_ADDR_WIDTH    = 32,
			parameter	M_AXI4_DATA_SIZE     = 3,		// 8^n (0:8bit, 1:16bit, 2:32bit, 3:64bit, ...)
			parameter	M_AXI4_DATA_WIDTH    = (8 << M_AXI4_DATA_SIZE),
			
			parameter	BLK_X_SIZE           = 3,		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
			parameter	BLK_Y_SIZE           = 3,		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
			parameter	STEP_Y_SIZE          = 1,		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
			
			parameter	X_WIDTH              = 10,
			parameter	Y_WIDTH              = 10,
			
			parameter	STRIDE_WIDTH         = SRC_STRIDE_WIDTH + BLK_Y_SIZE,
			parameter	SIZE_WIDTH           = 24,
			
			parameter	FIFO_PTR_WIDTH       = 10,
			parameter	FIFO_RAM_TYPE        = "block"
		)
		(
			input	wire								reset,
			input	wire								clk,
			
			input	wire								endian,
			
			input	wire	[X_WIDTH-1:0]				param_width,
			input	wire	[Y_WIDTH-1:0]				param_height,
			input	wire	[STRIDE_WIDTH-1:0]			param_stride,
			
			input	wire	[0:0]						s_axi4s_tuser,
			input	wire								s_axi4s_tlast,
			input	wire	[S_AXI4S_DATA_WIDTH-1:0]	s_axi4s_tdata,
			input	wire								s_axi4s_tvalid,
			output	wire								s_axi4s_tready
		);
	
	
	// ---------------------------------
	//  common
	// ---------------------------------
	
	genvar		i, j;
	
	localparam	COMPONENT_SIZE      = COMPONENT_DATA_WIDTH <=   8 ? 0 :
	                                  COMPONENT_DATA_WIDTH <=  16 ? 1 :
	                                  COMPONENT_DATA_WIDTH <=  32 ? 2 :
	                                  COMPONENT_DATA_WIDTH <=  64 ? 3 :
	                                  COMPONENT_DATA_WIDTH <= 128 ? 4 :
	                                  COMPONENT_DATA_WIDTH <= 256 ? 5 :
	                                  COMPONENT_DATA_WIDTH <= 512 ? 6 : 7;
	
	localparam	COMPONENT_SEL_WIDTH = COMPONENT_NUM        <=   2 ? 1 :
	                                  COMPONENT_NUM        <=   4 ? 2 :
	                                  COMPONENT_NUM        <=   8 ? 3 :
	                                  COMPONENT_NUM        <=  16 ? 4 :
	                                  COMPONENT_NUM        <=  32 ? 5 :
	                                  COMPONENT_NUM        <=  64 ? 6 : 7;
	
	
	localparam	CNV_DATA_WIDTH      = COMPONENT_NUM*M_AXI4_DATA_WIDTH;
	localparam	CNV_SIZE            = (M_AXI4_DATA_SIZE - COMPONENT_SIZE);
	localparam	CNV_NUM             = (1 << (M_AXI4_DATA_SIZE - COMPONENT_SIZE));
	
	
	// ---------------------------------
	//  width convert
	// ---------------------------------
	
	wire							cnv_tlast;
	wire	[CNV_DATA_WIDTH-1:0]	cnv_tdata_tmp;
	wire	[CNV_DATA_WIDTH-1:0]	cnv_tdata;
	wire							cnv_tvalid;
	wire							cnv_tready = 1;
	
	jelly_data_width_converter
			#(
				.UNIT_WIDTH		(S_AXI4S_DATA_WIDTH),
				.S_DATA_SIZE	(0),									// log2 (0:1bit, 1:2bit, 2:4bit, 3:8bit...)
				.M_DATA_SIZE	(M_AXI4_DATA_SIZE - COMPONENT_SIZE)		// log2 (0:1bit, 1:2bit, 2:4bit, 3:8bit...)
			)
		i_data_width_converter
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(1'b1),
				
				.endian			(endian),
				
				
				.s_data			(s_axi4s_tdata),
				.s_first		(s_axi4s_tuser),
				.s_last			(s_axi4s_tlast),
				.s_valid		(s_axi4s_tvalid),
				.s_ready		(s_axi4s_tready),
				
				.m_data			(cnv_tdata_tmp),
				.m_first		(),
				.m_last			(cnv_tlast),
				.m_valid		(cnv_tvalid),
				.m_ready		(cnv_tready)
			);
	
	generate
	for ( i = 0; i < COMPONENT_NUM; i = i+1 ) begin : loop_cvn_i
		for ( j = 0; j < CNV_NUM; j = j+1 ) begin : loop_cvn_j
			assign cnv_tdata[i*M_AXI4_DATA_WIDTH + j*COMPONENT_DATA_WIDTH +: COMPONENT_DATA_WIDTH]
						= cnv_tdata_tmp[j*S_AXI4S_DATA_WIDTH + i*COMPONENT_DATA_WIDTH +: COMPONENT_DATA_WIDTH];
		end
	end
	endgenerate
	
	
	
	
	// ---------------------------------
	//  FIFO
	// ---------------------------------
	
	jelly_texture_writer_fifo
			#(
				.COMPONENT_NUM			(COMPONENT_NUM),
				.COMPONENT_DATA_WIDTH	(COMPONENT_DATA_WIDTH << CNV_SIZE),
				
				.BLK_X_SIZE				(BLK_X_SIZE - CNV_SIZE),
				.BLK_Y_SIZE				(BLK_Y_SIZE),
				.STEP_Y_SIZE			(STEP_Y_SIZE),
				
				.X_WIDTH				(X_WIDTH - CNV_SIZE),
				.Y_WIDTH				(Y_WIDTH),
				
				.ADDR_WIDTH				(SIZE_WIDTH),
				
				.FIFO_PTR_WIDTH			(FIFO_PTR_WIDTH),
				.FIFO_RAM_TYPE			(FIFO_RAM_TYPE)
			)
		i_texture_writer_fifo
			(
				.reset					(reset),
				.clk					(clk),
				
				.param_width			(param_width[X_WIDTH-1:CNV_SIZE]),
				.param_height			(param_height),
				.param_stride			(param_width[X_WIDTH-1:CNV_SIZE]),
				
				.s_last					(cnv_tlast),
				.s_data					(cnv_tdata),
				.s_valid				(cnv_tvalid),
				.s_ready				(cnv_tready),
				
				.m_component			(),
				.m_addr					(),
				.m_data					(),
				.m_last					(),
				.m_valid				(),
				.m_ready				()
			);
	
	
	
	
endmodule


`default_nettype wire


// end of file
