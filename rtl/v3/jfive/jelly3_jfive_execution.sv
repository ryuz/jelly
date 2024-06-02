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
            parameter   int                     PHASE_BITS  = 1                                 ,
            parameter   type                    phase_t     = logic         [PHASE_BITS-1:0]    ,
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
            input   var logic               reset               ,
            input   var logic               clk                 ,
            input   var logic               cke                 ,

            // executions
            output  var id_t    [EXES-1:0]  exe_id              ,
            output  var logic   [EXES-1:0]  exe_rd_en           ,
            output  var ridx_t  [EXES-1:0]  exe_rd_idx          ,

            // branch
            output  var id_t                branch_id           ,
            output  var pc_t                branch_pc           ,
            output  var logic               branch_valid        ,

            // output
            input   var id_t                s_id                ,
            input   var phase_t             s_phase             ,
            input   var pc_t                s_pc                ,
            input   var instr_t             s_instr             ,
            input   var logic               s_rd_en             ,
            input   var ridx_t              s_rd_idx            ,
            input   var logic               s_rs1_en            ,
            input   var rval_t              s_rs1_val           ,
            input   var logic               s_rs2_en            ,
            input   var rval_t              s_rs2_val           ,
            input   var logic               s_offset            ,
            input   var logic               s_adder             ,
            input   var logic               s_logical           ,
            input   var logic               s_shifter           ,
            input   var logic               s_load              ,
            input   var logic               s_store             ,
            input   var logic               s_branch            ,
            input   var logic               s_adder_sub         ,
            input   var logic               s_adder_imm_en      ,
            input   var rval_t              s_adder_imm_val     ,
            input   var logic   [1:0]       s_logical_mode      ,
            input   var logic               s_logical_imm_en    ,
            input   var rval_t              s_logical_imm_val   ,
            input   var logic               s_shifter_arithmetic,
            input   var logic               s_shifter_left      ,
            input   var logic               s_shifter_imm_en    ,
            input   var shamt_t             s_shifter_imm_val   ,
            input   var logic   [2:0]       s_branch_mode       ,
            input   var pc_t                s_branch_pc         ,
            input   var logic               s_valid             ,
            output  var logic               s_wait
        );

    // -----------------------------------------
    //  stage 0
    // -----------------------------------------

    // adder
    logic       st0_adder_msb_c         ;
    logic       st0_adder_carry         ;
    logic       st0_adder_sign          ;
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
                .m_sign         (st0_adder_sign     ),
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
                
                .s_mode         (s_logical_mode     ),
                .s_imm_en       (s_logical_imm_en   ),
                .s_imm_val      (s_logical_imm_val  ),
                .s_rs1_val      (s_rs1_val          ),
                .s_rs2_val      (s_rs2_val          ),

                .m_rd_val       (st0_logical_rd_val )
        );

    // control
    id_t                st0_id                  ;
    phase_t             st0_phase               ;
    pc_t                st0_pc                  ;
    instr_t             st0_instr               ;
    logic               st0_rd_en               ;
    ridx_t              st0_rd_idx              ;
    logic               st0_rs1_en              ;
    rval_t              st0_rs1_val             ;
    logic               st0_rs2_en              ;
    rval_t              st0_rs2_val             ;

    logic               st0_offset              ;
    logic               st0_adder               ;
    logic               st0_logical             ;
    logic               st0_shifter             ;
    logic               st0_load                ;
    logic               st0_store               ;
    logic               st0_branch              ;
    logic               st0_adder_sub           ;
    logic               st0_adder_imm_en        ;
    rval_t              st0_adder_imm_val       ;
    logic   [1:0]       st0_logical_mode        ;
    logic               st0_logical_imm_en      ;
    rval_t              st0_logical_imm_val     ;
    logic               st0_shifter_arithmetic  ;
    logic               st0_shifter_left        ;
    logic               st0_shifter_imm_en      ;
    shamt_t             st0_shifter_imm_val     ;
    logic   [2:0]       st0_branch_mode         ;
    pc_t                st0_branch_pc           ;


    logic               st0_valid               ;



    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_id                  <= 'x;
            st0_phase               <= 'x;
            st0_pc                  <= 'x;
            st0_instr               <= 'x;
            st0_rd_en               <= 'x;
            st0_rd_idx              <= 'x;
            st0_rs1_en              <= 'x;
            st0_rs1_val             <= 'x;
            st0_rs2_en              <= 'x;
            st0_rs2_val             <= 'x;
            st0_offset              <= 'x;
            st0_adder               <= 'x;
            st0_logical             <= 'x;
            st0_shifter             <= 'x;
            st0_load                <= 'x;
            st0_store               <= 'x;
            st0_branch              <= 'x;
            st0_adder_sub           <= 'x;
            st0_adder_imm_en        <= 'x;
            st0_adder_imm_val       <= 'x;
            st0_logical_mode        <= 'x;
            st0_logical_imm_en      <= 'x;
            st0_logical_imm_val     <= 'x;
            st0_shifter_arithmetic  <= 'x;
            st0_shifter_left        <= 'x;
            st0_shifter_imm_en      <= 'x;
            st0_shifter_imm_val     <= 'x;
            st0_branch_mode         <= 'x;
            st0_branch_pc           <= 'x;
            st0_valid               <= 1'b0;
        end
        else if ( cke && !s_wait ) begin
            st0_id                  <= s_id                 ;
            st0_phase               <= s_phase              ;
            st0_pc                  <= s_pc                 ;
            st0_instr               <= s_instr              ;
            st0_rd_en               <= s_rd_en              ;
            st0_rd_idx              <= s_rd_idx             ;
            st0_rs1_en              <= s_rs1_en             ;
            st0_rs1_val             <= s_rs1_val            ;
            st0_rs2_en              <= s_rs2_en             ;
            st0_rs2_val             <= s_rs2_val            ;
            st0_offset              <= s_offset             ;
            st0_adder               <= s_adder              ;
            st0_logical             <= s_logical            ;
            st0_shifter             <= s_shifter            ;
            st0_load                <= s_load               ;
            st0_store               <= s_store              ;
            st0_branch              <= s_branch             ;
            st0_adder_sub           <= s_adder_sub          ;
            st0_adder_imm_en        <= s_adder_imm_en       ;
            st0_adder_imm_val       <= s_adder_imm_val      ;
            st0_logical_mode        <= s_logical_mode       ;
            st0_logical_imm_en      <= s_logical_imm_en     ;
            st0_logical_imm_val     <= s_logical_imm_val    ;
            st0_shifter_arithmetic  <= s_shifter_arithmetic ;
            st0_shifter_left        <= s_shifter_left       ;
            st0_shifter_imm_en      <= s_shifter_imm_en     ;
            st0_shifter_imm_val     <= s_shifter_imm_val    ;
            st0_branch_mode         <= s_branch_mode        ;
            st0_branch_pc           <= s_branch_pc          ;
            st0_valid               <= s_valid              ;
        end
    end


    // -----------------------------------------
    //  stage 1
    // -----------------------------------------

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

    // branch
    phase_t [THREADS-1:0]   st1_phase_table;
    jelly3_jfive_branch
            #(
                .THREADS        (THREADS                ),
                .ID_BITS        (ID_BITS                ),
                .id_t           (id_t                   ),
                .PHASE_BITS     (PHASE_BITS             ),
                .phase_t        (phase_t                ),
                .PC_BITS        (PC_BITS                ),
                .pc_t           (pc_t                   ),
                .DEVICE         (DEVICE                 ),
                .SIMULATION     (SIMULATION             ),
                .DEBUG          (DEBUG                  )
            )
        u_jfive_branch
            (
                .reset           ,
                .clk             ,
                .cke             ,

                .phase_table     (st1_phase_table       ),

                .branch_id       ,
                .branch_pc       ,
                .branch_valid    ,

                .s_id            (st0_id                ),
                .s_phase         (st0_phase             ),
                .s_mode          (st0_branch_mode       ),
                .s_msb_c         (st0_adder_msb_c       ),
                .s_carry         (st0_adder_carry       ),
                .s_sign          (st0_adder_sign        ),
                .s_eq            (st0_match_eq          ),
                .s_jalr_pc       (st0_adder_rd_val      ),
                .s_imm_pc        (st0_branch_pc         ),
                .s_valid         (st0_valid             )
            );


    // control
    id_t                st1_id          ;
    phase_t             st1_phase       ;
    pc_t                st1_pc          ;
    instr_t             st1_instr       ;
    logic               st1_rd_en       ;
    ridx_t              st1_rd_idx      ;
    logic               st1_rs1_en      ;
    rval_t              st1_rs1_val     ;
    logic               st1_rs2_en      ;
    rval_t              st1_rs2_val     ;
    logic               st1_valid       ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st1_id      <= 'x;
            st1_phase   <= 'x;
            st1_pc      <= 'x;
            st1_instr   <= 'x;
            st1_rd_en   <= 'x;
            st1_rd_idx  <= 'x;
            st1_rs1_en  <= 'x;
            st1_rs1_val <= 'x;
            st1_rs2_en  <= 'x;
            st1_rs2_val <= 'x;
            st1_valid   <= 1'b0;
        end
        else if ( cke && !s_wait ) begin
            st1_id      <= st0_id     ;
            st1_phase   <= st0_phase  ;
            st1_pc      <= st0_pc     ;
            st1_instr   <= st0_instr  ;
            st1_rd_en   <= st0_rd_en  ;
            st1_rd_idx  <= st0_rd_idx ;
            st1_rs1_en  <= st0_rs1_en ;
            st1_rs1_val <= st0_rs1_val;
            st1_rs2_en  <= st0_rs2_en ;
            st1_rs2_val <= st0_rs2_val;
            st1_valid   <= st0_valid && (st1_phase_table[st0_id] == st0_phase);
        end
    end


    assign s_wait = 1'b0;

endmodule


`default_nettype wire


// End of file
