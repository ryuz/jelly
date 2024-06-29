

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

    logic   reset;
    logic   clk;

    jelly3_axi4l_if
            #(
                .ADDR_BITS          (40          ),
                .DATA_BITS          (32          )
            )
        axi4l_peri
            (
                .aresetn            (~reset     ),
                .aclk               (clk        ),
                .aclken             (1'b1       )
            );

    design_1
        u_design_1
            (
                .fan_en             (fan_en             ),

                .out_reset          (reset              ),
                .out_clk            (clk                ),

                .m_axi4l_awaddr     (axi4l_peri.awaddr  ),
                .m_axi4l_awprot     (axi4l_peri.awprot  ),
                .m_axi4l_awvalid    (axi4l_peri.awvalid ),
                .m_axi4l_awready    (axi4l_peri.awready ),
                .m_axi4l_wdata      (axi4l_peri.wdata   ),
                .m_axi4l_wstrb      (axi4l_peri.wstrb   ),
                .m_axi4l_wvalid     (axi4l_peri.wvalid  ),
                .m_axi4l_wready     (axi4l_peri.wready  ),
                .m_axi4l_bresp      (axi4l_peri.bresp   ),
                .m_axi4l_bvalid     (axi4l_peri.bvalid  ),
                .m_axi4l_bready     (axi4l_peri.bready  ),
                .m_axi4l_araddr     (axi4l_peri.araddr  ),
                .m_axi4l_arprot     (axi4l_peri.arprot  ),
                .m_axi4l_arvalid    (axi4l_peri.arvalid ),
                .m_axi4l_arready    (axi4l_peri.arready ),
                .m_axi4l_rdata      (axi4l_peri.rdata   ),
                .m_axi4l_rresp      (axi4l_peri.rresp   ),
                .m_axi4l_rvalid     (axi4l_peri.rvalid  ),
                .m_axi4l_rready     (axi4l_peri.rready  )
            );

    // ----------------------------------------
    //  Address decoder
    // ----------------------------------------

    localparam DEC_CTL  = 0;
    localparam DEC_MEM  = 1;
    localparam DEC_NUM  = 2;

    jelly3_axi4l_if
            #(
                .ADDR_BITS      (40     ),
                .DATA_BITS      (32     )
            )
        axi4l_dec [DEC_NUM]
            (
                .aresetn        (~reset ),
                .aclk           (clk    ),
                .aclken         (1'b1   )
            );
    
    // address map
    assign {axi4l_dec[DEC_CTL].addr_base, axi4l_dec[DEC_CTL].addr_high} = {40'ha000_0000, 40'ha000_ffff};
    assign {axi4l_dec[DEC_MEM].addr_base, axi4l_dec[DEC_MEM].addr_high} = {40'ha010_0000, 40'ha01f_ffff};

    jelly3_axi4l_addr_decoder
            #(
                .NUM            (DEC_NUM    ),
                .DEC_ADDR_BITS  (28         )
            )
        u_axi4l_addr_decoder
            (
                .s_axi4l        (axi4l_peri   ),
                .m_axi4l        (axi4l_dec    )
            );



    // ---------------------------------
    //  JFive Core
    // ---------------------------------

    localparam  int                         XLEN              = 32                                  ;
    localparam  int                         THREADS           = 4;//8                                   ;
    localparam  int                         ID_BITS           = THREADS > 1 ? $clog2(THREADS) : 1   ;
    localparam  type                        id_t              = logic         [ID_BITS-1:0]         ;
    localparam  int                         PC_BITS           = 32                                  ;
    localparam  type                        pc_t              = logic         [PC_BITS-1:0]         ;
    localparam  pc_t                        PC_MASK           = '0                                  ;
    localparam  type                        rval_t            = logic signed  [XLEN-1:0]            ;
    localparam  int                         LOAD_QUES         = 2                                   ;
    localparam   int                        TCM_MEM_SIZE      = 4 * 1024                            ;
    localparam   rval_t                     TCM_ADDR_LO       = 32'h0000_0000                       ;
    localparam   rval_t                     TCM_ADDR_HI       = 32'h7fff_ffff                       ;
    localparam                              TCM_RAM_TYPE      = "block"                             ;
    localparam   bit                        TCM_READMEMB      = 1'b0                                ;
    localparam   bit                        TCM_READMEMH      = 1'b1                                ;
    localparam                              TCM_READMEM_FIlE  = "../../../mem.hex"                  ;
    localparam  int                         M_AXI4L_PORTS     = 1                                   ;
    localparam  int                         M_AXI4L_ADDR_BITS = 32                                  ;
    localparam  type                        m_axi4l_data_t    = logic   [M_AXI4L_ADDR_BITS-1:0]     ;
    localparam  rval_t  [M_AXI4L_PORTS-1:0] M_AXI4L_ADDRS_LO  = '{32'h8000_0000}                    ;
    localparam  rval_t  [M_AXI4L_PORTS-1:0] M_AXI4L_ADDRS_HI  = '{32'hffff_ffff}                    ;

    localparam  bit     [THREADS-1:0]       INIT_RUN          = 4'hf;//8'hff                               ;
    localparam  id_t                        INIT_ID           = '0                                  ;
    localparam  pc_t    [THREADS-1:0]       INIT_PC           = //'{32'h1c, 32'h18, 32'h14, 32'h10,
                                                                  '{32'h0c, 32'h08, 32'h04, 32'h00}   ;

    /*
    jelly3_axi4l_if
            #(
                .ADDR_BITS          (40          ),
                .DATA_BITS          (32          )
            )
        s_axi4l_ctl
            (
                .aresetn            (~reset     ),
                .aclk               (clk        ),
                .aclken             (1'b1       )
            );
    
    jelly3_axi4l_if
            #(
                .ADDR_BITS          (40          ),
                .DATA_BITS          (32          )
            )
        s_axi4l_mem
            (
                .aresetn            (~reset     ),
                .aclk               (clk        ),
                .aclken             (1'b1       )
            );
    */

    jelly3_axi4l_if
            #(
                .ADDR_BITS          (32          ),
                .DATA_BITS          (32          )
            )
        m_axi4l
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

                .s_axi4l_ctl        (axi4l_dec[DEC_CTL] ),
                .s_axi4l_mem        (axi4l_dec[DEC_MEM] ),
                .m_axi4l_ext        ('{m_axi4l}         )
            );



    // ---------------------------------
    //  PMOD
    // ---------------------------------

    jelly3_axi4l_register
            #(
                .NUM                (4          ),
                .BITS               (1          ),
                .INIT               ('0         )
            )
        u_axi4l_register
            (
                .s_axi4l            (m_axi4l    ),
                .value              (pmod[3:0]  )
            );

    logic   [27:0]    counter;
    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 28'h0;
        end else begin
            counter <= counter + 28'h1;
        end
    end
    assign pmod[7:4] = counter[27:24];

endmodule

`default_nettype wire

// end of file
