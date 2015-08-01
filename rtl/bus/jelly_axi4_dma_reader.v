// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



//  AXI4 から Read して AXI4Streamにするコア
module jelly_axi4_dma_reader
		#(
			parameter	AXI4_ID_WIDTH    = 6,
			parameter	AXI4_ADDR_WIDTH  = 32,
			parameter	AXI4_DATA_SIZE   = 2,	// 0:8bit, 1:16bit, 2:32bit ...
			parameter	AXI4_DATA_WIDTH  = (8 << AXI4_DATA_SIZE),
			parameter	AXI4_LEN_WIDTH   = 8,
			parameter	AXI4_QOS_WIDTH   = 4,
			parameter	AXI4_ARID        = {AXI4_ID_WIDTH{1'b0}},
			parameter	AXI4_ARSIZE      = AXI4_DATA_SIZE,
			parameter	AXI4_ARBURST     = 2'b01,
			parameter	AXI4_ARLOCK      = 1'b0,
			parameter	AXI4_ARCACHE     = 4'b0001,
			parameter	AXI4_ARPROT      = 3'b000,
			parameter	AXI4_ARQOS       = 0,
			parameter	AXI4_ARREGION    = 4'b0000,
			parameter	AXI4S_DATA_WIDTH = AXI4_DATA_WIDTH,
			parameter	COUNT_WIDTH      = AXI4_ADDR_WIDTH - AXI4_DATA_SIZE,
			parameter	LIMITTER_ENABLE  = 0,
			parameter	AXI4_AR_REGS     = 1,
			parameter	AXI4_R_REGS      = 1,
			parameter	AXI4S_REGS       = 0
		)
		(
			input	wire							aresetn,
			input	wire							aclk,
			
			// control
			input	wire							enable,
			output	wire							busy,
			
			// parameter
			input	wire	[AXI4_ADDR_WIDTH-1:0]	param_addr,				// 開始アドレス
			input	wire	[COUNT_WIDTH-1:0]		param_count,			// 転送個数
			input	wire	[AXI4_LEN_WIDTH-1:0]	param_maxlen,			// arlenの最大値
			input	wire							param_last_end,			// 転送の最後にlast付与
			input	wire							param_last_through,		// lastはスルーする
			input	wire							param_last_unit,		// unit単位でlast付与
			input	wire	[COUNT_WIDTH-1:0]		param_unit,				// unitサイズ
			input	wire	[COUNT_WIDTH-1:0]		param_limit,			// 同時発行サイズ
			
			// master AXI4 (read)
			output	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_arid,
			output	wire	[AXI4_ADDR_WIDTH-1:0]	m_axi4_araddr,
			output	wire	[AXI4_LEN_WIDTH-1:0]	m_axi4_arlen,
			output	wire	[2:0]					m_axi4_arsize,
			output	wire	[1:0]					m_axi4_arburst,
			output	wire	[0:0]					m_axi4_arlock,
			output	wire	[3:0]					m_axi4_arcache,
			output	wire	[2:0]					m_axi4_arprot,
			output	wire	[AXI4_QOS_WIDTH-1:0]	m_axi4_arqos,
			output	wire	[3:0]					m_axi4_arregion,
			output	wire							m_axi4_arvalid,
			input	wire							m_axi4_arready,
			input	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_rid,
			input	wire	[AXI4_DATA_WIDTH-1:0]	m_axi4_rdata,
			input	wire	[1:0]					m_axi4_rresp,
			input	wire							m_axi4_rlast,
			input	wire							m_axi4_rvalid,
			output	wire							m_axi4_rready,
			
			// master AXI4-Stream
			output	wire	[AXI4S_DATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire							m_axi4s_tlast,
			output	wire							m_axi4s_tvalid,
			input	wire							m_axi4s_tready
		);
	
	
	// -----------------------------
	//  insert FF
	// -----------------------------
	
	wire	[AXI4_ADDR_WIDTH-1:0]	axi4_araddr;
	wire	[AXI4_LEN_WIDTH-1:0]	axi4_arlen;
	wire							axi4_arvalid;
	wire							axi4_arready;
	
	wire	[AXI4_DATA_WIDTH-1:0]	axi4_rdata;
	wire							axi4_rlast;
	wire							axi4_rvalid;
	wire							axi4_rready;
	
	wire	[AXI4S_DATA_WIDTH-1:0]	axi4s_tdata;
	wire							axi4s_tlast;
	wire							axi4s_tvalid;
	wire							axi4s_tready;
	
	// AXI4 ar
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH			(AXI4_ADDR_WIDTH+AXI4_LEN_WIDTH),
				.SLAVE_REGS			(AXI4_AR_REGS),
				.MASTER_REGS		(AXI4_AR_REGS)
			)
		i_pipeline_insert_ff_ar
			(
				.reset				(~aresetn),
				.clk				(aclk),
				.cke				(1'b1),
				
				.s_data				({axi4_araddr, axi4_arlen}),
				.s_valid			(axi4_arvalid),
				.s_ready			(axi4_arready),
				
				.m_data				({m_axi4_araddr, m_axi4_arlen}),
				.m_valid			(m_axi4_arvalid),
				.m_ready			(m_axi4_arready),
				
				.buffered			(),
				.s_ready_next		()
			);
	assign m_axi4_arid     = AXI4_ARID;
	assign m_axi4_arsize   = AXI4_ARSIZE;
	assign m_axi4_arburst  = AXI4_ARBURST;
	assign m_axi4_arcache  = AXI4_ARCACHE;
	assign m_axi4_arlock   = AXI4_ARLOCK;
	assign m_axi4_arprot   = AXI4_ARPROT;
	assign m_axi4_arqos    = AXI4_ARQOS;
	assign m_axi4_arregion = AXI4_ARREGION;
	
	
	// AXI4 r
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH			(AXI4_DATA_WIDTH+1),
				.SLAVE_REGS			(AXI4_R_REGS),
				.MASTER_REGS		(AXI4_R_REGS)
			)
		i_pipeline_insert_ff_r
			(
				.reset				(~aresetn),
				.clk				(aclk),
				.cke				(1'b1),
				
				.s_data				({m_axi4_rdata, m_axi4_rlast}),
				.s_valid			(m_axi4_rvalid),
				.s_ready			(m_axi4_rready),
				
				.m_data				({axi4_rdata, axi4_rlast}),
				.m_valid			(axi4_rvalid),
				.m_ready			(axi4_rready),
				
				.buffered			(),
				.s_ready_next		()
			);
	
	
	// AXI4Stream
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH			(AXI4S_DATA_WIDTH+1),
				.SLAVE_REGS			(AXI4S_REGS),
				.MASTER_REGS		(AXI4S_REGS)
			)
		i_pipeline_insert_ff_t
			(
				.reset				(~aresetn),
				.clk				(aclk),
				.cke				(1'b1),
				
				.s_data				({axi4s_tdata, axi4s_tlast}),
				.s_valid			(axi4s_tvalid),
				.s_ready			(axi4s_tready),
				
				.m_data				({m_axi4s_tdata, m_axi4s_tlast}),
				.m_valid			(m_axi4s_tvalid),
				.m_ready			(m_axi4s_tready),
				
				.buffered			(),
				.s_ready_next		()
			);
	
	
	// -----------------------------
	//  Limitter
	// -----------------------------
	
	reg		[COUNT_WIDTH-1:0]	reg_limit_counter, next_limit_counter;
	reg							reg_limiter;
	always @* begin
		next_limit_counter = reg_limit_counter;
		if ( axi4_arvalid && axi4_arready ) begin
			next_limit_counter = next_limit_counter + axi4_arlen + 1'b1;
		end
		
		if ( m_axi4s_tvalid && m_axi4s_tready ) begin
			next_limit_counter = next_limit_counter - 1'b1;
		end
	end
	
	always @(posedge aclk) begin
		if ( !aresetn ) begin
			reg_limit_counter <= {COUNT_WIDTH{1'b0}};
			reg_limiter       <= 1'b0;
		end
		else begin
			reg_limit_counter <= next_limit_counter;
			if ( !axi4_arvalid || axi4_arready ) begin
				reg_limiter <= LIMITTER_ENABLE && (reg_limit_counter >= param_limit);
			end
		end
	end
	
	
	// -----------------------------
	//  Control
	// -----------------------------
	
	wire							cmd_busy;
	
	wire	[AXI4_ADDR_WIDTH-1:0]	axi4_ctl_araddr;
	wire	[AXI4_LEN_WIDTH-1:0]	axi4_ctl_arlen;
	wire							axi4_ctl_arvalid;
	wire							axi4_ctl_arready;
	
	jelly_axi4_dma_addr
			#(
				.AXI4_ID_WIDTH		(AXI4_ID_WIDTH),
				.AXI4_ADDR_WIDTH	(AXI4_ADDR_WIDTH),
				.AXI4_DATA_SIZE		(AXI4_DATA_SIZE),
				.AXI4_LEN_WIDTH		(AXI4_LEN_WIDTH),
				.COUNT_WIDTH		(COUNT_WIDTH)
			)
		i_axi4_dma_addr
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				
				.enable				(enable & !busy),
				.busy				(cmd_busy),
				
				.param_addr			(param_addr),
				.param_count		(param_count),
				.param_maxlen		(param_maxlen),
				
				.m_cmd_len			(),
				.m_cmd_valid		(),
				.m_cmd_ready		(1'b1),
				
				.m_axi4_addr		(axi4_ctl_araddr),
				.m_axi4_len			(axi4_ctl_arlen),
				.m_axi4_valid		(axi4_ctl_arvalid),
				.m_axi4_ready		(axi4_ctl_arready)
			);
	
	assign axi4_araddr      = axi4_ctl_araddr;
	assign axi4_arlen       = axi4_ctl_arlen;
	assign axi4_arvalid     = axi4_ctl_arvalid & !reg_limiter;
	assign axi4_ctl_arready = axi4_arready     & !reg_limiter;
	
	
	
	reg							reg_rbusy;
	reg		[COUNT_WIDTH-1:0]	reg_rcount;
	reg							reg_rlast_force;
	reg		[COUNT_WIDTH-1:0]	reg_unit_count;
	
	always @(posedge aclk) begin
		if ( !aresetn ) begin
			reg_rbusy        <= 1'b0;
			reg_rlast_force  <= 1'bx;
			reg_rcount       <= {COUNT_WIDTH{1'bx}};
			reg_unit_count   <= {COUNT_WIDTH{1'bx}};
		end
		else begin
			if ( enable && !busy ) begin
				// start
				reg_rbusy        <= 1'b1;
				reg_rlast_force  <= (param_last_unit && ((param_unit - 1'b1) == 0)) || (param_last_end && ((param_count - 1'b1) == 0));
				reg_rcount       <= param_count - 1'b1;
				reg_unit_count   <= param_unit - 1'b1;
			end
			
			if ( axi4_rvalid && axi4_rready ) begin
				reg_rlast_force <= 1'b0;
				reg_rcount      <= reg_rcount     - 1'b1;
				reg_unit_count  <= reg_unit_count - 1'b1;
				
				if ( (reg_unit_count - 1'b1) == 0 && param_last_unit ) begin
					reg_rlast_force <= 1'b1;
				end
				
				if ( (reg_rcount - 1'b1) == 0 && param_last_end ) begin
					reg_rlast_force <= 1'b1;
				end

				if ( reg_unit_count == 0 ) begin
					reg_unit_count <= param_unit - 1'b1;
				end
				
				if ( reg_rcount == 0 ) begin
					reg_rbusy <= 1'b0;
				end
			end
		end
	end
	
	
	assign axi4s_tlast  = ((axi4_rlast & param_last_through) | reg_rlast_force);
	assign axi4s_tdata  = axi4_rdata;
	assign axi4s_tvalid = axi4_rvalid;
	
	assign axi4_rready  = axi4s_tready;
	
	assign busy = cmd_busy || reg_rbusy;
	
endmodule


`default_nettype wire


// end of file
