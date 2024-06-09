// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_match
        #(
            parameter   int                     XLEN        = 32                                ,
            parameter   type                    rval_t      = logic [XLEN-1:0]                  ,
            parameter                           DEVICE      = "RTL"                             ,
            parameter                           SIMULATION  = "false"                           ,
            parameter                           DEBUG       = "false"                           
        )
        (
            input   var logic               reset           ,
            input   var logic               clk             ,
            input   var logic               cke             ,

            // input
            input   var rval_t              s_rs1_val       ,
            input   var rval_t              s_rs2_val       ,

            // output
            output  var logic               m_eq            ,
            input   var logic               m_acceptable    
        );


    // ------------------------------------
    //  Stage 0
    // ------------------------------------

    logic   st0_eq        ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_eq <= 'x;
        end
        else if ( cke && m_acceptable ) begin
            st0_eq <= (s_rs1_val == s_rs2_val);
        end
    end


    // ------------------------------------
    //  Output
    // ------------------------------------
    assign m_eq = st0_eq;

endmodule


`default_nettype wire


// End of file
