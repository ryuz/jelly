// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

// パケットの先頭
// パケットの末尾
// 直接伝搬するユーザーデータ
// パケットの単位で付与するフラグ
// バッファリングするデータ

// Histry buffer
module jelly3_histry_buffer_mem
        #(
            parameter   int     N            = 3                                ,
            parameter   int     USER_BITS    = 8                                ,
            parameter   type    user_t       = logic    [USER_BITS-1:0]         ,
            parameter   int     FLAG_BITS    = 1                                ,
            parameter   type    flag_t       = logic    [FLAG_BITS-1:0]         ,
            parameter   int     DATA_BITS    = 8                                ,
            parameter   type    data_t       = logic    [DATA_BITS-1:0]         ,
            parameter   int     BUF_SIZE     = 1024                             ,
            parameter   bit     SDP          = BUF_SIZE > 64                    ,
            parameter           RAM_TYPE     = SDP ? "block" : "distributed"    ,
            parameter   bit     DOUT_REG     = SDP                              
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

    if ( SDP ) begin : sdp
        jelly3_histry_buffer_mem_sdp
                #(
                    .N          (N          ),
                    .USER_BITS  (USER_BITS  ),
                    .user_t     (user_t     ),
                    .FLAG_BITS  (FLAG_BITS  ),
                    .flag_t     (flag_t     ),
                    .DATA_BITS  (DATA_BITS  ),
                    .data_t     (data_t     ),
                    .BUF_SIZE   (BUF_SIZE   ),
                    .RAM_TYPE   (RAM_TYPE   ),
                    .DOUT_REG   (DOUT_REG   )
                )
            u_histry_buffer_mem_sdp
                (
                    .reset      ,
                    .clk        ,
                    .cke        ,
                    
                    .s_first    ,
                    .s_user     ,
                    .s_flag     ,
                    .s_data     ,
                    .s_valid    ,
                    
                    .m_first    ,
                    .m_user     ,
                    .m_flag     ,
                    .m_data     ,
                    .m_valid    
                );
    end
    else begin : rf
        jelly3_histry_buffer_mem_rf
                #(
                    .N          (N          ),
                    .USER_BITS  (USER_BITS  ),
                    .user_t     (user_t     ),
                    .FLAG_BITS  (FLAG_BITS  ),
                    .flag_t     (flag_t     ),
                    .DATA_BITS  (DATA_BITS  ),
                    .data_t     (data_t     ),
                    .BUF_SIZE   (BUF_SIZE   ),
                    .RAM_TYPE   (RAM_TYPE   ),
                    .DOUT_REG   (DOUT_REG   )
                )
            u_histry_buffer_mem_rf
                (
                    .reset      ,
                    .clk        ,
                    .cke        ,
                    
                    .s_first    ,
                    .s_user     ,
                    .s_flag     ,
                    .s_data     ,
                    .s_valid    ,
                    
                    .m_first    ,
                    .m_user     ,
                    .m_flag     ,
                    .m_data     ,
                    .m_valid    
                );
    end
    
endmodule


// End of file
