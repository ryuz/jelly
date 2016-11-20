// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_axi4s_width_converter
		#(
			parameter	S_DATA_SIZE  = 0,	// log2 (0:8bit, 1:16bit, 2:32bit, 3:64bit...)
			parameter	S_DATA_WIDTH = (8 << S_DATA_SIZE),
			parameter	S_STRB_WIDTH = (1 << S_DATA_SIZE),
			
			parameter	M_DATA_SIZE  = 0,	// log2 (0:8bit, 1:16bit, 2:32bit, 3:64bit...)
			parameter	M_DATA_WIDTH = (8 << M_DATA_SIZE),
			parameter	M_STRB_WIDTH = (1 << M_DATA_SIZE)
		)
		(
			input	wire						aresetn,
			input	wire						aclk,
			input	wire						cke,
			input	wire						endian,
			
			input	wire	[S_DATA_WIDTH-1:0]	s_axi4s_tdata,
			input	wire	[S_STRB_WIDTH-1:0]	s_axi4s_tstrb,
			input	wire						s_axi4s_tfirst,
			input	wire						s_axi4s_tlast,
			input	wire						s_axi4s_tvalid,
			output	wire						s_axi4s_tready,
			
			output	wire	[M_DATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire	[M_STRB_WIDTH-1:0]	m_axi4s_tstrb,
			output	wire						m_axi4s_tfirst,
			output	wire						m_axi4s_tlast,
			output	wire						m_axi4s_tvalid,
			input	wire						m_axi4s_tready
		);
	
	jelly_data_width_converter
			#(
				.UNIT_WIDTH		(8),
				.S_DATA_SIZE	(S_DATA_SIZE),
				.M_DATA_SIZE	(M_DATA_SIZE),
				.INIT_DATA		({M_DATA_WIDTH{1'bx}})
			)
		i_data_width_converter_tdata
			(
				.reset			(~aresetn),
				.clk			(aclk),
				.cke			(cke),
				
				.endian			(endian),
				
				.s_data			(s_axi4s_tdata),
				.s_last			(s_axi4s_tlast),
				.s_valid		(s_axi4s_tvalid),
				.s_ready		(s_axi4s_tready),
				
				.m_data			(m_axi4s_tdata),
				.m_last			(m_axi4s_tlast),
				.m_valid		(m_axi4s_tvalid),
				.m_ready		(m_axi4s_tready)
			);
	
	jelly_data_width_converter
			#(
				.UNIT_WIDTH		(1),
				.S_DATA_SIZE	(S_DATA_SIZE),
				.M_DATA_SIZE	(M_DATA_SIZE),
				.INIT_DATA		({M_STRB_WIDTH{1'b0}})
			)
		i_data_width_converter_tstrb
			(
				.reset			(~aresetn),
				.clk			(aclk),
				.cke			(cke),
				
				.endian			(endian),
				
				.s_data			(s_axi4s_tstrb),
				.s_last			(s_axi4s_tlast),
				.s_valid		(s_axi4s_tvalid),
				.s_ready		(),
				
				.m_data			(m_axi4s_tstrb),
				.m_last			(),
				.m_valid		(),
				.m_ready		(m_axi4s_tready)
			);
		
endmodule


`default_nettype wire


// end of file
