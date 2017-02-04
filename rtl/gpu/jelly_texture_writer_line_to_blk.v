// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_writer_line_to_blk
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
			
			parameter	ADDR_WIDTH           = 24,
			parameter	S_DATA_WIDTH         = 8*3,
			parameter	M_DATA_SIZE          = 1,
			
			parameter	BUF_ADDR_WIDTH       = 1 + X_WIDTH + STEP_Y_SIZE - M_DATA_SIZE,
			parameter	BUF_RAM_TYPE         = "block",
			
			// local
			parameter	M_DATA_WIDTH         = (S_DATA_WIDTH << M_DATA_SIZE)
		)
		(
			input	wire								reset,
			input	wire								clk,
			
			input	wire								enable,
			output	wire								busy,
			
			input	wire	[X_WIDTH-1:0]				param_width,
			input	wire	[Y_WIDTH-1:0]				param_height,
			
			input	wire	[S_DATA_WIDTH-1:0]			s_data,
			input	wire								s_valid,
			output	wire								s_ready,
			
			output	wire	[ADDR_WIDTH-1:0]			m_addr,
			output	wire	[M_DATA_WIDTH-1:0]			m_data,
			output	wire								m_last,
			output	wire								m_valid,
			input	wire								m_ready
		);
	
		
	// ---------------------------------
	//  control
	// ---------------------------------
	
	reg			reg_busy;
	always @(posedge clk) begin
		if ( reset ) begin
			reg_busy <= 1'b0;
		end
		else begin
			if ( !busy ) begin
				reg_busy <= enable;
			end
			else begin
				if ( m_last && m_valid && m_ready ) begin
					reg_busy <= 1'b0;
				end
			end
		end
	end
	
	assign busy = reg_busy;
	
	
	
	// ---------------------------------
	//  buffer memory
	// ---------------------------------
	
	localparam	BUF_NUM        = (1 << M_DATA_SIZE);
	localparam	BUF_UNIT_WIDTH = S_DATA_WIDTH;
	localparam	BUF_DATA_WIDTH = M_DATA_WIDTH;
	
	localparam	BUF_BLK_WIDTH  = (BUF_ADDR_WIDTH + M_DATA_SIZE) - (BLK_X_SIZE + STEP_Y_SIZE);
	localparam	BUF_BLK_NUM    = (1 << BUF_BLK_WIDTH);
	
	
	wire									buf_full;
	wire									buf_empty;
	
	wire									buf_wr_req;
	wire									buf_wr_end;
	
	wire									buf_rd_req;
	wire									buf_rd_end;
	
	
	wire									buf_wr_cke;
	wire	[BUF_NUM-1:0]					buf_wr_en;
	wire	[BUF_NUM*ADDR_WIDTH-1:0]		buf_wr_addr;
	wire	[BUF_NUM*BUF_DATA_WIDTH-1:0]	buf_wr_din;
	
	wire									buf_rd_cke;
	wire	[ADDR_WIDTH-1:0]				buf_rd_addr;
	wire	[BUF_NUM*BUF_DATA_WIDTH-1:0]	buf_rd_dout;

	genvar									i;
	
	generate
	for ( i = 0; i < BUF_NUM; i = i+1 ) begin : loop_buf
		jelly_ram_simple_dualport
				#(
					.ADDR_WIDTH		(BUF_ADDR_WIDTH),
					.DATA_WIDTH		(BUF_UNIT_WIDTH),
					.RAM_TYPE		(BUF_RAM_TYPE),
					.DOUT_REGS		(1)
				)
			i_ram_simple_dualport
				(
					.wr_clk			(clk),
					.wr_en			(buf_wr_en[i] & buf_wr_cke),
					.wr_addr		(buf_wr_addr),
					.wr_din			(buf_wr_din[i*BUF_UNIT_WIDTH +: BUF_UNIT_WIDTH]),
					
					.rd_clk			(clk),
					.rd_en			(buf_rd_cke),
					.rd_regcke		(buf_rd_cke),
					.rd_addr		(buf_rd_addr),
					.rd_dout		(buf_rd_dout[i*BUF_UNIT_WIDTH +: BUF_UNIT_WIDTH])
				);
	end
	endgenerate
	
	reg		[BUF_BLK_WIDTH:0]	reg_buf_wr_count;	// writable block counter
	reg							reg_buf_full;
	
	reg		[BUF_BLK_WIDTH:0]	reg_buf_rd_count;	// readable block counter
	reg							reg_buf_empty;
	
	always @(posedge clk) begin
		if ( !busy ) begin
			reg_buf_wr_count <= BUF_BLK_NUM;
			reg_buf_full     <= 1'b0;
			
			reg_buf_rd_count <= 0;
			reg_buf_empty    <= 1'b1;
		end
		else begin
			reg_buf_wr_count <= reg_buf_wr_count - buf_wr_req + buf_rd_end;
			reg_buf_full     <= ((reg_buf_wr_count - buf_wr_req + buf_rd_end) == 0);
			
			reg_buf_rd_count <= reg_buf_rd_count + buf_wr_end - buf_rd_req;
			reg_buf_empty    <= ((reg_buf_rd_count + buf_wr_end - buf_rd_req) == 0);
		end
	end
	
	assign buf_full  = reg_buf_full;
	assign buf_empty = reg_buf_empty;
	
	
	
	
	// ---------------------------------
	//  write to buffer
	// ---------------------------------
	
	localparam	WR_PIX_X_NUM   = (1 << BLK_X_SIZE);
	localparam	WR_PIX_X_WIDTH = BLK_X_SIZE >= 0 ? BLK_X_SIZE : 1;
	
	localparam	WR_PIX_Y_NUM   = (1 << STEP_Y_SIZE);
	localparam	WR_PIX_Y_WIDTH = STEP_Y_SIZE >= 0 ? STEP_Y_SIZE : 1;
	
	localparam	WR_BLK_X_WIDTH = X_WIDTH - BLK_X_SIZE;
	
	
	wire	[WR_BLK_X_WIDTH-1:0]	wr_blk_x_num  = (param_width  >> BLK_X_SIZE);

	wire							wr_cke;
			
	reg		[WR_PIX_X_WIDTH-1:0]	wr0_x_count;
	reg								wr0_x_last;
	reg		[WR_BLK_X_WIDTH-1:0]	wr0_blk_count;
	reg								wr0_blk_last;
	reg		[WR_PIX_Y_WIDTH-1:0]	wr0_y_count;
	reg								wr0_y_last;
	reg		[S_DATA_WIDTH-1:0]		wr0_data;
	reg								wr0_valid;
	
	wire	[BUF_ADDR_WIDTH-1:0]	wr0_addr      = ((wr0_y_count << BLK_X_SIZE) |  wr0_x_count);
	wire							wr0_line_last = (wr0_x_last && wr0_blk_last);
