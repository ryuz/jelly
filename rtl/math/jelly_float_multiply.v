// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   reciprocal
//
//                                 Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// reciprocal
module jelly_float_multiply
		#(
			parameter	EXP_WIDTH       = 8,
			parameter	EXP_OFFSET      = (1 << (EXP_WIDTH-1)) - 1,
			parameter	FRAC_WIDTH      = 23,
			parameter	FLOAT_WIDTH     = 1 + EXP_WIDTH + FRAC_WIDTH,	// sign + exp + frac
			
			parameter	USER_WIDTH      = 0,
			
			parameter	MASTER_IN_REGS  = 1,
			parameter	MASTER_OUT_REGS = 1,
			
			parameter	USER_BITS       = USER_WIDTH > 0 ? USER_WIDTH : 1
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						cke,
			
			input	wire	[USER_BITS-1:0]		s_user,
			input	wire	[FLOAT_WIDTH-1:0]	s_float0,
			input	wire	[FLOAT_WIDTH-1:0]	s_float1,
			input	wire						s_valid,
			output	wire						s_ready,
			
			output	wire	[USER_BITS-1:0]		m_user,
			output	wire	[FLOAT_WIDTH-1:0]	m_float,
			output	wire						m_valid,
			input	wire						m_ready
		);
	
	localparam	PIPELINE_STAGES = 4;
	
	wire	[PIPELINE_STAGES-1:0]	stage_cke;
	wire	[PIPELINE_STAGES-1:0]	stage_valid;
	
	wire	[USER_BITS-1:0]			src_user;
	wire							src_sign0;
	wire	[EXP_WIDTH-1:0]			src_exp0;
	wire	[FRAC_WIDTH-1:0]		src_frac0;
	wire							src_sign1;
	wire	[EXP_WIDTH-1:0]			src_exp1;
	wire	[FRAC_WIDTH-1:0]		src_frac1;
	
	wire	[USER_BITS-1:0]			sink_user;
	wire							sink_sign;
	wire	[EXP_WIDTH-1:0]			sink_exp;
	wire	[FRAC_WIDTH-1:0]		sink_frac;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(PIPELINE_STAGES),
				.S_DATA_WIDTH		(USER_BITS+FLOAT_WIDTH+FLOAT_WIDTH),
				.M_DATA_WIDTH		(USER_BITS+FLOAT_WIDTH),
				.AUTO_VALID			(1),
				.MASTER_IN_REGS		(MASTER_IN_REGS),
				.MASTER_OUT_REGS	(MASTER_OUT_REGS)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_data				({s_user, s_float1, s_float0}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({m_user, m_float}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			({PIPELINE_STAGES{1'bx}}),
				.src_data			({src_user, src_sign1, src_exp1, src_frac1, src_sign0, src_exp0, src_frac0}),
				.src_valid			(),
				.sink_data			({sink_user, sink_sign, sink_exp, sink_frac}),
				.buffered			()
			);
	
	reg		[USER_BITS-1:0]		st0_user;
	reg							st0_sign0;
	reg		[EXP_WIDTH-1:0]		st0_exp0;
	reg		[FRAC_WIDTH:0]		st0_frac0;
	reg							st0_sign1;
	reg		[EXP_WIDTH-1:0]		st0_exp1;
	reg		[FRAC_WIDTH:0]		st0_frac1;
	
	reg		[USER_BITS-1:0]		st1_user;
	reg							st1_sign;
	reg		[EXP_WIDTH:0]		st1_exp;
	reg		[FRAC_WIDTH+1:0]	st1_frac;
	
	reg		[USER_BITS-1:0]		st2_user;
	reg							st2_sign;
	reg		[EXP_WIDTH:0]		st2_exp;
	reg		[FRAC_WIDTH+1:0]	st2_frac;
	
	reg		[USER_BITS-1:0]		st3_user;
	reg							st3_sign;
	reg		[EXP_WIDTH-1:0]		st3_exp;
	reg		[FRAC_WIDTH-1:0]	st3_frac;
	
	always @(posedge clk) begin
		if ( stage_cke[0] ) begin
			st0_user  <= src_user;
			
			st0_sign0 <= src_sign0;
			st0_exp0  <= src_exp0;
			if ( src_exp0 == {EXP_WIDTH{1'b0}} ) begin
				st0_frac0 <= {1'b0, src_frac0};
			end
			else begin
				st0_frac0 <= {1'b1, src_frac0};
			end
			
			st0_sign1 <= src_sign1;
			st0_exp1  <= src_exp1;
			if ( src_exp1 == {EXP_WIDTH{1'b0}} ) begin
				st0_frac1 <= {1'b0, src_frac1};
			end
			else begin
				st0_frac1 <= {1'b1, src_frac1};
			end
		end
		
		if ( stage_cke[1] ) begin
			st1_user <= st0_user;
			st1_sign <= st0_sign0 ^ st0_sign1;
			st1_exp  <= {1'b0, st0_exp0} + {1'b0, st0_exp1} - EXP_OFFSET;
			st1_frac <= (({{(FRAC_WIDTH+1){1'b0}}, st0_frac0} * {{(FRAC_WIDTH+1){1'b0}}, st0_frac1}) >> FRAC_WIDTH);
		end
		
		if ( stage_cke[2] ) begin
			st2_user <= st1_user;
			st2_sign <= st1_sign;
			st2_exp  <= st1_exp;
			st2_frac <= st1_frac;
		end
		
		if ( stage_cke[3] ) begin
			st3_user <= st2_user;
			st3_sign <= st2_sign;
			if ( st2_exp[EXP_WIDTH] ) begin	// overflow or underflow
				st3_exp  <= {EXP_WIDTH{1'b0}};
				st3_frac <= {FRAC_WIDTH{1'b0}};
			end
			else begin
				if ( st2_frac[FRAC_WIDTH+1] ) begin
					st3_exp  <= st2_exp + 1'b1;
					st3_frac <= (st2_frac >> 1);
				end
				else begin
					st3_exp  <= st2_exp;
					st3_frac <= st2_frac;
				end
			end
		end
	end
	
	assign sink_user = st3_user;
	assign sink_sign = st3_sign;
	assign sink_exp  = st3_exp;
	assign sink_frac = st3_frac;
	
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
			6'h00:	mem_dout <= 46'h00000003f040;
			6'h01:	mem_dout <= 46'h3e07e003d1b1;
			6'h02:	mem_dout <= 46'h3c1f0783b482;
			6'h03:	mem_dout <= 46'h3a44c683989d;
			6'h04:	mem_dout <= 46'h387878037ded;
			6'h05:	mem_dout <= 46'h36b981836463;
			6'h06:	mem_dout <= 46'h350750034bec;
			6'h07:	mem_dout <= 46'h33615a03347c;
			6'h08:	mem_dout <= 46'h31c71c031e00;
			6'h09:	mem_dout <= 46'h30381c030870;
			6'h0a:	mem_dout <= 46'h2eb3e402f3bb;
			6'h0b:	mem_dout <= 46'h2d3a0682dfd8;
			6'h0c:	mem_dout <= 46'h2bca1a82ccba;
			6'h0d:	mem_dout <= 46'h2a63bd82ba5b;
			6'h0e:	mem_dout <= 46'h29069002a8ac;
			6'h0f:	mem_dout <= 46'h27b23a0297a8;
			6'h10:	mem_dout <= 46'h266666028745;
			6'h11:	mem_dout <= 46'h2522c382777b;
			6'h12:	mem_dout <= 46'h23e706026844;
			6'h13:	mem_dout <= 46'h22b2e4025998;
			6'h14:	mem_dout <= 46'h218618024b70;
			6'h15:	mem_dout <= 46'h206060023dc6;
			6'h16:	mem_dout <= 46'h1f417d023096;
			6'h17:	mem_dout <= 46'h1e29320223d9;
			6'h18:	mem_dout <= 46'h1d1745821789;
			6'h19:	mem_dout <= 46'h1c0b81020ba2;
			6'h1a:	mem_dout <= 46'h1b05b0020020;
			6'h1b:	mem_dout <= 46'h1a05a001f4fe;
			6'h1c:	mem_dout <= 46'h190b2101ea37;
			6'h1d:	mem_dout <= 46'h18160581dfca;
			6'h1e:	mem_dout <= 46'h17262081d5b0;
			6'h1f:	mem_dout <= 46'h163b4881cbe7;
			6'h20:	mem_dout <= 46'h15555501c26b;
			6'h21:	mem_dout <= 46'h14741f81b93a;
			6'h22:	mem_dout <= 46'h13978281b050;
			6'h23:	mem_dout <= 46'h12bf5a81a7ab;
			6'h24:	mem_dout <= 46'h11eb85019f47;
			6'h25:	mem_dout <= 46'h111be1819723;
			6'h26:	mem_dout <= 46'h105050018f3b;
			6'h27:	mem_dout <= 46'h0f88b281878d;
			6'h28:	mem_dout <= 46'h0ec4ec018018;
			6'h29:	mem_dout <= 46'h0e04e00178d9;
			6'h2a:	mem_dout <= 46'h0d48738171cd;
			6'h2b:	mem_dout <= 46'h0c8f8d016af5;
			6'h2c:	mem_dout <= 46'h0bda1281644b;
			6'h2d:	mem_dout <= 46'h0b27ed015dd1;
			6'h2e:	mem_dout <= 46'h0a7904815784;
			6'h2f:	mem_dout <= 46'h09cd42815161;
			6'h30:	mem_dout <= 46'h092492014b68;
			6'h31:	mem_dout <= 46'h087ede014599;
			6'h32:	mem_dout <= 46'h07dc11813fee;
			6'h33:	mem_dout <= 46'h073c1a813a6a;
			6'h34:	mem_dout <= 46'h069ee581350b;
			6'h35:	mem_dout <= 46'h060460012fce;
			6'h36:	mem_dout <= 46'h056c79012ab2;
			6'h37:	mem_dout <= 46'h04d7200125b8;
			6'h38:	mem_dout <= 46'h0444440120dd;
			6'h39:	mem_dout <= 46'h03b3d5811c21;
			6'h3a:	mem_dout <= 46'h0325c5011782;
			6'h3b:	mem_dout <= 46'h029a04011300;
			6'h3c:	mem_dout <= 46'h021084010e9a;
			6'h3d:	mem_dout <= 46'h018937010a4e;
			6'h3e:	mem_dout <= 46'h01041001061c;
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
