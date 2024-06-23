
`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_controller
        #(
            parameter   int                         XLEN              = 32                                  ,
            parameter   int                         THREADS           = 4                                   ,
            localparam  int                         ID_BITS           = THREADS > 1 ? $clog2(THREADS) : 1   ,
            localparam  type                        id_t              = logic         [ID_BITS-1:0]         ,
            localparam  int                         PC_BITS           = 32                                  ,
            localparam  type                        pc_t              = logic         [PC_BITS-1:0]         ,
            parameter   pc_t                        PC_MASK           = '0                                  ,
            localparam  type                        rval_t            = logic signed  [XLEN-1:0]            ,
            parameter   int                         LOAD_QUES         = 2                                   ,
            parameter   int                         TCM_MEM_SIZE      = 64 * 1024                           ,
            parameter   rval_t                      TCM_ADDR_LO       = 32'h0000_0000                       ,
            parameter   rval_t                      TCM_ADDR_HI       = 32'h7fff_ffff                       ,
            parameter                               TCM_RAM_TYPE      = "block"                             ,
            parameter   bit                         TCM_READMEMB      = 1'b0                                ,
            parameter   bit                         TCM_READMEMH      = 1'b0                                ,
            parameter                               TCM_READMEM_FIlE  = ""                                  ,
            parameter   int                         M_AXI4L_PORTS     = 1                                   ,
            parameter   int                         M_AXI4L_ADDR_BITS = 32                                  ,
            localparam  type                        m_axi4l_data_t    = logic         [M_AXI4L_ADDR_BITS-1:0],
            parameter   rval_t  [M_AXI4L_PORTS-1:0] M_AXI4L_ADDRS_LO  = '{32'h8000_0000}                    ,
            parameter   rval_t  [M_AXI4L_PORTS-1:0] M_AXI4L_ADDRS_HI  = '{32'hffff_ffff}                    ,
            parameter   bit     [THREADS-1:0]       INIT_RUN          = 1                                   ,
            parameter   id_t                        INIT_ID           = '0                                  ,
            parameter   pc_t    [THREADS-1:0]       INIT_PC           = '0                                  ,
            parameter                               DEVICE            = "ULTRASCALE_PLUS", //"RTL"          ,
            parameter                               SIMULATION        = "false"                             ,
            parameter                               DEBUG              = "false"                            
        )
        (
            input   var logic           reset   ,
            input   var logic           clk     ,
            input   var logic           cke     ,

            jelly3_axi4l_if.s           s_axi4l                         ,
            jelly3_axi4l_if.m           m_axi4l   [0:M_AXI4L_PORTS-1]   ,

            output  var logic   [31:0]  monitor
        );


    // ---------------------------------------------------------
    //  parameter
    // ---------------------------------------------------------

    localparam   int                    PHASE_BITS     = 1                                                  ;
    localparam  type                    phase_t        = logic         [PHASE_BITS-1:0]                     ;

    localparam  int                     INSTR_BITS     = 32                                                 ;
    localparam  type                    instr_t        = logic         [INSTR_BITS-1:0]                     ;
    localparam  type                    ridx_t         = logic         [4:0]                                ;

    localparam  int                     TCM_SIZE       = (TCM_MEM_SIZE + $bits(rval_t)-1) / $bits(rval_t)   ;
    localparam  int                     TCM_ADDR_BITS  = $clog2(TCM_SIZE);
    
    localparam   type                   tcm_addr_t     = logic  [TCM_ADDR_BITS-1:0]                         ;
    localparam   int                    TCM_DATA_BITS  = 32                                                 ;
    localparam   type                   tcm_data_t     = logic  [TCM_DATA_BITS-1:0]                         ;

    localparam  int                     LS_UNITS       = 1 + M_AXI4L_PORTS                                  ;
    localparam  rval_t  [LS_UNITS-1:0]  LS_ADDRS_LO    = {M_AXI4L_ADDRS_LO, TCM_ADDR_LO}                    ;
    localparam  rval_t  [LS_UNITS-1:0]  LS_ADDRS_HI    = {M_AXI4L_ADDRS_HI, TCM_ADDR_HI}                    ;

    localparam  int                     IBUS_ADDR_BITS = TCM_ADDR_BITS                      ;
    localparam  type                    ibus_addr_t    = logic         [IBUS_ADDR_BITS-1:0] ;
    localparam  int                     IBUS_DATA_BITS = INSTR_BITS                         ;
    localparam  type                    ibus_data_t    = logic         [IBUS_DATA_BITS-1:0] ;
    localparam  int                     DBUS_ADDR_BITS = TCM_ADDR_BITS > M_AXI4L_ADDR_BITS  ? TCM_ADDR_BITS : M_AXI4L_ADDR_BITS;
    localparam  type                    dbus_addr_t    = logic         [DBUS_ADDR_BITS-1:0] ;
    localparam  int                     DBUS_DATA_BITS = XLEN                               ;
    localparam  type                    dbus_data_t    = logic         [DBUS_DATA_BITS-1:0] ;
    localparam  int                     DBUS_STRB_BITS = $bits(dbus_data_t) / 8             ;
    localparam  type                    dbus_strb_t    = logic         [DBUS_STRB_BITS-1:0] ;


    rval_t  [LS_UNITS-1:0]  param_LS_ADDRS_LO  = LS_ADDRS_LO;
    rval_t  [LS_UNITS-1:0]  param_LS_ADDRS_HI  = LS_ADDRS_HI;


    // ---------------------------------------------------------
    //  JFive Core
    // ---------------------------------------------------------

    id_t                        ibus_cmd_id     ;
    phase_t                     ibus_cmd_phase  ;
    pc_t                        ibus_cmd_pc     ;
    logic                       ibus_cmd_valid  ;
    logic                       ibus_cmd_ready  ;
    id_t                        ibus_res_id     ;
    phase_t                     ibus_res_phase  ;
    pc_t                        ibus_res_pc     ;
    instr_t                     ibus_res_instr  ;
    logic                       ibus_res_valid  ;
    logic                       ibus_res_ready  ;

    dbus_addr_t [LS_UNITS-1:0]  dbus_aaddr  ;
    logic       [LS_UNITS-1:0]  dbus_awrite ;
    logic       [LS_UNITS-1:0]  dbus_aread  ;
    logic       [LS_UNITS-1:0]  dbus_avalid ;
    logic       [LS_UNITS-1:0]  dbus_aready ;
    dbus_strb_t [LS_UNITS-1:0]  dbus_wstrb  ;
    dbus_data_t [LS_UNITS-1:0]  dbus_wdata  ;
    logic       [LS_UNITS-1:0]  dbus_wvalid ;
    logic       [LS_UNITS-1:0]  dbus_wready ;
    dbus_data_t [LS_UNITS-1:0]  dbus_rdata  ;
    logic       [LS_UNITS-1:0]  dbus_rvalid ;
    logic       [LS_UNITS-1:0]  dbus_rready ;

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
                .DBUS_ADDR_BITS     (DBUS_ADDR_BITS ),
                .dbus_addr_t        (dbus_addr_t    ),
                .DBUS_DATA_BITS     (DBUS_DATA_BITS ),
                .dbus_data_t        (dbus_data_t    ),
                .DBUS_STRB_BITS     (DBUS_STRB_BITS ),
                .dbus_strb_t        (dbus_strb_t    ),
                .LS_UNITS           (LS_UNITS       ),
                .LS_ADDRS_LO        (LS_ADDRS_LO    ),
                .LS_ADDRS_HI        (LS_ADDRS_HI    ),
                .LOAD_QUES          (LOAD_QUES      ),
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
                .ibus_cmd_ready     ,
                .ibus_res_id        ,
                .ibus_res_phase     ,
                .ibus_res_pc        ,
                .ibus_res_instr     ,
                .ibus_res_valid     ,
                .ibus_res_ready     ,

                .dbus_aaddr         ,
                .dbus_awrite        ,
                .dbus_aread         ,
                .dbus_avalid        ,
                .dbus_aready        ,
                .dbus_wstrb         ,
                .dbus_wdata         ,
                .dbus_wvalid        ,
                .dbus_wready        ,
                .dbus_rdata         ,
                .dbus_rvalid        ,
                .dbus_rready         
            );


    // ---------------------------------------------------------
    //  Tightly-Coupled Memory
    // ---------------------------------------------------------

    localparam  int     TCM_WE_BITS    = $bits(tcm_data_t) / 8;
    localparam  type    tcm_we_t       = logic  [TCM_WE_BITS-1:0]   ;

    logic           tcm_port0_cke   ;
    tcm_we_t        tcm_port0_we    ;
    tcm_addr_t      tcm_port0_addr  ;
    tcm_data_t      tcm_port0_din   ;
    tcm_data_t      tcm_port0_dout  ;

    logic           tcm_port1_cke   ;
    tcm_we_t        tcm_port1_we    ;
    tcm_addr_t      tcm_port1_addr  ;
    tcm_data_t      tcm_port1_din   ;
    tcm_data_t      tcm_port1_dout  ;

    jelly2_ram_dualport
            #(
                .ADDR_WIDTH     ($bits(tcm_addr_t)  ),
                .DATA_WIDTH     (32                 ),
                .WE_WIDTH       (4                  ),
                .WORD_WIDTH     (8                  ),
                .RAM_TYPE       (TCM_RAM_TYPE       ),
                .DOUT_REGS0     (1                  ),
                .DOUT_REGS1     (1                  ),
                .MODE0          ("NO_CHANGE"        ),
                .MODE1          ("NO_CHANGE"        ),
                .FILLMEM        (0                  ),
                .FILLMEM_DATA   (0                  ),
                .READMEMB       (TCM_READMEMB       ),
                .READMEMH       (TCM_READMEMH       ),
                .READMEM_FIlE   (TCM_READMEM_FIlE   )
            )
        u_ram_dualport
            (
                .port0_clk      (clk                ),
                .port0_en       (tcm_port0_cke      ),
                .port0_regcke   (tcm_port0_cke      ),
                .port0_we       (tcm_port0_we       ),
                .port0_addr     (tcm_port0_addr     ),
                .port0_din      (tcm_port0_din      ),
                .port0_dout     (tcm_port0_dout     ),

                .port1_clk      (clk                ),
                .port1_en       (tcm_port1_cke      ),
                .port1_regcke   (tcm_port1_cke      ),
                .port1_we       (tcm_port1_we       ),
                .port1_addr     (tcm_port1_addr     ),
                .port1_din      (tcm_port1_din      ),
                .port1_dout     (tcm_port1_dout     )
            );
    
    assign tcm_port0_cke  = cke & ibus_res_ready;
    assign tcm_port0_we   = '0;
    assign tcm_port0_addr = tcm_addr_t'(ibus_cmd_pc >> 2);
    assign tcm_port0_din  = '0;
    
    id_t    tcm_ibus_st0_id     ;
    phase_t tcm_ibus_st0_phase  ;
    pc_t    tcm_ibus_st0_pc     ;
    logic   tcm_ibus_st0_valid  ;
    id_t    tcm_ibus_st1_id     ;
    phase_t tcm_ibus_st1_phase  ;
    pc_t    tcm_ibus_st1_pc     ;
    logic   tcm_ibus_st1_valid  ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            tcm_ibus_st0_id     <= 'x;
            tcm_ibus_st0_phase  <= 'x;
            tcm_ibus_st0_pc     <= 'x;
            tcm_ibus_st0_valid  <= 1'b0;
            tcm_ibus_st1_id     <= 'x;
            tcm_ibus_st1_phase  <= 'x;
            tcm_ibus_st1_pc     <= 'x;
            tcm_ibus_st1_valid  <= 1'b0;
        end
        else if ( cke && ibus_res_ready ) begin
            tcm_ibus_st0_id     <= ibus_cmd_id;
            tcm_ibus_st0_phase  <= ibus_cmd_phase;
            tcm_ibus_st0_pc     <= ibus_cmd_pc;
            tcm_ibus_st0_valid  <= ibus_cmd_valid;
            tcm_ibus_st1_id     <= tcm_ibus_st0_id;
            tcm_ibus_st1_phase  <= tcm_ibus_st0_phase;
            tcm_ibus_st1_pc     <= tcm_ibus_st0_pc;
            tcm_ibus_st1_valid  <= tcm_ibus_st0_valid;
        end
    end

    assign ibus_cmd_ready  = ibus_res_ready   ;

    assign ibus_res_id    = tcm_ibus_st1_id     ;
    assign ibus_res_phase = tcm_ibus_st1_phase  ;
    assign ibus_res_pc    = tcm_ibus_st1_pc     ;
    assign ibus_res_instr = tcm_port0_dout      ;
    assign ibus_res_valid = tcm_ibus_st1_valid  ;


    // dbus
    localparam DBUS_MEM = 0;
    assign tcm_port1_cke  = cke && dbus_aready[DBUS_MEM]        ;
    assign tcm_port1_addr = tcm_addr_t'(dbus_aaddr[DBUS_MEM])   ;
    assign tcm_port1_we   = dbus_wstrb[DBUS_MEM]                ;
    assign tcm_port1_din  = dbus_wdata[DBUS_MEM]                ;

    logic   tcm_dbus_st0_valid  ;
    logic   tcm_dbus_st1_valid  ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            tcm_dbus_st0_valid  <= 1'b0;
            tcm_dbus_st1_valid  <= 1'b0;
        end
        else if ( cke && dbus_rready[DBUS_MEM] ) begin
            tcm_dbus_st0_valid  <= dbus_aread[DBUS_MEM];
            tcm_dbus_st1_valid  <= tcm_dbus_st0_valid;
        end
    end

    assign dbus_aready[DBUS_MEM] = !dbus_rvalid[DBUS_MEM] || dbus_rready[DBUS_MEM]  ;
    assign dbus_wready[DBUS_MEM] = !dbus_rvalid[DBUS_MEM] || dbus_rready[DBUS_MEM]  ;

    assign dbus_rdata [DBUS_MEM] = tcm_port1_dout            ;
    assign dbus_rvalid[DBUS_MEM] = tcm_dbus_st1_valid        ;

 

    // ---------------------------------------------------------
    //  Peripheral BUS
    // ---------------------------------------------------------

//  localparam DBUS_PERI = 1;
//  assign monitor = dbus_cmd_wdata[DBUS_PERI];
//  assign dbus_cmd_ready[DBUS_PERI] = !dbus_res_valid[DBUS_PERI] || dbus_res_ready[DBUS_PERI]  ;
//  assign dbus_res_rdata[DBUS_PERI] = 'x  ;
//  assign dbus_res_valid[DBUS_PERI] = dbus_cmd_valid[DBUS_PERI] && !dbus_cmd_wr[DBUS_PERI];

    localparam DBUS_AXI4L = 1;
    for ( genvar i = 0; i < M_AXI4L_PORTS ; i++ ) begin
        assign m_axi4l[i].awaddr  = dbus_aaddr [DBUS_AXI4L+i];
        assign m_axi4l[i].awprot  = '0;
        assign m_axi4l[i].awvalid = dbus_awrite[DBUS_AXI4L+i];
        assign m_axi4l[i].wdata   = dbus_wdata[DBUS_AXI4L+i];
        assign m_axi4l[i].wstrb   = dbus_wstrb[DBUS_AXI4L+i];
        assign m_axi4l[i].wvalid  = dbus_wvalid[DBUS_AXI4L+i];

        assign m_axi4l[i].araddr  = dbus_aaddr [DBUS_AXI4L+i];
        assign m_axi4l[i].arprot  = '0;
        assign m_axi4l[i].arvalid = dbus_aread[DBUS_AXI4L+i];

        assign dbus_aready[DBUS_AXI4L+i] = m_axi4l[i].awvalid ? m_axi4l[i].awready : m_axi4l[i].arready;
        assign dbus_wready[DBUS_AXI4L+i] = m_axi4l[i].wready;

        assign dbus_rdata[DBUS_AXI4L+i]  = m_axi4l[i].rdata ;
        assign dbus_rvalid[DBUS_AXI4L+i] = m_axi4l[i].rvalid;
        assign m_axi4l[i].rready = dbus_rready[DBUS_AXI4L+i];
    end

endmodule


`default_nettype wire


// end of file
