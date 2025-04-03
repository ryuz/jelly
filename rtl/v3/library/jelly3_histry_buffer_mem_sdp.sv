// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// Histry buffer with Simple Dualport-RAM
module jelly3_histry_buffer_mem_sdp
        #(
            parameter   int     N            = 3                            ,
            parameter   int     USER_BITS    = 8                            ,
            parameter   type    user_t       = logic    [USER_BITS-1:0]     ,
            parameter   int     FLAG_BITS    = 1                            ,
            parameter   type    flag_t       = logic    [FLAG_BITS-1:0]     ,
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

            input   var logic           s_first ,
            input   var user_t          s_user  ,
            input   var flag_t          s_flag  ,
            input   var data_t          s_data  ,
            input   var logic           s_valid ,

            output  var logic           m_first ,
            output  var user_t          m_user  ,
            output  var flag_t  [N-1:0] m_flag  ,
            output  var data_t  [N-1:0] m_data  ,
            output  var logic   [N-1:0] m_valid 
        );

    if ( N == 1 ) begin : blk_bypass
        assign m_first = s_first;
        assign m_user  = s_user ;
        assign m_flag  = s_flag ;
        assign m_data  = s_data ;
        assign m_valid = s_valid;
    end
    else begin : blk_line_buffer
        localparam  int     ADDR_BITS = $clog2(BUF_SIZE)        ;
        localparam  type    addr_t    = logic [ADDR_BITS-1:0]   ;

        logic           wr_en  ;
        addr_t          wr_addr;
        data_t  [N-2:0] wr_data;
        addr_t          rd_addr;
        data_t  [N-2:0] rd_data;

        jelly3_ram_simple_dualport
                #(
                    .ADDR_BITS  ($bits(wr_addr) ),
                    .DATA_BITS  ($bits(wr_data) ),
                    .MEM_DEPTH  (BUF_SIZE       ),
                    .RAM_TYPE   (RAM_TYPE       ),
                    .DOUT_REG   (DOUT_REG       )
                )
            u_ram_simple_dualport
                (
                    .wr_clk     (clk            ),
                    .wr_en      (wr_en          ),
                    .wr_addr    (wr_addr        ),
                    .wr_din     (wr_data        ),
            
                    .rd_clk     (clk            ),
                    .rd_en      (cke            ),
                    .rd_regcke  (cke            ),
                    .rd_addr    (rd_addr        ),
                    .rd_dout    (rd_data        )
                );

        addr_t  st0_addr    ;
        logic   st0_first   ;
        user_t  st0_user    ;
        flag_t  st0_flag    ;
        data_t  st0_data    ;
        logic   st0_valid   ;

        addr_t  st1_addr    ;
        logic   st1_first   ;
        user_t  st1_user    ;
        flag_t  st1_flag    ;
        data_t  st1_data    ;
        logic   st1_valid   ;

        addr_t  st2_addr    ;
        logic   st2_first   ;
        user_t  st2_user    ;
        flag_t  st2_flag    ;
        data_t  st2_data    ;
        logic   st2_valid   ;

        // stage 0
        always_ff @(posedge clk) begin
            if ( reset ) begin
                st0_addr  <= 'x;
                st0_first <= 'x;
                st0_user  <= 'x;
                st0_flag  <= 'x;
                st0_data  <= 'x;
                st0_valid <= 1'b0;
            end
            else if ( cke ) begin
                // stage 0
                st0_addr  <= st0_addr + addr_t'(st0_valid);
                if ( s_valid && s_first ) begin
                    st0_addr <= '0  ;
                end
                st0_first <= s_first;
                st0_user  <= s_user ;
                st0_flag  <= s_flag ;
                st0_data  <= s_data ;
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
                    st1_first <= 'x;
                    st1_user  <= 'x;
                    st1_flag  <= 'x;
                    st1_data  <= 'x;
                    st1_valid <= 1'b0;
                end
                else if ( cke ) begin
                    st1_addr  <= st0_addr   ;
                    st1_first <= st0_first  ;
                    st1_user  <= st0_user   ;
                    st1_flag  <= st0_flag   ;
                    st1_data  <= st0_data   ;
                    st1_valid <= st0_valid  ;
                end
            end
        end
        else begin : blk_stage1
            assign st1_addr  = st0_addr   ;
            assign st1_first = st0_first  ;
            assign st1_user  = st0_user   ;
            assign st1_flag  = st0_flag   ;
            assign st1_data  = st0_data   ;
            assign st1_valid = st0_valid  ;
        end

        // stage 2
        always_ff @(posedge clk) begin
            if ( reset ) begin
                st2_addr  <= 'x;
                st2_first <= 'x;
                st2_user  <= 'x;
                st2_flag  <= 'x;
                st2_data  <= 'x;
                st2_valid <= 1'b0;
            end
            else if ( cke ) begin
                // stage 0
                st2_addr  <= st1_addr ;
                st2_first <= st1_first;
                st2_user  <= st1_user ;
                st2_flag  <= st1_flag ;
                st2_data  <= st1_data ;
                st2_valid <= st1_valid;
            end
        end

        // flag & valid history
        flag_t  [N-1:0]     hist_flag    ;
        logic   [N-1:0]     hist_valid   ;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                for ( int i = 0; i < N; i++ ) begin
                    hist_flag [i] <= 'x;
                    hist_valid[i] <= '0;
                end
            end
            else if ( cke ) begin
                if ( st1_valid && st1_first ) begin
                    for ( int i = 0; i < N-1; i++ ) begin
                        hist_flag [i] <= hist_flag [i+1];
                        hist_valid[i] <= hist_valid[i+1];
                    end
                    hist_flag [N-1] <= st1_flag  ;
                    hist_valid[N-1] <= st1_valid ;
                end
            end
        end

        // write memory
        assign wr_en   = st2_valid;
        assign wr_addr = st2_addr;
        for ( genvar i = 0; i < N-1; i++ ) begin
            assign wr_data[i] = m_data[i+1];
        end

        // output
        assign m_first     = st2_first                  ;
        assign m_user      = st2_user                   ;
        assign m_flag      = hist_flag                  ;
        for ( genvar i = 0; i < N-1; i++ ) begin
            assign m_data[i] = rd_data[i];
        end
        assign m_data[N-1] = st2_data                   ;
        assign m_valid     = st2_valid ? hist_valid : '0;
    end

    
endmodule


// End of file
