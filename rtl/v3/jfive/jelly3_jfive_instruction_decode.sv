// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_instruction_decode
        #(
            localparam  int                     XLEN        = 32,
            parameter   int                     THREADS     = 4                                 ,
            parameter   int                     ID_BITS     = THREADS > 1 ? $clog2(THREADS) : 1 ,
            parameter   type                    id_t        = logic [ID_BITS-1:0]               ,
            parameter   int                     PC_BITS     = 32                                ,
            parameter   type                    pc_t        = logic [PC_BITS-1:0]               ,
            parameter   int                     INSTR_BITS  = 32                                ,
            parameter   type                    instr_t     = logic [INSTR_BITS-1:0]            ,
            parameter   int                     MEM_LATENCY = 2                                 ,
            parameter                           DEVICE      = "RTL"                             ,
            parameter   bit                     SIMULATION  = 1'b0                              ,
            parameter   bit     [THREADS-1:0]   INIT_RUN    = 1                                 ,
            parameter   id_t                    INIT_ID     = '0                                ,
            parameter   pc_t    [THREADS-1:0]   INIT_PC     = '0                                
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

            // instruction decode
            output  var id_t    m_id            ,
            output  var logic   m_phase         ,
            output  var pc_t    m_pc            ,
            output  var instr_t m_instr         ,
            output  var logic   m_valid         ,
            input   var logic   m_wait         
        );

    // -----------------------------------------
    //  Signals
    // -----------------------------------------

    // parameters
    localparam  int     SEL_WIDTH   = XLEN / 8;
    localparam  int     SIZE_WIDTH  = 2;
    localparam  int     INSTR_WIDTH = 32;
    localparam  int     RIDX_WIDTH  = 5;
    localparam  int     SHAMT_WIDTH = $clog2(XLEN);

    // instruction fetch
    logic   [INSTR_BITS-1:0]  if_instr;
    assign if_instr = s_instr;

    logic           [6:0]                   if_opcode;
    logic                                   if_rd_en;
    logic           [RIDX_WIDTH-1:0]        if_rd_idx;
    logic                                   if_rs1_en;
    logic           [RIDX_WIDTH-1:0]        if_rs1_idx;
    logic                                   if_rs2_en;
    logic           [RIDX_WIDTH-1:0]        if_rs2_idx;
    logic           [2:0]                   if_funct3;
    logic           [6:0]                   if_funct7;
    assign if_opcode  = if_instr[6:0];
    assign if_rd_idx  = if_instr[11:7];
    assign if_rs1_idx = if_instr[19:15];
    assign if_rs2_idx = if_instr[24:20];
    assign if_funct3  = if_instr[14:12];
    assign if_funct7  = if_instr[31:25];

    logic   signed  [11:0]                  if_imm_i;
    logic   signed  [11:0]                  if_imm_s;
    logic   signed  [12:0]                  if_imm_b;
    logic   signed  [31:0]                  if_imm_u;
    logic   signed  [20:0]                  if_imm_j;
    logic           [4:0]                   if_shamt;

    assign if_imm_i  = if_instr[31:20];
    assign if_imm_s  = {if_instr[31:25], if_instr[11:7]};
    assign if_imm_b  = {if_instr[31], if_instr[7], if_instr[30:25], if_instr[11:8], 1'b0};
    assign if_imm_u  = {if_instr[31:12], 12'd0};
    assign if_imm_j  = {if_instr[31], if_instr[19:12], if_instr[20], if_instr[30:21], 1'b0};
    assign if_shamt  = if_instr[24:20];


endmodule


`default_nettype wire


// End of file
