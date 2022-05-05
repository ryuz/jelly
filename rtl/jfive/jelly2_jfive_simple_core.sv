// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_jfive_simple_core
        #(
            parameter int                       IBUS_ADDR_WIDTH = 14,
            parameter int                       DBUS_ADDR_WIDTH = 32,
            parameter int                       PC_WIDTH        = IBUS_ADDR_WIDTH,
            parameter bit   [PC_WIDTH-1:0]      INIT_PC_ADDR    = PC_WIDTH'(32'h80000000),

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

            output  wire    [IBUS_ADDR_WIDTH-1:0]   ibus_addr,
            input   wire    [31:0]                  ibus_rdata,

            output  wire    [DBUS_ADDR_WIDTH-1:0]   dbus_addr,
            output  wire                            dbus_rd,
            output  wire                            dbus_wr,
            output  wire    [3:0]                   dbus_sel,
            output  wire    [31:0]                  dbus_wdata,
            input   wire    [31:0]                  dbus_rdata
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


    logic   [PC_WIDTH-1:0]      branch_pc;
    logic                       branch_valid;

    // Program counter
    logic   [PC_WIDTH-1:0]      pc_pc;

    //  Instruction Fetch
    logic   [PC_WIDTH-1:0]      if_pc;
    logic   [31:0]              if_instr;
    logic                       if_valid;

    logic           [6:0]       if_opcode;
    logic           [4:0]       if_rd_idx;
    logic           [4:0]       if_rs1_idx;
    logic           [4:0]       if_rs2_idx;
    logic           [2:0]       if_funct3;
    logic           [6:0]       if_funct7;

    logic   signed  [11:0]      if_imm_i;
    logic   signed  [11:0]      if_imm_s;
    logic   signed  [12:0]      if_imm_b;
    logic   signed  [31:0]      if_imm_u;
    logic   signed  [20:0]      if_imm_j;

    logic                       if_rd_en;
    logic                       if_rs1_en;
    logic                       if_rs2_en;


    //  Instruction Decode
    logic           [6:0]       id_opcode;
    logic                       id_rd_en;
    logic           [4:0]       id_rd_idx;
    logic                       id_rs1_en;
    logic           [4:0]       id_rs1_idx;
    logic   signed  [31:0]      id_rs1_val;
    logic                       id_rs2_en;
    logic           [4:0]       id_rs2_idx;
    logic   signed  [31:0]      id_rs2_val;
    logic           [2:0]       id_funct3;
    logic           [6:0]       id_funct7;

    logic   signed  [11:0]      id_imm_i;
    logic   signed  [11:0]      id_imm_s;
    logic   signed  [12:0]      id_imm_b;
    logic   signed  [31:0]      id_imm_u;
    logic   signed  [20:0]      id_imm_j;

    logic                       id_rs1_forward;
    logic                       id_rs2_forward;


    //  Execution
    logic   signed  [31:0]      ex_fwd_rs1_val;
    logic   signed  [31:0]      ex_fwd_rs2_val;
    logic           [31:0]      ex_fwd_rs1_val_u;
    logic           [31:0]      ex_fwd_rs2_val_u;

    logic   [PC_WIDTH-1:0]      ex_pc;
    logic   [31:0]              ex_instr;
    logic                       ex_valid;

    logic                       ex_rd_en;
    logic           [4:0]       ex_rd_idx;
    logic           [31:0]      ex_rd_val;
    logic                       ex_rs1_en;
    logic           [4:0]       ex_rs1_idx;
    logic           [31:0]      ex_rs1_val;
    logic                       ex_rs2_en;
    logic           [4:0]       ex_rs2_idx;
    logic           [31:0]      ex_rs2_val;


    // -----------------------------------------
    //  Program counter
    // -----------------------------------------


    always_ff @(posedge clk) begin
        if ( reset ) begin
            pc_pc <= INIT_PC_ADDR;
        end
        else if ( cke ) begin
            if ( branch_valid ) begin
                pc_pc <= branch_pc;
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
            if_valid <= 1'b1 & ~branch_valid;
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


    // -----------------------------------------
    //  Instruction Decode
    // -----------------------------------------

    logic   [PC_WIDTH-1:0]      id_pc;
    logic   [31:0]              id_instr;
    logic                       id_valid, id_valid_next;

    assign id_valid_next = if_valid && !branch_valid;


    // 命令デコード
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
                .cke,

                .wr_en          (ex_rd_en),
                .wr_addr        (ex_rd_idx),
                .wr_din         (ex_rd_val),

                .rd_en          ({2{cke}}),
                .rd_addr        ({if_rs2_idx, if_rs1_idx}),
                .rd_dout        ({id_rs2_val, id_rs1_val})
            );

    // forwarding
    always_ff @(posedge clk) begin
        id_rs1_forward <= id_rd_en && (id_rd_idx == if_rs1_idx) && if_valid;
        id_rs2_forward <= id_rd_en && (id_rd_idx == if_rs2_idx) && if_valid;
    end

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
        if ( cke ) begin
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
    logic   signed  [31:0]                  id_mem_offset;
    logic                                   id_mem_rd;
    logic                                   id_mem_wr;
    logic           [3:0]                   id_mem_sel;
    logic           [1:0]                   id_mem_size;
    logic                                   id_mem_unsigned;
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
                if ( if_dec_lb || if_dec_lh || if_dec_lw || if_dec_lbu || if_dec_lhu ) begin
                    id_mem_rd       <= 1'b1;
                    id_mem_offset   <= 32'(if_imm_i);
                    id_mem_unsigned <= (if_dec_lbu || if_dec_lhu);
                end
                if ( if_dec_sb || if_dec_sh ||  if_dec_sw ) begin
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

    // register destination
    /*
    always_ff @(posedge clk) begin
        if ( reset ) begin
            id_rd_en  <= '0;
        end
        else if ( cke ) begin
            id_rd_en <= '0;
            if ( id_valid_next ) begin
                id_rd_en <= (if_rd_idx != 0) & (
                                if_dec_lui   |
                                if_dec_auipc |
                                if_dec_jal   |
                                if_dec_jalr  |
                                if_dec_lb    |
                                if_dec_lh    |
                                if_dec_lw    |
                                if_dec_lbu   |
                                if_dec_lhu   |
                                if_dec_addi  |
                                if_dec_slti  |
                                if_dec_sltiu |
                                if_dec_xori  |
                                if_dec_ori   |
                                if_dec_andi  |
                                if_dec_slli  |
                                if_dec_srli  |
                                if_dec_srai  |
                                if_dec_add   |
                                if_dec_sub   |
                                if_dec_sll   |
                                if_dec_slt   |
                                if_dec_sltu  |
                                if_dec_xor   |
                                if_dec_srl   |
                                if_dec_sra   |
                                if_dec_or    |
                                if_dec_and   |
                                if_dec_fence);
            end
        end
    end
    */
    


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
        id_rd_en  <= if_rd_en  && (if_rd_idx  != '0) && if_valid;
        id_rs1_en <= if_rs1_en && if_valid;
        id_rs2_en <= if_rs2_en && if_valid;
    end


    // -----------------------------------------
    //  Execution
    // -----------------------------------------

    // forward
    assign ex_fwd_rs1_val = id_rs1_forward ? ex_rd_val : id_rs1_val;
    assign ex_fwd_rs2_val = id_rs2_forward ? ex_rd_val : id_rs2_val;
    assign ex_fwd_rs1_val_u = ex_fwd_rs1_val;
    assign ex_fwd_rs2_val_u = ex_fwd_rs2_val;

    // branch
    always_comb begin
        branch_valid = 1'b0;
        branch_pc    = 'x;
        unique case (1'b1)
        id_dec_jal : begin branch_pc = id_pc                   + PC_WIDTH'(id_imm_j); branch_valid = 1'b1; end
        id_dec_jalr: begin branch_pc = PC_WIDTH'(ex_fwd_rs1_val) + PC_WIDTH'(id_imm_i); branch_valid = 1'b1; end
        id_dec_beq : if ( ex_fwd_rs1_val   == ex_fwd_rs2_val   ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        id_dec_bne : if ( ex_fwd_rs1_val   != ex_fwd_rs2_val   ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        id_dec_blt : if ( ex_fwd_rs1_val    < ex_fwd_rs2_val   ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        id_dec_bge : if ( ex_fwd_rs1_val   >= ex_fwd_rs2_val   ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        id_dec_bltu: if ( ex_fwd_rs1_val_u  < ex_fwd_rs2_val_u ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        id_dec_bgeu: if ( ex_fwd_rs1_val_u >= ex_fwd_rs2_val_u ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        default: ;
        endcase

        if ( !id_valid ) begin
            branch_valid = 1'b0;
        end
    end


    // alu
    logic   signed  [31:0]  ex_rd_val_alu;
    always_ff @(posedge clk) begin
        ex_rd_val_alu <= 'x;
        unique case (1'b1)
        id_dec_lui  : ex_rd_val_alu <= id_imm_u;
        id_dec_auipc: ex_rd_val_alu <= id_imm_u + 32'(id_pc);
        id_dec_jal  : ex_rd_val_alu <= 32'(id_pc) + 32'd4;
        id_dec_jalr : ex_rd_val_alu <= 32'(id_pc) + 32'd4;
        id_dec_addi : ex_rd_val_alu <=  ex_fwd_rs1_val    + 32'(id_imm_i);
        id_dec_slti : ex_rd_val_alu <= (ex_fwd_rs1_val   < 32'(id_imm_i)  ) ? 32'd1 : 32'd0;
        id_dec_sltiu: ex_rd_val_alu <= (ex_fwd_rs1_val_u < 32'(id_imm_i_u)) ? 32'd1 : 32'd0;
        id_dec_xori : ex_rd_val_alu <=  ex_fwd_rs1_val    ^ 32'(id_imm_i);
        id_dec_ori  : ex_rd_val_alu <=  ex_fwd_rs1_val    | 32'(id_imm_i);
        id_dec_andi : ex_rd_val_alu <=  ex_fwd_rs1_val    & 32'(id_imm_i);
        id_dec_slli : ex_rd_val_alu <=  ex_fwd_rs1_val   << id_imm_i_u[4:0];
        id_dec_srli : ex_rd_val_alu <=  ex_fwd_rs1_val_u >> id_imm_i_u[4:0];
        id_dec_srai : ex_rd_val_alu <=  ex_fwd_rs1_val  >>> id_imm_i_u[4:0];
        id_dec_add  : ex_rd_val_alu <=  ex_fwd_rs1_val    + ex_fwd_rs2_val;
        id_dec_sub  : ex_rd_val_alu <=  ex_fwd_rs1_val    - ex_fwd_rs2_val;
        id_dec_sll  : ex_rd_val_alu <=  ex_fwd_rs1_val   << ex_fwd_rs2_val_u[4:0];
        id_dec_slt  : ex_rd_val_alu <= (ex_fwd_rs1_val   <  ex_fwd_rs2_val  ) ? 32'd1 : 32'd0;
        id_dec_sltu : ex_rd_val_alu <= (ex_fwd_rs1_val_u <  ex_fwd_rs2_val_u) ? 32'd1 : 32'd0;
        id_dec_xor  : ex_rd_val_alu <=  ex_fwd_rs1_val    ^ ex_fwd_rs2_val;
        id_dec_srl  : ex_rd_val_alu <=  ex_fwd_rs1_val_u >> ex_fwd_rs2_val_u[4:0];
        id_dec_sra  : ex_rd_val_alu <=  ex_fwd_rs1_val  >>> ex_fwd_rs2_val_u[4:0];
        id_dec_or   : ex_rd_val_alu <=  ex_fwd_rs1_val    | ex_fwd_rs2_val;
        id_dec_and  : ex_rd_val_alu <=  ex_fwd_rs1_val    & ex_fwd_rs2_val;
        default: ;
        endcase
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

    logic   signed  [31:0]  ex_rd_val_mem;
    always_comb begin
        ex_rd_val_mem = 'x;
        if ( ex_mem_rd ) begin
            ex_rd_val_mem = dbus_rdata;
            if ( ex_mem_unsigned ) begin
                case ( ex_mem_size )
                2'b00:      ex_rd_val_mem = 32'($unsigned(dbus_rdata[7:0]));
                2'b01:      ex_rd_val_mem = 32'($unsigned(dbus_rdata[15:0]));
                default:    ex_rd_val_mem = 32'($unsigned(dbus_rdata[31:0]));
                endcase
            end
            else begin
                case ( ex_mem_size )
                2'b00:      ex_rd_val_mem = 32'($signed(dbus_rdata[7:0]));
                2'b01:      ex_rd_val_mem = 32'($signed(dbus_rdata[15:0]));
                default:    ex_rd_val_mem = 32'($signed(dbus_rdata[31:0]));
                endcase
            end
        end
    end

    always_comb begin
        ex_rd_val = ex_mem_rd ? ex_rd_val_mem : ex_rd_val_alu;
    end

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
