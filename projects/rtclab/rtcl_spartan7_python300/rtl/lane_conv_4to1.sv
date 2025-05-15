// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

module lane_conv_4to1
        (
            jelly3_axi4s_if.s   s_axi4s ,
            jelly3_axi4s_if.m   m_axi4s  
        );
    

    logic   [1:0]   phase   ;
    logic           tuser   ;
    logic           tlast   ;
    logic   [39:0]  tdata   ;
    logic           tvalid  ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            phase   <= '0   ;
            tuser   <= 1'bx ;
            tlast   <= 1'bx ;
            tdata   <= 'x   ;
            tvalid  <= 1'b0 ;
        end
        else if ( s_axi4s.aclken ) begin
            if ( m_axi4s.tvalid && m_axi4s.tready ) begin
                phase <= phase + 1;
                tdata <= tdata >> 10;
                if ( phase == 2'd3 ) begin
                    tvalid <= 1'b0;
                end
            end
            if ( s_axi4s.tvalid || s_axi4s.tready ) begin
                phase   <= '0               ;
                tuser   <= s_axi4s.tuser    ;
                tlast   <= s_axi4s.tlast    ;
                tdata   <= s_axi4s.tdata    ;
                tvalid  <= s_axi4s.tvalid   ;
            end
        end
    end

    assign s_axi4s.tready = !m_axi4s.tvalid || (m_axi4s.tready && phase == 2'd3);

    assign m_axi4s.tuser  = tvalid ? tuser && phase == 2'd0 : 'x;
    assign m_axi4s.tlast  = tvalid ? tlast && phase == 2'd3 : 'x;
    assign m_axi4s.tdata  = tvalid ? tdata[9:0]             : 'x;
    assign m_axi4s.tvalid = tvalid;

endmodule


`default_nettype wire


// end of file
