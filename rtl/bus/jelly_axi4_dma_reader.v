// ---------------------------------------------------------------------------
//  AXI4 から Read して AXI4Streamにするコア
//      受付コマンド数などは AXI interconnect などで制約できるので
//    コアはシンプルな作りとする
//
//                                      Copyright (C) 2015 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly_axi4_dma_reader
		#(
			parameter	AXI4_ID_WIDTH    = 6,
			parameter	AXI4_ADDR_WIDTH  = 32,
			parameter	AXI4_DATA_SIZE   = 2,	// 0:8bit, 1:16bit, 2:32bit ...
			parameter	AXI4_DATA_WIDTH  = (8 << AXI4_DATA_SIZE),
			parameter	AXI4_LEN_WIDTH   = 8,
			parameter	AXI4_QOS_WIDTH   = 4,
			parameter	AXI4S_DATA_WIDTH = AXI4_DATA_WIDTH,
			parameter	COUNT_WIDTH      = AXI4_ADDR_WIDTH - AXI4_DATA_SIZE
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
			
			// master AXI4 (read)
			output	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_arid,
			output	wire	[AXI4_ADDR_WIDTH-1:0]	m_axi4_araddr,
			output	wire	[1:0]					m_axi4_arburst,
			output	wire	[3:0]					m_axi4_arcache,
			output	wire	[AXI4_LEN_WIDTH-1:0]	m_axi4_arlen,
			output	wire	[0:0]					m_axi4_arlock,
			output	wire	[2:0]					m_axi4_arprot,
			output	wire	[AXI4_QOS_WIDTH-1:0]	m_axi4_arqos,
			output	wire	[3:0]					m_axi4_arregion,
			output	wire	[2:0]					m_axi4_arsize,
			output	wire							m_axi4_arvalid,
			input	wire							m_axi4_arready,
			input	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_rid,
			input	wire	[1:0]					m_axi4_rresp,
			input	wire	[AXI4_DATA_WIDTH-1:0]	m_axi4_rdata,
			input	wire							m_axi4_rlast,
			input	wire							m_axi4_rvalid,
			output	wire							m_axi4_rready,
			
			// master AXI4-Stream
			output	wire							m_axi4s_tlast,
			output	wire	[AXI4S_DATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire							m_axi4s_tvalid,
			input	wire							m_axi4s_tready
		);
	
	wire							cmd_busy;
	
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
				
				.m_axi4_addr		(m_axi4_araddr),
				.m_axi4_len			(m_axi4_arlen),
				.m_axi4_valid		(m_axi4_arvalid),
				.m_axi4_ready		(m_axi4_arready)
			);
	
	assign m_axi4_arid     = 0;
	assign m_axi4_arburst  = 2'b01;
	assign m_axi4_arcache  = 4'b0001;
	assign m_axi4_arlock   = 1'b0;
	assign m_axi4_arprot   = 3'b000;
	assign m_axi4_arqos    = 0;
	assign m_axi4_arregion = 4'b0000;
	assign m_axi4_arsize   = AXI4_DATA_SIZE;
	
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
			
			if ( m_axi4_rvalid && m_axi4_rready ) begin
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
	
	
	assign m_axi4s_tlast  = ((m_axi4_rlast & param_last_through) | reg_rlast_force);
	assign m_axi4s_tdata  = m_axi4_rdata;
	assign m_axi4s_tvalid = m_axi4_rvalid;
	
	assign m_axi4_rready  = m_axi4s_tready;
	
	assign busy = cmd_busy || reg_rbusy;
	
endmodule


`default_nettype wire


// end of file
