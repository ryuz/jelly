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
            parameter   int                     XLEN           = 32                                 ,
            parameter   int                     THREADS        = 4                                  ,
            parameter   int                     ID_BITS        = THREADS > 1 ? $clog2(THREADS) : 1  ,
            parameter   type                    id_t           = logic         [ID_BITS-1:0]        ,
            parameter   int                     PHASE_BITS     = 1                                  ,
            parameter   type                    phase_t        = logic         [PHASE_BITS-1:0]     ,
            parameter   int                     PC_BITS        = 32                                 ,
            parameter   type                    pc_t           = logic         [PC_BITS-1:0]        ,
            parameter   int                     INSTR_BITS     = 32                                 ,
            parameter   type                    instr_t        = logic         [INSTR_BITS-1:0]     ,
            parameter   type                    ridx_t         = logic         [4:0]                ,
            parameter   type                    rval_t         = logic signed  [XLEN-1:0]           ,
            parameter   int                     SHAMT_BITS     = $clog2(XLEN)                       ,
            parameter   type                    shamt_t        = logic         [$clog2(XLEN)-1:0]   ,
            parameter   int                     ADDR_BITS      = $bits(rval_t)                      ,
            parameter   type                    addr_t         = logic         [ADDR_BITS-1:0]      ,
            parameter   int                     DATA_BITS      = $bits(rval_t)                      ,
            parameter   type                    data_t         = logic         [DATA_BITS-1:0]      ,
            parameter   int                     STRB_BITS      = $bits(data_t) / 8                  ,
            parameter   type                    strb_t         = logic         [STRB_BITS-1:0]      ,
            parameter   type                    size_t         = logic         [1:0]                ,
            parameter   int                     LS_UNITS       = 2                                  ,
            parameter   rval_t  [LS_UNITS-1:0]  LS_ADDRS_LO    = '{32'h8000_0000, 32'h0000_0000}    ,
            parameter   rval_t  [LS_UNITS-1:0]  LS_ADDRS_HI    = '{32'hffff_ffff, 32'h7fff_ffff}    ,
            parameter   int                     LOAD_QUES      = 2                                  ,
            parameter   int                     BUSY_RDS       = 3                                  ,
            parameter   bit                     RAW_HAZARD     = 1'b1                               ,
            parameter   bit                     WAW_HAZARD     = 1'b1                               ,
            parameter                           DEVICE         = "RTL"                              ,
            parameter                           SIMULATION     = "false"                            ,
            parameter                           DEBUG          = "false"                            
        )
        (
            input   var logic                   reset               ,
            input   var logic                   clk                 ,
            input   var logic                   cke                 ,

            // executions
            output  var id_t    [BUSY_RDS-1:0]  busy_id             ,
            output  var logic   [BUSY_RDS-1:0]  busy_rd_en          ,
            output  var ridx_t  [BUSY_RDS-1:0]  busy_rd_idx         ,

            // branch
            output  var id_t                    branch_id           ,
            output  var pc_t                    branch_pc           ,
            output  var pc_t                    branch_old_pc       ,
            output  var instr_t                 branch_instr        ,
            output  var logic                   branch_valid        ,

            // write-back
            output  var id_t                    wb_id               ,
            output  var pc_t                    wb_pc               ,
            output  var instr_t                 wb_instr            ,
            output  var logic                   wb_rd_en            ,
            output  var ridx_t                  wb_rd_idx           ,
            output  var rval_t                  wb_rd_val           ,

            // data bus 
            output  var addr_t  [LS_UNITS-1:0]  dbus_aaddr          ,
            output  var logic   [LS_UNITS-1:0]  dbus_awrite         ,
            output  var logic   [LS_UNITS-1:0]  dbus_aread          ,
            output  var logic   [LS_UNITS-1:0]  dbus_avalid         ,
            input   var logic   [LS_UNITS-1:0]  dbus_aready         ,
            output  var strb_t  [LS_UNITS-1:0]  dbus_wstrb          ,
            output  var data_t  [LS_UNITS-1:0]  dbus_wdata          ,
            output  var logic   [LS_UNITS-1:0]  dbus_wvalid         ,
            input   var logic   [LS_UNITS-1:0]  dbus_wready         ,
            input   var data_t  [LS_UNITS-1:0]  dbus_rdata          ,
            input   var logic   [LS_UNITS-1:0]  dbus_rvalid         ,
            output  var logic   [LS_UNITS-1:0]  dbus_rready         ,

            // output
            input   var id_t                    s_id                ,
            input   var phase_t                 s_phase             ,
            input   var pc_t                    s_pc                ,
            input   var instr_t                 s_instr             ,
            input   var logic                   s_rd_en             ,
            input   var ridx_t                  s_rd_idx            ,
            input   var rval_t                  s_rd_val            ,
            input   var logic                   s_rs1_en            ,
            input   var ridx_t                  s_rs1_idx           ,
            input   var rval_t                  s_rs1_val           ,
            input   var logic                   s_rs2_en            ,
            input   var ridx_t                  s_rs2_idx           ,
            input   var rval_t                  s_rs2_val           ,
            input   var logic                   s_offset            ,
            input   var logic                   s_adder             ,
            input   var logic                   s_slt               ,
            input   var logic                   s_logical           ,
            input   var logic                   s_shifter           ,
            input   var logic                   s_load              ,
            input   var logic                   s_store             ,
            input   var logic                   s_branch            ,
            input   var logic                   s_adder_sub         ,
            input   var logic                   s_adder_imm_en      ,
            input   var rval_t                  s_adder_imm_val     ,
            input   var logic                   s_slt_unsigned      ,
            input   var logic   [1:0]           s_logical_mode      ,
            input   var logic                   s_logical_imm_en    ,
            input   var rval_t                  s_logical_imm_val   ,
            input   var logic                   s_shifter_arithmetic,
            input   var logic                   s_shifter_left      ,
            input   var logic                   s_shifter_imm_en    ,
            input   var shamt_t                 s_shifter_imm_val   ,
            input   var logic   [2:0]           s_branch_mode       ,
            input   var pc_t                    s_branch_pc         ,
            input   var size_t                  s_mem_size          ,
            input   var logic                   s_mem_unsigned      ,
            input   var logic                   s_valid             ,
            output  var logic                   s_ready
        );

    localparam  int     ALIGN_BITS  = $clog2($bits(strb_t))             ;
    localparam  type    align_t     = logic         [ALIGN_BITS-1:0]    ;


    // branch phase table
    phase_t [THREADS-1:0]   phase_table;


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
                .cke            (cke & s_ready      ),

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
                .cke            (cke & s_ready      ),

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
                .cke            (cke & s_ready      ),
                
                .s_mode         (s_logical_mode     ),
                .s_imm_en       (s_logical_imm_en   ),
                .s_imm_val      (s_logical_imm_val  ),
                .s_rs1_val      (s_rs1_val          ),
                .s_rs2_val      (s_rs2_val          ),

                .m_rd_val       (st0_logical_rd_val )
        );

    // strobe計算
    function automatic strb_t make_strb(input size_t size, input align_t align);
        case ( size )
        2'b00:   return strb_t'('b0001) << (align & ~align_t'('b0000));
        2'b01:   return strb_t'('b0011) << (align & ~align_t'('b0001));
        2'b10:   return strb_t'('b1111) << (align & ~align_t'('b0011));
        default: return '1;
        endcase
    endfunction

    function automatic rval_t make_wdata(input size_t size, input rval_t val);
        case ( size )
        2'b00:   return {($bits(rval_t)/ 8){val[ 7:0]}};
        2'b01:   return {($bits(rval_t)/16){val[15:0]}};
        2'b10:   return {($bits(rval_t)/32){val[31:0]}};
        default: return val;
        endcase
    endfunction


    // control
    id_t                st0_id                  ;
    phase_t             st0_phase               ;
    pc_t                st0_pc                  ;
    instr_t             st0_instr               ;
    logic               st0_rd_en               ;
    logic               st0_rd_en_reg           ;
    ridx_t              st0_rd_idx              ;
    rval_t              st0_rd_val              ;
    logic               st0_rs1_en              ;
    ridx_t              st0_rs1_idx             ;
    rval_t              st0_rs1_val             ;
    logic               st0_rs2_en              ;
    ridx_t              st0_rs2_idx             ;
    rval_t              st0_rs2_val             ;

    logic               st0_offset              ;
    logic               st0_adder               ;
    logic               st0_slt                 ;
    logic               st0_logical             ;
    logic               st0_shifter             ;
    logic               st0_load                ;
    logic               st0_load_reg            ;
    logic               st0_store               ;
    logic               st0_store_reg           ;
    logic               st0_branch              ;
    logic               st0_branch_reg          ;
    logic               st0_branch_valid        ;
    logic               st0_adder_sub           ;
    logic               st0_adder_imm_en        ;
    rval_t              st0_adder_imm_val       ;
    logic               st0_slt_unsigned        ;
    logic   [1:0]       st0_logical_mode        ;
    logic               st0_logical_imm_en      ;
    rval_t              st0_logical_imm_val     ;
    logic               st0_shifter_arithmetic  ;
    logic               st0_shifter_left        ;
    logic               st0_shifter_imm_en      ;
    shamt_t             st0_shifter_imm_val     ;
    logic   [2:0]       st0_branch_mode         ;
    pc_t                st0_branch_pc           ;
    size_t              st0_mem_size            ;
    logic               st0_mem_unsigned        ;
    strb_t              st0_mem_wstrb           ;
    rval_t              st0_mem_wdata           ;
    logic               st0_mem_valid           ;
    logic               st0_mem_valid_reg       ;
    logic               st0_valid_reg           ;
    logic               st0_valid               ;
    logic               st0_ready               ;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_id                  <= 'x       ;
            st0_phase               <= 'x       ;
            st0_pc                  <= 'x       ;
            st0_instr               <= 'x       ;
            st0_rd_en_reg           <=1'b0      ;
            st0_rd_idx              <= 'x       ;
            st0_rd_val              <= 'x       ;
            st0_rs1_en              <= 'x       ;
            st0_rs1_idx             <= 'x       ;
            st0_rs1_val             <= 'x       ;
            st0_rs2_en              <= 'x       ;
            st0_rs2_idx             <= 'x       ;
            st0_rs2_val             <= 'x       ;
            st0_offset              <= 'x       ;
            st0_adder               <= 'x       ;
            st0_slt                 <= 'x       ;
            st0_logical             <= 'x       ;
            st0_shifter             <= 'x       ;
            st0_load_reg            <= 1'b0     ;
            st0_store_reg           <= 1'b0     ;
            st0_branch_reg          <= 1'b0     ;
            st0_adder_sub           <= 'x       ;
            st0_adder_imm_en        <= 'x       ;
            st0_adder_imm_val       <= 'x       ;
            st0_slt_unsigned        <= 'x       ;
            st0_logical_mode        <= 'x       ;
            st0_logical_imm_en      <= 'x       ;
            st0_logical_imm_val     <= 'x       ;
            st0_shifter_arithmetic  <= 'x       ;
            st0_shifter_left        <= 'x       ;
            st0_shifter_imm_en      <= 'x       ;
            st0_shifter_imm_val     <= 'x       ;
            st0_branch_mode         <= 'x       ;
            st0_branch_pc           <= 'x       ;
            st0_mem_size            <= 'x       ;
            st0_mem_unsigned        <= 'x       ;
            st0_mem_wstrb           <= '0       ;
            st0_mem_wdata           <= 'x       ;
            st0_mem_valid_reg       <= 1'b0     ;
            st0_valid_reg           <= 1'b0     ;
        end
        else if ( cke && s_ready ) begin
            st0_id                  <= s_id                 ;
            st0_phase               <= s_phase              ;
            st0_pc                  <= s_pc                 ;
            st0_instr               <= s_instr              ;
            st0_rd_en_reg           <= s_rd_en   & s_valid  ;
            st0_rd_idx              <= s_rd_idx             ;
            st0_rd_val              <= s_rd_val             ;
            st0_rs1_en              <= s_rs1_en             ;
            st0_rs1_idx             <= s_rs1_idx            ;
            st0_rs1_val             <= s_rs1_val            ;
            st0_rs2_en              <= s_rs2_en             ;
            st0_rs2_idx             <= s_rs2_idx            ;
            st0_rs2_val             <= s_rs2_val            ;
            st0_offset              <= s_offset             ;
            st0_adder               <= s_adder              ;
            st0_slt                 <= s_slt                ;
            st0_logical             <= s_logical            ;
            st0_shifter             <= s_shifter            ;
            st0_load_reg            <= s_load    & s_valid  ;
            st0_store_reg           <= s_store   & s_valid  ;
            st0_branch_reg          <= s_branch  & s_valid  ;
            st0_adder_sub           <= s_adder_sub          ;
            st0_adder_imm_en        <= s_adder_imm_en       ;
            st0_adder_imm_val       <= s_adder_imm_val      ;
            st0_slt_unsigned        <= s_slt_unsigned       ;
            st0_logical_mode        <= s_logical_mode       ;
            st0_logical_imm_en      <= s_logical_imm_en     ;
            st0_logical_imm_val     <= s_logical_imm_val    ;
            st0_shifter_arithmetic  <= s_shifter_arithmetic ;
            st0_shifter_left        <= s_shifter_left       ;
            st0_shifter_imm_en      <= s_shifter_imm_en     ;
            st0_shifter_imm_val     <= s_shifter_imm_val    ;
            st0_branch_mode         <= s_branch_mode        ;
            st0_branch_pc           <= s_branch_pc          ;
            st0_mem_size            <= s_mem_size           ;
            st0_mem_unsigned        <= s_mem_unsigned       ;
            st0_mem_wstrb           <= s_store ? make_strb (s_mem_size, align_t'(s_rs1_val + s_adder_imm_val)) : '0;
            st0_mem_wdata           <= make_wdata(s_mem_size, s_rs2_val)            ;
            st0_mem_valid_reg       <= (s_load || s_store) && s_valid               ;
            st0_valid_reg           <= s_valid                                      ;
        end
    end

    logic       st0_phase_en    ;
    assign st0_phase_en  = (st0_phase == phase_table[st0_id]);

    assign st0_rd_en        = st0_rd_en_reg     && st0_phase_en && st0_valid;
    assign st0_load         = st0_load_reg      && st0_phase_en;
    assign st0_store        = st0_store_reg     && st0_phase_en;
    assign st0_branch       = st0_branch_reg    && st0_phase_en;
    assign st0_mem_valid    = st0_mem_valid_reg && st0_phase_en;
    assign st0_valid        = st0_valid_reg     && st0_phase_en;
    assign st0_branch_valid = st0_branch  &&  st0_valid  && st0_ready;

    assign s_ready = !st0_valid || st0_ready;


    // -----------------------------------------
    //  stage 1
    // -----------------------------------------

    // shifter
    rval_t      st1_shifter_rd_val;
    jelly3_jfive_shifter
            #(
                .XLEN           (XLEN                       ),
                .SHAMT_BITS     (SHAMT_BITS                 ),
                .shamt_t        (shamt_t                    ),
                .rval_t         (rval_t                     ),
                .ridx_t         (ridx_t                     ),
                .DEVICE         (DEVICE                     ),
                .SIMULATION     (SIMULATION                 ),
                .DEBUG          (DEBUG                      )
            )
        u_jfive_shifter
            (
                .reset          ,
                .clk            ,
                .cke0           (cke && s_ready             ),
                .cke1           (cke && st0_ready           ),

                .s_arithmetic   (s_shifter_arithmetic       ),
                .s_left         (s_shifter_left             ),
                .s_imm_en       (s_shifter_imm_en           ),
                .s_rs1_val      (s_rs1_val                  ),
                .s_rs2_val      (shamt_t'(s_rs2_val)        ),
                .s_shamt        (s_shifter_imm_val          ),

                .m_rd_val       (st1_shifter_rd_val         )
            );

    // branch
    jelly3_jfive_branch
            #(
                .THREADS        (THREADS                    ),
                .ID_BITS        (ID_BITS                    ),
                .id_t           (id_t                       ),
                .PHASE_BITS     (PHASE_BITS                 ),
                .phase_t        (phase_t                    ),
                .PC_BITS        (PC_BITS                    ),
                .pc_t           (pc_t                       ),
                .DEVICE         (DEVICE                     ),
                .SIMULATION     (SIMULATION                 ),
                .DEBUG          (DEBUG                      )
            )
        u_jfive_branch
            (
                .reset           ,
                .clk             ,
                .cke             (cke                       ),

                .phase_table     (phase_table               ),

                .branch_id       ,
                .branch_pc       ,
                .branch_old_pc   ,
                .branch_instr    ,
                .branch_valid    ,

                .s_id            (st0_id                    ),
                .s_pc            (st0_pc                    ),
                .s_instr         (st0_instr                 ),
                .s_phase         (st0_phase                 ),
                .s_mode          (st0_branch_mode           ),
                .s_msb_c         (st0_adder_msb_c           ),
                .s_carry         (st0_adder_carry           ),
                .s_sign          (st0_adder_sign            ),
                .s_eq            (st0_match_eq              ),
                .s_jalr_pc       (st0_adder_rd_val          ),
                .s_imm_pc        (st0_branch_pc             ),
                .s_valid         (st0_branch_valid          )
            );

    // load/store
    logic   [LS_UNITS-1:0]                  mem_ready   ;
    id_t    [LS_UNITS-1:0][LOAD_QUES-1:0]   que_id      ;
    logic   [LS_UNITS-1:0][LOAD_QUES-1:0]   que_rd_en   ;
    ridx_t  [LS_UNITS-1:0][LOAD_QUES-1:0]   que_rd_idx  ;
    id_t    [LS_UNITS-1:0]                  load_id     ;
    pc_t    [LS_UNITS-1:0]                  load_pc     ;
    instr_t [LS_UNITS-1:0]                  load_instr  ;
    logic   [LS_UNITS-1:0]                  load_rd_en  ;
    ridx_t  [LS_UNITS-1:0]                  load_rd_idx ;
    rval_t  [LS_UNITS-1:0]                  load_rd_val ;
    logic   [LS_UNITS-1:0]                  load_valid  ;
    logic   [LS_UNITS-1:0]                  load_ready  ;
    for ( genvar i = 0; i < LS_UNITS; i++ ) begin : load_store

        jelly3_jfive_load_store
                #(
                    .LOAD_QUES          (LOAD_QUES                  ),
                    .XLEN               (XLEN                       ),
                    .ID_BITS            (ID_BITS                    ),
                    .id_t               (id_t                       ),
                    .PHASE_BITS         (PHASE_BITS                 ),
                    .phase_t            (phase_t                    ),
                    .PC_BITS            (PC_BITS                    ),
                    .pc_t               (pc_t                       ),
                    .INSTR_BITS         (INSTR_BITS                 ),
                    .instr_t            (instr_t                    ),
                    .ridx_t             (ridx_t                     ),
                    .rval_t             (rval_t                     ),
                    .ADDR_BITS          (ADDR_BITS                  ),
                    .addr_t             (addr_t                     ),
                    .DATA_BITS          (DATA_BITS                  ),
                    .data_t             (data_t                     ),
                    .STRB_BITS          (STRB_BITS                  ),
                    .strb_t             (strb_t                     ),
                    .ALIGN_BITS         (ALIGN_BITS                 ),
                    .align_t            (align_t                    ),
                    .size_t             (size_t                     ),
                    .ADDR_LO            (LS_ADDRS_LO[i]             ),
                    .ADDR_HI            (LS_ADDRS_HI[i]             ),
                    .DEVICE             (DEVICE                     ),
                    .SIMULATION         (SIMULATION                 ),
                    .DEBUG              (DEBUG                      )
                )
            u_jfive_load_store
                (
                    .reset              ,
                    .clk                ,
                    .cke                ,

                    .dbus_aaddr         (dbus_aaddr [i]             ) ,
                    .dbus_awrite        (dbus_awrite[i]             ) ,
                    .dbus_aread         (dbus_aread [i]             ) ,
                    .dbus_avalid        (dbus_avalid[i]             ) ,
                    .dbus_aready        (dbus_aready[i]             ) ,
                    .dbus_wstrb         (dbus_wstrb [i]             ) ,
                    .dbus_wdata         (dbus_wdata [i]             ) ,
                    .dbus_wvalid        (dbus_wvalid[i]             ) ,
                    .dbus_wready        (dbus_wready[i]             ) ,
                    .dbus_rdata         (dbus_rdata [i]             ) ,
                    .dbus_rvalid        (dbus_rvalid[i]             ) ,
                    .dbus_rready        (dbus_rready[i]             ) ,

                    .que_id             (que_id    [i]              ),
                    .que_rd_en          (que_rd_en [i]              ),
                    .que_rd_idx         (que_rd_idx[i]              ),

                    .s_id               (st0_id                     ),
                    .s_phase            (st0_phase                  ),
                    .s_pc               (st0_pc                     ),
                    .s_instr            (st0_instr                  ),
                    .s_rd_en            (st0_rd_en     & st0_valid  ),
                    .s_rd_idx           (st0_rd_idx                 ),
                    .s_addr             (st0_adder_rd_val           ),
                    .s_size             (st0_mem_size               ),
                    .s_unsigned         (st0_mem_unsigned           ),
                    .s_rd               (st0_load      & st0_valid  ),
                    .s_wr               (st0_store     & st0_valid  ),
                    .s_wstrb            (st0_mem_wstrb              ),
                    .s_wdata            (st0_mem_wdata              ),
                    .s_valid            (st0_mem_valid & st0_valid & st0_ready  ),
                    .s_ready            (mem_ready[i]               ),

                    .m_id               (load_id    [i]             ),
                    .m_pc               (load_pc    [i]             ),
                    .m_instr            (load_instr [i]             ),
                    .m_rd_en            (load_rd_en [i]             ),
                    .m_rd_idx           (load_rd_idx[i]             ),
                    .m_rd_val           (load_rd_val[i]             ),
                    .m_valid            (load_valid [i]             ),
                    .m_ready            (load_ready [i]             )
                );
    end

    // control
    id_t                st1_id          ;
    phase_t             st1_phase       ;
    pc_t                st1_pc          ;
    instr_t             st1_instr       ;
    logic               st1_rd_en       ;
    ridx_t              st1_rd_idx      ;
    rval_t              st1_rd_val      ;
    logic               st1_rs1_en      ;
    ridx_t              st1_rs1_idx     ;
    rval_t              st1_rs1_val     ;
    logic               st1_rs2_en      ;
    ridx_t              st1_rs2_idx     ;
    rval_t              st1_rs2_val     ;
    logic               st1_slt         ;
    logic               st1_slt_val     ;
    logic               st1_shifter     ;
    logic               st1_load        ;
    logic               st1_valid       ;
    logic               st1_ready       ;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st1_id      <= 'x;
            st1_phase   <= 'x;
            st1_pc      <= 'x;
            st1_instr   <= 'x;
            st1_rd_en   <= 'x;
            st1_rd_idx  <= 'x;
            st1_rd_val  <= 'x;
            st1_rs1_en  <= 'x;
            st1_rs1_idx <= 'x;
            st1_rs1_val <= 'x;
            st1_rs2_en  <= 'x;
            st1_rs2_idx <= 'x;
            st1_rs2_val <= 'x;
            st1_slt     <= 'x;
            st1_slt_val <= 'x;
            st1_shifter <= 'x;
            st1_load    <= 'x;
            st1_valid   <= 1'b0;
        end
        else if ( cke && st0_ready ) begin
            st1_id      <= st0_id     ;
            st1_phase   <= st0_phase  ;
            st1_pc      <= st0_pc     ;
            st1_instr   <= st0_instr  ;
            st1_rd_en   <= st0_rd_en && !st0_load && st0_valid;
            st1_rd_idx  <= st0_rd_idx ;
            st1_rd_val  <= st0_adder   ? st0_adder_rd_val   :
                           st0_logical ? st0_logical_rd_val :
                           st0_rd_val ;
            st1_rs1_en  <= st0_rs1_en ;
            st1_rs1_idx <= st0_rs1_idx;
            st1_rs1_val <= st0_rs1_val;
            st1_rs2_en  <= st0_rs2_en ;
            st1_rs2_idx <= st0_rs2_idx;
            st1_rs2_val <= st0_rs2_val;
            st1_slt     <= st0_slt    ;
            st1_slt_val <= st0_slt_unsigned ? ~st0_adder_carry : (st0_adder_carry ^ st0_adder_msb_c ^ st0_adder_sign);
            st1_shifter <= st0_shifter;
            st1_load    <= st0_load   ;
            st1_valid   <= st0_valid && st0_valid && s_ready;
        end
    end

    assign st0_ready = !st1_valid || (st1_ready && &mem_ready);


    // -----------------------------------------
    //  stage 2
    // -----------------------------------------

    // control
    id_t                st2_id          ;
    phase_t             st2_phase       ;
    pc_t                st2_pc          ;
    instr_t             st2_instr       ;
    logic               st2_rd_en       ;
    ridx_t              st2_rd_idx      ;
    rval_t              st2_rd_val      ;
    logic               st2_rs1_en      ;
    ridx_t              st2_rs1_idx     ;
    rval_t              st2_rs1_val     ;
    logic               st2_rs2_en      ;
    ridx_t              st2_rs2_idx     ;
    rval_t              st2_rs2_val     ;
    logic               st2_shifter     ;
    logic               st2_load        ;
    logic               st2_valid       ;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st2_id      <= 'x;
            st2_phase   <= 'x;
            st2_pc      <= 'x;
            st2_instr   <= 'x;
            st2_rd_en   <= 'x;
            st2_rd_idx  <= 'x;
            st2_rd_val  <= 'x;
            st2_rs1_en  <= 'x;
            st2_rs1_idx <= 'x;
            st2_rs1_val <= 'x;
            st2_rs2_en  <= 'x;
            st2_rs2_idx <= 'x;
            st2_rs2_val <= 'x;
            st2_shifter <= 'x;
            st2_load    <= 'x;
            st2_valid   <= 1'b0;
        end
        else if ( cke && st1_ready ) begin
            st2_id      <= st1_id     ;
            st2_phase   <= st1_phase  ;
            st2_pc      <= st1_pc     ;
            st2_instr   <= st1_instr  ;
            st2_rd_en   <= st1_rd_en  ;
            st2_rd_idx  <= st1_rd_idx ;
            st2_rd_val  <= st1_slt     ? rval_t'(st1_slt_val) :
                           st1_shifter ? st1_shifter_rd_val   :
                           st1_rd_val ;
            st2_rs1_en  <= st1_rs1_en ;
            st2_rs1_idx <= st1_rs1_idx;
            st2_rs1_val <= st1_rs1_val;
            st2_rs2_en  <= st1_rs2_en ;
            st2_rs2_idx <= st1_rs2_idx;
            st2_rs2_val <= st1_rs2_val;
            st2_shifter <= st1_shifter;
            st2_load    <= st1_load   ;
            st2_valid   <= st1_valid  ;
        end
    end

    // busy
    assign busy_id      = {que_id,     st0_id,     st1_id,     st2_id    };
    assign busy_rd_en   = {que_rd_en,  st0_rd_en,  st1_rd_en,  st2_rd_en };
    assign busy_rd_idx  = {que_rd_idx, st0_rd_idx, st1_rd_idx, st2_rd_idx};

    // writeback
    always_comb begin
        wb_id     = st2_id     ;
        wb_pc     = st2_pc     ;
        wb_instr  = st2_instr  ;
        wb_rd_en  = st2_rd_en  ;
        wb_rd_idx = st2_rd_idx ;
        wb_rd_val = st2_rd_val ;
        for ( int i = 0; i < LS_UNITS; i++ ) begin
            if ( load_valid[i] ) begin
                wb_id     = load_id    [i];
                wb_pc     = load_pc    [i];
                wb_instr  = load_instr [i];
                wb_rd_en  = load_rd_en [i];
                wb_rd_idx = load_rd_idx[i];
                wb_rd_val = load_rd_val[i];
                break;
            end
        end
    end

    // ready
    always_comb begin
        automatic logic ready = 1'b1;
        for ( int i = 0; i < LS_UNITS; i++ ) begin
            load_ready[i] = ready;
            if ( load_valid[i] ) begin
                ready = 1'b0;
            end
        end

        st1_ready = !(st2_valid && st2_rd_en) || ready;
    end

endmodule


`default_nettype wire


// End of file
