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

            output  wire    [DBUS_ADDR_WIDTH-1:0]   dbus_addr,
            output  wire                            dbus_rd,
            output  wire                            dbus_wr,
            output  wire    [3:0]                   dbus_sel,
            output  wire    [31:0]                  dbus_wdata,
            input   wire    [31:0]                  dbus_rdata
        );


    // -----------------------------------------
    //  Program counter
    // -----------------------------------------

    logic   [PC_WIDTH-1:0]      branch_pc;
    logic                       branch_valid;


    logic   [PC_WIDTH-1:0]      pc_pc;

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
    logic   [PC_WIDTH-1:0]      if_pc;
    logic   [31:0]              if_instr;
    logic                       if_valid;

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

    logic   [PC_WIDTH-1:0]      id_pc;
    logic   [31:0]              id_instr;
    logic                       id_valid, id_valid_next;

    assign id_valid_next = if_valid && !branch_valid;


    // 命令デコード
    logic           [6:0]   id_opcode;
    logic           [4:0]   id_rd;
    logic           [4:0]   id_rs1;
    logic           [4:0]   id_rs2;
    logic           [2:0]   id_funct3;
    logic           [6:0]   id_funct7;

    logic   signed  [11:0]  id_imm_i;
    logic   signed  [11:0]  id_imm_s;
    logic   signed  [12:0]  id_imm_b;
    logic   signed  [31:0]  id_imm_u;
    logic   signed  [20:0]  id_imm_j;

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
    logic                       ex_rd_en;
    logic           [4:0]       ex_rd;
    logic           [31:0]      ex_rd_wdata;

    logic                       id_rd_en;
    logic   signed  [31:0]      id_rs1_rdata_raw;
    logic   signed  [31:0]      id_rs2_rdata_raw;

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

                .wr_en          (ex_rd_en),
                .wr_addr        (ex_rd),
                .wr_din         (ex_rd_wdata),

                .rd_en          (2'b11),
                .rd_addr        ({if_rs2, if_rs1}),
                .rd_dout        ({id_rs2_rdata_raw, id_rs1_rdata_raw})
            );

    // forwarding
    logic   id_rs1_forward;
    logic   id_rs2_forward;
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

    logic   [PC_WIDTH-1:0]      ex_pc;
    logic   [31:0]              ex_instr;
    logic                       ex_valid;

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


    // dbus access
    assign dbus_addr  = id_rs1_rdata + id_mem_offset;
    assign dbus_rd    = id_mem_rd;
    assign dbus_wr    = id_mem_wr;
    assign dbus_sel   = id_mem_sel;
    assign dbus_wdata = id_rs2_rdata;

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

    logic   signed  [31:0]  ex_rd_wdata_mem;
    always_comb begin
        ex_rd_wdata_mem = 'x;
        if ( ex_mem_rd ) begin
            ex_rd_wdata_mem = dbus_rdata;
            if ( ex_mem_unsigned ) begin
                case ( ex_mem_size )
                2'b00:      ex_rd_wdata_mem = 32'($unsigned(dbus_rdata[7:0]));
                2'b01:      ex_rd_wdata_mem = 32'($unsigned(dbus_rdata[15:0]));
                default:    ex_rd_wdata_mem = 32'($unsigned(dbus_rdata[31:0]));
                endcase
            end
            else begin
                case ( ex_mem_size )
                2'b00:      ex_rd_wdata_mem = 32'($signed(dbus_rdata[7:0]));
                2'b01:      ex_rd_wdata_mem = 32'($signed(dbus_rdata[15:0]));
                default:    ex_rd_wdata_mem = 32'($signed(dbus_rdata[31:0]));
                endcase
            end
        end
    end

    always_comb begin
        ex_rd_wdata = ex_mem_rd ? ex_rd_wdata_mem : ex_rd_wdata_alu;
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin            
            ex_rd_en     <= 1'b0;
            ex_rd        <= 'x;
            ex_pc        <= 'x;
            ex_instr     <= 'x;
            ex_valid     <= 1'b0;
        end
        else if ( cke ) begin
            ex_rd_en     <= id_rd_en;
            ex_rd        <= id_rd;
            ex_pc        <= id_pc;
            ex_instr     <= id_instr;
            ex_valid     <= id_valid;
        end
    end
    
endmodule


`default_nettype wire


// End of file
