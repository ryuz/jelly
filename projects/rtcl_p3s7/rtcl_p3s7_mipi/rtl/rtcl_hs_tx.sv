// ---------------------------------------------------------------------------
//  RTC-lab  PYTHON300 + Spartan7 MIPI Global shutter camera
//
//                                 Copyright (C) 2024-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// Original Protocol
module rtcl_hs_tx
        #(
            parameter   int     CHANNELS   = 4          ,
            parameter   int     RAW_BITS   = 10         ,
            parameter   int     DPHY_LANES = 2          ,
            parameter           DEVICE     = "RTL"      ,
            parameter           SIMULATION = "false"    ,
            parameter           DEBUG      = "false"    
        )
        (
            jelly3_axi4s_if.s       s_axi4s             ,
            jelly3_axi4s_if.m       m_axi4s             
        );

    localparam  type    raw_t  = logic [RAW_BITS-1:0];

    // Zero Stuffing
    logic                       stuff_busy  ;
    logic                       stuff_first ;
    logic                       stuff_last  ;
    raw_t   [CHANNELS-1:0]      stuff_data  ;
    logic                       stuff_valid ;
    logic                       stuff_ready ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            stuff_busy  <= 1'b0 ;
            stuff_first <= 'x   ;
            stuff_last  <= 'x   ;
            stuff_data  <= 'x   ;
            stuff_valid <= 1'b0 ;
        end
        else begin
            if ( stuff_ready ) begin
                stuff_valid <= 1'b0;
            end

            if ( s_axi4s.tready ) begin
                if ( stuff_busy ) begin
                    stuff_first <= s_axi4s.tvalid ? s_axi4s.tuser[0] : '0;
                    stuff_last  <= s_axi4s.tvalid ? s_axi4s.tlast    : '0;
                    stuff_data  <= s_axi4s.tvalid ? s_axi4s.tdata    : '0;
                    stuff_valid <= 1'b1;  // always valid
                    if ( s_axi4s.tvalid && s_axi4s.tlast ) begin
                        stuff_busy <= 1'b0;
                    end
                end
                else begin
                    if ( s_axi4s.tvalid ) begin
                        stuff_busy  <= 1'b1             ;
                        stuff_first <= s_axi4s.tuser[0] ;
                        stuff_last  <= s_axi4s.tlast    ;
                        stuff_data  <= s_axi4s.tdata    ;
                        stuff_valid <= 1'b1;
                    end
                end
            end
        end
    end

    assign s_axi4s.tready = !stuff_valid || stuff_ready;


    // width convert
    jelly2_stream_width_convert
            #(
                .UNIT_WIDTH         (2                      ),
                .S_NUM              (CHANNELS*5             ),
                .M_NUM              (DPHY_LANES*4           ),
                .HAS_FIRST          (1                      ),
                .HAS_LAST           (1                      ),
                .HAS_STRB           (0                      ),
                .HAS_KEEP           (0                      ),
                .AUTO_FIRST         (0                      ),
                .HAS_ALIGN_S        (0                      ),
                .HAS_ALIGN_M        (0                      ),
                .FIRST_OVERWRITE    (0                      ),
                .FIRST_FORCE_LAST   (0                      ),
                .REDUCE_KEEP        (0                      ),
                .USER_F_WIDTH       (0                      ),
                .USER_L_WIDTH       (0                      ),
                .S_REGS             (1                      ),
                .M_REGS             (1                      )
            )
        u_stream_width_convert
            (
                .reset              (~s_axi4s.aresetn       ),
                .clk                (s_axi4s.aclk           ),
                .cke                (s_axi4s.aclken         ),

                .endian             (1'b0                   ),
                .padding            ('0                     ),
                
                .s_align_s          ('0                     ),
                .s_align_m          ('0                     ),
                .s_first            (stuff_first            ),
                .s_last             (stuff_last             ),
                .s_data             (stuff_data             ),
                .s_strb             ('1                     ),
                .s_keep             ('1                     ),
                .s_user_f           ('0                     ),
                .s_user_l           ('0                     ),
                .s_valid            (stuff_valid            ),
                .s_ready            (stuff_ready            ),

                .m_first            (m_axi4s.tuser[0]       ),
                .m_last             (m_axi4s.tlast          ),
                .m_data             (m_axi4s.tdata          ),
                .m_strb             (                       ),
                .m_keep             (                       ),
                .m_user_f           (                       ),
                .m_user_l           (                       ),
                .m_valid            (m_axi4s.tvalid         ),
                .m_ready            (m_axi4s.tready         )
            );


endmodule


`default_nettype wire


// end of file
