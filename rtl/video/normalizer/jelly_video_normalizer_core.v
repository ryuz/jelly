// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_video_normalizer_core
		#(
			parameter	TUSER_WIDTH   = 1,
			parameter	TDATA_WIDTH   = 24,
			parameter	X_WIDTH       = 12,
			parameter	Y_WIDTH       = 12,
			parameter	TIMER_WIDTH   = 32,
			parameter	S_SLAVE_REGS  = 1,
			parameter	S_MASTER_REGS = 1,
			parameter	M_SLAVE_REGS  = 1,
			parameter	M_MASTER_REGS = 1
		)
		(
			input	wire						aresetn,
			input	wire						aclk,
			input	wire						aclken,
			
			input	wire						param_enable,
			input	wire	[X_WIDTH-1:0]		param_width,
			input	wire	[Y_WIDTH-1:0]		param_height,
			input	wire	[TDATA_WIDTH-1:0]	param_fill,
			input	wire	[TIMER_WIDTH-1:0]	param_timeout,
			
			input	wire	[TUSER_WIDTH-1:0]	s_axi4s_tuser,
			input	wire						s_axi4s_tlast,
			input	wire	[TDATA_WIDTH-1:0]	s_axi4s_tdata,
			input	wire						s_axi4s_tvalid,
			output	wire						s_axi4s_tready,
			
			output	wire	[TUSER_WIDTH-1:0]	m_axi4s_tuser,
			output	wire						m_axi4s_tlast,
			output	wire	[TDATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire						m_axi4s_tvalid,
			input	wire						m_axi4s_tready
		);
	
	
	// input FF
	wire	[TUSER_WIDTH-1:0]	in_tuser;
	wire						in_tlast;
	wire	[TDATA_WIDTH-1:0]	in_tdata;
	wire						in_tvalid;
	wire						in_tready;
	
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH		(TUSER_WIDTH + 1 + TDATA_WIDTH),
				.SLAVE_REGS		(S_SLAVE_REGS),
				.MASTER_REGS	(S_MASTER_REGS)
			)
		i_pipeline_insert_ff_s
			(
				.reset			(~aresetn),
				.clk			(aclk),
				.cke			(aclken),
				
				.s_data			({s_axi4s_tuser, s_axi4s_tlast, s_axi4s_tdata}),
				.s_valid		(s_axi4s_tvalid),
				.s_ready		(s_axi4s_tready),
				
				.m_data			({in_tuser, in_tlast, in_tdata}),
				.m_valid		(in_tvalid),
				.m_ready		(in_tready),
				
				.buffered		(),
				.s_ready_next	()
			);
	
	
	wire						cke;
	
	reg		[X_WIDTH-1:0]		st0_param_width;
	reg		[Y_WIDTH-1:0]		st0_param_height;
	reg		[TDATA_WIDTH-1:0]	st0_param_fill;
	reg		[TIMER_WIDTH-1:0]	st0_param_timeout;
	
	localparam	[1:0]	ST_IDLE = 0, ST_BYPASS = 1, ST_FILL = 2, ST_SKIP = 3;
	
	reg							st0_state;
	reg							st0_skip;
	reg							st0_timeout;
	reg		[TIMER_WIDTH-1:0]	st0_timer;
	reg		[X_WIDTH-1:0]		st0_x;
	reg		[Y_WIDTH-1:0]		st0_y;
	wire						st0_x_last = (st0_x == st0_param_width);
	wire						st0_y_last = (st0_y == st0_param_height);
	
	reg		[TUSER_WIDTH-1:0]	st0_tuser;
	reg							st0_tlast;
	reg		[TDATA_WIDTH-1:0]	st0_tdata;
	reg							st0_tvalid;
	wire						st0_tready;
	
	always @(posedge aclk) begin
		if ( ~aresetn ) begin
			st0_param_width   <= {X_WIDTH{1'bx}};
			st0_param_height  <= {Y_WIDTH{1'bx}};
			st0_param_fill    <= {TDATA_WIDTH{1'bx}};
			st0_param_timeout <= {TIMER_WIDTH{1'bx}};
			
			st0_state         <= ST_IDLE;
			st0_timeout       <= 1'b0;
			st0_timer         <= {TIMER_WIDTH{1'bx}};
			st0_x             <= {X_WIDTH{1'bx}};
			st0_y             <= {Y_WIDTH{1'bx}};
			
			st0_tuser         <= {TUSER_WIDTH{1'bx}};
			st0_tlast         <= 1'bx;
			st0_tdata         <= {TDATA_WIDTH{1'bx}};
			st0_tvalid        <= 1'b0;
		end
		else if ( cke ) begin
			// x-y count
			if ( st0_tvalid ) begin
				st0_x <= st0_x + 1'b1;
				if ( st0_x_last ) begin
					st0_x <= {X_WIDTH{1'b0}};
					st0_y <= st0_y + 1'b1;
					if ( st0_y_last ) begin
						st0_y <= {Y_WIDTH{1'b0}};
					end
				end
			end
			
			case ( st0_state )
			ST_IDLE:
				begin
					st0_param_width   <= {X_WIDTH{1'bx}};
					st0_param_height  <= {Y_WIDTH{1'bx}};
					st0_param_timeout <= {TIMER_WIDTH{1'bx}};
					
					st0_busy          <= 1'b0;
					st0_timeout       <= 1'b0;
					st0_timer         <= {TIMER_WIDTH{1'bx}};
					st0_x             <= {X_WIDTH{1'bx}};
					st0_y             <= {Y_WIDTH{1'bx}};
					
					st0_tuser         <= {TUSER_WIDTH{1'bx}};
					st0_tlast         <= 1'bx;
					st0_tdata         <= {TDATA_WIDTH{1'bx}};
					st0_tvalid        <= 1'b0;
					
					if ( in_tuser[0] && in_tvalid && param_enable ) begin
						// start
						st0_param_width   <= param_width  - 1;
						st0_param_height  <= param_height - 1;
						st0_param_fill    <= param_fill;
						st0_param_timeout <= param_timeout;
						
						st0_busy   <= 1'b1;
						st0_timer  <= {TIMER_WIDTH{1'b0}};
						st0_x      <= {X_WIDTH{1'b0}};
						st0_y      <= {Y_WIDTH{1'b0}};
						
						st0_tuser  <= in_tuser;
						st0_tlast  <= in_tlast;
						st0_tdata  <= in_tdata;
						st0_tvalid <= in_tvalid;
					end
				end
			
			ST_BYPASS:
				begin
					st0_tuser  <= in_tuser;
					st0_tlast  <= in_tlast;
					st0_tdata  <= in_tdata;
					st0_tvalid <= in_tvalid;
					
					if ( st0_x_last && !st0_tlast ) begin
						st0_state  <= ST_SKIP;
						st0_tvalid <= 1'b0;
					end
					
					if ( st0_tlast && !st0_x_last ) begin
						st0_state  <= ST_SKIP;
						st0_tvalid <= 1'b0;
					end
					
				
				// timer
				st0_timer <= st0_timer + 1;
				if ( in_tvalid ) begin
					st0_timer <= {TIMER_WIDTH{1'b0}};
				end
				if ( st0_timer == st0_param_timeout ) begin
					st0_timeout <= 1'b1;
				end
				
				// normalize
				if ( st0_tvalid ) begin
					if ( st0_x_last && !st0_tlast ) begin
						st0_tvalid <= 1'b0;		// skip (wait for line end)
					end
					
					if ( (st0_tlast && !st0_x_last) || st0_timeout ) begin
						st0_tlast  <= 1'b1;
						st0_tdata  <= st0_param_fill;
						st0_tvalid <= 1'b1;
					end
				end
			end
			
			if ( st0_x_last && st0_y_last ) begin
				st0_busy   <= 1'b0;
				st0_tuser  <= {TUSER_WIDTH{1'bx}};
				st0_tlast  <= 1'bx;
				st0_tdata  <= {TDATA_WIDTH{1'bx}};
				st0_tvalid <= 1'b0;
			end
		end
	end
	
	assign in_tready = cke && ((!st0_busy && in_tuser[0] && in_tvalid && param_enable)
								|| (st0_busy && !st0_tlast || (st0_x_last && !st0_y_last)));
	
	assign cke = !st0_tvalid || st0_tready;
	
	
	// output FF

	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH		(TUSER_WIDTH + 1 + TDATA_WIDTH),
				.SLAVE_REGS		(S_SLAVE_REGS),
				.MASTER_REGS	(S_MASTER_REGS)
			)
		i_pipeline_insert_ff_m
			(
				.reset			(~aresetn),
				.clk			(aclk),
				.cke			(aclken),
				
				.s_data			({st0_tuser, st0_x_last, st0_tdata}),
				.s_valid		(st0_tvalid),
				.s_ready		(st0_tready),
				
				.m_data			({m_axi4s_tuser, m_axi4s_tlast, m_axi4s_tdata}),
				.m_valid		(m_axi4s_tvalid),
				.m_ready		(m_axi4s_tready),
				
				.buffered		(),
				.s_ready_next	()
			);
	
	
	/*
	reg		[TUSER_WIDTH-1:0]	st1_tuser;
	reg							st1_tlast;
	reg		[TDATA_WIDTH-1:0]	st1_tdata;
	reg							st1_tvalid;
	
	always @(posedge aclk) begin
		if ( ~aresetn ) begin
			st1_tuser  <= {TUSER_WIDTH{1'bx}};
			st1_tlast  <= 1'bx;
			st1_tdata  <= {TDATA_WIDTH{1'bx}};
			st1_tvalid <= 1'b0;
		end
		else if ( cke ) begin
			st1_tuser  <= st0_tuser;
			st1_tlast  <= st0_x_last;
			st1_tdata  <= st0_tdata;
			st1_tvalid <= st0_tvalid;
		end
	end
	*/
	
	
	
endmodule



`default_nettype wire



// end of file
