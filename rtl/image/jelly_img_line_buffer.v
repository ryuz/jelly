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
			parameter	DATA_WIDTH  = 8,
			parameter	LINE_NUM    = 3,
			parameter	LINE_CENTER = LINE_NUM / 2,
			parameter	MAX_Y_NUM   = 1024,
			parameter	BORDER_CARE = 1,
			parameter	RAM_TYPE    = "block"
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			input	wire	[1:0]						param_border_type,
			input	wire	[DATA_WIDTH-1:0]			param_border_constant,
			
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
	
	
	localparam	[1:0]	BORDER_TYPE_CONSTANT    = 2'd00;
	localparam	[1:0]	BORDER_TYPE_REPLICATE   = 2'd01;
	localparam	[1:0]	BORDER_TYPE_REFLECT     = 2'd10;
	localparam	[1:0]	BORDER_TYPE_REFLECT_101 = 2'd11;
	
	
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
	
	
	genvar								i;
	
	generate
	if ( LINE_NUM > 1 ) begin
		// memory
		wire	[MEM_NUM-1:0]				mem_we;
		wire	[ADDR_WIDTH-1:0]			mem_addr;
		wire	[DATA_WIDTH-1:0]			mem_wdata;
		wire								mem_wfirst;
		wire								mem_wlast;
		wire	[MEM_NUM*DATA_WIDTH-1:0]	mem_rdata;
		
		generate
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
		endgenerate
		
		
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
		
		integer								y0, y1;
		reg									border_flag;
		
		reg		[LINE_NUM-1:0]				st4_line_first;
		reg		[LINE_NUM-1:0]				st4_line_last;
		reg									st4_pixel_first;
		reg									st4_pixel_last;
		reg		[LINE_NUM*DATA_WIDTH-1:0]	st4_data;
		
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
				
				st3_line_first    <= 1'b0;
				st3_line_last     <= 1'b0;
				st3_pixel_first   <= 1'b0;
				st3_pixel_last    <= 1'b0;
				st3_data          <= {DATA_WIDTH{1'bx}};
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
				st4_line_first  <= st3_line_first;
				st4_line_last   <= st3_line_last;
				st4_pixel_first <= st3_pixel_first;
				st4_pixel_last  <= st3_pixel_last;
				st4_data        <= st3_data;
				
				border_flag = 1'b0;
				for ( y0 = LINE_CENTER; y0 < LINE_NUM; y0 = y0+1 ) begin
					if ( !border_flag ) begin
						if ( st3_line_first[y0] ) begin
							border_flag = 1'b1;
							y1          = y0;
							if ( param_border_type == BORDER_TYPE_REFLECT_101 ) begin
								y1 = y0 - 1;
							end
						end
					end
					else begin
						if ( param_border_type == BORDER_TYPE_CONSTANT ) begin
							st4_data[y0*DATA_WIDTH +: DATA_WIDTH] <= param_border_constant;
						end
						else begin
							st4_data[y0*DATA_WIDTH +: DATA_WIDTH] <= st3_data[y1*DATA_WIDTH +: DATA_WIDTH];
							if ( param_border_type == BORDER_TYPE_REFLECT || param_border_type == BORDER_TYPE_REFLECT_101 ) begin
								y1 = y1 - 1;
							end
						end
					end
				end
				
				border_flag = 1'b0;
				for ( y0 = LINE_CENTER; y0 >= 0; y0 = y0-1 ) begin
					if ( !border_flag ) begin
						if ( st3_line_last[y0] ) begin
							border_flag = 1'b1;
							y1          = y0;
							if ( param_border_type == BORDER_TYPE_REFLECT_101 ) begin
								y1 = y0 + 1;
							end
						end
					end
					else begin
						if ( param_border_type == BORDER_TYPE_CONSTANT ) begin
							st4_data[y0*DATA_WIDTH +: DATA_WIDTH] <= param_border_constant;
						end
						else begin
							st4_data[y0*DATA_WIDTH +: DATA_WIDTH] <= st3_data[y1*DATA_WIDTH +: DATA_WIDTH];
							if ( param_border_constant == BORDER_TYPE_REFLECT || param_border_constant == BORDER_TYPE_REFLECT_101 ) begin
								y1 = y1 + 1;
							end
						end
					end
				end
			end
		end
		
		
		assign mem_we            = st0_we;
		assign mem_addr          = st0_addr;
		assign mem_wdata         = st0_data;
		assign mem_wfirst        = st0_line_first;
		assign mem_wlast         = st0_line_last;
		
		if ( BORDER_CARE ) begin
			assign m_img_line_first  = st4_line_first[LINE_CENTER];
			assign m_img_line_last   = st4_line_last[LINE_CENTER];
			assign m_img_pixel_first = st4_pixel_first;
			assign m_img_pixel_last  = st4_pixel_last;
			assign m_img_data        = st4_data;
		end
		else begin
			assign m_img_line_first  = st3_line_first[LINE_CENTER];
			assign m_img_line_last   = st3_line_last[LINE_CENTER];
			assign m_img_pixel_first = st3_pixel_first;
			assign m_img_pixel_last  = st3_pixel_last;
			assign m_img_data        = st3_data;
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
