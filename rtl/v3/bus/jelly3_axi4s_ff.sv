// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4s_ff
        #(
            parameter   bit     S_REG      = 1                      ,
            parameter   bit     M_REG      = 1                      ,
            parameter           DEVICE     = "RTL"                  ,
            parameter           SIMULATION = "false"                ,
            parameter           DEBUG      = "false"                
        )
        (
            jelly3_axi4s_if.s       s_axi4s     ,
            jelly3_axi4s_if.m       m_axi4s     
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

    packet_t    m_packet ;
    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits(packet_t)    ),
                .data_t         (packet_t           ),
                .S_REG          (S_REG              ),
                .M_REG          (M_REG              )
            )
        u_stream_ff_s
            (
                .reset          (~s_axi4s.aresetn   ),
                .clk            (s_axi4s.aclk       ),
                .cke            (s_axi4s.aclken     ),

                .s_data         (s_packet           ),
                .s_valid        (s_axi4s.tvalid     ),
                .s_ready        (s_axi4s.tready     ),

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
