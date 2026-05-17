// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// 許可した分だけデータを通すゲート (ラッパー)
//   - BYPASS path  : データを素通しし、必要なら permit と combine する
//   - Gate  path  : 入出力FF の挿入 + jelly3_stream_gate_core への委譲
//   - 非同期FIFO (permit パス CDC) はパスに関わらずここで処理する
// first や last は 上位次元でbitが立っているとき下位次元は必ず立っているとみなす
module jelly3_stream_gate
        #(
            parameter   int                 N               = 1         ,   // 次元数(dimension)
            parameter   bit                 BYPASS          = 0         ,   // バイパス
            parameter   bit                 BYPASS_COMBINE  = 0         ,   // バイパス時にpermitもcombineするか
            parameter   bit                 DETECTOR_ENABLE = 0         ,   // フラグ検出器(読み飛ばし/パディング)を使うか
            parameter   bit     [N-1:0]     AUTO_FIRST      = {N{1'b1}} ,   // lastの後を自動的にfirst扱いにする
            
            parameter   int                 DATA_BITS       = 32        ,
            parameter   type                data_t          = logic [DATA_BITS-1:0],
            parameter   int                 LEN_BITS        = 32        ,
            parameter   type                len_t           = logic [LEN_BITS-1:0],
            parameter   bit                 LEN_OFFSET      = 1'b1      ,
            parameter   int                 USER_BITS       = 1         ,
            parameter   type                user_t          = logic [USER_BITS-1:0],
            parameter   bit                 S_REG           = 1         ,
            parameter   bit                 M_REG           = 1         ,

            parameter   bit                 ASYNC           = 0         ,
            parameter   int                 FIFO_PTR_BITS   = ASYNC ? 4 : 0,
            parameter   bit                 FIFO_DOUT_REG   = 0         ,
            parameter                       FIFO_RAM_TYPE   = "distributed",
            parameter   int                 FIFO_S_SYNC_FF  = 2         ,
            parameter   int                 FIFO_M_SYNC_FF  = 2         
        )
        (
            input   var logic               reset           ,
            input   var logic               clk             ,
            input   var logic               cke             ,

            input   var logic               skip            ,   // 非busy時に読み飛ばす
            input   var logic   [N-1:0]     detect_first    ,
            input   var logic   [N-1:0]     detect_last     ,
            input   var logic               padding_en      ,
            input   var data_t              padding_data    ,

            // stream slave
            input   var logic   [N-1:0]     s_first         ,
            input   var logic   [N-1:0]     s_last          ,
            input   var data_t              s_data          ,
            input   var logic               s_valid         ,
            output  var logic               s_ready         ,

            // stream master
            output  var logic   [N-1:0]     m_first         ,
            output  var logic   [N-1:0]     m_last          ,
            output  var data_t              m_data          ,
            output  var user_t              m_user          ,
            output  var logic               m_valid         ,
            input   var logic               m_ready         ,

            // permit slave (may be on a different clock when ASYNC=1)
            input   var logic               s_permit_reset  ,
            input   var logic               s_permit_clk    ,
            input   var logic               s_permit_cke    ,
            input   var logic   [N-1:0]     s_permit_first  ,
            input   var logic   [N-1:0]     s_permit_last   ,
            input   var len_t               s_permit_len    ,
            input   var user_t              s_permit_user   ,
            input   var logic               s_permit_valid  ,
            output  var logic               s_permit_ready  
        );

    // -----------------------------------------------------------------
    //  permit FIFO  (CDC or synchronous pass-through)
    // -----------------------------------------------------------------

    logic   [N-1:0] permit_fifo_first;
    logic   [N-1:0] permit_fifo_last ;
    len_t           permit_fifo_len  ;
    user_t          permit_fifo_user ;
    logic           permit_fifo_valid;
    logic           permit_fifo_ready;

    if ( ASYNC ) begin : blk_permit_fifo
        jelly3_stream_fifo
                #(
                    .ASYNC          (1                          ),
                    .PTR_BITS       (FIFO_PTR_BITS              ),
                    .DATA_BITS      ($bits(permit_fifo_first)
                                    + $bits(permit_fifo_last)
                                    + $bits(permit_fifo_len )
                                    + $bits(permit_fifo_user)),
                    .DOUT_REG       (FIFO_DOUT_REG              ),
                    .RAM_TYPE       (FIFO_RAM_TYPE              ),
                    .S_SYNC_FF      (FIFO_S_SYNC_FF             ),
                    .M_SYNC_FF      (FIFO_M_SYNC_FF             )
                )
            u_permit_fifo
                (
                    .s_reset        (s_permit_reset             ),
                    .s_clk          (s_permit_clk               ),
                    .s_cke          (s_permit_cke               ),
                    .s_data         ({
                                        s_permit_first  ,
                                        s_permit_last   ,
                                        s_permit_len    ,
                                        s_permit_user
                                    }),
                    .s_valid        (s_permit_valid             ),
                    .s_ready        (s_permit_ready             ),
                    .s_free_size    (                           ),

                    .m_reset        (reset                      ),
                    .m_clk          (clk                        ),
                    .m_cke          (cke                        ),
                    .m_data         ({
                                        permit_fifo_first  ,
                                        permit_fifo_last   ,
                                        permit_fifo_len    ,
                                        permit_fifo_user
                                    }),
                    .m_valid        (permit_fifo_valid          ),
                    .m_ready        (permit_fifo_ready          ),
                    .m_data_size    (                           )
                );
    end
    else begin : blk_permit_sync
        assign permit_fifo_first = s_permit_first   ;
        assign permit_fifo_last  = s_permit_last    ;
        assign permit_fifo_len   = s_permit_len     ;
        assign permit_fifo_user  = s_permit_user    ;
        assign permit_fifo_valid = s_permit_valid   ;
        assign s_permit_ready    = permit_fifo_ready;
    end


    // -----------------------------------------------------------------
    //  BYPASS path  /  Gate path
    // -----------------------------------------------------------------

    if ( BYPASS ) begin : blk_bypass
        // データはそのまま通過させる
        assign m_first           = s_first                                                      ;
        assign m_last            = s_last                                                       ;
        assign m_data            = s_data                                                       ;
        assign m_user            = BYPASS_COMBINE ? permit_fifo_user                : '0        ;
        assign m_valid           = BYPASS_COMBINE ? (s_valid & permit_fifo_valid)   : s_valid   ;
        assign s_ready           = BYPASS_COMBINE ? (m_ready & permit_fifo_valid)   : m_ready   ;
        assign permit_fifo_ready = BYPASS_COMBINE ? (m_ready & s_valid & s_last[0]) : 1'b1      ;
    end
    else begin : blk_gate

        // ---- 入力FF ----
        logic [N-1:0]   s_ff_s_first;
        logic [N-1:0]   s_ff_s_last ;
        data_t          s_ff_s_data ;
        logic [N-1:0]   s_ff_m_first;
        logic [N-1:0]   s_ff_m_last ;
        data_t          s_ff_m_data ;
        logic   core_s_valid;
        logic   core_s_ready;

        assign s_ff_s_first   = s_first;
        assign s_ff_s_last    = s_last ;
        assign s_ff_s_data    = s_data ;

        jelly3_stream_ff
                #(
                    .DATA_BITS      (2*N + $bits(data_t)                 ),
                    .S_REG          (S_REG          ),
                    .M_REG          (0              )
                )
            u_stream_ff_s
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    .cke            (cke            ),
                    .s_data         ({
                                        s_ff_s_first,
                                        s_ff_s_last ,
                                        s_ff_s_data
                                    }),
                    .s_valid        (s_valid        ),
                    .s_ready        (s_ready        ),
                    .m_data         ({
                                        s_ff_m_first,
                                        s_ff_m_last ,
                                        s_ff_m_data
                                    }),
                    .m_valid        (core_s_valid   ),
                    .m_ready        (core_s_ready   )
                );

        // ---- 出力FF ----
        logic [N-1:0]   m_ff_s_first;
        logic [N-1:0]   m_ff_s_last ;
        data_t          m_ff_s_data ;
        user_t          m_ff_s_user ;
        logic [N-1:0]   m_ff_m_first;
        logic [N-1:0]   m_ff_m_last ;
        data_t          m_ff_m_data ;
        user_t          m_ff_m_user ;
        logic   core_m_valid;
        logic   core_m_ready;

        jelly3_stream_ff
                #(
                    .DATA_BITS      (2*N
                                    + $bits(data_t)
                                    + $bits(user_t) ),
                    .S_REG          (0              ),
                    .M_REG          (M_REG          )
                )
            u_stream_ff_m
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    .cke            (cke            ),
                    .s_data         ({
                                        m_ff_s_first,
                                        m_ff_s_last ,
                                        m_ff_s_data ,
                                        m_ff_s_user
                                    }),
                    .s_valid        (core_m_valid   ),
                    .s_ready        (core_m_ready   ),
                    .m_data         ({
                                        m_ff_m_first,
                                        m_ff_m_last ,
                                        m_ff_m_data ,
                                        m_ff_m_user
                                    }),
                    .m_valid        (m_valid        ),
                    .m_ready        (m_ready        )
                );

        assign m_first = m_ff_m_first;
        assign m_last  = m_ff_m_last ;
        assign m_data  = m_ff_m_data ;
        assign m_user  = m_ff_m_user ;

        // ---- core ----
        logic [N-1:0]   core_m_first;
        logic [N-1:0]   core_m_last ;
        data_t          core_m_data ;
        user_t          core_m_user ;

        assign m_ff_s_first = core_m_first;
        assign m_ff_s_last  = core_m_last ;
        assign m_ff_s_data  = core_m_data ;
        assign m_ff_s_user  = core_m_user ;

        jelly3_stream_gate_core
                #(
                    .N              (N                          ),
                    .DETECTOR_ENABLE(DETECTOR_ENABLE            ),
                    .AUTO_FIRST     (AUTO_FIRST                 ),
                    .DATA_BITS      (DATA_BITS                  ),
                    .data_t         (data_t                     ),
                    .LEN_BITS       (LEN_BITS                   ),
                    .len_t          (len_t                      ),
                    .LEN_OFFSET     (LEN_OFFSET                 ),
                    .USER_BITS      (USER_BITS                  ),
                    .user_t         (user_t                     )
                )
            u_gate_core
                (
                    .reset          (reset                      ),
                    .clk            (clk                        ),
                    .cke            (cke                        ),

                    .skip           (skip                       ),
                    .detect_first   (detect_first               ),
                    .detect_last    (detect_last                ),
                    .padding_en     (padding_en                 ),
                    .padding_data   (padding_data               ),

                    .s_first        (s_ff_m_first               ),
                    .s_last         (s_ff_m_last                ),
                    .s_data         (s_ff_m_data                ),
                    .s_valid        (core_s_valid               ),
                    .s_ready        (core_s_ready               ),

                    .m_first        (core_m_first               ),
                    .m_last         (core_m_last                ),
                    .m_data         (core_m_data                ),
                    .m_user         (core_m_user                ),
                    .m_valid        (core_m_valid               ),
                    .m_ready        (core_m_ready               ),

                    .s_permit_first (permit_fifo_first          ),
                    .s_permit_last  (permit_fifo_last           ),
                    .s_permit_len   (permit_fifo_len            ),
                    .s_permit_user  (permit_fifo_user           ),
                    .s_permit_valid (permit_fifo_valid          ),
                    .s_permit_ready (permit_fifo_ready          )
                );
    end


    // -----------------------------------------------------------------
    //  simulation counter (permit clk ドメイン)
    // -----------------------------------------------------------------

    // verilator lint_off UNUSEDSIGNAL
    int count_permit_len;
    always_ff @(posedge s_permit_clk) begin
        if ( s_permit_reset ) begin
            count_permit_len <= 0;
        end
        else begin
            if ( s_permit_valid & s_permit_ready ) begin
                count_permit_len <= count_permit_len + int'(s_permit_len) + int'(LEN_OFFSET);
            end
        end
    end
    // verilator lint_on UNUSEDSIGNAL


endmodule


`default_nettype wire


// end of file
