// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4l_arbiter
        #(
            parameter   int NUM = 4
        )
        (
            jelly3_axi4l_if.s   s_axi4l [NUM],
            jelly3_axi4l_if.m   m_axi4l
        );

    localparam  int     SEL_BITS = NUM > 1 ? $clog2(NUM) : 1;
    localparam  type    sel_t    = logic [SEL_BITS-1:0]     ;

    typedef logic   [m_axi4l.ADDR_BITS-1:0] addr_t;
    typedef logic   [m_axi4l.DATA_BITS-1:0] data_t;
    typedef logic   [m_axi4l.STRB_BITS-1:0] strb_t;
    typedef logic   [m_axi4l.PROT_BITS-1:0] prot_t;
    typedef logic   [m_axi4l.RESP_BITS-1:0] resp_t;


    // assign for packed array
    addr_t  [NUM-1:0]   s_axi4l_awaddr  ;
    prot_t  [NUM-1:0]   s_axi4l_awprot  ;
    logic   [NUM-1:0]   s_axi4l_awvalid ;
    logic   [NUM-1:0]   s_axi4l_awready ;
    data_t  [NUM-1:0]   s_axi4l_wdata   ;
    strb_t  [NUM-1:0]   s_axi4l_wstrb   ;
    logic   [NUM-1:0]   s_axi4l_wvalid  ;
    logic   [NUM-1:0]   s_axi4l_wready  ;
    resp_t  [NUM-1:0]   s_axi4l_bresp   ;
    logic   [NUM-1:0]   s_axi4l_bvalid  ;
    logic   [NUM-1:0]   s_axi4l_bready  ;
    addr_t  [NUM-1:0]   s_axi4l_araddr  ;
    prot_t  [NUM-1:0]   s_axi4l_arprot  ;
    logic   [NUM-1:0]   s_axi4l_arvalid ;
    logic   [NUM-1:0]   s_axi4l_arready ;
    data_t  [NUM-1:0]   s_axi4l_rdata   ;
    resp_t  [NUM-1:0]   s_axi4l_rresp   ;
    logic   [NUM-1:0]   s_axi4l_rvalid  ;
    logic   [NUM-1:0]   s_axi4l_rready  ;
    for ( genvar i = 0; i < NUM; i++ ) begin : s_assign
        assign s_axi4l_awaddr [i] = s_axi4l[i].awaddr ;
        assign s_axi4l_awprot [i] = s_axi4l[i].awprot ;
        assign s_axi4l_awvalid[i] = s_axi4l[i].awvalid;
        assign s_axi4l_wstrb  [i] = s_axi4l[i].wstrb  ;
        assign s_axi4l_wdata  [i] = s_axi4l[i].wdata  ;
        assign s_axi4l_wvalid [i] = s_axi4l[i].wvalid ;
        assign s_axi4l_bready [i] = s_axi4l[i].bready ;
        assign s_axi4l_araddr [i] = s_axi4l[i].araddr ;
        assign s_axi4l_arprot [i] = s_axi4l[i].arprot ;
        assign s_axi4l_arvalid[i] = s_axi4l[i].arvalid;
        assign s_axi4l_rready [i] = s_axi4l[i].rready ;

        assign s_axi4l[i].awready = s_axi4l_awready[i];
        assign s_axi4l[i].wready  = s_axi4l_wready [i];
        assign s_axi4l[i].bresp   = s_axi4l_bresp  [i];
        assign s_axi4l[i].bvalid  = s_axi4l_bvalid [i];
        assign s_axi4l[i].arready = s_axi4l_arready[i];
        assign s_axi4l[i].rdata   = s_axi4l_rdata  [i];
        assign s_axi4l[i].rresp   = s_axi4l_rresp  [i];
        assign s_axi4l[i].rvalid  = s_axi4l_rvalid [i];
    end

    // write arbiter
    logic   write_busy  ;
    sel_t   write_sel   ;

    always_comb begin
        s_axi4l_awready = '0;
        s_axi4l_wready  = '0;
        if ( !write_busy ) begin
            for ( int i = 0; i < NUM; i++ ) begin
                if ( s_axi4l_awvalid[i] && s_axi4l_wvalid[i] ) begin
                    s_axi4l_awready[i] = 1'b1;
                    s_axi4l_wready [i] = 1'b1;
                    break;
                end
            end
        end
    end

    always_ff @(posedge m_axi4l.aclk) begin
        if ( ~m_axi4l.aresetn ) begin
            write_busy      <= 1'b0 ;
            write_sel       <= 'x   ;
            s_axi4l_bresp   <= 'x   ;
            s_axi4l_bvalid  <= '0   ;
            m_axi4l.awaddr  <= 'x   ;
            m_axi4l.awprot  <= 'x   ;
            m_axi4l.awvalid <= 1'b0 ;
            m_axi4l.wstrb   <= 'x   ;
            m_axi4l.wdata   <= 'x   ;
            m_axi4l.wvalid  <= 1'b0 ;
        end
        else if ( m_axi4l.aclken ) begin
            if ( m_axi4l.awready )  m_axi4l.awvalid <= 1'b0 ;
            if ( m_axi4l.wready  )  m_axi4l.wvalid  <= 1'b0 ;

            for ( int i = 0; i < NUM; i++ ) begin
                if ( s_axi4l_awvalid[i] && s_axi4l_awready[i]
                        && s_axi4l_wvalid[i] && s_axi4l_wready[i] ) begin
                    write_busy      <= 1'b1     ;
                    write_sel       <= sel_t'(i);
                    m_axi4l.awaddr  <= s_axi4l_awaddr [i];
                    m_axi4l.awprot  <= s_axi4l_awprot [i];
                    m_axi4l.awvalid <= s_axi4l_awvalid[i];
                    m_axi4l.wstrb   <= s_axi4l_wstrb  [i];
                    m_axi4l.wdata   <= s_axi4l_wdata  [i];
                    m_axi4l.wvalid  <= s_axi4l_wvalid [i];
                    break;
                end
            end

            for ( int i = 0; i < NUM; i++ ) begin
                if ( s_axi4l_bvalid[i] && s_axi4l_bready[i] ) begin
                    s_axi4l_bresp [i] <= 'x     ;
                    s_axi4l_bvalid[i] <= 1'b0   ;
                    write_busy        <= 1'b0   ;
                end
            end

            if ( m_axi4l.bvalid ) begin
                s_axi4l_bresp[write_sel]  <= m_axi4l.bresp  ;
                s_axi4l_bvalid[write_sel] <= m_axi4l.bvalid ;
            end
        end
    end

    assign m_axi4l.bready = 1'b1;


    // read arbiter
    logic   read_busy   ;
    sel_t   read_sel    ;

    always_comb begin
        s_axi4l_arready = '0;
        if ( !read_busy ) begin
            for ( int i = 0; i < NUM; i++ ) begin
                if ( s_axi4l_arvalid[i] ) begin
                    s_axi4l_arready[i] = 1'b1;
                    break;
                end
            end
        end
    end

    always_ff @(posedge m_axi4l.aclk) begin
        if ( ~m_axi4l.aresetn ) begin
            read_busy       <= 1'b0 ;
            read_sel        <= 'x   ;
            s_axi4l_rresp   <= 'x   ;
            s_axi4l_rdata   <= 'x   ;
            s_axi4l_rvalid  <= '0   ;
            m_axi4l.araddr  <= 'x   ;
            m_axi4l.arprot  <= 'x   ;
            m_axi4l.arvalid <= 1'b0 ;
        end
        else if ( m_axi4l.aclken ) begin
            if ( m_axi4l.arready )  m_axi4l.arvalid <= 1'b0 ;

            for ( int i = 0; i < NUM; i++ ) begin
                if ( s_axi4l_arvalid[i] && s_axi4l_arready[i] ) begin
                    read_busy       <= 1'b1     ;
                    read_sel        <= sel_t'(i);
                    m_axi4l.araddr  <= s_axi4l_araddr [i];
                    m_axi4l.arprot  <= s_axi4l_arprot [i];
                    m_axi4l.arvalid <= s_axi4l_arvalid[i];
                    break;
                end
            end

            for ( int i = 0; i < NUM; i++ ) begin
                if ( s_axi4l_rvalid[i] && s_axi4l_rready[i] ) begin
                    s_axi4l_rresp [i] <= 'x     ;
                    s_axi4l_rdata [i] <= 'x     ;
                    s_axi4l_rvalid[i] <= 1'b0   ;
                    read_busy         <= 1'b0   ;
                end
            end

            if ( m_axi4l.rvalid ) begin
                s_axi4l_rresp [read_sel] <= m_axi4l.rresp   ;
                s_axi4l_rdata [read_sel] <= m_axi4l.rdata   ;
                s_axi4l_rvalid[read_sel] <= m_axi4l.rvalid  ;
            end
        end
    end

    assign m_axi4l.rready = 1'b1;

endmodule


`default_nettype wire


// end of file
