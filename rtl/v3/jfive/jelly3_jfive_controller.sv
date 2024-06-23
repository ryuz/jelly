
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
            localparam  type                        m_axi4l_data_t    = logic   [M_AXI4L_ADDR_BITS-1:0]     ,
            parameter   rval_t  [M_AXI4L_PORTS-1:0] M_AXI4L_ADDRS_LO  = '{32'h8000_0000}                    ,
            parameter   rval_t  [M_AXI4L_PORTS-1:0] M_AXI4L_ADDRS_HI  = '{32'hffff_ffff}                    ,
            parameter   bit     [THREADS-1:0]       INIT_RUN          = 1                                   ,
            parameter   id_t                        INIT_ID           = '0                                  ,
            parameter   pc_t    [THREADS-1:0]       INIT_PC           = '0                                  ,
            parameter                               CORE_ID           = 32'h527a_ffff                       ,
            parameter                               CORE_VERSION      = 32'h0001_0000                       ,
            parameter   bit     [0:0]               INIT_CTL_CONTROL  = 1'b0                                ,
            parameter                               DEVICE            = "RTL"                               ,
            parameter                               SIMULATION        = "false"                             ,
            parameter                               DEBUG             = "false"                            
        )
        (
            input   var logic           reset                           ,
            input   var logic           clk                             ,
            input   var logic           cke                             ,

            jelly3_axi4l_if.s           s_axi4l_ctl                     ,
            jelly3_axi4l_if.s           s_axi4l_mem                     ,
            jelly3_axi4l_if.m           m_axi4l_ext [0:M_AXI4L_PORTS-1] 
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


    // ---------------------------------------------------------
    //  Control from host
    // ---------------------------------------------------------
    
    localparam  type regadr_t     = logic [4:0];
    localparam  type axi4l_data_t = logic [s_axi4l_ctl.DATA_BITS-1:0];
   
    // register address offset
    localparam  regadr_t REGADR_CORE_ID            = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION       = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_CONTROL        = regadr_t'('h04);
    localparam  regadr_t REGADR_CTL_STATUS         = regadr_t'('h05);
    localparam  regadr_t REGADR_CTL_INDEX          = regadr_t'('h07);
    localparam  regadr_t REGADR_CTL_SKIP           = regadr_t'('h08);
    localparam  regadr_t REGADR_CTL_FRM_TIMER_EN   = regadr_t'('h0a);
    localparam  regadr_t REGADR_CTL_FRM_TIMEOUT    = regadr_t'('h0b);
    localparam  regadr_t REGADR_PARAM_WIDTH        = regadr_t'('h10);
    localparam  regadr_t REGADR_PARAM_HEIGHT       = regadr_t'('h11);
    localparam  regadr_t REGADR_PARAM_FILL         = regadr_t'('h12);
    localparam  regadr_t REGADR_PARAM_TIMEOUT      = regadr_t'('h13);

    
    // registers
    logic   [0:0]   reg_ctl_control;

    function [s_axi4l_ctl.DATA_BITS-1:0] write_mask(
                                        input [s_axi4l_ctl.DATA_BITS-1:0] org,
                                        input [s_axi4l_ctl.DATA_BITS-1:0] data,
                                        input [s_axi4l_ctl.STRB_BITS-1:0] strb
                                    );
        for ( int i = 0; i < s_axi4l_ctl.DATA_BITS; i++ ) begin
            write_mask[i] = strb[i/8] ? data[i] : org[i];
        end
    endfunction

    regadr_t  regadr_write;
    regadr_t  regadr_read;
    assign regadr_write = regadr_t'(s_axi4l_ctl.awaddr / s_axi4l_ctl.ADDR_BITS'(s_axi4l_ctl.STRB_BITS));
    assign regadr_read  = regadr_t'(s_axi4l_ctl.araddr / s_axi4l_ctl.ADDR_BITS'(s_axi4l_ctl.STRB_BITS));

    always_ff @(posedge s_axi4l_ctl.aclk) begin
        if ( ~s_axi4l_ctl.aresetn ) begin
            reg_ctl_control      <= INIT_CTL_CONTROL;
        end
        else begin
            if ( s_axi4l_ctl.awvalid && s_axi4l_ctl.awready && s_axi4l_ctl.wvalid && s_axi4l_ctl.wready ) begin
                case ( regadr_write )
                REGADR_CTL_CONTROL: reg_ctl_control <= 1'(write_mask(axi4l_data_t'(reg_ctl_control), s_axi4l_ctl.wdata, s_axi4l_ctl.wstrb));
                default: ;
                endcase
            end
        end
    end

    always_ff @(posedge s_axi4l_ctl.aclk ) begin
        if ( ~s_axi4l_ctl.aresetn ) begin
            s_axi4l_ctl.bvalid <= 0;
        end
        else begin
            if ( s_axi4l_ctl.bready ) begin
                s_axi4l_ctl.bvalid <= 0;
            end
            if ( s_axi4l_ctl.awvalid && s_axi4l_ctl.awready ) begin
                s_axi4l_ctl.bvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l_ctl.awready = (~s_axi4l_ctl.bvalid || s_axi4l_ctl.bready) && s_axi4l_ctl.wvalid;
    assign s_axi4l_ctl.wready  = (~s_axi4l_ctl.bvalid || s_axi4l_ctl.bready) && s_axi4l_ctl.awvalid;
    assign s_axi4l_ctl.bresp   = '0;


    // read
    always_ff @(posedge s_axi4l_ctl.aclk ) begin
        if ( s_axi4l_ctl.arvalid && s_axi4l_ctl.arready ) begin
            case ( regadr_read )
            REGADR_CORE_ID:            s_axi4l_ctl.rdata <= axi4l_data_t'(CORE_ID             );
            REGADR_CORE_VERSION:       s_axi4l_ctl.rdata <= axi4l_data_t'(CORE_VERSION        );
            REGADR_CTL_CONTROL:        s_axi4l_ctl.rdata <= axi4l_data_t'(reg_ctl_control     );
            REGADR_CTL_STATUS:         s_axi4l_ctl.rdata <= axi4l_data_t'(reg_ctl_control     );
            default: ;
            endcase
        end
    end

    logic           axi4l_rvalid;
    always_ff @(posedge s_axi4l_ctl.aclk ) begin
        if ( ~s_axi4l_ctl.aresetn ) begin
            s_axi4l_ctl.rvalid <= 1'b0;
        end
        else begin
            if ( s_axi4l_ctl.rready ) begin
                s_axi4l_ctl.rvalid <= 1'b0;
            end
            if ( s_axi4l_ctl.arvalid && s_axi4l_ctl.arready ) begin
                s_axi4l_ctl.rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l_ctl.arready = ~s_axi4l_ctl.rvalid || s_axi4l_ctl.rready;
    assign s_axi4l_ctl.rresp   = '0;


    // ---------------------------------------------------------
    //  Memory access from host
    // ---------------------------------------------------------

    logic   [31:0]  host_addr    ;
    logic   [3:0]   host_we      ;
    logic   [31:0]  host_wdata   ;
    logic           host_valid   ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            host_addr   <= 'x;
            host_we     <= '0;
            host_wdata  <= 'x;
            host_valid  <= 1'b0;
        end
        else if ( cke ) begin
            host_we <= '0;
            if ( host_valid ) begin
                if ( s_axi4l_mem.bready ) begin
                    host_valid <= 1'b0;
                end
            end
            else begin
                if ( s_axi4l_mem.awvalid && s_axi4l_mem.awready ) begin
                    host_addr  <= s_axi4l_mem.awaddr;
                end
                if ( s_axi4l_mem.wvalid && s_axi4l_mem.wready ) begin
                    host_we    <= s_axi4l_mem.wstrb;
                    host_wdata <= s_axi4l_mem.wdata;
                    host_valid <= 1'b1;
                end
            end
        end
    end
    
    assign s_axi4l_mem.awready = !host_valid && s_axi4l_mem.wvalid;
    assign s_axi4l_mem.wready  = !host_valid && s_axi4l_mem.awvalid;
    assign s_axi4l_mem.bresp   = 2'b0;
    assign s_axi4l_mem.bvalid  = host_valid;



    // ---------------------------------------------------------
    //  JFive Core
    // ---------------------------------------------------------

    id_t                        ibus_aid    ;
    phase_t                     ibus_aphase ;
    pc_t                        ibus_apc    ;
    logic                       ibus_avalid ;
    logic                       ibus_aready ;
    id_t                        ibus_rid    ;
    phase_t                     ibus_rphase ;
    pc_t                        ibus_rpc    ;
    instr_t                     ibus_rinstr ;
    logic                       ibus_rvalid ;
    logic                       ibus_rready ;

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
                .XLEN               (XLEN               ),
                .THREADS            (THREADS            ),
                .ID_BITS            (ID_BITS            ),
                .id_t               (id_t               ),
                .PHASE_BITS         (PHASE_BITS         ),
                .phase_t            (phase_t            ),
                .PC_BITS            (PC_BITS            ),
                .pc_t               (pc_t               ),
                .PC_MASK            (PC_MASK            ),
                .INSTR_BITS         (INSTR_BITS         ),
                .instr_t            (instr_t            ),
                .DBUS_ADDR_BITS     (DBUS_ADDR_BITS     ),
                .dbus_addr_t        (dbus_addr_t        ),
                .DBUS_DATA_BITS     (DBUS_DATA_BITS     ),
                .dbus_data_t        (dbus_data_t        ),
                .DBUS_STRB_BITS     (DBUS_STRB_BITS     ),
                .dbus_strb_t        (dbus_strb_t        ),
                .LS_UNITS           (LS_UNITS           ),
                .LS_ADDRS_LO        (LS_ADDRS_LO        ),
                .LS_ADDRS_HI        (LS_ADDRS_HI        ),
                .LOAD_QUES          (LOAD_QUES          ),
                .INIT_RUN           (INIT_RUN           ),
                .INIT_ID            (INIT_ID            ),
                .INIT_PC            (INIT_PC            ),
                .DEVICE             (DEVICE             ),
                .SIMULATION         (SIMULATION         ),
                .DEBUG              (DEBUG              )
            )
        u_jfive_core
            (
                .reset              (~reg_ctl_control   ),
                .clk                ,
                .cke                ,

                .ibus_aid           ,
                .ibus_aphase        ,
                .ibus_apc           ,
                .ibus_avalid        ,
                .ibus_aready        ,
                .ibus_rid           ,
                .ibus_rphase        ,
                .ibus_rpc           ,
                .ibus_rinstr        ,
                .ibus_rvalid        ,
                .ibus_rready        ,

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
    
    assign tcm_port0_cke  = cke & ibus_rready;
    assign tcm_port0_we   = host_we;
    assign tcm_port0_addr = host_valid ? tcm_addr_t'(host_addr >> 2) : tcm_addr_t'(ibus_apc >> 2);
    assign tcm_port0_din  = host_wdata;
    
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
        else if ( cke && ibus_aready ) begin
            tcm_ibus_st0_id     <= ibus_aid;
            tcm_ibus_st0_phase  <= ibus_aphase;
            tcm_ibus_st0_pc     <= ibus_apc;
            tcm_ibus_st0_valid  <= ibus_avalid;
            tcm_ibus_st1_id     <= tcm_ibus_st0_id;
            tcm_ibus_st1_phase  <= tcm_ibus_st0_phase;
            tcm_ibus_st1_pc     <= tcm_ibus_st0_pc;
            tcm_ibus_st1_valid  <= tcm_ibus_st0_valid;
        end
    end

    assign ibus_aready    = !ibus_rvalid || ibus_rready ;

    assign ibus_rid    = tcm_ibus_st1_id    ;
    assign ibus_rphase = tcm_ibus_st1_phase ;
    assign ibus_rpc    = tcm_ibus_st1_pc    ;
    assign ibus_rinstr = tcm_port0_dout     ;
    assign ibus_rvalid = tcm_ibus_st1_valid ;


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

    localparam DBUS_AXI4L = 1;
    for ( genvar i = 0; i < M_AXI4L_PORTS ; i++ ) begin
        assign m_axi4l_ext[i].awaddr  = dbus_aaddr [DBUS_AXI4L+i] << 2;
        assign m_axi4l_ext[i].awprot  = '0;
        assign m_axi4l_ext[i].awvalid = dbus_awrite[DBUS_AXI4L+i];

        assign m_axi4l_ext[i].wdata   = dbus_wdata[DBUS_AXI4L+i];
        assign m_axi4l_ext[i].wstrb   = dbus_wstrb[DBUS_AXI4L+i];
        assign m_axi4l_ext[i].wvalid  = dbus_wvalid[DBUS_AXI4L+i];

        assign m_axi4l_ext[i].bready  = 1'b1;

        assign m_axi4l_ext[i].araddr  = dbus_aaddr [DBUS_AXI4L+i] << 2;
        assign m_axi4l_ext[i].arprot  = '0;
        assign m_axi4l_ext[i].arvalid = dbus_aread[DBUS_AXI4L+i];

        assign dbus_aready[DBUS_AXI4L+i] = m_axi4l_ext[i].awvalid ? m_axi4l_ext[i].awready : m_axi4l_ext[i].arready;
        assign dbus_wready[DBUS_AXI4L+i] = m_axi4l_ext[i].wready;

        assign dbus_rdata[DBUS_AXI4L+i]  = m_axi4l_ext[i].rdata ;
        assign dbus_rvalid[DBUS_AXI4L+i] = m_axi4l_ext[i].rvalid;
        assign m_axi4l_ext[i].rready = dbus_rready[DBUS_AXI4L+i];
    end

endmodule


`default_nettype wire


// end of file
