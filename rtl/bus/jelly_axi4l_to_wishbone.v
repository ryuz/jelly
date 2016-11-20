// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// AXI4Lite => WISHBONE converter
module jelly_axi4l_to_wishbone
		#(
			parameter	AXI4L_ADDR_WIDTH = 32,
			parameter	AXI4L_DATA_SIZE  = 2,						// 0:8bit, 1:16bit, 2:32bit ...
			parameter	AXI4L_DATA_WIDTH = (8 << AXI4L_DATA_SIZE),
			parameter	AXI4L_STRB_WIDTH = (1 << AXI4L_DATA_SIZE)
		)
		(
			// AXI4Light
			input	wire											s_axi4l_aresetn,
			input	wire											s_axi4l_aclk,
			input	wire	[AXI4L_ADDR_WIDTH-1:0]					s_axi4l_awaddr,
			input	wire	[2:0]									s_axi4l_awprot,
			input	wire											s_axi4l_awvalid,
			output	wire											s_axi4l_awready,
			input	wire	[AXI4L_STRB_WIDTH-1:0]					s_axi4l_wstrb,
			input	wire	[AXI4L_DATA_WIDTH-1:0]					s_axi4l_wdata,
			input	wire											s_axi4l_wvalid,
			output	wire											s_axi4l_wready,
			output	wire	[1:0]									s_axi4l_bresp,
			output	wire											s_axi4l_bvalid,
			input	wire											s_axi4l_bready,
			input	wire	[AXI4L_ADDR_WIDTH-1:0]					s_axi4l_araddr,
			input	wire	[2:0]									s_axi4l_arprot,
			input	wire											s_axi4l_arvalid,
			output	wire											s_axi4l_arready,
			output	wire	[AXI4L_DATA_WIDTH-1:0]					s_axi4l_rdata,
			output	wire	[1:0]									s_axi4l_rresp,
			output	wire											s_axi4l_rvalid,
			input	wire											s_axi4l_rready,
			
			// WISHBONE
			output	wire											m_wb_rst_o,
			output	wire											m_wb_clk_o,
			output	wire	[AXI4L_ADDR_WIDTH-1:AXI4L_DATA_SIZE]	m_wb_adr_o,
			output	wire	[AXI4L_DATA_WIDTH-1:0]					m_wb_dat_o,
			input	wire	[AXI4L_DATA_WIDTH-1:0]					m_wb_dat_i,
			output	wire											m_wb_we_o,
			output	wire	[AXI4L_STRB_WIDTH-1:0]					m_wb_sel_o,
			output	wire											m_wb_stb_o,
			input	wire											m_wb_ack_i
		);
	
	reg								reg_rvalid;
	reg		[AXI4L_DATA_WIDTH-1:0]	reg_rdata;
	reg								reg_bvalid;
	
	always @( posedge m_wb_clk_o ) begin
		if ( m_wb_rst_o ) begin
			reg_rvalid <= 1'b0;
			reg_rdata  <= {AXI4L_DATA_WIDTH{1'bx}};
			reg_bvalid <= 1'b0;
		end
		else begin
			if ( m_wb_stb_o & ~m_wb_we_o & m_wb_ack_i ) begin
				reg_rvalid <= 1'b1;
				reg_rdata  <= m_wb_dat_i;
			end
			else if ( s_axi4l_rvalid & s_axi4l_rready ) begin
				reg_rvalid <= 1'b0;
				reg_rdata  <= {AXI4L_DATA_WIDTH{1'bx}};
			end
			
			if ( m_wb_stb_o & m_wb_we_o & m_wb_ack_i ) begin
				reg_bvalid <= 1'b1;
			end
			else if ( s_axi4l_bvalid & s_axi4l_bready ) begin
				reg_bvalid <= 1'b0;
			end
		end
	end
	
	
	assign m_wb_rst_o      = ~s_axi4l_aresetn;
	assign m_wb_clk_o      = s_axi4l_aclk;
	assign m_wb_adr_o      = m_wb_we_o ? s_axi4l_awaddr[AXI4L_ADDR_WIDTH-1:AXI4L_DATA_SIZE] : s_axi4l_araddr[AXI4L_ADDR_WIDTH-1:AXI4L_DATA_SIZE];
	assign m_wb_dat_o      = s_axi4l_wdata;
	assign m_wb_we_o       = ~s_axi4l_arvalid;
	assign m_wb_sel_o      = s_axi4l_wstrb;
	assign m_wb_stb_o      = ((s_axi4l_awvalid & s_axi4l_wvalid) | s_axi4l_arvalid);
	
	assign s_axi4l_awready = (m_wb_stb_o & m_wb_we_o & m_wb_ack_i);
	assign s_axi4l_wready  = (m_wb_stb_o & m_wb_we_o & m_wb_ack_i);
	assign s_axi4l_bresp   = 2'b00;
	assign s_axi4l_bvalid  = reg_bvalid;
	assign s_axi4l_arready = (m_wb_stb_o & ~m_wb_we_o & m_wb_ack_i);
	assign s_axi4l_rdata   = reg_rdata;
	assign s_axi4l_rresp   = 2'b00;
	assign s_axi4l_rvalid  = reg_rvalid;
	
endmodule


`default_nettype wire


// end of file
