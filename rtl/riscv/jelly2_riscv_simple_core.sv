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
            parameter int   IBUS_ADDR_WIDTH = 12,
            parameter int   DBUS_ADDR_WIDTH = 14
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,

            output  wire    [IBUS_ADDR_WIDTH-1:0]   ibus_addr,
            input   wire    [31:0]                  ibus_rdata,

            output  wire    [DBUS_ADDR_WIDTH-1:0]   dbus_addr,
            output  wire                            dbus_rd,
            output  wire    [3:0]                   dbus_we,
            output  wire    [31:0]                  dbus_wdata,
            input   wire    [31:0]                  dbus_rdata
        );

    localparam  PC_WIDTH = IBUS_ADDR_WIDTH;


    // -----------------------------------------
    //  Instruction Fetch
    // -----------------------------------------

    logic   [PC_WIDTH-1:0]      branch_pc;
    logic                       branch_valid;

    logic   [PC_WIDTH-1:0]      if_pc;
    logic   [31:0]              if_instr;
    logic                       if_valid;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            if_pc    <= '0;
            if_valid <= 1'b0;
        end
        else if ( cke ) begin
            if ( branch_valid ) begin
                if_pc <= if_pc + PC_WIDTH'(4);
            end
            else begin
                if_pc <= branch_pc;
            end
            if_valid <= 1'b1;
        end
    end

    assign ibus_addr  = if_pc;

    assign if_instr = ibus_rdata;

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
    
    
    
    // -----------------------------------------
    //  Instruction Decode
    // -----------------------------------------

    logic   [PC_WIDTH-1:0]      id_pc;
    logic   [31:0]              id_instr;
    logic                       id_valid;

    always_ff @(posedge clk) begin
        if ( reset ) begin            
            id_pc    <= '0;
            id_instr <= '0;
            id_valid <= 1'b0;
        end
        else if ( cke ) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
            id_valid <= if_valid;
        end
    end


    logic   [31:0]      id_rs1_data;
    logic   [31:0]      id_rs2_data;

    // レジスタファイル
    jelly_register_file
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

                .wr_en          (1'b0),
                .wr_addr        (),
                .wr_din         (),

                .rd_en          (2'b11),
                .rd_addr        ({if_instr_rs2, if_instr_rs1}),
                .rd_dout        ({id_rs2_data, id_rs1_data})
            );
    

    wire    id_dec_lui    = (if_opcode == 7'b0110111);
    wire    id_dec_auipc  = (if_opcode == 7'b0010111);
    wire    id_dec_jal    = (if_opcode == 7'b1101111);
    wire    id_dec_jalr   = (if_opcode == 7'b1100111 && if_funct3 == 3'b000);
    wire    id_dec_beq    = (if_opcode == 7'b1100011 && if_funct3 == 3'b000);
    wire    id_dec_bne    = (if_opcode == 7'b1100011 && if_funct3 == 3'b001);
    wire    id_dec_blt    = (if_opcode == 7'b1100011 && if_funct3 == 3'b100);
    wire    id_dec_bge    = (if_opcode == 7'b1100011 && if_funct3 == 3'b101);
    wire    id_dec_bltu   = (if_opcode == 7'b1100011 && if_funct3 == 3'b110);
    wire    id_dec_bgeu   = (if_opcode == 7'b1100011 && if_funct3 == 3'b111);
 
    wire    id_dec_lb     = (if_opcode == 7'b0000011 && if_funct3 == 3'b000);
    wire    id_dec_lh     = (if_opcode == 7'b0000011 && if_funct3 == 3'b001);
    wire    id_dec_lw     = (if_opcode == 7'b0000011 && if_funct3 == 3'b010);
    wire    id_dec_lbu    = (if_opcode == 7'b0000011 && if_funct3 == 3'b100);
    wire    id_dec_lhu    = (if_opcode == 7'b0000011 && if_funct3 == 3'b101);
    wire    id_dec_sb     = (if_opcode == 7'b0100011 && if_funct3 == 3'b000);
    wire    id_dec_sh     = (if_opcode == 7'b0100011 && if_funct3 == 3'b001);
    wire    id_dec_sw     = (if_opcode == 7'b0100011 && if_funct3 == 3'b010);
 
    wire    id_dec_addi   = (if_opcode == 7'b0010011 && if_funct3 == 3'b000);
    wire    id_dec_slti   = (if_opcode == 7'b0010011 && if_funct3 == 3'b010);
    wire    id_dec_sltiu  = (if_opcode == 7'b0010011 && if_funct3 == 3'b011);
    wire    id_dec_xori   = (if_opcode == 7'b0010011 && if_funct3 == 3'b100);
    wire    id_dec_ori    = (if_opcode == 7'b0010011 && if_funct3 == 3'b110);
    wire    id_dec_andi   = (if_opcode == 7'b0010011 && if_funct3 == 3'b111);
    
    wire    id_dec_slli   = (if_opcode == 7'b0010011 && if_funct3 == 3'b001 && if_funct7 == 7'b0000000);
    wire    id_dec_srli   = (if_opcode == 7'b0010011 && if_funct3 == 3'b101 && if_funct7 == 7'b0000000);
    wire    id_dec_srai   = (if_opcode == 7'b0010011 && if_funct3 == 3'b101 && if_funct7 == 7'b0100000);
 
    wire    id_dec_add    = (if_opcode == 7'b0110011 && if_funct3 == 3'b000 && if_funct7 == 7'b0000000);
    wire    id_dec_sub    = (if_opcode == 7'b0110011 && if_funct3 == 3'b000 && if_funct7 == 7'b0100000);
    wire    id_dec_sll    = (if_opcode == 7'b0110011 && if_funct3 == 3'b001 && if_funct7 == 7'b0000000);
    wire    id_dec_slt    = (if_opcode == 7'b0110011 && if_funct3 == 3'b010 && if_funct7 == 7'b0000000);
    wire    id_dec_sltu   = (if_opcode == 7'b0110011 && if_funct3 == 3'b011 && if_funct7 == 7'b0000000);
    wire    id_dec_xor    = (if_opcode == 7'b0110011 && if_funct3 == 3'b100 && if_funct7 == 7'b0000000);
    wire    id_dec_srl    = (if_opcode == 7'b0110011 && if_funct3 == 3'b101 && if_funct7 == 7'b0000000);
    wire    id_dec_sra    = (if_opcode == 7'b0110011 && if_funct3 == 3'b101 && if_funct7 == 7'b0100000);
    wire    id_dec_or     = (if_opcode == 7'b0110011 && if_funct3 == 3'b110 && if_funct7 == 7'b0000000);
    wire    id_dec_and    = (if_opcode == 7'b0110011 && if_funct3 == 3'b111 && if_funct7 == 7'b0000000);

    wire    id_dec_fence  = (if_opcode == 7'b0001111);
    wire    id_dec_ecall  = (if_instr == 32'h00000073);
    wire    id_dec_ebreak = (if_instr == 32'h00100073);


    logic           id_lui;
    logic           id_auipc;
    logic           id_jal;
    logic           id_jalr;
    logic           id_beq;
    logic           id_bne;
    logic           id_blt;
    logic           id_bge;
    logic           id_bltu;
    logic           id_bgeu;

    always_ff @(posedge clk) begin
        if ( reset ) begin
        end
        else if ( cke ) begin
            id_lui   <= (if_opcode == 7'b0110111);
            id_auipc <= (if_opcode == 7'b0010111);
            id_jal   <= (if_opcode == 7'b1101111);
            id_jalr  <= (if_opcode == 7'b1100111 && if_funct3 == 3'b000);
            id_beq   <= (if_opcode == 7'b1100011 && if_funct3 == 3'b000);
            id_bne   <= (if_opcode == 7'b1100011 && if_funct3 == 3'b001);
            id_blt   <= (if_opcode == 7'b1100011 && if_funct3 == 3'b100);
            id_bge   <= (if_opcode == 7'b1100011 && if_funct3 == 3'b101);
            id_bltu  <= (if_opcode == 7'b1100011 && if_funct3 == 3'b110);
            id_bgeu  <= (if_opcode == 7'b1100011 && if_funct3 == 3'b111);

        end
    end


    // -----------------------------------------
    //  Execution
    // -----------------------------------------

    assign dbus_addr  = id_rs1 + id_mem_offset;
    assign dbus_rd    = id_mem_rd;
    assign dbus_rd    = id_mem_we;
    assign dbus_wdata = id_rs2;

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
