// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// selecter
module jelly_minmax
		#(
			parameter	NUM               = 2,
			parameter	COMMON_USER_WIDTH = 0,
			parameter	USER_WIDTH        = 0,
			parameter	DATA_WIDTH        = 32,
			parameter	DATA_SIGNED       = 0,
			parameter	CMP_MIN           = 0,		// minÇ©maxÇ©
			parameter	CMP_EQ            = 0,		// ìØílÇÃÇ∆Ç´ data0 Ç∆ data1 Ç«ÇøÇÁÇóDêÊÇ∑ÇÈÇ©
			
			parameter	COMMON_USER_BITS  = COMMON_USER_WIDTH > 0 ? COMMON_USER_WIDTH : 1,
			parameter	USER_BITS         = USER_WIDTH        > 0 ? USER_WIDTH        : 1
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			input	wire	[COMMON_USER_BITS-1:0]		s_common_user,
			input	wire	[NUM*USER_BITS-1:0]			s_user,
			input	wire	[NUM*DATA_WIDTH-1:0]		s_data,
			input	wire	[NUM-1:0]					s_en,
			input	wire								s_valid,
			
			output	wire	[COMMON_USER_BITS-1:0]		m_common_user,
			output	wire	[USER_BITS-1:0]				m_user,
			output	wire	[DATA_WIDTH-1:0]			m_data,
			output	wire								m_en,
			output	wire								m_valid
		);
	
	
	// àÍïîèàóùånÇ≈ $clog2 Ç™ê≥ÇµÇ≠ìÆÇ©Ç»Ç¢ÇÃÇ≈
	localparam	STAGES = NUM <=     2 ?  1 :
	                     NUM <=     4 ?  2 :
	                     NUM <=     8 ?  3 :
	                     NUM <=    16 ?  4 :
	                     NUM <=    32 ?  5 :
	                     NUM <=    64 ?  6 :
	                     NUM <=   128 ?  7 :
	                     NUM <=   256 ?  8 :
	                     NUM <=   512 ?  9 :
	                     NUM <=  1024 ? 10 :
	                     NUM <=  2048 ? 11 :
	                     NUM <=  4096 ? 12 :
	                     NUM <=  8192 ? 13 :
	                     NUM <= 16384 ? 14 :
	                     NUM <= 32768 ? 15 : 16;
	
	localparam	N      = (1 << (STAGES-1));
	
	
	// î‰är
	function cmp_data(
					input	[DATA_WIDTH-1:0]	in_data0,
					input						in_en0,
					input	[DATA_WIDTH-1:0]	in_data1,
					input						in_en1
				);
		reg		signed	[DATA_WIDTH:0]	data0;
		reg		signed	[DATA_WIDTH:0]	data1;
		begin
			if ( DATA_SIGNED ) begin
				data0 = {in_data0[DATA_WIDTH-1], in_data0};
				data1 = {in_data1[DATA_WIDTH-1], in_data1};
			end
			else begin
				data0 = {1'b0, in_data0};
				data1 = {1'b0, in_data1};
			end
			
			if ( in_en0 && in_en1 ) begin
				if ( CMP_EQ == 0 ) begin
					cmp_data = CMP_MIN ? (data1 <= data0) : (data1 >= data0);
				end
				else begin
					cmp_data = CMP_MIN ? (data1 <  data0) : (data1 > data0);
				end
			end
			else if ( in_en0 && !in_en1 ) begin
				cmp_data = 1'b0;
			end
			else if ( !in_en0 && in_en1 ) begin
				cmp_data = 1'b1;
			end
			else if ( !in_en0 && !in_en1 ) begin
				cmp_data = CMP_EQ;
			end
		end
	endfunction
	
	
	integer									i, j;
	
	reg		[STAGES*COMMON_USER_BITS-1:0]	reg_common_user;
	reg		[STAGES*N*USER_BITS-1:0]		reg_user;
	reg		[STAGES*N*DATA_WIDTH-1:0]		reg_data;
	reg		[STAGES*N-1:0]					reg_en;
	reg		[STAGES-1:0]					reg_valid;
	
	reg		[COMMON_USER_BITS-1:0]			tmp_common_user;
	reg		[(1 << STAGES)*USER_BITS-1:0]	tmp_user;
	reg		[(1 << STAGES)*DATA_WIDTH-1:0]	tmp_data;
	reg		[(1 << STAGES)-1:0]				tmp_en;
	reg										sel;
	
	always @(posedge clk) begin
		if ( cke ) begin
			for ( i = 0; i < STAGES; i = i+1 ) begin
				if ( i < STAGES - 1 ) begin
					tmp_common_user = reg_common_user[(i+1)*COMMON_USER_BITS +: COMMON_USER_BITS];
					tmp_user        = reg_user       [(i+1)*N*USER_BITS      +: N*USER_BITS];
					tmp_data        = reg_data       [(i+1)*N*DATA_WIDTH     +: N*DATA_WIDTH];
					tmp_en          = reg_en         [(i+1)*N                +: N];
				end
				else begin
					tmp_common_user = s_common_user;
					tmp_user        = s_user;
					tmp_data        = s_data;
					tmp_en          = s_en;
				end
				
				reg_common_user[i*COMMON_USER_BITS +: COMMON_USER_BITS] <= tmp_common_user;
				for ( j = 0; j < N; j = j+1 ) begin
					sel = cmp_data(tmp_data[(2*j+0)*DATA_WIDTH +: DATA_WIDTH], tmp_en[2*j+0],
					               tmp_data[(2*j+1)*DATA_WIDTH +: DATA_WIDTH], tmp_en[2*j+1]);
					
					reg_user[(i*N+j)*USER_BITS  +: USER_BITS]  <= tmp_user[(2*j+sel)*USER_BITS  +: USER_BITS];
					reg_data[(i*N+j)*DATA_WIDTH +: DATA_WIDTH] <= tmp_data[(2*j+sel)*DATA_WIDTH +: DATA_WIDTH];
					reg_en  [i*N+j]                            <= (tmp_en[2*j+0] || tmp_en[2*j+1]);
				end
			end
		end
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_valid <= {STAGES{1'b0}};
		end
		else begin
			reg_valid <= ({s_valid, reg_valid} >> 1);
		end
	end
	
	
	assign m_common_user = reg_common_user[0 +: COMMON_USER_BITS];
	assign m_user        = reg_user       [0 +: USER_BITS];
	assign m_data        = reg_data       [0 +: DATA_WIDTH];
	assign m_en          = reg_en         [0];
	assign m_valid       = reg_valid      [0];
	
	
endmodule


`default_nettype wire


// end of file
