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
			parameter	X_WIDTH             = 12,
			parameter	Y_WIDTH             = 12,
			
			parameter	WB_ADR_WIDTH        = 14,
			parameter	WB_DAT_WIDTH        = 32,
			parameter	WB_SEL_WIDTH        = (WB_DAT_WIDTH / 8),
			
			parameter	BANK_NUM            = 2,
			parameter	BANK_ADDR_WIDTH     = 12,
			parameter	PARAMS_ADDR_WIDTH   = 10,
			
			parameter	EDGE_NUM            = 12,
			parameter	EDGE_WIDTH          = 32,
			parameter	EDGE_RAM_TYPE       = "distributed",
			
			parameter	POLYGON_NUM         = 6,
			parameter	POLYGON_PARAM_NUM   = 3,
			parameter	POLYGON_WIDTH       = 32,
			parameter	POLYGON_RAM_TYPE    = "distributed",
			
			parameter	REGION_NUM          = POLYGON_NUM,
			parameter	REGION_WIDTH        = EDGE_NUM,
			parameter	REGION_RAM_TYPE     = "distributed",
			
			parameter	INIT_CTL_ENABLE     = 1'b0,
			parameter	INIT_CTL_BANK       = 0,
			parameter	INIT_PARAM_WIDTH    = 640-1,
			parameter	INIT_PARAM_HEIGHT   = 480-1,
			
			// local
			parameter	PARAMS_EDGE_SIZE    = EDGE_NUM*3,
			parameter	PARAMS_POLYGON_SIZE = POLYGON_NUM*POLYGON_PARAM_NUM*3,
			parameter	PARAMS_REGION_SIZE  = REGION_NUM*2
		)
		(
			input	wire											reset,
			input	wire											clk,
			input	wire											cke,
			
			output	wire											start,
			input	wire											busy,
			
			output	wire	[X_WIDTH-1:0]							param_width,
			output	wire	[Y_WIDTH-1:0]							param_height,
			
			output	wire	[PARAMS_EDGE_SIZE*EDGE_WIDTH-1:0]		params_edge,
			output	wire	[PARAMS_POLYGON_SIZE*POLYGON_WIDTH-1:0]	params_polygon,
			output	wire	[PARAMS_REGION_SIZE*REGION_WIDTH-1:0]	params_region,
			
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
	localparam	BANK_WIDTH         = BANK_NUM            <=     1 ?  0 :
			                         BANK_NUM            <=     2 ?  1 :
			                         BANK_NUM            <=     4 ?  2 :
			                         BANK_NUM            <=     8 ?  3 :
			                         BANK_NUM            <=    16 ?  4 :
			                         BANK_NUM            <=    32 ?  5 :
			                         BANK_NUM            <=    64 ?  6 :
			                         BANK_NUM            <=   128 ?  7 :
			                         BANK_NUM            <=   256 ?  8 :
			                         BANK_NUM            <=   512 ?  9 :
			                         BANK_NUM            <=  1024 ? 10 :
			                         BANK_NUM            <=  2048 ? 11 :
			                         BANK_NUM            <=  4096 ? 12 :
			                         BANK_NUM            <=  8192 ? 13 :
			                         BANK_NUM            <= 16384 ? 14 :
			                         BANK_NUM            <= 32768 ? 15 : 16;
	
	localparam	BANK_BITS          = BANK_WIDTH > 0 ? BANK_WIDTH : 1;
	
	localparam	EDGE_ADDR_WIDTH    = PARAMS_EDGE_SIZE    <=     2 ?  1 :
			                         PARAMS_EDGE_SIZE    <=     4 ?  2 :
			                         PARAMS_EDGE_SIZE    <=     8 ?  3 :
			                         PARAMS_EDGE_SIZE    <=    16 ?  4 :
			                         PARAMS_EDGE_SIZE    <=    32 ?  5 :
			                         PARAMS_EDGE_SIZE    <=    64 ?  6 :
			                         PARAMS_EDGE_SIZE    <=   128 ?  7 :
			                         PARAMS_EDGE_SIZE    <=   256 ?  8 :
			                         PARAMS_EDGE_SIZE    <=   512 ?  9 :
			                         PARAMS_EDGE_SIZE    <=  1024 ? 10 :
			                         PARAMS_EDGE_SIZE    <=  2048 ? 11 :
			                         PARAMS_EDGE_SIZE    <=  4096 ? 12 :
			                         PARAMS_EDGE_SIZE    <=  8192 ? 13 :
			                         PARAMS_EDGE_SIZE    <= 16384 ? 14 :
			                         PARAMS_EDGE_SIZE    <= 32768 ? 15 : 16;
	
	localparam	POLYGON_ADDR_WIDTH = PARAMS_POLYGON_SIZE <=     2 ?  1 :
			                         PARAMS_POLYGON_SIZE <=     4 ?  2 :
			                         PARAMS_POLYGON_SIZE <=     8 ?  3 :
			                         PARAMS_POLYGON_SIZE <=    16 ?  4 :
			                         PARAMS_POLYGON_SIZE <=    32 ?  5 :
			                         PARAMS_POLYGON_SIZE <=    64 ?  6 :
			                         PARAMS_POLYGON_SIZE <=   128 ?  7 :
			                         PARAMS_POLYGON_SIZE <=   256 ?  8 :
			                         PARAMS_POLYGON_SIZE <=   512 ?  9 :
			                         PARAMS_POLYGON_SIZE <=  1024 ? 10 :
			                         PARAMS_POLYGON_SIZE <=  2048 ? 11 :
			                         PARAMS_POLYGON_SIZE <=  4096 ? 12 :
			                         PARAMS_POLYGON_SIZE <=  8192 ? 13 :
			                         PARAMS_POLYGON_SIZE <= 16384 ? 14 :
			                         PARAMS_POLYGON_SIZE <= 32768 ? 15 : 16;
	
	localparam	REGION_ADDR_WIDTH  = PARAMS_REGION_SIZE  <=     2 ?  1 :
			                         PARAMS_REGION_SIZE  <=     4 ?  2 :
			                         PARAMS_REGION_SIZE  <=     8 ?  3 :
			                         PARAMS_REGION_SIZE  <=    16 ?  4 :
			                         PARAMS_REGION_SIZE  <=    32 ?  5 :
			                         PARAMS_REGION_SIZE  <=    64 ?  6 :
			                         PARAMS_REGION_SIZE  <=   128 ?  7 :
			                         PARAMS_REGION_SIZE  <=   256 ?  8 :
			                         PARAMS_REGION_SIZE  <=   512 ?  9 :
			                         PARAMS_REGION_SIZE  <=  1024 ? 10 :
			                         PARAMS_REGION_SIZE  <=  2048 ? 11 :
			                         PARAMS_REGION_SIZE  <=  4096 ? 12 :
			                         PARAMS_REGION_SIZE  <=  8192 ? 13 :
			                         PARAMS_REGION_SIZE  <= 16384 ? 14 :
			                         PARAMS_REGION_SIZE  <= 32768 ? 15 : 16;
	
	
	
	// 制御レジスタ
	localparam	REG_ADDR_CTL_ENABLE   = 32'h00;
	localparam	REG_ADDR_CTL_BANK     = 32'h01;
	localparam	REG_ADDR_PARAM_WIDTH  = 32'h02;
	localparam	REG_ADDR_PARAM_HEIGHT = 32'h03;
	localparam	REG_ADDR_PARAMS_BANK  = 32'h04;
	
	
	wire	[WB_DAT_WIDTH-1:0]	wb_regs_dat_o;
	wire						wb_regs_stb_i;
	wire						wb_regs_ack_o;
	
	reg							reg_ctl_enable;
	reg		[BANK_BITS-1:0]		reg_ctl_bank;
	reg		[X_WIDTH-1:0]		reg_param_width;
	reg		[Y_WIDTH-1:0]		reg_param_height;
	
	wire	[BANK_BITS-1:0]		params_bank;
	wire						params_start;
	
	// 非同期ラッチ(ソフトウェアはバンクの切り替わりを見てハンドシェークする)
	(* ASYNC_REG="true" *)	reg		[BANK_BITS-1:0]	ff0_params_bank, ff1_params_bank;
	always @(posedge s_wb_clk_i ) begin
		if ( s_wb_rst_i ) begin
			ff0_params_bank <= INIT_CTL_BANK;
			ff1_params_bank <= INIT_CTL_BANK;
		end
		else begin
			ff0_params_bank   <= params_bank;
			ff1_params_bank   <= ff0_params_bank;
		end
	end
	
	always @(posedge s_wb_clk_i ) begin
		if ( s_wb_rst_i ) begin
			reg_ctl_enable   <= INIT_CTL_ENABLE;
			reg_ctl_bank     <= INIT_CTL_BANK;
			reg_param_width  <= INIT_PARAM_WIDTH;
			reg_param_height <= INIT_PARAM_HEIGHT;
		end
		else begin
			if ( wb_regs_stb_i && s_wb_we_i ) begin
				case ( s_wb_adr_i[2:0] )
				REG_ADDR_CTL_ENABLE:	reg_ctl_enable   <= s_wb_dat_i;
				REG_ADDR_CTL_BANK:		reg_ctl_bank     <= s_wb_dat_i;
				REG_ADDR_PARAM_WIDTH:	reg_param_width  <= s_wb_dat_i;
				REG_ADDR_PARAM_HEIGHT:	reg_param_height <= s_wb_dat_i;
				endcase
			end
		end
	end
	
	assign wb_regs_dat_o = (s_wb_adr_i[2:0] == REG_ADDR_CTL_ENABLE)   ? reg_ctl_enable       :
	                       (s_wb_adr_i[2:0] == REG_ADDR_CTL_ENABLE)   ? reg_ctl_bank         :
				           (s_wb_adr_i[2:0] == REG_ADDR_PARAM_WIDTH)  ? reg_param_width  :
				           (s_wb_adr_i[2:0] == REG_ADDR_PARAM_HEIGHT) ? reg_param_height :
	                       (s_wb_adr_i[2:0] == REG_ADDR_PARAMS_BANK)  ? ff1_params_bank  :
	                       0;
	assign wb_regs_ack_o = wb_regs_stb_i;
	
	assign param_width  = reg_param_width;
	assign param_height = reg_param_height;
	
	
	
	// エッジ判定器用パラメータ
	wire	[WB_DAT_WIDTH-1:0]	wb_edge_dat_o;
	wire						wb_edge_stb_i;
	wire						wb_edge_ack_o;
	
	wire						edge_busy;
	
	jelly_params_ram
			#(
				.NUM			(PARAMS_EDGE_SIZE),
				.ADDR_WIDTH		(EDGE_ADDR_WIDTH),
				.DATA_WIDTH		(EDGE_WIDTH),
				.BANK_NUM		(BANK_NUM),
				.WRITE_ONLY		(1),
				.MEM_DOUT_REGS	(0),
				.RD_DOUT_REGS	(1),
				.RAM_TYPE		(EDGE_RAM_TYPE),
				.ENDIAN			(0)
			)
		i_params_ram_edge
			(
				.reset			(reset),
				.clk			(clk),
				
				.start			(params_start),
				.busy			(edge_busy),
				
				.bank			(params_bank),
				.params			(params_edge),
				
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
				.NUM			(PARAMS_POLYGON_SIZE),
				.ADDR_WIDTH		(POLYGON_ADDR_WIDTH),
				.DATA_WIDTH		(POLYGON_WIDTH),
				.BANK_NUM		(BANK_NUM),
				.WRITE_ONLY		(1),
				.MEM_DOUT_REGS	(0),
				.RD_DOUT_REGS	(1),
				.RAM_TYPE		(POLYGON_RAM_TYPE),
				.ENDIAN			(0)
			)
		i_params_ram_polygon
			(
				.reset			(reset),
				.clk			(clk),
				
				.start			(params_start),
				.busy			(polygon_busy),
				
				.bank			(params_bank),
				.params			(params_polygon),
				
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
				.NUM			(PARAMS_REGION_SIZE),
				.ADDR_WIDTH		(REGION_ADDR_WIDTH),
				.DATA_WIDTH		(REGION_WIDTH),
				.WRITE_ONLY		(1),
				.MEM_DOUT_REGS	(0),
				.RD_DOUT_REGS	(1),
				.RAM_TYPE		(REGION_RAM_TYPE),
				.ENDIAN			(0)
			)
		i_params_ram_region
			(
				.reset			(reset),
				.clk			(clk),
				
				.start			(params_start),
				.busy			(region_busy),
				
				.bank			(params_bank),
				.params			(params_region),
				
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
	
	
	// busy (一番遅いものを基準にする)
	wire	params_busy = (PARAMS_EDGE_SIZE    >= PARAMS_POLYGON_SIZE && PARAMS_EDGE_SIZE    >= PARAMS_REGION_SIZE) ? edge_busy    :
	                      (PARAMS_POLYGON_SIZE >= PARAMS_EDGE_SIZE    && PARAMS_POLYGON_SIZE >= PARAMS_REGION_SIZE) ? polygon_busy :
	                      region_busy;
	
	
	
	// 非同期ラッチ
	(* ASYNC_REG="true" *)	reg						ff0_ctl_enable, ff1_ctl_enable;
	(* ASYNC_REG="true" *)	reg		[BANK_BITS-1:0]	ff0_ctl_bank,   ff1_ctl_bank;
	always @(posedge clk) begin
		if ( reset ) begin
			ff0_ctl_enable <= 1'b0;
			ff1_ctl_enable <= 1'b0;
			
			ff0_ctl_bank   <= INIT_CTL_BANK;
			ff1_ctl_bank   <= INIT_CTL_BANK;
		end
		else begin
			ff0_ctl_enable <= reg_ctl_enable;
			ff1_ctl_enable <= ff0_ctl_enable;
			
			ff0_ctl_bank   <= reg_ctl_bank;
			ff1_ctl_bank   <= ff0_ctl_bank;
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
	
	assign params_start = reg_state[0];
	assign start        = reg_state[1];
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_state       <= ST_IDLE;
			reg_params_bank <= INIT_CTL_BANK;
		end
		else if ( cke ) begin
			case ( reg_state )
			ST_IDLE:
				begin
					if ( ff1_ctl_enable ) begin
						reg_state       <= ST_UPDATE_START;
						reg_params_bank <= ff1_ctl_bank;
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
