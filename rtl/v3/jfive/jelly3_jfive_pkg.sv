

package  jelly3_jfive32_pkg;

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


function automatic string instr2mnemonic (input logic [31:0] instr);
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

    string opecode = "Unknown";
    


    case ( opcode )
    OPCODE_LUI    : begin opecode = "LUI   "; end
    OPCODE_AUIPC  : begin opecode = "AUIPC "; end
    OPCODE_JAL    : begin opecode = "JAL   "; end
    OPCODE_JALR   : begin opecode = "JALR  "; end
    OPCODE_BRANCH :
        begin
            case ( funct3 )
            FUNCT3_BEQ  : begin opecode = "BEQ   "; end
            FUNCT3_BNE  : begin opecode = "BNE   "; end
            FUNCT3_BLT  : begin opecode = "BLT   "; end
            FUNCT3_BGE  : begin opecode = "BGE   "; end
            FUNCT3_BLTU : begin opecode = "BLTU  "; end
            FUNCT3_BGEU : begin opecode = "BGEU  "; end
            default     : ;
            endcase
        end
    OPCODE_LOAD :
        begin
            case ( funct3 )
            FUNCT3_LB   : begin opecode = "LB    "; end
            FUNCT3_LH   : begin opecode = "LH    "; end
            FUNCT3_LW   : begin opecode = "LW    "; end
            FUNCT3_LBU  : begin opecode = "LBU   "; end
            FUNCT3_LHU  : begin opecode = "LHU   "; end
            default     : ;
            endcase
        end
    OPCODE_STORE:
        begin
            case ( funct3 )
            FUNCT3_SB   : begin opecode = "SB    "; end
            FUNCT3_SH   : begin opecode = "SH    "; end
            FUNCT3_SW   : begin opecode = "SW    "; end
            default     : ;
            endcase
        end
    OPCODE_ALUI:
        begin
            case ( funct3 )
            FUNCT3_ADDI : begin opecode = "ADDI  "; end
            FUNCT3_SLTI : begin opecode = "SLTI  "; end
            FUNCT3_SLTIU: begin opecode = "SLTIU "; end
            FUNCT3_XORI : begin opecode = "XORI  "; end
            FUNCT3_ORI  : begin opecode = "ORI   "; end
            FUNCT3_ANDI : begin opecode = "ANDI  "; end
            FUNCT3_SLLI : begin opecode = "SLLI  "; end
            FUNCT3_SRLI : begin opecode = "SRLI  "; end
            FUNCT3_SRAI : begin opecode = "SRAI  "; end
            default     : ;
            endcase
        end
    OPCODE_ALU:
        begin
            case ( funct3 )
            FUNCT3_ADD  :
                begin
                    case ( funct7 )
                    FUNCT7_ADD  : begin opecode = "ADD   "; end
                    FUNCT7_SUB  : begin opecode = "SUB   "; end
                    default     : ;
                    endcase
                end
            FUNCT3_SLL  : begin opecode = "SLL   "; end
            FUNCT3_SLT  : begin opecode = "SLT   "; end
            FUNCT3_SLTU : begin opecode = "SLTU  "; end
            FUNCT3_XOR  : begin opecode = "XOR   "; end
            FUNCT3_SRL  :
                begin
                    case ( funct7 )
                    FUNCT7_SRL  : begin opecode = "SRL   "; end
                    FUNCT7_SRA  : begin opecode = "SRA   "; end
                    default     : ;
                    endcase
                end
            FUNCT3_OR   : begin opecode = "OR    "; end
            FUNCT3_AND  : begin opecode = "AND   "; end
            default     : ;
            endcase
        end
    OPCODE_FENCE: begin opecode = "FENCE "; end
    OPCODE_ECALL: begin opecode = "ECALL "; end
    OPCODE_EBREAK: begin opecode = "EBREAK"; end
    default: ;
    endcase

    return opecode;
endfunction

    
endpackage