// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// border
module jelly_texture_border_unit
		#(
			parameter	USER_WIDTH   = 0,
			parameter	ADDR_X_WIDTH = 10,
			parameter	ADDR_Y_WIDTH = 10,
			parameter	X_WIDTH      = 12,
			parameter	Y_WIDTH      = 12,
			parameter	M_REGS       = 0
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			input	wire			[ADDR_X_WIDTH-1:0]	param_width,
			input	wire			[ADDR_Y_WIDTH-1:0]	param_height,
			input	wire			[7:0]				param_op_x,
			input	wire			[7:0]				param_op_y,
			
			input	wire			[USER_BITS-1:0]		s_user,
			input	wire	signed	[X_WIDTH-1:0]		s_x,
			input	wire	signed	[Y_WIDTH-1:0]		s_y,
			input	wire								s_valid,
			output	wire								s_ready,
			
			output	wire			[USER_BITS-1:0]		m_user,
			output	wire								m_border,
			output	wire			[ADDR_X_WIDTH-1:0]	m_addrx,
			output	wire			[ADDR_Y_WIDTH-1:0]	m_addry,
			output	wire								m_valid,
			input	wire								m_ready
		);
	
	
	// 8'b0_0_00_00_00 BORDER_TRANSPARENT	borderフラグを立ててスルー(後段でケア)
	// 8'b0_0_00_00_00 BORDER_CONSTANT		borderフラグを立ててスルー(後段でケア)
	// 8'b1_1_11_10_11 BORDER_REPLICATE
	//		overflow  : param_width - 1                             : 0 + ((w-x-1) + 1)  c
	//		underflow : 0                                           : 0 - ((0    ) + 0)  c
	// 8'b1_0_01_10_00 BORDER_REFLECT
	//		overflow  : (param_width - 1) - (x - param_width)       : w + ((w-x-1) + 0)  n
	//		underflow : -x-1                                        : 0 - ((x    ) + 1)  n
	// 8'b1_0_01_10_01 BORDER_REFLECT101 (width には 1小さい数を設定すること)
	//		overflow  : (param_width - 1) - (x - param_width) - 1   : w + ((w-x-1) + 0)  n
	//		underflow : -x                                          : 0 - ((x    ) + 0)  c
	// 8'b1_0_10_01_00 BORDER_WRAP
	//		overflow  : x - param_width                             : 0 - ((w-x-1) + 1)  n
	//		underflow : x + param_width                             : w + ((x    ) + 0)  n
	// BORDER以外の箇所
	//                  x                                           : w - ((w-x-1) + 1)  n
	//
	//                                                                ^ ^   ^            ^
	// op[7] : boarder enable                                         | |   |            |
	// (op[4] & underflow) | (op[5] & overflow) ? 0 : w        -------| |   |            |
	// (op[2] & underflow) | (op[3] & overflow) ? + : -        ---------|   |            |
	// underflow ? w-x-1 : x                                   -------------|            |
	// op[6] & underflow : force zero                          -------------|            |
	// (op[0] & underflow) | (op[1] & overflow) ? c : n        --------------------------|
	
	
	// -------------------------------------
	//  local parameter
	// -------------------------------------
	
	localparam	USER_BITS = USER_WIDTH > 0 ? USER_WIDTH : 1;
	
	wire	signed	[X_WIDTH-1:0]		image_width  = {1'b0, param_width};
	wire	signed	[Y_WIDTH-1:0]		image_height = {1'b0, param_height};
	
	
	
	
	// -------------------------------------
	//  pipeline control
	// -------------------------------------
	
	localparam	PIPELINE_STAGES = 2;
	
	wire			[PIPELINE_STAGES-1:0]	stage_cke;
	wire			[PIPELINE_STAGES-1:0]	stage_valid;
	
	
	wire			[USER_BITS-1:0]			src_user;
	wire	signed	[X_WIDTH-1:0]			src_x;
	wire	signed	[Y_WIDTH-1:0]			src_y;
	
	wire			[USER_BITS-1:0]			sink_user;
	wire									sink_border;
	wire			[ADDR_X_WIDTH-1:0]		sink_addrx;
	wire			[ADDR_Y_WIDTH-1:0]		sink_addry;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(PIPELINE_STAGES),
				.S_DATA_WIDTH		(USER_BITS+X_WIDTH+Y_WIDTH),
				.M_DATA_WIDTH		(USER_BITS+1+ADDR_X_WIDTH+ADDR_Y_WIDTH),
				.AUTO_VALID			(1),
				.MASTER_IN_REGS		(M_REGS),
				.MASTER_OUT_REGS	(M_REGS)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1),
				
				.s_data				({s_user, s_x, s_y}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({m_user, m_border, m_addrx, m_addry}),
				.m_valid			(m_valid),
				.m_ready			(1),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			({PIPELINE_STAGES{1'bx}}),
				.src_data			({src_user, src_x, src_y}),
				.src_valid			(),
				.sink_data			({sink_user, sink_border, sink_addrx, sink_addry}),
				.buffered			()
			);
	
	
	
	// -------------------------------------
	//  calculate
	// -------------------------------------
	
	// stage 0
	reg				[USER_BITS-1:0]		st0_user;
	reg									st0_x_under;
	wire								st0_x_over; 
	reg		signed	[X_WIDTH-1:0]		st0_x;
	wire	signed	[X_WIDTH-1:0]		st0_x0;
	wire	signed	[X_WIDTH-1:0]		st0_x1;
	wire								st0_x_carry;
	
	reg									st0_y_under;
	wire								st0_y_over;
	reg		signed	[Y_WIDTH-1:0]		st0_y;
	wire	signed	[Y_WIDTH-1:0]		st0_y0;
	wire	signed	[Y_WIDTH-1:0]		st0_y1;
	wire								st0_y_carry;
	
	assign st0_x_over  = (~st0_x1[X_WIDTH-1] && !st0_x_under);
	assign st0_x0      = (param_op_x[4] & st0_x_under) | (param_op_x[5] & st0_x_over) ? {X_WIDTH{1'b0}} : image_width;
	assign st0_x1      = (param_op_x[6] & st0_x_under)                                ? {X_WIDTH{1'b0}} :
	                     (param_op_x[2] & st0_x_under) | (param_op_x[3] & st0_x_over) ? st0_x           : ~st0_x;
	assign st0_x_carry = (param_op_x[0] & st0_x_under) | (param_op_x[1] & st0_x_over) ? 1'b1            : 1'b0;
	
	assign st0_y_over  = (~st0_y1[Y_WIDTH-1] && !st0_y_under);
	assign st0_y0      = (param_op_y[4] & st0_y_under) | (param_op_y[5] & st0_y_over) ? {Y_WIDTH{1'b0}} : image_height;
	assign st0_y1      = (param_op_y[6] & st0_y_under)                                ? {Y_WIDTH{1'b0}} :
	                     (param_op_y[2] & st0_y_under) | (param_op_y[3] & st0_y_over) ? st0_y           : ~st0_y;
	assign st0_y_carry = (param_op_y[0] & st0_y_under) | (param_op_y[1] & st0_y_over) ? 1'b1            : 1'b0;
	
	
	// stage 1
	reg				[USER_BITS-1:0]		st1_user;
	reg									st1_border;
	reg		signed	[X_WIDTH-1:0]		st1_x;
	reg		signed	[Y_WIDTH-1:0]		st1_y;
	
	
	always @(posedge clk) begin
		// stage 0
		if ( stage_cke[0] ) begin
			st0_user    <= src_user;
			
			st0_x       <= src_x[X_WIDTH-1] ? src_x : image_width  - src_x - 1'b1;
			st0_x_under <= src_x[X_WIDTH-1];
			
			st0_y       <= src_y[Y_WIDTH-1] ? src_y : image_height - src_y - 1'b1;
			st0_y_under <= src_y[Y_WIDTH-1];
		end
		
		// stage 1
		if ( stage_cke[1] ) begin
			st1_user    <= st0_user;
			st1_border  <= (~param_op_x[7] && (st0_x_under || st0_x_over)) || (~param_op_y[7] && (st0_y_under || st0_y_over));
			st1_x       <= st0_x0 + st0_x1 + st0_x_carry;
			st1_y       <= st0_y0 + st0_y1 + st0_y_carry;
		end
	end
	
	assign sink_user   = st1_user;
	assign sink_border = st1_border;
	assign sink_addrx  = st1_x;
	assign sink_addry  = st1_y;
	
endmodule


`default_nettype wire


// end of file
