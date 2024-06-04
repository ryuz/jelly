

package jelly3_jfive32_pkg;

    // types

    localparam  int     XLEN        = 32                                ;
    localparam  int     PC_BITS     = 32                                ;
    localparam  type    pc_t        = logic         [PC_BITS-1:0]       ;
    localparam  int     INSTR_BITS  = 32                                ;
    localparam  type    instr_t     = logic         [INSTR_BITS-1:0]    ;
    localparam  type    ridx_t      = logic         [4:0]               ;
    localparam  type    rval_t      = logic signed  [XLEN-1:0]          ;
    localparam  type    shamt_t     = logic         [$clog2(XLEN)-1:0]  ;
    localparam  type    opcode_t    = logic         [6:0];
    localparam  type    funct3_t    = logic         [2:0];
    localparam  type    funct7_t    = logic         [6:0];

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
    localparam  funct3_t    FUNCT3_ADDI     = 3'b000;
    localparam  funct3_t    FUNCT3_SLTI     = 3'b010;
    localparam  funct3_t    FUNCT3_SLTIU    = 3'b011;
    localparam  funct3_t    FUNCT3_XORI     = 3'b100;
    localparam  funct3_t    FUNCT3_ORI      = 3'b110;
    localparam  funct3_t    FUNCT3_ANDI     = 3'b111;
    localparam  funct3_t    FUNCT3_SLLI     = 3'b001;
    localparam  funct3_t    FUNCT3_SRLI     = 3'b101;
    localparam  funct3_t    FUNCT3_SRAI     = 3'b101;
    localparam  funct3_t    FUNCT3_ADD      = 3'b000;
    localparam  funct3_t    FUNCT3_SUB      = 3'b000;
    localparam  funct3_t    FUNCT3_SLL      = 3'b001;
    localparam  funct3_t    FUNCT3_SL       = 3'b001;
    localparam  funct3_t    FUNCT3_SLT      = 3'b010;
    localparam  funct3_t    FUNCT3_SLTU     = 3'b011;
    localparam  funct3_t    FUNCT3_XOR      = 3'b100;
    localparam  funct3_t    FUNCT3_SR       = 3'b101;
    localparam  funct3_t    FUNCT3_SRL      = 3'b101;
    localparam  funct3_t    FUNCT3_SRA      = 3'b101;
    localparam  funct3_t    FUNCT3_OR       = 3'b110;
    localparam  funct3_t    FUNCT3_AND      = 3'b111;
    localparam  funct3_t    FUNCT3_FENCE    = 3'b000;
    localparam  funct3_t    FUNCT3_ECALL    = 3'b000;
    localparam  funct3_t    FUNCT3_EBREAK   = 3'b000;

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


function automatic string ridx2name (input ridx_t ridx);
    if      ( ridx == 0  ) return "zero";
    else if ( ridx == 1  ) return "ra";
    else if ( ridx == 2  ) return "sp";
    else if ( ridx == 3  ) return "gp";
    else if ( ridx == 4  ) return "tp";
    else if ( ridx <= 7  ) return $sformatf("t%0d",ridx - 5);
    else if ( ridx <= 9  ) return $sformatf("s%0d",ridx - 8);
    else if ( ridx <= 17 ) return $sformatf("a%0d",ridx - 10);
    else if ( ridx <= 27 ) return $sformatf("s%0d",ridx - 18);
    else                   return $sformatf("t%0d",ridx - 28);
endfunction



