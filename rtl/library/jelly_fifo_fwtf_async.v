// ---------------------------------------------------------------------------
//  Common components
//   First-Word Fall-Through mode asyncronous FIFO
//
//                                 Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// First-Word Fall-Through mode asyncronous FIFO
module jelly_fifo_fwtf_async
		#(
			parameter							DATA_WIDTH = 8,
			parameter							PTR_WIDTH  = 8
		)
		(
			input	wire						reset,
			
			input	wire						in_clk,
			input	wire						in_en,
			input	wire	[DATA_WIDTH-1:0]	in_data,
			output	wire						in_ready,
			output	wire	[PTR_WIDTH:0]		in_free_num,
			
			input	wire						out_clk,
			output	wire						out_en,
			output	wire	[DATA_WIDTH-1:0]	out_data,
			input	wire						out_ready,
			output	wire	[PTR_WIDTH:0]		out_data_num
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
				.clk0			(in_clk),
				.reset0			(1'b0),
				.en0			(ram_wr_en),
				.we0			(1'b1),
				.addr0			(ram_wr_addr),
				.din0			(ram_wr_data),
				.dout0			(),
				
				.clk1			(out_clk),
				.reset1			(1'b0),
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
	wire						wr_full;
	
	reg		[PTR_WIDTH:0]		wr_rptr_gray__async_rx;
	reg		[PTR_WIDTH:0]		wr_rptr_gray_in;
	wire	[PTR_WIDTH:0]		wr_rptr_in;
	reg		[PTR_WIDTH:0]		wr_rptr;
	
	
	// read
	reg		[PTR_WIDTH:0]		rd_rptr;
	wire	[PTR_WIDTH:0]		rd_rptr_gray;
	reg		[PTR_WIDTH:0]		rd_rptr_gray__async_tx;
	wire						rd_empty;
	
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
		
	always @ ( posedge in_clk or posedge reset ) begin
		if ( reset ) begin
			wr_wptr                <= 0;
			wr_wptr_gray__async_tx <= 0;

			wr_rptr_gray__async_rx <= 0;
			wr_rptr_gray_in        <= 0;
			wr_rptr                <= 0;
		end
		else begin
			// async
			wr_wptr_gray__async_tx <= wr_wptr_gray;
			wr_rptr_gray__async_rx <= rd_rptr_gray__async_tx;
			wr_rptr_gray_in        <= wr_rptr_gray__async_rx;
			wr_rptr                <= wr_rptr_in;
			
			// pinter
			if ( in_en & in_ready ) begin
				wr_wptr <= wr_wptr + 1;
			end
		end
	end

	assign wr_full     = (wr_wptr[PTR_WIDTH] != wr_rptr[PTR_WIDTH]) && (wr_wptr[PTR_WIDTH-1:0] == wr_rptr[PTR_WIDTH-1:0]);
	
	assign ram_wr_en   = in_en & in_ready;
	assign ram_wr_addr = wr_wptr[PTR_WIDTH-1:0];
	assign ram_wr_data = in_data;
	
	assign in_ready    = !wr_full;
    assign in_free_num = ((wr_rptr - wr_wptr) + (1 << PTR_WIDTH));
	
		
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
	
	reg							rd_valid;
	reg		[DATA_WIDTH:0]		rd_data;
	reg							rd_data_valid;
	always @ ( posedge out_clk or posedge reset ) begin
		if ( reset ) begin
			rd_rptr                <= 0;
			rd_rptr_gray__async_tx <= 0;

			rd_wptr_gray__async_rx <= 0;
			rd_wptr_gray_in        <= 0;
			rd_wptr                <= 0;
			
			rd_valid               <= 1'b0;
			rd_data                <= {DATA_WIDTH{1'bx}};
			rd_data_valid          <= 1'b0;
		end
		else begin
			// async
			rd_rptr_gray__async_tx <= rd_rptr_gray;
			rd_wptr_gray__async_rx <= wr_wptr_gray__async_tx;
			rd_wptr_gray_in        <= rd_wptr_gray__async_rx;
			rd_wptr                <= rd_wptr_in;
			
			// read pointer
			if ( ~rd_empty & (out_ready | ~out_en) ) begin
				rd_rptr <= rd_rptr + 1;
			end
			
			rd_valid <= !rd_empty;
			if ( out_ready ) begin
				rd_data_valid <= 1'b0;
			end
			else begin
				if ( !rd_data_valid ) begin
					rd_data       <= ram_rd_data;
					rd_data_valid <= rd_valid;
				end
			end
		end
	end
	
	assign rd_empty     = (rd_wptr == rd_rptr);
	
	assign ram_rd_en    = 1'b1;	// ~rd_empty & (out_ready | ~out_en);
	assign ram_rd_addr  = rd_rptr[PTR_WIDTH-1:0];
	
	assign out_en       = rd_data_valid | rd_valid;
	assign out_data     = rd_data_valid ? rd_data : ram_rd_data;
	assign out_data_num = (rd_wptr - rd_rptr);
	
endmodule


// End of file
