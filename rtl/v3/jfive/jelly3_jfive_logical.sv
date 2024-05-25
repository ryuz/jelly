// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_logical
        #(
            localparam  int                     XLEN        = 32                ,
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
            input   var logic   [1:0]       s_op            ,
            input   var logic               s_imm_en        ,
            input   var rval_t              s_imm_val       ,
            input   var rval_t              s_rs1_val       ,
            input   var rval_t              s_rs2_val       ,

            // output
            output  var rval_t              m_rd_val        
        );


    // ------------------------------------
    //  Stage 0
    // ------------------------------------

    rval_t              st0_rd_val  ;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            case ( s_op )
            2'b00:      st0_rd_val <= s_rs1_val ^ s_rs2_val;
            2'b10:      st0_rd_val <= s_rs1_val | s_rs2_val;
            2'b11:      st0_rd_val <= s_rs1_val & s_rs2_val;
            default:    st0_rd_val <= 'x;
            endcase
        end
    end


    // ------------------------------------
    //  Output
    // ------------------------------------

    assign m_rd_val = st0_rd_val;

endmodule


`default_nettype wire


// End of file
