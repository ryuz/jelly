// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   reciprocal
//
//                                 Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// 逆数テーブル
module jelly_float_reciprocal
		#(
			parameter	EXP_WIDTH   = 8,
			parameter	EXP_OFFSET  = (1 << (EXP_WIDTH-1)) - 1,
			parameter	FRAC_WIDTH  = 23,
			parameter	FLOAT_WIDTH = 1 + EXP_WIDTH + FRAC_WIDTH,	// sign + exp + frac
			
			parameter	D_WIDTH     = 6,							// interpolation table addr bits
			parameter	K_WIDTH     = FRAC_WIDTH - D_WIDTH,
			parameter	GRAD_WIDTH  = FRAC_WIDTH,
			
			parameter	RAM_TYPE    = "distributed",
			
			parameter	MAKE_TABLE  = 1,
			parameter	WRITE_TABLE = 0,
			parameter	READ_TABLE  = 0,
			parameter	FILE_NAME   = "float_reciprocal.hex"
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						cke,
			
			input	wire	[FLOAT_WIDTH-1:0]	s_float,
			input	wire						s_valid,
			output	wire						s_ready,
			
			output	wire	[FLOAT_WIDTH-1:0]	m_float,
			output	wire						m_valid,
			input	wire						m_ready
		);
	
	localparam	PIPELINE_STAGES = 5;
	
	wire	[PIPELINE_STAGES-1:0]	stage_cke;
	wire	[PIPELINE_STAGES-1:0]	stage_valid;
	
	wire							src_sign;
	wire	[EXP_WIDTH-1:0]			src_exp;
	wire	[FRAC_WIDTH-1:0]		src_frac;
	
	wire							sink_sign;
	wire	[EXP_WIDTH-1:0]			sink_exp;
	wire	[FRAC_WIDTH-1:0]		sink_frac;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(PIPELINE_STAGES),
				.S_DATA_WIDTH		(FLOAT_WIDTH),
				.M_DATA_WIDTH		(FLOAT_WIDTH),
				.AUTO_VALID			(1)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_data				(s_float),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				(m_float),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			({PIPELINE_STAGES{1'bx}}),
				.src_data			({src_sign, src_exp, src_frac}),
				.src_valid			(),
				.sink_data			({sink_sign, sink_exp, sink_frac}),
				.buffered			()
			);
	
	wire	[FRAC_WIDTH-1:0]	st1_frac;
	wire	[FRAC_WIDTH-1:0]	st1_grad;
	
	generate
	if ( FRAC_WIDTH == 23 && D_WIDTH == 6 && GRAD_WIDTH == 23 && !MAKE_TABLE && !WRITE_TABLE && !READ_TABLE ) begin
		// どんな合成器でも１種類は動くようにテーブル化
		jelly_float_reciprocal_frac23_d6
			i_float_reciprocal_frac23_d6
				(
					.clk			(clk),
					
					.cke			(stage_cke[1:0]),
					
					.in_d			(src_frac[FRAC_WIDTH-1 -: D_WIDTH]),
					
					.out_frac		(st1_frac),
					.out_grad		(st1_grad)
				);
	end
	else begin
		// テーブル生成
		jelly_float_reciprocal_table
				#(
					.FRAC_WIDTH		(FRAC_WIDTH),
					.D_WIDTH		(D_WIDTH),
					.K_WIDTH		(K_WIDTH),
					.GRAD_WIDTH		(GRAD_WIDTH),
					.OUT_REGS		(1),
					.RAM_TYPE		(RAM_TYPE),
					
					.WRITE_TABLE	(WRITE_TABLE),
					.READ_TABLE		(READ_TABLE),
					.FILE_NAME		(FILE_NAME)
				)
			i_float_reciprocal_table
				(
					.clk			(clk),
					
					.cke			(stage_cke[1:0]),
					
					.in_d			(src_frac[FRAC_WIDTH-1 -: D_WIDTH]),
					
					.out_frac		(st1_frac),
					.out_grad		(st1_grad)
				);
	end
	endgenerate
	
	reg							st0_sign;
	reg		[EXP_WIDTH-1:0]		st0_exp;
	reg							st0_frac_one;
	reg		[K_WIDTH-1:0]		st0_k;
	
	reg							st1_sign;
	reg		[EXP_WIDTH-1:0]		st1_exp;
	reg							st1_frac_one;
	reg		[K_WIDTH-1:0]		st1_k;
	
	reg							st2_sign;
	reg		[EXP_WIDTH-1:0]		st2_exp;
	reg		[FRAC_WIDTH-1:0]	st2_frac;
	reg		[K_WIDTH-1:0]		st2_k;
	reg		[GRAD_WIDTH-1:0]	st2_grad;

	reg							st3_sign;
	reg		[EXP_WIDTH-1:0]		st3_exp;
	reg		[FRAC_WIDTH-1:0]	st3_frac;
	reg		[GRAD_WIDTH-1:0]	st3_diff;
	
	reg							st4_sign;
	reg		[EXP_WIDTH-1:0]		st4_exp;
	reg		[FRAC_WIDTH-1:0]	st4_frac;
	
	always @(posedge clk) begin
		if ( stage_cke[0] ) begin
			st0_sign     <= src_sign;
			st0_exp      <= src_exp;
			st0_frac_one <= (src_frac == {FRAC_WIDTH{1'b0}});
			st0_k        <= src_frac[0 +: K_WIDTH];
		end
		
		if ( stage_cke[1] ) begin
			st1_sign     <= st0_sign;
			st1_exp      <= -(st0_exp - EXP_OFFSET) + st0_frac_one + EXP_OFFSET - 1;
			st1_frac_one <= st0_frac_one;
			st1_k        <= st0_k;
		end
		
		if ( stage_cke[2] ) begin
			st2_sign <= st1_sign;
			st2_exp  <= st1_exp;
			st2_frac <= st1_frac;
			st2_grad <= st1_grad;
			st2_k    <= st1_k;
		end
		
		if ( stage_cke[3] ) begin
			st3_sign <= st2_sign;
			st3_exp  <= st2_exp;
			st3_frac <= st2_frac;
			st3_diff <= (({{GRAD_WIDTH{1'b0}}, st2_grad} * {{K_WIDTH{1'b0}}, st2_k}) >> K_WIDTH);
		end
		
		if ( stage_cke[4] ) begin
			st4_sign <= st3_sign;
			st4_exp  <= st3_exp;
			st4_frac <= st3_frac - st3_diff;
		end
	end
	
	assign sink_sign = st4_sign;
	assign sink_exp  = st4_exp;
	assign sink_frac = st4_frac;
	
endmodule



module jelly_float_reciprocal_table
		#(
			parameter	FRAC_WIDTH  = 23,
			parameter	D_WIDTH     = 6,
			parameter	K_WIDTH     = FRAC_WIDTH - D_WIDTH,
			parameter	GRAD_WIDTH  = FRAC_WIDTH,
			parameter	OUT_REGS    = 1,
			parameter	RAM_TYPE    = "distributed",
			
			parameter	WRITE_TABLE = 0,
			parameter	READ_TABLE  = 0,
			parameter	FILE_NAME   = "float_reciprocal.hex"
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire	[1:0]				cke,
			
			input	wire	[D_WIDTH-1:0]		in_d,
			
			output	wire	[FRAC_WIDTH-1:0]	out_frac,
			output	wire	[GRAD_WIDTH-1:0]	out_grad
		);
	
	
	// テーブル定義
	localparam	TBL_WIDTH = FRAC_WIDTH + GRAD_WIDTH;
	localparam	TBL_SIZE  = (1 << D_WIDTH);
	
	(* RAM_STYLE=RAM_TYPE *)	reg		[TBL_WIDTH-1:0]		mem	[0:TBL_SIZE-1];
	
	
	// テーブル初期化
	integer						i;
	integer						fp;
	
	reg		[FRAC_WIDTH+1:0]	step;
	reg		[FRAC_WIDTH+1:0]	base, base_recip;
	reg		[FRAC_WIDTH+1:0]	next, next_recip;
	
	reg		[FRAC_WIDTH:0]		base_frac;
	reg		[FRAC_WIDTH:0]		next_frac;
	reg		[FRAC_WIDTH-1:0]	grad;
	reg		[FRAC_WIDTH-1:0]	grad_max;
	
	
	initial begin
		step                     = {(FRAC_WIDTH+2){1'b0}};
		step[FRAC_WIDTH-D_WIDTH] = 1'b1;
		
		base      = {2'b01, {FRAC_WIDTH{1'b0}}};
		base_frac = {2'b10, {(FRAC_WIDTH*2){1'b0}}} / base;
		
		grad_max = 0;
		for ( i = 0; i < TBL_SIZE; i = i+1 ) begin
			next      = base + step;
			next_frac = {2'b10, {(FRAC_WIDTH*2){1'b0}}} / next;
			
			grad       = base_frac - next_frac;
			if ( grad > grad_max ) grad_max = grad;
			
			mem[i] = {base_frac[0 +: FRAC_WIDTH], grad[0 +: GRAD_WIDTH]};
			
			base       = next;
			base_frac  = next_frac;
		end
