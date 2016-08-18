// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_dma
		#(
			parameter	COMPONENT_NUM        = 3,
			parameter	COMPONENT_DATA_WIDTH = 8,
			parameter	COMPONENT_SEL_WIDTH  = COMPONENT_NUM <= 2  ?  1 :
			                                   COMPONENT_NUM <= 4  ?  2 :
			                                   COMPONENT_NUM <= 8  ?  3 :
			                                   COMPONENT_NUM <= 16 ?  4 :
			                                   COMPONENT_NUM <= 32 ?  5 :
			                                   COMPONENT_NUM <= 64 ?  6 : 7,
			
			parameter	DATA_WIDTH           = COMPONENT_NUM * COMPONENT_DATA_WIDTH,
			parameter	STRB_WIDTH           = COMPONENT_NUM,
			
			parameter	ID_WIDTH             = 6,
			parameter	ADDR_WIDTH           = 24,
			
			parameter	M_AXI4_ID_WIDTH      = ID_WIDTH,
			parameter	M_AXI4_ADDR_WIDTH    = 32,
			parameter	M_AXI4_DATA_SIZE     = 2,	// 0:8bit, 1:16bit, 2:32bit ...
			parameter	M_AXI4_DATA_WIDTH    = (8 << M_AXI4_DATA_SIZE),
			parameter	M_AXI4_LEN_WIDTH     = 8,
			parameter	M_AXI4_QOS_WIDTH     = 4,
			parameter	M_AXI4_ARID          = {M_AXI4_ID_WIDTH{1'b0}},
			parameter	M_AXI4_ARSIZE        = M_AXI4_DATA_SIZE,
			parameter	M_AXI4_ARBURST       = 2'b01,
			parameter	M_AXI4_ARLOCK        = 1'b0,
			parameter	M_AXI4_ARCACHE       = 4'b0001,
			parameter	M_AXI4_ARPROT        = 3'b000,
			parameter	M_AXI4_ARQOS         = 0,
			parameter	M_AXI4_ARREGION      = 4'b0000,
			
			parameter	SLAVE_REGS           = 1,
			parameter	MASTER_REGS          = 1,
			parameter	M_AXI4_REGS          = 1
		)
		(
			input	wire											reset,
			input	wire											clk,
			
			input	wire	[M_AXI4_ADDR_WIDTH*COMPONENT_NUM-1:0]	param_addr,
			input	wire	[M_AXI4_LEN_WIDTH-1:0]					param_arlen,
			
			// slave port
			input	wire	[ID_WIDTH-1:0]							s_id,
			input	wire	[ADDR_WIDTH-1:0]						s_addr,
			input	wire											s_valid,
			output	wire											s_ready,
			
			// master port
			output	wire	[ID_WIDTH-1:0]							m_id,
			output	wire											m_last,
			output	wire	[STRB_WIDTH-1:0]						m_strb,
			output	wire	[DATA_WIDTH-1:0]						m_data,
			output	wire											m_valid,
			input	wire											m_ready,
			
			// AXI4 read (master)
			output	wire	[M_AXI4_ID_WIDTH-1:0]					m_axi4_arid,
			output	wire	[M_AXI4_ADDR_WIDTH-1:0]					m_axi4_araddr,
			output	wire	[M_AXI4_LEN_WIDTH-1:0]					m_axi4_arlen,
			output	wire	[2:0]									m_axi4_arsize,
			output	wire	[1:0]									m_axi4_arburst,
			output	wire	[0:0]									m_axi4_arlock,
			output	wire	[3:0]									m_axi4_arcache,
			output	wire	[2:0]									m_axi4_arprot,
			output	wire	[M_AXI4_QOS_WIDTH-1:0]					m_axi4_arqos,
			output	wire	[3:0]									m_axi4_arregion,
			output	wire											m_axi4_arvalid,
			input	wire											m_axi4_arready,
			input	wire	[M_AXI4_ID_WIDTH-1:0]					m_axi4_rid,
			input	wire	[M_AXI4_DATA_WIDTH-1:0]					m_axi4_rdata,
			input	wire	[1:0]									m_axi4_rresp,
			input	wire											m_axi4_rlast,
			input	wire											m_axi4_rvalid,
			output	wire											m_axi4_rready
		);
	
	
	// -----------------------------
	//  insert FF
	// -----------------------------
	
	// slave port
	wire	[ID_WIDTH-1:0]				slave_id;
	wire	[ADDR_WIDTH-1:0]			slave_addr;
	wire								slave_valid;
	wire								slave_ready;
	
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH			(ID_WIDTH+ADDR_WIDTH),
				.SLAVE_REGS			(SLAVE_REGS),
				.MASTER_REGS		(1)
			)
		i_pipeline_insert_ff_slave
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_data				({s_id, s_addr}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({slave_id, slave_addr}),
				.m_valid			(slave_valid),
				.m_ready			(slave_ready),
				
				.buffered			(),
				.s_ready_next		()
			);
	
	
	// master port
	wire	[ID_WIDTH-1:0]				master_id;
	wire								master_last;
	wire	[STRB_WIDTH-1:0]			master_strb;
	wire	[COMPONENT_DATA_WIDTH-1:0]	master_component_data;
	wire								master_valid;
	wire								master_ready;
	
	wire	[COMPONENT_DATA_WIDTH-1:0]	m_component_data;
	
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH			(ID_WIDTH+1+STRB_WIDTH+DATA_WIDTH),
				.SLAVE_REGS			(1),
				.MASTER_REGS		(MASTER_REGS)
			)
		i_pipeline_insert_ff_master
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_data				({master_id, master_last, master_strb, master_component_data}),
				.s_valid			(master_valid),
				.s_ready			(master_ready),
				
				.m_data				({m_id, m_last, m_strb, m_component_data}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.buffered			(),
				.s_ready_next		()
			);
	
	assign m_data = {COMPONENT_NUM{m_component_data}};
	
	
	// AXI4 ar
	wire	[M_AXI4_ID_WIDTH-1:0]	axi4_arid;
	wire	[M_AXI4_ADDR_WIDTH-1:0]	axi4_araddr;
	wire							axi4_arvalid;
	wire							axi4_arready;
	
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH			(M_AXI4_ID_WIDTH+M_AXI4_ADDR_WIDTH),
				.SLAVE_REGS			(1),
				.MASTER_REGS		(M_AXI4_REGS)
			)
		i_pipeline_insert_ff_ar
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_data				({axi4_arid, axi4_araddr}),
				.s_valid			(axi4_arvalid),
				.s_ready			(axi4_arready),
				
				.m_data				({m_axi4_arid, m_axi4_araddr}),
				.m_valid			(m_axi4_arvalid),
				.m_ready			(m_axi4_arready),
				
				.buffered			(),
				.s_ready_next		()
			);
	
	assign m_axi4_arlen    = param_arlen;
	
	assign m_axi4_arid     = M_AXI4_ARID;
	assign m_axi4_arsize   = M_AXI4_ARSIZE;
	assign m_axi4_arburst  = M_AXI4_ARBURST;
	assign m_axi4_arcache  = M_AXI4_ARCACHE;
	assign m_axi4_arlock   = M_AXI4_ARLOCK;
	assign m_axi4_arprot   = M_AXI4_ARPROT;
	assign m_axi4_arqos    = M_AXI4_ARQOS;
	assign m_axi4_arregion = M_AXI4_ARREGION;
	
	
	
	// -----------------------------
	//  core
	// -----------------------------
	
	// address
	reg		[M_AXI4_ID_WIDTH-1:0]		reg_arid;
	reg		[COMPONENT_SEL_WIDTH-1:0]	reg_arcomponent;
	reg		[ADDR_WIDTH-1:0]			reg_addr;
	reg		[M_AXI4_ADDR_WIDTH-1:0]		reg_araddr;
	reg									reg_arvalid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_arid        <= {M_AXI4_ID_WIDTH{1'bx}};
			reg_arcomponent <= {COMPONENT_SEL_WIDTH{1'bx}};
			reg_araddr      <= {M_AXI4_ADDR_WIDTH{1'bx}};
			reg_arvalid     <= 1'b0;
		end
		else begin
			if ( slave_valid && slave_ready ) begin
				reg_arid        <= slave_id;
				reg_arcomponent <= {COMPONENT_SEL_WIDTH{1'b0}};
				reg_addr        <= slave_addr;
				reg_araddr      <= slave_addr + param_addr[M_AXI4_ADDR_WIDTH-1:0];
				reg_arvalid     <= 1'b1;
			end
			else if ( axi4_arvalid && axi4_arready ) begin
				if ( reg_arcomponent == (COMPONENT_NUM-1) ) begin
					reg_arid        <= {M_AXI4_ID_WIDTH{1'bx}};
					reg_arcomponent <= {COMPONENT_SEL_WIDTH{1'bx}};
					reg_araddr      <= {M_AXI4_ADDR_WIDTH{1'bx}};
					reg_arvalid     <= 1'b0;
				end
				else begin
					reg_arid        <= reg_arid;
					reg_arcomponent <= reg_arcomponent + 1;
					reg_araddr      <= reg_addr + (param_addr >> ((reg_arcomponent + 1)*M_AXI4_ADDR_WIDTH));
					reg_arvalid     <= 1'b1;
				end
			end
		end
	end
	
	assign slave_ready = (!reg_arvalid || ((reg_arcomponent == (COMPONENT_NUM-1)) && axi4_arready));
	
	assign axi4_arid    = reg_arid;
	assign axi4_araddr  = reg_araddr;
	assign axi4_arvalid = reg_arvalid;
	
	
	// data
	reg		[STRB_WIDTH-1:0]	reg_strb;
	always @(posedge clk) begin
		if ( reset ) begin
			reg_strb <= 1;
		end
		else begin
			if ( m_axi4_rvalid && m_axi4_rready && m_axi4_rlast ) begin
				if ( reg_strb[COMPONENT_NUM-1] ) begin
					reg_strb <= 1;
				end
				else begin
					reg_strb <= (reg_strb << 1);
				end
			end
		end
	end
	
	assign m_axi4_rready         = master_ready;
	
	assign master_id             = m_axi4_rid;
	assign master_last           = (m_axi4_rlast && reg_strb[COMPONENT_NUM-1]);
	assign master_strb           = reg_strb;
	assign master_component_data = m_axi4_rdata;
	assign master_valid          = m_axi4_rvalid;
	
endmodule


`default_nettype wire


// end of file