function automatic string instr2mnemonic (input instr_t instr);
    opcode_t                opcode  = instr[6:0]                                                ;
    ridx_t                  rd_idx  = instr[11:7]                                               ;
    ridx_t                  rs1_idx = instr[19:15]                                              ;
    ridx_t                  rs2_idx = instr[24:20]                                              ;
    funct3_t                funct3  = instr[14:12]                                              ;
    funct7_t                funct7  = instr[31:25]                                              ;
    logic   signed  [11:0]  imm_i   = instr[31:20]                                              ;
    logic   signed  [11:0]  imm_s   = {instr[31:25], instr[11:7]}                               ;
    logic   signed  [12:0]  imm_b   = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}    ;
    logic   signed  [31:0]  imm_u   = {instr[31:12], 12'd0}                                     ;
    logic   signed  [20:0]  imm_j   = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}  ;
    shamt_t                 shamt   = instr[20 +: $bits(shamt_t)]                               ;

    if      ( opcode == OPCODE_LUI                                                     ) return {"lui   ", $sformatf("%s,0x%h",    ridx2name(rd_idx),  imm_u)};
    else if ( opcode == OPCODE_AUIPC                                                   ) return {"auipc ", $sformatf("%s,0x%h",    ridx2name(rd_idx),  imm_u)};
    else if ( opcode == OPCODE_JAL                                                     ) return {"jal   ", $sformatf("%s,0x%h",    ridx2name(rd_idx),  imm_j)};
    else if ( opcode == OPCODE_JALR  && funct3 == FUNCT3_JALR                          ) return {"jalr  ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_BEQ   && funct3 == FUNCT3_BEQ                           ) return {"beq   ", $sformatf("%s,%s,0x%h", ridx2name(rs1_idx), ridx2name(rs2_idx), imm_b)};
    else if ( opcode == OPCODE_BNE   && funct3 == FUNCT3_BNE                           ) return {"bne   ", $sformatf("%s,%s,0x%h", ridx2name(rs1_idx), ridx2name(rs2_idx), imm_b)};
    else if ( opcode == OPCODE_BLT   && funct3 == FUNCT3_BLT                           ) return {"blt   ", $sformatf("%s,%s,0x%h", ridx2name(rs1_idx), ridx2name(rs2_idx), imm_b)};
    else if ( opcode == OPCODE_BGE   && funct3 == FUNCT3_BGE                           ) return {"bge   ", $sformatf("%s,%s,0x%h", ridx2name(rs1_idx), ridx2name(rs2_idx), imm_b)};
    else if ( opcode == OPCODE_BLTU  && funct3 == FUNCT3_BLTU                          ) return {"bltu  ", $sformatf("%s,%s,0x%h", ridx2name(rs1_idx), ridx2name(rs2_idx), imm_b)};
    else if ( opcode == OPCODE_BGEU  && funct3 == FUNCT3_BGEU                          ) return {"bgeu  ", $sformatf("%s,%s,0x%h", ridx2name(rs1_idx), ridx2name(rs2_idx), imm_b)};
    else if ( opcode == OPCODE_LB    && funct3 == FUNCT3_LB                            ) return {"lb    ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_LH    && funct3 == FUNCT3_LH                            ) return {"lh    ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_LW    && funct3 == FUNCT3_LW                            ) return {"lw    ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_LBU   && funct3 == FUNCT3_LBU                           ) return {"lbu   ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_LHU   && funct3 == FUNCT3_LHU                           ) return {"lhu   ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_SB    && funct3 == FUNCT3_SB                            ) return {"sb    ", $sformatf("%s,%s,0x%h", ridx2name(rs1_idx), ridx2name(rs2_idx), imm_s)};
    else if ( opcode == OPCODE_SH    && funct3 == FUNCT3_SH                            ) return {"sh    ", $sformatf("%s,%s,0x%h", ridx2name(rs1_idx), ridx2name(rs2_idx), imm_s)};
    else if ( opcode == OPCODE_SW    && funct3 == FUNCT3_SW                            ) return {"sw    ", $sformatf("%s,%s,0x%h", ridx2name(rs1_idx), ridx2name(rs2_idx), imm_s)};
    else if ( opcode == OPCODE_ADDI  && funct3 == FUNCT3_ADDI                          ) return {"addi  ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_SLTI  && funct3 == FUNCT3_SLTI                          ) return {"slti  ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_SLTIU && funct3 == FUNCT3_SLTIU                         ) return {"sltiu ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_XORI  && funct3 == FUNCT3_XORI                          ) return {"xori  ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_ORI   && funct3 == FUNCT3_ORI                           ) return {"ori   ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_ANDI  && funct3 == FUNCT3_ANDI                          ) return {"andi  ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), imm_i)};
    else if ( opcode == OPCODE_SLLI  && funct3 == FUNCT3_SLLI                          ) return {"slli  ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), shamt)};
    else if ( opcode == OPCODE_SRLI  && funct3 == FUNCT3_SRLI                          ) return {"srli  ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), shamt)};
    else if ( opcode == OPCODE_SRAI  && funct3 == FUNCT3_SRAI                          ) return {"srai  ", $sformatf("%s,%s,0x%h", ridx2name(rd_idx),  ridx2name(rs1_idx), shamt)};
    else if ( opcode == OPCODE_ADD   && funct3 == FUNCT3_ADD   && funct7 == FUNCT7_ADD ) return {"add   ", $sformatf("%s,%s,%s",   ridx2name(rd_idx),  ridx2name(rs1_idx), ridx2name(rs2_idx))};
    else if ( opcode == OPCODE_SUB   && funct3 == FUNCT3_SUB   && funct7 == FUNCT7_SUB ) return {"sub   ", $sformatf("%s,%s,%s",   ridx2name(rd_idx),  ridx2name(rs1_idx), ridx2name(rs2_idx))};
    else if ( opcode == OPCODE_SLL   && funct3 == FUNCT3_SLL   && funct7 == FUNCT7_SLL ) return {"sll   ", $sformatf("%s,%s,%s",   ridx2name(rd_idx),  ridx2name(rs1_idx), ridx2name(rs2_idx))};
    else if ( opcode == OPCODE_SLT   && funct3 == FUNCT3_SLT                           ) return {"slt   ", $sformatf("%s,%s,%s",   ridx2name(rd_idx),  ridx2name(rs1_idx), ridx2name(rs2_idx))};
    else if ( opcode == OPCODE_SLTU  && funct3 == FUNCT3_SLTU                          ) return {"sltu  ", $sformatf("%s,%s,%s",   ridx2name(rd_idx),  ridx2name(rs1_idx), ridx2name(rs2_idx))};
    else if ( opcode == OPCODE_XOR   && funct3 == FUNCT3_XOR                           ) return {"xor   ", $sformatf("%s,%s,%s",   ridx2name(rd_idx),  ridx2name(rs1_idx), ridx2name(rs2_idx))};
    else if ( opcode == OPCODE_SRL   && funct3 == FUNCT3_SRL   && funct7 == FUNCT7_SRL ) return {"srl   ", $sformatf("%s,%s,%s",   ridx2name(rd_idx),  ridx2name(rs1_idx), ridx2name(rs2_idx))};
    else if ( opcode == OPCODE_SRA   && funct3 == FUNCT3_SRA   && funct7 == FUNCT7_SRA ) return {"sra   ", $sformatf("%s,%s,%s",   ridx2name(rd_idx),  ridx2name(rs1_idx), ridx2name(rs2_idx))};
    else if ( opcode == OPCODE_OR    && funct3 == FUNCT3_OR                            ) return {"or    ", $sformatf("%s,%s,%s",   ridx2name(rd_idx),  ridx2name(rs1_idx), ridx2name(rs2_idx))};
    else if ( opcode == OPCODE_AND   && funct3 == FUNCT3_AND                           ) return {"and   ", $sformatf("%s,%s,%s",   ridx2name(rd_idx),  ridx2name(rs1_idx), ridx2name(rs2_idx))};
    else if ( opcode == OPCODE_FENCE && funct3 == FUNCT3_FENCE                         ) return  "fence ";
    else if ( opcode == OPCODE_ECALL && funct3 == FUNCT3_ECALL                         ) return  "ecall ";
    else if ( opcode == OPCODE_EBREAK && funct3 == FUNCT3_EBREAK                       ) return  "ebreak";
    return "Unkwown";
endfunction

    
endpackage
