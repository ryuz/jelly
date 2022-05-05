// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_jfive_micro_core
        #(
            parameter   int                     PC_WIDTH         = 32,
            parameter   bit     [PC_WIDTH-1:0]  INIT_PC_ADDR     = PC_WIDTH'(32'h80000000),

            parameter   int                     TCM_ADDR_WIDTH   = 14,
            parameter   bit     [31:0]          TCM_DECODE_MASK  = 32'hff00_0000,
            parameter   bit     [31:0]          TCM_DECODE_ADDR  = 32'h8000_0000,

            parameter   int                     MMIO_ADDR_WIDTH  = 32,
            parameter   bit     [31:0]          MMIO_DECODE_MASK = 32'hff00_0000,
            parameter   bit     [31:0]          MMIO_DECODE_ADDR = 32'hff00_0000,
            
            parameter                           DEVICE           = "RTL",

            parameter   bit                     SIMULATION       = 1'b0,
            parameter   bit                     LOG_EXE_ENABLE   = 1'b0,
            parameter   string                  LOG_EXE_FILE     = "jfive_exe_log.txt",
            parameter   bit                     LOG_MEM_ENABLE   = 1'b0,
            parameter   string                  LOG_MEM_FILE     = "jfive_mem_log.txt"
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,

            // Tightly Coupled Memory (Instruction)
            output  wire                            itcm_en,        // enable
            output  wire    [TCM_ADDR_WIDTH-1:0]    itcm_addr,      // address
            input   wire    [31:0]                  itcm_rdata,     // read data

            // Tightly Coupled Memory (Data)
            output  wire                            dtcm_en,        // enable
            output  wire    [TCM_ADDR_WIDTH-1:0]    dtcm_addr,      // size
            output  wire    [3:0]                   dtcm_wsel,      // byte lane select(write only)
            output  wire    [31:0]                  dtcm_wdata,     // write data
            input   wire    [31:0]                  dtcm_rdata,     // read data
            
            // Memory mapped I/O
            output  wire                            mmio_en,        // read or write
            output  wire                            mmio_re,        // read enable
            output  wire                            mmio_we,        // write enable
            output  wire    [1:0]                   mmio_size,      // address
            output  wire    [MMIO_ADDR_WIDTH-1:0]   mmio_addr,      // size
            output  wire    [3:0]                   mmio_sel,       // byte lane select
            output  wire    [3:0]                   mmio_rsel,      // byte lane select(read only)
            output  wire    [3:0]                   mmio_wsel,      // byte lane select(write only)
            output  wire    [31:0]                  mmio_wdata,     // write data
            input   wire    [31:0]                  mmio_rdata      // read data
        );


    // -----------------------------------------
    //  Signals
    // -----------------------------------------

    // parameters
    localparam XLEN        = 32;
    localparam SEL_WIDTH   = XLEN / 8;
    localparam SIZE_WIDTH  = 2;
    localparam INSTR_WIDTH = 32;
    localparam RIDX_WIDTH  = 5;

    typedef enum logic [3:0] {
        BRANCH_JAL,
        BRANCH_JALR,
        BRANCH_BEQ,
        BRANCH_BNE,
        BRANCH_BLT,
        BRANCH_BGE,
        BRANCH_BLTU,
        BRANCH_BGEU
    } branch_sel_t;


    // Program counter
    logic                                   pc_cke;
    logic           [PC_WIDTH-1:0]          pc_pc;

    // Instruction Fetch
    logic                                   if_stall;
    logic                                   if_cke;
    logic           [PC_WIDTH-1:0]          if_pc;
    logic           [INSTR_WIDTH-1:0]       if_instr;
    logic                                   if_valid;

    logic           [6:0]                   if_opcode;
    logic                                   if_rd_en;
    logic           [RIDX_WIDTH-1:0]        if_rd_idx;
    logic                                   if_rs1_en;
    logic           [RIDX_WIDTH-1:0]        if_rs1_idx;
    logic                                   if_rs2_en;
    logic           [RIDX_WIDTH-1:0]        if_rs2_idx;
    logic           [2:0]                   if_funct3;
    logic           [6:0]                   if_funct7;

    logic   signed  [11:0]                  if_imm_i;
    logic   signed  [11:0]                  if_imm_s;
    logic   signed  [12:0]                  if_imm_b;
    logic   signed  [31:0]                  if_imm_u;
    logic   signed  [20:0]                  if_imm_j;

    // Instruction Decode
    logic                                   id_cke;

    logic           [PC_WIDTH-1:0]          id_pc;
    logic           [INSTR_WIDTH-1:0]       id_instr;
    logic                                   id_valid;

    logic           [6:0]                   id_opcode;
    logic           [RIDX_WIDTH-1:0]        id_rd_idx;
    logic           [RIDX_WIDTH-1:0]        id_rs1_idx;
    logic           [RIDX_WIDTH-1:0]        id_rs2_idx;
    logic           [2:0]                   id_funct3;
    logic           [6:0]                   id_funct7;

    logic   signed  [11:0]                  id_imm_i;
    logic   signed  [11:0]                  id_imm_s;
    logic   signed  [12:0]                  id_imm_b;
    logic   signed  [31:0]                  id_imm_u;
    logic   signed  [20:0]                  id_imm_j;

    logic                                   id_rs1_en;
    logic                                   id_rs2_en;
    logic                                   id_rd_en;
    logic   signed  [XLEN-1:0]              id_rs1_val;
    logic   signed  [XLEN-1:0]              id_rs2_val;

    branch_sel_t                            id_branch_sel;
    logic           [PC_WIDTH-1:0]          id_branch_pc0;
    logic           [PC_WIDTH-1:0]          id_branch_pc1;

    logic   signed  [XLEN-1:0]              id_mem_offset;
    logic                                   id_mem_re;
    logic                                   id_mem_we;
    logic           [1:0]                   id_mem_size;
    logic                                   id_mem_unsigned;


    //  Execution
    logic                                   ex_cke;
    logic                                   ex_valid;
    logic           [PC_WIDTH-1:0]          ex_pc;
    logic           [31:0]                  ex_instr;
    logic           [PC_WIDTH-1:0]          ex_expect_pc;

    logic           [1:0]                   ex_fwd_rs1_stage;
    logic           [1:0]                   ex_fwd_rs2_stage;
    logic   signed  [XLEN-1:0]              ex_fwd_rs1_val;
    logic   signed  [XLEN-1:0]              ex_fwd_rs2_val;
    logic           [XLEN-1:0]              ex_fwd_rs1_val_u;
    logic           [XLEN-1:0]              ex_fwd_rs2_val_u;

    logic           [PC_WIDTH-1:0]          ex_branch_pc;

    logic                                   ex_rs1_en;
    logic           [RIDX_WIDTH-1:0]        ex_rs1_idx;
    logic           [XLEN-1:0]              ex_rs1_val;
    logic                                   ex_rs2_en;
    logic           [RIDX_WIDTH-1:0]        ex_rs2_idx;
    logic           [XLEN-1:0]              ex_rs2_val;

    logic                                   ex_rd_en;
    logic           [RIDX_WIDTH-1:0]        ex_rd_idx;
    logic   signed  [XLEN-1:0]              ex_rd_val;

    logic                                   ex_mem_en = '0;
    logic                                   ex_mem_re = '0;
    logic                                   ex_mem_we = '0;
    logic           [XLEN-1:0]              ex_mem_addr;
    logic           [SIZE_WIDTH-1:0]        ex_mem_size;
    logic           [SEL_WIDTH-1:0]         ex_mem_sel = '0;
    logic           [SEL_WIDTH-1:0]         ex_mem_rsel = '0;
    logic           [SEL_WIDTH-1:0]         ex_mem_wsel = '0;
    logic           [XLEN-1:0]              ex_mem_wdata;
    logic                                   ex_mem_unsigned;

    logic                                   ex_dtcm_en = '0;
    logic                                   ex_dtcm_re = '0;
    logic           [3:0]                   ex_dtcm_wsel = '0;
    logic           [TCM_ADDR_WIDTH-1:0]    ex_dtcm_addr;
    logic           [31:0]                  ex_dtcm_wdata;

    logic                                   ex_mmio_en = '0;
    logic                                   ex_mmio_re = '0;
    logic                                   ex_mmio_we = '0;
    logic           [MMIO_ADDR_WIDTH-1:0]   ex_mmio_addr;
    logic           [SIZE_WIDTH-1:0]        ex_mmio_size;
    logic           [SEL_WIDTH-1:0]         ex_mmio_sel;
    logic           [SEL_WIDTH-1:0]         ex_mmio_rsel = '0;
    logic           [SEL_WIDTH-1:0]         ex_mmio_wsel = '0;
    logic           [XLEN-1:0]              ex_mmio_wdata;

    
    // Memory Access
    logic                                   ma_cke;
    logic                                   ma_valid;
    logic           [PC_WIDTH-1:0]          ma_pc;
    logic           [31:0]                  ma_instr;

    logic                                   ma_rs1_en;
    logic           [RIDX_WIDTH-1:0]        ma_rs1_idx;
    logic           [XLEN-1:0]              ma_rs1_val;
    logic                                   ma_rs2_en;
    logic           [RIDX_WIDTH-1:0]        ma_rs2_idx;
    logic           [XLEN-1:0]              ma_rs2_val;
    logic                                   ma_rd_en;
    logic           [RIDX_WIDTH-1:0]        ma_rd_idx;
    logic           [XLEN-1:0]              ma_rd_val;

    logic                                   ma_mem_we;
    logic                                   ma_mem_re;
    logic           [XLEN-1:0]              ma_mem_addr;
    logic           [SIZE_WIDTH-1:0]        ma_mem_size;
    logic           [SEL_WIDTH-1:0]         ma_mem_sel;
    logic                                   ma_mem_unsigned;
    logic           [XLEN-1:0]              ma_mem_wdata;
    logic           [XLEN-1:0]              ma_mem_rdata;
    logic                                   ma_dtcm_re;
    logic                                   ma_mmio_re;

    // Write back
    logic                                   wb_cke;
    logic                                   wb_valid;
    logic           [PC_WIDTH-1:0]          wb_pc;
    logic           [INSTR_WIDTH-1:0]       wb_instr;

    logic                                   wb_rs1_en;
    logic           [RIDX_WIDTH-1:0]        wb_rs1_idx;
    logic           [XLEN-1:0]              wb_rs1_val;
    logic                                   wb_rs2_en;
    logic           [RIDX_WIDTH-1:0]        wb_rs2_idx;
    logic           [XLEN-1:0]              wb_rs2_val;

    logic                                   wb_mem_we;
    logic                                   wb_mem_re;
    logic           [XLEN-1:0]              wb_mem_addr;
    logic           [SEL_WIDTH-1:0]         wb_mem_sel;
    logic           [XLEN-1:0]              wb_mem_wdata;
    logic           [XLEN-1:0]              wb_mem_rdata;

    logic                                   wb_rd_en;
    logic           [RIDX_WIDTH-1:0]        wb_rd_idx;
    logic           [XLEN-1:0]              wb_rd_val;


    // -----------------------------------------
    //  Interlock
    // -----------------------------------------

    // ストール時にデコードまでのパイプラインを止める
    assign pc_cke = cke & !if_stall;
    assign if_cke = cke & !if_stall;
    assign id_cke = cke;
    assign ex_cke = cke;
    assign ma_cke = cke;
    assign wb_cke = cke;


    // -----------------------------------------
    //  Program counter
    // -----------------------------------------

    always_ff @(posedge clk) begin
        if ( reset ) begin
            pc_pc <= INIT_PC_ADDR;
        end
        else if ( pc_cke ) begin
            pc_pc <= pc_pc + PC_WIDTH'(4);

            // 実行ステージの期待する命令がでコードパイプになければブランチ
            if ( !((ex_expect_pc == pc_pc)
                || (ex_expect_pc == if_pc && if_valid)
                || (ex_expect_pc == id_pc && id_valid)) ) begin
                pc_pc <= ex_expect_pc;
            end
        end
    end


    // -----------------------------------------
    //  Instruction Fetch
    // -----------------------------------------

    logic                               if_stall_en;

    logic           [PC_WIDTH-1:0]      if0_pc;
    logic           [INSTR_WIDTH-1:0]   if0_instr;
    logic                               if0_valid;

    logic           [PC_WIDTH-1:0]      if1_pc;
    logic           [INSTR_WIDTH-1:0]   if1_instr;
    logic                               if1_valid;

    // Instruction Fetch
    assign itcm_en   = ~if_stall;
    assign itcm_addr = TCM_ADDR_WIDTH'(pc_pc >> 2);
    assign if0_instr = itcm_rdata;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            if0_pc    <= 'x;
            if0_valid <= 1'b0;
        end
        else if ( if_cke ) begin
            if0_pc    <= pc_pc;
            if0_valid <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if ( if_cke ) begin
            if1_pc    <= if0_pc;
            if1_instr <= if0_instr;
            if1_valid <= if0_valid;
        end
    end

    assign if_pc    = if_stall ? if1_pc    : if0_pc;
    assign if_instr = if_stall ? if1_instr : if0_instr;
    assign if_valid = (if_stall ? if1_valid : if0_valid) & !if_stall_en;


    // instruction decocde
    assign if_opcode  = if_instr[6:0];
    assign if_rd_idx  = if_instr[11:7];
    assign if_rs1_idx = if_instr[19:15];
    assign if_rs2_idx = if_instr[24:20];
    assign if_funct3  = if_instr[14:12];
    assign if_funct7  = if_instr[31:25];

    assign if_imm_i  = if_instr[31:20];
    assign if_imm_s  = {if_instr[31:25], if_instr[11:7]};
    assign if_imm_b  = {if_instr[31], if_instr[7], if_instr[30:25], if_instr[11:8], 1'b0};
    assign if_imm_u  = {if_instr[31:12], 12'd0};
    assign if_imm_j  = {if_instr[31], if_instr[19:12], if_instr[20], if_instr[30:21], 1'b0};

    // register
    always_comb begin
        unique case ( if_opcode )
        7'b0110111: begin if_rd_en = 1'b1; if_rs1_en = 1'b0; if_rs2_en = 1'b0; end // LUI
        7'b0010111: begin if_rd_en = 1'b1; if_rs1_en = 1'b0; if_rs2_en = 1'b0; end // AUIPC
        7'b1101111: begin if_rd_en = 1'b1; if_rs1_en = 1'b0; if_rs2_en = 1'b0; end // JAL
        7'b1100111: begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b0; end // JALR
        7'b1100011: begin if_rd_en = 1'b0; if_rs1_en = 1'b1; if_rs2_en = 1'b1; end // Branch
        7'b0000011: begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b0; end // Load
        7'b0100011: begin if_rd_en = 1'b0; if_rs1_en = 1'b1; if_rs2_en = 1'b1; end // Store
        7'b0010011: begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b0; end // Arithmetic imm
        7'b0110011: begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b1; end // Arithmetic rs2
        7'b0001111: begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b0; end // FENCE
        7'b1110011: begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b0; end // ECALL/EBREAK
        default:    begin if_rd_en = 1'bx; if_rs1_en = 1'bx; if_rs2_en = 1'bx; end
        endcase
    end

    // stall
    always_ff @(posedge clk) begin
        if ( reset ) begin
            if_stall <= 1'b0;
        end
        else if ( cke ) begin
            if_stall <= if_stall_en;
        end
    end

    always_comb begin
        if_stall_en = 1'b0;
        if ( if_rs1_en && if_rs1_idx == id_rd_idx && id_mem_re ) begin if_stall_en = 1'b1; end
        if ( if_rs2_en && if_rs2_idx == id_rd_idx && id_mem_re ) begin if_stall_en = 1'b1; end
        if ( if_rs1_en && if_rs1_idx == ex_rd_idx && ex_mem_re ) begin if_stall_en = 1'b1; end
        if ( if_rs2_en && if_rs2_idx == ex_rd_idx && ex_mem_re ) begin if_stall_en = 1'b1; end
    end


    // decode
    wire    if_dec_lui    = (if_opcode == 7'b0110111);
    wire    if_dec_auipc  = (if_opcode == 7'b0010111);
    wire    if_dec_jal    = (if_opcode == 7'b1101111);
    wire    if_dec_jalr   = (if_opcode == 7'b1100111 && if_funct3 == 3'b000);
    wire    if_dec_beq    = (if_opcode == 7'b1100011 && if_funct3 == 3'b000);
    wire    if_dec_bne    = (if_opcode == 7'b1100011 && if_funct3 == 3'b001);
    wire    if_dec_blt    = (if_opcode == 7'b1100011 && if_funct3 == 3'b100);
    wire    if_dec_bge    = (if_opcode == 7'b1100011 && if_funct3 == 3'b101);
    wire    if_dec_bltu   = (if_opcode == 7'b1100011 && if_funct3 == 3'b110);
    wire    if_dec_bgeu   = (if_opcode == 7'b1100011 && if_funct3 == 3'b111);
    wire    if_dec_lb     = (if_opcode == 7'b0000011 && if_funct3 == 3'b000);
    wire    if_dec_lh     = (if_opcode == 7'b0000011 && if_funct3 == 3'b001);
    wire    if_dec_lw     = (if_opcode == 7'b0000011 && if_funct3 == 3'b010);
    wire    if_dec_lbu    = (if_opcode == 7'b0000011 && if_funct3 == 3'b100);
    wire    if_dec_lhu    = (if_opcode == 7'b0000011 && if_funct3 == 3'b101);
    wire    if_dec_sb     = (if_opcode == 7'b0100011 && if_funct3 == 3'b000);
    wire    if_dec_sh     = (if_opcode == 7'b0100011 && if_funct3 == 3'b001);
    wire    if_dec_sw     = (if_opcode == 7'b0100011 && if_funct3 == 3'b010);
    wire    if_dec_addi   = (if_opcode == 7'b0010011 && if_funct3 == 3'b000);
    wire    if_dec_slti   = (if_opcode == 7'b0010011 && if_funct3 == 3'b010);
    wire    if_dec_sltiu  = (if_opcode == 7'b0010011 && if_funct3 == 3'b011);
    wire    if_dec_xori   = (if_opcode == 7'b0010011 && if_funct3 == 3'b100);
    wire    if_dec_ori    = (if_opcode == 7'b0010011 && if_funct3 == 3'b110);
    wire    if_dec_andi   = (if_opcode == 7'b0010011 && if_funct3 == 3'b111);
    wire    if_dec_slli   = (if_opcode == 7'b0010011 && if_funct3 == 3'b001 && if_funct7 == 7'b0000000);
    wire    if_dec_srli   = (if_opcode == 7'b0010011 && if_funct3 == 3'b101 && if_funct7 == 7'b0000000);
    wire    if_dec_srai   = (if_opcode == 7'b0010011 && if_funct3 == 3'b101 && if_funct7 == 7'b0100000);
    wire    if_dec_add    = (if_opcode == 7'b0110011 && if_funct3 == 3'b000 && if_funct7 == 7'b0000000);
    wire    if_dec_sub    = (if_opcode == 7'b0110011 && if_funct3 == 3'b000 && if_funct7 == 7'b0100000);
    wire    if_dec_sll    = (if_opcode == 7'b0110011 && if_funct3 == 3'b001 && if_funct7 == 7'b0000000);
    wire    if_dec_slt    = (if_opcode == 7'b0110011 && if_funct3 == 3'b010 && if_funct7 == 7'b0000000);
    wire    if_dec_sltu   = (if_opcode == 7'b0110011 && if_funct3 == 3'b011 && if_funct7 == 7'b0000000);
    wire    if_dec_xor    = (if_opcode == 7'b0110011 && if_funct3 == 3'b100 && if_funct7 == 7'b0000000);
    wire    if_dec_srl    = (if_opcode == 7'b0110011 && if_funct3 == 3'b101 && if_funct7 == 7'b0000000);
    wire    if_dec_sra    = (if_opcode == 7'b0110011 && if_funct3 == 3'b101 && if_funct7 == 7'b0100000);
    wire    if_dec_or     = (if_opcode == 7'b0110011 && if_funct3 == 3'b110 && if_funct7 == 7'b0000000);
    wire    if_dec_and    = (if_opcode == 7'b0110011 && if_funct3 == 3'b111 && if_funct7 == 7'b0000000);
    wire    if_dec_fence  = (if_opcode == 7'b0001111);
    wire    if_dec_ecall  = (if_instr == 32'h00000073);
    wire    if_dec_ebreak = (if_instr == 32'h00100073);



    // -----------------------------------------
    //  Instruction Decode
    // -----------------------------------------

    // control
    always_ff @(posedge clk) begin
        if ( reset ) begin            
            id_pc    <= '0;
            id_instr <= '0;
            id_valid <= 1'b0;
        end
        else if ( id_cke ) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
            id_valid <= if_valid;
        end
    end

    always_ff @(posedge clk) begin
        if ( id_cke ) begin
            id_rs1_en <= if_rs1_en;
            id_rs2_en <= if_rs2_en;
        end
    end

    assign id_opcode  = id_instr[6:0];
    assign id_rd_idx  = id_instr[11:7];
    assign id_rs1_idx = id_instr[19:15];
    assign id_rs2_idx = id_instr[24:20];
    assign id_funct3  = id_instr[14:12];
    assign id_funct7  = id_instr[31:25];
    assign id_imm_i   = id_instr[31:20];
    assign id_imm_s   = {id_instr[31:25], id_instr[11:7]};
    assign id_imm_b   = {id_instr[31], id_instr[7], id_instr[30:25], id_instr[11:8], 1'b0};
    assign id_imm_u   = {id_instr[31:12], 12'd0};
    assign id_imm_j   = {id_instr[31], id_instr[19:12], id_instr[20], id_instr[30:21], 1'b0};

    logic           [11:0]  id_imm_i_u;
    assign id_imm_i_u = id_imm_i;
    

    // register file
    jelly2_register_file
            #(
                .WRITE_PORTS    (1),
                .READ_PORTS     (2),
                .ADDR_WIDTH     (RIDX_WIDTH),
                .DATA_WIDTH     (XLEN),
                .RAM_TYPE       ("distributed"),
                .DEVICE         (DEVICE),
                .SIMULATION     (SIMULATION)
            )
        i_register_file
            (
                .reset,
                .clk,
                .cke            (1'b1),

                .wr_en          (wb_rd_en),
                .wr_addr        (wb_rd_idx),
                .wr_din         (wb_rd_val),

                .rd_en          ({2{id_cke}}),
                .rd_addr        ({if_rs2_idx, if_rs1_idx}),
                .rd_dout        ({id_rs2_val, id_rs1_val})
            );

    
    // instruction decode
    logic    id_dec_lui;
    logic    id_dec_auipc;
    logic    id_dec_jal;
    logic    id_dec_jalr;
    logic    id_dec_beq;
    logic    id_dec_bne;
    logic    id_dec_blt;
    logic    id_dec_bge;
    logic    id_dec_bltu;
    logic    id_dec_bgeu;
    logic    id_dec_lb;
    logic    id_dec_lh;
    logic    id_dec_lw;
    logic    id_dec_lbu;
    logic    id_dec_lhu;
    logic    id_dec_sb;
    logic    id_dec_sh;
    logic    id_dec_sw;
    logic    id_dec_addi;
    logic    id_dec_slti;
    logic    id_dec_sltiu;
    logic    id_dec_xori;
    logic    id_dec_ori;
    logic    id_dec_andi;
    logic    id_dec_slli;
    logic    id_dec_srli;
    logic    id_dec_srai;
    logic    id_dec_add;
    logic    id_dec_sub;
    logic    id_dec_sll;
    logic    id_dec_slt;
    logic    id_dec_sltu;
    logic    id_dec_xor;
    logic    id_dec_srl;
    logic    id_dec_sra;
    logic    id_dec_or;
    logic    id_dec_and;
    logic    id_dec_fence;
    logic    id_dec_ecall;
    logic    id_dec_ebreak;

    always_ff @(posedge clk) begin
        if ( id_cke ) begin
            id_dec_lui    <= if_dec_lui;
            id_dec_auipc  <= if_dec_auipc;
            id_dec_jal    <= if_dec_jal;
            id_dec_jalr   <= if_dec_jalr;
            id_dec_beq    <= if_dec_beq;
            id_dec_bne    <= if_dec_bne;
            id_dec_blt    <= if_dec_blt;
            id_dec_bge    <= if_dec_bge;
            id_dec_bltu   <= if_dec_bltu;
            id_dec_bgeu   <= if_dec_bgeu;
            id_dec_lb     <= if_dec_lb;
            id_dec_lh     <= if_dec_lh;
            id_dec_lw     <= if_dec_lw;
            id_dec_lbu    <= if_dec_lbu;
            id_dec_lhu    <= if_dec_lhu;
            id_dec_sb     <= if_dec_sb;
            id_dec_sh     <= if_dec_sh;
            id_dec_sw     <= if_dec_sw;
            id_dec_addi   <= if_dec_addi;
            id_dec_slti   <= if_dec_slti;
            id_dec_sltiu  <= if_dec_sltiu;
            id_dec_xori   <= if_dec_xori;
            id_dec_ori    <= if_dec_ori;
            id_dec_andi   <= if_dec_andi;
            id_dec_slli   <= if_dec_slli;
            id_dec_srli   <= if_dec_srli;
            id_dec_srai   <= if_dec_srai;
            id_dec_add    <= if_dec_add;
            id_dec_sub    <= if_dec_sub;
            id_dec_sll    <= if_dec_sll;
            id_dec_slt    <= if_dec_slt;
            id_dec_sltu   <= if_dec_sltu;
            id_dec_xor    <= if_dec_xor;
            id_dec_srl    <= if_dec_srl;
            id_dec_sra    <= if_dec_sra;
            id_dec_or     <= if_dec_or;
            id_dec_and    <= if_dec_and;
            id_dec_fence  <= if_dec_fence;
            id_dec_ecall  <= if_dec_ecall;
            id_dec_ebreak <= if_dec_ebreak;
        end
    end

    // memory access
    always_ff @(posedge clk) begin
        if ( reset ) begin
            id_mem_offset   <= 'x;
            id_mem_re       <= 1'b0;
            id_mem_we       <= 1'b0;
            id_mem_size     <= 'x;
            id_mem_unsigned <= 1'bx;
        end
        else if ( id_cke ) begin
            id_mem_offset   <= 'x;
            id_mem_re       <= 1'b0;
            id_mem_we       <= 1'b0;
            id_mem_size     <= 'x;
            id_mem_unsigned <= 1'bx;
            if ( if_valid ) begin
                if ( if_dec_lb || if_dec_lh || if_dec_lw || if_dec_lbu || if_dec_lhu ) begin
                    id_mem_re       <= 1'b1;
                    id_mem_offset   <= 32'(if_imm_i);
                    id_mem_unsigned <= (if_dec_lbu || if_dec_lhu);
                end
                if ( if_dec_sb || if_dec_sh ||  if_dec_sw ) begin
                    id_mem_we     <= 1'b1;
                    id_mem_offset <= 32'(if_imm_s);
                end

                id_mem_size   <= if_funct3[1:0];
            end
        end
    end

    // register destination
    always_ff @(posedge clk) begin
        if ( reset ) begin
            id_rd_en  <= '0;
        end
        else if ( id_cke ) begin
            id_rd_en <= if_rd_en && (if_rd_idx != '0) && if_valid;
        end
    end

    // branch
    always_ff @(posedge clk) begin
        if ( id_cke ) begin
            id_branch_sel <= BRANCH_JAL;
            unique case (1'b1)
            if_dec_jal:     id_branch_sel <= BRANCH_JAL;
            if_dec_jalr:    id_branch_sel <= BRANCH_JALR;
            if_dec_beq:     id_branch_sel <= BRANCH_BEQ;
            if_dec_bne:     id_branch_sel <= BRANCH_BNE;
            if_dec_blt:     id_branch_sel <= BRANCH_BLT;
            if_dec_bge:     id_branch_sel <= BRANCH_BGE;
            if_dec_bltu:    id_branch_sel <= BRANCH_BLTU;
            if_dec_bgeu:    id_branch_sel <= BRANCH_BGEU;
            default:        id_branch_sel <= BRANCH_JAL;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if ( id_cke ) begin
            id_branch_pc0 <= if_pc + PC_WIDTH'(4);
            id_branch_pc1 <= if_pc + PC_WIDTH'(if_imm_b);
            
            if ( if_dec_jal ) begin
                id_branch_pc0 <= if_pc + PC_WIDTH'(if_imm_j);
            end
        end
    end



    // -----------------------------------------
    //  Execution
    // -----------------------------------------

    logic   ex_expect_valid;
    assign ex_expect_valid = ((ex_expect_pc == id_pc) && id_valid);

    // control
    always_ff @(posedge clk) begin
        if ( reset ) begin
            ex_pc        <= INIT_PC_ADDR;
            ex_expect_pc <= INIT_PC_ADDR;
            ex_instr     <= 'x;
            ex_valid     <= 1'b0;
        end
        else if ( ex_cke ) begin
            if ( ex_expect_valid ) begin
                ex_pc        <= ex_expect_pc;
                ex_expect_pc <= ex_branch_pc; 
                ex_instr     <= id_instr;
                ex_valid     <= 1'b1;
            end
            else begin
                ex_pc    <= 'x;
                ex_instr <= 'x;
                ex_valid <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if ( ex_cke ) begin
            ex_rs1_en  <= id_rs1_en;
            ex_rs1_idx <= id_rs1_idx;
            ex_rs1_val <= ex_fwd_rs1_val;
            ex_rs2_en  <= id_rs2_en;
            ex_rs2_idx <= id_rs2_idx;
            ex_rs2_val <= ex_fwd_rs2_val;
        end
    end

    // forwarding
    always_ff @(posedge clk) begin
        if ( ex_cke ) begin
            automatic logic  [RIDX_WIDTH-1:0]   rs1_idx;
            automatic logic  [RIDX_WIDTH-1:0]   rs2_idx;
            rs1_idx = if_rs1_idx;
            rs2_idx = if_rs2_idx;

            ex_fwd_rs1_stage <= 2'd0;
            if ( ma_rd_idx == rs1_idx && ma_rd_en ) begin ex_fwd_rs1_stage <= 2'd3; end
            if ( ex_rd_idx == rs1_idx && ex_rd_en ) begin ex_fwd_rs1_stage <= 2'd2; end
            if ( id_rd_idx == rs1_idx && id_rd_en && ex_expect_valid) begin ex_fwd_rs1_stage <= 2'd1; end

            ex_fwd_rs2_stage <= 2'd0;
            if ( ma_rd_idx == rs2_idx && ma_rd_en ) begin ex_fwd_rs2_stage <= 2'd3; end
            if ( ex_rd_idx == rs2_idx && ex_rd_en ) begin ex_fwd_rs2_stage <= 2'd2; end
            if ( id_rd_idx == rs2_idx && id_rd_en && ex_expect_valid ) begin ex_fwd_rs2_stage <= 2'd1; end
        end
    end

    always_comb begin
        case ( ex_fwd_rs1_stage )
        2'd0:   ex_fwd_rs1_val = id_rs1_val;
        2'd1:   ex_fwd_rs1_val = ex_rd_val;
        2'd2:   ex_fwd_rs1_val = ma_rd_val;
        2'd3:   ex_fwd_rs1_val = wb_rd_val;
        endcase
        ex_fwd_rs1_val_u = ex_fwd_rs1_val;
    end

    always_comb begin
        ex_fwd_rs2_val = 'x;
        case ( ex_fwd_rs2_stage )
        2'd0:   ex_fwd_rs2_val = id_rs2_val;
        2'd1:   ex_fwd_rs2_val = ex_rd_val;
        2'd2:   ex_fwd_rs2_val = ma_rd_val;
        2'd3:   ex_fwd_rs2_val = wb_rd_val;
        endcase
        ex_fwd_rs2_val_u = ex_fwd_rs2_val;
    end

    // conditions
    wire ex_cond_eq  = (ex_fwd_rs1_val == ex_fwd_rs2_val);
    wire ex_cond_ne  = (ex_fwd_rs1_val != ex_fwd_rs2_val);
    wire ex_cond_lt  = (ex_fwd_rs1_val  < ex_fwd_rs2_val);
    wire ex_cond_ge  = (ex_fwd_rs1_val >= ex_fwd_rs2_val);
    wire ex_cond_ltu = ($unsigned(ex_fwd_rs1_val)  < $unsigned(ex_fwd_rs2_val));
    wire ex_cond_geu = ($unsigned(ex_fwd_rs1_val) >= $unsigned(ex_fwd_rs2_val));

    // branch
    always_comb begin
        ex_branch_pc = id_branch_pc0;
        case (id_branch_sel)
        BRANCH_JAL:     begin ex_branch_pc = id_branch_pc0; end
        BRANCH_JALR:    begin ex_branch_pc = PC_WIDTH'(ex_fwd_rs1_val) + PC_WIDTH'(id_imm_i); end
        BRANCH_BEQ:     if ( ex_cond_eq  ) begin ex_branch_pc = id_branch_pc1; end
        BRANCH_BNE:     if ( ex_cond_ne  ) begin ex_branch_pc = id_branch_pc1; end
        BRANCH_BLT:     if ( ex_cond_lt  ) begin ex_branch_pc = id_branch_pc1; end
        BRANCH_BGE:     if ( ex_cond_ge  ) begin ex_branch_pc = id_branch_pc1; end
        BRANCH_BLTU:    if ( ex_cond_ltu ) begin ex_branch_pc = id_branch_pc1; end
        BRANCH_BGEU:    if ( ex_cond_geu ) begin ex_branch_pc = id_branch_pc1; end
        endcase
    end

    // alu
    logic   signed  [31:0]  ex_rd_wdata_alu;
    always_ff @(posedge clk) begin
        if ( ex_cke ) begin
            ex_rd_val <= 'x;
            unique case (1'b1)
            id_dec_lui  : ex_rd_val <= id_imm_u;
            id_dec_auipc: ex_rd_val <= id_imm_u + 32'(id_pc);
            id_dec_jal  : ex_rd_val <= 32'(id_pc) + 32'd4;
            id_dec_jalr : ex_rd_val <= 32'(id_pc) + 32'd4;
            id_dec_addi : ex_rd_val <= ex_fwd_rs1_val    + 32'(id_imm_i);
            id_dec_slti : ex_rd_val <= (ex_fwd_rs1_val   < 32'(id_imm_i)  ) ? 32'd1 : 32'd0;
            id_dec_sltiu: ex_rd_val <= (ex_fwd_rs1_val_u < 32'(id_imm_i_u)) ? 32'd1 : 32'd0;
            id_dec_xori : ex_rd_val <= ex_fwd_rs1_val    ^ 32'(id_imm_i);
            id_dec_ori  : ex_rd_val <= ex_fwd_rs1_val    | 32'(id_imm_i);
            id_dec_andi : ex_rd_val <= ex_fwd_rs1_val    & 32'(id_imm_i);
            id_dec_slli : ex_rd_val <= ex_fwd_rs1_val   << id_imm_i_u[4:0];
            id_dec_srli : ex_rd_val <= ex_fwd_rs1_val_u >> id_imm_i_u[4:0];
            id_dec_srai : ex_rd_val <= ex_fwd_rs1_val  >>> id_imm_i_u[4:0];
            id_dec_add  : ex_rd_val <= ex_fwd_rs1_val    + ex_fwd_rs2_val;
            id_dec_sub  : ex_rd_val <= ex_fwd_rs1_val    - ex_fwd_rs2_val;
            id_dec_sll  : ex_rd_val <= ex_fwd_rs1_val   << ex_fwd_rs2_val_u[4:0];
            id_dec_slt  : ex_rd_val <= (ex_fwd_rs1_val   < ex_fwd_rs2_val  ) ? 32'd1 : 32'd0;
            id_dec_sltu : ex_rd_val <= (ex_fwd_rs1_val_u < ex_fwd_rs2_val_u) ? 32'd1 : 32'd0;
            id_dec_xor  : ex_rd_val <= ex_fwd_rs1_val    ^ ex_fwd_rs2_val;
            id_dec_srl  : ex_rd_val <= ex_fwd_rs1_val_u >> ex_fwd_rs2_val_u[4:0];
            id_dec_sra  : ex_rd_val <= ex_fwd_rs1_val  >>> ex_fwd_rs2_val_u[4:0];
            id_dec_or   : ex_rd_val <= ex_fwd_rs1_val    | ex_fwd_rs2_val;
            id_dec_and  : ex_rd_val <= ex_fwd_rs1_val    & ex_fwd_rs2_val;
            default: ;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin            
            ex_rd_en     <= 1'b0;
            ex_rd_idx    <= 'x;
        end
        else if ( ex_cke ) begin
            ex_rd_en     <= id_rd_en & ex_expect_valid;
            ex_rd_idx    <= id_rd_idx;
        end
    end


    function    [SEL_WIDTH-1:0]  sel_mask(input [SIZE_WIDTH-1:0] size);
    begin
        sel_mask = 'x;
        if ( XLEN >=   8 && int'(size) == 0 )  begin sel_mask = SEL_WIDTH'({ 1{1'b1}}); end
        if ( XLEN >=  16 && int'(size) == 1 )  begin sel_mask = SEL_WIDTH'({ 2{1'b1}}); end
        if ( XLEN >=  32 && int'(size) == 2 )  begin sel_mask = SEL_WIDTH'({ 4{1'b1}}); end
        if ( XLEN >=  64 && int'(size) == 3 )  begin sel_mask = SEL_WIDTH'({ 8{1'b1}}); end
        if ( XLEN >= 128 && int'(size) == 4 )  begin sel_mask = SEL_WIDTH'({16{1'b1}}); end
    end
    endfunction

    // memory access
    always_ff @(posedge clk) begin
        if ( reset ) begin
            ex_mem_en        <= 1'b0;
            ex_mem_re        <= 1'b0;
            ex_mem_we        <= 1'b0;
            ex_mem_addr      <= 'x;
            ex_mem_size      <= 'x;
            ex_mem_sel       <= '0;
            ex_mem_rsel      <= '0;
            ex_mem_wsel      <= '0;
            ex_mem_wdata     <= 'x;
            ex_mem_unsigned  <= 1'bx;

            ex_dtcm_en       <= 1'b0;
            ex_dtcm_re       <= 1'b0;
            ex_dtcm_wsel     <= '0;
            ex_dtcm_addr     <= 'x;
            ex_dtcm_wdata    <= 'x;

            ex_mmio_en       <= 1'b0;
            ex_mmio_re       <= 1'b0;
            ex_mmio_we       <= 1'b0;
            ex_mmio_addr     <= 'x;
            ex_mmio_size     <= 'x;
            ex_mmio_sel      <= '0;
            ex_mmio_rsel     <= '0;
            ex_mmio_wsel     <= '0;
            ex_mmio_wdata    <= 'x;
        end
        else if ( ex_cke ) begin
            ex_mem_en        <= 1'b0;
            ex_mem_re        <= 1'b0;
            ex_mem_we        <= 1'b0;
            ex_mem_addr      <= 'x;
            ex_mem_size      <= 'x;
            ex_mem_sel       <= '0;
            ex_mem_rsel      <= '0;
            ex_mem_wsel      <= '0;
            ex_mem_wdata     <= 'x;
            ex_mem_unsigned  <= 1'bx;

            ex_dtcm_en       <= 1'b0;
            ex_dtcm_re       <= 1'b0;
            ex_dtcm_wsel     <= '0;
            ex_dtcm_addr     <= 'x;
            ex_dtcm_wdata    <= 'x;
            
            ex_mmio_en       <= 1'b0;
            ex_mmio_re       <= 1'b0;
            ex_mmio_we       <= 1'b0;
            ex_mmio_addr     <= 'x;
            ex_mmio_size     <= 'x;
            ex_mmio_sel      <= '0;
            ex_mmio_rsel     <= '0;
            ex_mmio_wsel     <= '0;
            ex_mmio_wdata    <= 'x;
            
            if ( ex_expect_valid ) begin
                automatic   logic   [XLEN-1:0]      mem_addr;
                automatic   logic   [XLEN-1:0]      mem_wdata;
                automatic   logic   [SEL_WIDTH-1:0] mem_sel;

                mem_addr = ex_fwd_rs1_val + id_mem_offset;
                
                mem_wdata = ex_fwd_rs2_val;
                if ( XLEN >=  16 && mem_addr[0] )    begin   mem_wdata = mem_wdata <<  8; end;
                if ( XLEN >=  32 && mem_addr[1] )    begin   mem_wdata = mem_wdata << 16; end;
                if ( XLEN >=  64 && mem_addr[2] )    begin   mem_wdata = mem_wdata << 32; end;
                if ( XLEN >= 128 && mem_addr[3] )    begin   mem_wdata = mem_wdata << 64; end;

                mem_sel   = sel_mask(id_mem_size);
                if ( XLEN >=  16 && mem_addr[0] )    begin   mem_sel = mem_sel << 1; end;
                if ( XLEN >=  32 && mem_addr[1] )    begin   mem_sel = mem_sel << 2; end;
                if ( XLEN >=  64 && mem_addr[2] )    begin   mem_sel = mem_sel << 4; end;
                if ( XLEN >= 128 && mem_addr[3] )    begin   mem_sel = mem_sel << 8; end;

                ex_mem_en       <= id_mem_re || id_mem_we;
                ex_mem_re       <= id_mem_re;
                ex_mem_we       <= id_mem_we;
                ex_mem_addr     <= mem_addr;
                ex_mem_size     <= id_mem_size;
                ex_mem_sel      <= mem_sel;
                ex_mem_rsel     <= id_mem_re ? mem_sel : '0;
                ex_mem_wsel     <= id_mem_we ? mem_sel : '0;
                ex_mem_wdata    <= mem_wdata;
                ex_mem_unsigned <= id_mem_unsigned;

                if ( (mem_addr & TCM_DECODE_MASK) == TCM_DECODE_ADDR ) begin
                    ex_dtcm_en    <= id_mem_re || id_mem_we;
                    ex_dtcm_re    <= id_mem_re;
                    ex_dtcm_addr  <= TCM_ADDR_WIDTH'(mem_addr >> 2);
                    ex_dtcm_wsel  <= id_mem_we ? mem_sel : '0;
                    ex_dtcm_wdata <= mem_wdata;
                end

                if ( (mem_addr & MMIO_DECODE_MASK) == MMIO_DECODE_ADDR ) begin
                    ex_mmio_en    <= id_mem_re || id_mem_we;
                    ex_mmio_re    <= id_mem_re;
                    ex_mmio_we    <= id_mem_we;
                    ex_mmio_addr  <= MMIO_ADDR_WIDTH'(mem_addr);
                    ex_mmio_size  <= id_mem_size;
                    ex_mmio_sel   <= mem_sel;
                    ex_mmio_rsel  <= id_mem_re ? mem_sel : '0;
                    ex_mmio_wsel  <= id_mem_we ? mem_sel : '0;
                    ex_mmio_wdata <= mem_wdata;
                end
            end
        end
    end


    // -----------------------------------------
    //  Memory Access
    // -----------------------------------------

    always_ff @(posedge clk) begin
        if ( reset ) begin
           ma_valid        <= 1'b0;
           ma_pc           <= 'x;
           ma_instr        <= 'x;

           ma_rd_en        <= 1'b0;
           ma_rd_idx       <= 'x;
           ma_rd_val       <= 'x;

           ma_mem_re       <= 1'b0;
           ma_mem_addr     <= 'x;
           ma_mem_size     <= 'x;
           ma_mem_unsigned <= 'x;
           ma_dtcm_re      <= 'x;
           ma_mmio_re      <= 'x;
        end
        else if ( ma_cke ) begin
           ma_valid        <= ex_valid;
           ma_pc           <= ex_pc;
           ma_instr        <= ex_instr;

           ma_rd_en        <= ex_rd_en;
           ma_rd_idx       <= ex_rd_idx;
           ma_rd_val       <= ex_rd_val;

           ma_mem_re       <= ex_mem_re;
           ma_mem_addr     <= ex_mem_addr;
           ma_mem_size     <= ex_mem_size;
           ma_mem_unsigned <= ex_mem_unsigned;
           ma_dtcm_re      <= ex_dtcm_re;
           ma_mmio_re      <= ex_mmio_re;
        end
    end

    always_ff @(posedge clk) begin
        if ( ma_cke ) begin
            ma_rs1_en    <= ex_rs1_en;
            ma_rs1_idx   <= ex_rs1_idx;
            ma_rs1_val   <= ex_rs1_val;
            ma_rs2_en    <= ex_rs2_en;
            ma_rs2_idx   <= ex_rs2_idx;
            ma_rs2_val   <= ex_rs2_val;
            ma_mem_sel   <= ex_mem_sel;
            ma_mem_we    <= ex_mem_we;
            ma_mem_wdata <= ex_mem_wdata;
        end
    end


    // data-bus access
    assign dtcm_en      = ex_dtcm_en;
    assign dtcm_addr    = ex_dtcm_addr;
    assign dtcm_wsel    = ex_dtcm_wsel;
    assign dtcm_wdata   = ex_dtcm_wdata;

    assign mmio_en      = ex_mmio_en;
    assign mmio_re      = ex_mmio_re;
    assign mmio_we      = ex_mmio_we;
    assign mmio_size    = ex_mmio_size;
    assign mmio_addr    = ex_mmio_addr;
    assign mmio_sel     = ex_mmio_sel;
    assign mmio_rsel    = ex_mmio_rsel;
    assign mmio_wsel    = ex_mmio_wsel;
    assign mmio_wdata   = ex_mmio_wdata;

    assign ma_mem_rdata = ma_dtcm_re ? dtcm_rdata : 
                          ma_mmio_re ? mmio_rdata : 'x;


    // -----------------------------------------
    //  Write back
    // -----------------------------------------ma

    always_ff @(posedge clk) begin
        if ( reset ) begin
            wb_valid <= 1'b0;
            wb_pc    <= 'x;
            wb_instr <= 'x;
        end
        else if ( wb_cke ) begin
            wb_valid <= ma_valid;
            wb_pc    <= ma_pc;
            wb_instr <= ma_instr;
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            wb_rd_en  <= 1'b0;
            wb_rd_idx <= 'x;
            wb_rd_val <= 'x;
        end
        else if ( wb_cke ) begin
            automatic   logic   [XLEN-1:0]  mem_rdata;
            mem_rdata = ma_mem_rdata;

            if ( XLEN >=  16 && ma_mem_addr[0] )    begin   mem_rdata = mem_rdata >>  8; end;
            if ( XLEN >=  32 && ma_mem_addr[1] )    begin   mem_rdata = mem_rdata >> 16; end;
            if ( XLEN >=  64 && ma_mem_addr[2] )    begin   mem_rdata = mem_rdata >> 32; end;
            if ( XLEN >= 128 && ma_mem_addr[3] )    begin   mem_rdata = mem_rdata >> 64; end;

            if ( ma_mem_unsigned ) begin
                if ( XLEN >=  8 && int'(ma_mem_size) == 0 )  begin   mem_rdata = XLEN'($unsigned(mem_rdata[ 7:0])); end
                if ( XLEN >= 16 && int'(ma_mem_size) == 1 )  begin   mem_rdata = XLEN'($unsigned(mem_rdata[15:0])); end
                if ( XLEN >= 32 && int'(ma_mem_size) == 2 )  begin   mem_rdata = XLEN'($unsigned(mem_rdata[31:0])); end
//              if ( XLEN >= 64 && int'(ma_mem_size) == 3 )  begin   mem_rdata = XLEN'($unsigned(mem_rdata[63:0])); end
            end
            else begin
                if ( XLEN >=  8 && int'(ma_mem_size) == 0 )  begin   mem_rdata = XLEN'($signed(mem_rdata[ 7:0])); end
                if ( XLEN >= 16 && int'(ma_mem_size) == 1 )  begin   mem_rdata = XLEN'($signed(mem_rdata[15:0])); end
                if ( XLEN >= 32 && int'(ma_mem_size) == 2 )  begin   mem_rdata = XLEN'($signed(mem_rdata[31:0])); end
//              if ( XLEN >= 64 && int'(ma_mem_size) == 3 )  begin   mem_rdata = XLEN'($signed(mem_rdata[63:0])); end
            end

            wb_rd_en   <= ma_rd_en;
            wb_rd_idx  <= ma_rd_idx;
            wb_rd_val  <= ma_mem_re ? mem_rdata : ma_rd_val;
        end
    end

    always_ff @(posedge clk) begin
        if ( wb_cke ) begin
            wb_rs1_en  <= ma_rs1_en;
            wb_rs1_idx <= ma_rs1_en ? ma_rs1_idx : '0;
            wb_rs1_val <= ma_rs1_en ? ma_rs1_val : '0;
            wb_rs2_en  <= ma_rs2_en;
            wb_rs2_idx <= ma_rs2_en ? ma_rs2_idx : '0;
            wb_rs2_val <= ma_rs2_en ? ma_rs2_val : '0;

            wb_mem_we    <= ma_mem_we;
            wb_mem_re    <= ma_mem_re;
            wb_mem_addr  <= ma_mem_addr;
            wb_mem_sel   <= ma_mem_sel;
            wb_mem_wdata <= ma_mem_wdata;
            wb_mem_rdata <= ma_mem_rdata;
        end
    end


    // -----------------------------------------
    //  Trace (simulation only)
    // -----------------------------------------

    generate
    if ( SIMULATION ) begin : simulation

        int     exe_counter;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                exe_counter <= 0;
            end
            else if ( wb_cke ) begin
                if ( wb_valid ) begin
                    exe_counter <= exe_counter + 1;
                end
            end
        end


        if ( LOG_EXE_ENABLE ) begin
            int     fp_trace;
            initial begin
                fp_trace = $fopen(LOG_EXE_FILE, "w");
            end
            always_ff @(posedge clk) begin
                if ( !reset ) begin
                    if ( cke ) begin
                        if ( wb_cke && wb_valid ) begin
                            automatic logic [RIDX_WIDTH-1:0]    rd_idx;
                            automatic logic [XLEN-1:0]          rd_val;
                            rd_idx = wb_rd_en ? wb_rd_idx : '0;
                            rd_val = wb_rd_en ? wb_rd_val : '0;

                            $fdisplay(fp_trace, "pc:%08x instr:%08x rd(%2d):%08x rs1(%2d):%08x rs2(%2d):%08x",
                                    wb_pc, wb_instr, rd_idx, rd_val, wb_rs1_idx, wb_rs1_val, wb_rs2_idx, wb_rs2_val);
                            
                            /*
                            if ( wb_mem_we ) begin 
                                $fdisplay(fp_trace, "  write  addr:%08x wdata:%08x sel:%b", wb_mem_addr, wb_mem_wdata, wb_mem_sel);
                            end
                            if ( wb_mem_re ) begin 
                                $fdisplay(fp_trace, "  read   addr:%08x rdata:%08x sel:%b", wb_mem_addr, wb_mem_rdata, wb_mem_sel);
                            end
                            */
                        end
                    end
                end
            end
        end

        if ( LOG_MEM_ENABLE ) begin
            int     fp_dbus;
            initial begin
                fp_dbus = $fopen(LOG_MEM_FILE, "w");
            end
            always_ff @(posedge clk) begin
                if ( !reset ) begin
                    if ( cke ) begin
                        if ( ma_mem_re ) begin
                            $fdisplay(fp_dbus, "%10d read  addr:%08x rdata:%08x sel:%b  (pc:%08x instr:%08x)",
                                    exe_counter, ma_mem_addr, dtcm_rdata, ma_mem_sel, ma_pc, ma_instr);
                        end
                        if ( ex_mem_we ) begin
                            $fdisplay(fp_dbus, "%10d write addr:%08x wdata:%08x sel:%b  (pc:%08x instr:%08x)",
                                    exe_counter, ex_mem_addr, ex_mem_wdata, ex_mem_sel, ex_pc, ex_instr);
                        end
                    end
                end
            end
        end
    end
    endgenerate

endmodule


`default_nettype wire


// End of file
