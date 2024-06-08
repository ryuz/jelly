
`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_simple
        #(
            parameter  int                     XLEN           = 32                                 ,
            parameter  int                     THREADS        = 4                                  ,
            parameter  int                     ID_BITS        = THREADS > 1 ? $clog2(THREADS) : 1  ,
            parameter  type                    id_t           = logic         [ID_BITS-1:0]        ,
            parameter  int                     PHASE_BITS     = 1                                  ,
            parameter  type                    phase_t        = logic         [PHASE_BITS-1:0]     ,
            parameter  int                     PC_BITS        = 32                                 ,
            parameter  type                    pc_t           = logic         [PC_BITS-1:0]        ,
            parameter  pc_t                    PC_MASK        = '0                                 ,
            parameter  int                     INSTR_BITS     = 32                                 ,
            parameter  type                    instr_t        = logic         [INSTR_BITS-1:0]     ,
        //  parameter  int                     IBUS_ADDR_BITS = 10                                 ,
        //  parameter  type                    ibus_addr_t    = logic         [IBUS_ADDR_BITS-1:0] ,
        //  parameter  int                     IBUS_DATA_BITS = INSTR_BITS                         ,
        //  parameter  type                    ibus_data_t    = logic         [IBUS_DATA_BITS-1:0] ,
            parameter  int                     DBUS_ADDR_BITS = 10                                 ,
            parameter  type                    dbus_addr_t    = logic         [DBUS_ADDR_BITS-1:0] ,
            parameter  int                     DBUS_DATA_BITS = XLEN                               ,
            parameter  type                    dbus_data_t    = logic         [DBUS_DATA_BITS-1:0] ,
            parameter  int                     DBUS_STRB_BITS = $bits(dbus_data_t) / 8             ,
            parameter  type                    dbus_strb_t    = logic         [DBUS_STRB_BITS-1:0] ,
        //  parameter  type                    ridx_t         = logic         [4:0]                ,
        //  parameter  type                    rval_t         = logic signed  [XLEN-1:0]           ,
        //  parameter  type                    shamt_t        = logic         [$clog2(XLEN)-1:0]   ,
        //  parameter  int                     EXES           = 4                                  ,
        //  parameter  bit                     RAW_HAZARD     = 1'b1                               ,
        //  parameter  bit                     WAW_HAZARD     = 1'b1                               ,
            parameter  bit     [THREADS-1:0]   INIT_RUN    = 1                                     ,
            parameter  id_t                    INIT_ID     = '0                                    ,
            parameter  pc_t    [THREADS-1:0]   INIT_PC     = '0                                    ,
            parameter                          DEVICE      = "RTL"                                 ,
            parameter                          SIMULATION  = "false"                               ,
            parameter                          DEBUG       = "false"                               
        )
        (
            input   var logic           reset   ,
            input   var logic           clk     ,
            output  var logic   [31:0]  monitor
        );

    logic               cke              = 1'b1;
    id_t                ibus_cmd_id     ;
    phase_t             ibus_cmd_phase  ;
    pc_t                ibus_cmd_pc     ;
    logic               ibus_cmd_valid  ;
    logic               ibus_cmd_wait   ;
    id_t                ibus_res_id     ;
    phase_t             ibus_res_phase  ;
    pc_t                ibus_res_pc     ;
    instr_t             ibus_res_instr  ;
    logic               ibus_res_valid  ;
    logic               ibus_res_wait   ;
    dbus_addr_t         dbus_cmd_addr   ;
    logic               dbus_cmd_wr     ;
    dbus_strb_t         dbus_cmd_strb   ;
    dbus_data_t         dbus_cmd_wdata  ;
    logic               dbus_cmd_valid  ;
    logic               dbus_cmd_wait   ;
    dbus_data_t         dbus_res_rdata  ;
    logic               dbus_res_valid  ;
    logic               dbus_res_wait   ;

    jelly3_jfive_core
        #(
                .XLEN               (XLEN           ),
                .THREADS            (THREADS        ),
                .ID_BITS            (ID_BITS        ),
                .id_t               (id_t           ),
                .PHASE_BITS         (PHASE_BITS     ),
                .phase_t            (phase_t        ),
                .PC_BITS            (PC_BITS        ),
                .pc_t               (pc_t           ),
                .PC_MASK            (PC_MASK        ),
                .INSTR_BITS         (INSTR_BITS     ),
                .instr_t            (instr_t        ),
    //          .IBUS_ADDR_BITS     (IBUS_ADDR_BITS ),
    //          .ibus_addr_t        (ibus_addr_t    ),
    //          .IBUS_DATA_BITS     (IBUS_DATA_BITS ),
    //          .ibus_data_t        (ibus_data_t    ),
                .DBUS_ADDR_BITS     (DBUS_ADDR_BITS ),
                .dbus_addr_t        (dbus_addr_t    ),
                .DBUS_DATA_BITS     (DBUS_DATA_BITS ),
                .dbus_data_t        (dbus_data_t    ),
                .DBUS_STRB_BITS     (DBUS_STRB_BITS ),
                .dbus_strb_t        (dbus_strb_t    ),
    //          .ridx_t             (ridx_t         ),
    //          .rval_t             (rval_t         ),
    //          .shamt_t            (shamt_t        ),
    //          .EXES               (EXES           ),
    //          .RAW_HAZARD         (RAW_HAZARD     ),
    //          .WAW_HAZARD         (WAW_HAZARD     ),
                .INIT_RUN           (INIT_RUN       ),
                .INIT_ID            (INIT_ID        ),
                .INIT_PC            (INIT_PC        ),
                .DEVICE             (DEVICE         ),
                .SIMULATION         (SIMULATION     ),
                .DEBUG              (DEBUG          )
            )
        u_jfive_core
            (
                .reset              ,
                .clk                ,
                .cke                ,
                .ibus_cmd_id        ,
                .ibus_cmd_phase     ,
                .ibus_cmd_pc        ,
                .ibus_cmd_valid     ,
                .ibus_cmd_wait      ,
                .ibus_res_id        ,
                .ibus_res_phase     ,
                .ibus_res_pc        ,
                .ibus_res_instr     ,
                .ibus_res_valid     ,
                .ibus_res_wait      ,
                .dbus_cmd_addr      ,
                .dbus_cmd_wr        ,
                .dbus_cmd_strb      ,
                .dbus_cmd_wdata     ,
                .dbus_cmd_valid     ,
                .dbus_cmd_wait      ,
                .dbus_res_rdata     ,
                .dbus_res_valid     ,
                .dbus_res_wait      
            );


    localparam int  MEM_ADDR_BITS  = 14;
    localparam type mem_addr_t     = logic  [MEM_ADDR_BITS-1:0] ;
    localparam int  MEM_DATA_BITS  = 32;
    localparam type mem_data_t     = logic  [MEM_DATA_BITS-1:0] ;
    localparam int  MEM_WE_BITS    = $bits(mem_data_t) / 8;
    localparam type mem_we_t       = logic  [MEM_WE_BITS-1:0]   ;

    mem_we_t        port0_we    ;
    mem_addr_t      port0_addr  ;
    mem_data_t      port0_din   ;
    mem_data_t      port0_dout  ;

    mem_we_t        port1_we    ;
    mem_addr_t      port1_addr  ;
    mem_data_t      port1_din   ;
    mem_data_t      port1_dout  ;

    jelly2_ram_dualport
            #(
                .ADDR_WIDTH     ($bits(mem_addr_t)  ),
                .DATA_WIDTH     (32                 ),
                .WE_WIDTH       (4                  ),
                .WORD_WIDTH     (8                  ),
                .RAM_TYPE       ("block"            ),
                .DOUT_REGS0     (1                  ),
                .DOUT_REGS1     (1                  ),
                .MODE0          ("NO_CHANGE"        ),
                .MODE1          ("NO_CHANGE"        ),
                .FILLMEM        (0                  ),
                .FILLMEM_DATA   (0                  ),
                .READMEMB       (0                  ),
                .READMEMH       (1                  ),
                .READMEM_FIlE   ("../mem.hex"       )
            )
        u_ram_dualport
            (
                .port0_clk      (clk                ),
                .port0_en       (cke                ),
                .port0_regcke   (cke                ),
                .port0_we       (port0_we           ),
                .port0_addr     (port0_addr         ),
                .port0_din      (port0_din          ),
                .port0_dout     (port0_dout         ),

                .port1_clk      (clk                ),
                .port1_en       (cke                ),
                .port1_regcke   (cke                ),
                .port1_we       (port1_we           ),
                .port1_addr     (port1_addr         ),
                .port1_din      (port1_din          ),
                .port1_dout     (port1_dout         )
            );
    
    assign port0_we    = '0;
    assign port0_addr  = mem_addr_t'(ibus_cmd_pc >> 2);
    assign port0_din   = '0;
    
    id_t    ibus_st0_id     ;
    phase_t ibus_st0_phase  ;
    pc_t    ibus_st0_pc     ;
    logic   ibus_st0_valid  ;
    id_t    ibus_st1_id     ;
    phase_t ibus_st1_phase  ;
    pc_t    ibus_st1_pc     ;
    logic   ibus_st1_valid  ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            ibus_st0_id     <= 'x;
            ibus_st0_phase  <= 'x;
            ibus_st0_pc     <= 'x;
            ibus_st0_valid  <= 1'b0;
            ibus_st1_id     <= 'x;
            ibus_st1_phase  <= 'x;
            ibus_st1_pc     <= 'x;
            ibus_st1_valid  <= 1'b0;
        end
        else if ( cke ) begin
            ibus_st0_id     <= ibus_cmd_id;
            ibus_st0_phase  <= ibus_cmd_phase;
            ibus_st0_pc     <= ibus_cmd_pc;
            ibus_st0_valid  <= ibus_cmd_valid;
            ibus_st1_id     <= ibus_st0_id;
            ibus_st1_phase  <= ibus_st0_phase;
            ibus_st1_pc     <= ibus_st0_pc;
            ibus_st1_valid  <= ibus_st0_valid;
        end
    end

    assign ibus_cmd_wait  = ibus_res_wait   ;

    assign ibus_res_id    = ibus_st1_id     ;
    assign ibus_res_phase = ibus_st1_phase  ;
    assign ibus_res_pc    = ibus_st1_pc     ;
    assign ibus_res_instr = port0_dout      ;
    assign ibus_res_valid = ibus_st1_valid  ;


    // dbus
    assign port1_addr = mem_addr_t'(dbus_cmd_addr)  ;
    assign port1_we   = dbus_cmd_strb               ;
    assign port1_din  = dbus_cmd_wdata              ;

    logic   dbus_st0_valid  ;
    logic   dbus_st1_valid  ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            dbus_st0_valid  <= 1'b0;
            dbus_st1_valid  <= 1'b0;
        end
        else if ( cke && !dbus_res_wait ) begin
            dbus_st0_valid  <= dbus_cmd_valid && !dbus_cmd_wr;
            dbus_st1_valid  <= dbus_st0_valid;
        end
    end

    assign dbus_cmd_wait  = dbus_res_wait   ;
    assign dbus_res_rdata = port1_dout      ;
    assign dbus_res_valid = dbus_st1_valid  ;

    assign monitor = dbus_cmd_wdata;

endmodule


`default_nettype wire


// end of file
