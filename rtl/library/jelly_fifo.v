// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   FIFO
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// FIFO
module jelly_fifo
		#(
			parameter	DATA_WIDTH = 8,
			parameter	PTR_WIDTH  = 10,
			parameter	DOUT_REGS  = 0,
			parameter	RAM_TYPE   = "block"
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			input	wire						wr_en,
			input	wire	[DATA_WIDTH-1:0]	wr_data,
			
			input	wire						rd_en,
			input	wire						rd_regcke,
			output	wire	[DATA_WIDTH-1:0]	rd_data,
			
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
				.en0			(ram_wr_en),
				.regcke0		(1'b0),
				.we0			(1'b1),
				.addr0			(ram_wr_addr),
				.din0			(ram_wr_data),
				.dout0			(),
				
				.clk1			(clk),
				.en1			(ram_rd_en),
				.regcke1		(rd_regcke),
				.we1			(1'b0),
				.addr1			(ram_rd_addr),
				.din1			({DATA_WIDTH{1'b0}}),
				.dout1			(ram_rd_data)
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
		next_wptr     = wptr;
		next_rptr     = rptr;
		next_empty    = empty;
		next_full     = full;
		next_data_count = data_count;
		next_free_count = free_count;
		
		if ( ram_wr_en ) begin
			next_wptr = wptr + 1'b1;
		end
		if ( ram_rd_en ) begin
			next_rptr = rptr + 1'b1;
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
	
	assign ram_wr_en   = wr_en & ~full;
	assign ram_wr_addr = wptr[PTR_WIDTH-1:0];
	assign ram_wr_data = wr_data;
	
	assign ram_rd_en   = rd_en & ~empty;
	assign ram_rd_addr = rptr[PTR_WIDTH-1:0];
	assign rd_data     = ram_rd_data;
	
endmodule


`default_nettype wire


// end of file
