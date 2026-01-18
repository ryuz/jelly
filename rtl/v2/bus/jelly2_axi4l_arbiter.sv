// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_axi4l_arbiter
        #(
            parameter   int NUM = 4,
            parameter   int AXI4L_ADDR_WIDTH = 32,
            parameter   int AXI4L_DATA_SIZE  = 2,   // 0:8bit, 1:16bit, 2:32bit ...
            parameter   int AXI4L_DATA_WIDTH = (8 << AXI4L_DATA_SIZE),
            parameter   int AXI4L_STRB_WIDTH = AXI4L_DATA_WIDTH / 8
        )
        (
            input   var logic                                   aresetn,
            input   var logic                                   aclk,
            input   var logic                                   aclken,

            input   var logic   [NUM-1:0][AXI4L_ADDR_WIDTH-1:0] s_axi4l_awaddr,
            input   var logic   [NUM-1:0][2:0]                  s_axi4l_awprot,
            input   var logic   [NUM-1:0]                       s_axi4l_awvalid,
            output  var logic   [NUM-1:0]                       s_axi4l_awready,
            input   var logic   [NUM-1:0][AXI4L_STRB_WIDTH-1:0] s_axi4l_wstrb,
            input   var logic   [NUM-1:0][AXI4L_DATA_WIDTH-1:0] s_axi4l_wdata,
            input   var logic   [NUM-1:0]                       s_axi4l_wvalid,
            output  var logic   [NUM-1:0]                       s_axi4l_wready,
            output  var logic   [NUM-1:0][1:0]                  s_axi4l_bresp,
            output  var logic   [NUM-1:0]                       s_axi4l_bvalid,
            input   var logic   [NUM-1:0]                       s_axi4l_bready,
            input   var logic   [NUM-1:0][AXI4L_ADDR_WIDTH-1:0] s_axi4l_araddr,
            input   var logic   [NUM-1:0][2:0]                  s_axi4l_arprot,
            input   var logic   [NUM-1:0]                       s_axi4l_arvalid,
            output  var logic   [NUM-1:0]                       s_axi4l_arready,
            output  var logic   [NUM-1:0][AXI4L_DATA_WIDTH-1:0] s_axi4l_rdata,
            output  var logic   [NUM-1:0][1:0]                  s_axi4l_rresp,
            output  var logic   [NUM-1:0]                       s_axi4l_rvalid,
            input   var logic   [NUM-1:0]                       s_axi4l_rready,

            output  var logic   [AXI4L_ADDR_WIDTH-1:0]          m_axi4l_awaddr,
            output  var logic   [2:0]                           m_axi4l_awprot,
            output  var logic                                   m_axi4l_awvalid,
            input   var logic                                   m_axi4l_awready,
            output  var logic   [AXI4L_STRB_WIDTH-1:0]          m_axi4l_wstrb,
            output  var logic   [AXI4L_DATA_WIDTH-1:0]          m_axi4l_wdata,
            output  var logic                                   m_axi4l_wvalid,
            input   var logic                                   m_axi4l_wready,
            input   var logic   [1:0]                           m_axi4l_bresp,
            input   var logic                                   m_axi4l_bvalid,
            output  var logic                                   m_axi4l_bready,
            output  var logic   [AXI4L_ADDR_WIDTH-1:0]          m_axi4l_araddr,
            output  var logic   [2:0]                           m_axi4l_arprot,
            output  var logic                                   m_axi4l_arvalid,
            input   var logic                                   m_axi4l_arready,
            input   var logic   [AXI4L_DATA_WIDTH-1:0]          m_axi4l_rdata,
            input   var logic   [1:0]                           m_axi4l_rresp,
            input   var logic                                   m_axi4l_rvalid,
            output  var logic                                   m_axi4l_rready

        );

    localparam  int     SEL_WIDTH = NUM > 1 ? $clog2(NUM) : 1;

    // write arbiter
    logic                   write_busy  ;
    logic   [SEL_WIDTH-1:0] write_sel   ;
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

    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            write_busy      <= 1'b0 ;
            write_sel       <= 'x   ;
            s_axi4l_bresp   <= 'x   ;
            s_axi4l_bvalid  <= '0   ;
            m_axi4l_awaddr  <= 'x   ;
            m_axi4l_awprot  <= 'x   ;
            m_axi4l_awvalid <= 1'b0 ;
            m_axi4l_wstrb   <= 'x   ;
            m_axi4l_wdata   <= 'x   ;
            m_axi4l_wvalid  <= 1'b0 ;
        end
        else if ( aclken ) begin
            if ( m_axi4l_awready )  m_axi4l_awvalid <= 1'b0 ;
            if ( m_axi4l_wready  )  m_axi4l_wvalid  <= 1'b0 ;

            for ( int i = 0; i < NUM; i++ ) begin
                if ( s_axi4l_awvalid[i] && s_axi4l_awready[i]
                        && s_axi4l_wvalid[i] && s_axi4l_wready[i] ) begin
                    write_busy      <= 1'b1     ;
                    write_sel       <= SEL_WIDTH'(i);
                    m_axi4l_awaddr  <= s_axi4l_awaddr [i];
                    m_axi4l_awprot  <= s_axi4l_awprot [i];
                    m_axi4l_awvalid <= s_axi4l_awvalid[i];
                    m_axi4l_wstrb   <= s_axi4l_wstrb  [i];
                    m_axi4l_wdata   <= s_axi4l_wdata  [i];
                    m_axi4l_wvalid  <= s_axi4l_wvalid [i];
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

            if ( m_axi4l_bvalid ) begin
                s_axi4l_bresp [write_sel] <= m_axi4l_bresp  ;
                s_axi4l_bvalid[write_sel] <= m_axi4l_bvalid ;
            end
        end
    end

    assign m_axi4l_bready = 1'b1;


    // read arbiter
    logic                   read_busy   ;
    logic   [SEL_WIDTH-1:0] read_sel    ;

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

    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            read_busy       <= 1'b0 ;
            read_sel        <= 'x   ;
            s_axi4l_rresp   <= 'x   ;
            s_axi4l_rdata   <= 'x   ;
            s_axi4l_rvalid  <= '0   ;
            m_axi4l_araddr  <= 'x   ;
            m_axi4l_arprot  <= 'x   ;
            m_axi4l_arvalid <= 1'b0 ;
        end
        else if ( aclken ) begin
            if ( m_axi4l_arready )  m_axi4l_arvalid <= 1'b0 ;

            for ( int i = 0; i < NUM; i++ ) begin
                if ( s_axi4l_arvalid[i] && s_axi4l_arready[i] ) begin
                    read_busy       <= 1'b1;
                    read_sel        <= SEL_WIDTH'(i);
                    m_axi4l_araddr  <= s_axi4l_araddr [i];
                    m_axi4l_arprot  <= s_axi4l_arprot [i];
                    m_axi4l_arvalid <= s_axi4l_arvalid[i];
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

            if ( m_axi4l_rvalid ) begin
                s_axi4l_rresp [read_sel] <= m_axi4l_rresp   ;
                s_axi4l_rdata [read_sel] <= m_axi4l_rdata   ;
                s_axi4l_rvalid[read_sel] <= m_axi4l_rvalid  ;
            end
        end
    end

    assign m_axi4l_rready = 1'b1;

endmodule


`default_nettype wire


// end of file
