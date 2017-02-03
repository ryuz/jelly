// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_writer_waddr
		#(
			parameter	BLK_X_SIZE           = 2,		// 2^n (0:1, 1:2, 2:4, 3:8... )
			parameter	STEP_Y_SIZE          = 1,		// 2^n (0:1, 1:2, 2:4, 3:8... )
			
			parameter	X_WIDTH              = 10,
			parameter	Y_WIDTH              = 10,
			
			parameter	ADDR_WIDTH           = 9,
			parameter	DATA_WIDTH           = 3*8
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			input	wire	[X_WIDTH-1:0]				param_width,
			
			input	wire	[DATA_WIDTH-1:0]			s_data,
			input	wire								s_valid,
			
			output	wire								m_last,
			output	wire	[ADDR_WIDTH-1:0]			m_addr,
			output	wire								m_valid
		);
	
	localparam	PIX_X_NUM    = (1 << BLK_X_SIZE);		// 転送単位ブロック内のX方向のピクセル数
	localparam	PIX_Y_NUM    = (1 << STEP_Y_SIZE);		// 転送単位ブロック内のX方向のピクセル数
	localparam	BLK_X_WIDTH  = X_WIDTH - BLK_X_SIZE;
	
	wire	[BLK_X_WIDTH-1:0]	blk_x_num  = (param_width  >> BLK_X_SIZE);
	
	reg		[BLK_X_SIZE-1:0]	st0_x_count;
	reg							st0_x_last;
	reg		[BLK_X_WIDTH-1:0]	st0_blk_count;
	reg							st0_blk_last;
	reg		[STEP_Y_SIZE-1:0]	st0_y_count;
	reg							st0_y_last;
	reg		[DATA_WIDTH-1:0]	st0_data;
	reg							st0_valid;
	
	reg		[ADDR_WIDTH-1:0]	st1_base;
	reg		[ADDR_WIDTH-1:0]	st1_addr;
	reg							st1_last;
	reg							st1_data;
	reg							st1_valid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			st0_x_count   <= {BLK_X_SIZE{1'b0}};
			st0_x_last    <= (PIX_X_NUM == 1);
			st0_blk_count <= {BLK_X_WIDTH{1'b0}};
			st0_blk_last  <= (blk_x_num == 1);
			st0_y_count   <= {STEP_Y_SIZE{1'b0}};
			st0_y_last    <= (PIX_Y_NUM == 1);
			st0_data      <= {DATA_WIDTH{1'b0}};
			st0_valid     <= 1'b0;
			
			st1_base      <= {ADDR_WIDTH{1'b0}};
			st1_addr      <= {ADDR_WIDTH{1'bx}};
			st1_last      <= 1'bx;
			st1_data      <= {DATA_WIDTH{1'b0}};
			st1_valid     <= 1'b0;
		end
		if ( cke ) begin
			// stage0
			if ( st0_valid ) begin
				st0_x_count   <= st0_x_count + 1'b1;
				st0_x_last    <= ((st0_x_count + 1'b1) == (PIX_X_NUM-1));
				if ( st0_x_last ) begin
					st0_x_count   <= {BLK_X_SIZE{1'b0}};
					st0_x_last    <= (PIX_X_NUM == 1);
					
					st0_blk_count <= st0_blk_count + 1'b1;
					st0_blk_last  <= ((st0_blk_count + 1'b1) == (blk_x_num - 1'b1));
					if ( st0_blk_last ) begin
						st0_blk_count <= {BLK_X_WIDTH{1'b0}};
						st0_blk_last  <= (blk_x_num == 1);
						
						st0_y_count   <= st0_y_count + 1'b1;
						st0_y_last    <= ((st0_y_count + 1'b1) == (PIX_Y_NUM - 1));
						if ( st0_y_last ) begin
							st0_y_count   <= {STEP_Y_SIZE{1'b0}};
							st0_y_last    <= (PIX_Y_NUM == 1);
						end
					end
				end
			end
			st0_data  <= s_data;
			st0_valid <= s_valid;
			
			// stage1
			if ( st1_valid ) begin
				if ( st1_last ) begin
					st1_base <= st1_addr + 1'b1;
				end
			end
			st1_addr  <= st1_base + {st0_y_count, st0_blk_count, st0_x_count};
			st1_last  <= (st0_x_last && st0_blk_last && st0_y_last);
			st1_data  <= st0_data;
			st1_valid <= st0_valid;
		end
	end
	
	assign	m_last  = st1_last;
	assign	m_addr  = st1_data;
	assign	m_valid = st1_valid;
	
	
endmodule



`default_nettype wire


// end of file
