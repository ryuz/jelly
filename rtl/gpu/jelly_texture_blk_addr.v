// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_blk_addr
		#(
			parameter	USER_WIDTH     = 1,
			
			parameter	ADDR_X_WIDTH   = 12,
			parameter	ADDR_Y_WIDTH   = 12,
			
			parameter	BLK_X_WIDTH    = 1,
			parameter	BLK_Y_WIDTH    = 1,
			
			parameter	BLK_X_NUM      = (1 << BLK_X_WIDTH),
			parameter	BLK_Y_NUM      = (1 << BLK_Y_WIDTH),

			parameter	FIFO_PTR_WIDTH = 6,
			parameter	FIFO_RAM_TYPE  = "distributed"
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			input	wire	[USER_WIDTH-1:0]	s_user,
			input	wire	[ADDR_X_WIDTH-1:0]	s_addrx,
			input	wire	[ADDR_Y_WIDTH-1:0]	s_addry,
			input	wire						s_valid,
			output	wire						s_ready,
			
			output	wire	[USER_WIDTH-1:0]	m_user,
			output	wire						m_last,
			output	wire	[ADDR_X_WIDTH-1:0]	m_addrx,
			output	wire	[ADDR_Y_WIDTH-1:0]	m_addry,
			output	wire						m_valid,
			input	wire						m_ready
		);
	
	localparam	X_WIDTH = BLK_X_WIDTH > 0 ? BLK_X_WIDTH : 1;
	localparam	Y_WIDTH = BLK_Y_WIDTH > 0 ? BLK_Y_WIDTH : 1;


	//  Queueing
	wire	[USER_WIDTH-1:0]		que_user;
	wire	[ADDR_X_WIDTH-1:0]		que_addrx;
	wire	[ADDR_Y_WIDTH-1:0]		que_addry;
	wire							que_valid;
	wire							que_ready;
	
	jelly_fifo_fwtf
			#(
				.DATA_WIDTH			(USER_WIDTH+ADDR_X_WIDTH+ADDR_Y_WIDTH),
				.PTR_WIDTH			(FIFO_PTR_WIDTH),
				.RAM_TYPE			(FIFO_RAM_TYPE),
				.MASTER_REGS		(0)
			)
		i_fifo_fwtf
			(
				.reset				(reset),
				.clk				(clk),
				
				.s_data				({s_user, s_addrx, s_addry}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				.s_free_count		(),
				
				.m_data				({que_user, que_addrx, que_addry}),
				.m_valid			(que_valid),
				.m_ready			(que_ready),
				.m_data_count		()
			);
	
	
	// addressing
	reg		[USER_WIDTH-1:0]	reg_user;
	reg		[ADDR_X_WIDTH-1:0]	reg_addrx;
	reg		[ADDR_Y_WIDTH-1:0]	reg_addry;
	reg		[X_WIDTH-1:0]		reg_x;
	reg		[Y_WIDTH-1:0]		reg_y;
	reg							reg_valid;
	always @(posedge clk) begin
		if ( reset ) begin
			reg_user  <= {USER_WIDTH{1'bx}};
			reg_addrx <= {ADDR_X_WIDTH{1'bx}};
			reg_addry <= {ADDR_Y_WIDTH{1'bx}};
			reg_x     <= {X_WIDTH{1'bx}};
			reg_y     <= {Y_WIDTH{1'bx}};
			reg_valid <= 1'b0;
		end
		else begin
			if ( m_valid && m_ready ) begin
				reg_x <= reg_x + 1'b1;
				if ( reg_x == (BLK_X_NUM-1) ) begin
					reg_x <= {X_WIDTH{1'b0}};
					reg_y <= reg_y + 1'b1;
					if ( reg_y == (BLK_Y_NUM-1) ) begin
						reg_user   <= {USER_WIDTH{1'bx}};
						reg_x      <= {X_WIDTH{1'bx}};
						reg_y      <= {Y_WIDTH{1'bx}};
						reg_valid  <= 1'b0;
					end
				end
			end
			
			if ( que_valid & que_ready ) begin
				reg_user  <= que_user;
				reg_addrx <= que_addrx;
				reg_addry <= que_addry;
				reg_x     <= {X_WIDTH{1'b0}};
				reg_y     <= {Y_WIDTH{1'b0}};
				reg_valid <= 1'b1;
			end
		end
	end
	
	assign que_ready = (!reg_valid || (m_ready && (reg_x == (BLK_X_NUM-1)) && (reg_y == (BLK_Y_NUM-1))));
	
	assign m_user  = reg_user;
	assign m_last  = ((reg_x == (BLK_X_NUM-1)) && (reg_y == (BLK_Y_NUM-1)));
	assign m_addrx = reg_addrx + reg_x;
	assign m_addry = reg_addry + reg_y;
	assign m_valid = reg_valid;
	
	
endmodule



`default_nettype wire


// end of file
