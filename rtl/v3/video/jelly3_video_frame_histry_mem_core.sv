// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_video_frame_histry_mem_core
        #(
            parameter   int     N            = 2                                ,
            parameter   int     C            = 1                                ,
            parameter   int     BUF_SIZE     = 640 * 480                        ,
            parameter   bit     SDP          = BUF_SIZE > 64                    ,
            parameter           RAM_TYPE     = SDP ? "block" : "distributed"    ,
            parameter   bit     DOUT_REG     = SDP                              
        )
        (
            jelly3_axi4s_if.s                   s_axi4s,
            jelly3_axi4s_if.m                   m_axi4s
        );

    localparam  int     USER_BITS    = 1                        ;
    localparam  type    user_t       = logic    [USER_BITS-1:0] ;
    localparam  int     DATA_BITS    = s_axi4s.DATA_BITS        ;
    localparam  type    data_t       = logic    [DATA_BITS-1:0] ;

    typedef struct packed {
        user_t  user    ;
        logic   last    ;
        data_t  data    ;
    } packet_t;

    logic                   cke;
    assign cke = s_axi4s.tready && s_axi4s.aclken;


    logic                   buf_s_first ;
    logic                   buf_s_last  ;
    logic                   buf_s_user  ;
    packet_t                buf_s_data  ;
    logic                   buf_s_valid ;

    logic                   buf_m_first ;
    logic                   buf_m_last  ;
    logic       [N-1:0]     buf_m_user  ;
    packet_t    [N-1:0]     buf_m_data  ;
    logic       [N-1:0]     buf_m_valid ;

    jelly3_histry_buffer_mem
            #(
                .N              (N                  ),
                .USER_BITS      (USER_BITS          ),
                .user_t         (user_t             ),
                .DATA_BITS      ($bits(packet_t)    ),
                .data_t         (packet_t           ),
                .BUF_SIZE       (BUF_SIZE           ),
                .SDP            (SDP                ),
                .RAM_TYPE       (RAM_TYPE           ),
                .DOUT_REG       (DOUT_REG           )
            )
        u_histry_buffer_mem
            (
                .reset          (~s_axi4s.aresetn   ),
                .clk            (s_axi4s.aclk       ),
                .cke            (cke                ),

                .s_first        (buf_s_first        ),
                .s_last         (buf_s_last         ),
                .s_user         (buf_s_user         ),
                .s_data         (buf_s_data         ),
                .s_valid        (buf_s_valid        ),

                .m_first        (buf_m_first        ),
                .m_last         (buf_m_last         ),
                .m_user         (buf_m_user         ),
                .m_data         (buf_m_data         ),
                .m_valid        (buf_m_valid        )
            );

    assign buf_s_first     = s_axi4s.tuser[0]   ;
    assign buf_s_last      = s_axi4s.tlast      ;
    assign buf_s_user      = 1'bx               ;
    assign buf_s_data      = s_axi4s.tdata      ;
    assign buf_s_valid     = s_axi4s.tvalid     ;

    assign s_axi4s.tready  = !m_axi4s.tvalid || m_axi4s.tready;

    assign m_axi4s.tuser   = buf_m_first    ;
    assign m_axi4s.tlast   = buf_m_last     ;
    assign m_axi4s.tdata   = buf_m_data     ;
    assign m_axi4s.tvalid  = buf_m_valid    ;

endmodule

`default_nettype wire

// end of file
