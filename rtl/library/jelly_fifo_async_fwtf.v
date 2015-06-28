// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   First-Word Fall-Through mode asyncronous FIFO
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// asyncronous FIFO (First-Word Fall-Through mode)
module jelly_fifo_async_fwtf
		#(
			parameter	DATA_WIDTH = 8,
			parameter	PTR_WIDTH  = 10,
			parameter	DOUT_REGS  = 0,
			parameter	RAM_TYPE   = "block"
		)
		(
			// slave port
			input	wire						s_reset,
			input	wire						s_clk,
			input	wire	[DATA_WIDTH-1:0]	s_data,
			input	wire						s_valid,
			output	wire						s_ready,
			output	wire	[PTR_WIDTH:0]		s_free_count,
			
			// master port
			input	wire						m_reset,
			input	wire						m_clk,
			output	wire	[DATA_WIDTH-1:0]	m_data,
			output	wire						m_valid,
			input	wire						m_ready,
			output	wire	[PTR_WIDTH:0]		m_data_count
		);
	
	
	//  asyncronous FIFO
	wire						fifo_wr_en;
	wire	[DATA_WIDTH-1:0]	fifo_wr_data;
	wire						fifo_wr_full;
	wire	[PTR_WIDTH:0]		fifo_wr_free_count;
	
	wire						fifo_rd_en;
	wire						fifo_rd_regcke;
	wire	[DATA_WIDTH-1:0]	fifo_rd_data;
	wire						fifo_rd_empty;
	wire	[PTR_WIDTH:0]		fifo_rd_data_count;
	
	jelly_fifo_async
			#(
				.DATA_WIDTH		(DATA_WIDTH),
				.PTR_WIDTH		(PTR_WIDTH),
				.DOUT_REGS		(DOUT_REGS),
				.RAM_TYPE		(RAM_TYPE)
			)
		i_fifo_async
			(
				.wr_reset		(s_reset),
				.wr_clk			(s_clk),
				.wr_en			(fifo_wr_en),
				.wr_data		(fifo_wr_data),
				.wr_full		(fifo_wr_full),
				.wr_free_count	(fifo_wr_free_count),
				                 
				.rd_reset		(m_reset),
				.rd_clk			(m_clk),
				.rd_en			(fifo_rd_en),
				.rd_regcke		(fifo_rd_regcke),
				.rd_data		(fifo_rd_data),
				.rd_empty		(fifo_rd_empty),
				.rd_data_count	(fifo_rd_data_count)
			);
	
	// write (slave port)
	assign fifo_wr_en   = s_valid & s_ready;
	assign fifo_wr_data = s_data;
	assign s_ready      = ~fifo_wr_full;
	assign s_free_count = ~fifo_wr_free_count;
	
	// read (master port)
	jelly_fifo_read_fwtf
			#(
				.DATA_WIDTH		(DATA_WIDTH),
				.PTR_WIDTH		(PTR_WIDTH),
				.DOUT_REGS		(DOUT_REGS)
			)
		i_fifo_read_fwtf
			(
				.reset			(m_reset),
				.clk			(m_clk),
				
				.rd_en			(fifo_rd_en),
				.rd_regcke		(fifo_rd_regcke),
				.rd_data		(fifo_rd_data),
				.rd_empty		(fifo_rd_empty),
				.rd_count		(fifo_rd_data_count),
				
				.m_data			(m_data),
				.m_valid		(m_valid),
				.m_ready		(m_ready),
				.m_count		(m_data_count)
			);
	
endmodule


`default_nettype wire


// end of file
