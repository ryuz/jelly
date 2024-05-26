// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_execution
        #(
            parameter   int                     XLEN        = 32,
            parameter   int                     THREADS     = 4                                 ,
            parameter   int                     ID_BITS     = THREADS > 1 ? $clog2(THREADS) : 1 ,
            parameter   type                    id_t        = logic         [ID_BITS-1:0]       ,
            parameter   int                     PC_BITS     = 32                                ,
            parameter   type                    pc_t        = logic         [PC_BITS-1:0]       ,
            parameter   int                     INSTR_BITS  = 32                                ,
            parameter   type                    instr_t     = logic         [INSTR_BITS-1:0]    ,
            parameter   type                    ridx_t      = logic         [4:0]               ,
            parameter   type                    rval_t      = logic signed  [XLEN-1:0]          ,
            parameter   int                     SHAMT_BITS  = $clog2(XLEN)                      ,
            parameter   type                    shamt_t     = logic         [$clog2(XLEN)-1:0]  ,
            parameter   int                     EXES        = 4                                 ,
            parameter   bit                     RAW_HAZARD  = 1'b1                              ,
            parameter   bit                     WAW_HAZARD  = 1'b1                              ,
            parameter                           DEVICE      = "RTL"                             ,
            parameter                           SIMULATION  = "false"                           ,
            parameter                           DEBUG       = "false"               
        )
        (
            input   var logic               reset       ,
            input   var logic               clk         ,
            input   var logic               cke         ,

            // executions
            output  var id_t    [EXES-1:0]  exe_id      ,
            output  var logic   [EXES-1:0]  exe_rd_en   ,
            output  var ridx_t  [EXES-1:0]  exe_rd_idx  ,

            // output
            input   var id_t                s_id                ,
            input   var logic               s_phase             ,
            input   var pc_t                s_pc                ,
            input   var instr_t             s_instr             ,
            input   var logic               s_rd_en             ,
            input   var ridx_t              s_rd_idx            ,
            input   var logic               s_rs1_en            ,
            input   var rval_t              s_rs1_val           ,
            input   var logic               s_rs2_en            ,
            input   var rval_t              s_rs2_val           ,
            input   var logic               s_adder_sub         ,
            input   var logic               s_adder_imm_en      ,
            input   var rval_t              s_adder_imm_val     ,
            input   var logic   [1:0]       s_logical_op        ,
            input   var logic               s_logical_imm_en    ,
            input   var rval_t              s_logical_imm_val   ,
            input   var logic               s_shifter_arithmetic,
            input   var logic               s_shifter_left      ,
            input   var logic               s_shifter_imm_en    ,
            input   var shamt_t             s_shifter_imm_val   ,
            input   var logic               s_valid             ,
            output  var logic               s_wait
        );

    // -----------------------------------------
    //  stage 0
    // -----------------------------------------

    id_t                st0_id          ;
    logic               st0_phase       ;
    pc_t                st0_pc          ;
    instr_t             st0_instr       ;
    logic               st0_rd_en       ;
    ridx_t              st0_rd_idx      ;
    logic               st0_rs1_en      ;
    rval_t              st0_rs1_val     ;
    logic               st0_rs2_en      ;
    rval_t              st0_rs2_val     ;


    // adder
    logic       st0_adder_msb_c         ;
    logic       st0_adder_carry         ;
    rval_t      st0_adder_rd_val        ;
    jelly3_jfive_adder
            #(
                .XLEN           (XLEN               ),
                .rval_t         (rval_t             ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_jfive_adder
            (
                .reset          ,
                .clk            ,
                .cke            ,

                .s_sub          (s_adder_sub        ),
                .s_imm_en       (s_adder_imm_en     ),
                .s_imm_val      (s_adder_imm_val    ),
                .s_rs1_val      (s_rs1_val          ),
                .s_rs2_val      (s_rs2_val          ),

                .m_msb_c        (st0_adder_msb_c    ),
                .m_carry        (st0_adder_carry    ),
                .m_rd_val       (st0_adder_rd_val   )
            );

    // match
    logic       st0_match_eq    ;     
    jelly3_jfive_match
            #(
                .XLEN           (XLEN               ),
                .rval_t         (rval_t             ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_jfive_match
        (
                .reset          ,
                .clk            ,
                .cke            ,

                .s_rs1_val      (s_rs1_val          ),
                .s_rs2_val      (s_rs2_val          ),
                
                .m_eq           (st0_match_eq       )
        );


    // logical
    rval_t      st0_logical_rd_val  ;
    jelly3_jfive_logical
            #(
                .XLEN           (XLEN               ),
                .rval_t         (rval_t             ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )                
            )
        u_jfive_logical
        (
                .reset          ,
                .clk            ,
                .cke            ,
                
                .s_op           (s_logical_op       ),
                .s_imm_en       (s_logical_imm_en   ),
                .s_imm_val      (s_logical_imm_val  ),
                .s_rs1_val      (s_rs1_val          ),
                .s_rs2_val      (s_rs2_val          ),

                .m_rd_val       (st0_logical_rd_val )
        );


    // shifter
    rval_t      st1_shifter_rd_val;
    jelly3_jfive_shifter
            #(
                .XLEN           (XLEN                   ),
                .SHAMT_BITS     (SHAMT_BITS             ),
                .shamt_t        (shamt_t                ),
                .rval_t         (rval_t                 ),
                .ridx_t         (ridx_t                 ),
                .DEVICE         (DEVICE                 ),
                .SIMULATION     (SIMULATION             ),
                .DEBUG          (DEBUG                  )
            )
        u_jfive_shifter
            (
                .reset          ,
                .clk            ,
                .cke            ,

                .s_arithmetic   (s_shifter_arithmetic   ),
                .s_left         (s_shifter_left         ),
                .s_imm_en       (s_shifter_imm_en       ),
                .s_rs1_val      (s_rs1_val              ),
                .s_rs2_val      (s_rs2_val              ),
                .s_shamt        (s_shifter_imm_val      ),

                .m_rd_val       (st1_shifter_rd_val     )
            );


endmodule


`default_nettype wire


// End of file
