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
            parameter   int                     XLEN        = 32                                ,
            parameter   int                     ID_BITS     = 4                                 ,
            parameter   type                    id_t        = logic         [ID_BITS-1:0]       ,
            parameter   int                     PC_BITS     = 32                                ,
            parameter   type                    pc_t        = logic         [PC_BITS-1:0]       ,
            parameter   type                    rval_t      = logic [XLEN-1:0]  ,
            parameter                           DEVICE      = "RTL"             ,
            parameter                           SIMULATION  = "false"           ,
            parameter                           DEBUG       = "false"                           
        )
        (
            input   var logic               reset           ,
            input   var logic               clk             ,
            input   var logic               cke             ,

            // input
            input   var id_t                s_id            ,
            input   var logic   [2:0]       s_op            ,
            input   var logic               s_msb_c         ,
            input   var logic               s_carry         ,
            input   var logic               s_sign          ,
            input   var logic               s_eq            ,
            input   var pc_t                s_jalr_pc       ,
            input   var pc_t                s_imm_pc        ,
            input   var logic               s_valid         ,

            // output
            output  var id_t                m_branch_id     ,
            output  var pc_t                m_branch_pc     ,
            output  var logic               m_branch_valid  
        );


    id_t    st0_branch_id       ;
    pc_t    st0_branch_pc       ;
    logic   st0_branch_valid    ;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_branch_id     <= 'x;
            st0_branch_pc     <= 'x;
            st0_branch_valid  <= 1'b0;
        end
        else if ( cke ) begin
            st0_branch_id     <= s_id;

            if ( s_op == 3'b101 ) begin
                st0_branch_pc <= s_jalr_pc;
            end
            else begin
                st0_branch_pc <= s_imm_pc;
            end

            case ( s_op )
            3'b000:  st0_branch_valid <= s_valid &&  s_eq;                          // BEQ
            3'b001:  st0_branch_valid <= s_valid && ~s_eq;                          // BNE
            3'b100:  st0_branch_valid <= s_valid &&  (s_carry ^ s_msb_c ^ s_sign);  // BLT
            3'b101:  st0_branch_valid <= s_valid && ~(s_carry ^ s_msb_c ^ s_sign);  // BGE
            3'b110:  st0_branch_valid <= s_valid &&  s_carry;                       // BLTU
            3'b111:  st0_branch_valid <= s_valid && ~s_carry;                       // BGEU
            default: st0_branch_valid <= s_valid;       // JAL or JALR
            endcase
        end
    end

    assign m_branch_id     = st0_branch_id    ;
    assign m_branch_pc     = st0_branch_pc    ;
    assign m_branch_valid  = st0_branch_valid ;

endmodule


`default_nettype wire


// End of file
