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
			parameter LANE_NUM         = 2,
			parameter DATA_WIDTH       = 10,
			parameter M_FIFO_ASYNC     = 1,
			parameter M_FIFO_PTR_WIDTH = M_FIFO_ASYNC ? 6 : 0,
			parameter M_FIFO_RAM_TYPE  = "distributed"
		)
		(
			input	wire						aresetn,
			input	wire						aclk,
			
			output	wire						overflow,
			
			// input
			input	wire						rxreseths,
			input	wire						rxbyteclkhs,
			input	wire	[LANE_NUM*8-1:0]	rxdatahs,
			input	wire	[LANE_NUM-1:0]		rxvalidhs,
			input	wire	[LANE_NUM-1:0]		rxactivehs,
			input	wire	[LANE_NUM-1:0]		rxsynchs,
			
			
			// output
			input	wire						m_axi4s_aresetn,
			input	wire						m_axi4s_aclk,
			output	wire	[0:0]				m_axi4s_tuser,
			output	wire						m_axi4s_tlast,
			output	wire	[DATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire	[0:0]				m_axi4s_tvalid,
			input	wire						m_axi4s_tready
		);
	
	
	(* MARK_DEBUG = "true" *)	wire	[0:0]				marge_tuser;
	(* MARK_DEBUG = "true" *)	wire	[7:0]				marge_tdata;
	(* MARK_DEBUG = "true" *)	wire						marge_tvalid;
	(* MARK_DEBUG = "true" *)	wire						marge_tready;
	
	(* MARK_DEBUG = "true" *)	wire						request_sync;
	(* MARK_DEBUG = "true" *)	wire						frame_start;
	(* MARK_DEBUG = "true" *)	wire						frame_end;
								wire						crc_error;
	
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
	
	
	(* MARK_DEBUG = "true" *)	wire						low_tlast;
	(* MARK_DEBUG = "true" *)	wire	[7:0]				low_tdata;
	(* MARK_DEBUG = "true" *)	wire						low_tvalid;
	(* MARK_DEBUG = "true" *)	wire						low_tready;
	
	jelly_csi2_rx_low_layer
		i_csi2_rx_low_layer
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				
				.param_data_type	(8'h2b),
				
				.out_request_sync	(request_sync),
				.out_frame_start	(frame_start),
				.out_frame_end		(frame_end),
				.out_crc_error		(crc_error),
				
				.s_axi4s_tuser		(marge_tuser),
				.s_axi4s_tdata		(marge_tdata),
				.s_axi4s_tvalid		(marge_tvalid),
				.s_axi4s_tready		(marge_tready),
				
				.m_axi4s_tlast		(low_tlast),
				.m_axi4s_tdata		(low_tdata),
				.m_axi4s_tvalid		(low_tvalid),
				.m_axi4s_tready		(low_tready)
			);
	
	reg			reg_tuser;
	always @(posedge aclk) begin
		if ( ~aresetn ) begin
			reg_tuser <= 1'b1;
		end
		else begin
			if ( frame_start || frame_end ) begin
				reg_tuser <= 1'b1;
			end
			
			if ( low_tvalid && low_tready ) begin
				reg_tuser <= 1'b0;
			end
		end
	end
	
	
	// RAW10
	wire	[0:0]				out_tuser;
	wire						out_tlast;
	wire	[DATA_WIDTH-1:0]	out_tdata;
	wire	[0:0]				out_tvalid;
	wire						out_tready;
	
	jelly_csi2_rx_raw10
			#(
				.S_AXI4S_REGS		(1),
				.M_AXI4S_REGS		(1)
			)
		i_csi2_rx_raw10
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				
				.s_axi4s_tuser		(reg_tuser),
				.s_axi4s_tlast		(low_tlast),
				.s_axi4s_tdata		(low_tdata),
				.s_axi4s_tvalid		(low_tvalid),
				.s_axi4s_tready		(low_tready),
				
				.m_axi4s_tuser		(out_tuser),
				.m_axi4s_tlast		(out_tlast),
				.m_axi4s_tdata		(out_tdata),
				.m_axi4s_tvalid		(out_tvalid),
				.m_axi4s_tready		(1'b1)
			);
	
	assign	overflow = (out_tvalid & !out_tready);
	
	
	jelly_fifo_generic_fwtf
			#(
				.ASYNC				(M_FIFO_ASYNC),
				.DATA_WIDTH			(2+DATA_WIDTH),
				.PTR_WIDTH			(M_FIFO_PTR_WIDTH),
				.DOUT_REGS			(0),
				.RAM_TYPE			(M_FIFO_RAM_TYPE),
				.LOW_DEALY			(0),
				.SLAVE_REGS			(0),
				.MASTER_REGS		(1)
			)
		i_fifo_generic_fwtf
			(
				.s_reset			(~aresetn),
				.s_clk				(aclk),
				.s_data				({out_tuser, out_tlast, out_tdata}),
				.s_valid			(out_tvalid),
				.s_ready			(out_tready),
				.s_free_count		(),
				
				.m_reset			(~m_axi4s_aresetn),
				.m_clk				(m_axi4s_aclk),
				.m_data				({m_axi4s_tuser, m_axi4s_tlast, m_axi4s_tdata}),
				.m_valid			(m_axi4s_tvalid),
				.m_ready			(m_axi4s_tready),
				.m_data_count		()
			);
	
	
endmodule


`default_nettype wire


// end of file
