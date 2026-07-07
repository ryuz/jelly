// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// AXI4-Lite FIFO bridge
//
// Inserts independent stream FIFOs on all AXI4-Lite channels.
// Each channel can cross clock domains by enabling ASYNC.
module jelly3_axi4l_fifo
        #(
            parameter   bit     ASYNC            = 1                 ,
            parameter   int     AW_FIFO_PTR_BITS = 4                 ,
            parameter   int     W_FIFO_PTR_BITS  = 4                 ,
            parameter   int     B_FIFO_PTR_BITS  = 4                 ,
            parameter   int     AR_FIFO_PTR_BITS = 4                 ,
            parameter   int     R_FIFO_PTR_BITS  = 4                 ,
            parameter   int     S_SYNC_FF        = 2                 ,
            parameter   int     M_SYNC_FF        = 2                 ,
            parameter           RAM_TYPE         = "block"           ,
            parameter   bit     DOUT_REG         = 1'b0              ,
            parameter           DEVICE           = "RTL"             ,
            parameter           SIMULATION       = "false"           ,
            parameter           DEBUG            = "false"           
        )
        (
            jelly3_axi4l_if.s   s_axi4l ,
            jelly3_axi4l_if.m   m_axi4l 
        );

    localparam type aw_packet_t = struct packed {
        logic [s_axi4l.ADDR_BITS-1:0] addr;
        logic [s_axi4l.PROT_BITS-1:0] prot;
    };

    localparam type w_packet_t = struct packed {
        logic [s_axi4l.DATA_BITS-1:0] data;
        logic [s_axi4l.STRB_BITS-1:0] strb;
    };

    localparam type b_packet_t = struct packed {
        logic [s_axi4l.RESP_BITS-1:0] resp;
    };

    localparam type ar_packet_t = struct packed {
        logic [s_axi4l.ADDR_BITS-1:0] addr;
        logic [s_axi4l.PROT_BITS-1:0] prot;
    };

    localparam type r_packet_t = struct packed {
        logic [s_axi4l.DATA_BITS-1:0] data;
        logic [s_axi4l.RESP_BITS-1:0] resp;
    };

    localparam int AW_FIFO_SIZE = 2 ** AW_FIFO_PTR_BITS;
    localparam int W_FIFO_SIZE  = 2 ** W_FIFO_PTR_BITS;
    localparam int B_FIFO_SIZE  = 2 ** B_FIFO_PTR_BITS;
    localparam int AR_FIFO_SIZE = 2 ** AR_FIFO_PTR_BITS;
    localparam int R_FIFO_SIZE  = 2 ** R_FIFO_PTR_BITS;

    localparam int AW_FIFO_SIZE_BITS = $clog2(AW_FIFO_SIZE + 1);
    localparam int W_FIFO_SIZE_BITS  = $clog2(W_FIFO_SIZE  + 1);
    localparam int B_FIFO_SIZE_BITS  = $clog2(B_FIFO_SIZE  + 1);
    localparam int AR_FIFO_SIZE_BITS = $clog2(AR_FIFO_SIZE + 1);
    localparam int R_FIFO_SIZE_BITS  = $clog2(R_FIFO_SIZE  + 1);

    localparam type aw_size_t = logic [AW_FIFO_SIZE_BITS-1:0];
    localparam type w_size_t  = logic [W_FIFO_SIZE_BITS-1:0];
    localparam type b_size_t  = logic [B_FIFO_SIZE_BITS-1:0];
    localparam type ar_size_t = logic [AR_FIFO_SIZE_BITS-1:0];
    localparam type r_size_t  = logic [R_FIFO_SIZE_BITS-1:0];

    aw_packet_t aw_s_data   ;
    aw_packet_t aw_m_data   ;
    w_packet_t  w_s_data    ;
    w_packet_t  w_m_data    ;
    b_packet_t  b_s_data    ;
    b_packet_t  b_m_data    ;
    ar_packet_t ar_s_data   ;
    ar_packet_t ar_m_data   ;
    r_packet_t  r_s_data    ;
    r_packet_t  r_m_data    ;

    aw_size_t   aw_s_free_size;
    aw_size_t   aw_m_data_size;
    w_size_t    w_s_free_size;
    w_size_t    w_m_data_size;
    b_size_t    b_s_free_size;
    b_size_t    b_m_data_size;
    ar_size_t   ar_s_free_size;
    ar_size_t   ar_m_data_size;
    r_size_t    r_s_free_size;
    r_size_t    r_m_data_size;

    // AW channel : s -> m
    assign aw_s_data.addr = s_axi4l.awaddr;
    assign aw_s_data.prot = s_axi4l.awprot;

    jelly3_stream_fifo
            #(
                .ASYNC          (ASYNC              ),
                .PTR_BITS       (AW_FIFO_PTR_BITS   ),
                .SIZE_BITS      (AW_FIFO_SIZE_BITS  ),
                .size_t         (aw_size_t          ),
                .DATA_BITS      ($bits(aw_packet_t) ),
                .data_t         (aw_packet_t        ),
                .S_SYNC_FF      (S_SYNC_FF          ),
                .M_SYNC_FF      (M_SYNC_FF          ),
                .RAM_TYPE       (RAM_TYPE           ),
                .DOUT_REG       (DOUT_REG           ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_stream_fifo_aw
            (
                .s_reset        (~s_axi4l.aresetn   ),
                .s_clk          (s_axi4l.aclk       ),
                .s_cke          (s_axi4l.aclken     ),
                .s_data         (aw_s_data          ),
                .s_valid        (s_axi4l.awvalid    ),
                .s_ready        (s_axi4l.awready    ),
                .s_free_size    (aw_s_free_size     ),

                .m_reset        (~m_axi4l.aresetn   ),
                .m_clk          (m_axi4l.aclk       ),
                .m_cke          (m_axi4l.aclken     ),
                .m_data         (aw_m_data          ),
                .m_valid        (m_axi4l.awvalid    ),
                .m_ready        (m_axi4l.awready    ),
                .m_data_size    (aw_m_data_size     )
            );

    assign m_axi4l.awaddr = aw_m_data.addr;
    assign m_axi4l.awprot = aw_m_data.prot;


    // W channel : s -> m
    assign w_s_data.data = s_axi4l.wdata;
    assign w_s_data.strb = s_axi4l.wstrb;

    jelly3_stream_fifo
            #(
                .ASYNC          (ASYNC              ),
                .PTR_BITS       (W_FIFO_PTR_BITS    ),
                .SIZE_BITS      (W_FIFO_SIZE_BITS   ),
                .size_t         (w_size_t           ),
                .DATA_BITS      ($bits(w_packet_t)  ),
                .data_t         (w_packet_t         ),
                .S_SYNC_FF      (S_SYNC_FF          ),
                .M_SYNC_FF      (M_SYNC_FF          ),
                .RAM_TYPE       (RAM_TYPE           ),
                .DOUT_REG       (DOUT_REG           ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_stream_fifo_w
            (
                .s_reset        (~s_axi4l.aresetn   ),
                .s_clk          (s_axi4l.aclk       ),
                .s_cke          (s_axi4l.aclken     ),
                .s_data         (w_s_data           ),
                .s_valid        (s_axi4l.wvalid     ),
                .s_ready        (s_axi4l.wready     ),
                .s_free_size    (w_s_free_size      ),

                .m_reset        (~m_axi4l.aresetn   ),
                .m_clk          (m_axi4l.aclk       ),
                .m_cke          (m_axi4l.aclken     ),
                .m_data         (w_m_data           ),
                .m_valid        (m_axi4l.wvalid     ),
                .m_ready        (m_axi4l.wready     ),
                .m_data_size    (w_m_data_size      )
            );

    assign m_axi4l.wdata = w_m_data.data;
    assign m_axi4l.wstrb = w_m_data.strb;


    // B channel : m -> s
    assign b_s_data.resp = m_axi4l.bresp;

    jelly3_stream_fifo
            #(
                .ASYNC          (ASYNC              ),
                .PTR_BITS       (B_FIFO_PTR_BITS    ),
                .SIZE_BITS      (B_FIFO_SIZE_BITS   ),
                .size_t         (b_size_t           ),
                .DATA_BITS      ($bits(b_packet_t)  ),
                .data_t         (b_packet_t         ),
                .S_SYNC_FF      (S_SYNC_FF          ),
                .M_SYNC_FF      (M_SYNC_FF          ),
                .RAM_TYPE       (RAM_TYPE           ),
                .DOUT_REG       (DOUT_REG           ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_stream_fifo_b
            (
                .s_reset        (~m_axi4l.aresetn   ),
                .s_clk          (m_axi4l.aclk       ),
                .s_cke          (m_axi4l.aclken     ),
                .s_data         (b_s_data           ),
                .s_valid        (m_axi4l.bvalid     ),
                .s_ready        (m_axi4l.bready     ),
                .s_free_size    (b_s_free_size      ),

                .m_reset        (~s_axi4l.aresetn   ),
                .m_clk          (s_axi4l.aclk       ),
                .m_cke          (s_axi4l.aclken     ),
                .m_data         (b_m_data           ),
                .m_valid        (s_axi4l.bvalid     ),
                .m_ready        (s_axi4l.bready     ),
                .m_data_size    (b_m_data_size      )
            );

    assign s_axi4l.bresp = b_m_data.resp;


    // AR channel : s -> m
    assign ar_s_data.addr = s_axi4l.araddr;
    assign ar_s_data.prot = s_axi4l.arprot;

    jelly3_stream_fifo
            #(
                .ASYNC          (ASYNC              ),
                .PTR_BITS       (AR_FIFO_PTR_BITS   ),
                .SIZE_BITS      (AR_FIFO_SIZE_BITS  ),
                .size_t         (ar_size_t          ),
                .DATA_BITS      ($bits(ar_packet_t) ),
                .data_t         (ar_packet_t        ),
                .S_SYNC_FF      (S_SYNC_FF          ),
                .M_SYNC_FF      (M_SYNC_FF          ),
                .RAM_TYPE       (RAM_TYPE           ),
                .DOUT_REG       (DOUT_REG           ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_stream_fifo_ar
            (
                .s_reset        (~s_axi4l.aresetn   ),
                .s_clk          (s_axi4l.aclk       ),
                .s_cke          (s_axi4l.aclken     ),
                .s_data         (ar_s_data          ),
                .s_valid        (s_axi4l.arvalid    ),
                .s_ready        (s_axi4l.arready    ),
                .s_free_size    (ar_s_free_size     ),

                .m_reset        (~m_axi4l.aresetn   ),
                .m_clk          (m_axi4l.aclk       ),
                .m_cke          (m_axi4l.aclken     ),
                .m_data         (ar_m_data          ),
                .m_valid        (m_axi4l.arvalid    ),
                .m_ready        (m_axi4l.arready    ),
                .m_data_size    (ar_m_data_size     )
            );

    assign m_axi4l.araddr = ar_m_data.addr;
    assign m_axi4l.arprot = ar_m_data.prot;


    // R channel : m -> s
    assign r_s_data.data = m_axi4l.rdata;
    assign r_s_data.resp = m_axi4l.rresp;

    jelly3_stream_fifo
            #(
                .ASYNC          (ASYNC              ),
                .PTR_BITS       (R_FIFO_PTR_BITS    ),
                .SIZE_BITS      (R_FIFO_SIZE_BITS   ),
                .size_t         (r_size_t           ),
                .DATA_BITS      ($bits(r_packet_t)  ),
                .data_t         (r_packet_t         ),
                .S_SYNC_FF      (S_SYNC_FF          ),
                .M_SYNC_FF      (M_SYNC_FF          ),
                .RAM_TYPE       (RAM_TYPE           ),
                .DOUT_REG       (DOUT_REG           ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_stream_fifo_r
            (
                .s_reset        (~m_axi4l.aresetn   ),
                .s_clk          (m_axi4l.aclk       ),
                .s_cke          (m_axi4l.aclken     ),
                .s_data         (r_s_data           ),
                .s_valid        (m_axi4l.rvalid     ),
                .s_ready        (m_axi4l.rready     ),
                .s_free_size    (r_s_free_size      ),

                .m_reset        (~s_axi4l.aresetn   ),
                .m_clk          (s_axi4l.aclk       ),
                .m_cke          (s_axi4l.aclken     ),
                .m_data         (r_m_data           ),
                .m_valid        (s_axi4l.rvalid     ),
                .m_ready        (s_axi4l.rready     ),
                .m_data_size    (r_m_data_size      )
            );

    assign s_axi4l.rdata = r_m_data.data;
    assign s_axi4l.rresp = r_m_data.resp;


    initial begin
        if (s_axi4l.ADDR_BITS != m_axi4l.ADDR_BITS) begin
            $error("ERROR: ADDR_BITS of s_axi4l and m_axi4l must be same");
        end
        if (s_axi4l.DATA_BITS != m_axi4l.DATA_BITS) begin
            $error("ERROR: DATA_BITS of s_axi4l and m_axi4l must be same");
        end
        if (s_axi4l.STRB_BITS != m_axi4l.STRB_BITS) begin
            $error("ERROR: STRB_BITS of s_axi4l and m_axi4l must be same");
        end
        if (s_axi4l.PROT_BITS != m_axi4l.PROT_BITS) begin
            $error("ERROR: PROT_BITS of s_axi4l and m_axi4l must be same");
        end
        if (s_axi4l.RESP_BITS != m_axi4l.RESP_BITS) begin
            $error("ERROR: RESP_BITS of s_axi4l and m_axi4l must be same");
        end
    end

endmodule


`default_nettype wire


// end of file