// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   First-Word Fall-Through mode FIFO
//
//                                 Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// FIFO (First-Word Fall-Through mode)
module jelly_fifo_fwtf
		#(
			parameter							DATA_WIDTH = 8,
			parameter							PTR_WIDTH  = 10
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			input	wire	[DATA_WIDTH-1:0]	wr_data,
			input	wire						wr_valid,
			output	wire						wr_ready,
			
			output	wire	[DATA_WIDTH-1:0]	rd_data,
			output	reg							rd_valid,
			input	wire						rd_ready,
			
			output	wire	[PTR_WIDTH:0]		free_num,
			output	wire	[PTR_WIDTH:0]		data_num
		);
	
	
	// ---------------------------------
	//  FIFO
	// ---------------------------------
	
	wire						fifo_wr_en;
	wire	[DATA_WIDTH-1:0]	fifo_wr_data;
	
	wire						fifo_rd_en;
	wire	[DATA_WIDTH-1:0]	fifo_rd_data;
	
	wire						fifo_full;
	wire						fifo_empty;
		
	jelly_fifo
			#(
				.DATA_WIDTH		(DATA_WIDTH),
				.PTR_WIDTH		(PTR_WIDTH)
			)
		i_fifo_async
			(
				.reset			(reset),
				.clk			(clk),
				
				.wr_en			(fifo_wr_en),
				.wr_data		(fifo_wr_data),
				
				.rd_en			(fifo_rd_en),
				.rd_data		(fifo_rd_data),

				.full			(fifo_full),				
				.empty			(fifo_empty),
				.free_num		(free_num),
				.data_num		(data_num)
			);
	
	// write
	assign fifo_wr_en   = wr_valid & wr_ready;
	assign fifo_wr_data = wr_data;
	assign wr_ready     = ~fifo_full;
	
	// read
	always @(posedge clk ) begin
		if ( reset ) begin
			rd_valid <= 1'b0;
		end
		else begin
			if ( ~rd_valid | rd_ready ) begin
				rd_valid <= fifo_rd_en;
			end
		end
	end
	
	assign fifo_rd_en  = ~fifo_empty & (~rd_valid | rd_ready);
	assign rd_data     = fifo_rd_data;
	
endmodule


`default_nettype wire


// end of file
