// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// firstフラグ自動生成(多次元対応版)
module jelly3_stream_auto_first
        #(
            parameter   bit     AUTO_FIRST  = 1                     ,
            parameter   int     N           = 1                     ,
            parameter   int     DATA_BITS   = 8                     ,
            parameter   type    data_t      = logic [DATA_BITS-1:0] 
        )
        (
            input   var logic           reset       ,
            input   var logic           clk         ,
            input   var logic           cke         ,
            
            // slave port
            input   var logic   [N-1:0] s_first     ,
            input   var logic   [N-1:0] s_last      ,
            input   var data_t          s_data      ,
            input   var logic           s_valid     ,
            output  var logic           s_ready     ,
            
            // master port
            output  var logic   [N-1:0] m_first     ,
            output  var logic   [N-1:0] m_last      ,
            output  var data_t          m_data      ,
            output  var logic           m_valid     ,
            input   var logic           m_ready     
        );
    
    
    
    logic   [N-1:0]     first;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            first <= '1;
        end
        else if ( cke ) begin
            for ( int i = 0; i < N; i++ ) begin
                if ( s_valid && s_ready) begin
                    first[i] <= s_last[i];
                end
            end
        end
    end

    assign m_first = AUTO_FIRST ? first : s_first;
    assign m_last  = s_last ;
    assign m_data  = s_data ;
    assign m_valid = s_valid;
    assign s_ready = m_ready;
    
endmodule


`default_nettype wire


// end of file
