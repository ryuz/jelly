


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4l_addr_decoder
    #(
        parameter   int     NUM       = 4
    )
    (
        jelly3_axi4l_if.s   s_axi4l,
        jelly3_axi4l_if.m   m_axi4l  [NUM]
    );

    // address decode
    logic   [NUM-1:0]  awaddr_match;
    logic              awaddr_other;
    always_comb begin
        awaddr_match = '0;
        awaddr_other = 1'b0;
        awaddr_other = 1'b1;
        for ( int i = 0; i < NUM; i++ ) begin
            if ( s_axi4l.awaddr >= m_axi4l[i].addr_base && s_axi4l.awaddr <= m_axi4l[i].addr_high ) begin
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
            if ( s_axi4l.araddr >= m_axi4l[i].addr_base && s_axi4l.araddr <= m_axi4l[i].addr_high ) begin
                araddr_match[i] = 1'b1;
                araddr_other    = 1'b0;
            end
        end
    end

    // write
    logic                           write_busy;
    logic   [s_axi4l.ADDR_BITS-1:0] awaddr;
    logic   [s_axi4l.PROT_BITS-1:0] awprot;
    logic   [s_axi4l.STRB_BITS-1:0] wstrb;
    logic   [s_axi4l.STRB_BITS-1:0] wdata;
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            write_busy  <= 1'b0;
            for ( int i = 0; i < NUM; i++ ) begin
                m_axi4l[i].awvalid <= 1'b0;
            end
            for ( int i = 0; i < NUM; i++ ) begin
                m_axi4l[i].wvalid <= 1'b0;
            end
            s_axi4l.bvalid <= 1'b0;
        end
        else begin
            // finish
            for ( int i = 0; i < NUM; i++ ) begin
                if ( m_axi4l[i].awvalid && m_axi4l[i].awready ) begin
                    m_axi4l[i].awvalid <= 1'b0;
                end
                if ( m_axi4l[i].wvalid && m_axi4l[i].wready ) begin
                    m_axi4l[i].wvalid  <= 1'b0;
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
                awaddr <= s_axi4l.awaddr;
                awprot <= s_axi4l.awprot;
                wstrb  <= s_axi4l.wstrb ;
                wdata  <= s_axi4l.wdata ;
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( awaddr_match[i] ) begin
                        m_axi4l[i].awvalid <= 1'b1;
                        m_axi4l[i].wvalid  <= 1'b1;
                    end
                end
                if ( awaddr_other ) begin
                    s_axi4l.bresp  <= '0;
                    s_axi4l.bvalid <= 1'b1;
                end
            end

            // response
            for ( int i = 0; i < NUM; i++ ) begin
                if ( m_axi4l[i].bvalid && m_axi4l[i].bready ) begin
                    s_axi4l.bresp  <= m_axi4l[i].bresp;
                    s_axi4l.bvalid <= 1'b1;
                end
            end
        end
    end

    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_axi4l[i].awaddr = m_axi4l[i].awvalid ? awaddr : 'x;
        assign m_axi4l[i].awprot = m_axi4l[i].awvalid ? awprot : 'x;
        assign m_axi4l[i].wstrb  = m_axi4l[i].wvalid  ? wstrb  : 'x;
        assign m_axi4l[i].wdata  = m_axi4l[i].wvalid  ? wdata  : 'x;
    end

    assign s_axi4l.awready = s_axi4l.wvalid  && (!write_busy || (s_axi4l.bvalid && s_axi4l.bready));
    assign s_axi4l.wready  = s_axi4l.awvalid && (!write_busy || (s_axi4l.bvalid && s_axi4l.bready));



    // read
    logic                           read_busy;
    logic   [s_axi4l.ADDR_BITS-1:0] araddr;
    logic   [s_axi4l.PROT_BITS-1:0] arprot;
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            read_busy  <= 1'b0;
            for ( int i = 0; i < NUM; i++ ) begin
                m_axi4l[i].arvalid <= 1'b0;
            end
            s_axi4l.rvalid <= 1'b0;
        end
        else begin
            // finish
            for ( int i = 0; i < NUM; i++ ) begin
                if ( m_axi4l[i].arvalid && m_axi4l[i].arready ) begin
                    m_axi4l[i].arvalid <= 1'b0;
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
                araddr <= s_axi4l.araddr;
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( araddr_match[i] ) begin
                        m_axi4l[i].arvalid <= 1'b1;
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
                if ( m_axi4l[i].rvalid && m_axi4l[i].rready ) begin
                    s_axi4l.rdata  <= m_axi4l[i].rdata;
                    s_axi4l.rresp  <= m_axi4l[i].rresp;
                    s_axi4l.bvalid <= 1'b1;
                end
            end
        end
    end

    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_axi4l[i].araddr = m_axi4l[i].arvalid ? araddr : 'x;
        assign m_axi4l[i].arprot = m_axi4l[i].arvalid ? arprot : 'x;
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
