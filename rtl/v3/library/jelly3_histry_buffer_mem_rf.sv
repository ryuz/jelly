// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// Histry buffer with Read-First RAM
module jelly3_histry_buffer_mem_rf
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

            input   var logic           s_first ,
            input   var logic           s_last  ,
            input   var user_t          s_user  ,
            input   var data_t          s_data  ,
            input   var logic           s_valid ,

            output  var logic           m_first ,
            output  var logic           m_last  ,
            output  var user_t  [N-1:0] m_user  ,
            output  var data_t  [N-1:0] m_data  ,
            output  var logic   [N-1:0] m_valid 
        );

    if ( N == 1 ) begin : blk_bypass
        assign m_first   = s_first  ;
        assign m_last    = s_last   ;
        assign m_user[0] = s_user   ;
        assign m_data[0] = s_data   ;
        assign m_valid   = s_valid  ;
    end
    else begin : blk_line_buffer
        localparam  int     ADDR_BITS = $clog2(BUF_SIZE)        ;
        localparam  type    addr_t    = logic [ADDR_BITS-1:0]   ;

        logic   [N-2:0] ram_we      ;
        addr_t  [N-2:0] ram_addr    ;
        data_t  [N-2:0] ram_din     ;
        data_t  [N-2:0] ram_dout    ;

        for ( genvar i = 0; i < N-1; i++ ) begin : ram
            jelly3_ram_singleport
                    #(
                        .addr_t     (addr_t         ),
                        .data_t     (data_t         ),
                        .MEM_DEPTH  (BUF_SIZE       ),
                        .RAM_TYPE   (RAM_TYPE       ),
                        .MODE       ("READ_FIRST"   ),
                        .DOUT_REG   (DOUT_REG       )
                    )
                u_ram_singleport
                    (
                        .clk        (clk           ),
                        .en         (cke           ),
                        .regcke     (cke           ),
                        .we         (ram_we  [i]   ),
                        .addr       (ram_addr[i]   ),
                        .din        (ram_din [i]   ),
                        .dout       (ram_dout[i]   )
                    );
        end

        localparam  int STEP   = DOUT_REG ? 2 : 1   ;
        localparam  int STAGES = (N-1) * STEP + 1   ;

        addr_t  [STAGES-1:0]        st_addr ;
        logic   [STAGES-1:0]        st_first;
        logic   [STAGES-1:0]        st_last ;
        user_t  [STAGES-1:0]        st_user ;
        data_t  [STAGES-1:0][N-1:0] st_data ;
        logic   [STAGES-1:0]        st_valid;

        always_ff @(posedge clk) begin
            if ( reset ) begin
                st_addr  <= 'x;
                st_first <= 'x;
                st_last  <= 'x;
                st_user  <= 'x;
                st_data  <= 'x;
                st_valid <= '0;
            end
            else if ( cke ) begin
                // stage 0
                st_addr[0]  <= st_addr[0] + addr_t'(st_valid[0]);
                if ( s_valid && s_first ) begin
                    st_addr[0] <= '0;
                end
                st_first[0]      <= s_first;
                st_last [0]      <= s_last ;
                st_user [0]      <= s_user ;
                st_data [0][N-1] <= s_data ;
                st_valid[0]      <= s_valid;

                for ( int i = 1; i < STAGES; i++ ) begin
                    st_addr [i] <= st_addr [i-1];
                    st_user [i] <= st_user [i-1];
                    st_data [i] <= st_data [i-1];
                    st_first[i] <= st_first[i-1];
                    st_last [i] <= st_last [i-1];
                    st_valid[i] <= st_valid[i-1];
                end
                for ( int i = 1; i < N-1; i++ ) begin
                    st_data[STAGES-i*STEP][i] <= ram_dout[i];
                end
            end
        end

        // memory write
        assign ram_we  [N-2] = st_valid[0];
        assign ram_addr[N-2] = st_addr [0];
        assign ram_din [N-2] = st_data [0][N-1];
        for ( genvar i = 1; i < N-1; i++ ) begin
            assign ram_we  [N-2-i] = st_valid[i*STEP];
            assign ram_addr[N-2-i] = st_addr [i*STEP];
            assign ram_din [N-2-i] = ram_dout[N-1-i];
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
                if ( st_valid[STAGES-2] && st_first[STAGES-2] ) begin
                    for ( int i = 0; i < N-1; i++ ) begin
                        mem_user [i] <= mem_user [i+1];
                        mem_valid[i] <= mem_valid[i+1];
                    end
                    mem_user [N-1] <= st_user [STAGES-2] ;
                    mem_valid[N-1] <= st_valid[STAGES-2] ;
                end
            end
        end

        // output
        assign m_first   = st_first[STAGES-1];
        assign m_last    = st_last[STAGES-1];
        assign m_data[0] = ram_dout[0]      ;
        for ( genvar i = 1; i < N; i++ ) begin
            assign m_data[i] = st_data[STAGES-1][i];
        end
        assign m_user    = mem_user         ;
        assign m_valid   = mem_valid        ;
    end
    
endmodule


// End of file
