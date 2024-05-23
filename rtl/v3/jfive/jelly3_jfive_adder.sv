// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_adder
        #(
            localparam  bit                     BYPASS_FF   = 1'b0                              ,
            localparam  int                     XLEN        = 32                                ,
            localparam  int                     SHAMT_BITS  = $clog2(XLEN)                      ,
            localparam  type                    shamt_t     = logic [SHAMT_BITS-1:0]            ,
            parameter   type                    rval_t      = logic [XLEN-1:0]                  ,
            parameter   int                     ID_BITS     = 4                                 ,
            parameter   type                    id_t        = logic [ID_BITS-1:0]               ,
            parameter   type                    ridx_t      = logic [5:0]                       ,
            parameter   type                    imm_i_t     = logic signed [11:0]               ,
            parameter                           DEVICE      = "RTL"                             ,
            parameter                           SIMULATION  = "false"                           ,
            parameter                           DEBUG       = "false"                           
        )
        (
            input   var logic               reset           ,
            input   var logic               clk             ,
            input   var logic               cke             ,

            // input
            input   var logic               s_sub_en        ,
            input   var logic               s_imm_en        ,
            input   var rval_t              s_rs1_val       ,
            input   var rval_t              s_rs2_val       ,
            input   var rval_t              s_imm_val       ,

            // output
            output  var rval_t              m_rd_val        ,
            output  var logic               m_carry         
        );


    // ------------------------------------
    //  Stage 0
    // ------------------------------------

    logic               st0_carry   ;
    rval_t              st0_rd_val  ;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            case ( {s_sub_en, s_imm_en})
            2'b00:      {st0_carry, st0_rd_val} <= s_rs1_val + s_rs2_val;
            2'b01:      {st0_carry, st0_rd_val} <= s_rs1_val + s_imm_val;
            2'b10:      {st0_carry, st0_rd_val} <= s_rs1_val - s_rs2_val;
            default:    {st0_carry, st0_rd_val} <= 'x;
            endcase
        end
    end


    // ------------------------------------
    //  Output
    // ------------------------------------

    assign m_rd_val = st0_rd_val;
    assign m_carry  = st0_carry;

endmodule


`default_nettype wire


// End of file
