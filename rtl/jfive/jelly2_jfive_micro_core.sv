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
            parameter int                   IBUS_ADDR_WIDTH = 14,
            parameter int                   DBUS_ADDR_WIDTH = 32,
            parameter int                   PC_WIDTH        = IBUS_ADDR_WIDTH,
            parameter bit   [PC_WIDTH-1:0]  RESET_PC_ADDR   = PC_WIDTH'(32'h80000000)
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,

            output  wire    [IBUS_ADDR_WIDTH-1:0]   ibus_addr,
            input   wire    [31:0]                  ibus_rdata,

            output  wire                            dbus_en,        // read or write
            output  wire                            dbus_re,        // read enable
            output  wire                            dbus_we,        // write enable
            output  wire    [1:0]                   dbus_size,      // address
            output  wire    [DBUS_ADDR_WIDTH-1:0]   dbus_addr,      // size
            output  wire    [3:0]                   dbus_sel,       // byte lane select
            output  wire    [3:0]                   dbus_rsel,      // byte lane select(read only)
            output  wire    [3:0]                   dbus_wsel,      // byte lane select(write only)
            output  wire    [31:0]                  dbus_wdata,     // write data
            input   wire    [31:0]                  dbus_rdata      // read data
        );

    localparam XLEN        = 32;
    localparam SEL_WIDTH   = XLEN / 8;
    localparam SIZE_WIDTH  = 2;
    localparam INSTR_WIDTH = 32;
    localparam RIDX_WIDTH  = 5;


    // -----------------------------------------
    //  Signals
    // -----------------------------------------

    // 
