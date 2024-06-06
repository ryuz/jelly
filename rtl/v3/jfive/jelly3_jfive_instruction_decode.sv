// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_instruction_decode
        #(
            parameter   int     XLEN        = 32                                ,
            parameter   int     THREADS     = 4                                 ,
            parameter   int     ID_BITS     = THREADS > 1 ? $clog2(THREADS) : 1 ,
            parameter   type    id_t        = logic         [ID_BITS-1:0]       ,
            parameter   int     PHASE_BITS  = 1                                 ,
            parameter   type    phase_t     = logic         [PHASE_BITS-1:0]    ,
            parameter   int     PC_BITS     = 32                                ,
            parameter   type    pc_t        = logic         [PC_BITS-1:0]       ,
            parameter   int     INSTR_BITS  = 32                                ,
            parameter   type    instr_t     = logic         [INSTR_BITS-1:0]    ,
            parameter   type    ridx_t      = logic         [4:0]               ,
            parameter   type    rval_t      = logic signed  [XLEN-1:0]          ,
            parameter   type    shamt_t     = logic         [$clog2(XLEN)-1:0]  ,
            parameter   int     DATA_BITS   = $bits(rval_t)                     ,
            parameter   type    data_t      = logic         [DATA_BITS-1:0]     ,
            parameter   int     STRB_BITS   = $bits(data_t) / 8                 ,
            parameter   type    strb_t      = logic         [STRB_BITS-1:0]     ,
            parameter   int     ALIGN_BITS  = $clog2($bits(strb_t))             ,
            parameter   type    align_t     = logic         [ALIGN_BITS-1:0]    ,
            parameter   type    size_t      = logic         [1:0]               ,
            parameter   int     EXES        = 4                                 ,
            parameter   bit     RAW_HAZARD  = 1'b1                              ,
            parameter   bit     WAW_HAZARD  = 1'b1                              ,
            parameter           DEVICE      = "RTL"                             ,
            parameter           SIMULATION  = "false"                           ,
            parameter           DEBUG       = "false"               
        )
        (
            input   var logic               reset               ,
            input   var logic               clk                 ,
            input   var logic               cke                 ,

            // executions
            input   var id_t    [EXES-1:0]  exe_id              ,
            input   var logic   [EXES-1:0]  exe_rd_en           ,
            input   var ridx_t  [EXES-1:0]  exe_rd_idx          ,

            // writeback
            input   var id_t                wb_id               ,
            input   var logic               wb_rd_en            ,
            input   var ridx_t              wb_rd_idx           ,
            input   var rval_t              wb_rd_val           ,

            //  input
            input   var id_t                s_id                ,
            input   var phase_t             s_phase             ,
            input   var pc_t                s_pc                ,
            input   var instr_t             s_instr             ,
            input   var logic               s_valid             ,
            output  var logic               s_wait              ,

            // output
            output  var id_t                m_id                ,
            output  var phase_t             m_phase             ,
            output  var pc_t                m_pc                ,
            output  var instr_t             m_instr             ,
            output  var logic               m_rd_en             ,
            output  var ridx_t              m_rd_idx            ,
            output  var rval_t              m_rd_val            ,
            output  var logic               m_rs1_en            ,
            output  var rval_t              m_rs1_val           ,
            output  var logic               m_rs2_en            ,
            output  var rval_t              m_rs2_val           ,

            output  var logic               m_offset            ,
            output  var logic               m_adder             ,
            output  var logic               m_logical           ,
            output  var logic               m_shifter           ,
            output  var logic               m_load              ,
            output  var logic               m_store             ,
            output  var logic               m_branch            ,

            output  var logic               m_adder_sub         ,
            output  var logic               m_adder_imm_en      ,
            output  var rval_t              m_adder_imm_val     ,

            output  var logic   [1:0]       m_logical_mode      ,
            output  var logic               m_logical_imm_en    ,
            output  var rval_t              m_logical_imm_val   ,

            output  var logic               m_shifter_arithmetic,
            output  var logic               m_shifter_left      ,
            output  var logic               m_shifter_imm_en    ,
            output  var shamt_t             m_shifter_imm_val   ,

            output  var logic   [2:0]       m_branch_mode       ,
            output  var pc_t                m_branch_pc         ,

            output  var size_t              m_mem_size          ,
            output  var logic               m_mem_unsigned      ,

            output  var logic               m_valid             ,
            input   var logic               m_wait
        );


    // -----------------------------------------
    //  Defines
    // -----------------------------------------

    // types
    localparam  type    opcode_t = logic [6:0];
    localparam  type    funct3_t = logic [2:0];
    localparam  type    funct7_t = logic [6:0];

    // opcodes
    localparam  opcode_t    OPCODE_LUI      = 7'b0110111;

    localparam  opcode_t    OPCODE_AUIPC    = 7'b0010111;
    
    localparam  opcode_t    OPCODE_JAL      = 7'b1101111;
    
    localparam  opcode_t    OPCODE_JALR     = 7'b1100111;

    localparam  opcode_t    OPCODE_BRANCH   = 7'b1100011;
    localparam  opcode_t    OPCODE_BEQ      = 7'b1100011;
    localparam  opcode_t    OPCODE_BNE      = 7'b1100011;
    localparam  opcode_t    OPCODE_BLT      = 7'b1100011;
    localparam  opcode_t    OPCODE_BGE      = 7'b1100011;
    localparam  opcode_t    OPCODE_BLTU     = 7'b1100011;
    localparam  opcode_t    OPCODE_BGEU     = 7'b1100011;
    
    localparam  opcode_t    OPCODE_LOAD     = 7'b0000011;
    localparam  opcode_t    OPCODE_LB       = 7'b0000011;
    localparam  opcode_t    OPCODE_LH       = 7'b0000011;
    localparam  opcode_t    OPCODE_LW       = 7'b0000011;
    localparam  opcode_t    OPCODE_LBU      = 7'b0000011;
    localparam  opcode_t    OPCODE_LHU      = 7'b0000011;
    
    localparam  opcode_t    OPCODE_STORE    = 7'b0100011;
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
//  localparam  funct3_t    FUNCT3_ADDI     = 3'b000;
//  localparam  funct3_t    FUNCT3_SLTI     = 3'b010;
//  localparam  funct3_t    FUNCT3_SLTIU    = 3'b011;
//  localparam  funct3_t    FUNCT3_XORI     = 3'b100;
//  localparam  funct3_t    FUNCT3_ORI      = 3'b110;
//  localparam  funct3_t    FUNCT3_ANDI     = 3'b111;
//  localparam  funct3_t    FUNCT3_SLLI     = 3'b001;
//  localparam  funct3_t    FUNCT3_SRLI     = 3'b101;
//  localparam  funct3_t    FUNCT3_SRAI     = 3'b101;
    localparam  funct3_t    FUNCT3_ADD      = 3'b000;
