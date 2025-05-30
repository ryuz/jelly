// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4l_to_axi4_w
        #(
            parameter   int     ID_BITS                        = 8          ,
            parameter   int     BURST_BITS                     = 2          ,
            parameter   int     LOCK_BITS                      = 1          ,
            parameter   int     CACHE_BITS                     = 4          ,
            parameter   int     PROT_BITS                      = 3          ,
            parameter   int     QOS_BITS                       = 4          ,
            parameter   int     REGION_BITS                    = 4          ,
            parameter   int     AWUSER_BITS                    = 4          ,
            parameter   int     WUSER_BITS                     = 4          ,
            parameter   bit     [ID_BITS    -1:0]   ID         = '0         ,
            parameter   bit     [BURST_BITS -1:0]   BURST      = 2'b01      ,
            parameter   bit     [LOCK_BITS  -1:0]   LOCK       = '0         ,
            parameter   bit     [CACHE_BITS -1:0]   CACHE      = '0         ,
            parameter   bit     [PROT_BITS  -1:0]   PROT       = 3'b010     ,
            parameter   bit     [QOS_BITS   -1:0]   QOS        = '0         ,
            parameter   bit     [REGION_BITS-1:0]   REGION     = '0         ,
            parameter   bit     [AWUSER_BITS-1:0]   AWUSER     = '0         ,
            parameter   bit     [WUSER_BITS -1:0]   WUSER      = '0         ,
            parameter                               DEVICE     = "RTL"      ,
            parameter                               SIMULATION = "false"    ,
            parameter                               DEBUG      = "false"    
        )
        (
            jelly3_axi4l_if.sw      s_axi4l ,
            jelly3_axi4_if.mw       m_axi4  
        );

    localparam type id_t     = logic [m_axi4.ID_BITS    -1:0]   ;
    localparam type addr_t   = logic [m_axi4.ADDR_BITS  -1:0]   ;
    localparam type len_t    = logic [m_axi4.LEN_BITS   -1:0]   ;
    localparam type size_t   = logic [m_axi4.SIZE_BITS  -1:0]   ;
    localparam type burst_t  = logic [m_axi4.BURST_BITS -1:0]   ;
    localparam type lock_t   = logic [m_axi4.LOCK_BITS  -1:0]   ;
    localparam type cache_t  = logic [m_axi4.CACHE_BITS -1:0]   ;
    localparam type prot_t   = logic [m_axi4.PROT_BITS  -1:0]   ;
    localparam type qos_t    = logic [m_axi4.QOS_BITS   -1:0]   ;
    localparam type region_t = logic [m_axi4.REGION_BITS-1:0]   ;
    localparam type awuser_t = logic [m_axi4.AWUSER_BITS-1:0]   ;
    localparam type data_t   = logic [m_axi4.DATA_BITS  -1:0]   ;
    localparam type strb_t   = logic [m_axi4.STRB_BITS  -1:0]   ;
    localparam type wuser_t  = logic [m_axi4.WUSER_BITS -1:0]   ;
    localparam type buser_t  = logic [m_axi4.BUSER_BITS -1:0]   ;

    assign m_axi4.awid     = id_t'(ID)                      ;
    assign m_axi4.awaddr   = s_axi4l.awaddr                 ;
    assign m_axi4.awlen    = len_t'(0)                      ;
    assign m_axi4.awsize   = size_t'($clog2($bits(strb_t))) ;
    assign m_axi4.awburst  = burst_t'(BURST)                ;
    assign m_axi4.awlock   = lock_t'(LOCK)                  ;
    assign m_axi4.awcache  = cache_t'(CACHE)                ;
    assign m_axi4.awprot   = s_axi4l.awprot                 ;
    assign m_axi4.awqos    = qos_t'(QOS)                    ;
    assign m_axi4.awregion = region_t'(REGION)              ;
    assign m_axi4.awuser   = awuser_t'(AWUSER)              ;
    assign m_axi4.awvalid  = s_axi4l.awvalid                ;
    assign m_axi4.wdata    = s_axi4l.wdata                  ;
    assign m_axi4.wstrb    = s_axi4l.wstrb                  ;
    assign m_axi4.wlast    = 1'b1                           ;
    assign m_axi4.wuser    = wuser_t'(WUSER)                ;
    assign m_axi4.wvalid   = s_axi4l.wvalid                 ;
    assign m_axi4.bready   = s_axi4l.bready                 ;

    assign s_axi4l.awready = m_axi4.awready                 ;
    assign s_axi4l.wready  = m_axi4.wready                  ;
    assign s_axi4l.bresp   = m_axi4.bresp                   ;
    assign s_axi4l.bvalid  = m_axi4.bvalid                  ;

    initial begin
        if ( s_axi4l.DATA_BITS != m_axi4.DATA_BITS ) begin
            $error("ERROR: DATA_BITS of axi4l and axi4 must be same");
        end
    end

    if ( SIMULATION == "true" ) begin
        always_comb begin
            sva_clk : assert (s_axi4l.aclk   === m_axi4.aclk    );
            sva_cke : assert (s_axi4l.aclken === m_axi4.aclken  );
        end
    end

endmodule


`default_nettype wire


// end of file