//		$display("grad_max:%h", grad_max);
		
		// テーブルをファイル出力
		if ( WRITE_TABLE ) begin
			fp = $fopen(FILE_NAME, "w");
			for ( i = 0; i < TBL_SIZE; i = i+1 ) begin
				$fdisplay(fp, "%h", mem[i]);
			end
			$fclose(fp);
		end
		
		// テーブルをファイルから入力
		if ( READ_TABLE) begin
			$readmemh(FILE_NAME, mem);
		end
	end
	
	// read memory
	reg		[TBL_WIDTH-1:0]		tbl_out;
	always @(posedge clk) begin
		if ( cke[0] ) begin
			tbl_out <= mem[in_d];
		end
	end
	
	
	
	generate
	if ( OUT_REGS ) begin
		// output register
		reg		[TBL_WIDTH-1:0]		tbl_reg;
		always @(posedge clk) begin
			if ( cke[1] ) begin
				tbl_reg <= tbl_out;
			end
		end
		
		assign out_frac = tbl_reg[GRAD_WIDTH +: FRAC_WIDTH];
		assign out_grad = tbl_reg[0          +: GRAD_WIDTH];
	end
	else begin
		assign out_frac = tbl_out[GRAD_WIDTH +: FRAC_WIDTH];
		assign out_grad = tbl_out[0          +: GRAD_WIDTH];
	end
	endgenerate
	
	
