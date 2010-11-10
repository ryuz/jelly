// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   First-Word Fall-Through mode asyncronous FIFO
//
//                                 Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// asyncronous FIFO (First-Word Fall-Through mode)
module jelly_fifo_async_fwtf
		#(
			parameter							DATA_WIDTH = 8,
			parameter							PTR_WIDTH  = 10
		)
		(
			input	wire						wr_reset,
			input	wire						wr_clk,
			input	wire	[DATA_WIDTH-1:0]	wr_data,
			input	wire						wr_valid,
			output	wire						wr_ready,
			output	wire	[PTR_WIDTH:0]		wr_free_num,
			
			input	wire						rd_reset,
			input	wire						rd_clk,
			output	wire	[DATA_WIDTH-1:0]	rd_data,
			output	reg							rd_valid,
			input	wire						rd_ready,
			output	wire	[PTR_WIDTH:0]		rd_data_num
		);
	
	
	// ---------------------------------
	//  asyncronous FIFO
	// ---------------------------------
	
	wire						fifo_wr_en;
	wire	[DATA_WIDTH-1:0]	fifo_wr_data;
	wire						fifo_wr_full;
	wire	[PTR_WIDTH:0]		fifo_wr_free_num;
	
	wire						fifo_rd_en;
	wire	[DATA_WIDTH-1:0]	fifo_rd_data;
	wire						fifo_rd_empty;
	wire	[PTR_WIDTH:0]		fifo_rd_data_num;
	
	jelly_fifo_async
			#(
				.DATA_WIDTH		(DATA_WIDTH),
				.PTR_WIDTH		(PTR_WIDTH)
			)
		i_fifo_async
			(
				.wr_reset		(wr_reset),
				.wr_clk			(wr_clk),
				.wr_en			(fifo_wr_en),
				.wr_data		(fifo_wr_data),
				.wr_full		(fifo_wr_full),
				.wr_free_num	(fifo_wr_free_num),
				                 
				.rd_reset		(rd_reset),			
				.rd_clk			(rd_clk),
				.rd_en			(fifo_rd_en),
				.rd_data		(fifo_rd_data),
				.rd_empty		(fifo_rd_empty),
				.rd_data_num	(fifo_rd_data_num)
			);
	
	// write
	assign fifo_wr_en   = wr_valid & wr_ready;
	assign fifo_wr_data = wr_data;
	assign wr_ready     = ~fifo_wr_full;
	assign wr_free_num  = ~fifo_wr_free_num;
	
	// read
	always @(posedge rd_clk ) begin
		if ( rd_reset ) begin
			rd_valid <= 1'b0;
		end
		else begin
			if ( ~rd_valid | rd_ready ) begin
				rd_valid <= fifo_rd_en;
			end
		end
	end
	
	assign fifo_rd_en  = ~fifo_rd_empty & (~rd_valid | rd_ready);
	assign rd_data     = fifo_rd_data;
	assign rd_data_num = fifo_rd_data_num;
	
endmodule


`default_nettype wire


// end of file
