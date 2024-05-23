// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4l_addr_decoder
        #(
            parameter   int             NUM       = 4,
            parameter   int             DEC_ADDR_BITS = 0,
            parameter   bit     [63:0]  DEC_ADDR_MASK = '1
        )
        (
            jelly3_axi4l_if.s   s_axi4l,
            jelly3_axi4l_if.m   m_axi4l  [NUM]
        );

    localparam int DEC_MASK_BITS = DEC_ADDR_BITS > 0 ? DEC_ADDR_BITS : s_axi4l.ADDR_BITS;
    typedef logic   [DEC_MASK_BITS-1:0]     mask_t;
    function [DEC_MASK_BITS-1:0] dec_addr_mask(input [s_axi4l.ADDR_BITS-1:0] addr);
        return DEC_MASK_BITS'(addr) & DEC_MASK_BITS'(DEC_ADDR_MASK);
    endfunction

    logic   [s_axi4l.ADDR_BITS-1:0]  addr_base   [NUM];
    logic   [s_axi4l.ADDR_BITS-1:0]  addr_high   [NUM];
    for ( genvar i = 0; i < NUM; i++ ) begin
        assign addr_base[i] = m_axi4l[i].addr_base;
        assign addr_high[i] = m_axi4l[i].addr_high;
    end

    // address decode
    logic   [NUM-1:0]  awaddr_match;
    logic              awaddr_other;
    always_comb begin
        awaddr_match = '0;
        awaddr_other = 1'b0;
        awaddr_other = 1'b1;
        for ( int i = 0; i < NUM; i++ ) begin
            if ( dec_addr_mask(s_axi4l.awaddr) >= dec_addr_mask(addr_base[i])
              && dec_addr_mask(s_axi4l.awaddr) <= dec_addr_mask(addr_high[i]) ) begin
                awaddr_match[i] = 1'b1;
                awaddr_other    = 1'b0;
            end
        end
    end

    logic   [NUM-1:0]  araddr_match;
    logic              araddr_other;
    always_comb begin
        araddr_match = '0;
        araddr_other = 1'b0;
        araddr_other = 1'b1;
        for ( int i = 0; i < NUM; i++ ) begin
            if ( dec_addr_mask(s_axi4l.araddr) >= dec_addr_mask(addr_base[i])
              && dec_addr_mask(s_axi4l.araddr) <= dec_addr_mask(addr_high[i]) ) begin
                araddr_match[i] = 1'b1;
                araddr_other    = 1'b0;
            end
        end
    end
    
    // write
    logic                           m_awready     [NUM];
    logic                           m_wready      [NUM];
    logic   [s_axi4l.RESP_BITS-1:0] m_bresp       [NUM];
    logic                           m_bvalid      [NUM];
    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_awready[i] = m_axi4l[i].awready;
        assign m_wready [i] = m_axi4l[i].wready;
        assign m_bresp[i]   = m_axi4l[i].bresp;
        assign m_bvalid[i]  = m_axi4l[i].bvalid;
    end

    logic                           write_busy;
    logic   [s_axi4l.ADDR_BITS-1:0] m_awaddr;
    logic   [s_axi4l.PROT_BITS-1:0] m_awprot;
    logic                           m_awvalid     [NUM];
    logic   [s_axi4l.STRB_BITS-1:0] m_wstrb;
    logic   [s_axi4l.DATA_BITS-1:0] m_wdata;
    logic                           m_wvalid      [NUM];

    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            write_busy  <= 1'b0;
            for ( int i = 0; i < NUM; i++ ) begin
                m_awvalid[i] <= 1'b0;
            end
            for ( int i = 0; i < NUM; i++ ) begin
                m_wvalid[i] <= 1'b0;
            end
            s_axi4l.bvalid <= 1'b0;
        end
        else begin
            // finish
            for ( int i = 0; i < NUM; i++ ) begin
                if ( m_awvalid[i] && m_awready[i] ) begin
                    m_awvalid[i] <= 1'b0;
                end
                if ( m_wvalid[i] && m_wready[i] ) begin
                    m_wvalid[i]  <= 1'b0;
                end
            end
            if ( s_axi4l.bvalid && s_axi4l.bready ) begin
                write_busy     <= 1'b0;
                s_axi4l.bresp  <= 'x;
                s_axi4l.bvalid <= 1'b0;
            end
            
            // start
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                write_busy  <= 1'b1;
                m_awaddr <= s_axi4l.awaddr;
                m_awprot <= s_axi4l.awprot;
                m_wstrb  <= s_axi4l.wstrb ;
                m_wdata  <= s_axi4l.wdata ;
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( awaddr_match[i] ) begin
                        m_awvalid[i] <= 1'b1;
                        m_wvalid[i]  <= 1'b1;
                    end
                end
                if ( awaddr_other ) begin
                    s_axi4l.bresp  <= '0;
                    s_axi4l.bvalid <= 1'b1;
                end
            end

            // response
            for ( int i = 0; i < NUM; i++ ) begin
                if ( m_bvalid[i] ) begin
                    s_axi4l.bresp  <= m_bresp[i];
                    s_axi4l.bvalid <= 1'b1;
                end
            end
        end
    end

    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_axi4l[i].awaddr  = m_awvalid[i] ? m_awaddr : 'x;
        assign m_axi4l[i].awprot  = m_awvalid[i] ? m_awprot : 'x;
        assign m_axi4l[i].awvalid = m_awvalid[i];
        assign m_axi4l[i].wstrb   = m_wvalid [i] ? m_wstrb  : 'x;
        assign m_axi4l[i].wdata   = m_wvalid [i] ? m_wdata  : 'x;
        assign m_axi4l[i].wvalid  = m_wvalid[i];
        assign m_axi4l[i].bready  = 1'b1;
    end

    assign s_axi4l.awready = s_axi4l.wvalid  && (!write_busy || (s_axi4l.bvalid && s_axi4l.bready));
    assign s_axi4l.wready  = s_axi4l.awvalid && (!write_busy || (s_axi4l.bvalid && s_axi4l.bready));



    // read
    logic                           m_arready    [NUM];
    logic   [s_axi4l.RESP_BITS-1:0] m_rresp      [NUM];
    logic   [s_axi4l.DATA_BITS-1:0] m_rdata      [NUM];
    logic                           m_rvalid     [NUM];
    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_arready[i] = m_axi4l[i].arready;
        assign m_rresp[i]   = m_axi4l[i].rresp;
        assign m_rdata[i]   = m_axi4l[i].rdata;
        assign m_rvalid[i]  = m_axi4l[i].rvalid;
    end

    logic                           read_busy;
    logic   [s_axi4l.ADDR_BITS-1:0] m_araddr;
    logic   [s_axi4l.PROT_BITS-1:0] m_arprot;
    logic                           m_arvalid   [NUM];
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            read_busy  <= 1'b0;
            for ( int i = 0; i < NUM; i++ ) begin
                m_arvalid[i] <= 1'b0;
            end
            s_axi4l.rvalid <= 1'b0;
        end
        else begin
            // finish
            for ( int i = 0; i < NUM; i++ ) begin
                if ( m_arvalid[i] && m_arready[i] ) begin
                    m_arvalid[i] <= 1'b0;
                end
            end
            if ( s_axi4l.rvalid && s_axi4l.rready ) begin
                read_busy      <= 1'b0;
                s_axi4l.rdata  <= 'x;
                s_axi4l.rresp  <= 'x;
                s_axi4l.rvalid <= 1'b0;
            end
        
            // start
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                read_busy  <= 1'b1;
                m_araddr <= s_axi4l.araddr;
                m_arprot <= s_axi4l.arprot;
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( araddr_match[i] ) begin
                        m_arvalid[i] <= 1'b1;
                    end
                end
                if ( araddr_other ) begin
                    s_axi4l.rdata  <= '0;
                    s_axi4l.rresp  <= '0;
                    s_axi4l.rvalid <= 1'b1;
                end
            end

            // response
            for ( int i = 0; i < NUM; i++ ) begin
                if ( m_rvalid[i] ) begin
                    s_axi4l.rdata  <= m_rdata[i];
                    s_axi4l.rresp  <= m_rresp[i];
                    s_axi4l.rvalid <= 1'b1;
                end
            end
        end
    end

    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_axi4l[i].araddr  = m_arvalid[i] ? m_araddr : 'x;
        assign m_axi4l[i].arprot  = m_arvalid[i] ? m_arprot : 'x;
        assign m_axi4l[i].arvalid = m_arvalid[i];
        assign m_axi4l[i].rready  = 1'b1;
    end

    assign s_axi4l.arready = !read_busy || (s_axi4l.rvalid && s_axi4l.rready);




`ifdef __SIMULATION__
    initial begin
        if ( s_axi4l.ADDR_BITS != m_axi4l[0].ADDR_BITS ) begin
            $display("ERROR: ADDR_BITS mismatch");
            $finish;
        end
        if ( s_axi4l.DATA_BITS != m_axi4l[0].DATA_BITS ) begin
            $display("ERROR: DATA_BITS mismatch");
            $finish;
        end
    end
`endif


endmodule


`default_nettype wire


// end of file
