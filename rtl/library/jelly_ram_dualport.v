// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   Dualport-RAM
//
//                                 Copyright (C) 2007-2008 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// Dualport-RAM
(* ram_style="auto" *)
module jelly_ram_dualport
		#(
			parameter	ADDR_WIDTH   = 8,
			parameter	DATA_WIDTH   = 8,
			parameter	MEM_SIZE     = (1 << ADDR_WIDTH),
			parameter	WRITE_FIRST  = 0,
			parameter	INIT_DOUT    = 0,
			
			parameter	FILLMEM      = 0,
			parameter	FILLMEM_DATA = 0,
			parameter	READMEMB     = 0,
			parameter	READMEMH     = 0,
			parameter	READMEM_FIlE = ""
		)
		(
			// port0
			input	wire						clk0,
			input	wire						reset0,
			input	wire						en0,
			input	wire						we0,
			input	wire	[ADDR_WIDTH-1:0]	addr0,
			input	wire	[DATA_WIDTH-1:0]	din0,
			output	reg		[DATA_WIDTH-1:0]	dout0,
			
			// port1
			input	wire						clk1,
			input	wire						reset1,
			input	wire						en1,
			input	wire						we1,
			input	wire	[ADDR_WIDTH-1:0]	addr1,
			input	wire	[DATA_WIDTH-1:0]	din1,
			output	reg		[DATA_WIDTH-1:0]	dout1
		);
	
	// memory
	reg		[DATA_WIDTH-1:0]	mem	[0:MEM_SIZE-1];
	
	
	// port0
	generate
	if ( WRITE_FIRST ) begin
		// write first
		always @ ( posedge clk0 ) begin
			if ( en0 ) begin
				if ( we0 ) begin
					mem[addr0] <= din0;
				end
				
				if ( reset0 ) begin
					dout0 <= INIT_DOUT;
				end
				else begin
					if ( we0 ) begin
						dout0 <= din0;
					end
					else begin
						dout0 <= mem[addr0];
					end
				end
			end
		end
	end
	else begin
		// read first
		always @ ( posedge clk0 ) begin
			if ( en0 ) begin
				if ( we0 ) begin
					mem[addr0] <= din0;
				end
				
				if ( reset0 ) begin
					dout0 <= INIT_DOUT;
				end
				else begin
					dout0 <= mem[addr0];
				end
			end
		end
	end
	endgenerate
	
	// port1
	generate
	if ( WRITE_FIRST ) begin
		// write first
		always @ ( posedge clk1 ) begin
			if ( en1 ) begin
				if ( we1 ) begin
					mem[addr1] <= din1;
				end
				
				if ( reset1 ) begin
					dout1 <= INIT_DOUT;
				end
				else begin
					if ( we1 ) begin
						dout1 <= din1;
					end
					else begin
						dout1 <= mem[addr1];
					end
				end
			end
		end
	end
	else begin
		// read first
		always @ ( posedge clk1 ) begin
			if ( en1 ) begin
				if ( we1 ) begin
					mem[addr1] <= din1;
				end
				
				if ( reset1 ) begin
					dout1 <= INIT_DOUT;
				end
				else begin
					dout1 <= mem[addr1];
				end
			end
		end
	end
	endgenerate
	
	// initialize
	integer	i;
	initial begin
		if ( FILLMEM ) begin
			for ( i = 0; i < MEM_SIZE; i = i + 1 ) begin
				mem[i] = FILLMEM_DATA;
			end
		end
		
		if ( READMEMB ) begin
			$readmemb(READMEM_FIlE, mem);
		end
		if ( READMEMH ) begin
			$readmemh(READMEM_FIlE, mem);
		end
	end
	
endmodule


// End of file
