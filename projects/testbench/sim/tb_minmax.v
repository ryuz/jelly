
`timescale 1ns / 1ps
`default_nettype none


module tb_minmax();
	localparam RATE = 10.0;
	
	initial begin
		$dumpfile("tb_minmax.vcd");
		$dumpvars(0, tb_minmax);
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	always #(RATE*20)	reset = 1'b0;
	
	
	parameter	NUM               = 5;
	parameter	COMMON_USER_WIDTH = 4+8;
	parameter	USER_WIDTH        = 4;
	parameter	DATA_WIDTH        = 8;
	parameter	DATA_SIGNED       = 0;
	parameter	CMP_MIN           = 1;		// min‚©max‚©
	parameter	CMP_EQ            = 0;		// “¯’l‚Ì‚Æ‚« data0 ‚Æ data1 ‚Ç‚¿‚ç‚ð—Dæ‚·‚é‚©
	
	parameter	COMMON_USER_BITS  = COMMON_USER_WIDTH > 0 ? COMMON_USER_WIDTH : 1;
	parameter	USER_BITS         = USER_WIDTH        > 0 ? USER_WIDTH        : 1;
	
	
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
	
	
	
	reg									cke = 1'b1;
	
	reg		[COMMON_USER_BITS-1:0]		s_common_user;
	reg		[NUM*USER_BITS-1:0]			s_user;
	reg		[NUM*DATA_WIDTH-1:0]		s_data;
	reg		[NUM-1:0]					s_en;
	reg									s_valid = 0;
	
	wire	[COMMON_USER_BITS-1:0]		m_common_user;
	wire	[USER_BITS-1:0]				m_user;
	wire	[DATA_WIDTH-1:0]			m_data;
	wire								m_en;
	wire								m_valid;
	
	jelly_minmax
			#(
				.NUM               (NUM),
				.COMMON_USER_WIDTH (COMMON_USER_WIDTH),
				.USER_WIDTH        (USER_WIDTH),
				.DATA_WIDTH        (DATA_WIDTH),
				.DATA_SIGNED       (DATA_SIGNED),
				.CMP_MIN           (CMP_MIN),
				.CMP_EQ            (CMP_EQ)
			)
		i_minmax
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_common_user		(s_common_user),
				.s_user				(s_user),
				.s_data				(s_data),
				.s_en				(s_en),
				.s_valid			(s_valid),
				
				.m_common_user		(m_common_user),
				.m_user				(m_user),
				.m_data				(m_data),
				.m_en				(m_en),
				.m_valid			(m_valid)
			);
	
	jelly_minmax2
			#(
				.NUM               (NUM),
				.COMMON_USER_WIDTH (COMMON_USER_WIDTH),
				.USER_WIDTH        (USER_WIDTH),
				.DATA_WIDTH        (DATA_WIDTH),
				.DATA_SIGNED       (DATA_SIGNED),
				.CMP_MIN           (CMP_MIN),
				.CMP_EQ            (CMP_EQ)
			)
		i_minmax2
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_common_user		(s_common_user),
				.s_user				(s_user),
				.s_data				(s_data),
				.s_en				(s_en),
				.s_valid			(s_valid),
				
				.m_common_user		(),
				.m_user				(),
				.m_data				(),
				.m_en				(),
				.m_valid			()
			);
	
	/*
	wire	[COMMON_USER_BITS-1:0]	st0_common_user = i_minmax.reg_common_user[0*COMMON_USER_BITS +: COMMON_USER_BITS];
	wire	[N*USER_BITS-1:0]		st0_user        = i_minmax.reg_user       [0*N*USER_BITS      +: N*USER_BITS];
	wire	[N*DATA_WIDTH-1:0]		st0_data        = i_minmax.reg_data       [0*N*DATA_WIDTH     +: N*DATA_WIDTH];
	wire	[N-1:0]					st0_en          = i_minmax.reg_en         [0*N                +: N];
	wire							st0_valid       = i_minmax.reg_valid      [0                  +: 1];
	
	wire	[COMMON_USER_BITS-1:0]	st1_common_user = i_minmax.reg_common_user[1*COMMON_USER_BITS +: COMMON_USER_BITS];
	wire	[N*USER_BITS-1:0]		st1_user        = i_minmax.reg_user       [1*N*USER_BITS      +: N*USER_BITS];
	wire	[N*DATA_WIDTH-1:0]		st1_data        = i_minmax.reg_data       [1*N*DATA_WIDTH     +: N*DATA_WIDTH];
	wire	[N-1:0]					st1_en          = i_minmax.reg_en         [1*N                +: N];
	wire							st1_valid       = i_minmax.reg_valid      [1                  +: 1];
	
	wire	[COMMON_USER_BITS-1:0]	st2_common_user = i_minmax.reg_common_user[2*COMMON_USER_BITS +: COMMON_USER_BITS];
	wire	[N*USER_BITS-1:0]		st2_user        = i_minmax.reg_user       [2*N*USER_BITS      +: N*USER_BITS];
	wire	[N*DATA_WIDTH-1:0]		st2_data        = i_minmax.reg_data       [2*N*DATA_WIDTH     +: N*DATA_WIDTH];
	wire	[N-1:0]					st2_en          = i_minmax.reg_en         [2*N                +: N];
	wire							st2_valid       = i_minmax.reg_valid      [2                  +: 1];
	*/
	
	initial begin
		#500
		@(posedge clk)
			$display("-----");
			s_common_user <= 1;
			s_user        <= {4'h4,  4'h3,  4'h2 , 4'h1,  4'h0 };
			s_data        <= {8'h15, 8'h14, 8'h13, 8'h12, 8'h11};
			s_en          <= {1'b1,  1'b1,  1'b1,  1'b1,  1'b1 };
			s_valid       <= 1'b1;
			
		@(posedge clk);
			$display("-----");
			s_common_user <= 2;
			s_user        <= {4'h4,  4'h3,  4'h2 , 4'h1,  4'h0 };
			s_data        <= {8'h15, 8'h44, 8'h10, 8'h12, 8'h33};
			s_en          <= {1'b1,  1'b1,  1'b1,  1'b1,  1'b1 };
			s_valid       <= 1'b1;
		@(posedge clk);
			s_valid       <= 1'b0;
			
		@(posedge clk);
			$display("-----");
			s_common_user <= 3;
			s_user        <= {4'h4,  4'h3,  4'h2 , 4'h1,  4'h0 };
			s_data        <= {8'h15, 8'h14, 8'h12, 8'h12, 8'h33};
			s_en          <= {1'b1,  1'b1,  1'b1,  1'b1,  1'b1 };
			s_valid       <= 1'b1;
			
		@(posedge clk);
			$display("-----");
			s_common_user <= 3;
			s_user        <= {4'h4,  4'h3,  4'h2 , 4'h1,  4'h0 };
			s_data        <= {8'h15, 8'h55, 8'h12, 8'h55, 8'h33};
			s_en          <= {1'b1,  1'b1,  1'b1,  1'b1,  1'b1 };
			s_valid       <= 1'b1;
			
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
			$finish();
	end
	
	
endmodule


`default_nettype wire


// end of file
