// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// DPHYの受信
module jelly3_mipi_dphy_recv
        #(
            parameter   int     LANES           = 2         ,
            parameter           DEVICE         = "RTL"      ,
            parameter           SIMULATION     = "false"    ,
            parameter           DEBUG          = "false"    
        )
        (
            // input
            input   var logic   [LANES-1:0][7:0]    rxdatahs    ,
            input   var logic   [LANES-1:0]         rxvalidhs   ,   // syncコードでは立たない
            input   var logic   [LANES-1:0]         rxactivehs  ,   // hs期間
            input   var logic   [LANES-1:0]         rxsynchs    ,   // syncコード

            // output
            jelly3_axi4s_if.m                       m_axi4s     
        );

    // parameter check
    initial begin
        if (m_axi4s.DATA_BITS != LANES*8) begin
            $error("m_axi4s.DATA_BITS must be %0d, but it is %0d", LANES*8, m_axi4s.DATA_BITS);
        end
    end


    logic   [LANES-1:0][7:0]    st0_rxdatahs    ;
    logic   [LANES-1:0]         st0_rxvalidhs   ;
    logic   [LANES-1:0]         st0_rxactivehs  ;
    logic   [LANES-1:0]         st0_rxsynchs    ;
    
    logic                       st1_busy        ;
    logic   [LANES*8-1:0]       st1_data        ;
    logic                       st1_first       ;
    logic                       st1_last        ;
    logic                       st1_valid       ;
    
    always_ff @(posedge m_axi4s.aclk) begin
        if ( ~m_axi4s.aresetn ) begin
            st0_rxdatahs   <= 'x    ;
            st0_rxvalidhs  <= '0    ;
            st0_rxactivehs <= '0    ;
            st0_rxsynchs   <= '0    ;
            
            st1_busy       <= 1'b0  ;
            st1_data       <= 'x    ;
            st1_first      <= 1'bx  ;
            st1_last       <= 1'bx  ;
            st1_valid      <= 1'b0  ;
        end
        else begin
            // stage 0
            st0_rxdatahs   <= rxdatahs  ;
            st0_rxvalidhs  <= rxvalidhs ;
            st0_rxactivehs <= rxactivehs;
            st0_rxsynchs   <= rxsynchs  ;
            
            
            // stage 1
            if ( &st0_rxsynchs & &rxactivehs ) begin
                st1_busy <= 1'b1;
            end
            else if ( st1_valid & st1_last ) begin
                st1_busy <= 1'b0;
            end
            
            if ( &st0_rxsynchs & &rxactivehs ) begin
                st1_first <= 1'b1;
            end
            else if ( st1_valid ) begin
                st1_first <= 1'b0;
            end
            
            st1_last  <= ((rxactivehs == 0) || (rxvalidhs == 0) | (rxsynchs != 0));
            st1_data  <= st0_rxdatahs;
            st1_valid <= ((st0_rxvalidhs != 0) && st1_busy);
        end
    end
    
    assign m_axi4s.tuser[0] = st1_first ;
    assign m_axi4s.tlast    = st1_last  ;
    assign m_axi4s.tdata    = st1_data  ;
    assign m_axi4s.tvalid   = st1_valid ;
    
endmodule


`default_nettype wire


// end of file
