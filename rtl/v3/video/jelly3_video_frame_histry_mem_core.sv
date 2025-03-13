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
    localparam  int     FLAG_BITS    = 1                        ;
    localparam  type    flag_t       = logic    [FLAG_BITS-1:0] ;
    localparam  int     DATA_BITS    = s_axi4s.DATA_BITS        ;
    localparam  type    data_t       = logic    [DATA_BITS-1:0] ;


    logic                   cke;
    assign cke = s_axi4s.tready && s_axi4s.aclken;


    logic                   hist_s_first ;
    user_t                  hist_s_user  ;
    flag_t                  hist_s_flag  ;
    data_t                  hist_s_data  ;
    logic                   hist_s_valid ;

    logic                   hist_m_first ;
    logic                   hist_m_user  ;
    logic       [N-1:0]     hist_m_flag  ;
    data_t      [N-1:0]     hist_m_data  ;
    logic       [N-1:0]     hist_m_valid ;

    jelly3_histry_buffer_mem
            #(
                .N              (N                  ),
                .USER_BITS      (USER_BITS          ),
                .user_t         (user_t             ),
                .DATA_BITS      (DATA_BITS          ),
                .data_t         (data_t             ),
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

                .s_first        (hist_s_first       ),
                .s_user         (hist_s_user        ),
                .s_flag         (hist_s_flag        ),
                .s_data         (hist_s_data        ),
                .s_valid        (hist_s_valid       ),

                .m_first        (hist_m_first       ),
                .m_user         (hist_m_user        ),
                .m_flag         (hist_m_flag        ),
                .m_data         (hist_m_data        ),
                .m_valid        (hist_m_valid       )
            );

    assign hist_s_first    = s_axi4s.tuser[0]   ;
    assign hist_s_user     = s_axi4s.tlast      ;
    assign hist_s_flag     = 1'bx               ;
    assign hist_s_data     = s_axi4s.tdata      ;
    assign hist_s_valid    = s_axi4s.tvalid     ;

    assign s_axi4s.tready  = !m_axi4s.tvalid || m_axi4s.tready;

    assign m_axi4s.tuser   = hist_m_first    ;
    assign m_axi4s.tlast   = hist_m_user     ;
    assign m_axi4s.tdata   = hist_m_data     ;
    assign m_axi4s.tvalid  = hist_m_valid    ;
    
endmodule

`default_nettype wire

// end of file
