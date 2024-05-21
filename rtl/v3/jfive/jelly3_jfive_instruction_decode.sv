// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_instruction_decode
//import jelly3_jfive_package::*;
        #(
            localparam  int                     XLEN        = 32,
            parameter   int                     THREADS     = 4                                 ,
            parameter   int                     ID_BITS     = THREADS > 1 ? $clog2(THREADS) : 1 ,
            parameter   type                    id_t        = logic [ID_BITS-1:0]               ,
            parameter   int                     PC_BITS     = 32                                ,
            parameter   type                    pc_t        = logic [PC_BITS-1:0]               ,
            parameter   int                     INSTR_BITS  = 32                                ,
            parameter   type                    instr_t     = logic [INSTR_BITS-1:0]            ,
            parameter   type                    ridx_t      = logic [4:0]                       ,
            parameter   type                    rval_t      = logic [XLEN-1:0]                  ,
            parameter                           DEVICE      = "RTL"                             ,
            parameter                           SIMULATION  = "false"                           
        )
        (
            input   var logic   reset           ,
            input   var logic   clk             ,
            input   var logic   cke             ,

            // instruction input
            input   var id_t    s_id            ,
            input   var logic   s_phase         ,
            input   var pc_t    s_pc            ,
            input   var instr_t s_instr         ,
            input   var logic   s_valid         ,
            output  var logic   s_wait          ,

            // writeback
            input   var id_t    s_wb_id         ,
            input   var ridx_t  s_wb_rd_idx     ,
            input   var rval_t  s_wb_rd_val     ,
            input   var logic   s_wb_valid      ,


            // instruction decode
            output  var id_t    m_id            ,
            output  var logic   m_phase         ,
            output  var pc_t    m_pc            ,
            output  var instr_t m_instr         ,
            output  var logic   m_valid         ,
            input   var logic   m_wait         
        );

    // parameters
