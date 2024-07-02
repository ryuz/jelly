// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4_accessor
    #(
        parameter   unsigned    RAND_RATE_AW = 0,
        parameter   unsigned    RAND_RATE_W  = 0,
        parameter   unsigned    RAND_RATE_B  = 0,
        parameter   unsigned    RAND_RATE_AR = 0,
        parameter   unsigned    RAND_RATE_R  = 0
    )
    (
        jelly3_axi4_if.m    m_axi4
    );

    localparam  EPSILON = 0.01;

    localparam  type    id_t        = logic [m_axi4.ID_BITS    -1:0]    ;
    localparam  type    addr_t      = logic [m_axi4.ADDR_BITS  -1:0]    ;
    localparam  type    len_t       = logic [m_axi4.LEN_BITS   -1:0]    ;
    localparam  type    size_t      = logic [m_axi4.SIZE_BITS  -1:0]    ;
    localparam  type    burst_t     = logic [m_axi4.BURST_BITS -1:0]    ;
    localparam  type    lock_t      = logic [m_axi4.LOCK_BITS  -1:0]    ;
    localparam  type    cache_t     = logic [m_axi4.CACHE_BITS -1:0]    ;
    localparam  type    prot_t      = logic [m_axi4.PROT_BITS  -1:0]    ;
    localparam  type    qos_t       = logic [m_axi4.QOS_BITS   -1:0]    ;
    localparam  type    region_t    = logic [m_axi4.REGION_BITS-1:0]    ;
    localparam  type    data_t      = logic [m_axi4.DATA_BITS  -1:0]    ;
    localparam  type    strb_t      = logic [m_axi4.STRB_BITS  -1:0]    ;
    localparam  type    resp_t      = logic [m_axi4.RESP_BITS  -1:0]    ;
    localparam  type    awuser_t    = logic [m_axi4.AWUSER_BITS-1:0]    ;
    localparam  type    wuser_t     = logic [m_axi4.WUSER_BITS -1:0]    ;
    localparam  type    buser_t     = logic [m_axi4.BUSER_BITS -1:0]    ;
    localparam  type    aruser_t    = logic [m_axi4.ARUSER_BITS-1:0]    ;
    localparam  type    ruser_t     = logic [m_axi4.RUSER_BITS -1:0]    ;


    logic   busy_aw;
    logic   busy_w ;
    logic   busy_b ;
    logic   busy_ar;
    logic   busy_r ;
    always_ff @(posedge m_axi4.aclk) begin
        if ( m_axi4.aclken ) begin
            if ( !m_axi4.awvalid || m_axi4.awready )    busy_aw <= RAND_RATE_AW > 0 ? $urandom_range(100) < RAND_RATE_AW : 1'b0;
            if ( !m_axi4.wvalid  || m_axi4.wready  )    busy_w  <= RAND_RATE_W  > 0 ? $urandom_range(100) < RAND_RATE_W  : 1'b0;
                                                        busy_b  <= RAND_RATE_B  > 0 ? $urandom_range(100) < RAND_RATE_B  : 1'b0;
            if ( !m_axi4.arvalid || m_axi4.arready )    busy_ar <= RAND_RATE_AR > 0 ? $urandom_range(100) < RAND_RATE_AR : 1'b0;
                                                        busy_r  <= RAND_RATE_R  > 0 ? $urandom_range(100) < RAND_RATE_R  : 1'b0;
        end
    end


    // signals  
    id_t        awid            ;
    addr_t      awaddr          ;
    len_t       awlen           ;
    size_t      awsize          ;
    burst_t     awburst         ;
    lock_t      awlock          ;
    cache_t     awcache         ;
    prot_t      awprot          ;
    qos_t       awqos           ;
    region_t    awregion        ;
    awuser_t    awuser          ;
    logic       awvalid = 1'b0  ;
    logic       awready         ;

    data_t      wdata           ;
    strb_t      wstrb           ;
    logic       wlast           ;
    wuser_t     wuser           ;
    logic       wvalid = 1'b0   ;
    logic       wready          ;

    id_t        bid             ;
    resp_t      bresp           ;
    buser_t     buser           ;
    logic       bvalid          ;
    logic       bready = 1'b0   ;

    id_t        arid            ;
    addr_t      araddr          ;
    len_t       arlen           ;
    size_t      arsize          ;
    burst_t     arburst         ;
    lock_t      arlock          ;
    cache_t     arcache         ;
    prot_t      arprot          ;
    qos_t       arqos           ;
    region_t    arregion        ;
    aruser_t    aruser          ;
    logic       arvalid = 1'b0  ;
    logic       arready         ;

    id_t        rid             ;
    data_t      rdata           ;
    resp_t      rresp           ;
    logic       rlast           ;
    ruser_t     ruser           ;
    logic       rvalid          ;
    logic       rready = 1'b0   ;

    assign m_axi4.awid     = awvalid ? awid     : 'x    ;
    assign m_axi4.awaddr   = awvalid ? awaddr   : 'x    ;
    assign m_axi4.awlen    = awvalid ? awlen    : 'x    ;
    assign m_axi4.awsize   = awvalid ? awsize   : 'x    ;
    assign m_axi4.awburst  = awvalid ? awburst  : 'x    ;
    assign m_axi4.awlock   = awvalid ? awlock   : 'x    ;
    assign m_axi4.awcache  = awvalid ? awcache  : 'x    ;
    assign m_axi4.awprot   = awvalid ? awprot   : 'x    ;
    assign m_axi4.awqos    = awvalid ? awqos    : 'x    ;
    assign m_axi4.awregion = awvalid ? awregion : 'x    ;
    assign m_axi4.awuser   = awvalid ? awuser   : 'x    ;
    assign m_axi4.awvalid  = awvalid && !busy_aw        ;

    assign m_axi4.wdata    = wvalid  ? wdata    : 'x    ;
    assign m_axi4.wstrb    = wvalid  ? wstrb    : 'x    ;
    assign m_axi4.wlast    = wvalid  ? wlast    : 'x    ;
    assign m_axi4.wuser    = wvalid  ? wuser    : 'x    ;
    assign m_axi4.wvalid   = wvalid && !busy_w          ;

    assign m_axi4.bready   = !busy_b;

    assign m_axi4.arid     = arvalid ? arid     : 'x    ;
    assign m_axi4.araddr   = arvalid ? araddr   : 'x    ;
    assign m_axi4.arlen    = arvalid ? arlen    : 'x    ;
    assign m_axi4.arsize   = arvalid ? arsize   : 'x    ;
    assign m_axi4.arburst  = arvalid ? arburst  : 'x    ;
    assign m_axi4.arlock   = arvalid ? arlock   : 'x    ;
    assign m_axi4.arcache  = arvalid ? arcache  : 'x    ;
    assign m_axi4.arprot   = arvalid ? arprot   : 'x    ;
    assign m_axi4.arqos    = arvalid ? arqos    : 'x    ;
    assign m_axi4.arregion = arvalid ? arregion : 'x    ;
    assign m_axi4.aruser   = arvalid ? aruser   : 'x    ;
    assign m_axi4.arvalid  = arvalid && !busy_ar        ;
    
    assign m_axi4.rready  = !busy_r                     ;

    always_ff @(posedge m_axi4.aclk) begin
        if ( m_axi4.aclken ) begin
            awready <= m_axi4.awready;
            wready  <= m_axi4.wready ;
            bid     <= m_axi4.bid    ;
            bresp   <= m_axi4.bresp  ;
            buser   <= m_axi4.buser  ;
            bvalid  <= m_axi4.bvalid ;
            arready <= m_axi4.arready;
            rid     <= m_axi4.rid    ;
            rdata   <= m_axi4.rdata  ;
            rresp   <= m_axi4.rresp  ;
            rlast   <= m_axi4.rlast  ;
            ruser   <= m_axi4.ruser  ;
            rvalid  <= m_axi4.rvalid ;
        end
    end

    logic                               issue_aw;
    logic                               issue_w ;
    logic                               issue_b ;
    logic                               issue_ar;
    logic                               issue_r ;
    always_ff @(posedge m_axi4.aclk) begin
        issue_aw <= m_axi4.awvalid & m_axi4.awready   ;
        issue_w  <= m_axi4.wvalid  & m_axi4.wready    ;
        issue_b  <= m_axi4.bvalid  & m_axi4.bready    ;
        issue_ar <= m_axi4.arvalid & m_axi4.arready   ;
        issue_r  <= m_axi4.rvalid  & m_axi4.rready    ;
    end

    task write(
                input   id_t        id      ,
                input   addr_t      addr    ,
                input   size_t      size    ,
                input   burst_t     burst   ,
                input   lock_t      lock    ,
                input   cache_t     cache   ,
                input   prot_t      prot    ,
                input   qos_t       qos     ,
                input   region_t    region  ,
                input   awuser_t    user    ,
                input   data_t      data [] ,
                input   strb_t      strb []
            );
        automatic len_t len = len_t'(data.size() - 1);
        automatic len_t idx = 0;

        $display("[axi4 write] awaddr:%x", addr);
        @(posedge m_axi4.aclk); #EPSILON;
        awid     = id       ;
        awaddr   = addr     ;
        awlen    = len      ;
        awsize   = size     ;
        awburst  = burst    ;
        awlock   = lock     ;
        awcache  = cache    ;
        awprot   = prot     ;
        awqos    = qos      ;
        awregion = region   ;
        awuser   = user     ;
        awvalid  = 1'b1     ;

        wdata    = data[0]  ;
        wstrb    = strb[0]  ;
        wlast    = len == 0 ;
        wuser    = '0       ;
        wvalid   = 1'b1     ;

        @(posedge m_axi4.aclk); #EPSILON;
        while ( awvalid || wvalid ) begin
            if ( issue_aw ) begin
                awid     = 'x   ;
                awaddr   = 'x   ;
                awlen    = 'x   ;
                awsize   = 'x   ;
                awburst  = 'x   ;
                awlock   = 'x   ;
                awcache  = 'x   ;
                awprot   = 'x   ;
                awqos    = 'x   ;
                awregion = 'x   ;
                awuser   = 'x   ;
                awvalid  = 1'b0 ;
            end
            if ( issue_w ) begin
                $display("[axi4 write] wdata:%x wstrb:%x", data[idx], strb[idx]);
                if ( wlast ) begin
                    wdata   = 'x;
                    wstrb   = 'x;
                    wlast   = 'x;
                    wuser   = 'x;
                    wvalid  = 1'b0;
                end
                else begin
                    idx++;
                    wdata = data[idx]       ;
                    wstrb = strb[idx]       ;
                    wlast = (len == idx)    ;
                end
            end
            @(posedge m_axi4.aclk); #EPSILON;
        end

        while ( !issue_b ) begin
            @(posedge m_axi4.aclk); #EPSILON;
        end
    endtask

    task read(
                input   id_t        id      ,
                input   addr_t      addr    ,
                input   len_t       len     ,
                input   size_t      size    ,
                input   burst_t     burst   ,
                input   lock_t      lock    ,
                input   cache_t     cache   ,
                input   prot_t      prot    ,
                input   qos_t       qos     ,
                input   region_t    region  ,
                input   awuser_t    user    ,
                output  data_t      data [] 
            );
        automatic len_t idx = 0;
        data = new[int'(len) + 1];

        $display("[axi4 read] araddr:%x", addr);
        @(posedge m_axi4.aclk); #EPSILON;
        arid     = id       ;
        araddr   = addr     ;
        arlen    = len      ;
        arsize   = size     ;
        arburst  = burst    ;
        arlock   = lock     ;
        arcache  = cache    ;
        arprot   = prot     ;
        arqos    = qos      ;
        arregion = region   ;
        aruser   = user     ;
        arvalid  = 1'b1     ;
        @(posedge m_axi4.aclk); #EPSILON;

        forever begin
            if ( issue_ar ) begin
                arid     = 'x   ;
                araddr   = 'x   ;
                arlen    = 'x   ;
                arsize   = 'x   ;
                arburst  = 'x   ;
                arlock   = 'x   ;
                arcache  = 'x   ;
                arprot   = 'x   ;
                arqos    = 'x   ;
                arregion = 'x   ;
                aruser   = 'x   ;
                arvalid  = 1'b0 ;
            end
            if ( issue_r ) begin
                $display("[axi4l read] rdata:%x", rdata);
                data[idx] = rdata;
                idx++;
                if ( rlast || idx >= int'(len) ) begin
                    break;
                end
            end
            @(posedge m_axi4.aclk); #EPSILON;
        end
    endtask

    /*
    localparam ADDR_UNIT = m_axi4.DATA_BITS / 8;

    task write_reg(
                input   addr_t  base_addr,
                input   int     reg_idx,
                input   data_t  data,
                input   strb_t  strb
            );
        write(base_addr + m_axi4.ADDR_BITS'(reg_idx) * ADDR_UNIT, data, strb);
    endtask

    task read_reg(
                input   addr_t  base_addr,
                input   int     reg_idx,
                output  data_t  data
            );
        read(base_addr + m_axi4.ADDR_BITS'(reg_idx) * ADDR_UNIT, data);
    endtask
    */

endmodule


`default_nettype wire


// end of file
