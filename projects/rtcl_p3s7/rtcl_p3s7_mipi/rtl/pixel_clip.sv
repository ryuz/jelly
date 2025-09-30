// ---------------------------------------------------------------------------
//  RTC-lab  PYTHON300 + Spartan7 MIPI Global shutter camera
//
//                                 Copyright (C) 2024-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module pixel_clip
        #(
            parameter   int     CHANNELS       = 4  ,
            parameter   int     RAW_BITS       = 10 
        )
        (
            input var logic     enable  ,

            jelly3_axi4s_if.s   s_axi4s ,
            jelly3_axi4s_if.m   m_axi4s  
        );

    localparam  type    user_t = logic [s_axi4s.USER_BITS-1:0]  ;
    localparam  type    raw_t  = logic [RAW_BITS-1:0]           ;

    // 0なら1にクリップ
    function automatic raw_t clip_value(raw_t raw);
        if ( raw == '0 ) begin
            return 1;
        end
        return raw;
    endfunction

    // clip
    user_t                  tuser   ;
    logic                   tlast   ;
    raw_t  [CHANNELS-1:0]   tdata   ;
    logic                   tvalid  ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            tuser  <= 'x    ;
            tlast  <= 'x    ;
            tdata  <= 'x    ;
            tvalid <= 1'b0  ;
        end
        else if ( s_axi4s.aclken ) begin
            if ( s_axi4s.tready ) begin
                tuser  <= s_axi4s.tuser ;
                tlast  <= s_axi4s.tlast ;
                for ( int i = 0; i < CHANNELS; i = i + 1 ) begin
                    if ( enable ) begin
                        tdata[i] <= clip_value(s_axi4s.tdata[i*RAW_BITS +: RAW_BITS]);
                    end
                    else begin
                        tdata[i] <= s_axi4s.tdata[i*RAW_BITS +: RAW_BITS];
                    end
                end
                tvalid <= s_axi4s.tvalid;
            end
        end
    end

    assign s_axi4s.tready = !m_axi4s.tvalid || m_axi4s.tready;

    assign m_axi4s.tuser  = tuser ;
    assign m_axi4s.tlast  = tlast ;
    assign m_axi4s.tdata  = tdata ;
    assign m_axi4s.tvalid = tvalid;

endmodule


`default_nettype wire


// end of file