//	wire							wr0_last      = (wr0_x_last && wr0_blk_last && wr0_y_last);
	
	reg		[BUF_ADDR_WIDTH-1:0]	wr1_base_addr;
	reg		[BUF_ADDR_WIDTH-1:0]	wr1_blk_addr;
	reg		[BUF_ADDR_WIDTH-1:0]	wr1_addr;
	reg		[BUF_NUM-1:0]			wr1_we;
	reg								wr1_x_last;
	reg								wr1_blk_last;
	reg								wr1_line_last;
	reg								wr1_last;
	reg								wr1_data;
	reg								wr1_valid;
	
	always @(posedge clk) begin
		if ( !busy ) begin
			wr0_x_count   <= {WR_PIX_X_WIDTH{1'b0}};
			wr0_x_last    <= (WR_PIX_X_NUM == 1);
			wr0_blk_count <= {WR_BLK_X_WIDTH{1'b0}};
			wr0_blk_last  <= (wr_blk_x_num == 1);
			wr0_y_count   <= {WR_PIX_Y_WIDTH{1'b0}};
			wr0_y_last    <= (WR_PIX_Y_NUM == 1);
			wr0_data      <= {S_DATA_WIDTH{1'bx}};
			wr0_valid     <= 1'b0;
			
			wr1_x_last    <= 1'b0;
			wr1_blk_last  <= 1'b0;
			wr1_line_last <= 1'b0;
			wr1_last      <= 1'b0;
			wr1_base_addr <= {BUF_ADDR_WIDTH{1'b0}};
			wr1_blk_addr  <= {BUF_ADDR_WIDTH{1'b0}};
			wr1_addr      <= {BUF_ADDR_WIDTH{1'b0}};
			wr1_we        <= {BUF_NUM{1'bx}};
			wr1_data      <= {S_DATA_WIDTH{1'bx}};
			wr1_valid     <= 1'b0;
		end
		else if ( wr_cke ) begin
			// stage0
			if ( wr0_valid ) begin
				wr0_x_count   <= wr0_x_count + 1'b1;
				wr0_x_last    <= ((wr0_x_count + 1'b1) == (WR_PIX_X_NUM-1));
				if ( wr0_x_last ) begin
					wr0_x_count   <= {WR_PIX_X_WIDTH{1'b0}};
					wr0_x_last    <= (WR_PIX_X_NUM == 1);
					
					wr0_blk_count <= wr0_blk_count + 1'b1;
					wr0_blk_last  <= ((wr0_blk_count + 1'b1) == (wr_blk_x_num - 1'b1));
					if ( wr0_blk_last ) begin
						wr0_blk_count <= {WR_BLK_X_WIDTH{1'b0}};
						wr0_blk_last  <= (wr_blk_x_num == 1);
						
						wr0_y_count   <= wr0_y_count + 1'b1;
						wr0_y_last    <= ((wr0_y_count + 1'b1) == (WR_PIX_Y_NUM - 1));
						if ( wr0_y_last ) begin
							wr0_y_count   <= {WR_PIX_Y_WIDTH{1'b0}};
							wr0_y_last    <= (WR_PIX_Y_NUM == 1);
						end
					end
				end
			end
			wr0_data  <= s_data;
			wr0_valid <= s_valid;
			
			
			// stage1
			if ( wr1_valid ) begin
				wr1_addr <= wr1_addr + 1'b1;
				if ( wr1_x_last ) begin
					wr1_addr     <= wr1_blk_addr;
					wr1_blk_addr <= wr1_blk_addr + (1 << (BLK_X_SIZE + STEP_Y_SIZE));
				end
				if ( wr1_line_last ) begin
					wr1_addr      <= wr1_base_addr;
					wr1_blk_addr  <= wr1_base_addr;
					wr1_base_addr <= wr1_base_addr + (param_width >> M_DATA_SIZE);
				end
			end
			
			wr1_we        <= wr0_valid ? (1 << (wr0_addr & ~((1 << M_DATA_SIZE) - 1))) : {BUF_NUM{1'b0}};
			wr1_addr      <= wr1_base_addr + (wr0_addr >> M_DATA_SIZE);
			wr1_x_last    <= wr0_x_last;
			wr1_line_last <= wr0_line_last;
			wr1_blk_last  <= (wr0_valid && wr0_line_last && wr0_blk_last);
	//		wr1_last      <= wr0_last;
			wr1_data      <= wr0_data;
			wr1_valid     <= wr0_valid;
		end
	end
	
	assign	wr_cke      = !buf_full;
	
	assign	buf_wr_req  = (wr_cke && wr1_blk_last);
	assign	buf_wr_end  = (wr_cke && wr1_blk_last);
	
	assign	buf_wr_cke  = wr_cke;
	assign	buf_wr_en   = wr1_we;
	assign	buf_wr_addr = wr1_addr;
	assign	buf_wr_din  = {BUF_NUM{wr1_data}};
	
	
	
	// ---------------------------------
	//  read from buffer
	// ---------------------------------
	
	localparam	RD_PIX_SIZE     = BLK_X_SIZE + STEP_Y_SIZE - M_DATA_SIZE;
	localparam	RD_PIX_NUM      = (1 << RD_PIX_SIZE);
	localparam	RD_PIX_WIDTH    = RD_PIX_SIZE > 0 ? RD_PIX_SIZE : 1;
	
	localparam	RD_STEP_NUM     = (1 << STEP_Y_SIZE);
	localparam	RD_STEP_WIDTH   = STEP_Y_SIZE > 0 ? STEP_Y_SIZE : 1;
	
	localparam	RD_BLK_X_WIDTH  = X_WIDTH - BLK_X_SIZE;
	localparam	RD_Y_WIDTH      = Y_WIDTH - STEP_Y_SIZE;
	
	
	wire	[RD_BLK_X_WIDTH-1:0]		rd_blk_x_num = (param_width  >> BLK_X_SIZE);
	wire	[RD_Y_WIDTH-1:0]			rd_blk_y_num = (param_height >> STEP_Y_SIZE);
	
	wire								rd_cke;
	
	reg		[RD_PIX_WIDTH-1:0]			rd0_pix_count;
	reg									rd0_pix_last;
	reg		[BUF_ADDR_WIDTH-1:0]		rd0_addr;
	wire								rd0_valid = !buf_empty;
	
	reg									rd1_pix_last;
	reg		[COMPONENT_SEL_WIDTH-1:0]	rd1_cmp_count;
	reg									rd1_cmp_last;
	reg		[RD_BLK_X_WIDTH-1:0]		rd1_blk_count;
	reg									rd1_blk_last;
	reg		[RD_STEP_WIDTH-1:0]			rd1_step_count;
	reg									rd1_step_last;
	reg		[RD_Y_WIDTH-1:0]			rd1_y_count;
	reg									rd1_y_last;
	reg									rd1_valid;

	reg									rd2_pix_last;
	reg									rd2_cmp_last;
	reg									rd2_blk_last;
	reg									rd2_step_last;
	reg									rd2_y_last;
	
	reg		[COMPONENT_SEL_WIDTH-1:0]	rd2_component;
	reg		[ADDR_WIDTH-1:0]		rd2_base_addr;
	reg		[ADDR_WIDTH-1:0]		rd2_blk_addr;
	reg		[ADDR_WIDTH-1:0]		rd2_step_addr;
	reg		[ADDR_WIDTH-1:0]		rd2_addr;
	reg		[ADDR_WIDTH-1:0]		rd2_base;
	reg									rd2_last;
	wire	[M_DATA_WIDTH-1:0]			rd2_data = buf_rd_dout;
	reg									rd2_valid;
	
	always @(posedge clk) begin
		if ( !busy ) begin
			/*
			rd0_pix_count  <= {RD_PIX_WIDTH{1'b0}};
			rd0_pix_last   <= (RD_PIX_NUM == 1);
			rd0_cmp_count  <= {COMPONENT_SEL_WIDTH{1'b0}};
			rd0_cmp_last   <= (COMPONENT_NUM == 1);
			rd0_blk_count  <= {RD_BLK_X_WIDTH{1'b0}};
			rd0_blk_last   <= (rd_blk_x_num == 1);
			rd0_step_count <= {RD_STEP_WIDTH{1'b0}};
			rd0_step_last  <= (RD_STEP_NUM == 1);
			rd0_y_count    <= {RD_Y_WIDTH{1'b0}};
			rd0_y_last     <= (rd_blk_y_num == 1);
			rd0_valid      <= 1'b0;
			*/
		end
		else if ( rd_cke ) begin
			// stage0
			if ( rd0_valid ) begin
				rd0_addr <= rd0_addr + 1'b1;
				
				rd0_pix_count <= rd0_pix_count + 1'b1;
				rd0_pix_last  <= ((rd0_pix_count + 1'b1) == (RD_PIX_NUM - 1));
				if ( rd0_pix_last ) begin
					rd0_pix_count  <= {RD_PIX_WIDTH{1'b0}};
					rd0_pix_last   <= (RD_PIX_NUM == 1);
				end
			end
			
			// stage1
			if ( rd1_valid ) begin
				rd1_pix_last <= rd0_pix_last;
				if ( rd1_pix_last ) begin
					rd1_cmp_count  <= rd1_cmp_count + 1'b1;
					rd1_cmp_last   <= ((rd1_cmp_count + 1'b1) == (COMPONENT_NUM - 1));
					if ( rd1_cmp_last ) begin
						rd1_cmp_count  <= {COMPONENT_SEL_WIDTH{1'b0}};
						rd1_cmp_last   <= (COMPONENT_NUM == 0);
						
						rd1_blk_count  <= rd1_blk_count + 1'b1;
						rd1_blk_last   <= ((rd1_blk_count + 1'b1) == (rd_blk_x_num - 1));
						if ( rd1_blk_last ) begin
							rd1_blk_count  <= {RD_BLK_X_WIDTH{1'b0}};
							rd1_blk_last   <= (rd_blk_x_num == 1);
							
							rd1_step_count <= rd1_step_count + 1'b1;
							rd1_step_last  <= ((rd1_step_count + 1'b1) == (RD_STEP_NUM - 1));
							if ( rd1_step_last ) begin
								rd1_step_count <= {RD_STEP_WIDTH{1'b0}};
								rd1_step_last  <= (RD_STEP_NUM == 1);
							end
							
							rd1_y_count    <= rd1_y_count + 1'b1;
							rd1_y_last     <= ((rd1_y_count + 1'b1) == (RD_STEP_NUM - 1));
							if ( rd1_y_last ) begin
								rd1_y_count    <= {RD_STEP_WIDTH{1'b0}};
								rd1_y_last     <= (RD_STEP_NUM == 1);
							end
						end
					end
				end
			end
			
			// stage1
			if ( rd2_valid ) begin
				rd2_addr <= rd2_addr + 1'b1;
				if ( rd2_pix_last ) begin
					rd2_addr <= rd2_blk_addr;
				end
				if ( rd2_cmp_last ) begin
					rd2_addr     <= rd2_blk_addr + (1 << RD_PIX_SIZE);
					rd2_blk_addr <= rd2_blk_addr + (1 << RD_PIX_SIZE);
				end
				if ( rd2_blk_last ) begin
					rd2_addr      <= rd2_step_addr;
					rd2_blk_addr  <= rd2_step_addr;
					rd2_step_addr <= rd2_step_addr + ((param_width >> M_DATA_SIZE) << STEP_Y_SIZE);
				end
				if ( rd2_step_last ) begin
					rd2_addr      <= rd2_base_addr;
					rd2_blk_addr  <= rd2_base_addr;
					rd2_step_addr <= rd2_base_addr + ((param_width >> M_DATA_SIZE) << STEP_Y_SIZE);
					rd2_base_addr <= rd2_base_addr + ((param_width >> M_DATA_SIZE) << (BLK_Y_SIZE));
				end
			end
			
			rd2_cmp_last  <= rd1_cmp_last;
			rd2_blk_last  <= rd1_blk_last;
			rd2_step_last <= rd1_step_last;
	//		rd2_last      <= rd1_last;
			
			rd2_component <= rd1_cmp_count;
			rd2_valid     <= rd1_valid;
		end
	end
	
	assign	rd_cke      = (!m_valid || m_ready);
	
	assign	buf_rd_req  = (rd_cke && rd0_valid && rd0_pix_last);
	assign	buf_rd_end  = (rd_cke && rd1_valid && rd1_pix_last);
	
	assign	buf_rd_cke  = rd_cke;
	assign	buf_rd_addr = rd0_addr;
	
	assign	m_addr      = rd2_addr;
	assign	m_data      = rd2_data;
	assign	m_last      = rd2_last;
	assign	m_valid     = rd2_valid;
	
endmodule



`default_nettype wire


// end of file
