// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_writer_addr
		#(
			parameter	COMPONENT_NUM        = 3,
			parameter	COMPONENT_SEL_WIDTH  = COMPONENT_NUM <= 2  ?  1 :
			                                   COMPONENT_NUM <= 4  ?  2 :
			                                   COMPONENT_NUM <= 8  ?  3 :
			                                   COMPONENT_NUM <= 16 ?  4 :
			                                   COMPONENT_NUM <= 32 ?  5 :
			                                   COMPONENT_NUM <= 64 ?  6 : 7,
			
			parameter	BLK_X_SIZE           = 2,		// 2^n (0:1, 1:2, 2:4, 3:8... )
			parameter	BLK_Y_SIZE           = 2,		// 2^n (0:1, 1:2, 2:4, 3:8... )
			parameter	STEP_Y_SIZE          = 1,		// 2^n (0:1, 1:2, 2:4, 3:8... )
			
			parameter	X_WIDTH              = 10,
			parameter	Y_WIDTH              = 10,
			
			parameter	SRC_STRIDE_WIDTH     = X_WIDTH,
			parameter	DST_STRIDE_WIDTH     = SRC_STRIDE_WIDTH + BLK_Y_SIZE,
			parameter	SRC_ADDR_WIDTH       = 10,
			parameter	SRC_FIFO_PTR_WIDTH   = SRC_ADDR_WIDTH + 1,
			parameter	DST_ADDR_WIDTH       = 24
		)
		(
			input	wire								reset,
			input	wire								clk,
			
			input	wire								enable,
			output	wire								busy,
			
			input	wire	[X_WIDTH-1:0]				param_width,
			input	wire	[Y_WIDTH-1:0]				param_height,
			input	wire	[SRC_STRIDE_WIDTH-1:0]		param_src_stride,
			input	wire	[DST_STRIDE_WIDTH-1:0]		param_dst_stride,
			
			output	wire	[COMPONENT_SEL_WIDTH-1:0]	m_component,
			output	wire	[SRC_ADDR_WIDTH-1:0]		m_src_addr,
			output	wire	[SRC_FIFO_PTR_WIDTH-1:0]	m_src_ptr,
			output	wire								m_src_ptr_update,
			output	wire								m_src_blk_last,
			output	wire	[DST_ADDR_WIDTH-1:0]		m_dst_addr,
			output	wire								m_dst_blk_last,
			output	wire								m_last,
			output	wire								m_valid,
			input	wire								m_ready
		);
	
	
	localparam	STEP_Y_NUM         = (1 << STEP_Y_SIZE);
	localparam	STEP_Y_WIDTH       = STEP_Y_SIZE > 0 ? STEP_Y_SIZE : 1;
	localparam	BLK_X_NUM          = (1 << BLK_X_SIZE);
	localparam	BLK_X_WIDTH        = BLK_X_SIZE > 0 ? BLK_X_SIZE : 1;
	localparam	BLK_Y_NUM          = (1 << BLK_Y_SIZE);
	localparam	BLK_Y_WIDTH        = BLK_Y_SIZE > 0 ? BLK_Y_SIZE : 1;
	
	localparam	SRC_OFFSET_Y_WIDTH = SRC_STRIDE_WIDTH + STEP_Y_SIZE;
	
	
	// cke
	wire								cke = m_ready;
	
	
	// common
	reg		[COMPONENT_SEL_WIDTH-1:0]	st0_component;
	reg									st0_component_last;
	reg		[BLK_X_WIDTH-1:0]			st0_blk_x;
	reg									st0_blk_x_last;
	reg		[STEP_Y_WIDTH-1:0]			st0_step_y;
	reg									st0_step_y_last;
	reg		[BLK_Y_WIDTH-1:0]			st0_blk_y;
	reg									st0_blk_y_last;
	reg		[X_WIDTH-1:0]				st0_x;
	reg									st0_x_last;
	reg		[X_WIDTH-1:0]				st0_y;
	reg									st0_y_last;
	
	// src addr
	reg		[SRC_FIFO_PTR_WIDTH:0]		st0_src_base_addr;
	reg		[SRC_OFFSET_Y_WIDTH-1:0]	st0_src_offset_addr;
	
	reg		[DST_ADDR_WIDTH-1:0]		st0_dst_base_addr;
	
	// valid
	reg									st0_valid;
	
	always @(posedge clk) begin
		if ( !st0_valid ) begin
			st0_component      <= {COMPONENT_SEL_WIDTH{1'b0}};
			st0_component_last <= (COMPONENT_NUM == 1);
			st0_blk_x          <= {BLK_X_WIDTH{1'b0}};
			st0_blk_x_last     <= (BLK_X_NUM == 1);
			st0_step_y         <= {STEP_Y_WIDTH{1'b0}};
			st0_step_y_last    <= (STEP_Y_NUM == 1);
			st0_blk_y          <= {BLK_Y_WIDTH{1'b0}};
			st0_blk_y_last     <= (BLK_Y_NUM == 1);
			st0_x              <= {X_WIDTH{1'b0}};
			st0_x_last         <= (param_width == 1);
			st0_y              <= {Y_WIDTH{1'b0}};
			st0_y_last         <= (param_height == 1);
		end
		else if ( cke ) begin
			// blk_x
			st0_blk_x      <= st0_blk_x + 1'b1;
			st0_blk_x_last <= ((st0_blk_x + 1'b1) == (BLK_X_NUM - 1));
			
			// step_y
			if ( st0_blk_x_last ) begin
				st0_step_y      <= st0_step_y + 1'b1;
				st0_step_y_last <= ((st0_step_y + 1'b1) == (STEP_Y_NUM - 1));
			end
			
			// component
			if ( st0_blk_x_last && st0_step_y_last ) begin
				if ( st0_component_last ) begin
					st0_component      <= {COMPONENT_SEL_WIDTH{1'b0}};
					st0_component_last <= (COMPONENT_NUM == 1);
				end
				else begin
					st0_component      <= st0_component + 1'b1;
					st0_component_last <= ((st0_component + 1'b1) == (COMPONENT_NUM - 1));
				end
			end
			
			// x
			if ( st0_blk_x_last && st0_step_y_last && st0_component_last ) begin
				if ( st0_x_last ) begin
					st0_x      <= {X_WIDTH{1'b0}};
					st0_x_last <= (param_width == 1);
				end
				else begin
					st0_x      <= st0_x + BLK_X_NUM;
					st0_x_last <= ((st0_x + BLK_X_NUM) == (param_width - BLK_X_NUM));
				end
			end
			
			// blk_y
			if ( st0_blk_x_last && st0_step_y_last && st0_component_last && st0_x_last ) begin
				st0_blk_y      <= st0_blk_y + STEP_Y_NUM;
				st0_blk_y_last <= ((st0_blk_y + STEP_Y_NUM) == (BLK_Y_NUM - STEP_Y_NUM));
			end
			
			// y
			if ( st0_blk_x_last && st0_step_y_last && st0_component_last && st0_x_last ) begin
				if ( st0_y_last ) begin
					st0_y      <= {Y_WIDTH{1'b0}};
					st0_y_last <= (param_height == 1);
				end
				else begin
					st0_y      <= st0_y + STEP_Y_NUM;
					st0_y_last <= ((st0_y + STEP_Y_NUM) == (param_height - STEP_Y_NUM));
				end
			end
		end
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			st0_src_base_addr   <= {SRC_FIFO_PTR_WIDTH{1'b0}};
			st0_src_offset_addr <= {SRC_OFFSET_Y_WIDTH{1'b0}};
		end
		else if ( cke ) begin
			if ( st0_valid ) begin
				if ( st0_blk_x_last && st0_step_y_last && st0_component_last && st0_x_last ) begin
					st0_src_base_addr <= st0_src_base_addr + (param_src_stride << STEP_Y_SIZE);
				end
				
				if ( st0_blk_x_last ) begin
					if ( st0_step_y_last ) begin
						st0_src_offset_addr <= {SRC_OFFSET_Y_WIDTH{1'b0}};
					end
					else begin
						st0_src_offset_addr <= st0_src_offset_addr + param_src_stride;
					end
				end
			end
		end
	end
	
	always @(posedge clk) begin
		if ( !st0_valid ) begin
			st0_dst_base_addr   <= {DST_ADDR_WIDTH{1'b0}};
		end
		else if ( cke ) begin
			if ( st0_blk_x_last && st0_step_y_last && st0_component_last && st0_x_last && st0_blk_y_last ) begin
				if ( st0_y_last ) begin
					st0_dst_base_addr <= {DST_ADDR_WIDTH{1'b0}};
				end
				else begin
					st0_dst_base_addr <= st0_dst_base_addr + param_dst_stride;
				end
			end
		end
	end
	
	
	// valid
	always @(posedge clk) begin
		if ( reset ) begin
			st0_valid <= 1'b0;
		end
		else if ( cke ) begin
			if ( !st0_valid ) begin
				if ( enable ) begin
					st0_valid <= 1'b1;
				end
			end
			else begin
				if ( st0_blk_x_last && st0_step_y_last && st0_component_last && st0_x_last && st0_y_last ) begin
					st0_valid <= 1'b0;
				end
			end
		end
	end
	
	
	
	// sum address
	reg		[COMPONENT_SEL_WIDTH-1:0]	st1_component;
	reg		[SRC_ADDR_WIDTH-1:0]		st1_src_addr;
	reg		[SRC_FIFO_PTR_WIDTH-1:0]	st1_src_ptr;
	reg									st1_src_ptr_update;
	reg									st1_src_blk_last;
	reg		[DST_ADDR_WIDTH-1:0]		st1_dst_addr;
	reg									st1_dst_blk_last;
	reg									st1_last;
	reg									st1_valid;
	
	reg		[COMPONENT_SEL_WIDTH-1:0]	st2_component;
	reg		[SRC_ADDR_WIDTH-1:0]		st2_src_addr;
	reg		[SRC_FIFO_PTR_WIDTH-1:0]	st2_src_ptr;
	reg									st2_src_ptr_update;
	reg									st2_src_blk_last;
	reg		[DST_ADDR_WIDTH-1:0]		st2_dst_addr;
	reg									st2_dst_blk_last;
	reg									st2_last;
	reg									st2_valid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			st1_last           <= 1'bx;
			st1_component      <= {COMPONENT_SEL_WIDTH{1'bx}};
			st1_src_addr       <= {SRC_ADDR_WIDTH{1'bx}};
			st1_src_ptr        <= {SRC_FIFO_PTR_WIDTH{1'bx}};
			st1_src_ptr_update <= 1'bx;
			st1_src_blk_last   <= 1'bx;
			st1_dst_addr       <= {DST_ADDR_WIDTH{1'bx}};
			st1_dst_blk_last   <= 1'bx;
			st1_last           <= 1'bx;
			st1_valid          <= 1'b0;
			
			st2_last           <= 1'bx;
			st2_component      <= {COMPONENT_SEL_WIDTH{1'bx}};
			st2_src_addr       <= {SRC_ADDR_WIDTH{1'bx}};
			st2_src_ptr        <= {SRC_FIFO_PTR_WIDTH{1'bx}};
			st2_src_ptr_update <= 1'bx;
			st2_src_blk_last   <= 1'bx;
			st2_dst_addr       <= {DST_ADDR_WIDTH{1'bx}};
			st2_dst_blk_last   <= 1'bx;
			st2_last           <= 1'bx;
			st2_valid          <= 1'b0;
		end
		else if ( cke ) begin
			// stage 1
			st1_component       <= st0_component;
			st1_src_addr        <= st0_src_offset_addr + st0_x + st0_blk_x;
			st1_src_ptr         <= st0_src_base_addr;
			st1_src_ptr_update  <= st0_blk_x_last && st0_step_y_last && st0_component_last && st0_x_last;
			st1_src_blk_last    <= (st0_blk_x_last && st0_step_y_last && st0_component_last && st0_x_last && st0_blk_y_last);
			st1_dst_addr        <= st0_dst_base_addr + (((st0_blk_y + st0_step_y) << BLK_X_SIZE) | (st0_x << BLK_Y_SIZE) | st0_blk_x);
			st1_dst_blk_last    <= (st0_blk_x_last && st0_step_y_last);
			st1_last            <= (st0_blk_x_last && st0_step_y_last && st0_component_last && st0_x_last && st0_y_last);
			st1_valid           <= st0_valid;
			
			// stage 2
			st2_component       <= st1_component;
			st2_src_addr        <= st1_src_ptr + st1_src_addr;
			st2_src_ptr         <= st1_src_ptr;
			st2_src_ptr_update  <= st1_src_ptr_update;
			st2_src_blk_last    <= st1_src_blk_last;
			st2_dst_addr        <= st1_dst_addr;
			st2_dst_blk_last    <= st1_dst_blk_last;
			st2_last            <= st1_last;
			st2_valid           <= st1_valid;
		end
	end
	
	assign busy              = st0_valid;
	
	assign m_last           = st2_last;
	assign m_component      = st2_component;
	assign m_src_addr       = st2_src_addr;
	assign m_src_ptr        = st2_src_ptr;
	assign m_src_ptr_update = st2_src_ptr_update;
	assign m_src_blk_last   = st2_src_blk_last;
	assign m_dst_addr       = st2_dst_addr;
	assign m_dst_blk_last   = st2_dst_blk_last;
	assign m_last           = st2_last;
	assign m_valid          = st2_valid;
	
endmodule



`default_nettype wire


// end of file
