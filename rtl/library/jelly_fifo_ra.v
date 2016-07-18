// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// FIFO (random access)
module jelly_fifo_ra
		#(
			parameter	DATA_WIDTH = 8,
			parameter	PTR_WIDTH  = 9,
			parameter	DOUT_REGS  = 1,
			parameter	RAM_TYPE   = "block"
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			input	wire						wr_en,
			input	wire						wr_addr,
			input	wire	[DATA_WIDTH-1:0]	wr_data,
			
			output	wire	[PTR_WIDTH-1:0]		wr_ptr_addr,
			input	wire						wr_ptr_update,
			input	wire	[PTR_WIDTH-1:0]		wr_ptr_step,
			
			
			input	wire						rd_en,
			input	wire	[PTR_WIDTH-1:0]		rd_addr,
			input	wire						rd_regcke,
			output	wire	[DATA_WIDTH-1:0]	rd_data,
			
			output	wire	[PTR_WIDTH-1:0]		rd_ptr_addr,
			input	wire						rd_ptr_update,
			input	wire	[PTR_WIDTH-1:0]		rd_ptr_step,
			
			output	reg							full,
			output	reg							empty,
			output	reg		[PTR_WIDTH:0]		free_count,
			output	reg		[PTR_WIDTH:0]		data_count
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
				.ADDR_WIDTH		(PTR_WIDTH),
				.DOUT_REGS1		(DOUT_REGS),
				.RAM_TYPE		(RAM_TYPE)
			)
		i_ram_dualport
			(
				.clk0			(clk),
				.en0			(wr_en),
				.regcke0		(1'b0),
				.we0			(1'b1),
				.addr0			(wr_addr),
				.din0			(wr_data),
				.dout0			(),
				
				.clk1			(clk),
				.en1			(rd_en),
				.regcke1		(rd_regcke),
				.we1			(1'b0),
				.addr1			(rd_addr),
				.din1			({DATA_WIDTH{1'b0}}),
				.dout1			(rd_data)
			);
	
	
	
	// ---------------------------------
	//  FIFO pointer
	// ---------------------------------
	
	// write
	reg		[PTR_WIDTH:0]		wptr;
	reg		[PTR_WIDTH:0]		rptr;
	
	reg		[PTR_WIDTH:0]		next_rptr;
	reg		[PTR_WIDTH:0]		next_wptr;
	reg							next_empty;
	reg							next_full;
	reg		[PTR_WIDTH:0]		next_data_count;
	reg		[PTR_WIDTH:0]		next_free_count;
	always @* begin
		next_wptr       = wptr;
		next_rptr       = rptr;
		next_empty      = empty;
		next_full       = full;
		next_data_count = data_count;
		next_free_count = free_count;
		
		if ( wr_ptr_update ) begin
			next_wptr = wptr + wr_ptr_step;
		end
		
		if ( rd_ptr_update ) begin
			next_rptr = rptr + rd_ptr_step;
		end
		
		next_empty      = (next_wptr == next_rptr);
		next_full       = (next_wptr[PTR_WIDTH] != next_rptr[PTR_WIDTH]) && (next_wptr[PTR_WIDTH-1:0] == next_rptr[PTR_WIDTH-1:0]);
		next_data_count = (next_wptr - next_rptr);
		next_free_count = ((next_rptr - next_wptr) + (1'b1 << PTR_WIDTH));
	end
	
	always @ ( posedge clk ) begin
		if ( reset ) begin
			wptr       <= 0;
			rptr       <= 0;
			full       <= 1'b1;
			empty      <= 1'b1;
			free_count <= 0;
			data_count <= 0;
		end
		else begin
			wptr       <= next_wptr;
			rptr       <= next_rptr;
			full       <= next_full;
			empty      <= next_empty;
			free_count <= next_free_count;
			data_count <= next_data_count;
		end
	end
	
	assign wr_ptr_addr = wptr[PTR_WIDTH-1:0];
	assign rd_ptr_addr = rptr[PTR_WIDTH-1:0];
	
endmodule


`default_nettype wire


// end of file
