// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// wishbone master to slave
module jelly_wishbone_m_to_s
		#(
			parameter	WB_ADR_WIDTH  = 30,
			parameter	WB_DAT_WIDTH  = 32,
			parameter	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
		)
		(
			// system
			input	wire						reset,
			input	wire						clk,
			
			// slave port
			input	wire	[WB_ADR_WIDTH-1:0]	s_wb_adr_o,
			output	wire	[WB_DAT_WIDTH-1:0]	s_wb_dat_i,
			input	wire	[WB_DAT_WIDTH-1:0]	s_wb_dat_o,
			input	wire						s_wb_we_o,
			input	wire	[WB_SEL_WIDTH-1:0]	s_wb_sel_o,
			input	wire						s_wb_stb_o,
			output	wire						s_wb_ack_i,
			
			// master port
			output	wire						m_wb_rst_i,
			output	wire						m_wb_clk_i,
			output	wire	[WB_ADR_WIDTH-1:0]	m_wb_adr_i,
			input	wire	[WB_DAT_WIDTH-1:0]	m_wb_dat_o,
			output	wire	[WB_DAT_WIDTH-1:0]	m_wb_dat_i,
			output	wire						m_wb_we_i,
			output	wire	[WB_SEL_WIDTH-1:0]	m_wb_sel_i,
			output	wire						m_wb_stb_i,
			input	wire						m_wb_ack_o
		);
	
	assign m_wb_rst_i = reset;
	assign m_wb_clk_i = clk;
	assign m_wb_adr_i = s_wb_adr_o;
	assign m_wb_dat_i = s_wb_dat_o;
	assign m_wb_we_i  = s_wb_we_o;
	assign m_wb_sel_i = s_wb_sel_o;
	assign m_wb_stb_i = s_wb_stb_o;
	
	assign s_wb_dat_i = m_wb_dat_o;
	assign s_wb_ack_i = m_wb_ack_o;
	
	
endmodule



`default_nettype wire


// end of file
