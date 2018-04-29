// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_csi2_rx
		#(
			parameter LANE_NUM   = 2,
			parameter DATA_WIDTH = 10
		)
		(
			// input
			input	wire						rxreseths,
			input	wire						rxbyteclkhs,
			input	wire	[LANE_NUM*8-1:0]	rxdatahs,
			input	wire	[LANE_NUM-1:0]		rxvalidhs,
			input	wire	[LANE_NUM-1:0]		rxactivehs,
			input	wire	[LANE_NUM-1:0]		rxsynchs,
			
			
			// output
			input	wire						aresetn,
			input	wire						aclk,
			output	wire	[0:0]				m_axi4s_tuser,
			output	wire						m_axi4s_tlast,
			output	wire	[DATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire	[0:0]				m_axi4s_tvalid,
			input	wire						m_axi4s_tready
		);
	
	
	wire	[0:0]				marge_tuser;
	wire	[7:0]				marge_tdata;
	wire	[0:0]				marge_tvalid;
	wire						marge_tready;
	
	wire						request_sync;
	
	jelly_csi2_rx_lane_merging
			#(
				.LANE_NUM			(LANE_NUM),
				.M_AXI4S_REGS		(0)
			)
		i_csi2_rx_lane_merging
			(
				.rxreseths			(rxreseths),
				.rxbyteclkhs		(rxbyteclkhs),
				.rxdatahs			(rxdatahs),
				.rxvalidhs			(rxvalidhs),
				.rxactivehs			(rxactivehs),
				.rxsynchs			(rxsynchs),
				
				.aresetn			(aresetn),
				.aclk				(aclk),
				.m_axi4s_tuser		(marge_tuser),
				.m_axi4s_tdata		(marge_tdata),
				.m_axi4s_tvalid		(marge_tvalid),
				.m_axi4s_tready		(marge_tready),
				
				.request_sync		(request_sync)
			);
	
	
	jelly_csi2_rx_low_layer
		i_csi2_rx_low_layer
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				
				.param_data_type	(8'h2b),
				
				.out_request_sync	(request_sync),
				.out_frame_start	(),
				.out_frame_end		(),
				
				.s_axi4s_tuser		(marge_tuser),
				.s_axi4s_tdata		(marge_tdata),
				.s_axi4s_tvalid		(marge_tvalid),
				.s_axi4s_tready		(marge_tready),
				
				.m_axi4s_tlast		(),
				.m_axi4s_tdata		(),
				.m_axi4s_tvalid		(),
				.m_axi4s_tready		(1)
			);
	
	
	
//	assign marge_tready = 1;
//	assign request_sync = 0;
	
endmodule


`default_nettype wire


// end of file
