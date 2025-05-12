// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4_s
        #(
            parameter   int     MEM_ADDR_BITS    = 16                   ,
            parameter   int     MEM_SIZE         = (1 << MEM_ADDR_BITS) ,
            parameter   bit     READ_DATA_ADDR   = 0                    ,      // リード結果をアドレスとする
            parameter   string  WRITE_LOG_FILE   = ""                   ,
            parameter   string  READ_LOG_FILE    = ""                   ,
            parameter   int     AW_DELAY         = 0                    ,
            parameter   int     AR_DELAY         = 0                    ,
            parameter   int     AW_FIFO_PTR_BITS = 0                    ,
            parameter   int     W_FIFO_PTR_BITS  = 0                    ,
            parameter   int     B_FIFO_PTR_BITS  = 0                    ,
            parameter   int     AR_FIFO_PTR_BITS = 0                    ,
            parameter   int     R_FIFO_PTR_BITS  = 0                    ,
            parameter   int     AW_BUSY_RATE     = 0                    ,
            parameter   int     W_BUSY_RATE      = 0                    ,
            parameter   int     B_BUSY_RATE      = 0                    ,
            parameter   int     AR_BUSY_RATE     = 0                    ,
            parameter   int     R_BUSY_RATE      = 0                    ,
            parameter   int     AW_BUSY_RAND     = 0                    ,
            parameter   int     W_BUSY_RAND      = 1                    ,
            parameter   int     B_BUSY_RAND      = 2                    ,
            parameter   int     AR_BUSY_RAND     = 3                    ,
            parameter   int     R_BUSY_RAND      = 4                    
        )
        (
            jelly3_axi4_if.s    s_axi4         
        );
    

    jelly2_axi4_slave_model
            #(
                .AXI_ID_WIDTH       (s_axi4.ID_BITS             ),
                .AXI_ADDR_WIDTH     (s_axi4.ADDR_BITS           ),
                .AXI_QOS_WIDTH      (s_axi4.QOS_BITS            ),
                .AXI_LEN_WIDTH      (s_axi4.LEN_BITS            ),
                .AXI_DATA_SIZE      ($clog2(s_axi4.STRB_BITS)   ),
                .AXI_DATA_WIDTH     (s_axi4.DATA_BITS           ),
                .AXI_STRB_WIDTH     (s_axi4.STRB_BITS           ),
                .MEM_WIDTH          (MEM_ADDR_BITS              ),
                .MEM_SIZE           (MEM_SIZE                   ),
                .READ_DATA_ADDR     (READ_DATA_ADDR             ),
                .WRITE_LOG_FILE     (WRITE_LOG_FILE             ),
                .READ_LOG_FILE      (READ_LOG_FILE              ),
                .AW_DELAY           (AW_DELAY                   ),
                .AR_DELAY           (AR_DELAY                   ),
                .AW_FIFO_PTR_WIDTH  (AW_FIFO_PTR_BITS           ),
                .W_FIFO_PTR_WIDTH   (W_FIFO_PTR_BITS            ),
                .B_FIFO_PTR_WIDTH   (B_FIFO_PTR_BITS            ),
                .AR_FIFO_PTR_WIDTH  (AR_FIFO_PTR_BITS           ),
                .R_FIFO_PTR_WIDTH   (R_FIFO_PTR_BITS            ),
                .AW_BUSY_RATE       (AW_BUSY_RATE               ),
                .W_BUSY_RATE        (W_BUSY_RATE                ),
                .B_BUSY_RATE        (B_BUSY_RATE                ),
                .AR_BUSY_RATE       (AR_BUSY_RATE               ),
                .R_BUSY_RATE        (R_BUSY_RATE                ),
                .AW_BUSY_RAND       (AW_BUSY_RAND               ),
                .W_BUSY_RAND        (W_BUSY_RAND                ),
                .B_BUSY_RAND        (B_BUSY_RAND                ),
                .AR_BUSY_RAND       (AR_BUSY_RAND               ),
                .R_BUSY_RAND        (R_BUSY_RAND                )
            )
        u_axi4_slave_model
            (
                .aresetn            (s_axi4.aresetn             ),
                .aclk               (s_axi4.aclk                ),
                .aclken             (s_axi4.aclken              ),
                .s_axi4_awid        (s_axi4.awid                ),
                .s_axi4_awaddr      (s_axi4.awaddr              ),
                .s_axi4_awlen       (s_axi4.awlen               ),
                .s_axi4_awsize      (s_axi4.awsize              ),
                .s_axi4_awburst     (s_axi4.awburst             ),
                .s_axi4_awlock      (s_axi4.awlock              ),
                .s_axi4_awcache     (s_axi4.awcache             ),
                .s_axi4_awprot      (s_axi4.awprot              ),
                .s_axi4_awqos       (s_axi4.awqos               ),
                .s_axi4_awvalid     (s_axi4.awvalid             ),
                .s_axi4_awready     (s_axi4.awready             ),
                .s_axi4_wdata       (s_axi4.wdata               ),
                .s_axi4_wstrb       (s_axi4.wstrb               ),
                .s_axi4_wlast       (s_axi4.wlast               ),
                .s_axi4_wvalid      (s_axi4.wvalid              ),
                .s_axi4_wready      (s_axi4.wready              ),
                .s_axi4_bid         (s_axi4.bid                 ),
                .s_axi4_bresp       (s_axi4.bresp               ),
                .s_axi4_bvalid      (s_axi4.bvalid              ),
                .s_axi4_bready      (s_axi4.bready              ),
                .s_axi4_arid        (s_axi4.arid                ),
                .s_axi4_araddr      (s_axi4.araddr              ),
                .s_axi4_arlen       (s_axi4.arlen               ),
                .s_axi4_arsize      (s_axi4.arsize              ),
                .s_axi4_arburst     (s_axi4.arburst             ),
                .s_axi4_arlock      (s_axi4.arlock              ),
                .s_axi4_arcache     (s_axi4.arcache             ),
                .s_axi4_arprot      (s_axi4.arprot              ),
                .s_axi4_arqos       (s_axi4.arqos               ),
                .s_axi4_arvalid     (s_axi4.arvalid             ),
                .s_axi4_arready     (s_axi4.arready             ),
                .s_axi4_rid         (s_axi4.rid                 ),
                .s_axi4_rdata       (s_axi4.rdata               ),
                .s_axi4_rresp       (s_axi4.rresp               ),
                .s_axi4_rlast       (s_axi4.rlast               ),
                .s_axi4_rvalid      (s_axi4.rvalid              ),
                .s_axi4_rready      (s_axi4.rready              )
            );
    
    
endmodule


`default_nettype wire


// end of file
