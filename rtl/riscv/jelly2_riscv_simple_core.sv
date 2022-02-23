// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_riscv_simple_core
        #(
            parameter int                   IBUS_ADDR_WIDTH = 14,
            parameter int                   DBUS_ADDR_WIDTH = 14,
            parameter int                   PC_WIDTH        = IBUS_ADDR_WIDTH,
            parameter bit   [PC_WIDTH-1:0]  RESET_PC_ADDR   = '0
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,

            output  wire    [IBUS_ADDR_WIDTH-1:0]   ibus_addr,
            input   wire    [31:0]                  ibus_rdata,

            output  reg     [DBUS_ADDR_WIDTH-1:0]   dbus_addr,
            output  reg                             dbus_rd,
            output  reg     [3:0]                   dbus_we,
            output  reg     [31:0]                  dbus_wdata,
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

    // 
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
            if_valid <= 1'b1;
        end
    end


    // Instruction Fetch
    assign ibus_addr  = pc_pc;
    assign if_instr = ibus_rdata;


    // decocde
    logic           [6:0]   if_opcode;
    logic           [4:0]   if_rd;
    logic           [4:0]   if_rs1;
    logic           [4:0]   if_rs2;
    logic           [2:0]   if_funct3;
    logic           [6:0]   if_funct7;

    logic   signed  [11:0]  if_i_imm;
    logic   signed  [11:0]  if_s_imm;
    logic   signed  [12:0]  if_b_imm;
    logic   signed  [31:0]  if_u_imm;
    logic   signed  [20:0]  if_j_imm;

    assign if_opcode = if_instr[6:0];
    assign if_rd     = if_instr[11:7];
    assign if_rs1    = if_instr[19:15];
    assign if_rs2    = if_instr[24:20];
    assign if_funct3 = if_instr[14:12];
    assign if_funct7 = if_instr[31:25];

    assign if_i_imm  = if_instr[31:20];
    assign if_s_imm  = {if_instr[31:25], if_instr[11:7]};
    assign if_b_imm  = {if_instr[31], if_instr[7], if_instr[30:25], if_instr[11:8], 1'b0};
    assign if_u_imm  = {if_instr[31:12], 12'd0};
    assign if_j_imm  = {if_instr[31], if_instr[19:12], if_instr[20], if_instr[30:21], 1'b0};
    

    wire    if_lui    = (if_opcode == 7'b0110111);
    wire    if_auipc  = (if_opcode == 7'b0010111);
    wire    if_jal    = (if_opcode == 7'b1101111);
    wire    if_jalr   = (if_opcode == 7'b1100111 && if_funct3 == 3'b000);
    wire    if_beq    = (if_opcode == 7'b1100011 && if_funct3 == 3'b000);
    wire    if_bne    = (if_opcode == 7'b1100011 && if_funct3 == 3'b001);
    wire    if_blt    = (if_opcode == 7'b1100011 && if_funct3 == 3'b100);
    wire    if_bge    = (if_opcode == 7'b1100011 && if_funct3 == 3'b101);
    wire    if_bltu   = (if_opcode == 7'b1100011 && if_funct3 == 3'b110);
    wire    if_bgeu   = (if_opcode == 7'b1100011 && if_funct3 == 3'b111);
    wire    if_lb     = (if_opcode == 7'b0000011 && if_funct3 == 3'b000);
    wire    if_lh     = (if_opcode == 7'b0000011 && if_funct3 == 3'b001);
    wire    if_lw     = (if_opcode == 7'b0000011 && if_funct3 == 3'b010);
    wire    if_lbu    = (if_opcode == 7'b0000011 && if_funct3 == 3'b100);
    wire    if_lhu    = (if_opcode == 7'b0000011 && if_funct3 == 3'b101);
    wire    if_sb     = (if_opcode == 7'b0100011 && if_funct3 == 3'b000);
    wire    if_sh     = (if_opcode == 7'b0100011 && if_funct3 == 3'b001);
    wire    if_sw     = (if_opcode == 7'b0100011 && if_funct3 == 3'b010);
    wire    if_addi   = (if_opcode == 7'b0010011 && if_funct3 == 3'b000);
    wire    if_slti   = (if_opcode == 7'b0010011 && if_funct3 == 3'b010);
    wire    if_sltiu  = (if_opcode == 7'b0010011 && if_funct3 == 3'b011);
    wire    if_xori   = (if_opcode == 7'b0010011 && if_funct3 == 3'b100);
    wire    if_ori    = (if_opcode == 7'b0010011 && if_funct3 == 3'b110);
    wire    if_andi   = (if_opcode == 7'b0010011 && if_funct3 == 3'b111);
    wire    if_slli   = (if_opcode == 7'b0010011 && if_funct3 == 3'b001 && if_funct7 == 7'b0000000);
    wire    if_srli   = (if_opcode == 7'b0010011 && if_funct3 == 3'b101 && if_funct7 == 7'b0000000);
    wire    if_srai   = (if_opcode == 7'b0010011 && if_funct3 == 3'b101 && if_funct7 == 7'b0100000);
    wire    if_add    = (if_opcode == 7'b0110011 && if_funct3 == 3'b000 && if_funct7 == 7'b0000000);
    wire    if_sub    = (if_opcode == 7'b0110011 && if_funct3 == 3'b000 && if_funct7 == 7'b0100000);
    wire    if_sll    = (if_opcode == 7'b0110011 && if_funct3 == 3'b001 && if_funct7 == 7'b0000000);
    wire    if_slt    = (if_opcode == 7'b0110011 && if_funct3 == 3'b010 && if_funct7 == 7'b0000000);
    wire    if_sltu   = (if_opcode == 7'b0110011 && if_funct3 == 3'b011 && if_funct7 == 7'b0000000);
    wire    if_xor    = (if_opcode == 7'b0110011 && if_funct3 == 3'b100 && if_funct7 == 7'b0000000);
    wire    if_srl    = (if_opcode == 7'b0110011 && if_funct3 == 3'b101 && if_funct7 == 7'b0000000);
    wire    if_sra    = (if_opcode == 7'b0110011 && if_funct3 == 3'b101 && if_funct7 == 7'b0100000);
    wire    if_or     = (if_opcode == 7'b0110011 && if_funct3 == 3'b110 && if_funct7 == 7'b0000000);
    wire    if_and    = (if_opcode == 7'b0110011 && if_funct3 == 3'b111 && if_funct7 == 7'b0000000);
    wire    if_fence  = (if_opcode == 7'b0001111);
    wire    if_ecall  = (if_instr == 32'h00000073);
    wire    if_ebreak = (if_instr == 32'h00100073);
    
    

    // -----------------------------------------
    //  Instruction Decode
    // -----------------------------------------

    logic   [PC_WIDTH-1:0]      ex_expect_pc_next;

    logic   [PC_WIDTH-1:0]      id_pc;
    logic   [31:0]              id_instr;
    logic                       id_valid, id_valid_next;

    // 将来分岐キャッシュとかやる用に当たり判定してみる
    assign id_valid_next = if_valid && (if_pc == ex_expect_pc_next);

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

    logic           [6:0]   id_opcode;
    logic           [4:0]   id_rd;
    logic           [4:0]   id_rs1;
    logic           [4:0]   id_rs2;
    logic           [2:0]   id_funct3;
    logic           [6:0]   id_funct7;

    logic   signed  [11:0]  id_i_imm;
    logic   signed  [11:0]  id_s_imm;
    logic   signed  [12:0]  id_b_imm;
    logic   signed  [31:0]  id_u_imm;
    logic   signed  [20:0]  id_j_imm;

    assign id_opcode = id_instr[6:0];
    assign id_rd     = id_instr[11:7];
    assign id_rs1    = id_instr[19:15];
    assign id_rs2    = id_instr[24:20];
    assign id_funct3 = id_instr[14:12];
    assign id_funct7 = id_instr[31:25];
    assign id_i_imm  = id_instr[31:20];
    assign id_s_imm  = {id_instr[31:25], id_instr[11:7]};
    assign id_b_imm  = {id_instr[31], id_instr[7], id_instr[30:25], id_instr[11:8], 1'b0};
    assign id_u_imm  = {id_instr[31:12], 12'd0};
    assign id_j_imm  = {id_instr[31], id_instr[19:12], id_instr[20], id_instr[30:21], 1'b0};

    logic           [11:0]  id_i_imm_u;
    logic           [11:0]  id_s_imm_u;
    logic           [12:0]  id_b_imm_u;
    logic           [31:0]  id_u_imm_u;
    logic           [20:0]  id_j_imm_u;
    assign id_i_imm_u = id_i_imm;
    assign id_s_imm_u = id_s_imm;
    assign id_b_imm_u = id_b_imm;
    assign id_u_imm_u = id_u_imm;
    assign id_j_imm_u = id_j_imm;


    // register file
    logic                       ex_rd_en;
    logic           [4:0]       ex_rd;
    logic           [31:0]      ex_rd_wdata;

    logic   signed  [31:0]      id_rs1_rdata;
    logic   signed  [31:0]      id_rs2_rdata;

    jelly2_register_file
            #(
                .WRITE_PORTS    (1),
                .READ_PORTS     (2),
                .ADDR_WIDTH     (5),
                .DATA_WIDTH     (32),
                .ZERO_REG       (0)
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
                .rd_dout        ({id_rs2_rdata, id_rs1_rdata})
            );

    logic           [31:0]      id_rs1_rdata_u;
    logic           [31:0]      id_rs2_rdata_u;
    assign id_rs1_rdata_u = id_rs1_rdata;
    assign id_rs2_rdata_u = id_rs2_rdata;



    // instruction decode
    logic    id_lui   ;
    logic    id_auipc ;
    logic    id_jal   ;
    logic    id_jalr  ;
    logic    id_beq   ;
    logic    id_bne   ;
    logic    id_blt   ;
    logic    id_bge   ;
    logic    id_bltu  ;
    logic    id_bgeu  ;
    logic    id_lb    ;
    logic    id_lh    ;
    logic    id_lw    ;
    logic    id_lbu   ;
    logic    id_lhu   ;
    logic    id_sb    ;
    logic    id_sh    ;
    logic    id_sw    ;
    logic    id_addi  ;
    logic    id_slti  ;
    logic    id_sltiu ;
    logic    id_xori  ;
    logic    id_ori   ;
    logic    id_andi  ;
    logic    id_slli  ;
    logic    id_srli  ;
    logic    id_srai  ;
    logic    id_add   ;
    logic    id_sub   ;
    logic    id_sll   ;
    logic    id_slt   ;
    logic    id_sltu  ;
    logic    id_xor   ;
    logic    id_srl   ;
    logic    id_sra   ;
    logic    id_or    ;
    logic    id_and   ;
    logic    id_fence ;
    logic    id_ecall ;
    logic    id_ebreak;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            id_lui    <= 1'b0;
            id_auipc  <= 1'b0;
            id_jal    <= 1'b0;
            id_jalr   <= 1'b0;
            id_beq    <= 1'b0;
            id_bne    <= 1'b0;
            id_blt    <= 1'b0;
            id_bge    <= 1'b0;
            id_bltu   <= 1'b0;
            id_bgeu   <= 1'b0;
            id_lb     <= 1'b0;
            id_lh     <= 1'b0;
            id_lw     <= 1'b0;
            id_lbu    <= 1'b0;
            id_lhu    <= 1'b0;
            id_sb     <= 1'b0;
            id_sh     <= 1'b0;
            id_sw     <= 1'b0;
            id_addi   <= 1'b0;
            id_slti   <= 1'b0;
            id_sltiu  <= 1'b0;
            id_xori   <= 1'b0;
            id_ori    <= 1'b0;
            id_andi   <= 1'b0;
            id_slli   <= 1'b0;
            id_srli   <= 1'b0;
            id_srai   <= 1'b0;
            id_add    <= 1'b0;
            id_sub    <= 1'b0;
            id_sll    <= 1'b0;
            id_slt    <= 1'b0;
            id_sltu   <= 1'b0;
            id_xor    <= 1'b0;
            id_srl    <= 1'b0;
            id_sra    <= 1'b0;
            id_or     <= 1'b0;
            id_and    <= 1'b0;
            id_fence  <= 1'b0;
            id_ecall  <= 1'b0;
            id_ebreak <= 1'b0;
        end
        else if ( cke ) begin
            id_lui    <= if_lui    & if_valid;
            id_auipc  <= if_auipc  & if_valid;
            id_jal    <= if_jal    & if_valid;
            id_jalr   <= if_jalr   & if_valid;
            id_beq    <= if_beq    & if_valid;
            id_bne    <= if_bne    & if_valid;
            id_blt    <= if_blt    & if_valid;
            id_bge    <= if_bge    & if_valid;
            id_bltu   <= if_bltu   & if_valid;
            id_bgeu   <= if_bgeu   & if_valid;
            id_lb     <= if_lb     & if_valid;
            id_lh     <= if_lh     & if_valid;
            id_lw     <= if_lw     & if_valid;
            id_lbu    <= if_lbu    & if_valid;
            id_lhu    <= if_lhu    & if_valid;
            id_sb     <= if_sb     & if_valid;
            id_sh     <= if_sh     & if_valid;
            id_sw     <= if_sw     & if_valid;
            id_addi   <= if_addi   & if_valid;
            id_slti   <= if_slti   & if_valid;
            id_sltiu  <= if_sltiu  & if_valid;
            id_xori   <= if_xori   & if_valid;
            id_ori    <= if_ori    & if_valid;
            id_andi   <= if_andi   & if_valid;
            id_slli   <= if_slli   & if_valid;
            id_srli   <= if_srli   & if_valid;
            id_srai   <= if_srai   & if_valid;
            id_add    <= if_add    & if_valid;
            id_sub    <= if_sub    & if_valid;
            id_sll    <= if_sll    & if_valid;
            id_slt    <= if_slt    & if_valid;
            id_sltu   <= if_sltu   & if_valid;
            id_xor    <= if_xor    & if_valid;
            id_srl    <= if_srl    & if_valid;
            id_sra    <= if_sra    & if_valid;
            id_or     <= if_or     & if_valid;
            id_and    <= if_and    & if_valid;
            id_fence  <= if_fence  & if_valid;
            id_ecall  <= if_ecall  & if_valid;
            id_ebreak <= if_ebreak & if_valid;
        end
    end

    logic   signed  [31:0]                  id_mem_offset;
    logic                                   id_mem_rd;
    logic                                   id_mem_we;
    logic           [1:0]                   id_mem_sel;
    logic                                   id_mem_unsigned;
    always_ff @(posedge clk) begin
        if ( reset ) begin
        end
        else if ( cke ) begin
            id_mem_offset   <= 'x;
            id_mem_rd       <= 1'b0;
            id_mem_we       <= '0;
            id_mem_sel      <= 'x;
            id_mem_unsigned <= 1'bx;
            if ( id_valid_next ) begin
                id_mem_sel    <= if_funct3[1:0];
                if ( if_lb || if_lh || if_lw || if_lbu || if_lhu ) begin
                    id_mem_rd       <= 1'b1;
                    id_mem_offset   <= 32'(if_i_imm);
                    id_mem_unsigned <= (if_lbu || if_lhu);
                end
                if ( if_sb || if_sh ||  if_sw ) begin
                    id_mem_we     <= 1'b1;
                    id_mem_offset <= 32'(if_s_imm);
                end
            end
        end
    end


    // -----------------------------------------
    //  Execution
    // -----------------------------------------

    logic   [PC_WIDTH-1:0]      ex_pc_next;

    logic   [PC_WIDTH-1:0]      ex_pc;
    logic   [31:0]              ex_instr;
    logic                       ex_valid;

    always_ff @(posedge clk) begin
        if ( reset ) begin            
            ex_pc    <= RESET_PC_ADDR;
            ex_instr <= '0;
            ex_valid <= 1'b0;
        end
        else if ( cke ) begin
            ex_pc    <= id_pc;
            ex_instr <= id_instr;
            ex_valid <= id_valid;
        end
    end

    // branch
    always_comb begin
        ex_pc_next = ex_pc + 4;
        unique case (1'b1)
        id_jal : ex_expect_pc_next = id_pc                   + PC_WIDTH'(id_j_imm);
        id_jalr: ex_expect_pc_next = PC_WIDTH'(id_rs1_rdata) + PC_WIDTH'(id_i_imm);
        id_beq : if ( id_rs1_rdata == id_rs2_rdata ) ex_expect_pc_next = id_pc + PC_WIDTH'(id_b_imm);
        id_bne : if ( id_rs1_rdata != id_rs2_rdata ) ex_expect_pc_next = id_pc + PC_WIDTH'(id_b_imm);
        id_blt : if ( $signed(id_rs1_rdata)  < $signed(id_rs2_rdata) ) ex_expect_pc_next = id_pc + PC_WIDTH'(id_b_imm);
        id_bge : if ( $signed(id_rs1_rdata) >= $signed(id_rs2_rdata) ) ex_expect_pc_next = id_pc + PC_WIDTH'(id_b_imm);
        id_bltu: if ( $unsigned(id_rs1_rdata)  < $unsigned(id_rs2_rdata) ) ex_expect_pc_next = id_pc + PC_WIDTH'(id_b_imm);
        id_bgeu: if ( $unsigned(id_rs1_rdata) >= $unsigned(id_rs2_rdata) ) ex_expect_pc_next = id_pc + PC_WIDTH'(id_b_imm);
        default: ;
        endcase

        if ( !id_valid ) begin
            ex_pc_next = ex_pc;
        end
    end


    // alu
    logic   signed  [31:0]  id_rd_wdata_alu;
    always_comb begin
        id_rd_wdata_alu = '0;
        unique case (1'b1)
        id_addi : id_rd_wdata_alu = id_rs1_rdata    + 32'(id_i_imm);
        id_slti : id_rd_wdata_alu = (id_rs1_rdata   < 32'(id_i_imm)  ) ? 32'd1 : 32'd0;
        id_sltiu: id_rd_wdata_alu = (id_rs1_rdata_u < 32'(id_i_imm_u)) ? 32'd1 : 32'd0;
        id_xori : id_rd_wdata_alu = id_rs1_rdata    ^ 32'(id_i_imm);
        id_ori  : id_rd_wdata_alu = id_rs1_rdata    | 32'(id_i_imm);
        id_andi : id_rd_wdata_alu = id_rs1_rdata    & 32'(id_i_imm);
        id_slli : id_rd_wdata_alu = id_rs1_rdata   << id_i_imm_u[4:0];
        id_srli : id_rd_wdata_alu = id_rs1_rdata_u >> id_i_imm_u[4:0];
        id_srai : id_rd_wdata_alu = id_rs1_rdata  >>> id_i_imm_u[4:0];
        id_add  : id_rd_wdata_alu = id_rs1_rdata    + id_rs2_rdata;
        id_sub  : id_rd_wdata_alu = id_rs1_rdata    - id_rs2_rdata;
        id_sll  : id_rd_wdata_alu = id_rs1_rdata   << id_rs2_rdata_u[4:0];
        id_slt  : id_rd_wdata_alu = (id_rs1_rdata   < id_rs2_rdata  ) ? 32'd1 : 32'd0;
        id_sltu : id_rd_wdata_alu = (id_rs1_rdata_u < id_rs2_rdata_u) ? 32'd1 : 32'd0;
        id_xor  : id_rd_wdata_alu = id_rs1_rdata    ^ id_rs2_rdata;
        id_srl  : id_rd_wdata_alu = id_rs1_rdata_u >> id_rs2_rdata_u[4:0];
        id_sra  : id_rd_wdata_alu = id_rs1_rdata  >>> id_rs2_rdata_u[4:0];
        id_or   : id_rd_wdata_alu = id_rs1_rdata    | id_rs2_rdata;
        id_and  : id_rd_wdata_alu = id_rs1_rdata    & id_rs2_rdata;
        default: ;
        endcase
    end


    // dbus access
    logic                       dbus_alignment_error;
    logic   [1:0]               dbus_addr_lo;
    always_comb begin
        automatic   logic   [31:0]  addr;
        addr       = id_rs1_rdata + id_mem_offset;
        dbus_rd    = id_mem_rd;
        dbus_we    = '0;
        dbus_wdata = 'x;
        dbus_alignment_error = 1'b0;
        if ( id_mem_we ) begin
            if ( id_mem_sel[1] ) begin
                dbus_we = 4'b1111;
                dbus_wdata = id_rs2_rdata;
                dbus_alignment_error = (addr[1:0] != 2'b00);
            end
            else if ( id_mem_sel[0] ) begin
                dbus_we[0] = (addr[1] == 1'b0);
                dbus_we[1] = (addr[1] == 1'b0);
                dbus_we[2] = (addr[1] == 1'b1);
                dbus_we[3] = (addr[1] == 1'b1);
                dbus_wdata = {2{id_rs2_rdata[15:0]}};
                dbus_alignment_error = (addr[0] != 1'b0);
            end
            else begin
                dbus_we[0] = (addr[1:0] == 2'b00);
                dbus_we[1] = (addr[1:0] == 2'b01);
                dbus_we[2] = (addr[1:0] == 2'b10);
                dbus_we[3] = (addr[1:0] == 2'b11);
                dbus_wdata = {4{id_rs2_rdata[7:0]}};
            end
        end
        dbus_addr_lo = addr[1:0];
        dbus_addr    = DBUS_ADDR_WIDTH'(addr[31:2]);
    end

    logic                                   ex_mem_rd;
    logic           [1:0]                   ex_mem_addr;
    logic           [1:0]                   ex_mem_sel;
    logic                                   ex_mem_unsigned;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            ex_mem_rd       <= 1'b0;
            ex_mem_addr     <= 'x;
            ex_mem_sel      <= 'x;
            ex_mem_unsigned <= 1'bx;
        end
        else if ( cke ) begin
            ex_mem_rd       <= id_mem_rd;
            ex_mem_addr     <= dbus_addr_lo;
            ex_mem_sel      <= id_mem_sel;
            ex_mem_unsigned <= id_mem_unsigned;
        end
    end

    logic   signed  [31:0]  id_rd_wdata_mem;
    always_comb begin
        id_rd_wdata_mem = 'x;
        if ( ex_mem_sel[1] ) begin
            id_rd_wdata_mem = dbus_rdata;
        end
        else begin
            if ( ex_mem_unsigned ) begin
                if ( id_mem_sel[0] ) begin
                    case ( ex_mem_addr[1] )
                    1'b0:   id_rd_wdata_mem = 32'($unsigned(dbus_rdata[15:0]));
                    1'b1:   id_rd_wdata_mem = 32'($unsigned(dbus_rdata[31:16]));
                    endcase
                end
                else begin
                    case ( ex_mem_addr[1:0] )
                    2'b00:   id_rd_wdata_mem = 32'($unsigned(dbus_rdata[7:0]));
                    2'b01:   id_rd_wdata_mem = 32'($unsigned(dbus_rdata[15:8]));
                    2'b10:   id_rd_wdata_mem = 32'($unsigned(dbus_rdata[23:16]));
                    2'b11:   id_rd_wdata_mem = 32'($unsigned(dbus_rdata[31:24]));
                    endcase
                end
            end
            else begin
                if ( id_mem_sel[0] ) begin
                    case ( ex_mem_addr[1] )
                    1'b0:   id_rd_wdata_mem = 32'($signed(dbus_rdata[15:0]));
                    1'b1:   id_rd_wdata_mem = 32'($signed(dbus_rdata[31:16]));
                    endcase
                end
                else begin
                    case ( ex_mem_addr[1:0] )
                    2'b00:   id_rd_wdata_mem = 32'($signed(dbus_rdata[7:0]));
                    2'b01:   id_rd_wdata_mem = 32'($signed(dbus_rdata[15:8]));
                    2'b10:   id_rd_wdata_mem = 32'($signed(dbus_rdata[23:16]));
                    2'b11:   id_rd_wdata_mem = 32'($signed(dbus_rdata[31:24]));
                    endcase
                end
            end
        end
    end

    logic   signed  [31:0]  id_rd_wdata;
    always_comb begin
        id_rd_wdata = ex_mem_rd ? id_rd_wdata_mem : id_rd_wdata_alu;
    end


    always_ff @(posedge clk) begin
        if ( reset ) begin

        end
        else if ( cke ) begin
            
        end
    end

    // if, id, ex, wb



endmodule


`default_nettype wire


// End of file
