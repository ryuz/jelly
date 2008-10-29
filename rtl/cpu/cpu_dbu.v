// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


// register addresss map
`define DBG_ADR_STATUS			7'h00
`define DBG_ADR_INST_ADDR		7'h02
`define DBG_ADR_INST_DATA		7'h03
`define DBG_ADR_DATA_ADDR		7'h04
`define DBG_ADR_DATA_DATA		7'h05
`define DBG_ADR_PC				7'h08
`define DBG_ADR_R0				7'h10
`define DBG_ADR_R1				7'h11
`define DBG_ADR_R2				7'h12
`define DBG_ADR_R3				7'h13
`define DBG_ADR_R4				7'h14
`define DBG_ADR_R5				7'h15
`define DBG_ADR_R6				7'h16
`define DBG_ADR_R7				7'h17
`define DBG_ADR_R8				7'h18
`define DBG_ADR_R9				7'h19
`define DBG_ADR_R10				7'h1a
`define DBG_ADR_R11				7'h1b
`define DBG_ADR_R12				7'h1c
`define DBG_ADR_R13				7'h1d
`define DBG_ADR_R14				7'h1e
`define DBG_ADR_R15				7'h1f
`define DBG_ADR_R16				7'h20
`define DBG_ADR_R17				7'h21
`define DBG_ADR_R18				7'h22
`define DBG_ADR_R19				7'h23
`define DBG_ADR_R20				7'h24
`define DBG_ADR_R21				7'h25
`define DBG_ADR_R22				7'h26
`define DBG_ADR_R23				7'h27
`define DBG_ADR_R24				7'h28
`define DBG_ADR_R25				7'h29
`define DBG_ADR_R26				7'h2a
`define DBG_ADR_R27				7'h2b
`define DBG_ADR_R28				7'h2c
`define DBG_ADR_R29				7'h2d
`define DBG_ADR_R30				7'h2e
`define DBG_ADR_R31				7'h21f




// Debug Unit
module cpu_dbu
		(
			reset, clk, endian,
			wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	parameter	ADDR_WIDTH   = 7;
	parameter	DATA_SIZE    = 2;  	// 0:8bit, 1:16bit, 2:32bit ...
	
	localparam	SEL_WIDTH    = (1 << DATA_SIZE);
	localparam	DATA_WIDTH   = (8 << DATA_SIZE);
	
	// system
	input								reset;
	input								clk;
	input								endian;

	// Whishbone bus
	input	[ADDR_WIDTH-1:DATA_SIZE]	wb_adr_i;
	input	[DATA_WIDTH-1:0]			wb_dat_i;
	output	[DATA_WIDTH-1:0]			wb_dat_o;
	input								wb_we_i;
	input	[SEL_WIDTH-1:0]				wb_sel_i;
	input								wb_stb_i;
	output								wb_ack_o;

	
	// debug status
	output								enable;
	input								in_break;
	
	// i-bus control
	output	[31:2]						wb_inst_adr_o;
	input	[31:0]						wb_inst_dat_i;
	output								wb_inst_stb_o;
	
	// d-bus control
	output	[31:2]						wb_data_adr_o;
	input	[31:0]						wb_data_dat_i;
	output	[31:0]						wb_data_dat_o;
	output								wb_data_we_o;
	output	[3:0]						wb_data_sel_o;
	output								wb_data_stb_o;
	input								wb_data_ack_i;
	
	
	// PC control
	output								pc_we;
	output	[31:0]						pc_wdata;
	input	[31:0]						pc_rdata;
	
	// gpr control
	output								gpr_en;
	output								gpr_we;
	output	[4:0]						gpr_addr;
	output	[31:0]						gpr_wdata;
	input	[31:0]						gpr_rdata;
	
	// hi/lo control
	output								hilo_en;
	output								hilo_we;
	output	[0:0]						hilo_addr;
	output	[31:0]						hilo_wdata;
	input	[31:0]						hilo_rdata;
	
	// cop0 control
	output								cop0_en;
	output								cop0_we;
	output	[4:0]						cop0_addr;
	output	[31:0]						cop0_wdata;
	input	[31:0]						cop0_rdata;
	
	
	
	
	
	

	
	// adder
	wire	[DATA_WIDTH-1:0]	adder_in_data0;
	wire	[DATA_WIDTH-1:0]	adder_in_data1;
	wire						adder_in_carry;
	wire	[DATA_WIDTH-1:0]	adder_out_data;
	
	assign adder_in_data0 = in_data0;
	assign adder_in_data1 = (op_adder_func[0] ? ~in_data1 : in_data1) &
							(op_adder_func[1] ? {DATA_WIDTH{1'b0}} : {DATA_WIDTH{1'b1}});
	
	assign adder_in_carry = (op_adder_func == `ALU_ADDER_FUNC_SUB) ? 1'b1 : 1'b0;
	
	cpu_adder
		i_cpu_adder
			(
				.in_data0		(adder_in_data0),
				.in_data1		(adder_in_data1),
				.in_carry		(adder_in_carry),
			
				.out_data		(adder_out_data),
			
				.out_carry		(out_carry),
				.out_overflow	(out_overflow),
				.out_negative	(out_negative),
				.out_zero		(out_zero)
			);
	
	
	// logic
	wire	[DATA_WIDTH-1:0]	logic_out_data;
	assign logic_out_data = (op_logic_func == `ALU_LOGIC_FUNC_AND) ?  (in_data0 & in_data1) : {DATA_WIDTH{1'b0}}
							| (op_logic_func == `ALU_LOGIC_FUNC_OR)  ?  (in_data0 | in_data1) : {DATA_WIDTH{1'b0}}
							| (op_logic_func == `ALU_LOGIC_FUNC_XOR) ?  (in_data0 ^ in_data1) : {DATA_WIDTH{1'b0}}
							| (op_logic_func == `ALU_LOGIC_FUNC_NOR) ? ~(in_data0 | in_data1) : {DATA_WIDTH{1'b0}};
	
	// compare
	wire	[DATA_WIDTH-1:0]	comp_out_data;
	assign comp_out_data[0] = (op_comp_func == `ALU_COMP_FUNC_SLT) ? (out_negative != out_overflow) : ~out_carry;
	assign comp_out_data[DATA_WIDTH-1:1] = 0;
	
	// output
	assign out_data = op_adder_en ? adder_out_data : {DATA_WIDTH{1'b0}}
					| op_logic_en ? logic_out_data : {DATA_WIDTH{1'b0}}
					| op_comp_en  ? comp_out_data  : {DATA_WIDTH{1'b0}};
	
	
endmodule

