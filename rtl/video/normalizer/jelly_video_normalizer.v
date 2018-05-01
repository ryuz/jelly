// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_video_normalizer
		#(
			parameter	WB_ADR_WIDTH       = 8,
			parameter	WB_DAT_WIDTH       = 32,
			parameter	WB_SEL_WIDTH       = (WB_DAT_WIDTH / 8),
			
			parameter	TUSER_WIDTH        = 1,
			parameter	TDATA_WIDTH        = 24,
			parameter	X_WIDTH            = 12,
			parameter	Y_WIDTH            = 12,
			parameter	TIMER_WIDTH        = 32,
			parameter	S_SLAVE_REGS       = 1,
			parameter	S_MASTER_REGS      = 1,
			parameter	M_SLAVE_REGS       = 1,
			parameter	M_MASTER_REGS      = 1,
			
			parameter	INIT_CTL_ENABLE    = 0,
			parameter	INIT_PARAM_WIDTH   = 640,
			parameter	INIT_PARAM_HEIGHT  = 480,
			parameter	INIT_PARAM_FILL    = {TDATA_WIDTH{1'b0}},
			parameter	INIT_PARAM_TIMEOUT = 0
		)
		(
			input	wire						aresetn,
			input	wire						aclk,
			input	wire						aclken,
			
			input	wire						s_wb_rst_i,
			input	wire						s_wb_clk_i,
			input	wire	[WB_ADR_WIDTH-1:0]	s_wb_adr_i,
			input	wire	[WB_DAT_WIDTH-1:0]	s_wb_dat_i,
			output	wire	[WB_DAT_WIDTH-1:0]	s_wb_dat_o,
			input	wire						s_wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	s_wb_sel_i,
			input	wire						s_wb_stb_i,
			output	wire						s_wb_ack_o,
			
			
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
	
	
	// register
	localparam	REG_ADDR_CTL_ENABLE    = 32'h00;
	localparam	REG_ADDR_CTL_BUSY      = 32'h01;
	localparam	REG_ADDR_PARAM_WIDTH   = 32'h04;
	localparam	REG_ADDR_PARAM_HEIGHT  = 32'h05;
	localparam	REG_ADDR_PARAM_FILL    = 32'h06;
	localparam	REG_ADDR_PARAM_TIMEOUT = 32'h07;
	
	reg							reg_enable;
	reg		[X_WIDTH-1:0]		reg_param_width;
	reg		[Y_WIDTH-1:0]		reg_param_height;
	reg		[TDATA_WIDTH-1:0]	reg_param_fill;
	reg		[TIMER_WIDTH-1:0]	reg_param_timeout;
	
	wire						busy;
	reg							reg_busy;
	always @(posedge s_wb_clk_i) begin
		reg_busy <= busy;
	end
	
	always @(posedge s_wb_clk_i) begin
		if ( s_wb_rst_i ) begin
			reg_enable        <= INIT_CTL_ENABLE;
			reg_param_width   <= INIT_PARAM_WIDTH;
			reg_param_height  <= INIT_PARAM_HEIGHT;
			reg_param_fill    <= INIT_PARAM_FILL;
			reg_param_timeout <= INIT_PARAM_TIMEOUT;
		end
		else begin
			
		end
	end
	
	reg		[WB_DAT_WIDTH-1:0]	wb_dat_o;
	always @* begin
		wb_dat_o = {WB_DAT_WIDTH{1'b0}};
		case ( s_wb_adr_i )
		REG_ADDR_CTL_ENABLE:	wb_dat_o = reg_enable;
		REG_ADDR_CTL_BUSY:		wb_dat_o = reg_busy;
		REG_ADDR_PARAM_WIDTH:	wb_dat_o = reg_param_width;
		REG_ADDR_PARAM_HEIGHT:	wb_dat_o = reg_param_height;
		REG_ADDR_PARAM_FILL:	wb_dat_o = reg_param_fill;
		REG_ADDR_PARAM_TIMEOUT:	wb_dat_o = reg_param_timeout;
		endcase
	end
	
	assign s_wb_dat_o = wb_dat_o;
	assign s_wb_ack_o = s_wb_stb_i;
	
	
	
	// core
	reg							ff_enable;
	reg		[X_WIDTH-1:0]		ff_param_width;
	reg		[Y_WIDTH-1:0]		ff_param_height;
	reg		[TDATA_WIDTH-1:0]	ff_param_fill;
	reg		[TIMER_WIDTH-1:0]	ff_param_timeout;
	always @(posedge aclk) begin
		if ( ~aresetn ) begin
			ff_enable        <= INIT_CTL_ENABLE;
			ff_param_width   <= INIT_PARAM_WIDTH;
			ff_param_height  <= INIT_PARAM_HEIGHT;
			ff_param_fill    <= INIT_PARAM_FILL;
			ff_param_timeout <= INIT_PARAM_TIMEOUT;
		end
		else begin
			ff_enable        <= reg_enable;
			ff_param_width   <= reg_param_width;
			ff_param_height  <= reg_param_height;
			ff_param_fill    <= reg_param_fill;
			ff_param_timeout <= reg_param_timeout;
		end
	end
	
	jelly_video_normalizer_core
			#(
				.TUSER_WIDTH		(TUSER_WIDTH),
				.TDATA_WIDTH		(TDATA_WIDTH),
				.X_WIDTH			(X_WIDTH),
				.Y_WIDTH			(Y_WIDTH),
				.TIMER_WIDTH		(TIMER_WIDTH),
				.S_SLAVE_REGS		(S_SLAVE_REGS),
				.S_MASTER_REGS		(S_MASTER_REGS),
				.M_SLAVE_REGS		(M_SLAVE_REGS),
				.M_MASTER_REGS		(M_MASTER_REGS)
			)
		i_video_normalizer_core
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				.aclken				(aclken),
				
				.ctl_enable			(ff_enable),
				.ctl_busy			(busy),
				
				.param_width		(ff_param_width),
				.param_height		(ff_param_height),
				.param_fill			(ff_param_fill),
				.param_timeout		(ff_param_timeout),
				
				.s_axi4s_tuser		(s_axi4s_tuser),
				.s_axi4s_tlast		(s_axi4s_tlast),
				.s_axi4s_tdata		(s_axi4s_tdata),
				.s_axi4s_tvalid		(s_axi4s_tvalid),
				.s_axi4s_tready		(s_axi4s_tready),
				
				.m_axi4s_tuser		(m_axi4s_tuser),
				.m_axi4s_tlast		(m_axi4s_tlast),
				.m_axi4s_tdata		(m_axi4s_tdata),
				.m_axi4s_tvalid		(m_axi4s_tvalid),
				.m_axi4s_tready		(m_axi4s_tready)
			);
	
	
endmodule



`default_nettype wire



// end of file
