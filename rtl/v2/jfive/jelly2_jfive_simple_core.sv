// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// RISC-V(RV32I 3-stage pipelines)
module jelly2_jfive_simple_core
        #(
            parameter   int                     IBUS_ADDR_WIDTH = 14,
            parameter   int                     DBUS_ADDR_WIDTH = 32,
            parameter   int                     PC_WIDTH        = IBUS_ADDR_WIDTH,
            parameter   bit   [PC_WIDTH-1:0]    INIT_PC_ADDR    = PC_WIDTH'(32'h80000000),

            parameter                           DEVICE           = "RTL",

            parameter   bit                     SIMULATION       = 1'b0,
            parameter   bit                     LOG_EXE_ENABLE   = 1'b0,
            parameter                           LOG_EXE_FILE     = "jfive_exe_log.txt",
            parameter   bit                     LOG_MEM_ENABLE   = 1'b0,
            parameter                           LOG_MEM_FILE     = "jfive_mem_log.txt"
        )
        (
            input   var logic                           reset,
            input   var logic                           clk,
            input   var logic                           cke,

            output  var logic   [IBUS_ADDR_WIDTH-1:0]   ibus_addr,
            input   var logic   [31:0]                  ibus_rdata,

            output  var logic   [DBUS_ADDR_WIDTH-1:0]   dbus_addr,
            output  var logic                           dbus_rd,
            output  var logic                           dbus_wr,
            output  var logic   [3:0]                   dbus_sel,
            output  var logic   [31:0]                  dbus_wdata,
            input   var logic   [31:0]                  dbus_rdata
        );

    // -----------------------------------------
    //  Signals
    // -----------------------------------------

    // parameters
    localparam  int     XLEN        = 32;
    localparam  int     SEL_WIDTH   = XLEN / 8;
    localparam  int     SIZE_WIDTH  = 2;
    localparam  int     INSTR_WIDTH = 32;
    localparam  int     RIDX_WIDTH  = 5;
    localparam  int     SHAMT_WIDTH = $clog2(XLEN);

    // enums
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

    typedef enum logic [2:0] {
        ALU_OP_ADD,
        ALU_OP_SUB,
        ALU_OP_SLL,
        ALU_OP_SRL,
        ALU_OP_SRA,
        ALU_OP_AND,
        ALU_OP_OR,
        ALU_OP_XOR
    } alu_op_t;

    typedef enum logic [1:0] {
        ALU_SEL0_RS1,
        ALU_SEL0_ZERO,
        ALU_SEL0_SLT,
        ALU_SEL0_SLTU
    } alu_sel0_t;

    typedef enum logic [0:0] {
        ALU_SEL1_RS2,
        ALU_SEL1_VAL
    } alu_sel1_t;


    // Program counter
    logic           [PC_WIDTH-1:0]          pc_pc;

    //  Instruction Fetch           
    logic           [PC_WIDTH-1:0]          if_pc;
    logic           [INSTR_WIDTH-1:0]       if_instr;
    logic                                   if_valid;

    logic           [6:0]                   if_opcode;
    logic           [RIDX_WIDTH-1:0]        if_rd_idx;
    logic           [RIDX_WIDTH-1:0]        if_rs1_idx;
    logic           [RIDX_WIDTH-1:0]        if_rs2_idx;
    logic           [2:0]                   if_funct3;
    logic           [6:0]                   if_funct7;

    logic   signed  [11:0]                  if_imm_i;
    logic   signed  [11:0]                  if_imm_s;
    logic   signed  [12:0]                  if_imm_b;
    logic   signed  [31:0]                  if_imm_u;
    logic   signed  [20:0]                  if_imm_j;

    logic                                   if_rd_en;
    logic                                   if_rs1_en;
    logic                                   if_rs2_en;


    //  Instruction Decode  
    logic           [PC_WIDTH-1:0]          id_pc;
    logic           [INSTR_WIDTH-1:0]       id_instr;
    logic                                   id_valid;

    logic           [6:0]                   id_opcode;
    logic                                   id_rd_en;
    logic           [RIDX_WIDTH-1:0]        id_rd_idx;
    logic                                   id_rs1_en;
    logic           [4:0]                   id_rs1_idx;
    logic   signed  [XLEN-1:0]              id_rs1_val;
    logic                                   id_rs2_en;
    logic           [RIDX_WIDTH-1:0]        id_rs2_idx;
    logic   signed  [XLEN-1:0]              id_rs2_val;
    logic           [2:0]                   id_funct3;
    logic           [6:0]                   id_funct7;

    logic   signed  [11:0]                  id_imm_i;
    logic   signed  [11:0]                  id_imm_s;
    logic   signed  [12:0]                  id_imm_b;
    logic   signed  [31:0]                  id_imm_u;
    logic   signed  [20:0]                  id_imm_j;

    logic                                   id_branch_en;
    logic           [PC_WIDTH-1:0]          id_branch_pc;
    branch_sel_t                            id_branch_sel;

    logic   signed  [XLEN-1:0]              id_mem_offset;
    logic                                   id_mem_rd;
    logic                                   id_mem_wr;
    logic           [3:0]                   id_mem_sel;
    logic           [1:0]                   id_mem_size;
    logic                                   id_mem_unsigned;

    logic                                   id_rs1_forward;
    logic                                   id_rs2_forward;


    //  Execution   
    logic   signed  [XLEN-1:0]              ex_fwd_rs1_val;
    logic   signed  [XLEN-1:0]              ex_fwd_rs2_val;
    logic           [XLEN-1:0]              ex_fwd_rs1_val_u;
    logic           [XLEN-1:0]              ex_fwd_rs2_val_u;

    logic                                   ex_valid;
    logic           [PC_WIDTH-1:0]          ex_pc;
    logic           [INSTR_WIDTH-1:0]       ex_instr;

    logic           [PC_WIDTH-1:0]          ex_branch_pc;
    logic                                   ex_branch_valid;

    logic                                   ex_rd_en;
    logic           [RIDX_WIDTH-1:0]        ex_rd_idx;
    logic           [XLEN-1:0]              ex_rd_val;
    logic                                   ex_rs1_en;
    logic           [RIDX_WIDTH-1:0]        ex_rs1_idx;
    logic           [XLEN-1:0]              ex_rs1_val;
    logic                                   ex_rs2_en;
    logic           [RIDX_WIDTH-1:0]        ex_rs2_idx;
    logic           [XLEN-1:0]              ex_rs2_val;



    // -----------------------------------------
    //  Program counter
    // -----------------------------------------

    always_ff @(posedge clk) begin
        if ( reset ) begin
            pc_pc <= INIT_PC_ADDR;
        end
        else if ( cke ) begin
            if ( ex_branch_valid ) begin
                pc_pc <= ex_branch_pc;
            end
            else begin
                pc_pc <= pc_pc + PC_WIDTH'(4);
            end
        end
    end


    // -----------------------------------------
    //  Instruction Fetch
    // -----------------------------------------

    // PC & Instruction
    always_ff @(posedge clk) begin
        if ( reset ) begin            
            if_pc    <= '0;
            if_valid <= 1'b0;
        end
        else if ( cke ) begin
            if_pc    <= pc_pc;
            if_valid <= 1'b1 & ~ex_branch_valid;
        end
    end

    // Instruction Fetch
    assign ibus_addr = IBUS_ADDR_WIDTH'(pc_pc);
    assign if_instr  = ibus_rdata;

    // decocde
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

    // decode
    wire    if_dec_lui    = (if_opcode == 7'b0110111);
    wire    if_dec_auipc  = (if_opcode == 7'b0010111);
    wire    if_dec_jal    = (if_opcode == 7'b1101111);
    wire    if_dec_jalr   = (if_opcode == 7'b1100111); // (if_funct3 == 3'b000);
    wire    if_dec_branch = (if_opcode == 7'b1100011);
    wire    if_dec_beq    = (if_dec_branch && if_funct3 == 3'b000);
    wire    if_dec_bne    = (if_dec_branch && if_funct3 == 3'b001);
    wire    if_dec_blt    = (if_dec_branch && if_funct3 == 3'b100);
    wire    if_dec_bge    = (if_dec_branch && if_funct3 == 3'b101);
    wire    if_dec_bltu   = (if_dec_branch && if_funct3 == 3'b110);
    wire    if_dec_bgeu   = (if_dec_branch && if_funct3 == 3'b111);
    wire    if_dec_load   = (if_opcode == 7'b0000011);
    wire    if_dec_lb     = (if_dec_load && if_funct3 == 3'b000);
    wire    if_dec_lh     = (if_dec_load && if_funct3 == 3'b001);
    wire    if_dec_lw     = (if_dec_load && if_funct3 == 3'b010);
    wire    if_dec_lbu    = (if_dec_load && if_funct3 == 3'b100);
    wire    if_dec_lhu    = (if_dec_load && if_funct3 == 3'b101);
    wire    if_dec_store  = (if_opcode == 7'b0100011);
    wire    if_dec_sb     = (if_dec_store && if_funct3 == 3'b000);
    wire    if_dec_sh     = (if_dec_store && if_funct3 == 3'b001);
    wire    if_dec_sw     = (if_dec_store && if_funct3 == 3'b010);
    wire    if_dec_alui   = (if_opcode == 7'b0010011);
    wire    if_dec_addi   = (if_dec_alui && if_funct3 == 3'b000);
    wire    if_dec_slti   = (if_dec_alui && if_funct3 == 3'b010);
    wire    if_dec_sltiu  = (if_dec_alui && if_funct3 == 3'b011);
    wire    if_dec_xori   = (if_dec_alui && if_funct3 == 3'b100);
    wire    if_dec_ori    = (if_dec_alui && if_funct3 == 3'b110);
    wire    if_dec_andi   = (if_dec_alui && if_funct3 == 3'b111);
    wire    if_dec_slli   = (if_dec_alui && if_funct3 == 3'b001 && if_funct7[5] == 1'b0);   // if_funct7 == 7'b0000000);
    wire    if_dec_srli   = (if_dec_alui && if_funct3 == 3'b101 && if_funct7[5] == 1'b0);   // if_funct7 == 7'b0000000);
    wire    if_dec_srai   = (if_dec_alui && if_funct3 == 3'b101 && if_funct7[5] == 1'b1);   // if_funct7 == 7'b0100000);
    wire    if_dec_alu    = (if_opcode == 7'b0110011);
    wire    if_dec_add    = (if_dec_alu && if_funct3 == 3'b000  && if_funct7[5] == 1'b0);   // (if_funct7 == 7'b0000000);
    wire    if_dec_sub    = (if_dec_alu && if_funct3 == 3'b000  && if_funct7[5] == 1'b1);   // (if_funct7 == 7'b0100000);
    wire    if_dec_sll    = (if_dec_alu && if_funct3 == 3'b001);                            // (if_funct7 == 7'b0000000);
    wire    if_dec_slt    = (if_dec_alu && if_funct3 == 3'b010);                            // (if_funct7 == 7'b0000000);
    wire    if_dec_sltu   = (if_dec_alu && if_funct3 == 3'b011);                            // (if_funct7 == 7'b0000000);
    wire    if_dec_xor    = (if_dec_alu && if_funct3 == 3'b100);                            // (if_funct7 == 7'b0000000);
    wire    if_dec_srl    = (if_dec_alu && if_funct3 == 3'b101 && if_funct7[5] == 1'b0);    // (if_funct7 == 7'b0000000);
    wire    if_dec_sra    = (if_dec_alu && if_funct3 == 3'b101 && if_funct7[5] == 1'b1);    // (if_funct7 == 7'b0100000);
    wire    if_dec_or     = (if_dec_alu && if_funct3 == 3'b110);                            // (if_funct7 == 7'b0000000);
    wire    if_dec_and    = (if_dec_alu && if_funct3 == 3'b111);                            // (if_funct7 == 7'b0000000);
    wire    if_dec_fence  = (if_opcode == 7'b0001111);
    wire    if_dec_ecall  = (if_opcode == 7'b1110011 && if_instr[20] == 1'b0);              // (if_instr == 32'h00000073);
    wire    if_dec_ebreak = (if_opcode == 7'b1110011 && if_instr[20] == 1'b1);              // (if_instr == 32'h00100073);


    // register enable
    always_comb begin
        if_rd_en  = 1'bx;
        if_rs1_en = 1'bx;
        if_rs2_en = 1'bx;
        if ( if_dec_lui    ) begin if_rd_en = 1'b1; if_rs1_en = 1'b0; if_rs2_en = 1'b0; end // LUI
        if ( if_dec_auipc  ) begin if_rd_en = 1'b1; if_rs1_en = 1'b0; if_rs2_en = 1'b0; end // AUIPC
        if ( if_dec_jal    ) begin if_rd_en = 1'b1; if_rs1_en = 1'b0; if_rs2_en = 1'b0; end // JAL
        if ( if_dec_jalr   ) begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b0; end // JALR
        if ( if_dec_branch ) begin if_rd_en = 1'b0; if_rs1_en = 1'b1; if_rs2_en = 1'b1; end // Branch
        if ( if_dec_load   ) begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b0; end // Load
        if ( if_dec_store  ) begin if_rd_en = 1'b0; if_rs1_en = 1'b1; if_rs2_en = 1'b1; end // Store
        if ( if_dec_alui   ) begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b0; end // Arithmetic imm
        if ( if_dec_alu    ) begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b1; end // Arithmetic rs2
        if ( if_dec_fence  ) begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b0; end // FENCE
        if ( if_dec_ecall  ) begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b0; end // ECALL
        if ( if_dec_ebreak ) begin if_rd_en = 1'b1; if_rs1_en = 1'b1; if_rs2_en = 1'b0; end // EBREAK
    end



    // -----------------------------------------
    //  Instruction Decode
    // -----------------------------------------

    logic                       id_valid_next;
    assign id_valid_next = if_valid && !ex_branch_valid;

    // control
    always_ff @(posedge clk) begin
        if ( reset ) begin            
            id_pc    <= '0;
            id_instr <= '0;
            id_valid <= 1'b0;
        end
        else if ( cke ) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
            id_valid <= id_valid_next;
        end
    end

    always_ff @(posedge clk) begin
        if ( cke ) begin
            id_rd_en  <= if_rd_en  && (if_rd_idx  != '0) && if_valid;
            id_rs1_en <= if_rs1_en && if_valid;
            id_rs2_en <= if_rs2_en && if_valid;
        end
    end

    // Instruction decode
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

                .wr_en          (ex_rd_en),
                .wr_addr        (ex_rd_idx),
                .wr_din         (ex_rd_val),

                .rd_en          ({2{cke}}),
                .rd_addr        ({if_rs2_idx, if_rs1_idx}),
                .rd_dout        ({id_rs2_val, id_rs1_val})
            );


    // branch
    always_ff @(posedge clk) begin
        if ( cke ) begin
            id_branch_en  <= 1'b0;
            id_branch_sel <= branch_sel_t'('x);
            if ( if_dec_jal  ) begin id_branch_en <= id_valid_next; id_branch_sel <= BRANCH_JAL;  end
            if ( if_dec_jalr ) begin id_branch_en <= id_valid_next; id_branch_sel <= BRANCH_JALR; end
            if ( if_dec_beq  ) begin id_branch_en <= id_valid_next; id_branch_sel <= BRANCH_BEQ;  end
            if ( if_dec_bne  ) begin id_branch_en <= id_valid_next; id_branch_sel <= BRANCH_BNE;  end
            if ( if_dec_blt  ) begin id_branch_en <= id_valid_next; id_branch_sel <= BRANCH_BLT;  end
            if ( if_dec_bge  ) begin id_branch_en <= id_valid_next; id_branch_sel <= BRANCH_BGE;  end
            if ( if_dec_bltu ) begin id_branch_en <= id_valid_next; id_branch_sel <= BRANCH_BLTU; end
            if ( if_dec_bgeu ) begin id_branch_en <= id_valid_next; id_branch_sel <= BRANCH_BGEU; end
        end
    end

    always_ff @(posedge clk) begin
        if ( cke ) begin
            id_branch_pc <= if_pc + PC_WIDTH'(if_imm_b);
            if ( if_opcode == 7'b1101111 ) begin   // jal
                id_branch_pc <= if_pc + PC_WIDTH'(if_imm_j);
            end
        end
    end


    // ALU
    alu_op_t                    id_alu_op;
    logic   [1:0]               id_alu_sel0;
    logic                       id_alu_sel1;
    logic   signed  [XLEN-1:0]  id_alu_val1;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            id_alu_sel0 <= alu_sel0_t'('x);
            id_alu_sel1 <= alu_sel1_t'('x);
            id_alu_val1 <= 'x;
            
            unique case (1'b1)
            if_dec_lui:     begin id_alu_op <= ALU_OP_ADD; id_alu_sel0 <= ALU_SEL0_ZERO; id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(if_imm_u); end
            if_dec_auipc:   begin id_alu_op <= ALU_OP_ADD; id_alu_sel0 <= ALU_SEL0_ZERO; id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(if_pc) + XLEN'(if_imm_u);end
            if_dec_jal:     begin id_alu_op <= ALU_OP_ADD; id_alu_sel0 <= ALU_SEL0_ZERO; id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(if_pc) + XLEN'(4); end
            if_dec_jalr:    begin id_alu_op <= ALU_OP_ADD; id_alu_sel0 <= ALU_SEL0_ZERO; id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(if_pc) + XLEN'(4); end
            if_dec_addi:    begin id_alu_op <= ALU_OP_ADD; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(if_imm_i); end
            if_dec_xori:    begin id_alu_op <= ALU_OP_XOR; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(if_imm_i); end
            if_dec_ori:     begin id_alu_op <= ALU_OP_OR;  id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(if_imm_i); end
            if_dec_andi:    begin id_alu_op <= ALU_OP_AND; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(if_imm_i); end
            if_dec_slli:    begin id_alu_op <= ALU_OP_SLL; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(if_imm_i); end
            if_dec_srli:    begin id_alu_op <= ALU_OP_SRL; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(if_imm_i); end
            if_dec_srai:    begin id_alu_op <= ALU_OP_SRA; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(if_imm_i); end
            if_dec_add:     begin id_alu_op <= ALU_OP_ADD; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_RS2; id_alu_val1 <= 'x; end
            if_dec_sub:     begin id_alu_op <= ALU_OP_SUB; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_RS2; id_alu_val1 <= 'x; end
            if_dec_sll:     begin id_alu_op <= ALU_OP_SLL; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_RS2; id_alu_val1 <= 'x; end
            if_dec_slti:    begin id_alu_op <= ALU_OP_ADD; id_alu_sel0 <= ALU_SEL0_SLT;  id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(0); end
            if_dec_sltiu:   begin id_alu_op <= ALU_OP_ADD; id_alu_sel0 <= ALU_SEL0_SLTU; id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(0); end
            if_dec_slt:     begin id_alu_op <= ALU_OP_ADD; id_alu_sel0 <= ALU_SEL0_SLT;  id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(0); end
            if_dec_sltu:    begin id_alu_op <= ALU_OP_ADD; id_alu_sel0 <= ALU_SEL0_SLTU; id_alu_sel1 <= ALU_SEL1_VAL; id_alu_val1 <= XLEN'(0); end
            if_dec_xor:     begin id_alu_op <= ALU_OP_XOR; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_RS2; id_alu_val1 <= 'x; end
            if_dec_srl:     begin id_alu_op <= ALU_OP_SRL; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_RS2; id_alu_val1 <= 'x; end
            if_dec_sra:     begin id_alu_op <= ALU_OP_SRA; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_RS2; id_alu_val1 <= 'x; end
            if_dec_or:      begin id_alu_op <= ALU_OP_OR;  id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_RS2; id_alu_val1 <= 'x; end
            if_dec_and:     begin id_alu_op <= ALU_OP_AND; id_alu_sel0 <= ALU_SEL0_RS1;  id_alu_sel1 <= ALU_SEL1_RS2; id_alu_val1 <= 'x; end
            default: ;
            endcase
        end
    end


    // memory access
    always_ff @(posedge clk) begin
        if ( reset ) begin
            id_mem_offset   <= 'x;
            id_mem_rd       <= 1'b0;
            id_mem_wr       <= 1'b0;
            id_mem_sel      <= 'x;
            id_mem_size     <= 'x;
            id_mem_unsigned <= 1'bx;
        end
        else if ( cke ) begin
            id_mem_offset   <= 'x;
            id_mem_rd       <= 1'b0;
            id_mem_wr       <= 1'b0;
            id_mem_sel      <= 'x;
            id_mem_size     <= 'x;
            id_mem_unsigned <= 1'bx;
            if ( id_valid_next ) begin
                if ( if_opcode == 7'b0000011 ) begin    // load
                    id_mem_rd       <= 1'b1;
                    id_mem_offset   <= 32'(if_imm_i);
                    id_mem_unsigned <= if_funct3[2];
                end
                if ( if_opcode == 7'b0100011 ) begin    // store
                    id_mem_wr     <= 1'b1;
                    id_mem_offset <= 32'(if_imm_s);
                end

                id_mem_sel[0] <= 1'b1;
                id_mem_sel[1] <= (if_funct3[1:0] >= 2'd1);
                id_mem_sel[2] <= (if_funct3[1:0] >= 2'd2);
                id_mem_sel[3] <= (if_funct3[1:0] >= 2'd2);
                
                id_mem_size   <= if_funct3[1:0];
            end
        end
    end


    // forwarding
    always_ff @(posedge clk) begin
        if ( cke ) begin
            id_rs1_forward <= id_rd_en && (id_rd_idx == if_rs1_idx) && if_valid;
            id_rs2_forward <= id_rd_en && (id_rd_idx == if_rs2_idx) && if_valid;
        end
    end


    // -----------------------------------------
    //  Execution
    // -----------------------------------------

    // forward
    assign ex_fwd_rs1_val = id_rs1_forward ? ex_rd_val : id_rs1_val;
    assign ex_fwd_rs2_val = id_rs2_forward ? ex_rd_val : id_rs2_val;
    assign ex_fwd_rs1_val_u = ex_fwd_rs1_val;
    assign ex_fwd_rs2_val_u = ex_fwd_rs2_val;

    // control
    always_ff @(posedge clk) begin
        if ( reset ) begin            
            ex_rd_en     <= 1'b0;
            ex_rd_idx    <= 'x;
            ex_pc        <= 'x;
            ex_instr     <= 'x;
            ex_valid     <= 1'b0;
        end
        else if ( cke ) begin
            ex_rd_en     <= id_rd_en && id_valid;
            ex_rd_idx    <= id_rd_idx;
            ex_pc        <= id_pc;
            ex_instr     <= id_instr;
            ex_valid     <= id_valid;
        end
    end
    
    always_ff @(posedge clk) begin
        if ( cke ) begin
            ex_rs1_en  <= id_rs1_en;
            ex_rs1_idx <= id_rs1_en ? id_rs1_idx     : '0;
            ex_rs1_val <= id_rs1_en ? ex_fwd_rs1_val : '0;
            ex_rs2_en  <= id_rs2_en;
            ex_rs2_idx <= id_rs2_en ? id_rs2_idx     : '0;
            ex_rs2_val <= id_rs2_en ? ex_fwd_rs2_val : '0;
        end
    end

    // conditions
    logic                   ex_cond_eq; 
    logic                   ex_cond_ne;
    logic                   ex_cond_lt;
    logic                   ex_cond_ge;
    logic                   ex_cond_ltu;
    logic                   ex_cond_geu;
    always_comb begin
        automatic   logic   signed  [XLEN-1:0]  cmp_data0;
        automatic   logic   signed  [XLEN-1:0]  cmp_data1;
        automatic   logic   signed  [XLEN-1:0]  cond_data;
        automatic   logic                       msb_carry;
        automatic   logic                       flg_carry;
        automatic   logic                       flg_overflow;
        automatic   logic                       flg_zero;
        automatic   logic                       flg_negative;
        cmp_data0    = 'x;
        cmp_data1    = 'x;
        cond_data    = 'x;
        msb_carry    = 'x;
        flg_carry    = 'x;
        flg_overflow = 'x;
        flg_zero     = 'x;
        flg_negative = 'x;

        cmp_data0 = ex_fwd_rs1_val;
        cmp_data1 = ex_fwd_rs2_val;
        if ( !id_opcode[5] ) begin
            cmp_data1 = id_funct3[0] ? XLEN'(id_imm_i_u) : XLEN'(id_imm_i);
        end

        cmp_data1 = ~cmp_data1;
        {msb_carry, cond_data[XLEN-2:0]} = {1'b0, cmp_data0[XLEN-2:0]} + {1'b0, cmp_data1[XLEN-2:0]} + XLEN'(1);
        {flg_carry, cond_data[XLEN-1]}   = cmp_data0[XLEN-1] + cmp_data1[XLEN-1] + msb_carry;

        flg_overflow = (msb_carry != flg_carry);
        flg_zero     = (cond_data == '0);
        flg_negative = cond_data[XLEN-1];

        ex_cond_eq  = flg_zero;
        ex_cond_ne  = !flg_zero;
        ex_cond_lt  = (flg_overflow != flg_negative);
        ex_cond_ge  = (flg_overflow == flg_negative);
        ex_cond_ltu = !flg_carry;
        ex_cond_geu = flg_carry;
    end


    // branch
    always_comb begin
        ex_branch_valid = 1'b0;
        ex_branch_pc    = 'x;
        if ( id_branch_en ) begin
            case (id_branch_sel)
            BRANCH_JAL:     begin ex_branch_pc = id_branch_pc; ex_branch_valid = 1'b1; end
            BRANCH_JALR:    begin ex_branch_pc = PC_WIDTH'(ex_fwd_rs1_val) + PC_WIDTH'(id_imm_i); ex_branch_valid = 1'b1; end
            BRANCH_BEQ:     if ( ex_cond_eq  ) begin ex_branch_pc = id_branch_pc; ex_branch_valid = 1'b1; end
            BRANCH_BNE:     if ( ex_cond_ne  ) begin ex_branch_pc = id_branch_pc; ex_branch_valid = 1'b1; end
            BRANCH_BLT:     if ( ex_cond_lt  ) begin ex_branch_pc = id_branch_pc; ex_branch_valid = 1'b1; end
            BRANCH_BGE:     if ( ex_cond_ge  ) begin ex_branch_pc = id_branch_pc; ex_branch_valid = 1'b1; end
            BRANCH_BLTU:    if ( ex_cond_ltu ) begin ex_branch_pc = id_branch_pc; ex_branch_valid = 1'b1; end
            BRANCH_BGEU:    if ( ex_cond_geu ) begin ex_branch_pc = id_branch_pc; ex_branch_valid = 1'b1; end
            default:;
            endcase
        end
    end

    // ALU
    logic   signed  [31:0]  ex_alu_rd_val;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            automatic   logic   signed  [XLEN-1:0]          alu_val0;
            automatic   logic   signed  [XLEN-1:0]          alu_val1;
            automatic   logic   signed  [XLEN-1:0]          adder_din0;
            automatic   logic   signed  [XLEN-1:0]          adder_din1;
            automatic   logic                               adder_cin;
            automatic   logic   signed  [XLEN-1:0]          adder_val;
            automatic   logic           [SHAMT_WIDTH-1:0]   shamt;
            automatic   logic   signed  [XLEN-1:0]          shifter_val;
            alu_val0    = 'x;
            alu_val1    = 'x;
            adder_din0  = 'x;
            adder_din1  = 'x;
            adder_cin   = 'x;
            shamt       = 'x;
            shifter_val = 'x;
            
            // alu input0
            case ( id_alu_sel0 )
            ALU_SEL0_RS1:  begin alu_val0 = ex_fwd_rs1_val;     end
            ALU_SEL0_ZERO: begin alu_val0 = '0;                 end
            ALU_SEL0_SLT:  begin alu_val0 = XLEN'(ex_cond_lt);  end
            ALU_SEL0_SLTU: begin alu_val0 = XLEN'(ex_cond_ltu); end
            default: ;
            endcase

            // alu input1
            case ( id_alu_sel1 )
            ALU_SEL1_RS2:  begin alu_val1 = ex_fwd_rs2_val;     end
            ALU_SEL1_VAL:  begin alu_val1 = id_alu_val1;        end
            default: ;
            endcase

            // adder 
            case ( id_alu_op )
            ALU_OP_ADD: begin adder_din0 = alu_val0;            adder_din1 =  alu_val1; adder_cin = 1'b0; end
            ALU_OP_SUB: begin adder_din0 = alu_val0;            adder_din1 = ~alu_val1; adder_cin = 1'b1; end
            ALU_OP_AND: begin adder_din0 = alu_val0 & alu_val1; adder_din1 = '0;        adder_cin = 1'b0; end
            ALU_OP_OR:  begin adder_din0 = alu_val0 | alu_val1; adder_din1 = '0;        adder_cin = 1'b0; end
            ALU_OP_XOR: begin adder_din0 = alu_val0 ^ alu_val1; adder_din1 = '0;        adder_cin = 1'b0; end
            default:;
            endcase
            adder_val = adder_din0 + adder_din1 + XLEN'(adder_cin);

            // shifter
            shamt = alu_val1[SHAMT_WIDTH-1:0];
            case ( id_alu_op )
            ALU_OP_SLL: begin shifter_val = ex_fwd_rs1_val   << shamt; end
            ALU_OP_SRL: begin shifter_val = ex_fwd_rs1_val_u >> shamt; end
            ALU_OP_SRA: begin shifter_val = ex_fwd_rs1_val  >>> shamt; end
            default:;
            endcase

            // output
            case ( id_alu_op )
            ALU_OP_ADD: begin ex_alu_rd_val <= adder_val; end
            ALU_OP_SUB: begin ex_alu_rd_val <= adder_val; end
            ALU_OP_AND: begin ex_alu_rd_val <= adder_val; end
            ALU_OP_OR:  begin ex_alu_rd_val <= adder_val; end
            ALU_OP_XOR: begin ex_alu_rd_val <= adder_val; end
            ALU_OP_SLL: begin ex_alu_rd_val <= shifter_val; end
            ALU_OP_SRL: begin ex_alu_rd_val <= shifter_val; end
            ALU_OP_SRA: begin ex_alu_rd_val <= shifter_val; end
            default:    begin ex_alu_rd_val <= 'x; end
            endcase
        end
    end

    // dbus access
    assign dbus_addr  = ex_fwd_rs1_val + id_mem_offset;
    assign dbus_rd    = id_mem_rd;
    assign dbus_wr    = id_mem_wr;
    assign dbus_sel   = id_mem_sel;
    assign dbus_wdata = ex_fwd_rs2_val;

    logic               ex_mem_rd;
    logic   [1:0]       ex_mem_size;
    logic               ex_mem_unsigned;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            ex_mem_rd       <= 1'b0;
            ex_mem_size     <= 'x;
            ex_mem_unsigned <= 1'bx;
        end
        else if ( cke ) begin
            ex_mem_rd       <= id_mem_rd;
            ex_mem_size     <= id_mem_size;
            ex_mem_unsigned <= id_mem_unsigned;
        end
    end

    logic   signed  [31:0]  ex_mem_rd_val;
    always_comb begin
        ex_mem_rd_val = 'x;
        if ( ex_mem_rd ) begin
            ex_mem_rd_val = dbus_rdata;
            if ( ex_mem_unsigned ) begin
                case ( ex_mem_size )
                2'b00:      ex_mem_rd_val = 32'($unsigned(dbus_rdata[7:0]));
                2'b01:      ex_mem_rd_val = 32'($unsigned(dbus_rdata[15:0]));
                default:    ex_mem_rd_val = 32'($unsigned(dbus_rdata[31:0]));
                endcase
            end
            else begin
                case ( ex_mem_size )
                2'b00:      ex_mem_rd_val = 32'($signed(dbus_rdata[7:0]));
                2'b01:      ex_mem_rd_val = 32'($signed(dbus_rdata[15:0]));
                default:    ex_mem_rd_val = 32'($signed(dbus_rdata[31:0]));
                endcase
            end
        end
    end

    always_comb begin
        ex_rd_val = ex_mem_rd ? ex_mem_rd_val : ex_alu_rd_val;
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
            else if ( cke ) begin
                if ( ex_valid ) begin
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
                        if ( ex_valid ) begin
                            automatic logic [RIDX_WIDTH-1:0]    rd_idx;
                            automatic logic [XLEN-1:0]          rd_val;
                            rd_idx = ex_rd_en ? ex_rd_idx : '0;
                            rd_val = ex_rd_en ? ex_rd_val : '0;
                            $fdisplay(fp_trace, "pc:%08x instr:%08x rd(%2d):%08x rs1(%2d):%08x rs2(%2d):%08x",
                                    ex_pc, ex_instr, rd_idx, rd_val, ex_rs1_idx, ex_rs1_val, ex_rs2_idx, ex_rs2_val);
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

            logic   [DBUS_ADDR_WIDTH-1:0]   log_dbus_addr;
            logic                           log_dbus_rd;
            logic                           log_dbus_wr;
            logic   [3:0]                   log_dbus_sel;
            always_ff @(posedge clk) begin
                if ( !reset ) begin
                    if ( cke ) begin
                        log_dbus_addr <= dbus_addr;
                        log_dbus_rd   <= dbus_rd;
                        log_dbus_wr   <= dbus_wr;
                        log_dbus_sel  <= dbus_sel;
                        if ( log_dbus_rd ) begin
                            $fdisplay(fp_dbus, "%10d read  addr:%08x rdata:%08x sel:%b  (pc:%08x instr:%08x)",
                                    exe_counter, log_dbus_addr, dbus_rdata, log_dbus_sel, ex_pc, ex_instr);
                        end
                        if ( dbus_wr ) begin
                            $fdisplay(fp_dbus, "%10d write addr:%08x wdata:%08x sel:%b  (pc:%08x instr:%08x)",
                                    exe_counter, dbus_addr, dbus_wdata, dbus_sel, id_pc, id_instr);
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
