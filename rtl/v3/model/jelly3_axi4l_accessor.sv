// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4l_accessor
    #(
        parameter   unsigned    RAND_RATE_AW = 0,
        parameter   unsigned    RAND_RATE_W  = 0,
        parameter   unsigned    RAND_RATE_B  = 0,
        parameter   unsigned    RAND_RATE_AR = 0,
        parameter   unsigned    RAND_RATE_R  = 0
    )
    (
        jelly3_axi4l_if.m   m_axi4l
    );

    localparam EPSILON = 0.01;

    localparam type addr_t = logic [m_axi4l.ADDR_BITS-1:0];
    localparam type data_t = logic [m_axi4l.DATA_BITS-1:0];
    localparam type strb_t = logic [m_axi4l.STRB_BITS-1:0];
    localparam type prot_t = logic [m_axi4l.PROT_BITS-1:0];
    localparam type resp_t = logic [m_axi4l.RESP_BITS-1:0];

    logic   busy_aw;
    logic   busy_w ;
    logic   busy_b ;
    logic   busy_ar;
    logic   busy_r ;
    always_ff @(posedge m_axi4l.aclk) begin
        if ( m_axi4l.aclken ) begin
            if ( !m_axi4l.awvalid || m_axi4l.awready )  busy_aw <= RAND_RATE_AW > 0 ? $urandom_range(100) < RAND_RATE_AW : 1'b0;
            if ( !m_axi4l.wvalid  || m_axi4l.wready  )  busy_w  <= RAND_RATE_W  > 0 ? $urandom_range(100) < RAND_RATE_W  : 1'b0;
                                                        busy_b  <= RAND_RATE_B  > 0 ? $urandom_range(100) < RAND_RATE_B  : 1'b0;
            if ( !m_axi4l.arvalid || m_axi4l.arready )  busy_ar <= RAND_RATE_AR > 0 ? $urandom_range(100) < RAND_RATE_AR : 1'b0;
                                                        busy_r  <= RAND_RATE_R  > 0 ? $urandom_range(100) < RAND_RATE_R  : 1'b0;
        end
    end


    // signals
    addr_t      awaddr  ;
    prot_t      awprot  ;
    logic       awvalid = 1'b0;
    logic       awready ;
    strb_t      wstrb   ;
    data_t      wdata   ;
    logic       wvalid = 1'b0;
    logic       wready  ;
    resp_t      bresp   ;
    logic       bvalid  ;
    logic       bready = 1'b0;
    addr_t      araddr  ;
    prot_t      arprot  ;
    logic       arvalid = 1'b0;
    logic       arready ;
    data_t      rdata   ;
    resp_t      rresp   ;
    logic       rvalid  ;
    logic       rready = 1'b0;

    assign m_axi4l.awaddr  = awvalid ? awaddr : 'x  ;
    assign m_axi4l.awprot  = awvalid ? awprot : 'x  ;
    assign m_axi4l.awvalid = awvalid && !busy_aw;
    assign m_axi4l.wstrb   = wvalid  ? wstrb  : 'x  ;
    assign m_axi4l.wdata   = wvalid  ? wdata  : 'x  ;
    assign m_axi4l.wvalid  = wvalid && !busy_w ;
    assign m_axi4l.bready  = !busy_b;
    assign m_axi4l.araddr  = arvalid ? araddr : 'x  ;
    assign m_axi4l.arprot  = arvalid ? arprot : 'x  ;
    assign m_axi4l.arvalid = arvalid && !busy_ar;
    assign m_axi4l.rready  = !busy_r;

    always_ff @(posedge m_axi4l.aclk) begin
        if ( m_axi4l.aclken ) begin
            awready <= m_axi4l.awready;
            wready  <= m_axi4l.wready ;
            bresp   <= m_axi4l.bresp  ;
            bvalid  <= m_axi4l.bvalid ;
            arready <= m_axi4l.arready;
            rdata   <= m_axi4l.rdata  ;
            rresp   <= m_axi4l.rresp  ;
            rvalid  <= m_axi4l.rvalid ;
        end
    end

    logic                               issue_aw;
    logic                               issue_w ;
    logic                               issue_b ;
    logic                               issue_ar;
    logic                               issue_r ;
    always_ff @(posedge m_axi4l.aclk) begin
        issue_aw <= m_axi4l.awvalid & m_axi4l.awready   ;
        issue_w  <= m_axi4l.wvalid  & m_axi4l.wready    ;
        issue_b  <= m_axi4l.bvalid  & m_axi4l.bready    ;
        issue_ar <= m_axi4l.arvalid & m_axi4l.arready   ;
        issue_r  <= m_axi4l.rvalid  & m_axi4l.rready    ;
    end

    task write(
                input   addr_t  addr,
                input   data_t  data,
                input   strb_t  strb
            );
        $display("[axi4l write] addr:%x <= data:%x strb:%x", addr, data, strb);
        @(posedge m_axi4l.aclk); #EPSILON;
        awaddr  = addr;
        awprot  = '0;
        awvalid = 1'b1;
        wstrb   = strb;
        wdata   = data;
        wvalid  = 1'b1;

        @(posedge m_axi4l.aclk); #EPSILON;
        while ( awvalid || wvalid ) begin
            if ( issue_aw ) begin
                awaddr  = 'x;
                awprot  = 'x;
                awvalid = 1'b0;
            end
            if ( issue_w ) begin
                wstrb   = 'x;
                wdata   = 'x;
                wvalid  = 1'b0;
            end
            @(posedge m_axi4l.aclk); #EPSILON;
        end

        while ( !issue_b ) begin
            @(posedge m_axi4l.aclk); #EPSILON;
        end
    endtask

    task read(
                input   addr_t  addr,
                output  data_t  data
            );
        @(posedge m_axi4l.aclk); #EPSILON;
        araddr  = addr;
        arprot  = '0;
        arvalid = 1'b1;
        @(posedge m_axi4l.aclk); #EPSILON;
        while ( !issue_ar ) begin
            @(posedge m_axi4l.aclk); #EPSILON;
        end

        araddr  = 'x;
        arprot  = 'x;
        arvalid = 1'b0;
        @(posedge m_axi4l.aclk); #EPSILON;
        while ( !issue_r ) begin
            @(posedge m_axi4l.aclk); #EPSILON;
        end
        data = rdata;
        $display("[axi4l read] addr:%x => data:%x", addr, data);
    endtask

    localparam ADDR_UNIT = m_axi4l.DATA_BITS / 8;

    task write_reg(
                input   addr_t  base_addr,
                input   int     reg_idx,
                input   data_t  data,
                input   strb_t  strb
            );
        write(base_addr + m_axi4l.ADDR_BITS'(reg_idx) * ADDR_UNIT, data, strb);
    endtask

    task read_reg(
                input   addr_t  base_addr,
                input   int     reg_idx,
                output  data_t  data
            );
        read(base_addr + m_axi4l.ADDR_BITS'(reg_idx) * ADDR_UNIT, data);
    endtask

endmodule


`default_nettype wire


// end of file
