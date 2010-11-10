// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   First-Word Fall-Through mode asyncronous FIFO
//
//                                 Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// First-Word Fall-Through mode asyncronous FIFO
module jelly_fifo_async
		#(
			parameter							DATA_WIDTH = 8,
			parameter							PTR_WIDTH  = 10
		)
		(
			input	wire						wr_reset,			
			input	wire						wr_clk,
			input	wire						wr_en,
			input	wire	[DATA_WIDTH-1:0]	wr_data,
			output	reg							wr_full,
			output	reg		[PTR_WIDTH:0]		wr_free_num,
			
			input	wire						rd_reset,			
			input	wire						rd_clk,
			input	wire						rd_en,
			output	wire	[DATA_WIDTH-1:0]	rd_data,
			output	reg							rd_empty,
			output	reg		[PTR_WIDTH:0]		rd_data_num
		);
	
	
	// ---------------------------------
	//  RAM
	// ---------------------------------
	
	wire						ram_wr_en;
	wire	[PTR_WIDTH-1:0]		ram_wr_addr;
	wire	[DATA_WIDTH-1:0]	ram_wr_data;
	
	wire						ram_rd_en;
	wire	[PTR_WIDTH-1:0]		ram_rd_addr;
	wire	[DATA_WIDTH-1:0]	ram_rd_data;
	
	// ram
	jelly_ram_dualport
			#(
				.DATA_WIDTH		(DATA_WIDTH),
				.ADDR_WIDTH		(PTR_WIDTH)
			)
		i_ram_dualport
			(
				.clk0			(wr_clk),
				.en0			(ram_wr_en),
				.we0			(1'b1),
				.addr0			(ram_wr_addr),
				.din0			(ram_wr_data),
				.dout0			(),
				
				.clk1			(rd_clk),
				.en1			(ram_rd_en),
				.we1			(1'b0),
				.addr1			(ram_rd_addr),
				.din1			({DATA_WIDTH{1'b0}}),
				.dout1			(ram_rd_data)
			);	
	
	
	
	// ---------------------------------
	//  FIFO pointer
	// ---------------------------------
	
	// write
	reg		[PTR_WIDTH:0]		wr_wptr;
	wire	[PTR_WIDTH:0]		wr_wptr_gray;
	reg		[PTR_WIDTH:0]		wr_wptr_gray__async_tx;
	
	reg		[PTR_WIDTH:0]		wr_rptr_gray__async_rx;
	reg		[PTR_WIDTH:0]		wr_rptr_gray_in;
	wire	[PTR_WIDTH:0]		wr_rptr_in;
	reg		[PTR_WIDTH:0]		wr_rptr;
	
	
	// read
	reg		[PTR_WIDTH:0]		rd_rptr;
	wire	[PTR_WIDTH:0]		rd_rptr_gray;
	reg		[PTR_WIDTH:0]		rd_rptr_gray__async_tx;
	
	reg		[PTR_WIDTH:0]		rd_wptr_gray__async_rx;
	reg		[PTR_WIDTH:0]		rd_wptr_gray_in;
	wire	[PTR_WIDTH:0]		rd_wptr_in;
	reg		[PTR_WIDTH:0]		rd_wptr;
	
	
	// write pointer
	jelly_binary_to_graycode
			#(
				.WIDTH		(PTR_WIDTH+1)
			)
		i_binary_to_graycode_wr
			(
				.binary		(wr_wptr),
				.graycode	(wr_wptr_gray)
			);
	
	jelly_graycode_to_binary
			#(
				.WIDTH		(PTR_WIDTH+1)
			)
		i_graycode_to_binary_wr
			(
				.graycode	(wr_rptr_gray_in),
				.binary		(wr_rptr_in)
			);
	
	reg		[PTR_WIDTH:0]	next_wr_wptr;
	reg						next_wr_full;
	reg		[PTR_WIDTH:0]	next_wr_free_num;
	always @* begin
		next_wr_wptr     = wr_wptr;
		next_wr_full     = wr_full;
		next_wr_free_num = wr_free_num;
		
		if ( ram_wr_en ) begin
			next_wr_wptr = wr_wptr + 1;
		end
		
		next_wr_full     = (next_wr_wptr[PTR_WIDTH] != wr_rptr[PTR_WIDTH]) && (next_wr_wptr[PTR_WIDTH-1:0] == wr_rptr[PTR_WIDTH-1:0]);
		next_wr_free_num = ((wr_rptr - next_wr_wptr) + (1 << PTR_WIDTH));
	end
	
	always @ ( posedge wr_clk ) begin
		if ( wr_reset ) begin
			wr_wptr                <= 0;
			wr_wptr_gray__async_tx <= 0;
			
			wr_rptr_gray__async_rx <= 0;
			wr_rptr_gray_in        <= 0;
			wr_rptr                <= 0;
			
			wr_full                <= 1'b1;
			wr_free_num            <= 0;
		end
		else begin
			// async (double ratch)
			wr_wptr_gray__async_tx <= wr_wptr_gray;
			wr_rptr_gray__async_rx <= rd_rptr_gray__async_tx;
			wr_rptr_gray_in        <= wr_rptr_gray__async_rx;
			wr_rptr                <= wr_rptr_in;
			
			// pinter logic
			wr_wptr                <= next_wr_wptr;
			wr_full                <= next_wr_full;
			wr_free_num            <= next_wr_free_num;
		end
	end
	
	assign ram_wr_en   = wr_en & !wr_full;
	assign ram_wr_addr = wr_wptr[PTR_WIDTH-1:0];
	assign ram_wr_data = wr_data;
	
	
	
	// read pointer
	jelly_binary_to_graycode
			#(
				.WIDTH		(PTR_WIDTH+1)
			)
		i_binary_to_graycode_rd
			(
				.binary		(rd_rptr),
				.graycode	(rd_rptr_gray)
			);
	
	jelly_graycode_to_binary
			#(
				.WIDTH		(PTR_WIDTH+1)
			)
		i_graycode_to_binary_rd
			(
				.graycode	(rd_wptr_gray_in),
				.binary		(rd_wptr_in)
			);
	
	
	reg		[PTR_WIDTH:0]	next_rd_rptr;
	reg						next_rd_empty;
	reg		[PTR_WIDTH:0]	next_rd_data_num;
	always @* begin
		next_rd_rptr     = rd_rptr;
		next_rd_empty    = rd_empty;
		next_rd_data_num = rd_data_num;
		
		if ( ram_rd_en ) begin
			next_rd_rptr = rd_rptr + 1;
		end
		
		next_rd_empty    = (rd_wptr == next_rd_rptr);
		next_rd_data_num = (rd_wptr - next_rd_rptr);
	end
	
	always @ ( posedge rd_clk ) begin
		if ( rd_reset ) begin
			rd_rptr                <= 0;			
			rd_rptr_gray__async_tx <= 0;
			
			rd_wptr_gray__async_rx <= 0;
			rd_wptr_gray_in        <= 0;
			rd_wptr                <= 0;
			
			rd_empty               <= 1'b1;
			rd_data_num            <= 0;
		end
		else begin
			// async (double ratch)
			rd_rptr_gray__async_tx <= rd_rptr_gray;
			rd_wptr_gray__async_rx <= wr_wptr_gray__async_tx;
			rd_wptr_gray_in        <= rd_wptr_gray__async_rx;
			rd_wptr                <= rd_wptr_in;
			
			// read pointer logic
			rd_rptr                <= next_rd_rptr;
			rd_empty               <= next_rd_empty;
			rd_data_num            <= next_rd_data_num;
		end
	end
		
	assign ram_rd_en    = rd_en & ~rd_empty;
	assign ram_rd_addr  = rd_rptr[PTR_WIDTH-1:0];
	assign rd_data      = ram_rd_data;
	
endmodule


`default_nettype wire


// end of file
