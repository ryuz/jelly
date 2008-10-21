// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


// opcode
`define OP_SPECIAL		6'b000000
`define OP_ADDI			6'b001000
`define OP_ADDIU		6'b001001
`define OP_SLTI			6'b001010
`define OP_SLTIU		6'b001011
`define OP_BEQ			6'b000100
`define OP_REGIMM		6'b000001
`define OP_BGTZ			6'b000111
`define OP_BLEZ			6'b000110
`define OP_BNE			6'b000101
`define OP_J			6'b000010
`define OP_JAL			6'b000011
`define OP_LB			6'b100000
`define OP_LBU			6'b100100
`define OP_LH			6'b100001
`define OP_LHU			6'b100101
`define OP_LW			6'b100011
`define OP_LWL			6'b100010
`define OP_LWR			6'b100110
`define OP_SB			6'b101000
`define OP_SH			6'b101001
`define OP_SW			6'b101011
`define OP_SWL			6'b101010
`define OP_SWR			6'b101110
`define OP_ANDI			6'b001100
`define OP_LUI			6'b001111
`define OP_ORI			6'b001101
`define OP_XORI			6'b001110
`define OP_COP0			6'b010000

// func
`define FUNC_ADD		6'b100000
`define FUNC_ADDU		6'b100001
`define FUNC_DIV		6'b011010
`define FUNC_DIVU		6'b011011
`define FUNC_MULT		6'b011000
`define FUNC_MULTU		6'b011001
`define FUNC_SLT		6'b101010
`define FUNC_SLTU		6'b101011
`define FUNC_SUB		6'b100010
`define FUNC_SUBU		6'b100011
`define FUNC_JALR		6'b001001
`define FUNC_JR			6'b001000
`define FUNC_AND		6'b100100
`define FUNC_NOR		6'b100111
`define FUNC_OR			6'b100101
`define FUNC_XOR		6'b100110
`define FUNC_MFHI		6'b010000
`define FUNC_MFLO		6'b010010
`define FUNC_MTHI		6'b010001
`define FUNC_MTLO		6'b010011
`define FUNC_SLL		6'b000000
`define FUNC_SLLV		6'b000100
`define FUNC_SRA		6'b000011
`define FUNC_SRAV		6'b000111
`define FUNC_SRL		6'b000010
`define FUNC_SRLV		6'b000110
`define FUNC_BREAK		6'b001101
`define FUNC_SYSCALL	6'b001100
`define FUNC_RFE		6'b010000
`define FUNC_ERET		6'b011000



// Instruction Decode Unit
module cpu_idu
		(
			instruction,
			
			immediate_en,
			immediate_data,

			rs_en,
			rs_addr,
			                 
			rt_en,
			rt_addr,
			
			branch_en,
			branch_func,
			branch_index,
			branch_index_en,
			branch_imm_en,
			branch_rs_en,
						
			alu_adder_en,	
			alu_adder_func,
			alu_logic_en,
			alu_logic_func,
			alu_comp_en,
			alu_comp_func,

			shifter_en,
			shifter_func,
			shifter_sa_en,
			shifter_sa_data,
			
			muldiv_en,
			muldiv_mul,
			muldiv_div,
			muldiv_mthi,
			muldiv_mtlo,
			muldiv_mfhi,
			muldiv_mflo,
			muldiv_signed,
			
			cop0_mfc0,
			cop0_mtc0,
			cop0_rfe,

			exp_syscall,
			exp_break,
			
			mem_en,
			mem_we,
			mem_size,
			mem_unsigned,
			
			dst_reg_en,
			dst_reg_addr,
			dst_src_alu,
			dst_src_shifter,
			dst_src_mem,
			dst_src_pc,
			dst_src_hi,
			dst_src_lo,
			dst_src_cop0
		);
	
	parameter WIDTH = 32;
	
	input	[31:0]			instruction;

	output					rs_en;
	output	[4:0]			rs_addr;
			                 
	output					rt_en;
	output	[4:0]			rt_addr;
		
	output					immediate_en;
	output	[31:0]			immediate_data;
	
	output					branch_en;
	output	[3:0]			branch_func;
	output	[27:0]			branch_index;
	output					branch_index_en;
	output					branch_imm_en;
	output					branch_rs_en;
	
	output					alu_adder_en;
	output	[1:0]			alu_adder_func;
	output					alu_logic_en;
	output	[1:0]			alu_logic_func;
	output					alu_comp_en;
	output					alu_comp_func;
	
	output					shifter_en;
	output	[1:0]			shifter_func;
	output					shifter_sa_en;
	output	[4:0]			shifter_sa_data;
	
	output					muldiv_en;
	output					muldiv_mul;
	output					muldiv_div;
	output					muldiv_mthi;
	output					muldiv_mtlo;
	output					muldiv_mfhi;
	output					muldiv_mflo;
	output					muldiv_signed;

	output					cop0_mfc0;
	output					cop0_mtc0;
	output					cop0_rfe;

	output					exp_syscall;
	output					exp_break;

	output					mem_en;
	output					mem_we;
	output	[1:0]			mem_size;
	output					mem_unsigned;
			
	output					dst_reg_en;
	output	[4:0]			dst_reg_addr;
	output					dst_src_alu;
	output					dst_src_shifter;
	output					dst_src_mem;
	output					dst_src_pc;
	output					dst_src_hi;
	output					dst_src_lo;
	output					dst_src_cop0;


	// -----------------------------
	//  Support
	// -----------------------------
	
	// ADD
	wire	inst_add;
	assign inst_add   = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_ADD));

	// ADDI
	wire	inst_addi;
	assign inst_addi  = (instruction[31:26] == `OP_ADDI);

	// ADDIU
	wire	inst_addiu;
	assign inst_addiu = (instruction[31:26] == `OP_ADDIU);

	// ADDU
	wire	inst_addu;
	assign inst_addu = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_ADDU));
	
	// DIV
	wire	inst_div;
	assign inst_div  = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_DIV));

	// DIVU
	wire	inst_divu;
	assign inst_divu  = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_DIVU));

	// MULT
	wire	inst_mult;
	assign inst_mult = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_MULT));

	// MULTU
	wire	inst_multu;
	assign inst_multu = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_MULTU));

	// SLT
	wire	inst_slt;
	assign inst_slt = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SLT));

	// SLTI
	wire	inst_slti;
	assign inst_slti = ((instruction[31:26] == `OP_SLTI));

	// SLTIU
	wire	inst_sltiu;
	assign inst_sltiu = (instruction[31:26] == `OP_SLTIU);

	// SLTU
	wire	inst_sltu;
	assign inst_sltu = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SLTU));

	// SUB
	wire	inst_sub;
	assign inst_sub = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SUB));

	// SUBU
	wire	inst_subu;
	assign inst_subu = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SUBU));
	
	// BEQ
	wire	inst_beq;
	assign inst_beq = (instruction[31:26] == `OP_BEQ);
	
	// BGEZ
	wire	inst_bgez;
	assign inst_bgez = (instruction[31:26] == `OP_REGIMM) & (instruction[20:16] == 5'b00001);
	
	// BGEZAL
	wire	inst_bgezal;
	assign inst_bgezal = (instruction[31:26] == `OP_REGIMM) & (instruction[20:16] == 5'b10001);

	// BGTZ
	wire	inst_bgtz;
	assign inst_bgtz = (instruction[31:26] == `OP_BGTZ);
	
	// BLEZ
	wire	inst_blez;
	assign inst_blez = (instruction[31:26] == `OP_BLEZ);

	// BLTZ
	wire	inst_bltz;
	assign inst_bltz = ((instruction[31:26] == `OP_REGIMM ) & (instruction[20:16] == 5'b00000));
	
	// BLTZAL
	wire	inst_bltzal;
	assign inst_bltzal = ((instruction[31:26] == `OP_REGIMM ) & (instruction[20:16] == 5'b10000));
	
	// BNE
	wire	inst_bne;
	assign inst_bne = (instruction[31:26] == `OP_BNE);
	
	// J
	wire	inst_j;
	assign inst_j = (instruction[31:26] == `OP_J);

	// JAL
	wire	inst_jal;
	assign inst_jal = (instruction[31:26] == `OP_JAL);
	
	// JALR
	wire	inst_jalr;
	assign inst_jalr = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_JALR));
	
	// JR
	wire	inst_jr;
	assign inst_jr = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_JR));

	// LB
	wire	inst_lb;
	assign inst_lb = (instruction[31:26] == `OP_LB);
	
	// LBU
	wire	inst_lbu;
	assign inst_lbu = (instruction[31:26] == `OP_LBU);

	// LH
	wire	inst_lh;
	assign inst_lh = (instruction[31:26] == `OP_LH);

	// LHU
	wire	inst_lhu;
	assign inst_lhu = (instruction[31:26] == `OP_LHU);

	// LW
	wire	inst_lw;
	assign inst_lw = (instruction[31:26] == `OP_LW);

	// LWL
	wire	inst_lwl;
	assign inst_lwl = (instruction[31:26] == `OP_LWL);

	// LWR
	wire	inst_lwr;
	assign inst_lwr = (instruction[31:26] == `OP_LWR);

	// SB
	wire	inst_sb;
	assign inst_sb = (instruction[31:26] == `OP_SB);

	// SH
	wire	inst_sh;
	assign inst_sh = (instruction[31:26] == `OP_SH);

	// SW
	wire	inst_sw;
	assign inst_sw = (instruction[31:26] == `OP_SW);

	// SWL
	wire	inst_swl;
	assign inst_swl = (instruction[31:26] == `OP_SWL);

	// SWR
	wire	inst_swr;
	assign inst_swr = (instruction[31:26] == `OP_SWR);
	
	// AND
	wire	inst_and;
	assign inst_and = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_AND));

	// ANDI
	wire	inst_andi;
	assign inst_andi = (instruction[31:26] == `OP_ANDI);

	// LUI
	wire	inst_lui;
	assign inst_lui = (instruction[31:26] == `OP_LUI);

	// NOR
	wire	inst_nor;
	assign inst_nor = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_NOR));

	// OR
	wire	inst_or;
	assign inst_or = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_OR));

	// ORI
	wire	inst_ori;
	assign inst_ori = (instruction[31:26] == `OP_ORI);

	// XOR
	wire	inst_xor;
	assign inst_xor = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_XOR));
	
	// XORI
	wire	inst_xori;
	assign inst_xori = (instruction[31:26] == `OP_XORI);

	// MFHI
	wire	inst_mfhi;
	assign inst_mfhi = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_MFHI));

	// MFLO
	wire	inst_mflo;
	assign inst_mflo = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_MFLO));

	// MTHI
	wire	inst_mthi;
	assign inst_mthi = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_MTHI));
	
	// MTLO
	wire	inst_mtlo;
	assign inst_mtlo = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_MTLO));

	// SLL
	wire	inst_sll;
	assign inst_sll = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SLL));
	
	// SLLV
	wire	inst_sllv;
	assign inst_sllv = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SLLV));

	// SRA
	wire	inst_sra;
	assign inst_sra = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRA));

	// SRAV
	wire	inst_srav;
	assign inst_srav = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRAV));

	// SRL
	wire	inst_srl;
	assign inst_srl = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRL));

	// SRLV
	wire	inst_srlv;
	assign inst_srlv = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRLV));

	// BREAK
	wire	inst_break;
	assign inst_break = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_BREAK));
	
	// SYSCALL
	wire	inst_syscall;
	assign inst_syscall = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SYSCALL));

	// RFE
	wire	inst_rfe;
	assign inst_rfe = ((instruction[31:26] == `OP_COP0) & (instruction[25] == 1'b1) & (instruction[5:0] == `FUNC_RFE));
		
	// ERET
	wire	inst_eret;
	assign inst_eret = ((instruction[31:26] == `OP_COP0) & (instruction[25] == 1'b1) & (instruction[5:0] == `FUNC_ERET));
	
	// MFC0
	wire	inst_mfc0;
	assign inst_mfc0 = ((instruction[31:26] == `OP_COP0) & (instruction[25:21] == 5'b00000));
	
	// MTC0
	wire	inst_mtc0;
	assign inst_mtc0 = ((instruction[31:26] == `OP_COP0) & (instruction[25:21] == 5'b00100));
	
	
	
	
	assign cop0_mfc0   = inst_mfc0;
	assign cop0_mtc0   = inst_mtc0;
	assign cop0_rfe    = inst_rfe | inst_eret;

	assign exp_syscall = inst_syscall;
	assign exp_break   = inst_break;
	
	
	
	// -----------------------------
	//  Immidiate
	// -----------------------------
	
	wire					immediate_signed;
	wire					immediate_unsigned;
	wire					immediate_lui;
	wire					immediate_instr_index;
	
	assign immediate_signed = (instruction[31:26] == `OP_ADDI)
					| (instruction[31:26] == `OP_ADDI)
					| (instruction[31:26] == `OP_ADDIU)
					| (instruction[31:26] == `OP_SLTI)
					| (instruction[31:26] == `OP_SLTIU)
			/*		| (instruction[31:26] == `OP_BEQ)
					| (instruction[31:26] == `OP_BGTZ)
					| (instruction[31:26] == `OP_BLEZ)
					| (instruction[31:26] == `OP_BNE)
					| (instruction[31:26] == `OP_REGIMM)	*/
					| (instruction[31:26] == `OP_LUI)
					| (instruction[31:26] == `OP_LB)
					| (instruction[31:26] == `OP_LBU)
					| (instruction[31:26] == `OP_LH)
					| (instruction[31:26] == `OP_LHU)
					| (instruction[31:26] == `OP_LW)
					| (instruction[31:26] == `OP_LWL)
					| (instruction[31:26] == `OP_LWR)
					| (instruction[31:26] == `OP_SB)
					| (instruction[31:26] == `OP_SH)
					| (instruction[31:26] == `OP_SW)
					| (instruction[31:26] == `OP_SWL)
					| (instruction[31:26] == `OP_SWR);
	
	assign immediate_unsigned = (instruction[31:26] == `OP_ANDI)
					| (instruction[31:26] == `OP_ORI)
					| (instruction[31:26] == `OP_XORI);
	
	assign immediate_lui = (instruction[31:26] == `OP_LUI);
	
	assign immediate_data[31:16] = immediate_lui ? ~instruction[15:0] : (immediate_unsigned ? {16{1'b0}} : {16{instruction[15]}});
	assign immediate_data[15:0]  = immediate_lui ? ~16'h0000          : instruction[15:0];
	
	
	assign immediate_instr_index = (instruction[31:26] == `OP_J)
					| (instruction[31:26] == `OP_JAL);
	
	assign instr_index = (instruction[25:0] << 2);
	
	
	assign immediate_en = immediate_signed | immediate_unsigned | immediate_lui;



	// -----------------------------
	//  Source register
	// -----------------------------
	
	assign rs_en = (instruction[25:21] != 6'b00000)
					& ( inst_add
						| inst_addi
						| inst_addiu
						| inst_addu
						| inst_div
						| inst_divu
						| inst_mult
						| inst_multu
						| inst_slt
						| inst_slti
						| inst_sltiu
						| inst_sltu
						| inst_sub
						| inst_subu
						| inst_beq
						| inst_bgez
						| inst_bgezal
						| inst_bgtz
						| inst_blez
						| inst_bltz
						| inst_bltzal
						| inst_bne
						| inst_jalr
						| inst_jr
						| inst_lb
						| inst_lbu
						| inst_lh
						| inst_lhu
						| inst_lw
						| inst_lwl
						| inst_lwr
						| inst_sb
						| inst_sh
						| inst_sw
						| inst_swl
						| inst_swr
						| inst_and
						| inst_andi
						| inst_nor
						| inst_or
						| inst_ori
						| inst_xor
						| inst_xori
						| inst_mthi
						| inst_mtlo
						| inst_sllv
						| inst_srav
						| inst_srlv);

	assign rs_addr = instruction[25:21];
	
	
	assign rt_en   = (instruction[20:16] != 6'b00000)
					& ( inst_add
						| inst_addu
						| inst_div
						| inst_divu
						| inst_mult
						| inst_multu
						| inst_slt
						| inst_sltu
						| inst_sub
						| inst_subu
						| inst_lb
						| inst_lbu
						| inst_lh
						| inst_lhu
						| inst_lw
						| inst_lwl
						| inst_lwr
						| inst_and
						| inst_nor
						| inst_or
						| inst_xor
						| inst_sll
						| inst_sllv
						| inst_sra
						| inst_srav
						| inst_srl
						| inst_srlv
						| inst_mtc0);

	assign rt_addr = instruction[20:16];
	

	// -----------------------------
	//  Branch
	// -----------------------------

	assign branch_en = inst_beq
						| inst_bgez
						| inst_bgezal
						| inst_bgtz
						| inst_blez
						| inst_bltz
						| inst_bltzal
						| inst_bne
						| inst_j
						| inst_jal
						| inst_jalr
						| inst_jr;
	
	assign branch_func   = {instruction[16], instruction[28:26]};
	assign branch_index  = (instruction[25:0] << 2);
	
	assign branch_index_en = inst_j
							| inst_jal;
	assign branch_imm_en = inst_beq
							| inst_bgez
							| inst_bgezal
							| inst_bgtz
							| inst_blez
							| inst_bltz
							| inst_bltzal
							| inst_bne;
	assign branch_rs_en = inst_jr | inst_jalr;
	
	
	// -----------------------------
	//  ALU operation
	// -----------------------------
	
	assign alu_adder_en = (instruction[31:26] == `OP_ADDI)
							| (instruction[31:26] == `OP_ADDIU)
							| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_ADD))
							| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_ADDU))
							| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SUB))
							| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SUBU))
							| (instruction[31:26] == `OP_LB)
							| (instruction[31:26] == `OP_LBU)
							| (instruction[31:26] == `OP_LH)
							| (instruction[31:26] == `OP_LHU)
							| (instruction[31:26] == `OP_LW)
							| (instruction[31:26] == `OP_LWL)
							| (instruction[31:26] == `OP_LWR)
							| (instruction[31:26] == `OP_SB)
							| (instruction[31:26] == `OP_SH)
							| (instruction[31:26] == `OP_SW)
							| (instruction[31:26] == `OP_SWL)
							| (instruction[31:26] == `OP_SWR);
	
	assign alu_adder_func[0] = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SUB))
							| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SUBU))
							| inst_beq
							| inst_bne
							| alu_comp_en;
	assign alu_adder_func[1] = inst_blez | inst_bgtz | inst_bltz | inst_bltzal | inst_bgez | inst_bgezal;
	
	
	assign alu_logic_en   = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_AND))
							| (instruction[31:26] == `OP_ANDI)
							| (instruction[31:26] == `OP_LUI)
							| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_NOR))
							| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_OR))
							| (instruction[31:26] == `OP_ORI)
							| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_XOR))
							| (instruction[31:26] == `OP_XORI);

//`define	ALU_LOGIC_FUNC_AND	2'b00
//`define	ALU_LOGIC_FUNC_OR	2'b01
//`define	ALU_LOGIC_FUNC_XOR	2'b10
//`define	ALU_LOGIC_FUNC_NOR	2'b11
	assign alu_logic_func = (instruction[28] == 1'b0) ? instruction[1:0] : instruction[27:26];
	
	
	assign alu_comp_en   = inst_slt | inst_slti | inst_sltu | inst_sltiu;
	assign alu_comp_func = inst_slt | inst_slti;
	
	
	// -----------------------------
	//  Shifter operation
	// -----------------------------
	
	assign shifter_en = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SLL))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SLLV))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRA))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRAV))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRL))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRLV));
	
	assign shifter_func[0]  = instruction[1];
	assign shifter_func[1]  = instruction[0];
	
	assign shifter_sa_en   = ~instruction[2];
	assign shifter_sa_data = instruction[10:6];
	
	
	
	// -----------------------------
	//  Multiplier / Devider
	// -----------------------------


	assign muldiv_mul    = inst_mult | inst_multu;
	assign muldiv_div    = inst_div | inst_divu;
	assign muldiv_mthi   = inst_mtlo;
	assign muldiv_mtlo   = inst_mthi;
	assign muldiv_mfhi   = inst_mflo;
	assign muldiv_mflo   = inst_mfhi;
	assign muldiv_signed = ~instruction[0];
	
	assign muldiv_en     = muldiv_mul | muldiv_div | muldiv_mthi | muldiv_mtlo | muldiv_mfhi | muldiv_mflo;



	// -----------------------------
	//  Memory
	// -----------------------------
	
	assign mem_en = (instruction[31:26] == `OP_LB)
					| (instruction[31:26] == `OP_LBU)
					| (instruction[31:26] == `OP_LH)
					| (instruction[31:26] == `OP_LHU)
					| (instruction[31:26] == `OP_LW)
					| (instruction[31:26] == `OP_LWL)
					| (instruction[31:26] == `OP_LWR)
					| (instruction[31:26] == `OP_SB)
					| (instruction[31:26] == `OP_SH)
					| (instruction[31:26] == `OP_SW)
					| (instruction[31:26] == `OP_SWL)
					| (instruction[31:26] == `OP_SWR);
	
	assign mem_we       = instruction[29];
	assign mem_size     = instruction[27:26];
	assign mem_unsigned = instruction[28];
	
	
	
	
	
	// -----------------------------
	//  Distination register
	// -----------------------------
	
	wire	dst_reg_rt;
	wire	dst_reg_rd;
	wire	dst_reg_r31;
	
	assign dst_reg_rt = (instruction[31:26] == `OP_ADDI)
						| (instruction[31:26] == `OP_ADDIU)
						| (instruction[31:26] == `OP_SLTI)
						| (instruction[31:26] == `OP_SLTIU)
						| (instruction[31:26] == `OP_ANDI)
						| (instruction[31:26] == `OP_ORI)
						| (instruction[31:26] == `OP_XORI)
						| (instruction[31:26] == `OP_LB)
						| (instruction[31:26] == `OP_LBU)
						| (instruction[31:26] == `OP_LH)
						| (instruction[31:26] == `OP_LHU)
						| (instruction[31:26] == `OP_LW)
						| (instruction[31:26] == `OP_LWL)
						| (instruction[31:26] == `OP_LWR)
						| (instruction[31:26] == `OP_LUI)
						| ((instruction[31:26] == `OP_COP0) & (instruction[25:21] == 5'b00000));


	assign dst_reg_rd = ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_ADD))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_ADDU))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SLT))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SLTU))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SUB))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SUBU))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_AND))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_NOR))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_OR))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_XOR))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_MFHI))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_MFLO))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SLL))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SLLV))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRA))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRAV))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRL))
						| ((instruction[31:26] == `OP_SPECIAL) & (instruction[5:0] == `FUNC_SRLV))
						| inst_jalr;

	assign dst_reg_r31 = ((instruction[31:26] == `OP_REGIMM) & (instruction[20:16] == 5'b10001))	// BGEZAL
						| ((instruction[31:26] == `OP_REGIMM ) & (instruction[20:16] == 5'b10000))	// BLTZAL
						| (instruction[31:26] == `OP_JAL);
	
	
	assign dst_reg_en      = (dst_reg_addr != 5'b00000);
	assign dst_reg_addr    = (dst_reg_rt  ? instruction[20:16] : 5'b00000) |
							 (dst_reg_rd  ? instruction[15:11] : 5'b00000) |
							 (dst_reg_r31 ? 5'b11111           : 5'b00000);
	
	assign dst_src_alu     = alu_adder_en | alu_logic_en | alu_comp_en;
	assign dst_src_shifter = shifter_en;
	assign dst_src_mem     = mem_en & ~mem_we;
	assign dst_src_pc      = dst_reg_r31 | inst_jalr;
	assign dst_src_hi      = inst_mfhi;
	assign dst_src_lo      = inst_mflo;
	assign dst_src_cop0    = inst_mfc0;
	
endmodule