endmodule



// 固定テーブル
module jelly_float_reciprocal_frac23_d6
		(
			input	wire				reset,
			input	wire				clk,
			input	wire	[1:0]		cke,
			
			input	wire	[5:0]		in_d,
			
			output	wire	[22:0]		out_frac,
			output	wire	[22:0]		out_grad
		);
	
	(* rom_style = "distributed" *)		reg		[45:0]		mem_dout;
	
	always @(posedge clk) begin
		if ( cke[0] ) begin
			case ( in_d )
			6'h00:	mem_dout <= 46'h00000003f03f;
			6'h01:	mem_dout <= 46'h3e07e083d1b1;
			6'h02:	mem_dout <= 46'h3c1f0803b483;
			6'h03:	mem_dout <= 46'h3a44c683989c;
			6'h04:	mem_dout <= 46'h387878837ded;
			6'h05:	mem_dout <= 46'h36b982036463;
			6'h06:	mem_dout <= 46'h350750834bed;
			6'h07:	mem_dout <= 46'h33615a03347b;
			6'h08:	mem_dout <= 46'h31c71c831e01;
			6'h09:	mem_dout <= 46'h30381c03086f;
			6'h0a:	mem_dout <= 46'h2eb3e482f3bb;
			6'h0b:	mem_dout <= 46'h2d3a0702dfd8;
			6'h0c:	mem_dout <= 46'h2bca1b02ccbb;
			6'h0d:	mem_dout <= 46'h2a63bd82ba5a;
			6'h0e:	mem_dout <= 46'h29069082a8ac;
			6'h0f:	mem_dout <= 46'h27b23a8297a8;
			6'h10:	mem_dout <= 46'h266666828745;
			6'h11:	mem_dout <= 46'h2522c402777c;
			6'h12:	mem_dout <= 46'h23e706026844;
			6'h13:	mem_dout <= 46'h22b2e4025997;
			6'h14:	mem_dout <= 46'h218618824b70;
			6'h15:	mem_dout <= 46'h206060823dc7;
			6'h16:	mem_dout <= 46'h1f417d023096;
			6'h17:	mem_dout <= 46'h1e29320223d8;
			6'h18:	mem_dout <= 46'h1d1746021789;
			6'h19:	mem_dout <= 46'h1c0b81820ba2;
			6'h1a:	mem_dout <= 46'h1b05b0820020;
			6'h1b:	mem_dout <= 46'h1a05a081f4fe;
			6'h1c:	mem_dout <= 46'h190b2181ea38;
			6'h1d:	mem_dout <= 46'h18160581dfca;
			6'h1e:	mem_dout <= 46'h17262081d5af;
			6'h1f:	mem_dout <= 46'h163b4901cbe7;
			6'h20:	mem_dout <= 46'h15555581c26c;
			6'h21:	mem_dout <= 46'h14741f81b93a;
			6'h22:	mem_dout <= 46'h13978281b050;
			6'h23:	mem_dout <= 46'h12bf5a81a7ab;
			6'h24:	mem_dout <= 46'h11eb85019f47;
			6'h25:	mem_dout <= 46'h111be1819722;
			6'h26:	mem_dout <= 46'h105050818f3b;
			6'h27:	mem_dout <= 46'h0f88b301878d;
			6'h28:	mem_dout <= 46'h0ec4ec818018;
			6'h29:	mem_dout <= 46'h0e04e08178d9;
			6'h2a:	mem_dout <= 46'h0d48740171ce;
			6'h2b:	mem_dout <= 46'h0c8f8d016af4;
			6'h2c:	mem_dout <= 46'h0bda1301644c;
			6'h2d:	mem_dout <= 46'h0b27ed015dd1;
			6'h2e:	mem_dout <= 46'h0a7904815783;
			6'h2f:	mem_dout <= 46'h09cd43015161;
			6'h30:	mem_dout <= 46'h092492814b69;
			6'h31:	mem_dout <= 46'h087ede014598;
			6'h32:	mem_dout <= 46'h07dc12013fef;
			6'h33:	mem_dout <= 46'h073c1a813a6a;
			6'h34:	mem_dout <= 46'h069ee581350a;
			6'h35:	mem_dout <= 46'h060460812fce;
			6'h36:	mem_dout <= 46'h056c79812ab2;
			6'h37:	mem_dout <= 46'h04d7208125b8;
			6'h38:	mem_dout <= 46'h0444448120de;
			6'h39:	mem_dout <= 46'h03b3d5811c21;
			6'h3a:	mem_dout <= 46'h0325c5011782;
			6'h3b:	mem_dout <= 46'h029a04011300;
			6'h3c:	mem_dout <= 46'h021084010e99;
			6'h3d:	mem_dout <= 46'h018937810a4e;
			6'h3e:	mem_dout <= 46'h01041081061d;
			6'h3f:	mem_dout <= 46'h008102010204;
			endcase
		end
	end
	
	reg		[22:0]		reg_frac;
	reg		[22:0]		reg_grad;
	
	always @(posedge clk) begin
		if ( cke[1] ) begin
			{reg_frac, reg_grad} <= mem_dout;
		end
	end
	
	assign out_frac = reg_frac;
	assign out_grad = reg_grad;
	
	
endmodule



`default_nettype wire



// end of file
