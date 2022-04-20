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

            output  wire                            dbus_en,
            output  wire                            dbus_re,
            output  wire                            dbus_we,
            output  wire    [1:0]                   dbus_size,
            output  wire    [DBUS_ADDR_WIDTH-1:0]   dbus_addr,
            output  wire    [3:0]                   dbus_sel,
            output  wire    [3:0]                   dbus_rsel,
            output  wire    [3:0]                   dbus_wsel,
            output  wire    [31:0]                  dbus_wdata,
            input   wire    [31:0]                  dbus_rdata,
            input   wire                            dbus_wait
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
    logic           [PC_WIDTH-1:0]      branch_pc;
    logic                               branch_valid;

    // Program counter
    logic           [PC_WIDTH-1:0]      pc_pc;

    // Instruction Fetch
    logic           [PC_WIDTH-1:0]      if_pc;
    logic           [INSTR_WIDTH-1:0]   if_instr;
    logic                               if_valid;

    // Instruction Decode
    logic           [PC_WIDTH-1:0]      id_pc;
    logic           [INSTR_WIDTH-1:0]   id_instr;
    logic                               id_valid, id_valid_next;

    logic           [6:0]               id_opcode;
    logic           [4:0]               id_rd;
    logic           [4:0]               id_rs1;
    logic           [4:0]               id_rs2;
    logic           [2:0]               id_funct3;
    logic           [6:0]               id_funct7;

    logic   signed  [11:0]              id_imm_i;
    logic   signed  [11:0]              id_imm_s;
    logic   signed  [12:0]              id_imm_b;
    logic   signed  [31:0]              id_imm_u;
    logic   signed  [20:0]              id_imm_j;

    logic                               id_rd_en;