//    localparam  int     SEL_WIDTH   = XLEN / 8;
//    localparam  int     SIZE_WIDTH  = 2;
//    localparam  int     SHAMT_WIDTH = $clog2(XLEN);


    // -----------------------------------------
    //  Signals
    // -----------------------------------------

    localparam  type    opcode_t = logic [6:0];
    localparam  type    funct3_t = logic [2:0];
    localparam  type    funct7_t = logic [6:0];

    // opcodes
    localparam  opcode_t    OPCODE_LUI      = 7'b0110111;

    localparam  opcode_t    OPCODE_AUIPC    = 7'b0010111;
    
    localparam  opcode_t    OPCODE_JAL      = 7'b1101111;
    
    localparam  opcode_t    OPCODE_JALR     = 7'b1100111;

    localparam  opcode_t    OPCODE_B        = 7'b1100011;
    localparam  opcode_t    OPCODE_BEQ      = 7'b1100011;
    localparam  opcode_t    OPCODE_BNE      = 7'b1100011;
    localparam  opcode_t    OPCODE_BLT      = 7'b1100011;
    localparam  opcode_t    OPCODE_BGE      = 7'b1100011;
    localparam  opcode_t    OPCODE_BLTU     = 7'b1100011;
    localparam  opcode_t    OPCODE_BGEU     = 7'b1100011;
    
    localparam  opcode_t    OPCODE_L        = 7'b0000011;
    localparam  opcode_t    OPCODE_LB       = 7'b0000011;
    localparam  opcode_t    OPCODE_LH       = 7'b0000011;
    localparam  opcode_t    OPCODE_LW       = 7'b0000011;
    localparam  opcode_t    OPCODE_LBU      = 7'b0000011;
    localparam  opcode_t    OPCODE_LHU      = 7'b0000011;
    
    localparam  opcode_t    OPCODE_S        = 7'b0100011;
    localparam  opcode_t    OPCODE_SB       = 7'b0100011;
    localparam  opcode_t    OPCODE_SH       = 7'b0100011;
    localparam  opcode_t    OPCODE_SW       = 7'b0100011;

    localparam  opcode_t    OPCODE_ALUI     = 7'b0010011;
    localparam  opcode_t    OPCODE_ADDI     = 7'b0010011;
    localparam  opcode_t    OPCODE_SLTI     = 7'b0010011;
    localparam  opcode_t    OPCODE_SLTIU    = 7'b0010011;
    localparam  opcode_t    OPCODE_XORI     = 7'b0010011;
    localparam  opcode_t    OPCODE_ORI      = 7'b0010011;
    localparam  opcode_t    OPCODE_ANDI     = 7'b0010011;
    localparam  opcode_t    OPCODE_SLLI     = 7'b0010011;
    localparam  opcode_t    OPCODE_SRLI     = 7'b0010011;
    localparam  opcode_t    OPCODE_SRAI     = 7'b0010011;
    
    localparam  opcode_t    OPCODE_ALU      = 7'b0110011;
    localparam  opcode_t    OPCODE_ADD      = 7'b0110011;
    localparam  opcode_t    OPCODE_SUB      = 7'b0110011;
    localparam  opcode_t    OPCODE_SLL      = 7'b0110011;
    localparam  opcode_t    OPCODE_SLT      = 7'b0110011;
    localparam  opcode_t    OPCODE_SLTU     = 7'b0110011;
    localparam  opcode_t    OPCODE_XOR      = 7'b0110011;
    localparam  opcode_t    OPCODE_SRL      = 7'b0110011;
    localparam  opcode_t    OPCODE_SRA      = 7'b0110011;
    localparam  opcode_t    OPCODE_OR       = 7'b0110011;
    localparam  opcode_t    OPCODE_AND      = 7'b0110011;

    localparam  opcode_t    OPCODE_FENCE    = 7'b0001111;
    localparam  opcode_t    OPCODE_ECALL    = 7'b1110011;
    localparam  opcode_t    OPCODE_EBREAK   = 7'b1110011;

    // funct3
    localparam  funct3_t    FUNCT3_JALR     = 3'b000;
    localparam  funct3_t    FUNCT3_BEQ      = 3'b000;
    localparam  funct3_t    FUNCT3_BNE      = 3'b001;
    localparam  funct3_t    FUNCT3_BLT      = 3'b100;
    localparam  funct3_t    FUNCT3_BGE      = 3'b101;
    localparam  funct3_t    FUNCT3_BLTU     = 3'b110;
    localparam  funct3_t    FUNCT3_BGEU     = 3'b111;
    localparam  funct3_t    FUNCT3_LB       = 3'b000;
    localparam  funct3_t    FUNCT3_LH       = 3'b001;
    localparam  funct3_t    FUNCT3_LW       = 3'b010;
    localparam  funct3_t    FUNCT3_LBU      = 3'b100;
    localparam  funct3_t    FUNCT3_LHU      = 3'b101;
    localparam  funct3_t    FUNCT3_SB       = 3'b000;
    localparam  funct3_t    FUNCT3_SH       = 3'b001;
    localparam  funct3_t    FUNCT3_SW       = 3'b010;
    localparam  funct3_t    FUNCT3_ADDI     = 3'b000;
    localparam  funct3_t    FUNCT3_SLTI     = 3'b010;
    localparam  funct3_t    FUNCT3_SLTIU    = 3'b011;
    localparam  funct3_t    FUNCT3_XORI     = 3'b100;
    localparam  funct3_t    FUNCT3_ORI      = 3'b110;
    localparam  funct3_t    FUNCT3_ANDI     = 3'b111;
    localparam  funct3_t    FUNCT3_SLLI     = 3'b001;
    localparam  funct3_t    FUNCT3_SRLI     = 3'b101;
    localparam  funct3_t    FUNCT3_SRAI     = 3'b101;
    localparam  funct3_t    FUNCT3_ADD      = 3'b000;
    localparam  funct3_t    FUNCT3_SUB      = 3'b000;
    localparam  funct3_t    FUNCT3_SLL      = 3'b001;
    localparam  funct3_t    FUNCT3_SLT      = 3'b010;
    localparam  funct3_t    FUNCT3_SLTU     = 3'b011;
    localparam  funct3_t    FUNCT3_XOR      = 3'b100;
    localparam  funct3_t    FUNCT3_SRL      = 3'b101;
    localparam  funct3_t    FUNCT3_SRA      = 3'b101;
    localparam  funct3_t    FUNCT3_OR       = 3'b110;
    localparam  funct3_t    FUNCT3_AND      = 3'b111;
    localparam  funct3_t    FUNCT3_FENCE    = 3'b000;
    localparam  funct3_t    FUNCT3_ECALL    = 3'b000;
    localparam  funct3_t    FUNCT3_EBREAK   = 3'b000;

    // funct7
    localparam  funct7_t    FUNCT7_SLLI     = 7'b0000000;
    localparam  funct7_t    FUNCT7_SRLI     = 7'b0000000;
    localparam  funct7_t    FUNCT7_SRAI     = 7'b0100000;
    localparam  funct7_t    FUNCT7_ADD      = 7'b0000000;
    localparam  funct7_t    FUNCT7_SUB      = 7'b0100000;
    localparam  funct7_t    FUNCT7_SLL      = 7'b0000000;
    localparam  funct7_t    FUNCT7_SLT      = 7'b0000000;
    localparam  funct7_t    FUNCT7_SLTU     = 7'b0000000;
    localparam  funct7_t    FUNCT7_XOR      = 7'b0000000;
    localparam  funct7_t    FUNCT7_SRL      = 7'b0000000;
    localparam  funct7_t    FUNCT7_SRA      = 7'b0100000;
    localparam  funct7_t    FUNCT7_OR       = 7'b0000000;
    localparam  funct7_t    FUNCT7_AND      = 7'b0000000;


    // -----------------------------------------
    //  Input Signals
    // -----------------------------------------

    wire opcode_t      s_opcode  = s_instr[6:0]   ;
    wire ridx_t        s_rd_idx  = s_instr[11:7]  ;
    wire ridx_t        s_rs1_idx = s_instr[19:15] ;
    wire ridx_t        s_rs2_idx = s_instr[24:20] ;
    wire funct3_t      s_funct3  = s_instr[14:12] ;
    wire funct7_t      s_funct7  = s_instr[31:25] ;

    wire    logic   signed  [11:0]  s_imm_i = s_instr[31:20]                                                   ;
    wire    logic   signed  [11:0]  s_imm_s = {s_instr[31:25], s_instr[11:7]}                                  ;
    wire    logic   signed  [12:0]  s_imm_b = {s_instr[31], s_instr[7], s_instr[30:25], s_instr[11:8], 1'b0}   ;
    wire    logic   signed  [31:0]  s_imm_u = {s_instr[31:12], 12'd0}                                          ;
    wire    logic   signed  [20:0]  s_imm_j = {s_instr[31], s_instr[19:12], s_instr[20], s_instr[30:21], 1'b0} ;
    wire    logic           [4:0]   s_shamt = s_instr[24:20]                                                   ;


    // -----------------------------------------
    //  Stage 0
    // -----------------------------------------

    // opcode の下位2bit は 11 で共通なので一旦無視

    logic  st0_rd_en;
    ridx_t st0_rd_idx;
    logic  st0_rs1_en;
    ridx_t st0_rs1_idx;
    logic  st0_rs2_en;
    ridx_t st0_rs2_idx;

    logic  st0_lui;
    logic  st0_auipc;
    logic  st0_jal;
    logic  st0_jalr;
    logic  st0_branch;
    logic  st0_load;
    logic  st0_store;
    logic  st0_alui;
    logic  st0_alu;
    logic  st0_fence;
    logic  st0_ecall;
    logic  st0_ebreak;

    logic  st0_alu_add;
    logic  st0_alu_sub;
    logic  st0_alu_sll;
    logic  st0_alu_slt;
    logic  st0_alu_sltu;
    logic  st0_alu_xor;

    always_ff @(posedge clk) begin
        if ( cke && !m_wait ) begin

            st0_rd_en  <= s_opcode[6:2] == OPCODE_LUI   [6:2]
                       || s_opcode[6:2] == OPCODE_AUIPC [6:2]
                       || s_opcode[6:2] == OPCODE_JAL   [6:2]
                       || s_opcode[6:2] == OPCODE_JALR  [6:2]
                       || s_opcode[6:2] == OPCODE_L     [6:2]
                       || s_opcode[6:2] == OPCODE_ALUI  [6:2]
                       || s_opcode[6:2] == OPCODE_ALU   [6:2]
                       || s_opcode[6:2] == OPCODE_FENCE [6:2];
            st0_rd_idx  <= s_rd_idx;

            st0_rs1_en <= s_opcode[6:2] == OPCODE_JALR  [6:2]
                       || s_opcode[6:2] == OPCODE_B     [6:2]
                       || s_opcode[6:2] == OPCODE_L     [6:2]
                       || s_opcode[6:2] == OPCODE_S     [6:2]
                       || s_opcode[6:2] == OPCODE_ALUI  [6:2]
                       || s_opcode[6:2] == OPCODE_ALU   [6:2]
                       || s_opcode[6:2] == OPCODE_FENCE [6:2];
            st0_rs1_idx <= s_rs1_idx;

            st0_rs2_en <= s_opcode[6:2] == OPCODE_B     [6:2]
                       || s_opcode[6:2] == OPCODE_S     [6:2]
                       || s_opcode[6:2] == OPCODE_ALU   [6:2];
            st0_rs2_idx <= s_rs2_idx;
            
            st0_lui    <= s_opcode[6:2] == OPCODE_LUI   [6:2];
            st0_auipc  <= s_opcode[6:2] == OPCODE_AUIPC [6:2];
            st0_jal    <= s_opcode[6:2] == OPCODE_JAL   [6:2];
            st0_jalr   <= s_opcode[6:2] == OPCODE_JALR  [6:2];
            st0_branch <= s_opcode[6:2] == OPCODE_B     [6:2];
            st0_load   <= s_opcode[6:2] == OPCODE_L     [6:2];
            st0_store  <= s_opcode[6:2] == OPCODE_S     [6:2];
            st0_alui   <= s_opcode[6:2] == OPCODE_ALUI  [6:2];
            st0_alu    <= s_opcode[6:2] == OPCODE_ALU   [6:2];
            st0_fence  <= s_opcode[6:2] == OPCODE_FENCE [6:2];
            st0_ecall  <= s_opcode[6:2] == OPCODE_ECALL [6:2];
            st0_ebreak <= s_opcode[6:2] == OPCODE_EBREAK[6:2];

            
        end
    end


endmodule


`default_nettype wire


// End of file
