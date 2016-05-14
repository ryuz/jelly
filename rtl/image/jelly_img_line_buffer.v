// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


//   フレーム期間中のデータ入力の無い期間は cke を落とすことを
// 前提としてデータ稠密で、メモリを READ_FIRST モードで最適化
//   フレーム末尾で吐き出しのためにブランクデータを入れる際は
// line_first と line_last は正しく制御が必要

module jelly_img_line_buffer
		#(
			parameter	DATA_WIDTH   = 8,
			parameter	LINE_NUM     = 3,
			parameter	LINE_CENTER  = LINE_NUM / 2,
			parameter	MAX_Y_NUM    = 1024,
			parameter	BORDER_MODE  = "REPLICATE",			// NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
			parameter	BORDER_VALUE = {DATA_WIDTH{1'b0}},	// BORDER_MODE == "CONSTANT"
			parameter	RAM_TYPE     = "block"
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			// slave (input)
			input	wire								s_img_line_first,
			input	wire								s_img_line_last,
			input	wire								s_img_pixel_first,
			input	wire								s_img_pixel_last,
			input	wire	[DATA_WIDTH-1:0]			s_img_data,
			
			// master (output)
			output	wire								m_img_line_first,
			output	wire								m_img_line_last,
			output	wire								m_img_pixel_first,
			output	wire								m_img_pixel_last,
			output	wire	[LINE_NUM*DATA_WIDTH-1:0]	m_img_data
		);
	
	
//	localparam	[1:0]	BORDER_TYPE_CONSTANT    = 2'd00;
//	localparam	[1:0]	BORDER_TYPE_REPLICATE   = 2'd01;
//	localparam	[1:0]	BORDER_TYPE_REFLECT     = 2'd10;
//	localparam	[1:0]	BORDER_TYPE_REFLECT_101 = 2'd11;
	
	
	localparam	ADDR_WIDTH     = (MAX_Y_NUM   <=    2) ?  1 :
	                             (MAX_Y_NUM   <=    4) ?  2 :
	                             (MAX_Y_NUM   <=    8) ?  3 :
	                             (MAX_Y_NUM   <=   16) ?  4 :
	                             (MAX_Y_NUM   <=   32) ?  5 :
	                             (MAX_Y_NUM   <=   64) ?  6 :
	                             (MAX_Y_NUM   <=  128) ?  7 :
	                             (MAX_Y_NUM   <=  256) ?  8 :
	                             (MAX_Y_NUM   <=  512) ?  9 :
	                             (MAX_Y_NUM   <= 1024) ? 10 :
	                             (MAX_Y_NUM   <= 2048) ? 11 :
	                             (MAX_Y_NUM   <= 4096) ? 12 :
	                             (MAX_Y_NUM   <= 8192) ? 13 : 14;
	
	localparam	MEM_NUM        = LINE_NUM - 1;
	
	localparam	LINE_SEL_WIDTH = (MEM_NUM <=    2) ?  1 :
	                             (MEM_NUM <=    4) ?  2 :
	                             (MEM_NUM <=    8) ?  3 :
	                             (MEM_NUM <=   16) ?  4 :
	                             (MEM_NUM <=   32) ?  5 :
	                             (MEM_NUM <=   64) ?  6 :
	                             (MEM_NUM <=  128) ?  7 :
	                             (MEM_NUM <=  256) ?  8 : 9;
	
	localparam	POS_WIDTH      = (LINE_NUM <=   1) ?  1 :
	                             (LINE_NUM <=   3) ?  2 :
	                             (LINE_NUM <=   7) ?  3 :
	                             (LINE_NUM <=  15) ?  4 :
	                             (LINE_NUM <=  31) ?  5 :
	                             (LINE_NUM <=  63) ?  6 :
	                             (LINE_NUM <= 127) ?  7 :
	                             (LINE_NUM <= 255) ?  8 : 9;
	
	
	
	genvar									i;
	
	generate
	if ( LINE_NUM > 1 ) begin
		// memory
		wire	[MEM_NUM-1:0]				mem_we;
		wire	[ADDR_WIDTH-1:0]			mem_addr;
		wire	[DATA_WIDTH-1:0]			mem_wdata;
		wire								mem_wfirst;
		wire								mem_wlast;
		wire	[MEM_NUM*DATA_WIDTH-1:0]	mem_rdata;
		
		for ( i = 0; i < MEM_NUM; i = i+1 ) begin : mem_loop
			jelly_ram_singleport
					#(
						.ADDR_WIDTH		(ADDR_WIDTH),
						.DATA_WIDTH		(DATA_WIDTH),
						.MEM_SIZE		(MAX_Y_NUM),
						.RAM_TYPE		(RAM_TYPE),
						.DOUT_REGS		(1),
						.MODE			("READ_FIRST")
					)
				jelly_ram_singleport
					(
						.clk			(clk),
						.en				(cke),
						.regcke			(cke),
						.we				(mem_we[i]),
						.addr			(mem_addr),
						.din			(mem_wdata),
						.dout			(mem_rdata[DATA_WIDTH*i +: DATA_WIDTH])
					);
		end
		
		
		// control
		reg		[MEM_NUM-1:0]				st0_we;
		reg		[ADDR_WIDTH-1:0]			st0_addr;
		reg									st0_line_first;
		reg									st0_line_last;
		reg									st0_pixel_first;
		reg									st0_pixel_last;
		reg		[DATA_WIDTH-1:0]			st0_data;
		
		reg									st1_line_first;
		reg									st1_line_last;
		reg									st1_pixel_first;
		reg									st1_pixel_last;
		reg		[DATA_WIDTH-1:0]			st1_data;
		
		reg		[LINE_SEL_WIDTH-1:0]		st2_sel;
		reg									st2_line_first;
		reg									st2_line_last;
		reg									st2_pixel_first;
		reg									st2_pixel_last;
		reg		[DATA_WIDTH-1:0]			st2_data;
		
		reg		[LINE_NUM-1:0]				st3_line_first;
		reg		[LINE_NUM-1:0]				st3_line_last;
		reg									st3_pixel_first;
		reg									st3_pixel_last;
		reg		[LINE_NUM*DATA_WIDTH-1:0]	st3_data;
		
		reg									st4_line_first;
		reg									st4_line_last;
		reg									st4_pixel_first;
		reg									st4_pixel_last;
		reg		[LINE_NUM*DATA_WIDTH-1:0]	st4_data;
		reg		[POS_WIDTH-1:0]				st4_pos_first;
		reg		[POS_WIDTH-1:0]				st4_pos_last;
		
		reg									st5_line_first;
		reg									st5_line_last;
		reg									st5_pixel_first;
		reg									st5_pixel_last;
		reg		[LINE_NUM*DATA_WIDTH-1:0]	st5_data;
		reg		[LINE_NUM*POS_WIDTH-1:0]	st5_pos_data;
		
		reg									st6_line_first;
		reg									st6_line_last;
		reg									st6_pixel_first;
		reg									st6_pixel_last;
		reg		[LINE_NUM*DATA_WIDTH-1:0]	st6_data;
		
		integer								y;
		
		always @(posedge clk) begin
			if ( reset ) begin
				st0_we            <= {MEM_NUM{1'b0}};
				st0_we[MEM_NUM-1] <= 1'b1;
				st0_addr          <= {ADDR_WIDTH{1'b0}};
				st0_line_first    <= 1'b0;
				st0_line_last     <= 1'b0;
				st0_pixel_first   <= 1'b0;
				st0_pixel_last    <= 1'b0;
				st0_data          <= {DATA_WIDTH{1'bx}};
				
				st1_line_first    <= 1'b0;
				st1_line_last     <= 1'b0;
				st1_pixel_first   <= 1'b0;
				st1_pixel_last    <= 1'b0;
				st1_data          <= {DATA_WIDTH{1'bx}};
				
				st2_sel           <= {LINE_SEL_WIDTH{1'b0}};
				st2_line_first    <= 1'b0;
				st2_line_last     <= 1'b0;
				st2_pixel_first   <= 1'b0;
				st2_pixel_last    <= 1'b0;
				st2_data          <= {DATA_WIDTH{1'bx}};
				
				st3_line_first    <= {LINE_NUM{1'b0}};
				st3_line_last     <= {LINE_NUM{1'b0}};
				st3_pixel_first   <= 1'b0;
				st3_pixel_last    <= 1'b0;
				st3_data          <= {(LINE_NUM*DATA_WIDTH){1'bx}};
				
				st4_line_first    <= 1'b0;
				st4_line_last     <= 1'b0;
				st4_pixel_first   <= 1'b0;
				st4_pixel_last    <= 1'b0;
				st4_data          <= {(LINE_NUM*DATA_WIDTH){1'bx}};
				st4_pos_first     <= {POS_WIDTH{1'bx}};
				st4_pos_last      <= {POS_WIDTH{1'bx}};
				
				st5_line_first    <= 1'b0;
				st5_line_last     <= 1'b0;
				st5_pixel_first   <= 1'b0;
				st5_pixel_last    <= 1'b0;
				st5_data          <= {(LINE_NUM*DATA_WIDTH){1'bx}};
				st5_pos_data      <= {(LINE_NUM*POS_WIDTH){1'bx}};
				
				st6_line_first    <= 1'b0;
				st6_line_last     <= 1'b0;
				st6_pixel_first   <= 1'b0;
				st6_pixel_last    <= 1'b0;
				st6_data          <= {(LINE_NUM*DATA_WIDTH){1'bx}};
			end
			else if ( cke ) begin
				// stage 0
				if ( s_img_pixel_first ) begin
					st0_we   <= ((st0_we >> 1) | (st0_we[0] << (MEM_NUM-1)));
					st0_addr <= {ADDR_WIDTH{1'b0}};
				end
				else begin
					st0_addr <= st0_addr + 1'b1;
				end
				
				st0_line_first  <= s_img_line_first;
				st0_line_last   <= s_img_line_last;
				st0_pixel_first <= s_img_pixel_first;
				st0_pixel_last  <= s_img_pixel_last;
				st0_data        <= s_img_data;
				
				// stage1
				st1_line_first  <= st0_line_first;
				st1_line_last   <= st0_line_last;
				st1_pixel_first <= st0_pixel_first;
				st1_pixel_last  <= st0_pixel_last;
				st1_data        <= st0_data;
				
				// stage2
				if ( st1_pixel_first ) begin
					st2_sel <= st2_sel - 1'b1;
					if ( st2_sel == {LINE_SEL_WIDTH{1'b0}} ) begin
						st2_sel <= MEM_NUM-1;
					end
				end
				st2_line_first  <= st1_line_first;
				st2_line_last   <= st1_line_last;
				st2_pixel_first <= st1_pixel_first;
				st2_pixel_last  <= st1_pixel_last;
				st2_data        <= st1_data;
				
				// stage3
				if ( st2_pixel_first ) begin
					st3_line_first[LINE_NUM-1:1] <= st3_line_first[LINE_NUM-2:0];
					st3_line_last[LINE_NUM-1:1]  <= st3_line_last[LINE_NUM-2:0];
				end
				st3_line_first[0] <= st2_line_first;
				st3_line_last[0]  <= st2_line_last;
				
				st3_pixel_first                            <= st2_pixel_first;
				st3_pixel_last                             <= st2_pixel_last;
				st3_data[LINE_NUM*DATA_WIDTH-1:DATA_WIDTH] <= ({mem_rdata, mem_rdata} >> (st2_sel * DATA_WIDTH));
				st3_data[DATA_WIDTH-1:0]                   <= st2_data;
				
				
				// stage4
				st4_line_first  <= st3_line_first[LINE_CENTER];
				st4_line_last   <= st3_line_last[LINE_CENTER];
				st4_pixel_first <= st3_pixel_first;
				st4_pixel_last  <= st3_pixel_last;
				st4_data        <= st3_data;
				st4_pos_first   <= (LINE_NUM-1);
				st4_pos_last    <= 0;
				
				begin : search_first
					for ( y = LINE_CENTER; y < LINE_NUM; y = y+1 ) begin
						if ( st3_line_first[y] ) begin
							st4_pos_first <= y;
							disable search_first;
						end
					end
				end
				
				begin : search_last
					for ( y = LINE_CENTER; y >= 0; y = y-1 ) begin
						if ( st3_line_last[y] ) begin
							st4_pos_last <= y;
							disable search_last;
						end
					end
				end
				
				
				// stage5
				st5_line_first  <= st4_line_first;
				st5_line_last   <= st4_line_last;
				st5_pixel_first <= st4_pixel_first;
				st5_pixel_last  <= st4_pixel_last;
				st5_data        <= st4_data;
				
				for ( y = 0; y < LINE_NUM; y = y+1 ) begin
					st5_pos_data[y*POS_WIDTH +: POS_WIDTH] <= y;
					if ( y > LINE_CENTER ) begin
						if ( y > st4_pos_first ) begin
							if      ( BORDER_MODE == "CONSTANT"    ) begin st5_pos_data[y*POS_WIDTH +: POS_WIDTH] <= LINE_NUM;                end
							else if ( BORDER_MODE == "REPLICATE"   ) begin st5_pos_data[y*POS_WIDTH +: POS_WIDTH] <= st4_pos_first;           end
							else if ( BORDER_MODE == "REFLECT"     ) begin st5_pos_data[y*POS_WIDTH +: POS_WIDTH] <= st4_pos_first*2 - y;     end
							else if ( BORDER_MODE == "REFLECT_101" ) begin st5_pos_data[y*POS_WIDTH +: POS_WIDTH] <= st4_pos_first*2 - y - 1; end
						end
					end
					else if ( y < LINE_CENTER ) begin
						if ( y < st4_pos_last ) begin
							if      ( BORDER_MODE == "CONSTANT"    ) begin st5_pos_data[y*POS_WIDTH +: POS_WIDTH] <= LINE_NUM;                end
							else if ( BORDER_MODE == "REPLICATE"   ) begin st5_pos_data[y*POS_WIDTH +: POS_WIDTH] <= st4_pos_first;           end
							else if ( BORDER_MODE == "REFLECT"     ) begin st5_pos_data[y*POS_WIDTH +: POS_WIDTH] <= st4_pos_first*2 - y;     end
							else if ( BORDER_MODE == "REFLECT_101" ) begin st5_pos_data[y*POS_WIDTH +: POS_WIDTH] <= st4_pos_first*2 - y + 1; end
						end
					end
				end
				
				// stage6
				st6_line_first  <= st5_line_first;
				st6_line_last   <= st5_line_last;
				st6_pixel_first <= st5_pixel_first;
				st6_pixel_last  <= st5_pixel_last;
				st6_data        <= st5_data;
				for ( y = 0; y < LINE_NUM; y = y+1 ) begin
					st6_data[y*DATA_WIDTH +: DATA_WIDTH] <= ({BORDER_VALUE, st5_data} >> (DATA_WIDTH * st5_pos_data[y*POS_WIDTH +: POS_WIDTH]));
				end
			end
		end
		
		assign mem_we     = st0_we;
		assign mem_addr   = st0_addr;
		assign mem_wdata  = st0_data;
		assign mem_wfirst = st0_line_first;
		assign mem_wlast  = st0_line_last;
		
		
		
		if ( BORDER_MODE == "NONE" ) begin
			assign m_img_line_first  = st4_line_first[LINE_CENTER];
			assign m_img_line_last   = st4_line_last[LINE_CENTER];
			assign m_img_pixel_first = st4_pixel_first;
			assign m_img_pixel_last  = st4_pixel_last;
			assign m_img_data        = st4_data;
		end
		else begin
			assign m_img_line_first  = st6_line_first;
			assign m_img_line_last   = st6_line_last;
			assign m_img_pixel_first = st6_pixel_first;
			assign m_img_pixel_last  = st6_pixel_last;
			assign m_img_data        = st6_data;
		end
	end
	else begin
		assign m_img_line_first  = s_img_line_first;
		assign m_img_line_last   = s_img_line_last;
		assign m_img_pixel_first = s_img_pixel_first;
		assign m_img_pixel_last  = s_img_pixel_last;
		assign m_img_data        = s_img_data;
	end
	endgenerate
	
	
endmodule


`default_nettype wire


// end of file