//    logic   signed  [XLEN-1:0]          id_rs1_rdata_raw;
//    logic   signed  [XLEN-1:0]          id_rs2_rdata_raw;
    logic   signed  [XLEN-1:0]          id_rs1_rdata;
    logic   signed  [XLEN-1:0]          id_rs2_rdata;

    logic           [1:0]               id_rs1_fwd;
    logic           [1:0]               id_rs2_fwd;


    logic                               id_mem_re;
    logic                               id_mem_we;
    logic   signed  [XLEN-1:0]          id_mem_offset;


    //  Execution
    logic                               ex_cke;
    logic                               ex_valid;
    logic           [PC_WIDTH-1:0]      ex_pc;
    logic           [31:0]              ex_instr;

    logic   signed  [XLEN-1:0]          ex_fwd_rs1;
    logic   signed  [XLEN-1:0]          ex_fwd_rs2;

    logic                               ex_rd_en;
    logic           [RIDX_WIDTH-1:0]    ex_rd_idx;
    logic   signed  [XLEN-1:0]          ex_rd_val;

    logic                               ex_mem_unsigned;
    logic                               ex_mem_en;      // read or write
    logic                               ex_mem_re;      // read enable
    logic                               ex_mem_we;      // write enable
    logic           [XLEN-1:0]          ex_mem_addr;    // address
    logic           [SIZE_WIDTH-1:0]    ex_mem_size;    // size
    logic           [SEL_WIDTH-1:0]     ex_mem_sel;     // byte lane select
    logic           [SEL_WIDTH-1:0]     ex_mem_rsel;    // byte lane select(read only)
    logic           [SEL_WIDTH-1:0]     ex_mem_wsel;    // byte lane select(write only)
    logic           [XLEN-1:0]          ex_mem_wdata;   // write data

    // Memory Access
    logic                               ma_cke;
    logic                               ma_valid;
    logic           [PC_WIDTH-1:0]      ma_pc;
    logic           [31:0]              ma_instr;

    logic                               ma_rd_en;
    logic           [RIDX_WIDTH-1:0]    ma_rd_idx;
    logic           [XLEN-1:0]          ma_rd_val;

    logic                               ma_unsigned;
    logic           [XLEN-1:0]          ma_addr;
    logic           [SIZE_WIDTH-1:0]    ma_size;
    logic           [XLEN-1:0]          ma_rdata;
    logic                               ma_rvalid;

    // Write back
    logic                               wb_cke;
    logic                               wb_valid;
    logic                               wb_pc;
    logic           [INSTR_WIDTH-1:0]   wb_instr;

    logic                               wb_rd_en;
    logic           [RIDX_WIDTH-1:0]    wb_rd_idx;
    logic           [XLEN-1:0]          wb_rd_val;



    // -----------------------------------------
    //  Program counter
    // -----------------------------------------

    always_ff @(posedge clk) begin
        if ( reset ) begin
            pc_pc <= RESET_PC_ADDR;
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
    logic           [6:0]   if_opcode;
    logic           [4:0]   if_rd;
    logic           [4:0]   if_rs1;
    logic           [4:0]   if_rs2;
    logic           [2:0]   if_funct3;
    logic           [6:0]   if_funct7;

    logic   signed  [11:0]  if_imm_i;
    logic   signed  [11:0]  if_imm_s;
    logic   signed  [12:0]  if_imm_b;
    logic   signed  [31:0]  if_imm_u;
    logic   signed  [20:0]  if_imm_j;

    assign if_opcode = if_instr[6:0];
    assign if_rd     = if_instr[11:7];
    assign if_rs1    = if_instr[19:15];
    assign if_rs2    = if_instr[24:20];
    assign if_funct3 = if_instr[14:12];
    assign if_funct7 = if_instr[31:25];

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

    assign id_valid_next = if_valid && !branch_valid;

    assign id_opcode = id_instr[6:0];
    assign id_rd     = id_instr[11:7];
    assign id_rs1    = id_instr[19:15];
    assign id_rs2    = id_instr[24:20];
    assign id_funct3 = id_instr[14:12];
    assign id_funct7 = id_instr[31:25];
    assign id_imm_i  = id_instr[31:20];
    assign id_imm_s  = {id_instr[31:25], id_instr[11:7]};
    assign id_imm_b  = {id_instr[31], id_instr[7], id_instr[30:25], id_instr[11:8], 1'b0};
    assign id_imm_u  = {id_instr[31:12], 12'd0};
    assign id_imm_j  = {id_instr[31], id_instr[19:12], id_instr[20], id_instr[30:21], 1'b0};

    logic           [11:0]  id_imm_i_u;
    assign id_imm_i_u = id_imm_i;
    

    // register file
    jelly2_register_file_ram
            #(
                .READ_PORTS     (2),
                .ADDR_WIDTH     (5),
                .DATA_WIDTH     (32)
            )
        i_register_file
            (
                .reset,
                .clk,
                .cke,

                .wr_en          (wb_rd_en),
                .wr_addr        (wb_rd),
                .wr_din         (wb_rd_wdata),

                .rd_en          (2'b11),
                .rd_addr        ({if_rs2, if_rs1}),
                .rd_dout        ({id_rs2_rdata_raw, id_rs1_rdata_raw})
            );

    // forwarding
    always_ff @(posedge clk) begin
        id_rs1_forward <= id_rd_en && (id_rd == if_rs1);
        id_rs2_forward <= id_rd_en && (id_rd == if_rs2);
    end

    logic   signed  [31:0]      id_rs1_rdata;
    logic   signed  [31:0]      id_rs2_rdata;
    assign id_rs1_rdata = id_rs1_forward ? ex_rd_wdata : id_rs1_rdata_raw;
    assign id_rs2_rdata = id_rs2_forward ? ex_rd_wdata : id_rs2_rdata_raw;

    logic           [31:0]      id_rs1_rdata_u;
    logic           [31:0]      id_rs2_rdata_u;
    assign id_rs1_rdata_u = id_rs1_rdata;
    assign id_rs2_rdata_u = id_rs2_rdata;

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
    always_ff @(posedge clk) begin
        if ( reset ) begin
            id_rd_en  <= '0;
        end
        else if ( cke ) begin
            id_rd_en <= '0;
            if ( id_valid_next ) begin
                id_rd_en <= (if_rd != 0) & (
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



    // -----------------------------------------
    //  Execution
    // -----------------------------------------

    // branch
    always_comb begin
        branch_valid = 1'b0;
        branch_pc    = 'x;
        unique case (1'b1)
        id_dec_jal : begin branch_pc = id_pc                   + PC_WIDTH'(id_imm_j); branch_valid = 1'b1; end
        id_dec_jalr: begin branch_pc = PC_WIDTH'(id_rs1_rdata) + PC_WIDTH'(id_imm_i); branch_valid = 1'b1; end
        id_dec_beq : if ( id_rs1_rdata   == id_rs2_rdata   ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        id_dec_bne : if ( id_rs1_rdata   != id_rs2_rdata   ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        id_dec_blt : if ( id_rs1_rdata    < id_rs2_rdata   ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        id_dec_bge : if ( id_rs1_rdata   >= id_rs2_rdata   ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        id_dec_bltu: if ( id_rs1_rdata_u  < id_rs2_rdata_u ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        id_dec_bgeu: if ( id_rs1_rdata_u >= id_rs2_rdata_u ) begin branch_pc = id_pc + PC_WIDTH'(id_imm_b); branch_valid = 1'b1; end
        default: ;
        endcase

        if ( !id_valid ) begin
            branch_valid = 1'b0;
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
        id_dec_addi : ex_rd_wdata_alu <= id_rs1_rdata    + 32'(id_imm_i);
        id_dec_slti : ex_rd_wdata_alu <= (id_rs1_rdata   < 32'(id_imm_i)  ) ? 32'd1 : 32'd0;
        id_dec_sltiu: ex_rd_wdata_alu <= (id_rs1_rdata_u < 32'(id_imm_i_u)) ? 32'd1 : 32'd0;
        id_dec_xori : ex_rd_wdata_alu <= id_rs1_rdata    ^ 32'(id_imm_i);
        id_dec_ori  : ex_rd_wdata_alu <= id_rs1_rdata    | 32'(id_imm_i);
        id_dec_andi : ex_rd_wdata_alu <= id_rs1_rdata    & 32'(id_imm_i);
        id_dec_slli : ex_rd_wdata_alu <= id_rs1_rdata   << id_imm_i_u[4:0];
        id_dec_srli : ex_rd_wdata_alu <= id_rs1_rdata_u >> id_imm_i_u[4:0];
        id_dec_srai : ex_rd_wdata_alu <= id_rs1_rdata  >>> id_imm_i_u[4:0];
        id_dec_add  : ex_rd_wdata_alu <= id_rs1_rdata    + id_rs2_rdata;
        id_dec_sub  : ex_rd_wdata_alu <= id_rs1_rdata    - id_rs2_rdata;
        id_dec_sll  : ex_rd_wdata_alu <= id_rs1_rdata   << id_rs2_rdata_u[4:0];
        id_dec_slt  : ex_rd_wdata_alu <= (id_rs1_rdata   < id_rs2_rdata  ) ? 32'd1 : 32'd0;
        id_dec_sltu : ex_rd_wdata_alu <= (id_rs1_rdata_u < id_rs2_rdata_u) ? 32'd1 : 32'd0;
        id_dec_xor  : ex_rd_wdata_alu <= id_rs1_rdata    ^ id_rs2_rdata;
        id_dec_srl  : ex_rd_wdata_alu <= id_rs1_rdata_u >> id_rs2_rdata_u[4:0];
        id_dec_sra  : ex_rd_wdata_alu <= id_rs1_rdata  >>> id_rs2_rdata_u[4:0];
        id_dec_or   : ex_rd_wdata_alu <= id_rs1_rdata    | id_rs2_rdata;
        id_dec_and  : ex_rd_wdata_alu <= id_rs1_rdata    & id_rs2_rdata;
        default: ;
        endcase
    end

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
            ex_mem_rd    <= 1'b0;
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

            mem_addr = ex_fwd_rs1 + id_mem_offset;
            
            mem_wdata = ex_fwd_rs2;
            if ( XLEN >=  16 && mem_addr[0] )    begin   mem_wdata = mem_wdata <<  8; end;
            if ( XLEN >=  32 && mem_addr[1] )    begin   mem_wdata = mem_wdata << 16; end;
            if ( XLEN >=  64 && mem_addr[2] )    begin   mem_wdata = mem_wdata << 32; end;
            if ( XLEN >= 128 && mem_addr[3] )    begin   mem_wdata = mem_wdata << 64; end;

            mem_sel   = size_mask(id_mem_size);
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
           ma_valid  <= 1'b0;
           ma_pc     <= 'x;
           ma_instr  <= 'x;

           ma_rd_en  <= 1'b0;
           ma_rd_idx <= 'x;
           ma_rd_val <= 'x;
        end
        else if ( ma_cke ) begin
           ma_valid  <= ex_valid;
           ma_pc     <= ex_pc;
           ma_instr  <= ex_instr;

           ma_rd_en  <= ex_rd_en;
           ma_rd_idx <= ex_rd_idx;
           ma_rd_val <= ex_rd_val;
        end
    end

    logic                               ma_wait;
    logic                               ma_wait_en;
    logic                               ma_wait_re;
    logic                               ma_wait_we;
    logic           [XLEN-1:0]          ma_wait_addr;
    logic           [SIZE_WIDTH-1:0]    ma_wait_size;
    logic           [SEL_WIDTH-1:0]     ma_wait_sel;
    logic           [SEL_WIDTH-1:0]     ma_wait_rsel;
    logic           [SEL_WIDTH-1:0]     ma_wait_wsel;
    logic           [XLEN-1:0]          ma_wait_wdata;
    logic                               ma_wait_unsigned;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            ma_wait <= 1'b0;
        end
        else begin
            ma_wait <= dbus_wait;
        end
    end

    always_ff @(posedge clk) begin
        if ( ma_cke && !)
            ma_wait <= dbus_wait;
        end
    end


    always_ff @(posedge clk) begin
        if ( !ma_wait ) begin
            ma_wait_en       <= ex_mem_en;
            ma_wait_re       <= ex_mem_re;
            ma_wait_we       <= ex_mem_we;
            ma_wait_addr     <= ex_mem_addr;
            ma_wait_size     <= ex_mem_size;
            ma_wait_sel      <= ex_mem_sel;
            ma_wait_rsel     <= ex_mem_rsel;
            ma_wait_wsel     <= ex_mem_wsel;
            ma_wait_wdata    <= ex_mem_wdata;
            ma_wait_unsigned <= ex_mem_unsigned;
        end
    end

    // data-bus access
    assign dbus_en      = ma_wait ? ma_wait_en    : ex_mem_en;
    assign dbus_re      = ma_wait ? ma_wait_re    : ex_mem_re;
    assign dbus_we      = ma_wait ? ma_wait_we    : ex_mem_we;
    assign dbus_size    = ma_wait ? ma_wait_size  : ex_mem_size;
    assign dbus_addr    = ma_wait ? ma_wait_addr  : ex_mem_addr;
    assign dbus_sel     = ma_wait ? ma_wait_sel   : ex_mem_sel;
    assign dbus_rsel    = ma_wait ? ma_wait_rsel  : ex_mem_rsel;
    assign dbus_wsel    = ma_wait ? ma_wait_wsel  : ex_mem_wsel;
    assign dbus_wdata   = ma_wait ? ma_wait_wdata : ex_mem_wdata;

    wire    dus_unsigned;
    assign dus_unsigned = ma_wait ? ma_wait_unsigned : ex_mem_unsigned;
    assign ma_rdata     = dbus_rdata;
    assign ma_rvalid    = dbus_en & dbus_en;


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
            
            mem_rdata = ma_rdata;
            if ( XLEN >=  16 && dbus_addr[0] )    begin   mem_rdata = mem_rdata >>  8; end;
            if ( XLEN >=  32 && dbus_addr[1] )    begin   mem_rdata = mem_rdata >> 16; end;
            if ( XLEN >=  64 && dbus_addr[2] )    begin   mem_rdata = mem_rdata >> 32; end;
            if ( XLEN >= 128 && dbus_addr[3] )    begin   mem_rdata = mem_rdata >> 64; end;

            if ( dus_unsigned ) begin
                if ( XLEN >=  16 && int'(dbus_size) == 0 )  begin   rdata = XLEN'($unsigned(mem_rdatal[ 7:0])); end
                if ( XLEN >=  32 && int'(dbus_size) == 1 )  begin   rdata = XLEN'($unsigned(mem_rdatal[15:0])); end
                if ( XLEN >=  64 && int'(dbus_size) == 2 )  begin   rdata = XLEN'($unsigned(mem_rdatal[31:0])); end
                if ( XLEN >= 128 && int'(dbus_size) == 3 )  begin   rdata = XLEN'($unsigned(mem_rdatal[63:0])); end
            end
            else begin
                if ( XLEN >=  16 && int'(dbus_size) == 0 )  begin   rdata = XLEN'($signed(mem_rdatal[ 7:0])); end
                if ( XLEN >=  32 && int'(dbus_size) == 1 )  begin   rdata = XLEN'($signed(mem_rdatal[15:0])); end
                if ( XLEN >=  64 && int'(dbus_size) == 2 )  begin   rdata = XLEN'($signed(mem_rdatal[31:0])); end
                if ( XLEN >= 128 && int'(dbus_size) == 3 )  begin   rdata = XLEN'($signed(mem_rdatal[63:0])); end
            end

            wb_rd_en  <= ma_rd_en || ma_rvalid;
            wb_rd_idx <= ma_rd_idx;
            wb_rd_val <= ma_rvalid ? rdata : ma_rd_val;
        end
    end
    
endmodule


`default_nettype wire


// End of file
