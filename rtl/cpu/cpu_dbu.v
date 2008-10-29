// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


// register addresss map
`define DBG_ADR_DBGCTL			7'h00
`define DBG_ADR_BUS_ADDR		7'h04
`define DBG_ADR_DBUS_DATA		7'h05
`define DBG_ADR_IBUS_DATA		7'h06
`define DBG_ADR_PC				7'h10
`define DBG_ADR_R0				7'h20
`define DBG_ADR_R1				7'h21
`define DBG_ADR_R2				7'h22
`define DBG_ADR_R3				7'h23
`define DBG_ADR_R4				7'h24
`define DBG_ADR_R5				7'h25
`define DBG_ADR_R6				7'h26
`define DBG_ADR_R7				7'h27
`define DBG_ADR_R8				7'h28
`define DBG_ADR_R9				7'h29
`define DBG_ADR_R10				7'h2a
`define DBG_ADR_R11				7'h2b
`define DBG_ADR_R12				7'h2c
`define DBG_ADR_R13				7'h2d
`define DBG_ADR_R14				7'h2e
`define DBG_ADR_R15				7'h2f
`define DBG_ADR_R16				7'h30
`define DBG_ADR_R17				7'h31
`define DBG_ADR_R18				7'h32
`define DBG_ADR_R19				7'h33
`define DBG_ADR_R20				7'h34
`define DBG_ADR_R21				7'h35
`define DBG_ADR_R22				7'h36
`define DBG_ADR_R23				7'h37
`define DBG_ADR_R24				7'h38
`define DBG_ADR_R25				7'h39
`define DBG_ADR_R26				7'h3a
`define DBG_ADR_R27				7'h3b
`define DBG_ADR_R28				7'h3c
`define DBG_ADR_R29				7'h3d
`define DBG_ADR_R30				7'h3e
`define DBG_ADR_R31				7'h3f
`define DBG_ADR_HI				7'h40
`define DBG_ADR_LO				7'h41
`define DBG_ADR_COP0_STATUS		7'h6c
`define DBG_ADR_COP0_CAUSE		7'h6d
`define DBG_ADR_COP0_EPC		7'h6e



// Debug Unit
module cpu_dbu
		(
			reset, clk, endian,
			wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o,
			enable, in_break,
			wb_inst_adr_o, wb_inst_dat_i, wb_inst_stb_o,
			wb_data_adr_o, wb_data_dat_i, wb_data_dat_o, wb_data_we_o, wb_data_sel_o, wb_data_stb_o, wb_data_ack_i,
			pc_we, pc_wdata, pc_rdata,
			gpr_en, gpr_we, gpr_addr, gpr_wdata, gpr_rdata,
			hilo_en, hilo_we, hilo_addr, hilo_wdata, hilo_rdata,
			cop0_en, cop0_we, cop0_addr, cop0_wdata, cop0_rdata
		);
	
	// system
	input				reset;
	input				clk;
	input				endian;

	// Whishbone bus
	input	[7:0]		wb_adr_i;
	input	[31:0]		wb_dat_i;
	output	[31:0]		wb_dat_o;
	input				wb_we_i;
	input	[3:0]		wb_sel_i;
	input				wb_stb_i;
	output				wb_ack_o;

	
	// debug status
	output				enable;
	input				in_break;
	
	// i-bus control
	output	[31:2]		wb_inst_adr_o;
	input	[31:0]		wb_inst_dat_i;
	output				wb_inst_stb_o;
	
	// d-bus control
	output	[31:2]		wb_data_adr_o;
	input	[31:0]		wb_data_dat_i;
	output	[31:0]		wb_data_dat_o;
	output				wb_data_we_o;
	output	[3:0]		wb_data_sel_o;
	output				wb_data_stb_o;
	input				wb_data_ack_i;
	
	
	// PC control
	output				pc_we;
	output	[31:0]		pc_wdata;
	input	[31:0]		pc_rdata;
	
	// gpr control
	output				gpr_en;
	output				gpr_we;
	output	[4:0]		gpr_addr;
	output	[31:0]		gpr_wdata;
	input	[31:0]		gpr_rdata;
	
	// hi/lo control
	output				hilo_en;
	output				hilo_we;
	output	[0:0]		hilo_addr;
	output	[31:0]		hilo_wdata;
	input	[31:0]		hilo_rdata;
	
	// cop0 control
	output				cop0_en;
	output				cop0_we;
	output	[4:0]		cop0_addr;
	output	[31:0]		cop0_wdata;
	input	[31:0]		cop0_rdata;
	
	
	
	// dbgctl
	reg					reg_enable;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_enable <= 1'b0;
		end
		else begin
			if ( in_break ) begin
				reg_enable <= 1'b1;
			end
			else begin
				if ( wb_stb_i & wb_we_i & (wb_adr_i == `DBG_ADR_DBGCTL) ) begin
					if ( wb_sel_i[0] ) reg_enable <= wb_dat_i[0];
				end
			end
		end
	end
	
	assign enable = reg_enable;
	
	
	// bus_addr
	reg		[31:0]		reg_bus_addr;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_bus_addr <= {32{1'b0}};
		end
		else begin
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `DBG_ADR_BUS_ADDR) ) begin
				if ( wb_sel_i[0] ) reg_bus_addr[7:2]   <= wb_dat_i[7:2];
				if ( wb_sel_i[1] ) reg_bus_addr[15:8]  <= wb_dat_i[15:8];
				if ( wb_sel_i[2] ) reg_bus_addr[23:16] <= wb_dat_i[23:16];
				if ( wb_sel_i[3] ) reg_bus_addr[31:24] <= wb_dat_i[31:24];
			end
		end
	end
	
	
	
endmodule

