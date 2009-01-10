// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// debug register addresss map
`define DBG_ADR_DBG_CTL			4'h0
`define DBG_ADR_DBG_ADDR		4'h2
`define DBG_ADR_REG_DATA		4'h4
`define DBG_ADR_DBUS_DATA		4'h6
`define DBG_ADR_IBUS_DATA		4'h7

// register address
`define REG_ADR_HI				8'h10
`define REG_ADR_LO				8'h11
`define REG_ADR_R0				8'h20
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
`define REG_ADR_COP0_DEBUG		8'h57
`define REG_ADR_COP0_DEEPC		8'h58


// Debug Unit
module cpu_dbu
		#(
			parameter					USE_IBUS_HOOK = 1'b0,
			parameter					USE_DBUS_HOOK = 1'b1,
			parameter					IBUS_HOOK_FF  = 1'b0,
			parameter					DBUS_HOOK_FF  = 1'b1
		)
		(
			// system
			input	wire				reset,
			input	wire				clk,
			input	wire				endian,

			// wishbone bus
			input	wire	[3:0]		wb_adr_i,
			input	wire	[31:0]		wb_dat_i,
			output	reg		[31:0]		wb_dat_o,
			input	wire				wb_we_i,
			input	wire	[3:0]		wb_sel_i,
			input	wire				wb_stb_i,
			output	reg					wb_ack_o,

			
			// debug status
			output	reg					dbg_enable,
			output	reg					dbg_break_req,
			input	wire				dbg_break,
			
			
			// d-bus control
			output	wire	[31:2]		wb_data_adr_o,
			input	wire	[31:0]		wb_data_dat_i,
			output	wire	[31:0]		wb_data_dat_o,
			output	wire				wb_data_we_o,
			output	wire	[3:0]		wb_data_sel_o,
			output	wire				wb_data_stb_o,
			input	wire				wb_data_ack_i,
			
			// i-bus control
			output	wire	[31:2]		wb_inst_adr_o,
			input	wire	[31:0]		wb_inst_dat_i,
			output	wire	[3:0]		wb_inst_sel_o,
			output	wire				wb_inst_stb_o,
			input	wire				wb_inst_ack_i,
			
			// gpr control
			output	reg					gpr_en,
			output	wire				gpr_we,
			output	wire	[4:0]		gpr_addr,
			output	wire	[31:0]		gpr_wdata,
			input	wire	[31:0]		gpr_rdata,
			
			// hi/lo control
			output	reg					hilo_en,
			output	wire				hilo_we,
			output	wire	[0:0]		hilo_addr,
			output	wire	[31:0]		hilo_wdata,
			input	wire	[31:0]		hilo_rdata,
			
			// cop0 control
			output	reg					cop0_en,
			output	wire				cop0_we,
			output	wire	[4:0]		cop0_addr,
			output	wire	[31:0]		cop0_wdata,
			input	wire	[31:0]		cop0_rdata
		);
	
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
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			dbg_enable    <= 1'b0;
			dbg_break_req <= 1'b0;
		end
		else begin
			// dbg_enable
			if ( dbg_break ) begin
				dbg_enable <= 1'b1;
			end
			else begin
				if ( wb_stb_i & wb_we_i & wb_sel_i[0] & (wb_adr_i == `DBG_ADR_DBG_CTL) ) begin
					if ( wb_sel_i[0] ) dbg_enable <= dbg_enable & wb_dat_i[0];
				end
			end

			// dbg_break_req
			if ( wb_stb_i & wb_we_i & wb_sel_i[0] & (wb_adr_i == `DBG_ADR_DBG_CTL) ) begin
				dbg_break_req <= wb_dat_i[1];
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
	assign reg_addr  = dbg_addr[9:2];
	assign reg_wdata = wb_dat_i;


	// d-bus control
	wire	[31:2]		dbus_wb_adr_o;
	wire	[31:0]		dbus_wb_dat_i;
	wire	[31:0]		dbus_wb_dat_o;
	wire				dbus_wb_we_o;
	wire	[3:0]		dbus_wb_sel_o;
	wire				dbus_wb_stb_o;
	wire				dbus_wb_ack_i;
	
	// i-bus control
	wire	[31:2]		ibus_wb_adr_o;
	wire	[31:0]		ibus_wb_dat_i;
	wire	[3:0]		ibus_wb_sel_o;
	wire				ibus_wb_stb_o;
	wire				ibus_wb_ack_i;


	// d-bus control
	assign dbus_wb_adr_o = dbg_addr[31:2];
	assign dbus_wb_dat_o = wb_dat_i;
	assign dbus_wb_we_o  = wb_we_i;
	assign dbus_wb_sel_o = wb_sel_i;
	assign dbus_wb_stb_o = wb_stb_i & (wb_adr_i == `DBG_ADR_DBUS_DATA);

	// i-bus control
	assign ibus_wb_adr_o = dbg_addr[31:2];
	assign ibus_wb_sel_o = wb_sel_i;
	assign ibus_wb_stb_o = wb_stb_i & (wb_adr_i == `DBG_ADR_IBUS_DATA);
	
	
	// read
	always @* begin
		casex ( wb_adr_i )
		`DBG_ADR_DBG_CTL:	// DBG_CTL
			begin
				wb_dat_o = {{30{1'b0}}, dbg_break_req, dbg_enable};
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
				wb_dat_o = dbus_wb_dat_i;
				wb_ack_o = dbus_wb_ack_i;
			end
		
		`DBG_ADR_IBUS_DATA:	// IBUS_DATA
			begin
				wb_dat_o = ibus_wb_dat_i;
				wb_ack_o = ibus_wb_ack_i;
			end
				
		default:
			begin
				wb_dat_o = {32{1'b0}};
				wb_ack_o = 1'b1;
			end
		endcase
	end



	// d-bus control
	generate
	if ( USE_DBUS_HOOK ) begin
		if ( DBUS_HOOK_FF ) begin
			// insert flip-flop
			wishbone_bridge
					#(
						.WB_ADR_WIDTH	(30),
						.WB_DAT_WIDTH	(32)
					)
				i_wishbone_bridge_dbus
					(
						.reset			(reset),
						.clk			(clk),
						
						.wb_in_adr_i	(dbus_wb_adr_o),
						.wb_in_dat_o	(dbus_wb_dat_i),
						.wb_in_dat_i	(dbus_wb_dat_o),
						.wb_in_we_i		(dbus_wb_we_o),
						.wb_in_sel_i	(dbus_wb_sel_o),
						.wb_in_stb_i	(dbus_wb_stb_o),
						.wb_in_ack_o	(dbus_wb_ack_i),
						
						.wb_out_adr_o	(wb_data_adr_o),
						.wb_out_dat_i	(wb_data_dat_i),
						.wb_out_dat_o	(wb_data_dat_o),
						.wb_out_we_o	(wb_data_we_o),
						.wb_out_sel_o	(wb_data_sel_o),
						.wb_out_stb_o	(wb_data_stb_o),
						.wb_out_ack_i	(wb_data_ack_i)
					);
		end
		else begin
			assign wb_data_adr_o = dbus_wb_adr_o;
			assign wb_data_dat_o = dbus_wb_dat_o;
			assign wb_data_we_o  = dbus_wb_we_o;
			assign wb_data_sel_o = dbus_wb_sel_o;
			assign wb_data_stb_o = dbus_wb_stb_o;
			assign dbus_wb_dat_i = wb_data_dat_i;
			assign dbus_wb_ack_i = wb_data_ack_i;
		end
	end
	else begin
		// no use
		assign wb_data_adr_o = 0;
		assign wb_data_dat_o = 0;
		assign wb_data_we_o  = 1'b0;
		assign wb_data_sel_o = 0;
		assign wb_data_stb_o = 1'b0;	
		assign dbus_wb_dat_i = 0;
		assign dbus_wb_ack_i = 1'b1;
	end
	
	// i-bus control
	if ( USE_IBUS_HOOK ) begin
		assign wb_inst_adr_o = ibus_wb_adr_o;
		assign wb_inst_sel_o = ibus_wb_sel_o;
		assign wb_inst_stb_o = ibus_wb_stb_o;
		assign ibus_wb_dat_i = wb_inst_dat_i;
		assign ibus_wb_ack_i = wb_inst_ack_i;
	end
	else begin
		assign wb_inst_adr_o = 0;
		assign wb_inst_sel_o = 0;
		assign wb_inst_stb_o = 1'b0;
		assign ibus_wb_dat_i = 0;
		assign ibus_wb_ack_i = 1'b1;
	end
	endgenerate

	
	
	// -----------------------------
	//  Register access
	// -----------------------------
	
	// hi/lo control
	assign hilo_we    = reg_we;
	assign hilo_addr  = reg_addr[0];
	assign hilo_wdata = reg_wdata;
	
	// gpr control
	assign gpr_we     = reg_we;
	assign gpr_addr   = reg_addr[4:0];
	assign gpr_wdata  = reg_wdata;
		
	// cop0 control
	assign cop0_we    = reg_we;
	assign cop0_addr  = reg_addr[4:0];
	assign cop0_wdata = reg_wdata;
	
	// address decode
	always @* begin
		hilo_en = 1'b0;
		gpr_en  = 1'b0;
		cop0_en = 1'b0;
		casex ( reg_addr[7:0] )		
		8'b0001_000x:			// HI, LO
			begin
				hilo_en   = reg_en;
				reg_rdata = hilo_rdata;
			end

		8'b001x_xxxx:			// GPR
			begin
				gpr_en    = reg_en;
				reg_rdata = gpr_rdata;
			end

		8'b010x_xxxx:			// COP0
			begin
				cop0_en   = reg_en;
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

