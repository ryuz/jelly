// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_hazard_control
        #(
            parameter   int     SRCS        = 3                     ,
            parameter   int     EXES        = 4                     ,
            parameter   int     INDEX_BITS  = 8                     ,           
            parameter   type    index_t     = logic [INDEX_BITS-1:0],
            parameter           DEVICE      = "RTL"                 ,
            parameter           SIMULATION  = "false"               ,
            parameter           DEBUG       = "false"               
        )
        (
            input   var logic               reset       ,
            input   var logic               clk         ,
            input   var logic               cke         ,

            // executions
            input   var logic   [EXES-1:0]  exe_en      ,
            input   var index_t [EXES-1:0]  exe_idx     ,

            // writeback
//            input   var logic               wb_en     ,
//            input   var index_t             wb_idx    ,

            // input
            input   var logic   [SRCS-1:0]  s_src_en    ,
            input   var index_t [SRCS-1:0]  s_src_idx   ,
            input   var logic               s_dst_en    ,
            input   var index_t             s_dst_idx   ,
            input   var logic               s_valid     ,
            output  var logic               s_wait      ,

            // output
            output  var logic   [SRCS-1:0]  m_src_en    ,
            output  var index_t [SRCS-1:0]  m_src_idx   ,
            output  var logic               m_dst_en    ,
            output  var index_t             m_dst_idx   ,
            output  var logic               m_valid     ,
            input   var logic               m_wait      
        );

    // stage 0
    logic   [SRCS-1:0]  st0_src_en    ;
    index_t [SRCS-1:0]  st0_src_idx   ;
    logic               st0_dst_en    ;
    index_t             st0_dst_idx   ;
    logic               st0_valid     ;
    logic               st0_stall     , st0_stall_next;

    always_comb begin
        if ( st0_stall ) begin
            st0_stall_next = 0;
            for ( int i = 0; i < EXES; i++ ) begin
                if ( st0_src_en[i] && exe_en[i] && st0_src_idx[i] == exe_idx[i] ) begin
                    st0_stall_next = 1;
                end
            end
        end
        else begin
            st0_stall_next = 0;
            for ( int i = 0; i < EXES; i++ ) begin
                if ( s_src_en[i] && exe_en[i] && s_src_idx[i] == exe_idx[i] ) begin
                    st0_stall_next = 1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            st0_src_en    <= '0;
            st0_src_idx   <= 'x;
            st0_dst_en    <= '0;
            st0_dst_idx   <= 'x;
            st0_valid     <= '0;
            st0_stall     <= '0;
        end
        else if ( cke && !m_wait ) begin
            if ( !s_wait ) begin
                st0_src_en    <= s_valid ? s_src_en : '0;
                st0_src_idx   <= s_src_idx;
                st0_dst_en    <= s_valid ? s_dst_en : '0;
                st0_dst_idx   <= s_dst_idx;
                st0_valid     <= s_valid;
            end
        end
        st0_stall <= st0_stall_next;
    end

    assign s_wait = st0_stall || m_wait;


    assign m_src_en  = st0_src_en   ;
    assign m_src_idx = st0_src_idx  ;
    assign m_dst_en  = st0_dst_en   ;
    assign m_dst_idx = st0_dst_idx  ;
    assign m_valid   = st0_valid    ;

endmodule


`default_nettype wire


// End of file
