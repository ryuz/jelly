// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module video_mnist
		#(
			parameter	MAX_X_NUM       = 1024,
			parameter	RAM_TYPE        = "block",
			
			parameter	NUM_CALSS       = 10,
			parameter	CHANNEL_WIDTH   = 7,
			
			parameter	IMG_Y_NUM       = 480,
			parameter	IMG_Y_WIDTH     = 12,
			
			parameter	TUSER_WIDTH     = 1,
			parameter	M_TDATA_WIDTH   = NUM_CALSS*CHANNEL_WIDTH,
			parameter	M_TNUMBER_WIDTH = 4,
			parameter	M_TCOUNT_WIDTH  = 4,
			
			parameter	WITH_VALIDATION = 1,
			
			parameter	DEVICE          = "rtl"
		)
		(
			input	wire							aresetn,
			input	wire							aclk,
			
			input	wire	[TUSER_WIDTH-1:0]		s_axi4s_tuser,
			input	wire							s_axi4s_tlast,
			input	wire	[0:0]					s_axi4s_tdata,
			input	wire							s_axi4s_tvalid,
			output	wire							s_axi4s_tready,
			
			output	wire	[TUSER_WIDTH-1:0]		m_axi4s_tuser,
			output	wire							m_axi4s_tlast,
			output	wire	[M_TNUMBER_WIDTH-1:0]	m_axi4s_tnumber,
			output	wire	[M_TCOUNT_WIDTH-1:0]	m_axi4s_tcount,
			output	wire	[M_TDATA_WIDTH-1:0]		m_axi4s_tdata,
			output	wire	[0:0]					m_axi4s_tvalidation,
			output	wire							m_axi4s_tvalid,
			input	wire							m_axi4s_tready
		);
	
	
	// DNN
	wire	[TUSER_WIDTH-1:0]		axi4s_dnn_tuser;
	wire							axi4s_dnn_tlast;
	wire	[M_TDATA_WIDTH-1:0]		axi4s_dnn_tdata;
	wire	[0:0]					axi4s_dnn_tvalidation;
	wire							axi4s_dnn_tvalid;
	wire							axi4s_dnn_tready;
	
	video_mnist_classifier_core
			#(
				.MAX_X_NUM			(MAX_X_NUM),
				.RAM_TYPE			(RAM_TYPE),
				                     
				.IMG_Y_NUM			(IMG_Y_NUM),
				.IMG_Y_WIDTH		(IMG_Y_WIDTH),
				                     
				.S_TDATA_WIDTH		(1),
				.M_TDATA_WIDTH		(M_TDATA_WIDTH),
				.TUSER_WIDTH		(TUSER_WIDTH),
				
				.DEVICE				(DEVICE)
			)
		i_video_mnist_classifier_core
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				
				.param_blank_num	(3),
				
				.s_axi4s_tuser		(s_axi4s_tuser),
				.s_axi4s_tlast		(s_axi4s_tlast),
				.s_axi4s_tdata		(s_axi4s_tdata),
				.s_axi4s_tvalid		(s_axi4s_tvalid),
				.s_axi4s_tready		(s_axi4s_tready),
				
				.m_axi4s_tuser		(axi4s_dnn_tuser),
				.m_axi4s_tlast		(axi4s_dnn_tlast),
				.m_axi4s_tdata		(axi4s_dnn_tdata),
				.m_axi4s_tvalid		(axi4s_dnn_tvalid),
				.m_axi4s_tready		(axi4s_dnn_tready)
			);
	
	generate
	if ( WITH_VALIDATION ) begin : blk_validation
		video_mnist_validation_core
				#(
					.MAX_X_NUM			(MAX_X_NUM),
					.RAM_TYPE			(RAM_TYPE),
					                     
					.IMG_Y_NUM			(IMG_Y_NUM),
					.IMG_Y_WIDTH		(IMG_Y_WIDTH),
					                     
					.S_TDATA_WIDTH		(1),
					.M_TDATA_WIDTH		(1),
					.TUSER_WIDTH		(TUSER_WIDTH),
					
					.DEVICE				(DEVICE)
				)
			i_video_mnist_validation_core
				(
					.aresetn			(aresetn),
					.aclk				(aclk),
					
					.param_blank_num	(3),
					
					.s_axi4s_tuser		(s_axi4s_tuser),
					.s_axi4s_tlast		(s_axi4s_tlast),
					.s_axi4s_tdata		(s_axi4s_tdata),
					.s_axi4s_tvalid		(s_axi4s_tvalid),
					.s_axi4s_tready		(),
					
					.m_axi4s_tuser		(),
					.m_axi4s_tlast		(),
					.m_axi4s_tdata		(axi4s_dnn_tvalidation),
					.m_axi4s_tvalid		(),
					.m_axi4s_tready		(axi4s_dnn_tready)
				);
	end
	else begin : bypass_validation
		assign axi4s_dnn_tvalidation = 1'b1;
	end
	endgenerate
	
	
	video_dnn_max_count
			#(
				.NUM_CALSS			(NUM_CALSS),
				.CHANNEL_WIDTH		(CHANNEL_WIDTH),
				.TUSER_WIDTH		(1 + TUSER_WIDTH),
				.TNUMBER_WIDTH		(4),
				.TCOUNT_WIDTH		(4)
			)
		i_video_dnn_max_count
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				
				.s_axi4s_tuser		({axi4s_dnn_tvalidation, axi4s_dnn_tuser}),
				.s_axi4s_tlast		(axi4s_dnn_tlast),
				.s_axi4s_tdata		(axi4s_dnn_tdata),
				.s_axi4s_tvalid		(axi4s_dnn_tvalid),
				.s_axi4s_tready		(axi4s_dnn_tready),
				
				.m_axi4s_tuser		({m_axi4s_tvalidation, m_axi4s_tuser}),
				.m_axi4s_tlast		(m_axi4s_tlast),
				.m_axi4s_tnumber	(m_axi4s_tnumber),
				.m_axi4s_tcount		(m_axi4s_tcount),
				.m_axi4s_tdata		(m_axi4s_tdata),
				.m_axi4s_tvalid		(m_axi4s_tvalid),
				.m_axi4s_tready		(m_axi4s_tready)
			);
	
	
endmodule



`default_nettype wire



// end of file
