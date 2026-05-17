// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// 許可した分だけデータを通すゲート (ラッパー)
//   - 非同期FIFO (permit パス CDC) と入出力FF の挿入を担当
//   - ゲートの本質ロジックは jelly3_stream_gate_core に委譲
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
            input   var logic               reset       ,
            input   var logic               clk         ,
            input   var logic               cke         ,

            input   var logic               skip        ,   // 非busy時に読み飛ばす
            input   var logic   [N-1:0]     detect_first,
            input   var logic   [N-1:0]     detect_last ,
            input   var logic               padding_en  ,
            input   var data_t              padding_data,

            // stream slave
            input   var logic   [N-1:0]     s_first     ,
            input   var logic   [N-1:0]     s_last      ,
            input   var data_t              s_data      ,
            input   var logic               s_valid     ,
            output  var logic               s_ready     ,

            // stream master
            output  var logic   [N-1:0]     m_first     ,
            output  var logic   [N-1:0]     m_last      ,
            output  var data_t              m_data      ,
            output  var user_t              m_user      ,
            output  var logic               m_valid     ,
            input   var logic               m_ready     ,

            // permit slave (may be on a different clock when ASYNC=1)
            input   var logic               s_permit_reset,
            input   var logic               s_permit_clk  ,
            input   var logic   [N-1:0]     s_permit_first,
            input   var logic   [N-1:0]     s_permit_last ,
            input   var len_t               s_permit_len  ,
            input   var user_t              s_permit_user ,
            input   var logic               s_permit_valid,
            output  var logic               s_permit_ready
        );

    // -----------------------------------------------------------------
    //  permit FIFO  (CDC or synchronous pass-through)
    // -----------------------------------------------------------------
    // permit信号をまとめたstructでFIFOに通す(ASYNC=1時はクロック境界を越える)

    typedef struct packed {
        logic   [N-1:0] first;
        logic   [N-1:0] last ;
        len_t           len  ;
        user_t          user ;
    } permit_t;

    permit_t    fifo_s_permit_data ;
    logic       fifo_s_permit_valid;
    logic       fifo_s_permit_ready;
    permit_t    fifo_m_permit_data ;
    logic       fifo_m_permit_valid;
    logic       fifo_m_permit_ready;

    assign fifo_s_permit_data.first = s_permit_first;
    assign fifo_s_permit_data.last  = s_permit_last ;
    assign fifo_s_permit_data.len   = s_permit_len  ;
    assign fifo_s_permit_data.user  = s_permit_user ;
    assign fifo_s_permit_valid      = s_permit_valid;
    assign s_permit_ready           = fifo_s_permit_ready;

    if ( ASYNC ) begin : blk_permit_fifo
        jelly3_stream_fifo
                #(
                    .ASYNC          (1                          ),
                    .PTR_BITS       (FIFO_PTR_BITS              ),
                    .DATA_BITS      ($bits(permit_t)            ),
                    .data_t         (permit_t                   ),
                    .DOUT_REG       (FIFO_DOUT_REG              ),
                    .RAM_TYPE       (FIFO_RAM_TYPE              ),
                    .S_SYNC_FF      (FIFO_S_SYNC_FF             ),
                    .M_SYNC_FF      (FIFO_M_SYNC_FF             )
                )
            u_permit_fifo
                (
                    .s_reset        (s_permit_reset             ),
                    .s_clk          (s_permit_clk               ),
                    .s_cke          (1'b1                       ),
                    .s_data         (fifo_s_permit_data         ),
                    .s_valid        (fifo_s_permit_valid        ),
                    .s_ready        (fifo_s_permit_ready        ),
                    .s_free_size    (                           ),

                    .m_reset        (reset                      ),
                    .m_clk          (clk                        ),
                    .m_cke          (cke                        ),
                    .m_data         (fifo_m_permit_data         ),
                    .m_valid        (fifo_m_permit_valid        ),
                    .m_ready        (fifo_m_permit_ready & cke  ),
                    .m_data_size    (                           )
                );
    end
    else begin : blk_permit_sync
        // 同期系: wire-through のみ
        assign fifo_m_permit_data  = fifo_s_permit_data ;
        assign fifo_m_permit_valid = fifo_s_permit_valid;
        assign fifo_s_permit_ready = fifo_m_permit_ready;
    end


    // -----------------------------------------------------------------
    //  data path FFs (gate path のみ; BYPASS は wire-through)
    // -----------------------------------------------------------------
    // core とのインターフェース用中間信号
    logic   [N-1:0] core_s_first;
    logic   [N-1:0] core_s_last ;
    data_t          core_s_data ;
    logic           core_s_valid;
    logic           core_s_ready;
    logic   [N-1:0] core_m_first;
    logic   [N-1:0] core_m_last ;
    data_t          core_m_data ;
    user_t          core_m_user ;
    logic           core_m_valid;
    logic           core_m_ready;

    if ( !BYPASS ) begin : blk_data_ff

        // ---- 入力FF ----
        typedef struct packed {
            logic [N-1:0]   first;
            logic [N-1:0]   last ;
            data_t          data ;
        } s_ff_t;

        s_ff_t  s_ff_s_data;
        s_ff_t  s_ff_m_data;

        assign s_ff_s_data.first = s_first;
        assign s_ff_s_data.last  = s_last ;
        assign s_ff_s_data.data  = s_data ;

        jelly3_stream_ff
                #(
                    .DATA_BITS      ($bits(s_ff_t)  ),
                    .data_t         (s_ff_t         ),
                    .S_REG          (S_REG          ),
                    .M_REG          (0              )
                )
            u_stream_ff_s
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    .cke            (cke            ),
                    .s_data         (s_ff_s_data    ),
                    .s_valid        (s_valid        ),
                    .s_ready        (s_ready        ),
                    .m_data         (s_ff_m_data    ),
                    .m_valid        (core_s_valid   ),
                    .m_ready        (core_s_ready   )
                );

        assign core_s_first = s_ff_m_data.first;
        assign core_s_last  = s_ff_m_data.last ;
        assign core_s_data  = s_ff_m_data.data ;

        // ---- 出力FF ----
        typedef struct packed {
            logic [N-1:0]   first;
            logic [N-1:0]   last ;
            data_t          data ;
            user_t          user ;
        } m_ff_t;

        m_ff_t  m_ff_s_data;
        m_ff_t  m_ff_m_data;

        assign m_ff_s_data.first = core_m_first;
        assign m_ff_s_data.last  = core_m_last ;
        assign m_ff_s_data.data  = core_m_data ;
        assign m_ff_s_data.user  = core_m_user ;

        jelly3_stream_ff
                #(
                    .DATA_BITS      ($bits(m_ff_t)  ),
                    .data_t         (m_ff_t         ),
                    .S_REG          (0              ),
                    .M_REG          (M_REG          )
                )
            u_stream_ff_m
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    .cke            (cke            ),
                    .s_data         (m_ff_s_data    ),
                    .s_valid        (core_m_valid   ),
                    .s_ready        (core_m_ready   ),
                    .m_data         (m_ff_m_data    ),
                    .m_valid        (m_valid        ),
                    .m_ready        (m_ready        )
                );

        assign m_first = m_ff_m_data.first;
        assign m_last  = m_ff_m_data.last ;
        assign m_data  = m_ff_m_data.data ;
        assign m_user  = m_ff_m_data.user ;

    end
    else begin : blk_bypass_data
        // BYPASS時はwire-through (FF不要)
        assign core_s_first = s_first;
        assign core_s_last  = s_last ;
        assign core_s_data  = s_data ;
        assign core_s_valid = s_valid;
        assign s_ready      = core_s_ready;

        assign m_first      = core_m_first;
        assign m_last       = core_m_last ;
        assign m_data       = core_m_data ;
        assign m_user       = core_m_user ;
        assign m_valid      = core_m_valid;
        assign core_m_ready = m_ready;
    end


    // -----------------------------------------------------------------
    //  core
    // -----------------------------------------------------------------

    jelly3_stream_gate_core
            #(
                .N              (N              ),
                .BYPASS         (BYPASS         ),
                .BYPASS_COMBINE (BYPASS_COMBINE ),
                .DETECTOR_ENABLE(DETECTOR_ENABLE),
                .AUTO_FIRST     (AUTO_FIRST     ),
                .DATA_BITS      (DATA_BITS      ),
                .data_t         (data_t         ),
                .LEN_BITS       (LEN_BITS       ),
                .len_t          (len_t          ),
                .LEN_OFFSET     (LEN_OFFSET     ),
                .USER_BITS      (USER_BITS      ),
                .user_t         (user_t         )
            )
        u_gate_core
            (
                .reset          (reset          ),
                .clk            (clk            ),
                .cke            (cke            ),

                .skip           (skip           ),
                .detect_first   (detect_first   ),
                .detect_last    (detect_last    ),
                .padding_en     (padding_en     ),
                .padding_data   (padding_data   ),

                .s_first        (core_s_first   ),
                .s_last         (core_s_last    ),
                .s_data         (core_s_data    ),
                .s_valid        (core_s_valid   ),
                .s_ready        (core_s_ready   ),

                .m_first        (core_m_first   ),
                .m_last         (core_m_last    ),
                .m_data         (core_m_data    ),
                .m_user         (core_m_user    ),
                .m_valid        (core_m_valid   ),
                .m_ready        (core_m_ready   ),

                .s_permit_first (fifo_m_permit_data.first ),
                .s_permit_last  (fifo_m_permit_data.last  ),
                .s_permit_len   (fifo_m_permit_data.len   ),
                .s_permit_user  (fifo_m_permit_data.user  ),
                .s_permit_valid (fifo_m_permit_valid      ),
                .s_permit_ready (fifo_m_permit_ready      )
            );


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
