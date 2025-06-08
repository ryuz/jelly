// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_core
        #(
            parameter   int                     XLEN           = 32                                 ,
            parameter   int                     THREADS        = 4                                  ,
            parameter   int                     ID_BITS        = THREADS > 1 ? $clog2(THREADS) : 1  ,
            parameter   type                    id_t           = logic         [ID_BITS-1:0]        ,
            parameter   int                     PHASE_BITS     = 1                                  ,
            parameter   type                    phase_t        = logic         [PHASE_BITS-1:0]     ,
            parameter   int                     PC_BITS        = 32                                 ,
            parameter   type                    pc_t           = logic         [PC_BITS-1:0]        ,
            parameter   pc_t                    PC_MASK        = '0                                 ,
            parameter   int                     INSTR_BITS     = 32                                 ,
            parameter   type                    instr_t        = logic         [INSTR_BITS-1:0]     ,
            parameter   type                    ridx_t         = logic         [4:0]                ,
            parameter   type                    rval_t         = logic signed  [XLEN-1:0]           ,
            parameter   int                     LS_UNITS       = 2                                  ,
            parameter   rval_t  [LS_UNITS-1:0]  LS_ADDRS_LO    = '{32'h8000_0000, 32'h0000_0000}    ,
            parameter   rval_t  [LS_UNITS-1:0]  LS_ADDRS_HI    = '{32'hffff_ffff, 32'h7fff_ffff}    ,
            parameter   int                     LOAD_QUES      = 2                                  ,
            parameter   int                     DBUS_ADDR_BITS = 10                                 ,
            parameter   type                    dbus_addr_t    = logic         [DBUS_ADDR_BITS-1:0] ,
            parameter   int                     DBUS_DATA_BITS = XLEN                               ,
            parameter   type                    dbus_data_t    = logic         [DBUS_DATA_BITS-1:0] ,
            parameter   int                     DBUS_STRB_BITS = $bits(dbus_data_t) / 8             ,
            parameter   type                    dbus_strb_t    = logic         [DBUS_STRB_BITS-1:0] ,

            parameter   bit     [THREADS-1:0]   INIT_RUN    = 1                                     ,
            parameter   id_t                    INIT_ID     = '0                                    ,
            parameter   pc_t    [THREADS-1:0]   INIT_PC     = '0                                    ,

            parameter                           DEVICE      = "RTL"                                 ,
            parameter                           SIMULATION  = "false"                               ,
            parameter                           DEBUG       = "false"                               
        )
        (
            input   var logic                       reset       ,
            input   var logic                       clk         ,
            input   var logic                       cke         ,

            // instruction bus
            output  var id_t                        ibus_aid    ,
            output  var phase_t                     ibus_aphase ,
            output  var pc_t                        ibus_apc    ,
            output  var logic                       ibus_avalid ,
            input   var logic                       ibus_aready ,
            input   var id_t                        ibus_rid    ,
            input   var phase_t                     ibus_rphase ,
            input   var pc_t                        ibus_rpc    ,
            input   var instr_t                     ibus_rinstr ,
            input   var logic                       ibus_rvalid ,
            output  var logic                       ibus_rready ,

            // data bus
            output  var dbus_addr_t [LS_UNITS-1:0]  dbus_aaddr  ,
            output  var logic       [LS_UNITS-1:0]  dbus_awrite ,
            output  var logic       [LS_UNITS-1:0]  dbus_aread  ,
            output  var logic       [LS_UNITS-1:0]  dbus_avalid ,
            input   var logic       [LS_UNITS-1:0]  dbus_aready ,
            output  var dbus_strb_t [LS_UNITS-1:0]  dbus_wstrb  ,
            output  var dbus_data_t [LS_UNITS-1:0]  dbus_wdata  ,
            output  var logic       [LS_UNITS-1:0]  dbus_wvalid ,
            input   var logic       [LS_UNITS-1:0]  dbus_wready ,
            input   var dbus_data_t [LS_UNITS-1:0]  dbus_rdata  ,
            input   var logic       [LS_UNITS-1:0]  dbus_rvalid ,
            output  var logic       [LS_UNITS-1:0]  dbus_rready  
        );



    // -----------------------------
    //  Program Counter
    // -----------------------------

    id_t    wakeup_id       ;
    logic   wakeup_valid    = 0;

    id_t    shutdown_id     ;
    logic   shutdown_valid  = 0;

    id_t    branch_id       ;
    pc_t    branch_pc       ;
    pc_t    branch_old_pc   ;
    instr_t branch_instr    ;
    logic   branch_valid    ;

    id_t    pc_id           ;
    phase_t pc_phase        ;
    pc_t    pc_pc           ;
    logic   pc_valid        ;
    logic   pc_ready        ;

    jelly3_jfive_program_counter
            #(
                .THREADS            (THREADS            ),
                .ID_BITS            (ID_BITS            ),
                .id_t               (id_t               ),
                .PC_BITS            (PC_BITS            ),
                .pc_t               (pc_t               ),
                .INIT_RUN           (INIT_RUN           ),
                .INIT_ID            (INIT_ID            ),
                .INIT_PC            (INIT_PC            ),
                .PC_MASK            (PC_MASK            ),
                .DEVICE             (DEVICE             ),
                .SIMULATION         (SIMULATION         )
            )
        u_jfive_program_counter
            (
                .reset              ,
                .clk                ,
                .cke                ,

                .wakeup_id          (wakeup_id          ),
                .wakeup_valid       (wakeup_valid       ),
                .shutdown_id        (shutdown_id        ),
                .shutdown_valid     (shutdown_valid     ),
                
                .branch_id          (branch_id          ),
                .branch_pc          (branch_pc          ),
                .branch_valid       (branch_valid       ),
                
                .m_id               (pc_id              ),
                .m_phase            (pc_phase           ),
                .m_pc               (pc_pc              ),
                .m_valid            (pc_valid           ),
                .m_ready            (pc_ready           )
            );


    // -----------------------------
    //  Instruction Fetch
    // -----------------------------

    id_t    if_id       ;
    phase_t if_phase    ;
    pc_t    if_pc       ;
    instr_t if_instr    ;
    logic   if_valid    ;
    logic   if_ready    ;

    assign ibus_aid    = pc_id   ;
    assign ibus_aphase = pc_phase;
    assign ibus_apc    = pc_pc   ;
    assign ibus_avalid = pc_valid;
    assign pc_ready = ibus_aready;

    /*
    assign if_id    = ibus_rid   ;
    assign if_phase = ibus_rphase;
    assign if_pc    = ibus_rpc   ;
    assign if_instr = ibus_rinstr;
    assign if_valid = ibus_rvalid;
    assign ibus_rready = if_ready;
    */
    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits({
                                    if_id       ,
                                    if_phase    ,
                                    if_pc       ,
                                    if_instr    
                                })),
                .S_REG          (1              ),
                .M_REG          (0              ),
                .INIT_DATA      ('x             ),
                .RESET_READY    (1'b1           )
            )
        u_stream_ff
            (
                .reset          ,
                .clk            ,
                .cke            ,

                .s_data         ({
                                    ibus_rid    ,
                                    ibus_rphase ,
                                    ibus_rpc    ,
                                    ibus_rinstr
                                }),
                .s_valid        (ibus_rvalid    ),
                .s_ready        (ibus_rready    ),

                .m_data         ({
                                    if_id       ,
                                    if_phase    ,
                                    if_pc       ,
                                    if_instr
                                }),
                .m_valid        (if_valid       ),
                .m_ready        (if_ready       )
            );


    // -----------------------------
    //  Instruction Decode
    // -----------------------------

    localparam  int     BUSY_RDS         = 3 + LS_UNITS * LOAD_QUES         ;
    localparam  bit     RAW_HAZARD       = 1'b1                             ;
    localparam  bit     WAW_HAZARD       = 1'b1                             ;
    localparam  int     SHAMT_BITS       = $clog2(XLEN)                     ;
//  localparam  type    shamt_t          = logic        [SHAMT_BITS-1:0]    ;   // 何故か verilator がエラーになる
    localparam  type    shamt_t          = logic        [4:0]               ;
    localparam  type    size_t           = logic        [1:0]               ;


    id_t    [BUSY_RDS-1:0]  busy_id             ;
    logic   [BUSY_RDS-1:0]  busy_rd_en          ;
    ridx_t  [BUSY_RDS-1:0]  busy_rd_idx         ;

    id_t                wb_id                   ;
    pc_t                wb_pc                   ;
    instr_t             wb_instr                ;
    logic               wb_rd_en                ;
    ridx_t              wb_rd_idx               ;
    rval_t              wb_rd_val               ;

    id_t                id_id                   ;
    phase_t             id_phase                ;
    pc_t                id_pc                   ;
    instr_t             id_instr                ;
    logic               id_rd_en                ;
    ridx_t              id_rd_idx               ;
    rval_t              id_rd_val               ;
    logic               id_rs1_en               ;
    ridx_t              id_rs1_idx              ;
    rval_t              id_rs1_val              ;
    logic               id_rs2_en               ;
    ridx_t              id_rs2_idx              ;
    rval_t              id_rs2_val              ;
    logic               id_offset               ;
    logic               id_adder                ;
    logic               id_slt                  ;
    logic               id_logical              ;
    logic               id_shifter              ;
    logic               id_load                 ;
    logic               id_store                ;
    logic               id_branch               ;
    logic               id_adder_sub            ;
    logic               id_adder_imm_en         ;
    rval_t              id_adder_imm_val        ;
    logic               id_slt_unsigned         ;
    logic   [1:0]       id_logical_mode         ;
    logic               id_logical_imm_en       ;
    rval_t              id_logical_imm_val      ;
    logic               id_shifter_arithmetic   ;
    logic               id_shifter_left         ;
    logic               id_shifter_imm_en       ;
    shamt_t             id_shifter_imm_val      ;
    logic   [2:0]       id_branch_mode          ;
    pc_t                id_branch_pc            ;
    size_t              id_mem_size             ;
    logic               id_mem_unsigned         ;
    logic               id_valid                ;
    logic               id_ready                ;
    
    jelly3_jfive_instruction_decode
            #(
                .XLEN                   (XLEN                   ),
                .THREADS                (THREADS                ),
                .ID_BITS                (ID_BITS                ),
                .id_t                   (id_t                   ),
                .PHASE_BITS             (PHASE_BITS             ),
                .phase_t                (phase_t                ),
                .PC_BITS                (PC_BITS                ),
                .pc_t                   (pc_t                   ),
                .INSTR_BITS             (INSTR_BITS             ),
                .instr_t                (instr_t                ),
                .ridx_t                 (ridx_t                 ),
                .rval_t                 (rval_t                 ),
                .shamt_t                (shamt_t                ),
                .BUSY_RDS               (BUSY_RDS               ),
                .RAW_HAZARD             (RAW_HAZARD             ),
                .WAW_HAZARD             (WAW_HAZARD             ),
                .DEVICE                 (DEVICE                 ),
                .SIMULATION             (SIMULATION             ),
                .DEBUG                  (DEBUG                  )
            )
        u_jfive_instruction_decode
            (
                .reset                  ,
                .clk                    ,
                .cke                    ,
                
                .busy_id                ,
                .busy_rd_en             ,
                .busy_rd_idx            ,

                .wb_id                  ,
                .wb_rd_en               ,
                .wb_rd_idx              ,
                .wb_rd_val              ,

                .s_id                   (if_id                  ),
                .s_phase                (if_phase               ),
                .s_pc                   (if_pc                  ),
                .s_instr                (if_instr               ),
                .s_valid                (if_valid               ),
                .s_ready                (if_ready               ),

                .m_id                   (id_id                  ),
                .m_phase                (id_phase               ),
                .m_pc                   (id_pc                  ),
                .m_instr                (id_instr               ),
                .m_rd_en                (id_rd_en               ),
                .m_rd_idx               (id_rd_idx              ),
                .m_rd_val               (id_rd_val              ),
                .m_rs1_en               (id_rs1_en              ),
                .m_rs1_idx              (id_rs1_idx             ),
                .m_rs1_val              (id_rs1_val             ),
                .m_rs2_en               (id_rs2_en              ),
                .m_rs2_idx              (id_rs2_idx             ),
                .m_rs2_val              (id_rs2_val             ),
                .m_offset               (id_offset              ),
                .m_adder                (id_adder               ),
                .m_slt                  (id_slt                 ),
                .m_logical              (id_logical             ),
                .m_shifter              (id_shifter             ),
                .m_load                 (id_load                ),
                .m_store                (id_store               ),
                .m_branch               (id_branch              ),
                .m_adder_sub            (id_adder_sub           ),
                .m_adder_imm_en         (id_adder_imm_en        ),
                .m_adder_imm_val        (id_adder_imm_val       ),
                .m_slt_unsigned         (id_slt_unsigned        ),
                .m_logical_mode         (id_logical_mode        ),
                .m_logical_imm_en       (id_logical_imm_en      ),
                .m_logical_imm_val      (id_logical_imm_val     ),
                .m_shifter_arithmetic   (id_shifter_arithmetic  ),
                .m_shifter_left         (id_shifter_left        ),
                .m_shifter_imm_en       (id_shifter_imm_en      ),
                .m_shifter_imm_val      (id_shifter_imm_val     ),
                .m_branch_mode          (id_branch_mode         ),
                .m_branch_pc            (id_branch_pc           ),
                .m_mem_size             (id_mem_size            ),
                .m_mem_unsigned         (id_mem_unsigned        ),
                .m_valid                (id_valid               ),
                .m_ready                (id_ready               )
        );



    // -----------------------------
    //  Execution
    // -----------------------------

    jelly3_jfive_execution
            #(
                .XLEN                   (XLEN                   ),
                .THREADS                (THREADS                ),
                .ID_BITS                (ID_BITS                ),
                .id_t                   (id_t                   ),
                .PHASE_BITS             (PHASE_BITS             ),
                .phase_t                (phase_t                ),
                .PC_BITS                (PC_BITS                ),
                .pc_t                   (pc_t                   ),
                .INSTR_BITS             (INSTR_BITS             ),
                .instr_t                (instr_t                ),
                .ridx_t                 (ridx_t                 ),
                .rval_t                 (rval_t                 ),
                .SHAMT_BITS             (SHAMT_BITS             ),
                .shamt_t                (shamt_t                ),
                .ADDR_BITS              (DBUS_ADDR_BITS         ),
                .addr_t                 (dbus_addr_t            ),
                .DATA_BITS              (DBUS_DATA_BITS         ),
                .data_t                 (dbus_data_t            ),
                .STRB_BITS              (DBUS_STRB_BITS         ),
                .strb_t                 (dbus_strb_t            ),
                .size_t                 (size_t                 ),
                .LS_UNITS               (LS_UNITS               ),
                .LS_ADDRS_LO            (LS_ADDRS_LO            ),
                .LS_ADDRS_HI            (LS_ADDRS_HI            ),
                .LOAD_QUES              (LOAD_QUES              ),
                .BUSY_RDS               (BUSY_RDS               ),
                .RAW_HAZARD             (RAW_HAZARD             ),
                .WAW_HAZARD             (WAW_HAZARD             ),
                .DEVICE                 (DEVICE                 ),
                .SIMULATION             (SIMULATION             ),
                .DEBUG                  ("true"                 )
            )
        u_jfive_execution
            (
                .reset                  ,
                .clk                    ,
                .cke                    ,
                
                .busy_id                ,
                .busy_rd_en             ,
                .busy_rd_idx            ,
                
                .branch_id              ,
                .branch_pc              ,
                .branch_old_pc          ,
                .branch_instr           ,
                .branch_valid           ,

                .wb_id                  ,
                .wb_pc                  ,
                .wb_instr               ,
                .wb_rd_en               ,
                .wb_rd_idx              ,
                .wb_rd_val              ,

                .dbus_aaddr             ,
                .dbus_awrite            ,
                .dbus_aread             ,
                .dbus_avalid            ,
                .dbus_aready            ,
                .dbus_wstrb             ,
                .dbus_wdata             ,
                .dbus_wvalid            ,
                .dbus_wready            ,
                .dbus_rdata             ,
                .dbus_rvalid            ,
                .dbus_rready            ,

                .s_id                   (id_id                  ),
                .s_phase                (id_phase               ),
                .s_pc                   (id_pc                  ),
                .s_instr                (id_instr               ),
                .s_rd_en                (id_rd_en               ),
                .s_rd_idx               (id_rd_idx              ),
                .s_rd_val               (id_rd_val              ),
                .s_rs1_en               (id_rs1_en              ),
                .s_rs1_idx              (id_rs1_idx             ),
                .s_rs1_val              (id_rs1_val             ),
                .s_rs2_en               (id_rs2_en              ),
                .s_rs2_idx              (id_rs2_idx             ),
                .s_rs2_val              (id_rs2_val             ),
                .s_offset               (id_offset              ),
                .s_adder                (id_adder               ),
                .s_slt                  (id_slt                 ),
                .s_logical              (id_logical             ),
                .s_shifter              (id_shifter             ),
                .s_load                 (id_load                ),
                .s_store                (id_store               ),
                .s_branch               (id_branch              ),
                .s_adder_sub            (id_adder_sub           ),
                .s_adder_imm_en         (id_adder_imm_en        ),
                .s_adder_imm_val        (id_adder_imm_val       ),
                .s_slt_unsigned         (id_slt_unsigned        ),
                .s_logical_mode         (id_logical_mode        ),
                .s_logical_imm_en       (id_logical_imm_en      ),
                .s_logical_imm_val      (id_logical_imm_val     ),
                .s_shifter_arithmetic   (id_shifter_arithmetic  ),
                .s_shifter_left         (id_shifter_left        ),
                .s_shifter_imm_en       (id_shifter_imm_en      ),
                .s_shifter_imm_val      (id_shifter_imm_val     ),
                .s_branch_mode          (id_branch_mode         ),
                .s_branch_pc            (id_branch_pc           ),
                .s_mem_size             (id_mem_size            ),
                .s_mem_unsigned         (id_mem_unsigned        ),
                .s_valid                (id_valid               ),
                .s_ready                (id_ready               )
        );


endmodule


`default_nettype wire


// End of file
