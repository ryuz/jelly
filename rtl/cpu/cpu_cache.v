// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// Cached Load Store Unit
module jelly_cpu_cache
		#(
			parameter										CPUBUS_ADDR_WIDTH  = 24,
			parameter										CPUBUS_DATA_SIZE   = 2,  		// log2 (0:8bit, 1:16bit, 2:32bit ...)
			parameter										CPUBUS_SEL_WIDTH   = (1 << CPUBUS_DATA_SIZE),
			parameter										CPUBUS_DATA_WIDTH  = (8 << CPUBUS_DATA_SIZE),
			
			parameter										MEMBUS_ADDR_WIDTH  = 24,
			parameter										MEMBUS_DATA_SIZE   = 2,  		// log2 (0:8bit, 1:16bit, 2:32bit ...)
			parameter										MEMBUS_SEL_WIDTH   = (1 << MEMBUS_DATA_SIZE),
			parameter										MEMBUS_DATA_WIDTH  = (8 << MEMBUS_DATA_SIZE),
			
			parameter										WAY                = 2,
			parameter										PAGE_SIZE          = 8,			// log2
			parameter										LINE_SIZE          = 2,			// log2
			
			parameter										TAGRAM_ADDR_WIDTH  = PAGE_SIZE,
			parameter										TAGRAM_DATA_WIDTH  = 1 + (MEMBUS_ADDR_WIDTH - (PAGE_SIZE + LINE_SIZE)),
			parameter										DATARAM_ADDR_WIDTH = PAGE_SIZE + LINE_SIZE,
			parameter										DATARAM_DATA_WIDTH = MEMBUS_DATA_WIDTH
		)
		(
			// system
			input	wire									reset,
			input	wire									clk,
			input	wire									endian,
			
			// cpu bus
			input	wire									cpubus_interlock,
			input	wire									cpubus_en,
			input	wire									cpubus_we,
			input	wire	[CPUBUS_SEL_WIDTH-1:0]			cpubus_sel,
			input	wire	[CPUBUS_ADDR_WIDTH-1:0]			cpubus_addr,
			input	wire	[CPUBUS_DATA_WIDTH-1:0]			cpubus_wdata,
			output	wire	[CPUBUS_DATA_WIDTH-1:0]			cpubus_rdata,
			output	wire									cpubus_busy,
			
			// memory bus
			output	wire									membus_interlock,
			output	wire									membus_en,
			output	wire									membus_we,
			output	wire	[MEMBUS_SEL_WIDTH-1:0]			membus_sel,
			output	wire	[MEMBUS_ADDR_WIDTH-1:0]			membus_addr,
			output	wire	[MEMBUS_DATA_WIDTH-1:0]			membus_wdata,
			input	wire	[MEMBUS_DATA_WIDTH-1:0]			membus_rdata,
			output	wire									membus_busy,
			
			// tag ram
			output	reg		[WAY-1:0]						tagram_en,
			output	reg		[WAY-1:0]						tagram_we,
			output	reg		[WAY*TAGRAM_ADDR_WIDTH-1:0]		tagram_addr,
			output	reg		[WAY*TAGRAM_DATA_WIDTH-1:0]		tagram_wdata,
			input	wire	[WAY*TAGRAM_DATA_WIDTH-1:0]		tagram_rdata,
			
			// data ram
			output	reg		[WAY-1:0]						dataram_en,
			output	reg		[WAY-1:0]						dataram_we,
			output	reg		[WAY*DATARAM_ADDR_WIDTH-1:0]	dataram_addr,
			output	reg		[WAY*DATARAM_DATA_WIDTH-1:0]	dataram_wdata,
			input	wire	[WAY*DATARAM_DATA_WIDTH-1:0]	dataram_rdata
		);
	
	
	localparam	BUS_SIZE_RATE  = (MEMBUS_DATA_SIZE - CPUBUS_DATA_SIZE);
	localparam	BUS_WIDTH_RATE = (MEMBUS_DATA_WIDTH / CPUBUS_DATA_WIDTH);
	
	localparam	ADDR_OFFSET_WIDTH = LINE_SIZE;
	localparam	ADDR_INDEX_WIDTH  = PAGE_SIZE;
	localparam	ADDR_TAG_WIDTH    = MEMBUS_ADDR_WIDTH - (PAGE_SIZE + LINE_SIZE);
	
	
	
	// -----------------------------------------
	//  signals
	// -----------------------------------------
	
	integer									i, j;
	
	// all
	wire									interlock;
	
	// writeback stage
	wire									wbk_out_en;
	wire	[ADDR_OFFSET_WIDTH-1:0]			wbk_out_addr_offset;
	wire	[ADDR_INDEX_WIDTH-1:0]			wbk_out_addr_index;
	wire	[WAY-1:0]						wbk_out_we;
	wire									wbk_out_valid;
	wire	[ADDR_TAG_WIDTH-1:0]			wbk_out_tag;
	wire	[DATARAM_DATA_WIDTH-1:0]		wbk_out_data;
	
	
	
	// -----------------------------------------
	//  cache memory access stage
	// -----------------------------------------
	
	reg										cha_out_cpu_en;
	reg										cha_out_cpu_we;
	reg		[CPUBUS_SEL_WIDTH-1:0]			cha_out_cpu_sel;
	reg		[BUS_SIZE_RATE-1:0]				cha_out_cpu_addr_select;
	reg		[ADDR_OFFSET_WIDTH-1:0]			cha_out_cpu_addr_offset;
	reg		[ADDR_INDEX_WIDTH-1:0]			cha_out_cpu_addr_index;
	reg		[ADDR_TAG_WIDTH-1:0]			cha_out_cpu_addr_tag;
	reg		[CPUBUS_DATA_WIDTH-1:0]			cha_out_cpu_wdata;
	
	reg		[WAY-1:0]						cha_out_cache_valid;
	reg		[WAY*ADDR_TAG_WIDTH-1:0]		cha_out_cache_tag;
	reg		[WAY*DATARAM_DATA_WIDTH-1:0]	cha_out_cache_data;
	
	wire									cha_out_cpu_busy;
	
	
	wire	[BUS_SIZE_RATE-1:0]				cha_cpu_addr_select;
	wire	[ADDR_OFFSET_WIDTH-1:0]			cha_cpu_addr_offset;
	wire	[ADDR_INDEX_WIDTH-1:0]			cha_cpu_addr_index;
	wire	[ADDR_TAG_WIDTH-1:0]			cha_cpu_addr_tag;
	
	assign cha_cpu_addr_select = cpubus_addr[0                                                +: BUS_SIZE_RATE];
	assign cha_cpu_addr_offset = cpubus_addr[BUS_SIZE_RATE                                    +: ADDR_OFFSET_WIDTH];
	assign cha_cpu_addr_index  = cpubus_addr[BUS_SIZE_RATE+ADDR_OFFSET_WIDTH                  +: ADDR_INDEX_WIDTH];
	assign cha_cpu_addr_tag    = cpubus_addr[BUS_SIZE_RATE+ADDR_OFFSET_WIDTH+ADDR_INDEX_WIDTH +: ADDR_TAG_WIDTH];
	
	// cache memory access
	always @* begin
		for ( i = 0; i < WAY; i = i + 1 ) begin
			// tag ram
			tagram_en[i]                                           = ((cpubus_en & !cpubus_interlock) | wbk_out_en) & !interlock;
			tagram_we[i]                                           = wbk_out_en ? wbk_out_we[i]      : 1'b0;
			tagram_addr[TAGRAM_ADDR_WIDTH*i +: TAGRAM_ADDR_WIDTH]  = wbk_out_en ? wbk_out_addr_index : cha_cpu_addr_index;
			tagram_wdata[TAGRAM_DATA_WIDTH*i +: TAGRAM_DATA_WIDTH] = {wbk_out_valid, wbk_out_tag};
			{cha_out_cache_valid[i], cha_out_cache_tag[ADDR_TAG_WIDTH*i +: ADDR_TAG_WIDTH]} = tagram_rdata[TAGRAM_DATA_WIDTH*i +: TAGRAM_DATA_WIDTH];
			
			// data ram
			dataram_en[i]                                             = ((cpubus_en & !cpubus_interlock) | wbk_out_en) & !interlock;
			dataram_we[i]                                             = wbk_out_en ? wbk_out_we[i]                             : 1'b0;
			dataram_addr[DATARAM_ADDR_WIDTH*i +: DATARAM_ADDR_WIDTH]  = wbk_out_en ? {wbk_out_addr_index, wbk_out_addr_offset} : {cha_cpu_addr_index, cha_cpu_addr_offset};
			dataram_wdata[DATARAM_DATA_WIDTH*i +: DATARAM_DATA_WIDTH] = wbk_out_data;
			cha_out_cache_data[DATARAM_DATA_WIDTH*i +: DATARAM_DATA_WIDTH] = dataram_rdata[DATARAM_DATA_WIDTH*i +: DATARAM_DATA_WIDTH];
		end
	end
	
	// ff
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			cha_out_cpu_en          <= 1'b0;
			cha_out_cpu_we          <= 1'bx;
			cha_out_cpu_sel         <= {CPUBUS_SEL_WIDTH{1'bx}};
			cha_out_cpu_addr_select <= {BUS_SIZE_RATE{1'bx}};
			cha_out_cpu_addr_offset <= {ADDR_OFFSET_WIDTH{1'bx}};
			cha_out_cpu_addr_index  <= {ADDR_INDEX_WIDTH{1'bx}};
			cha_out_cpu_addr_tag    <= {ADDR_TAG_WIDTH{1'bx}};
			cha_out_cpu_wdata       <= {CPUBUS_DATA_WIDTH{1'bx}};
		end
		else begin
			if ( !interlock ) begin
				cha_out_cpu_en          <= (cpubus_en & !cpubus_interlock) & !wbk_out_en;
				cha_out_cpu_we          <= cpubus_we;
				cha_out_cpu_sel         <= cpubus_sel;
				cha_out_cpu_addr_select <= cha_cpu_addr_select;
				cha_out_cpu_addr_offset <= cha_cpu_addr_offset;
				cha_out_cpu_addr_index  <= cha_cpu_addr_index;
				cha_out_cpu_addr_tag    <= cha_cpu_addr_tag;
				cha_out_cpu_wdata       <= cpubus_wdata;
			end
		end
	end
	
	assign cha_out_cpu_busy = (cpubus_en & (wbk_out_en));
	
	
	
	// -----------------------------------------
	//  compare stage
	// -----------------------------------------

	// register
	reg										cmp_out_mem_en;
	reg										cmp_out_mem_we;
	reg		[ADDR_OFFSET_WIDTH-1:0]			cmp_out_mem_addr_offset;
	reg		[ADDR_INDEX_WIDTH-1:0]			cmp_out_mem_addr_index;
	reg		[ADDR_TAG_WIDTH-1:0]			cmp_out_mem_addr_tag;
	reg		[MEMBUS_SEL_WIDTH-1:0]			cmp_out_mem_sel;
	reg		[MEMBUS_DATA_WIDTH-1:0]			cmp_out_mem_wdata;
	reg										cmp_out_mem_last;
	
	reg		[WAY-1:0]						cmp_out_wbk_we;
	
	// compare
	reg										cmp_cache_hit;
	reg		[WAY-1:0]						cmp_cache_hit_mask;
	reg		[MEMBUS_DATA_WIDTH-1:0]			cmp_cache_data;
	
	always @* begin
		cmp_cache_hit  = 1'b0;
		cmp_cache_data = {MEMBUS_DATA_WIDTH{1'b0}};
		for ( i = 0; i < WAY; i = i + 1 ) begin : way
			cmp_cache_hit_mask[i] = (cha_out_cache_tag[ADDR_TAG_WIDTH*i +: ADDR_TAG_WIDTH] == cha_out_cpu_addr_tag) & cha_out_cache_valid[i];
			
			cmp_cache_hit  = cmp_cache_hit | cmp_cache_hit_mask[i];
			cmp_cache_data = cmp_cache_data | (cmp_cache_hit_mask[i] ? cha_out_cache_data[DATARAM_DATA_WIDTH*i +: DATARAM_DATA_WIDTH] : {MEMBUS_DATA_WIDTH{1'b0}});
		end
	end
	
	
	reg							cmp_last;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			cmp_out_mem_en          <= 1'b0;
			cmp_out_mem_we          <= 1'bx;
			cmp_out_mem_addr_offset <= {ADDR_OFFSET_WIDTH{1'bx}};
			cmp_out_mem_addr_index  <= {ADDR_INDEX_WIDTH{1'bx}};
			cmp_out_mem_addr_tag    <= {ADDR_TAG_WIDTH{1'bx}};
			cmp_out_mem_sel         <= {MEMBUS_SEL_WIDTH{1'bx}};
			cmp_out_mem_wdata       <= {MEMBUS_DATA_WIDTH{1'bx}};
			cmp_out_mem_last        <= 1'b1;
			cmp_out_wbk_we          <= {WAY{1'bx}};
		end
		else begin
			if ( !membus_busy ) begin
				if ( !cmp_out_mem_en | cmp_out_mem_last ) begin
					if ( cha_out_cpu_en & cha_out_cpu_we ) begin	// write through
						// write
						cmp_out_mem_en          <= 1'b1;
						cmp_out_mem_we          <= 1'b1;
						cmp_out_mem_addr_offset <= cha_out_cpu_addr_offset;
						cmp_out_mem_addr_index  <= cha_out_cpu_addr_index;
						cmp_out_mem_addr_tag    <= cha_out_cpu_addr_tag;
						for ( i = 0; i < BUS_WIDTH_RATE; i = i + 1 ) begin
							if ( (cha_out_cpu_addr_select ^ {BUS_SIZE_RATE{endian}}) == i ) begin
								cmp_out_mem_sel[CPUBUS_SEL_WIDTH*i +: CPUBUS_SEL_WIDTH] <= cha_out_cpu_sel;
								for ( j = 0; j < CPUBUS_SEL_WIDTH; j = j + 1 ) begin
									if ( cha_out_cpu_sel[i] ) begin
										cmp_out_mem_wdata[CPUBUS_SEL_WIDTH*i + 8*j +: 8] <= cha_out_cpu_wdata[8*j +: 8];
									end
									else begin
										cmp_out_mem_wdata[CPUBUS_SEL_WIDTH*i + 8*j +: 8] <= cha_out_cache_data[CPUBUS_SEL_WIDTH*i + 8*j +: 8];
									end
								end
							end
							else begin
								cmp_out_mem_sel[CPUBUS_SEL_WIDTH*i +: CPUBUS_SEL_WIDTH]     <= {CPUBUS_SEL_WIDTH{1'b0}};
								cmp_out_mem_wdata[CPUBUS_DATA_WIDTH*i +: CPUBUS_DATA_WIDTH] <= cha_out_cache_data[CPUBUS_DATA_WIDTH*i +: CPUBUS_DATA_WIDTH];
							end
						end
						cmp_out_mem_last <= 1'b1;
						cmp_out_wbk_we   <= cmp_cache_hit_mask;
					end
					else if ( cha_out_cpu_en & !cha_out_cpu_we & !cmp_cache_hit ) begin		// read miss-hit
						// read start
						cmp_out_mem_en          <= 1'b1;
						cmp_out_mem_we          <= 1'b0;
						cmp_out_mem_sel         <= {MEMBUS_SEL_WIDTH{1'b1}};
						cmp_out_mem_addr_offset <= {ADDR_OFFSET_WIDTH{1'b0}};
						cmp_out_mem_addr_index  <= cha_out_cpu_addr_index;
						cmp_out_mem_addr_tag    <= cha_out_cpu_addr_tag;
						cmp_out_mem_wdata       <= {BUS_WIDTH_RATE{1'bx}};
						cmp_out_mem_last        <= 1'b1;
						cmp_out_wbk_we          <= cmp_cache_hit_mask;
					end
					else begin
						// read continue
						cmp_out_mem_en          <= 1'b0;
						cmp_out_mem_addr_offset <= cmp_out_mem_addr_offset + 1;
						cmp_out_mem_last        <= ((cmp_out_mem_addr_offset + 1) == {ADDR_OFFSET_WIDTH{1'b1}});
					end
				end
				else begin
					cmp_out_mem_en          <= 1'b0;
					cmp_out_mem_we          <= 1'bx;
					cmp_out_mem_addr_offset <= {ADDR_OFFSET_WIDTH{1'bx}};
					cmp_out_mem_addr_index  <= {ADDR_INDEX_WIDTH{1'bx}};
					cmp_out_mem_addr_tag    <= {ADDR_TAG_WIDTH{1'bx}};
					cmp_out_mem_sel         <= {CPUBUS_ADDR_WIDTH{1'bx}};
					cmp_out_mem_wdata       <= {CPUBUS_DATA_WIDTH{1'bx}};
				end
			end
		end
	end
	
	
	// -----------------------------------------
	//  memory stage
	// -----------------------------------------
	
	reg									mem_out_mem_we;
	reg									mem_out_wbk_en;
	reg		[WAY-1:0]					mem_out_wbk_we;
	reg		[ADDR_OFFSET_WIDTH-1:0]		mem_out_wbk_addr_offset;
	reg		[ADDR_INDEX_WIDTH-1:0]		mem_out_wbk_addr_index;
	reg		[ADDR_TAG_WIDTH-1:0]		mem_out_wbk_addr_tag;
	reg		[MEMBUS_DATA_WIDTH-1:0]		mem_out_wbk_wdata;
	wire	[MEMBUS_DATA_WIDTH-1:0]		mem_out_wbk_rdata;
	
	// memory bus
	assign membus_interlock = 1'b0;
	assign membus_en        = cmp_out_mem_en;
	assign membus_we        = cmp_out_mem_we;
	assign membus_addr      = {cmp_out_mem_addr_tag, cmp_out_mem_addr_index, cmp_out_mem_addr_offset};
	assign membus_sel       = cmp_out_mem_sel;
	assign membus_wdata     = cmp_out_mem_wdata;
	
	always @ ( posedge clk or negedge reset ) begin
		if ( reset ) begin
			mem_out_mem_we          <= 1'b0;
			mem_out_wbk_en          <= 1'b0;
			mem_out_wbk_we          <= {WAY{1'bx}};
			mem_out_wbk_addr_offset <= {ADDR_OFFSET_WIDTH{1'bx}};
			mem_out_wbk_addr_index  <= {ADDR_INDEX_WIDTH{1'bx}};
			mem_out_wbk_addr_tag    <= {ADDR_TAG_WIDTH{1'bx}};
			mem_out_wbk_wdata       <= {MEMBUS_DATA_WIDTH{1'bx}};
		end
		else begin
			mem_out_mem_we          <= cmp_out_mem_we;
			mem_out_wbk_en          <= cmp_out_mem_en;
			mem_out_wbk_we          <= cmp_out_wbk_we;
			mem_out_wbk_addr_offset <= cmp_out_mem_addr_offset;
			mem_out_wbk_addr_index  <= cmp_out_mem_addr_index;
			mem_out_wbk_addr_tag    <= cmp_out_mem_addr_tag;
			mem_out_wbk_wdata       <= cmp_out_mem_wdata;
		end
	end
	assign mmem_out_wbk_rdata = membus_rdata;
	
	
	// -----------------------------------------
	//  writeback stage
	// -----------------------------------------
	
	assign wbk_out_en          = mem_out_wbk_en;
	assign wbk_out_we          = mem_out_wbk_we;
	assign wbk_out_addr_offset = mem_out_wbk_addr_offset;
	assign wbk_out_addr_index  = mem_out_wbk_addr_index;
	assign wbk_out_valid       = 1'b1;
	assign wbk_out_tag         = mem_out_wbk_addr_tag;
	assign wbk_out_data        = mem_out_mem_we ? mem_out_wbk_wdata : mem_out_wbk_rdata;
	
	
	// -----------------------------------------
	//  
	// -----------------------------------------
	
	assign cpubus_rdata = cmp_cache_hit ? cmp_cache_data : wbk_out_data;
	
endmodule