//  localparam  funct3_t    FUNCT3_SUB      = 3'b000;
//  localparam  funct3_t    FUNCT3_SLL      = 3'b001;
    localparam  funct3_t    FUNCT3_SL       = 3'b001;
    localparam  funct3_t    FUNCT3_SLT      = 3'b010;
    localparam  funct3_t    FUNCT3_SLTU     = 3'b011;
    localparam  funct3_t    FUNCT3_XOR      = 3'b100;
    localparam  funct3_t    FUNCT3_SR       = 3'b101;
//  localparam  funct3_t    FUNCT3_SRL      = 3'b101;
//  localparam  funct3_t    FUNCT3_SRA      = 3'b101;
    localparam  funct3_t    FUNCT3_OR       = 3'b110;
    localparam  funct3_t    FUNCT3_AND      = 3'b111;
//  localparam  funct3_t    FUNCT3_FENCE    = 3'b000;
//  localparam  funct3_t    FUNCT3_ECALL    = 3'b000;
//  localparam  funct3_t    FUNCT3_EBREAK   = 3'b000;

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

    wire    opcode_t                s_opcode  = s_instr[6:0]   ;
    wire    ridx_t                  s_rd_idx  = s_instr[11:7]  ;
    wire    ridx_t                  s_rs1_idx = s_instr[19:15] ;
    wire    ridx_t                  s_rs2_idx = s_instr[24:20] ;
    wire    funct3_t                s_funct3  = s_instr[14:12] ;
    wire    funct7_t                s_funct7  = s_instr[31:25] ;

    wire    logic   signed  [11:0]  s_imm_i = s_instr[31:20]                                                   ;
    wire    logic   signed  [11:0]  s_imm_s = {s_instr[31:25], s_instr[11:7]}                                  ;
    wire    logic   signed  [12:0]  s_imm_b = {s_instr[31], s_instr[7], s_instr[30:25], s_instr[11:8], 1'b0}   ;
    wire    logic   signed  [31:0]  s_imm_u = {s_instr[31:12], 12'd0}                                          ;
    wire    logic   signed  [20:0]  s_imm_j = {s_instr[31], s_instr[19:12], s_instr[20], s_instr[30:21], 1'b0} ;
    wire    shamt_t                 s_shamt = s_instr[20 +: $bits(shamt_t)]                                    ;


    // -----------------------------------------
    //  Valiables
    // -----------------------------------------

    // stage 0
    id_t            st0_id                  ;
    logic           st0_phase               ;
    pc_t            st0_pc                  ;
    instr_t         st0_instr               ;
    logic           st0_rd_en               ;
    logic           st0_rs1_en              ;
    logic           st0_rs2_en              ;
    logic           st0_valid               ;


    // stage 1
    id_t            st1_id                  ;
    logic           st1_phase               ;
    pc_t            st1_pc                  ;
    instr_t         st1_instr               ;
    logic           st1_rd_en               ;
    rval_t          st2_rd_pc               ;
    rval_t          st2_rd_imm              ;
    logic           st1_rs1_en              ;
    rval_t          st1_rs1_val             ;
    logic           st1_rs2_en              ;
    rval_t          st1_rs2_val             ;
    logic           st1_pre_stall           ;
    logic           st1_valid               ;

    logic           st1_lui                 ;
    logic           st1_auipc               ;
    logic           st1_jal                 ;
    logic           st1_jalr                ;
    logic           st1_branch              ;
    logic           st1_load                ;
    logic           st1_store               ;
    logic           st1_alu                 ;

    wire    opcode_t                st1_opcode  = st1_instr[6:0]   ;
    wire    ridx_t                  st1_rd_idx  = st1_instr[11:7]  ;
    wire    ridx_t                  st1_rs1_idx = st1_instr[19:15] ;
    wire    ridx_t                  st1_rs2_idx = st1_instr[24:20] ;
    wire    funct3_t                st1_funct3  = st1_instr[14:12] ;
    wire    funct7_t                st1_funct7  = st1_instr[31:25] ;

    wire    logic   signed  [11:0]  st1_imm_i = st1_instr[31:20]                                                        ;
    wire    logic   signed  [11:0]  st1_imm_s = {st1_instr[31:25], st1_instr[11:7]}                                     ;
    wire    logic   signed  [12:0]  st1_imm_b = {st1_instr[31], st1_instr[7], st1_instr[30:25], st1_instr[11:8], 1'b0}  ;
    wire    logic   signed  [31:0]  st1_imm_u = {st1_instr[31:12], 12'd0}                                               ;
    wire    logic   signed  [20:0]  st1_imm_j = {st1_instr[31], st1_instr[19:12], st1_instr[20], st1_instr[30:21], 1'b0};
    wire    logic           [4:0]   st1_shamt = st1_instr[24:20]                                                        ;


    // stage 2
    logic           st2_stall               ;

    logic           st2_valid               ;
    id_t            st2_id                  ;
    logic           st2_phase               ;
    pc_t            st2_pc                  ;
    instr_t         st2_instr               ;
    logic           st2_rd_en               ;
    rval_t          st2_rd_val              ;
    logic           st2_rs1_en              ;
    rval_t          st2_rs1_val             ;
    logic           st2_rs2_en              ;
    rval_t          st2_rs2_val             ;

    logic           st2_offset              ;
    logic           st2_adder               ;
    logic           st2_logical             ;
    logic           st2_shifter             ;
    logic           st2_load                ;
    logic           st2_store               ;
    logic           st2_branch              ;

    logic           st2_adder_sub           ;
    logic           st2_adder_imm_en        ;
    rval_t          st2_adder_imm_val       ;

    logic           st2_shifter_arithmetic  ;
    logic           st2_shifter_left        ;
    logic           st2_shifter_imm_en      ;
    shamt_t         st2_shifter_imm_val     ;

    logic   [2:0]   st2_branch_mode         ;
    pc_t            st2_branch_pc           ;

    wire    opcode_t                st2_opcode  = st2_instr[6:0]   ;
    wire    ridx_t                  st2_rd_idx  = st2_instr[11:7]  ;
    wire    ridx_t                  st2_rs1_idx = st2_instr[19:15] ;
    wire    ridx_t                  st2_rs2_idx = st2_instr[24:20] ;
    wire    funct3_t                st2_funct3  = st2_instr[14:12] ;
    wire    funct7_t                st2_funct7  = st2_instr[31:25] ;

    wire    logic   signed  [11:0]  st2_imm_i = st2_instr[31:20]                                                        ;
    wire    logic   signed  [11:0]  st2_imm_s = {st2_instr[31:25], st2_instr[11:7]}                                     ;
    wire    logic   signed  [12:0]  st2_imm_b = {st2_instr[31], st2_instr[7], st2_instr[30:25], st2_instr[11:8], 1'b0}  ;
    wire    logic   signed  [31:0]  st2_imm_u = {st2_instr[31:12], 12'd0}                                               ;
    wire    logic   signed  [20:0]  st2_imm_j = {st2_instr[31], st2_instr[19:12], st2_instr[20], st2_instr[30:21], 1'b0};
    wire    shamt_t                 st2_shamt = st2_instr[20 +: $bits(shamt_t)]                                         ;



    // -----------------------------------------
    //  Stage 0
    // -----------------------------------------

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_valid  <= 1'b0    ;
            st0_id     <= 'x      ;
            st0_phase  <= 'x      ;
            st0_pc     <= 'x      ;
            st0_instr  <= 'x      ;
            st0_rd_en  <= 'x      ;
            st0_rs1_en <= 'x      ;
            st0_rs2_en <= 'x      ;
        end
        else if ( cke && !s_wait ) begin
            st0_valid  <= s_valid;
            st0_id     <= s_id      ;
            st0_phase  <= s_phase   ;
            st0_pc     <= s_pc      ;
            st0_instr  <= s_instr   ;

            // opcode の下位2bit は 11 で共通なので一旦無視
            st0_rd_en  <= s_valid 
                        && (s_opcode[6:2] == OPCODE_LUI   [6:2]
                         || s_opcode[6:2] == OPCODE_AUIPC [6:2]
                         || s_opcode[6:2] == OPCODE_JAL   [6:2]
                         || s_opcode[6:2] == OPCODE_JALR  [6:2]
                         || s_opcode[6:2] == OPCODE_LOAD  [6:2]
                         || s_opcode[6:2] == OPCODE_ALUI  [6:2]
                         || s_opcode[6:2] == OPCODE_ALU   [6:2]
                         || s_opcode[6:2] == OPCODE_FENCE [6:2]);

            st0_rs1_en <= s_valid
                        && (s_opcode[6:2] == OPCODE_JALR  [6:2]
                         || s_opcode[6:2] == OPCODE_BRANCH[6:2]
                         || s_opcode[6:2] == OPCODE_LOAD  [6:2]
                         || s_opcode[6:2] == OPCODE_STORE [6:2]
                         || s_opcode[6:2] == OPCODE_ALUI  [6:2]
                         || s_opcode[6:2] == OPCODE_ALU   [6:2]
                         || s_opcode[6:2] == OPCODE_FENCE [6:2]);

            st0_rs2_en <= s_valid
                        && (s_opcode[6:2] == OPCODE_BRANCH[6:2]
                         || s_opcode[6:2] == OPCODE_STORE [6:2]
                         || s_opcode[6:2] == OPCODE_ALU   [6:2]);
        end
    end

    wire    opcode_t                st0_opcode  = st0_instr[6:0]   ;
    wire    ridx_t                  st0_rd_idx  = st0_instr[11:7]  ;
    wire    ridx_t                  st0_rs1_idx = st0_instr[19:15] ;
    wire    ridx_t                  st0_rs2_idx = st0_instr[24:20] ;
    wire    funct3_t                st0_funct3  = st0_instr[14:12] ;
    wire    funct7_t                st0_funct7  = st0_instr[31:25] ;

    wire    logic   signed  [11:0]  st0_imm_i = st0_instr[31:20]                                                        ;
    wire    logic   signed  [11:0]  st0_imm_s = {st0_instr[31:25], st0_instr[11:7]}                                     ;
    wire    logic   signed  [12:0]  st0_imm_b = {st0_instr[31], st0_instr[7], st0_instr[30:25], st0_instr[11:8], 1'b0}  ;
    wire    logic   signed  [31:0]  st0_imm_u = {st0_instr[31:12], 12'd0}                                               ;
    wire    logic   signed  [20:0]  st0_imm_j = {st0_instr[31], st0_instr[19:12], st0_instr[20], st0_instr[30:21], 1'b0};
    wire    logic           [4:0]   st0_shamt = st0_instr[24:20]                                                        ;



    // -----------------------------------------
    //  Stage 1
    // -----------------------------------------

    logic  sig1_pre_stall;
    always_comb begin
        sig1_pre_stall = 1'b0;
        for ( int i = 0; i < EXES; i++ ) begin
            if ( RAW_HAZARD && st0_rs1_en && exe_rd_en[i] && {st0_id, st0_rs1_idx} == {exe_id[i], exe_rd_idx[i]} ) sig1_pre_stall = 1'b1;
            if ( RAW_HAZARD && st0_rs2_en && exe_rd_en[i] && {st0_id, st0_rs2_idx} == {exe_id[i], exe_rd_idx[i]} ) sig1_pre_stall = 1'b1;
            if ( WAW_HAZARD && st0_rd_en  && exe_rd_en[i] && {st0_id, st0_rs1_idx} == {exe_id[i], exe_rd_idx[i]} ) sig1_pre_stall = 1'b1;
        end
        if ( RAW_HAZARD && st0_rs1_en && st1_rd_en && {st0_id, st0_rs1_idx} == {st1_id, st1_rd_idx} ) sig1_pre_stall = 1'b1;
        if ( RAW_HAZARD && st0_rs2_en && st1_rd_en && {st0_id, st0_rs2_idx} == {st1_id, st1_rd_idx} ) sig1_pre_stall = 1'b1;
        if ( WAW_HAZARD && st0_rd_en  && st1_rd_en && {st0_id, st0_rs1_idx} == {st1_id, st1_rd_idx} ) sig1_pre_stall = 1'b1;

        if ( RAW_HAZARD && st0_rs1_en && st2_rd_en && {st0_id, st0_rs1_idx} == {st2_id, st2_rd_idx} ) sig1_pre_stall = 1'b1;
        if ( RAW_HAZARD && st0_rs2_en && st2_rd_en && {st0_id, st0_rs2_idx} == {st2_id, st2_rd_idx} ) sig1_pre_stall = 1'b1;
        if ( WAW_HAZARD && st0_rd_en  && st2_rd_en && {st0_id, st0_rs1_idx} == {st2_id, st2_rd_idx} ) sig1_pre_stall = 1'b1;
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st1_id        <= 'x  ;
            st1_phase     <= 'x  ;
            st1_pc        <= 'x  ;
            st1_instr     <= 'x  ;
            st1_rd_en     <= 'x  ;
            st1_rs1_en    <= 'x  ;
            st1_rs2_en    <= 'x  ;
            st1_lui       <= 'x  ;
            st1_auipc     <= 'x  ;
            st1_pre_stall <= 1'b0;
            st1_valid     <= 1'b0;
        end
        else if ( cke && !s_wait ) begin
            st1_id        <= st0_id     ;
            st1_phase     <= st0_phase  ;
            st1_pc        <= st0_pc     ;
            st1_instr     <= st0_instr  ;
            st1_rd_en     <= st0_rd_en  && (st0_rd_idx  != 0);
            st1_rs1_en    <= st0_rs1_en && (st0_rs1_idx != 0);
            st1_rs2_en    <= st0_rs2_en && (st0_rs2_idx != 0);
            st1_lui       <= st0_opcode[6:2] == OPCODE_LUI[6:2];
            st1_auipc     <= st0_opcode[6:2] == OPCODE_AUIPC[6:2];
            st1_pre_stall <= sig1_pre_stall;
            st1_valid     <= st0_valid;
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st1_lui     <= 1'bx;
            st1_auipc   <= 1'bx;
            st1_jal     <= 1'bx;
            st1_jalr    <= 1'bx;
            st1_branch  <= 1'bx;
            st1_load    <= 1'bx;
            st1_store   <= 1'bx;
            st1_alu     <= 1'bx;
        end
        else if ( cke & !s_wait ) begin
            st1_lui     <= st0_opcode[6:2] == OPCODE_LUI[6:2];
            st1_auipc   <= st0_opcode[6:2] == OPCODE_AUIPC[6:2];
            st1_jal     <= st0_opcode[6:2] == OPCODE_JAL[6:2];
            st1_jalr    <= st0_opcode[6:2] == OPCODE_JALR[6:2];
            st1_branch  <= st0_opcode[6:2] == OPCODE_BRANCH[6:2];
            st1_load    <= st0_opcode[6:2] == OPCODE_LOAD[6:2];
            st1_store   <= st0_opcode[6:2] == OPCODE_STORE[6:2];
            st1_alu     <= st0_opcode[6:2] == OPCODE_ALU[6:2] || st0_opcode[6:2] == OPCODE_ALUI[6:2];
        end
    end


    // register file
    jelly3_jfive_register_file
            #(
                .READ_PORTS     (2                          ),
                .ADDR_BITS      ($bits(id_t) + $bits(ridx_t)),
                .DATA_BITS      ($bits(rval_t)              ),
                .ZERO_REG       (1'b0                       ),
                .REGISTERS      (THREADS * 32               ), 
                .RAM_TYPE       ("distributed"              ),
                .DEVICE         (DEVICE                     ),
                .SIMULATION     (SIMULATION                 ),
                .DEBUG          (DEBUG                      )
            )
        u_register_file
            (
                .reset          ,
                .clk            ,
                .cke            ,

                .wr_en          (wb_rd_en                   ),
                .wr_addr        ({wb_id, wb_rd_idx}         ),
                .wr_din         (wb_rd_val                  ),

                .rd_addr        ({
                                    {st1_id, st1_rs2_idx},
                                    {st1_id, st1_rs1_idx}
                                }),
                .rd_dout        ({
                                    st1_rs2_val,
                                    st1_rs1_val
                                })
            );

                                                  ;



    // -----------------------------------------
    //  Stage 2
    // -----------------------------------------

    // stall control
    logic  sig2_stall;
    always_comb begin
        sig2_stall = 1'b0;
        for ( int i = 0; i < EXES; i++ ) begin
            if ( RAW_HAZARD && st2_rs1_en && exe_rd_en[i] && {st2_id, st2_rs1_idx} == {exe_id[i], exe_rd_idx[i]} ) sig2_stall = 1'b1;
            if ( RAW_HAZARD && st2_rs2_en && exe_rd_en[i] && {st2_id, st2_rs2_idx} == {exe_id[i], exe_rd_idx[i]} ) sig2_stall = 1'b1;
            if ( WAW_HAZARD && st2_rd_en  && exe_rd_en[i] && {st2_id, st2_rs1_idx} == {exe_id[i], exe_rd_idx[i]} ) sig2_stall = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st2_stall    <= 1'b0;
        end
        else if ( cke ) begin
            if ( !s_wait ) begin
                st2_stall   <= st1_pre_stall;
            end
            
            if ( st2_stall ) begin
                st2_stall <= sig2_stall;
            end
        end
    end

    assign s_wait = st2_stall || m_wait;


    // context
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st2_valid    <= 1'b0;
            st2_id       <= 'x  ;
            st2_phase    <= 'x  ;
            st2_pc       <= 'x  ;
            st2_instr    <= 'x  ;
        end
        else if ( cke && !s_wait ) begin
            st2_valid   <= st1_valid    ;
            st2_id      <= st1_id       ;
            st2_phase   <= st1_phase    ;
            st2_pc      <= st1_pc       ;
            st2_instr   <= st1_instr    ;
        end
    end

    // registers
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st2_rd_en    <= 'x  ;
            st2_rd_val   <= 'x  ;
            st2_rs1_en   <= 'x  ;
            st2_rs1_val  <= 'x  ;
            st2_rs2_en   <= 'x  ;
            st2_rs2_val  <= 'x  ;
        end
        else if ( cke ) begin
            if ( !s_wait ) begin
                // rd
                st2_rd_en   <= st1_rd_en    ;
                if ( st1_lui ) begin
                    st2_rd_val <= rval_t'(st1_imm_u);
                end 
                else if ( st1_auipc ) begin
                    st2_rd_val <= rval_t'(st1_pc) + rval_t'(st1_imm_u);
                end
                else begin
                    st2_rd_val <= rval_t'(st1_pc) + rval_t'(4);
                end

                // rs1/rs2
                st2_rs1_en  <= st1_rs1_en   ;
                st2_rs1_val <= st1_rs1_val  ;
                st2_rs2_en  <= st1_rs2_en   ;
                st2_rs2_val <= st1_rs2_val  ;
                if ( wb_rd_en && {wb_id, wb_rd_idx} == {st1_id, st1_rs1_idx} ) st2_rs1_val <= wb_rd_val;    // forward
                if ( wb_rd_en && {wb_id, wb_rd_idx} == {st1_id, st1_rs2_idx} ) st2_rs2_val <= wb_rd_val;    // forward
            end
            else begin
                if ( wb_rd_en && {wb_id, wb_rd_idx} == {st2_id, st2_rs1_idx} ) st2_rs1_val <= wb_rd_val;    // forward
                if ( wb_rd_en && {wb_id, wb_rd_idx} == {st2_id, st2_rs2_idx} ) st2_rs2_val <= wb_rd_val;    // forward
            end
        end
    end

    // control
    always_ff @(posedge clk) begin
        if ( cke && !s_wait ) begin
            // type
            st2_offset    <= st1_lui || st1_auipc || st1_jal || st1_jalr;
            st2_adder     <= st1_alu && (st1_funct3 == FUNCT3_ADD || st1_funct3 == FUNCT3_SLT || st1_funct3 == FUNCT3_SLTU);
            st2_logical   <= st1_alu && (st1_funct3 == FUNCT3_XOR || st1_funct3 == FUNCT3_OR  || st1_funct3 == FUNCT3_AND);
            st2_shifter   <= st1_alu && (st1_funct3 == FUNCT3_SL  || st1_funct3 == FUNCT3_SR);
            st2_load      <= st1_opcode[6:2] == OPCODE_LOAD[6:2];
            st2_store     <= st1_opcode[6:2] == OPCODE_STORE[6:2];
            st2_branch    <= st1_jal || st1_jalr || st1_branch;

            // adder
            st2_adder_sub     <= (st1_instr[6:5] == 2'b01 && st1_instr[30] == 1'b1) // SUB
                            || (st1_instr[6:2] == OPCODE_BRANCH[6:2]);                 // BEQ/BNE/BLT/BGE/BLTU/BGEU
            st2_adder_imm_en  <= st1_instr[6:2] == OPCODE_JALR[6:2]                 // JALR
                            || st1_instr[6:2] == OPCODE_ALUI[6:2];                // ADDI/STLI/STLIU/XORI/ORI/ANDI
            st2_adder_imm_val <= st1_funct3 == FUNCT3_SLTU ? rval_t'($unsigned(st1_imm_i)) : rval_t'($signed(st1_imm_i));

            // shifter
            st2_shifter_arithmetic <= st1_funct7[5] ;
            st2_shifter_left       <= ~st1_funct3[2];
            st2_shifter_imm_en     <= ~st1_opcode[5];
            st2_shifter_imm_val    <= st1_shamt     ;

            // branch
            st2_branch_mode <= st1_funct3;
            if ( st1_jal  ) st2_branch_mode <= 3'b010;
            if ( st1_jalr ) st2_branch_mode <= 3'b011;
            st2_branch_pc <= st1_pc + (st1_jal ?  + pc_t'(st1_imm_j) : pc_t'(st1_imm_b));
        end
    end




    // -----------------------------------------
    //  output
    // -----------------------------------------

    assign m_valid              = st2_valid && !st2_stall   ;

    assign m_id                 = st2_id                    ;
    assign m_phase              = st2_phase                 ;
    assign m_pc                 = st2_pc                    ;
    assign m_instr              = st2_instr                 ;

    assign m_rd_en              = st2_rd_en                 ;
    assign m_rd_idx             = st2_rd_idx                ;
    assign m_rd_val             = st2_rd_val                ;
    assign m_rs1_en             = st2_rs1_en                ;
    assign m_rs1_val            = st2_rs1_val               ;
    assign m_rs2_en             = st2_rs2_en                ;
    assign m_rs2_val            = st2_rs2_val               ;

    assign m_offset             = st2_offset                ;
    assign m_adder              = st2_adder                 ;
    assign m_logical            = st2_logical               ;
    assign m_shifter            = st2_shifter               ;
    assign m_load               = st2_load                  ;
    assign m_store              = st2_store                 ;
    assign m_branch             = st2_branch                ;

    assign m_adder_sub          = st2_adder_sub             ;
    assign m_adder_imm_en       = st2_adder_imm_en          ;
    assign m_adder_imm_val      = st2_adder_imm_val         ;

    assign m_logical_mode       = st2_funct3[1:0]           ;
    assign m_logical_imm_en     = st2_adder_imm_en          ;
    assign m_logical_imm_val    = st2_adder_imm_val         ;

    assign m_shifter_arithmetic = st2_shifter_arithmetic    ;
    assign m_shifter_left       = st2_shifter_left          ;
    assign m_shifter_imm_en     = st2_shifter_imm_en        ;
    assign m_shifter_imm_val    = st2_shifter_imm_val       ;

    assign m_branch_mode        = st2_branch_mode           ;
    assign m_branch_pc          = st2_branch_pc             ;

    assign m_mem_size           = st2_funct3[1:0]           ;
    assign m_mem_unsigned       = st2_funct3[2]             ;


endmodule


`default_nettype wire


// End of file
