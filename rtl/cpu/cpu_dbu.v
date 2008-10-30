// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


// debug register addresss map
`define DBG_ADR_DBG_CTL			4'h0
`define DBG_ADR_DBG_ADDR		4'h2
`define DBG_ADR_REG_DATA		4'h4
`define DBG_ADR_DBUS_DATA		4'h6
`define DBG_ADR_IBUS_DATA		4'h7

// register address
`define REG_ADR_PC				8'b00
`define REG_ADR_HI				8'h10
`define REG_ADR_LO				8'h11
`define REG_ADR_GPR				8'h20
`define REG_ADR_R1				8'h21
`define REG_ADR_R2				8'h22
`define REG_ADR_R3				8'h23
`define REG_ADR_R4				8'h24
`define REG_ADR_R5				8'h25
`define REG_ADR_R6				8'h26
`define REG_ADR_R7				8'h27
`define REG_ADR_R8				8'h28
`define REG_ADR_R9				8'h29
`define REG_ADR_R10				8'h2a
`define REG_ADR_R11				8'h2b
`define REG_ADR_R12				8'h2c
`define REG_ADR_R13				8'h2d
`define REG_ADR_R14				8'h2e
`define REG_ADR_R15				8'h2f
`define REG_ADR_R16				8'h30
`define REG_ADR_R17				8'h31
`define REG_ADR_R18				8'h32
`define REG_ADR_R19				8'h33
`define REG_ADR_R20				8'h34
`define REG_ADR_R21				8'h35
`define REG_ADR_R22				8'h36
`define REG_ADR_R23				8'h37
`define REG_ADR_R24				8'h38
`define REG_ADR_R25				8'h39
`define REG_ADR_R26				8'h3a
`define REG_ADR_R27				8'h3b
`define REG_ADR_R28				8'h3c
`define REG_ADR_R29				8'h3d
`define REG_ADR_R30				8'h3e
`define REG_ADR_R31				8'h3f
`define REG_ADR_COP0_STATUS		8'h4c
`define REG_ADR_COP0_CAUSE		8'h4d
`define REG_ADR_COP0_EPC		8'h4e



// Debug Unit
module cpu_dbu
		(
			reset, clk, endian,
			wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o,
			dbg_enable, in_break,
			wb_data_adr_o, wb_data_dat_i, wb_data_dat_o, wb_data_we_o, wb_data_sel_o, wb_data_stb_o, wb_data_ack_i,
			wb_inst_adr_o, wb_inst_dat_i, wb_inst_sel_o, wb_inst_stb_o, wb_inst_ack_i,
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
	input	[3:0]		wb_adr_i;
	input	[31:0]		wb_dat_i;
	output	[31:0]		wb_dat_o;
	input				wb_we_i;
	input	[3:0]		wb_sel_i;
	input				wb_stb_i;
	output				wb_ack_o;

	
	// debug status
	output				dbg_enable;
	input				in_break;
	
	
	// d-bus control
	output	[31:2]		wb_data_adr_o;
	input	[31:0]		wb_data_dat_i;
	output	[31:0]		wb_data_dat_o;
	output				wb_data_we_o;
	output	[3:0]		wb_data_sel_o;
	output				wb_data_stb_o;
	input				wb_data_ack_i;

	// i-bus control
	output	[31:2]		wb_inst_adr_o;
	input	[31:0]		wb_inst_dat_i;
	output	[3:0]		wb_inst_sel_o;
	output				wb_inst_stb_o;
	input				wb_inst_ack_i;
	
	
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
	
	
	// register control
	wire				reg_en;
	wire				reg_we;
	wire	[7:0]		reg_addr;
	wire	[31:0]		reg_wdata;
	reg		[31:0]		reg_rdata;
	reg					reg_ack;
	
	
	// -----------------------------
	//  Debug control
	// -----------------------------
	
	// dbgctl
	reg					dbg_enable;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			dbg_enable <= 1'b0;
		end
		else begin
			if ( in_break ) begin
				dbg_enable <= 1'b1;
			end
			else begin
				if ( wb_stb_i & wb_we_i & (wb_adr_i == `DBG_ADR_DBG_CTL) ) begin
					if ( wb_sel_i[0] ) dbg_enable <= wb_dat_i[0];
				end
			end
		end
	end
	
	
	// dbg_addr
	reg		[31:0]		dbg_addr;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			dbg_addr <= {32{1'b0}};
		end
		else begin
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `DBG_ADR_DBG_ADDR) ) begin
				if ( wb_sel_i[0] ) dbg_addr[7:2]   <= wb_dat_i[7:2];
				if ( wb_sel_i[1] ) dbg_addr[15:8]  <= wb_dat_i[15:8];
				if ( wb_sel_i[2] ) dbg_addr[23:16] <= wb_dat_i[23:16];
				if ( wb_sel_i[3] ) dbg_addr[31:24] <= wb_dat_i[31:24];
			end
		end
	end

	// register control
	assign reg_en    = wb_stb_i & (wb_adr_i == `DBG_ADR_REG_DATA);
	assign reg_we    = wb_we_i;
	assign reg_addr  = dbg_addr;
	assign reg_wdata = wb_dat_i;
	
	// d-bus control
	assign wb_data_adr_o = dbg_addr[31:2];
	assign wb_data_dat_o = wb_dat_i;
	assign wb_data_we_o  = wb_we_i;
	assign wb_data_sel_o = wb_sel_i;
	assign wb_data_stb_o = wb_stb_i & (wb_adr_i == `DBG_ADR_DBUS_DATA);

	// i-bus control
	assign wb_inst_adr_o = dbg_addr[31:2];
	assign wb_inst_sel_o = wb_sel_i;
	assign wb_inst_stb_o = wb_stb_i & (wb_adr_i == `DBG_ADR_IBUS_DATA);
	
	
	// read
	reg		[31:0]		wb_dat_o;
	reg					wb_ack_o;
	always @* begin
		casex ( wb_adr_i )
		`DBG_ADR_DBG_CTL:	// DBG_CTL
			begin
				wb_dat_o = {{31{1'b0}}, dbg_enable};
				wb_ack_o = 1'b1;
			end

		`DBG_ADR_DBG_ADDR:	// DBG_ADDR
			begin
				wb_dat_o = dbg_addr;
				wb_ack_o = 1'b1;
			end

		`DBG_ADR_REG_DATA:	// REG_DATA
			begin
				wb_dat_o = reg_rdata;
				wb_ack_o = reg_ack;
			end
		
		`DBG_ADR_DBUS_DATA:	// DBUS_DATA
			begin
				wb_dat_o = wb_data_dat_i;
				wb_ack_o = wb_data_ack_i;
			end
		
		`DBG_ADR_IBUS_DATA:	// IBUS_DATA
			begin
				wb_dat_o = wb_inst_dat_i;
				wb_ack_o = wb_inst_ack_i;
			end
				
		default:
			begin
				wb_dat_o = {32{1'b0}};
				wb_ack_o = 1'b1;
			end
		endcase
	end



	// -----------------------------
	//  Register access
	// -----------------------------
	
	// PC control
	assign pc_we      = reg_en & reg_we & (reg_addr == `REG_ADR_PC);
	assign pc_wdata   = reg_wdata;
	
	// hi/lo control
	assign hilo_en    = reg_en & (reg_addr[7:1] == 7'b0001_000);
	assign hilo_we    = reg_we;
	assign hilo_addr  = reg_addr[0];
	assign hilo_wdata = reg_wdata;
	
	// gpr control
	assign gpr_en     = reg_en & (reg_addr[7:5] == 3'b001);
	assign gpr_we     = reg_we;
	assign gpr_addr   = reg_addr[4:0];
	assign gpr_wdata  = reg_wdata;
		
	// cop0 control
	assign cop0_en    = reg_en & (reg_addr[7:5] == 3'b010);
	assign cop0_we    = reg_we;
	assign cop0_addr  = reg_addr[4:0];
	assign cop0_wdata = reg_wdata;
	
	// reg_rdata
	always @* begin
		casex ( reg_addr )		
		`REG_ADR_PC:			// PC
			begin
				reg_rdata = pc_rdata;
			end
		
		8'b0001_000x:			// HI, LO
			begin
				reg_rdata = hilo_rdata;
			end

		8'b001x_xxxx:			// GPR
			begin
				reg_rdata = gpr_rdata;
			end

		8'b010x_xxxx:			// COP0
			begin
				reg_rdata = cop0_rdata;
			end

		default:
			begin
				reg_rdata = {32{1'b0}};
			end
		endcase
	end
	
	// reg_ack (1 cycle wait)
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_ack <= 1'b0;
		end
		else begin
			reg_ack <= ~reg_ack & reg_en;
		end
	end
	
endmodule

