// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_rasterizer_params
		#(
			parameter	WB_ADR_WIDTH      = 12,
			parameter	WB_DAT_WIDTH      = 32,
			parameter	WB_SEL_WIDTH      = (WB_DAT_WIDTH / 8),
			
			parameter	BANK_NUM          = 2,
			parameter	BANK_ADDR_WIDTH   = 10,
			parameter	PARAMS_ADDR_WIDTH = 8,
			
			parameter	EDGE_NUM          = 12,
			parameter	EDGE_WIDTH        = 32,
			parameter	EDGE_PARAM_NUM    = EDGE_NUM*2,
			parameter	EDGE_RAM_TYPE     = "distributed",
			
			parameter	POLYGON_NUM       = 6,
			parameter	POLYGON_WIDTH     = 32,
			parameter	POLYGON_PARAM_NUM = POLYGON_NUM*3,
			parameter	POLYGON_RAM_TYPE  = "distributed",
			
			parameter	REGION_NUM        = POLYGON_NUM,
			parameter	REGION_WIDTH      = EDGE_NUM,
			parameter	REGION_PARAM_NUM  = REGION_NUM*2,
			parameter	REGION_RAM_TYPE   = "distributed",
			
			parameter	INIT_ENABLE       = 1'b0,
			parameter	INIT_BANK         = 0
		)
		(
			input	wire											reset,
			input	wire											clk,
			input	wire											cke,
			
			output	wire											start,
			input	wire											busy,
			
			output	wire	[EDGE_PARAM_NUM   *EDGE_WIDTH-1:0]		edge_params,
			output	wire	[POLYGON_PARAM_NUM*POLYGON_WIDTH-1:0]	polygon_params,
			output	wire	[REGION_PARAM_NUM *REGION_WIDTH-1:0]	region_params,
			
			input	wire											s_wb_rst_i,
			input	wire											s_wb_clk_i,
			input	wire	[WB_ADR_WIDTH-1:0]						s_wb_adr_i,
			output	wire	[WB_DAT_WIDTH-1:0]						s_wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]						s_wb_dat_i,
			input	wire											s_wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]						s_wb_sel_i,
			input	wire											s_wb_stb_i,
			output	wire											s_wb_ack_o
		);
	
	
	// 一部処理系で $clog2 が正しく動かないので
	parameter	BANK_WIDTH         = BANK_NUM          <=     1 ?  0 :
			                         BANK_NUM          <=     2 ?  1 :
			                         BANK_NUM          <=     4 ?  2 :
			                         BANK_NUM          <=     8 ?  3 :
			                         BANK_NUM          <=    16 ?  4 :
			                         BANK_NUM          <=    32 ?  5 :
			                         BANK_NUM          <=    64 ?  6 :
			                         BANK_NUM          <=   128 ?  7 :
			                         BANK_NUM          <=   256 ?  8 :
			                         BANK_NUM          <=   512 ?  9 :
			                         BANK_NUM          <=  1024 ? 10 :
			                         BANK_NUM          <=  2048 ? 11 :
			                         BANK_NUM          <=  4096 ? 12 :
			                         BANK_NUM          <=  8192 ? 13 :
			                         BANK_NUM          <= 16384 ? 14 :
			                         BANK_NUM          <= 32768 ? 15 : 16;
	
	parameter	BANK_BITS          = BANK_WIDTH > 0 ? BANK_WIDTH : 1;
	
	localparam	EDGE_ADDR_WIDTH    = EDGE_PARAM_NUM    <=     2 ?  1 :
			                         EDGE_PARAM_NUM    <=     4 ?  2 :
			                         EDGE_PARAM_NUM    <=     8 ?  3 :
			                         EDGE_PARAM_NUM    <=    16 ?  4 :
			                         EDGE_PARAM_NUM    <=    32 ?  5 :
			                         EDGE_PARAM_NUM    <=    64 ?  6 :
			                         EDGE_PARAM_NUM    <=   128 ?  7 :
			                         EDGE_PARAM_NUM    <=   256 ?  8 :
			                         EDGE_PARAM_NUM    <=   512 ?  9 :
			                         EDGE_PARAM_NUM    <=  1024 ? 10 :
			                         EDGE_PARAM_NUM    <=  2048 ? 11 :
			                         EDGE_PARAM_NUM    <=  4096 ? 12 :
			                         EDGE_PARAM_NUM    <=  8192 ? 13 :
			                         EDGE_PARAM_NUM    <= 16384 ? 14 :
			                         EDGE_PARAM_NUM    <= 32768 ? 15 : 16;
	
	localparam	POLYGON_ADDR_WIDTH = POLYGON_PARAM_NUM <=     2 ?  1 :
			                         POLYGON_PARAM_NUM <=     4 ?  2 :
			                         POLYGON_PARAM_NUM <=     8 ?  3 :
			                         POLYGON_PARAM_NUM <=    16 ?  4 :
			                         POLYGON_PARAM_NUM <=    32 ?  5 :
			                         POLYGON_PARAM_NUM <=    64 ?  6 :
			                         POLYGON_PARAM_NUM <=   128 ?  7 :
			                         POLYGON_PARAM_NUM <=   256 ?  8 :
			                         POLYGON_PARAM_NUM <=   512 ?  9 :
			                         POLYGON_PARAM_NUM <=  1024 ? 10 :
			                         POLYGON_PARAM_NUM <=  2048 ? 11 :
			                         POLYGON_PARAM_NUM <=  4096 ? 12 :
			                         POLYGON_PARAM_NUM <=  8192 ? 13 :
			                         POLYGON_PARAM_NUM <= 16384 ? 14 :
			                         POLYGON_PARAM_NUM <= 32768 ? 15 : 16;
	
	localparam	REGION_ADDR_WIDTH  = REGION_PARAM_NUM <=     2 ?  1 :
			                         REGION_PARAM_NUM <=     4 ?  2 :
			                         REGION_PARAM_NUM <=     8 ?  3 :
			                         REGION_PARAM_NUM <=    16 ?  4 :
			                         REGION_PARAM_NUM <=    32 ?  5 :
			                         REGION_PARAM_NUM <=    64 ?  6 :
			                         REGION_PARAM_NUM <=   128 ?  7 :
			                         REGION_PARAM_NUM <=   256 ?  8 :
			                         REGION_PARAM_NUM <=   512 ?  9 :
			                         REGION_PARAM_NUM <=  1024 ? 10 :
			                         REGION_PARAM_NUM <=  2048 ? 11 :
			                         REGION_PARAM_NUM <=  4096 ? 12 :
			                         REGION_PARAM_NUM <=  8192 ? 13 :
			                         REGION_PARAM_NUM <= 16384 ? 14 :
			                         REGION_PARAM_NUM <= 32768 ? 15 : 16;
	
	
	
	// 制御レジスタ
	localparam	REG_ADDR_ENABLE      = 32'h00;
	localparam	REG_ADDR_BANK        = 32'h01;
	localparam	REG_ADDR_PARAMS_BANK = 32'h02;
	
	
	wire	[WB_DAT_WIDTH-1:0]	wb_regs_dat_o;
	wire						wb_regs_stb_i;
	wire						wb_regs_ack_o;
	
	reg							reg_enable;
	reg		[BANK_BITS-1:0]		reg_bank;
	
	wire	[BANK_BITS-1:0]		params_bank;
	wire						params_update_start;
	
	// 非同期ラッチ
	(* ASYNC_REG="true" *)	reg		[BANK_BITS-1:0]	ff0_params_bank, ff1_params_bank;
	always @(posedge s_wb_clk_i ) begin
		if ( s_wb_rst_i ) begin
			ff0_params_bank <= INIT_BANK;
			ff1_params_bank <= INIT_BANK;
		end
		else begin
			ff0_params_bank   <= params_bank;
			ff1_params_bank   <= ff0_params_bank;
		end
	end
	
	always @(posedge s_wb_clk_i ) begin
		if ( s_wb_rst_i ) begin
			reg_enable <= INIT_ENABLE;
			reg_bank   <= INIT_BANK;
		end
		else begin
			if ( wb_regs_stb_i && s_wb_we_i ) begin
				case ( s_wb_adr_i[1:0] )
				REG_ADDR_ENABLE: reg_enable <= s_wb_dat_i;
				REG_ADDR_BANK:   reg_bank   <= s_wb_dat_i;
				endcase
			end
		end
	end
	
	assign wb_regs_dat_o = (s_wb_adr_i[1:0] == REG_ADDR_ENABLE) ? reg_enable      :
	                       (s_wb_adr_i[1:0] == REG_ADDR_ENABLE) ? reg_bank        :
	                       (s_wb_adr_i[1:0] == REG_ADDR_ENABLE) ? ff1_params_bank :
	                       0;
	assign wb_regs_ack_o = wb_regs_stb_i;
	
	
	// エッジ判定器用パラメータ
	wire	[WB_DAT_WIDTH-1:0]	wb_edge_dat_o;
	wire						wb_edge_stb_i;
	wire						wb_edge_ack_o;
	
	wire						edge_busy;
	
	jelly_params_ram
			#(
				.NUM			(EDGE_PARAM_NUM),
				.ADDR_WIDTH		(EDGE_ADDR_WIDTH),
				.DATA_WIDTH		(EDGE_WIDTH),
				.BANK_NUM		(BANK_NUM),
				.WRITE_ONLY		(1),
				.DOUT_REGS		(0),
				.RAM_TYPE		(EDGE_RAM_TYPE),
				.ENDIAN			(0)
			)
		i_params_ram_edge
			(
				.reset			(reset),
				.clk			(clk),
				
				.start			(params_update_start),
				.busy			(edge_busy),
				
				.bank			(params_bank),
				.params			(edge_params),
				
				.mem_clk		(s_wb_clk_i),
				.mem_en			(wb_edge_stb_i),
				.mem_regcke		(1'b0),
				.mem_we			(s_wb_we_i),
				.mem_bank		(s_wb_adr_i[BANK_ADDR_WIDTH +: BANK_BITS]),
				.mem_addr		(s_wb_adr_i[EDGE_ADDR_WIDTH-1:0]),
				.mem_din		(s_wb_dat_i),
				.mem_dout		()
			);
	
	assign wb_edge_dat_o = {WB_DAT_WIDTH{1'b0}};
	assign wb_edge_ack_o = wb_edge_stb_i;
	
	
	// ポリゴンラスタライズ用パラメータ
	wire	[WB_DAT_WIDTH-1:0]	wb_polygon_dat_o;
	wire						wb_polygon_stb_i;
	wire						wb_polygon_ack_o;
	
	wire						polygon_busy;
	
	jelly_params_ram
			#(
				.NUM			(POLYGON_PARAM_NUM),
				.ADDR_WIDTH		(POLYGON_ADDR_WIDTH),
				.DATA_WIDTH		(POLYGON_WIDTH),
				.BANK_NUM		(BANK_NUM),
				.WRITE_ONLY		(1),
				.DOUT_REGS		(0),
				.RAM_TYPE		(POLYGON_RAM_TYPE),
				.ENDIAN			(0)
			)
		i_params_ram_polygon
			(
				.reset			(reset),
				.clk			(clk),
				
				.start			(params_update_start),
				.busy			(polygon_busy),
				
				.bank			(params_bank),
				.params			(polygon_params),
				
				.mem_clk		(s_wb_clk_i),
				.mem_en			(wb_polygon_stb_i),
				.mem_regcke		(1'b0),
				.mem_we			(s_wb_we_i),
				.mem_bank		(s_wb_adr_i[BANK_ADDR_WIDTH +: BANK_BITS]),
				.mem_addr		(s_wb_adr_i[POLYGON_ADDR_WIDTH-1:0]),
				.mem_din		(s_wb_dat_i),
				.mem_dout		()
			);
	
	assign wb_polygon_dat_o = {WB_DAT_WIDTH{1'b0}};
	assign wb_polygon_ack_o = wb_polygon_stb_i;
	
	
	// ポリゴン領域対応エッジパラメータ
	wire	[WB_DAT_WIDTH-1:0]	wb_region_dat_o;
	wire						wb_region_stb_i;
	wire						wb_region_ack_o;
	
	wire						region_busy;
	
	jelly_params_ram
			#(
				.NUM			(REGION_PARAM_NUM),
				.ADDR_WIDTH		(REGION_ADDR_WIDTH),
				.DATA_WIDTH		(REGION_WIDTH),
				.WRITE_ONLY		(1),
				.DOUT_REGS		(0),
				.RAM_TYPE		(REGION_RAM_TYPE),
				.ENDIAN			(0)
			)
		i_params_ram_region
			(
				.reset			(reset),
				.clk			(clk),
				
				.start			(params_update_start),
				.busy			(region_busy),
				
				.bank			(params_bank),
				.params			(region_params),
				
				.mem_clk		(s_wb_clk_i),
				.mem_en			(wb_region_stb_i),
				.mem_regcke		(1'b0),
				.mem_we			(s_wb_we_i),
				.mem_bank		(s_wb_adr_i[BANK_ADDR_WIDTH +: BANK_BITS]),
				.mem_addr		(s_wb_adr_i[REGION_ADDR_WIDTH-1:0]),
				.mem_din		(s_wb_dat_i[REGION_WIDTH-1:0]),
				.mem_dout		()
			);
	
	assign wb_region_dat_o = {WB_DAT_WIDTH{1'b0}};
	assign wb_region_ack_o = wb_region_stb_i;
	
	
	// busy
	wire	params_busy = (EDGE_NUM    >= POLYGON_NUM && EDGE_NUM    >= REGION_NUM) ? edge_busy    :
	                      (POLYGON_NUM >= EDGE_NUM    && POLYGON_NUM >= REGION_NUM) ? polygon_busy :
	                      region_busy;
	
	
	
	// 非同期ラッチ
	(* ASYNC_REG="true" *)	reg						ff0_enable, ff1_enable;
	(* ASYNC_REG="true" *)	reg		[BANK_BITS-1:0]	ff0_bank,   ff1_bank;
	always @(posedge clk) begin
		if ( reset ) begin
			ff0_enable <= 1'b0;
			ff1_enable <= 1'b0;
			
			ff0_bank   <= INIT_BANK;
			ff1_bank   <= INIT_BANK;
		end
		else begin
			ff0_enable <= reg_enable;
			ff1_enable <= ff0_enable;
			
			ff0_bank   <= reg_bank;
			ff1_bank   <= ff0_bank;
		end
	end
	
	
	// ステートマシン
	localparam	ST_IDLE         = 4'b0000;
	localparam	ST_UPDATE_START = 4'b1001;
	localparam	ST_UPDATE_BUSY  = 4'b1100;
	localparam	ST_CORE_START   = 4'b1010;
	localparam	ST_CORE_BUSY    = 4'b1000;
	
	reg		[3:0]				reg_state;
	reg		[BANK_WIDTH-1:0]	reg_params_bank;
	
	assign params_update_start = reg_state[0];
	assign start               = reg_state[1];
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_state <= ST_IDLE;
		end
		else if ( cke ) begin
			case ( reg_state )
			ST_IDLE:
				begin
					if ( ff1_enable ) begin
						reg_state       <= ST_UPDATE_START;
						reg_params_bank <= ff1_bank;
					end
				end
				
			ST_UPDATE_START:
				begin
					reg_state <= ST_UPDATE_BUSY;
				end
				
			ST_UPDATE_BUSY:
				begin
					if ( !params_busy ) begin
						reg_state <= ST_CORE_START;
					end
				end
				
			ST_CORE_START:
				begin
					reg_state <= ST_CORE_BUSY;
				end
			
			ST_CORE_BUSY:
				begin
					if ( !busy ) begin
						reg_state <= ST_IDLE;
					end
				end
			
			default:
				begin
					reg_state <= 4'bxxxx;
				end
			endcase
		end
	end
	
	assign params_bank = reg_params_bank;
	
	
	
	// WISHBONE addr decode
	assign wb_regs_stb_i    = s_wb_stb_i && (s_wb_adr_i[PARAMS_ADDR_WIDTH +: 2] == 2'b00);
	assign wb_edge_stb_i    = s_wb_stb_i && (s_wb_adr_i[PARAMS_ADDR_WIDTH +: 2] == 2'b01);
	assign wb_polygon_stb_i = s_wb_stb_i && (s_wb_adr_i[PARAMS_ADDR_WIDTH +: 2] == 2'b10);
	assign wb_region_stb_i  = s_wb_stb_i && (s_wb_adr_i[PARAMS_ADDR_WIDTH +: 2] == 2'b11);
	
	assign s_wb_dat_o       = wb_regs_stb_i    ? wb_regs_dat_o    :
	                          wb_edge_stb_i    ? wb_edge_dat_o    :
	                          wb_polygon_stb_i ? wb_polygon_dat_o :
	                          wb_region_stb_i  ? wb_region_dat_o  :
	                          0;
	
	assign s_wb_ack_o       = wb_regs_stb_i    ? wb_regs_ack_o    :
	                          wb_edge_stb_i    ? wb_edge_ack_o    :
	                          wb_polygon_stb_i ? wb_polygon_ack_o :
	                          wb_region_stb_i  ? wb_region_ack_o  :
	                          s_wb_stb_i;
	
	
	
endmodule


`default_nettype wire


// End of file
