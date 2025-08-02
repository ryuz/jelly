// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4s_fifo
        #(
            parameter   bit     ASYNC      = 1                      ,
            parameter   int     PTR_BITS   = 9                      ,
            localparam  int     FIFO_SIZE  = 2 ** PTR_BITS          ,
            parameter   int     SIZE_BITS  = $clog2(FIFO_SIZE + 1)  ,
            parameter   type    size_t     = logic [SIZE_BITS-1:0]  ,
            parameter           RAM_TYPE   = "block"                ,
            parameter   int     S_SYNC_FF  = 2                      ,
            parameter   int     M_SYNC_FF  = 2                      ,
            parameter   bit     DOUT_REG   = 1                      ,
            parameter   bit     S_REG      = 1                      ,
            parameter   bit     M_REG      = 1                      ,
            parameter           DEVICE     = "RTL"                  ,
            parameter           SIMULATION = "false"                ,
            parameter           DEBUG      = "false"                
        )
        (
            jelly3_axi4s_if.s       s_axi4s     ,
            jelly3_axi4s_if.m       m_axi4s     ,
            output  var size_t      s_free_size ,
            output  var size_t      m_data_size 
        );

    localparam  int     DATA_BITS = s_axi4s.DATA_BITS   ;
    localparam  int     BYTE_BITS = s_axi4s.BYTE_BITS   ;
    localparam  int     STRB_BITS = s_axi4s.STRB_BITS   ;
    localparam  int     KEEP_BITS = s_axi4s.KEEP_BITS   ;
    localparam  int     ID_BITS   = s_axi4s.ID_BITS     ;
    localparam  int     DEST_BITS = s_axi4s.DEST_BITS   ;
    localparam  int     USER_BITS = s_axi4s.USER_BITS   ;

    typedef struct packed {
        logic   [DATA_BITS-1:0]     tdata   ;
        logic   [STRB_BITS-1:0]     tstrb   ;
        logic   [STRB_BITS-1:0]     tkeep   ;
        logic                       tlast   ;
        logic   [ID_BITS-1:0]       tid     ;
        logic   [DEST_BITS-1:0]     tdest   ;
        logic   [USER_BITS-1:0]     tuser   ;
    } packet_t;


    // slave FF
    packet_t    s_packet;
    assign s_packet.tdata = s_axi4s.tdata;
    assign s_packet.tstrb = s_axi4s.tstrb;
    assign s_packet.tkeep = s_axi4s.tkeep;
    assign s_packet.tlast = s_axi4s.tlast;
    assign s_packet.tid   = s_axi4s.tid  ;
    assign s_packet.tdest = s_axi4s.tdest;
    assign s_packet.tuser = s_axi4s.tuser;

    packet_t    s_ff_packet ;
    logic       s_ff_valid  ;
    logic       s_ff_ready  ;
    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits(packet_t)    ),
                .data_t         (packet_t           ),
                .S_REG          (S_REG              ),
                .M_REG          (S_REG              )
            )
        u_stream_ff_s
            (
                .reset          (~s_axi4s.aresetn   ),
                .clk            (s_axi4s.aclk       ),
                .cke            (s_axi4s.aclken     ),

                .s_data         (s_packet           ),
                .s_valid        (s_axi4s.tvalid     ),
                .s_ready        (s_axi4s.tready     ),

                .m_data         (s_ff_packet        ),
                .m_valid        (s_ff_valid         ),
                .m_ready        (s_ff_ready         )
            );
        

    // FIFO
    packet_t    fifo_packet ;
    logic       fifo_valid  ;
    logic       fifo_ready  ;
    jelly3_stream_fifo
            #(
                .ASYNC          (ASYNC              ),
                .PTR_BITS       (PTR_BITS           ),
                .SIZE_BITS      (SIZE_BITS          ),
                .DATA_BITS      ($bits(packet_t)    ),
                .data_t         (packet_t           ),
                .S_SYNC_FF      (S_SYNC_FF          ),
                .M_SYNC_FF      (M_SYNC_FF          ),
                .RAM_TYPE       (RAM_TYPE           ),
                .DOUT_REG       (DOUT_REG           ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_stream_fifo
            (
                .s_reset        (~s_axi4s.aresetn   ),
                .s_clk          (s_axi4s.aclk       ),
                .s_cke          (s_axi4s.aclken     ),
                .s_data         (s_ff_packet        ),
                .s_valid        (s_ff_valid         ),
                .s_ready        (s_ff_ready         ),
                .s_free_size    (s_free_size        ),

                .m_reset        (~m_axi4s.aresetn   ),
                .m_clk          (m_axi4s.aclk       ),
                .m_cke          (m_axi4s.aclken     ),
                .m_data         (fifo_packet        ),
                .m_valid        (fifo_valid         ),
                .m_ready        (fifo_ready         ),
                .m_data_size    (m_data_size        )
            );

    // master FF
    packet_t    m_packet    ;
    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits(packet_t)    ),
                .data_t         (packet_t           ),
                .S_REG          (M_REG              ),
                .M_REG          (M_REG              )
            )
        u_stream_ff_m
            (
                .reset          (~m_axi4s.aresetn   ),
                .clk            (m_axi4s.aclk       ),
                .cke            (m_axi4s.aclken     ),

                .s_data         (fifo_packet        ),
                .s_valid        (fifo_valid         ),
                .s_ready        (fifo_ready         ),

                .m_data         (m_packet           ),
                .m_valid        (m_axi4s.tvalid     ),
                .m_ready        (m_axi4s.tready     )
            );
    
    assign m_axi4s.tdata  = m_packet.tdata  ;
    assign m_axi4s.tstrb  = m_packet.tstrb  ;
    assign m_axi4s.tkeep  = m_packet.tkeep  ;
    assign m_axi4s.tlast  = m_packet.tlast  ;
    assign m_axi4s.tid    = m_packet.tid    ;
    assign m_axi4s.tdest  = m_packet.tdest  ;
    assign m_axi4s.tuser  = m_packet.tuser  ;
    

endmodule


`default_nettype wire


// end of file