//    logic           [PC_WIDTH-1:0]      branch_pc;
//    logic                               branch_valid;

    // Program counter
    logic                               pc_cke;
    logic           [PC_WIDTH-1:0]      pc_pc;


    // Instruction Fetch
    logic                               if_cke;
    logic           [PC_WIDTH-1:0]      if_pc;
    logic           [INSTR_WIDTH-1:0]   if_instr;
    logic                               if_valid;

    logic           [6:0]               if_opcode;
    logic           [RIDX_WIDTH-1:0]    if_rd_idx;
    logic           [RIDX_WIDTH-1:0]    if_rs1_idx;
    logic           [RIDX_WIDTH-1:0]    if_rs2_idx;
    logic           [2:0]               if_funct3;
    logic           [6:0]               if_funct7;

    logic   signed  [11:0]              if_imm_i;
    logic   signed  [11:0]              if_imm_s;
    logic   signed  [12:0]              if_imm_b;
    logic   signed  [31:0]              if_imm_u;
    logic   signed  [20:0]              if_imm_j;


    // Instruction Decode
    logic                               id_cke;
    logic           [PC_WIDTH-1:0]      id_pc;
    logic           [INSTR_WIDTH-1:0]   id_instr;
    logic                               id_valid;

    logic           [6:0]               id_opcode;
    logic           [RIDX_WIDTH-1:0]    id_rd_idx;
    logic           [RIDX_WIDTH-1:0]    id_rs1_idx;
    logic           [RIDX_WIDTH-1:0]    id_rs2_idx;
    logic           [2:0]               id_funct3;
    logic           [6:0]               id_funct7;

    logic   signed  [11:0]              id_imm_i;
    logic   signed  [11:0]              id_imm_s;
    logic   signed  [12:0]              id_imm_b;
    logic   signed  [31:0]              id_imm_u;
    logic   signed  [20:0]              id_imm_j;

    logic                               id_rd_en;
    logic   signed  [XLEN-1:0]          id_rs1_val;
    logic   signed  [XLEN-1:0]          id_rs2_val;

    logic           [1:0]               id_rs1_fwd;
    logic           [1:0]               id_rs2_fwd;

    logic                               id_branch_valid;
    logic           [PC_WIDTH-1:0]      id_branch_pc;

    logic                               id_mem_re;
    logic                               id_mem_we;
    logic   signed  [XLEN-1:0]          id_mem_offset;


    //  Execution
    logic                               ex_cke;
    logic                               ex_valid;
    logic           [PC_WIDTH-1:0]      ex_pc;
    logic           [31:0]              ex_instr;
    logic           [PC_WIDTH-1:0]      ex_expect_pc;

    logic   signed  [XLEN-1:0]          ex_fwd_rs1_val;
    logic   signed  [XLEN-1:0]          ex_fwd_rs2_val;
    logic           [XLEN-1:0]          ex_fwd_rs1_val_u;
    logic           [XLEN-1:0]          ex_fwd_rs2_val_u;

    logic                               ex_rd_en;
    logic           [RIDX_WIDTH-1:0]    ex_rd_idx;
    logic   signed  [XLEN-1:0]          ex_rd_val;

    logic                               ex_mem_en;
    logic                               ex_mem_re;
    logic                               ex_mem_we;
    logic           [XLEN-1:0]          ex_mem_addr;
    logic           [SIZE_WIDTH-1:0]    ex_mem_size;
    logic           [SEL_WIDTH-1:0]     ex_mem_sel;
    logic           [SEL_WIDTH-1:0]     ex_mem_rsel;
    logic           [SEL_WIDTH-1:0]     ex_mem_wsel;
    logic           [XLEN-1:0]          ex_mem_wdata;
    logic                               ex_mem_unsigned;

    // Memory Access
    logic                               ma_cke;
    logic                               ma_valid;
    logic           [PC_WIDTH-1:0]      ma_pc;
    logic           [31:0]              ma_instr;

    logic                               ma_rd_en;
    logic           [RIDX_WIDTH-1:0]    ma_rd_idx;
    logic           [XLEN-1:0]          ma_rd_val;

    logic                               ma_mem_re;
    logic           [XLEN-1:0]          ma_mem_addr;
    logic           [SIZE_WIDTH-1:0]    ma_mem_size;
    logic                               ma_mem_unsigned;
    logic           [XLEN-1:0]          ma_mem_rdata;

    // Write back
    logic                               wb_cke;
    logic                               wb_valid;
    logic                               wb_pc;
    logic           [INSTR_WIDTH-1:0]   wb_instr;

    logic                               wb_rd_en;
    logic           [RIDX_WIDTH-1:0]    wb_rd_idx;
    logic           [XLEN-1:0]          wb_rd_val;


    // -----------------------------------------
    //  Interlock
    // -----------------------------------------

    // ストール時にデコードまでのパイプラインを止める
    assign pc_cke = cke & id_stall;
    assign if_cke = cke & id_stall;
    assign id_cke = cke & id_stall;
    assign ex_cke = cke;
    assign ma_cke = cke;
    assign wb_cke = cke;


    // -----------------------------------------
    //  Program counter
    // -----------------------------------------

    always_ff @(posedge clk) begin
        if ( reset ) begin
            pc_pc <= RESET_PC_ADDR;
        end
        else if ( pc_cke ) begin
            pc_pc <= pc_pc + PC_WIDTH'(4);

            // 実行ステージの期待する命令がでコードパイプになければブランチ
            if ( !((pc_pc == ex_expect_pc)
                || (id_pc == ex_expect_pc && if_valid)
                || (id_pc == ex_expect_pc && id_valid)) ) begin
                pc_pc <= ex_expect_pc;
            end
        end
    end


    // -----------------------------------------
    //  Instruction Fetch
    // -----------------------------------------

    // PC & Instruction
    always_ff @(posedge clk) begin
        if ( reset ) begin            
            if_pc    <= 'x;
            if_valid <= 1'b0;
        end
        else if ( if_cke ) begin
            if_pc    <= pc_pc;
            if_valid <= 1'b1;
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
    
    

    // -----------------------------------------
    //  Instruction Decode
    // -----------------------------------------

    logic       id_stall;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            id_stall <= 1'b0;
        end
        else if ( cke ) begin
            if ( id_stall ) begin
                id_stall <= 1'b0;
            end
            else if ( id_mem_re ) begin
                if ( (if_opcode == 7'b1100111 && (if_rs1_idx == id_rd_idx))
                        || (if_opcode == 7'b1100011 && ((if_rs1_idx == id_rd_idx) || (if_rs2_idx == id_rd_idx)))
                        || (if_opcode == 7'b0000011 && (if_rs1_idx == id_rd_idx))
                        || (if_opcode == 7'b0100011 && ((if_rs1_idx == id_rd_idx) || (if_rs2_idx == id_rd_idx)))
                        || (if_opcode == 7'b0010011 && (if_rs1_idx == id_rd_idx))
                        || (if_opcode == 7'b0010011 && (if_rs1_idx == id_rd_idx))
                        || (if_opcode == 7'b0110011 && ((if_rs1_idx == id_rd_idx) || (if_rs2_idx == id_rd_idx)))
                        || (if_opcode == 7'b0001111 && (if_rs1_idx == id_rd_idx)) ) begin
                    id_stall <= 1'b1;
                end
            end
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
    jelly2_register_file_ram
            #(
                .READ_PORTS     (2),
                .ADDR_WIDTH     (RIDX_WIDTH),
                .DATA_WIDTH     (XLEN)
            )
        i_register_file
            (
                .reset,
                .clk,
                .cke,

                .wr_en          (wb_rd_en),
                .wr_addr        (wb_rd_idx),
                .wr_din         (wb_rd_val),

                .rd_en          ({2{id_cke}}),
                .rd_addr        ({if_rs2_idx, if_rs1_idx}),
                .rd_dout        ({id_rs2_val, id_rs1_val})
            );

    // forwarding
    always_ff @(posedge clk) begin
        if ( id_cke ) begin
            id_rs1_fwd <= 2'd0;
            if ( ma_rd_en && (ma_rd_idx == if_rs1_idx) ) begin id_rs1_fwd <= 2'd3; end
            if ( ex_rd_en && (ex_rd_idx == if_rs1_idx) ) begin id_rs1_fwd <= 2'd2; end
            if ( id_rd_en && (id_rd_idx == if_rs1_idx) ) begin id_rs1_fwd <= 2'd1; end

            id_rs2_fwd <= 2'd0;
            if ( ma_rd_en && (ma_rd_idx == if_rs2_idx) ) begin id_rs2_fwd <= 2'd3; end
            if ( ex_rd_en && (ex_rd_idx == if_rs2_idx) ) begin id_rs2_fwd <= 2'd2; end
            if ( id_rd_en && (id_rd_idx == if_rs2_idx) ) begin id_rs2_fwd <= 2'd1; end
        end
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
            if ( if_valid ) begin
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
    always_ff @(posedge clk) begin
        if ( reset ) begin
            id_rd_en  <= '0;
        end
        else if ( id_cke ) begin
            id_rd_en <= '0;
            if ( if_valid ) begin
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


    always_ff @(posedge clk) begin
        id_branch_pc <= 'x;
        unique case (1'b1)
        if_dec_jal : id_branch_pc <= if_pc + PC_WIDTH'(if_imm_j);
        if_dec_beq : id_branch_pc <= if_pc + PC_WIDTH'(if_imm_b);
        if_dec_bne : id_branch_pc <= if_pc + PC_WIDTH'(if_imm_b);
        if_dec_blt : id_branch_pc <= if_pc + PC_WIDTH'(if_imm_b);
        if_dec_bge : id_branch_pc <= if_pc + PC_WIDTH'(if_imm_b);
        if_dec_bltu: id_branch_pc <= if_pc + PC_WIDTH'(if_imm_b);
        if_dec_bgeu: id_branch_pc <= if_pc + PC_WIDTH'(if_imm_b);
        default:     id_branch_pc <= 'x;
        endcase
    end
    
    // control
    logic   id_valid_tmp;
    always_ff @(posedge clk) begin
        if ( reset ) begin            
            id_pc    <= '0;
            id_instr <= '0;
            id_valid_tmp <= 1'b0;
        end
        else if ( id_cke ) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
            id_valid_tmp <= if_valid;
        end
    end
    assign id_valid = id_valid_tmp && !id_stall;


    // -----------------------------------------
    //  Execution
    // -----------------------------------------

    // control
    always_ff @(posedge clk) begin
        if ( reset ) begin            
            ex_pc    <= RESET_PC_ADDR;
            ex_instr <= 'x;
            ex_valid <= 1'b0;
        end
        else if ( id_cke ) begin
            if ( id_valid && id_pc == ex_expect_pc ) begin
                ex_pc    <= id_pc;
                ex_instr <= id_instr;
                ex_valid <= id_valid;
            end
        end
    end

    // forwarding
    always_comb begin
        case ( id_rs1_fwd )
        2'd0:   ex_fwd_rs1_val = id_rs1_val;
        2'd1:   ex_fwd_rs1_val = ex_rd_val;
        2'd2:   ex_fwd_rs1_val = ma_rd_val;
        2'd3:   ex_fwd_rs1_val = wb_rd_val;
        endcase
        ex_fwd_rs1_val_u = ex_fwd_rs1_val;
    end

    always_comb begin
        ex_fwd_rs2_val = 'x;
        case ( id_rs1_fwd )
        2'd0:   ex_fwd_rs2_val = id_rs2_val;
        2'd1:   ex_fwd_rs2_val = ex_rd_val;
        2'd2:   ex_fwd_rs2_val = ma_rd_val;
        2'd3:   ex_fwd_rs2_val = wb_rd_val;
        endcase
        ex_fwd_rs2_val_u = ex_fwd_rs2_val;
    end

    // branch
    always_comb begin
        ex_expect_pc = ex_pc;

        if ( ex_valid ) begin
            ex_expect_pc += PC_WIDTH'(4);
        end

        if ( id_valid ) begin
            unique case (1'b1)
            id_dec_jal:  begin ex_expect_pc = id_branch_pc; end
            id_dec_jalr: begin ex_expect_pc = PC_WIDTH'(ex_fwd_rs1_val) + PC_WIDTH'(id_imm_i); end
            id_dec_beq:  if ( ex_fwd_rs1_val   == ex_fwd_rs2_val   ) begin ex_expect_pc = id_branch_pc; end
            id_dec_bne:  if ( ex_fwd_rs1_val   != ex_fwd_rs2_val   ) begin ex_expect_pc = id_branch_pc; end
            id_dec_blt:  if ( ex_fwd_rs1_val    < ex_fwd_rs2_val   ) begin ex_expect_pc = id_branch_pc; end
            id_dec_bge:  if ( ex_fwd_rs1_val   >= ex_fwd_rs2_val   ) begin ex_expect_pc = id_branch_pc; end
            id_dec_bltu: if ( ex_fwd_rs1_val_u  < ex_fwd_rs2_val_u ) begin ex_expect_pc = id_branch_pc; end
            id_dec_bgeu: if ( ex_fwd_rs1_val_u >= ex_fwd_rs2_val_u ) begin ex_expect_pc = id_branch_pc; end
            default: ;
            endcase
        end
    end


    // alu
    logic   signed  [31:0]  ex_rd_wdata_alu;
    always_ff @(posedge clk) begin
        ex_rd_wdata_alu <= 'x;
        unique case (1'b1)
        id_dec_lui  : ex_rd_wdata_alu <= id_imm_u;
        id_dec_auipc: ex_rd_wdata_alu <= id_imm_u + 32'(id_pc);
        id_dec_jal  : ex_rd_wdata_alu <= 32'(id_pc) + 32'd4;
        id_dec_jalr : ex_rd_wdata_alu <= 32'(id_pc) + 32'd4;
        id_dec_addi : ex_rd_wdata_alu <= ex_fwd_rs1_val    + 32'(id_imm_i);
        id_dec_slti : ex_rd_wdata_alu <= (ex_fwd_rs1_val   < 32'(id_imm_i)  ) ? 32'd1 : 32'd0;
        id_dec_sltiu: ex_rd_wdata_alu <= (ex_fwd_rs1_val_u < 32'(id_imm_i_u)) ? 32'd1 : 32'd0;
        id_dec_xori : ex_rd_wdata_alu <= ex_fwd_rs1_val    ^ 32'(id_imm_i);
        id_dec_ori  : ex_rd_wdata_alu <= ex_fwd_rs1_val    | 32'(id_imm_i);
        id_dec_andi : ex_rd_wdata_alu <= ex_fwd_rs1_val    & 32'(id_imm_i);
        id_dec_slli : ex_rd_wdata_alu <= ex_fwd_rs1_val   << id_imm_i_u[4:0];
        id_dec_srli : ex_rd_wdata_alu <= ex_fwd_rs1_val_u >> id_imm_i_u[4:0];
        id_dec_srai : ex_rd_wdata_alu <= ex_fwd_rs1_val  >>> id_imm_i_u[4:0];
        id_dec_add  : ex_rd_wdata_alu <= ex_fwd_rs1_val    + ex_fwd_rs2_val;
        id_dec_sub  : ex_rd_wdata_alu <= ex_fwd_rs1_val    - ex_fwd_rs2_val;
        id_dec_sll  : ex_rd_wdata_alu <= ex_fwd_rs1_val   << ex_fwd_rs2_val_u[4:0];
        id_dec_slt  : ex_rd_wdata_alu <= (ex_fwd_rs1_val   < ex_fwd_rs2_val  ) ? 32'd1 : 32'd0;
        id_dec_sltu : ex_rd_wdata_alu <= (ex_fwd_rs1_val_u < ex_fwd_rs2_val_u) ? 32'd1 : 32'd0;
        id_dec_xor  : ex_rd_wdata_alu <= ex_fwd_rs1_val    ^ ex_fwd_rs2_val;
        id_dec_srl  : ex_rd_wdata_alu <= ex_fwd_rs1_val_u >> ex_fwd_rs2_val_u[4:0];
        id_dec_sra  : ex_rd_wdata_alu <= ex_fwd_rs1_val  >>> ex_fwd_rs2_val_u[4:0];
        id_dec_or   : ex_rd_wdata_alu <= ex_fwd_rs1_val    | ex_fwd_rs2_val;
        id_dec_and  : ex_rd_wdata_alu <= ex_fwd_rs1_val    & ex_fwd_rs2_val;
        default: ;
        endcase
    end

    /*
    function    [XLEN-1:0]  size_mask(input [SIZE_WIDTH-1:0] size);
    begin
        size_mask = 'x;
        if ( XLEN >=   8 && int'(size) == 0 )  begin size_mask = XLEN'({  8{1'b1}}); end
        if ( XLEN >=  16 && int'(size) == 1 )  begin size_mask = XLEN'({ 16{1'b1}}); end
        if ( XLEN >=  32 && int'(size) == 2 )  begin size_mask = XLEN'({ 32{1'b1}}); end
        if ( XLEN >=  64 && int'(size) == 3 )  begin size_mask = XLEN'({ 64{1'b1}}); end
        if ( XLEN >= 128 && int'(size) == 4 )  begin size_mask = XLEN'({128{1'b1}}); end
    end
    endfunction
    */

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
            ex_mem_en    <= 1'b0;
            ex_mem_re    <= 1'b0;
            ex_mem_we    <= 1'b0;
            ex_mem_addr  <= 'x;
            ex_mem_size  <= 'x;
            ex_mem_sel   <= '0;
            ex_mem_rsel  <= '0;
            ex_mem_wsel  <= '0;
            ex_mem_wdata <= 'x;
        end
        else if ( cke ) begin
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

            ex_mem_en    <= id_mem_re || id_mem_we;
            ex_mem_re    <= id_mem_re;
            ex_mem_we    <= id_mem_we;
            ex_mem_addr  <= mem_addr;
            ex_mem_size  <= id_mem_size;
            ex_mem_sel   <= mem_sel;
            ex_mem_rsel  <= id_mem_re ? mem_sel : '0;
            ex_mem_wsel  <= id_mem_we ? mem_sel : '0;
            ex_mem_wdata <= mem_wdata;
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
        end
        else if ( cke ) begin
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
        end
    end

    // data-bus access
    assign dbus_en      = ex_mem_en;
    assign dbus_re      = ex_mem_re;
    assign dbus_we      = ex_mem_we;
    assign dbus_size    = ex_mem_size;
    assign dbus_addr    = ex_mem_addr;
    assign dbus_sel     = ex_mem_sel;
    assign dbus_rsel    = ex_mem_rsel;
    assign dbus_wsel    = ex_mem_wsel;
    assign dbus_wdata   = ex_mem_wdata;

    assign ma_mem_rdata = dbus_rdata;



    // -----------------------------------------
    //  Write back
    // -----------------------------------------

    always_ff @(posedge clk) begin
        if ( reset ) begin
            wb_rd_en  <= 1'b0;
            wb_rd_idx <= 'x;
            wb_rd_val <= 'x;
        end
        else if ( wb_cke ) begin
            automatic   logic   [XLEN-1:0]  mem_rdata;
            
            mem_rdata = ma_mem_rdata;
            if ( XLEN >=  16 && dbus_addr[0] )    begin   mem_rdata = mem_rdata >>  8; end;
            if ( XLEN >=  32 && dbus_addr[1] )    begin   mem_rdata = mem_rdata >> 16; end;
            if ( XLEN >=  64 && dbus_addr[2] )    begin   mem_rdata = mem_rdata >> 32; end;
            if ( XLEN >= 128 && dbus_addr[3] )    begin   mem_rdata = mem_rdata >> 64; end;

            if ( ma_mem_unsigned ) begin
                if ( XLEN >=  16 && int'(dbus_size) == 0 )  begin   mem_rdata = XLEN'($unsigned(mem_rdata[ 7:0])); end
                if ( XLEN >=  32 && int'(dbus_size) == 1 )  begin   mem_rdata = XLEN'($unsigned(mem_rdata[15:0])); end
                if ( XLEN >=  64 && int'(dbus_size) == 2 )  begin   mem_rdata = XLEN'($unsigned(mem_rdata[31:0])); end
//              if ( XLEN >= 128 && int'(dbus_size) == 3 )  begin   mem_rdata = XLEN'($unsigned(mem_rdata[63:0])); end
            end
            else begin
                if ( XLEN >=  16 && int'(dbus_size) == 0 )  begin   mem_rdata = XLEN'($signed(mem_rdata[ 7:0])); end
                if ( XLEN >=  32 && int'(dbus_size) == 1 )  begin   mem_rdata = XLEN'($signed(mem_rdata[15:0])); end
                if ( XLEN >=  64 && int'(dbus_size) == 2 )  begin   mem_rdata = XLEN'($signed(mem_rdata[31:0])); end
//              if ( XLEN >= 128 && int'(dbus_size) == 3 )  begin   mem_rdata = XLEN'($signed(mem_rdata[63:0])); end
            end

            wb_rd_en  <= ma_rd_en || ma_mem_re;
            wb_rd_idx <= ma_rd_idx;
            wb_rd_val <= ma_rd_en ? wb_rd_val : mem_rdata;
        end
    end

endmodule


`default_nettype wire


// End of file
