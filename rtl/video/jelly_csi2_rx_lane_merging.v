// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_csi2_rx_lane_merging
		#(
			parameter LANE_NUM     = 2,
			parameter M_AXI4S_REGS = 0
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
			output	wire	[7:0]				m_axi4s_tdata,
			output	wire						m_axi4s_tvalid,
			input	wire						m_axi4s_tready,
			
			input	wire						request_sync
		);
	
	genvar		i;
	
	
	// lane receive
	wire	[LANE_NUM-1:0]		lane_tuser;
	wire	[LANE_NUM*8-1:0]	lane_tdata;
	wire	[LANE_NUM-1:0]		lane_tvalid;
	reg		[LANE_NUM-1:0]		lane_tready;
	
	generate
	for ( i = 0; i < LANE_NUM; i = i+1 ) begin : loop_lane
		jelly_csi2_rx_lane_recv
				#(
					.PRE_DELAY			(i == 0 ? 0 : 2),		// ŠJŽnŽž‚É•K‚¸lane0Šî€‚É‚È‚é‚æ‚¤‚É‚·‚é
					.FIFO_PTR_WIDTH		(6),
					.FIFO_RAM_TYPE		("distributed"),
					.M_AXI4S_REGS		(0)
				)
			i_csi2_rx_lane_recv
				(
					.rxreseths			(rxreseths),
					.rxbyteclkhs		(rxbyteclkhs),
					.rxdatahs			(rxdatahs  [i*8 +: 8]),
					.rxvalidhs			(rxvalidhs [i]),
					.rxactivehs			(rxactivehs[i]),
					.rxsynchs			(rxsynchs  [i]),
					
					.aresetn			(aresetn),
					.aclk				(aclk),
					.m_axi4s_tuser		(lane_tuser [i]),
					.m_axi4s_tdata		(lane_tdata [i*8 +: 8]),
					.m_axi4s_tvalid		(lane_tvalid[i]),
					.m_axi4s_tready		(lane_tready[i]),
					
					.request_sync		(request_sync)
				);
	end
	endgenerate
	
	// marge
	reg							marge_tuser;
	reg		[7:0]				marge_tdata;
	reg							marge_tvalid;
	wire						marge_tready;
	
	reg							reg_busy;
	reg		[LANE_NUM-1:0]		reg_phase;
	always @(posedge aclk) begin
		if ( ~aresetn ) begin
			reg_busy  <= 1'b0;
			reg_phase <= 1;
		end
		else begin
			if ( marge_tvalid && marge_tready ) begin
				if ( reg_busy || lane_tuser[0] ) begin
					reg_busy  <= 1'b1;
					reg_phase <= {reg_phase, reg_phase[LANE_NUM-1]};
				end
			end
			
			if ( request_sync ) begin
				reg_busy  <= 1'b0;
				reg_phase <= 1;
			end
		end
	end
	
	integer		j;
	always @* begin
		marge_tuser  = 1'bx;
		marge_tdata  = 8'hxx;
		marge_tvalid = 1'b0;
		lane_tready  = {LANE_NUM{1'b0}};
		for ( j = 0; j < LANE_NUM; j = j+1 ) begin
			if ( reg_phase == (1 << j) ) begin
				marge_tuser  = lane_tuser[j];
				marge_tdata  = lane_tdata[j*8 +: 8];
				marge_tvalid = lane_tvalid[j];
				
				lane_tready[j] = marge_tready;
			end
		end
		
		if ( !reg_busy && !lane_tuser[0] ) begin
			lane_tready = {LANE_NUM{1'b1}};
		end
	end
	
	
	// insert FF
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH		(1+8),
				.SLAVE_REGS		(M_AXI4S_REGS),
				.MASTER_REGS	(0)
			)
		i_pipeline_insert_ff
			(
				.reset			(~aresetn),
				.clk			(aclk),
				.cke			(1'b1),
				
				.s_data			({marge_tuser, marge_tdata}),
				.s_valid		(marge_tvalid),
				.s_ready		(marge_tready),
				
				.m_data			({m_axi4s_tuser, m_axi4s_tdata}),
				.m_valid		(m_axi4s_tvalid),
				.m_ready		(m_axi4s_tready),
				
				.buffered		(),
				.s_ready_next	()
			);
	
	
endmodule


`default_nettype wire


// end of file
