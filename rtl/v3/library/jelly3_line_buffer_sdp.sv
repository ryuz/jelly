// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// Line buffer with Simple Dualport-RAM
module jelly3_line_buffer_sdp
        #(
            parameter   int     N            = 3                            ,
            parameter   int     USER_BITS    = 8                            ,
            parameter   type    user_t       = logic    [USER_BITS-1:0]     ,
            parameter   int     DATA_BITS    = 8                            ,
            parameter   type    data_t       = logic    [DATA_BITS-1:0]     ,
            parameter   int     BUF_SIZE     = 1024                         ,
            parameter           RAM_TYPE     = "block"                      ,
            parameter   bit     DOUT_REG     = 1'b1                         
        )
        (
            input   var logic           reset   ,
            input   var logic           clk     ,
            input   var logic           cke     ,

            input   var user_t          s_user  ,
            input   var data_t          s_data  ,
            input   var logic           s_last  ,
            input   var logic           s_valid ,

            output  var user_t  [N-1:0] m_user  ,
            output  var data_t  [N-1:0] m_data  ,
            output  var logic           m_first ,
            output  var logic           m_last  ,
            output  var logic   [N-1:0] m_valid 
        );

    if ( N == 1 ) begin : blk_bypass
        assign m_user[0] = s_user;
        assign m_data[0] = s_data;
        assign m_last    = s_last;
        assign m_valid   = s_valid;
    end
    else begin : blk_line_buffer

        localparam  type    addr_t  = logic [$clog2(BUF_SIZE)-1:0];

        addr_t          wr_addr;
        data_t  [N-2:0] wr_data;
        addr_t          rd_addr;
        data_t  [N-2:0] rd_data;

        for ( genvar i = 0; i < N-1; i++ ) begin : ram
            jelly3_ram_simple_dualport
                    #(
                        .addr_t     (addr_t     ),
                        .data_t     (data_t     ),
                        .MEM_DEPTH  (BUF_SIZE   ),
                        .RAM_TYPE   (RAM_TYPE   ),
                        .DOUT_REG   (DOUT_REG   )
                    )
                u_ram_simple_dualport
                    (
                        .wr_clk     (clk        ),
                        .wr_en      (cke        ),
                        .wr_addr    (wr_addr    ),
                        .wr_din     (wr_data[i] ),
                
                        .rd_clk     (clk        ),
                        .rd_en      (cke        ),
                        .rd_regcke  (cke        ),
                        .rd_addr    (rd_addr    ),
                        .rd_dout    (rd_data[i] )
                    );
        end

        logic   s_first     ;

        addr_t  st0_addr    ;
        user_t  st0_user    ;
        data_t  st0_data    ;
        logic   st0_first   ;
        logic   st0_last    ;
        logic   st0_valid   ;

        addr_t  st1_addr    ;
        user_t  st1_user    ;
        data_t  st1_data    ;
        logic   st1_first   ;
        logic   st1_last    ;
        logic   st1_valid   ;

        addr_t  st2_addr    ;
        user_t  st2_user    ;
        data_t  st2_data    ;
        logic   st2_first   ;
        logic   st2_last    ;
        logic   st2_valid   ;

        // generate first flag
        always_ff @(posedge clk) begin
            if ( reset ) begin
                s_first   <= 1'b1;
            end
            else if ( cke ) begin
                if ( s_valid ) begin
                    s_first <= s_last;
                end
            end
        end

        // stage 0
        always_ff @(posedge clk) begin
            if ( reset ) begin
                st0_addr  <= 'x;
                st0_user  <= 'x;
                st0_data  <= 'x;
                st0_first <= 'x;
                st0_last  <= 'x;
                st0_valid <= 1'b0;
            end
            else if ( cke ) begin
                // stage 0
                st0_addr  <= st0_addr + st0_valid;
                if ( s_valid && s_first ) begin
                    st0_addr <= '0  ;
                end
                st0_user  <= s_user ;
                st0_data  <= s_data ;
                st0_first <= s_first;
                st0_last  <= s_last ;
                st0_valid <= s_valid;
            end
        end

        // memory read
        assign rd_addr = st0_addr;

        // stage 1
        if ( DOUT_REG ) begin : blk_stage1_reg
            always_ff @(posedge clk) begin
                if ( reset ) begin
                    st1_addr  <= 'x;
                    st1_user  <= 'x;
                    st1_data  <= 'x;
                    st1_first <= 'x;
                    st1_last  <= 'x;
                    st1_valid <= 1'b0;
                end
                else if ( cke ) begin
                    st1_addr  <= st0_addr   ;
                    st1_user  <= st0_user   ;
                    st1_data  <= st0_data   ;
                    st1_first <= st0_first  ;
                    st1_last  <= st0_last   ;
                    st1_valid <= st0_valid  ;
                end
            end
        end
        else begin : blk_stage1
            assign st1_addr  = st0_addr   ;
            assign st1_user  = st0_user   ;
            assign st1_data  = st0_data   ;
            assign st1_first = st0_first  ;
            assign st1_last  = st0_last   ;
            assign st1_valid = st0_valid  ;
        end

        // stage 2
        always_ff @(posedge clk) begin
            if ( reset ) begin
                st2_addr  <= 'x;
                st2_user  <= 'x;
                st2_data  <= 'x;
                st2_first <= 'x;
                st2_last  <= 'x;
                st2_valid <= 1'b0;
            end
            else if ( cke ) begin
                // stage 0
                st2_addr  <= st1_addr ;
                st2_user  <= st1_user ;
                st2_data  <= st1_data ;
                st2_first <= st1_first;
                st2_last  <= st1_last ;
                st2_valid <= st1_valid;
            end
        end

        // user memory
        user_t  [N-1:0]     mem_user    ;
        logic   [N-1:0]     mem_valid   ;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                for ( int i = 0; i < N; i++ ) begin
                    mem_user [i] <= 'x;
                    mem_valid[i] <= '0;
                end
            end
            else if ( cke ) begin
                if ( st1_valid && st1_first ) begin
                    for ( int i = 0; i < N-1; i++ ) begin
                        mem_user [i] <= mem_user [i+1];
                        mem_valid[i] <= mem_valid[i+1];
                    end
                    mem_user [N-1] <= st1_user  ;
                    mem_valid[N-1] <= st1_valid ;
                end
            end
        end

        // write memory
        assign wr_addr = st2_addr;
        for ( genvar i = 0; i < N-1; i++ ) begin
            assign wr_data[i] = m_data[i+1];
        end

        // output
        for ( genvar i = 0; i < N-1; i++ ) begin
            assign m_data[i] = rd_data[i];
        end
        assign m_data[N-1] = st2_data       ;
        assign m_user      = mem_user       ;
        assign m_last      = st2_last       ;
        assign m_valid     = mem_valid      ;
    end

    
endmodule


// End of file
