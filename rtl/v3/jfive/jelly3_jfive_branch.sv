// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_branch
        #(
            parameter   int     THREADS     = 4                                 ,
            parameter   int     ID_BITS     = THREADS > 1 ? $clog2(THREADS) : 1 ,
            parameter   type    id_t        = logic         [ID_BITS-1:0]       ,
            parameter   int     PHASE_BITS  = 1                                 ,
            parameter   type    phase_t     = logic         [PHASE_BITS-1:0]    ,
            parameter   int     PC_BITS     = 32                                ,
            parameter   type    pc_t        = logic         [PC_BITS-1:0]       ,
            parameter   int     INSTR_BITS  = 32                                ,
            parameter   type    instr_t     = logic         [INSTR_BITS-1:0]    ,
            parameter           DEVICE      = "RTL"                             ,
            parameter           SIMULATION  = "false"                           ,
            parameter           DEBUG       = "false"                           
        )
        (
            input   var logic               reset           ,
            input   var logic               clk             ,
            input   var logic               cke             ,

            // phase
            output  phase_t [THREADS-1:0]   phase_table     ,

            // branch
            output  var id_t                branch_id       ,
            output  var pc_t                branch_pc       ,
            output  var pc_t                branch_old_pc   ,
            output  var instr_t             branch_instr    ,
            output  var logic               branch_valid    ,

            // input
            input   var id_t                s_id            ,
            input   var pc_t                s_pc            ,
            input   var instr_t             s_instr         ,
            input   var phase_t             s_phase         ,
            input   var logic   [2:0]       s_mode          ,
            input   var logic               s_msb_c         ,
            input   var logic               s_carry         ,
            input   var logic               s_sign          ,
            input   var logic               s_eq            ,
            input   var pc_t                s_jalr_pc       ,
            input   var pc_t                s_imm_pc        ,
            input   var logic               s_valid         
        );


    // ------------------------------------
    //  Inputs
    // ------------------------------------

    logic s_branch_en;
    always_comb begin
        s_branch_en = 1'b0;
        if ( s_valid && s_phase == phase_table[s_id] ) begin
            case ( s_mode )
            3'b000: s_branch_en =  s_eq;                          // BEQ
            3'b001: s_branch_en = ~s_eq;                          // BNE
            3'b100: s_branch_en =  (s_carry ^ s_msb_c ^ s_sign);  // BLT
            3'b101: s_branch_en = ~(s_carry ^ s_msb_c ^ s_sign);  // BGE
            3'b110: s_branch_en = ~s_carry;                       // BLTU
            3'b111: s_branch_en =  s_carry;                       // BGEU
            3'b010: s_branch_en = 1'b1;                           // JAL
            3'b011: s_branch_en = 1'b1;                           // JALR
            endcase
        end
    end


    // ------------------------------------
    //  stage 0
    // ------------------------------------

    id_t                    st0_id              ;
    pc_t                    st0_pc              ;
    instr_t                 st0_instr           ;
    pc_t                    st0_branch_pc       ;
    logic                   st0_branch_valid    ;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            phase_table       <= '0;
            st0_id            <= 'x;
            st0_pc            <= 'x;
            st0_instr         <= 'x;
            st0_branch_pc     <= 'x;
            st0_branch_valid  <= 1'b0;
        end
        else if ( cke ) begin
            if ( s_branch_en ) begin
                phase_table[s_id] <= phase_table[s_id] + phase_t'(1);
            end

            st0_id        <= s_id;
            st0_pc        <= s_pc;
            st0_instr     <= s_instr;
            st0_branch_pc <= s_imm_pc;
            if ( s_mode == 3'b011 ) begin
                st0_branch_pc <= s_jalr_pc;
            end
            st0_branch_valid <= s_branch_en;
        end
    end

    assign branch_id     = st0_id           ;
    assign branch_pc     = st0_branch_pc    ;
    assign branch_old_pc = st0_pc           ;
    assign branch_instr  = st0_instr        ;
    assign branch_valid  = st0_branch_valid ;

endmodule


`default_nettype wire


// End of file
