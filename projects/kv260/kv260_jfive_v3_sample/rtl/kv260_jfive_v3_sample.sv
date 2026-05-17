

`timescale 1ns / 1ps
`default_nettype none

module kv260_jfive_v3_sample
        #(
            parameter   DEVICE            = "ULTRASCALE_PLUS"   ,
            parameter   SIMULATION        = "false"             ,
            parameter   DEBUG             = "true"             
        )
        (
            output  var logic           fan_en  ,
            output  var logic   [7:0]   pmod
        );
    
    // ---------------------------------
    //  PS
    // ---------------------------------

    logic   reset           ;
    logic   clk             ;
    logic   axi4l_aresetn   ;
    logic   axi4l_aclk      ;
    logic   axi4_aresetn    ;
    logic   axi4_aclk       ;

    jelly3_axi4l_if
            #(
                .ADDR_BITS      (40             ),
                .DATA_BITS      (32             )
            )
        axi4l_ctl
            (
                .aresetn        (axi4l_aresetn  ),
                .aclk           (axi4l_aclk     ),
                .aclken         (1'b1           )
            );

    jelly3_axi4_if
            #(
                .ID_BITS        (16             ),
                .ADDR_BITS      (40             ),
                .DATA_BITS      (32             )
            )
        axi4_mem
            (
                .aresetn        (axi4_aresetn   ),
                .aclk           (axi4_aclk      ),
                .aclken         (1'b1           )
            );

    design_1
        u_design_1
            (
                .fan_en             (fan_en             ),

                .core_reset         (reset              ),
                .core_clk           (clk                ),

                .m_axi4l_aresetn    (axi4l_aresetn      ),
                .m_axi4l_aclk       (axi4l_aclk         ),
                .m_axi4l_awaddr     (axi4l_ctl.awaddr   ),
                .m_axi4l_awprot     (axi4l_ctl.awprot   ),
                .m_axi4l_awvalid    (axi4l_ctl.awvalid  ),
                .m_axi4l_awready    (axi4l_ctl.awready  ),
                .m_axi4l_wdata      (axi4l_ctl.wdata    ),
                .m_axi4l_wstrb      (axi4l_ctl.wstrb    ),
                .m_axi4l_wvalid     (axi4l_ctl.wvalid   ),
                .m_axi4l_wready     (axi4l_ctl.wready   ),
                .m_axi4l_bresp      (axi4l_ctl.bresp    ),
                .m_axi4l_bvalid     (axi4l_ctl.bvalid   ),
                .m_axi4l_bready     (axi4l_ctl.bready   ),
                .m_axi4l_araddr     (axi4l_ctl.araddr   ),
                .m_axi4l_arprot     (axi4l_ctl.arprot   ),
                .m_axi4l_arvalid    (axi4l_ctl.arvalid  ),
                .m_axi4l_arready    (axi4l_ctl.arready  ),
                .m_axi4l_rdata      (axi4l_ctl.rdata    ),
                .m_axi4l_rresp      (axi4l_ctl.rresp    ),
                .m_axi4l_rvalid     (axi4l_ctl.rvalid   ),
                .m_axi4l_rready     (axi4l_ctl.rready   ),

                .m_axi4_aresetn     (axi4_aresetn       ),
                .m_axi4_aclk        (axi4_aclk          ),
                .m_axi4_awid        (axi4_mem.awid      ),
                .m_axi4_awaddr      (axi4_mem.awaddr    ),
                .m_axi4_awlen       (axi4_mem.awlen     ),
                .m_axi4_awsize      (axi4_mem.awsize    ),
                .m_axi4_awburst     (axi4_mem.awburst   ),
                .m_axi4_awlock      (axi4_mem.awlock    ),
                .m_axi4_awcache     (axi4_mem.awcache   ),
                .m_axi4_awprot      (axi4_mem.awprot    ),
                .m_axi4_awqos       (axi4_mem.awqos     ),
                .m_axi4_awregion    (axi4_mem.awregion  ),
//              .m_axi4_awuser      (axi4_mem.awuser    ),
                .m_axi4_awvalid     (axi4_mem.awvalid   ),
                .m_axi4_awready     (axi4_mem.awready   ),
                .m_axi4_wdata       (axi4_mem.wdata     ),
                .m_axi4_wstrb       (axi4_mem.wstrb     ),
                .m_axi4_wlast       (axi4_mem.wlast     ),
//              .m_axi4_wuser       (axi4_mem.wuser     ),
                .m_axi4_wvalid      (axi4_mem.wvalid    ),
                .m_axi4_wready      (axi4_mem.wready    ),
                .m_axi4_bid         (axi4_mem.bid       ),
                .m_axi4_bresp       (axi4_mem.bresp     ),
//              .m_axi4_buser       (axi4_mem.buser     ),
                .m_axi4_bvalid      (axi4_mem.bvalid    ),
                .m_axi4_bready      (axi4_mem.bready    ),
                .m_axi4_arid        (axi4_mem.arid      ),
                .m_axi4_araddr      (axi4_mem.araddr    ),
                .m_axi4_arlen       (axi4_mem.arlen     ),
                .m_axi4_arsize      (axi4_mem.arsize    ),
                .m_axi4_arburst     (axi4_mem.arburst   ),
                .m_axi4_arlock      (axi4_mem.arlock    ),
                .m_axi4_arcache     (axi4_mem.arcache   ),
                .m_axi4_arprot      (axi4_mem.arprot    ),
                .m_axi4_arqos       (axi4_mem.arqos     ),
                .m_axi4_arregion    (axi4_mem.arregion  ),
//              .m_axi4_aruser      (axi4_mem.aruser    ),
                .m_axi4_arvalid     (axi4_mem.arvalid   ),
                .m_axi4_arready     (axi4_mem.arready   ),
                .m_axi4_rid         (axi4_mem.rid       ),
                .m_axi4_rdata       (axi4_mem.rdata     ),
                .m_axi4_rresp       (axi4_mem.rresp     ),
                .m_axi4_rlast       (axi4_mem.rlast     ),
//              .m_axi4_ruser       (axi4_mem.ruser     ),
                .m_axi4_rvalid      (axi4_mem.rvalid    ),
                .m_axi4_rready      (axi4_mem.rready    )
            );


    // ---------------------------------
    //  JFive Core
    // ---------------------------------

    localparam  bit                         S_AXI4L_CLT_ASYNC = 1'b1                                ;
    localparam  bit                         S_AXI4_MEM_ASYNC  = 1'b1                                ;
    localparam  int                         XLEN              = 32                                  ;
//  localparam  int                         THREADS           = 1                                   ;
    localparam  int                         THREADS           = 4                                   ;
//  localparam  int                         THREADS           = 8                                   ;
    localparam  int                         ID_BITS           = THREADS > 1 ? $clog2(THREADS) : 1   ;
    localparam  type                        id_t              = logic         [ID_BITS-1:0]         ;
    localparam  int                         PC_BITS           = 32                                  ;
    localparam  type                        pc_t              = logic         [PC_BITS-1:0]         ;
    localparam  pc_t                        PC_MASK           = '0                                  ;
    localparam  type                        rval_t            = logic signed  [XLEN-1:0]            ;
    localparam  int                         LOAD_QUES         = 2                                   ;
    localparam  int                         TCM_MEM_SIZE      = 64 * 1024                           ;
    localparam  rval_t                      TCM_ADDR_LO       = 32'h0000_0000                       ;
    localparam  rval_t                      TCM_ADDR_HI       = 32'h7fff_ffff                       ;
    localparam                              TCM_RAM_TYPE      = "block"                             ;
    localparam                              TCM_RAM_MODE      = "NO_CHANGE"                         ;
    localparam  bit                         TCM_FILLMEM       = 1                                   ;
    localparam  logic   [31:0]              TCM_FILLMEM_DATA  = '0                                  ;
    localparam  bit                         TCM_READMEMB      = 1'b0                                ;
    localparam  bit                         TCM_READMEMH      = 1'b1                                ;
    localparam                              TCM_READMEM_FIlE  = "../../../jfive/jfive_mem.hex"      ;
    localparam  int                         M_AXI4L_PORTS     = 2                                   ;
    localparam  int                         M_AXI4L_ADDR_BITS = 32                                  ;
    localparam  type                        m_axi4l_data_t    = logic   [M_AXI4L_ADDR_BITS-1:0]     ;
    localparam  rval_t  [M_AXI4L_PORTS-1:0] M_AXI4L_ADDRS_LO  = '{32'hc000_0000, 32'h8000_0000}     ;
    localparam  rval_t  [M_AXI4L_PORTS-1:0] M_AXI4L_ADDRS_HI  = '{32'hffff_ffff, 32'hbfff_ffff}     ;
    localparam  bit     [THREADS-1:0]       INIT_RUN          = THREADS'((1 << THREADS)-1)          ;
    localparam  id_t                        INIT_ID           = '0                                  ;
//  localparam  pc_t    [THREADS-1:0]       INIT_PC           = '{32'h00}                           ; // THREADS = 1
    localparam  pc_t    [THREADS-1:0]       INIT_PC           = '{32'h0c, 32'h08, 32'h04, 32'h00}   ; // THREADS = 4
//  localparam  pc_t    [THREADS-1:0]       INIT_PC           = '{32'h1c, 32'h18, 32'h14, 32'h10, 32'h0c, 32'h08, 32'h04, 32'h00}; // THREADS = 8

    jelly3_axi4l_if
            #(
                .ADDR_BITS          (32         ),
                .DATA_BITS          (32         )
            )
        axi4l_jfive [2]
            (
                .aresetn            (~reset     ),
                .aclk               (clk        ),
                .aclken             (1'b1       )
            );

    jelly3_jfive_controller
            #(
                .XLEN               (XLEN               ),
                .THREADS            (THREADS            ),
                .PC_MASK            (PC_MASK            ),
                .LOAD_QUES          (LOAD_QUES          ),
                .TCM_MEM_SIZE       (TCM_MEM_SIZE       ),
                .TCM_ADDR_LO        (TCM_ADDR_LO        ),
                .TCM_ADDR_HI        (TCM_ADDR_HI        ),
                .TCM_RAM_TYPE       (TCM_RAM_TYPE       ),
                .TCM_RAM_MODE       (TCM_RAM_MODE       ),
                .TCM_FILLMEM        (TCM_FILLMEM        ),
                .TCM_FILLMEM_DATA   (TCM_FILLMEM_DATA   ),
                .TCM_READMEMB       (TCM_READMEMB       ),
                .TCM_READMEMH       (TCM_READMEMH       ),
                .TCM_READMEM_FIlE   (TCM_READMEM_FIlE   ),
                .M_AXI4L_PORTS      (M_AXI4L_PORTS      ),
                .M_AXI4L_ADDR_BITS  (M_AXI4L_ADDR_BITS  ),
                .M_AXI4L_ADDRS_LO   (M_AXI4L_ADDRS_LO   ),
                .M_AXI4L_ADDRS_HI   (M_AXI4L_ADDRS_HI   ),
                .INIT_RUN           (INIT_RUN           ),
                .INIT_ID            (INIT_ID            ),
                .INIT_PC            (INIT_PC            ),
                .DEVICE             (DEVICE             ),
                .SIMULATION         (SIMULATION         ),
                .DEBUG              (DEBUG              )
            )
        u_jfive_controller
            (
                .reset              (reset              ),
                .clk                (clk                ),
                .cke                (1'b1               ),

                .s_axi4l_ctl        (axi4l_ctl          ),
                .s_axi4_mem         (axi4_mem           ),
                .m_axi4l_ext        (axi4l_jfive        )
            );


    // ---------------------------------
    //  PMOD
    // ---------------------------------

    jelly3_uart
            #(
                .ASYNC              (0                      ),
                .TX_FIFO_PTR_BITS   (4                      ),
                .RX_FIFO_PTR_BITS   (4                      ),
                .RAM_TYPE           ("distributed"          ),
                .DIVIDER_BITS       (16                     ),
                .INIT_DIVIDER       (16'(434-1)             ),  // 115200bps@400MHz
                .DEVICE             (DEVICE                 ),
                .SIMULATION         (SIMULATION             ),
                .DEBUG              (DEBUG                  )
            )
        u_uart
            (
                .uart_reset         (~axi4l_jfive[0].aresetn),
                .uart_clk           (axi4l_jfive[0].aclk    ),
                .uart_tx            (pmod[5]                ),
                .uart_rx            (pmod[6]                ),

                .s_axi4l            (axi4l_jfive[0]         ),
                .irq_rx             (                       ),
                .irq_tx             (                       )
            );
    

    jelly3_axi4l_register
            #(
                .NUM                (4                      ),
                .BITS               (1                      ),
                .INIT               ('0                     )
            )
        u_axi4l_register
            (
                .s_axi4l            (axi4l_jfive[1]         ),
                .value              (pmod[3:0]              )
            );

    /*
    logic   [27:0]    counter;
    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 28'h0;
        end else begin
            counter <= counter + 28'h1;
        end
    end
    assign pmod[7:4] = counter[27:24];
    */

endmodule

`default_nettype wire

// end of file
