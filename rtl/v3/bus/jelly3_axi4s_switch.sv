// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4s_switch
        #(
            parameter   int     S_NUM         = 1                               ,
            parameter   int     M_NUM         = 1                               ,
            parameter   int     S_SEL_BITS    = S_NUM > 1 ? $clog2(S_NUM) : 1   ,
            parameter   type    s_sel_t       = logic  [S_SEL_BITS-1:0]         ,
            parameter   int     M_SEL_BITS    = S_NUM > 1 ? $clog2(S_NUM) : 1   ,
            parameter   type    m_sel_t       = logic  [M_SEL_BITS-1:0]         ,
            parameter   bit     DEFAULT_READY = 1'b0                            ,
            parameter           DEVICE        = "RTL"                           ,
            parameter           SIMULATION    = "false"                         ,
            parameter           DEBUG         = "false"                         
        )
        (
            input var s_sel_t       s_sel           ,
            jelly3_axi4s_if.s       s_axi4s [S_NUM] ,
            input var m_sel_t       m_sel           ,
            jelly3_axi4s_if.m       m_axi4s [M_NUM] 
        );

    // type
    localparam  type    data_t = logic [s_axi4s[0].DATA_BITS-1:0]  ;
    localparam  type    strb_t = logic [s_axi4s[0].STRB_BITS-1:0]  ;
    localparam  type    keep_t = logic [s_axi4s[0].KEEP_BITS-1:0]  ;
    localparam  type    id_t   = logic [s_axi4s[0].ID_BITS  -1:0]  ;
    localparam  type    dest_t = logic [s_axi4s[0].DEST_BITS-1:0]  ;
    localparam  type    user_t = logic [s_axi4s[0].USER_BITS-1:0]  ;

    // slave
    data_t  [S_NUM-1:0]     s_tdata   ;
    strb_t  [S_NUM-1:0]     s_tstrb   ;
    keep_t  [S_NUM-1:0]     s_tkeep   ;
    logic   [S_NUM-1:0]     s_tlast   ;
    id_t    [S_NUM-1:0]     s_tid     ;
    dest_t  [S_NUM-1:0]     s_tdest   ;
    user_t  [S_NUM-1:0]     s_tuser   ;
    logic   [S_NUM-1:0]     s_tvalid  ;
    logic   [S_NUM-1:0]     s_tready  ;
    for ( genvar i = 0; i < S_NUM; i++ ) begin
        assign s_tdata [i] = s_axi4s[i].tdata   ;
        assign s_tstrb [i] = s_axi4s[i].tstrb   ;
        assign s_tkeep [i] = s_axi4s[i].tkeep   ;
        assign s_tlast [i] = s_axi4s[i].tlast   ;
        assign s_tid   [i] = s_axi4s[i].tid     ;
        assign s_tdest [i] = s_axi4s[i].tdest   ;
        assign s_tuser [i] = s_axi4s[i].tuser   ;
        assign s_tvalid[i] = s_axi4s[i].tvalid  ;

        assign s_axi4s[i].tready = s_tready[i]  ;
    end

    // master
    data_t  [M_NUM-1:0]     m_tdata   ;
    strb_t  [M_NUM-1:0]     m_tstrb   ;
    keep_t  [M_NUM-1:0]     m_tkeep   ;
    logic   [M_NUM-1:0]     m_tlast   ;
    id_t    [M_NUM-1:0]     m_tid     ;
    dest_t  [M_NUM-1:0]     m_tdest   ;
    user_t  [M_NUM-1:0]     m_tuser   ;
    logic   [M_NUM-1:0]     m_tvalid  ;
    logic   [M_NUM-1:0]     m_tready  ;
    for ( genvar i = 0; i < M_NUM; i++ ) begin
        assign m_axi4s[i].tdata  = m_tdata [i];
        assign m_axi4s[i].tstrb  = m_tstrb [i];
        assign m_axi4s[i].tkeep  = m_tkeep [i];
        assign m_axi4s[i].tlast  = m_tlast [i];
        assign m_axi4s[i].tid    = m_tid   [i];
        assign m_axi4s[i].tdest  = m_tdest [i];
        assign m_axi4s[i].tuser  = m_tuser [i];
        assign m_axi4s[i].tvalid = m_tvalid[i];

        assign m_tready[i] = m_axi4s[i].tready;
    end


    // switch
    always_comb begin
        m_tdata  = 'x;
        m_tstrb  = 'x;
        m_tkeep  = 'x;
        m_tlast  = 'x;
        m_tid    = 'x;
        m_tdest  = 'x;
        m_tuser  = 'x;
        m_tvalid = '0;
        m_tdata [m_sel] = s_tdata [s_sel];
        m_tstrb [m_sel] = s_tstrb [s_sel];
        m_tkeep [m_sel] = s_tkeep [s_sel];
        m_tlast [m_sel] = s_tlast [s_sel];
        m_tid   [m_sel] = s_tid   [s_sel];
        m_tdest [m_sel] = s_tdest [s_sel];
        m_tuser [m_sel] = s_tuser [s_sel];
        m_tvalid[m_sel] = s_tvalid[s_sel];
        s_tready = {S_NUM{DEFAULT_READY}};
        s_tready[s_sel] = m_tready[m_sel];
    end

endmodule

`default_nettype wire

// end of file

