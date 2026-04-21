// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_axi4_terminator
        #(
            parameter   int                             AXI4_ID_WIDTH    = 6,
            parameter   int                             AXI4_ADDR_WIDTH  = 32,
            parameter   int                             AXI4_DATA_SIZE   = 2,
            parameter   int                             AXI4_DATA_WIDTH  = (8 << AXI4_DATA_SIZE),
            parameter   int                             AXI4_STRB_WIDTH  = AXI4_DATA_WIDTH / 8,
            parameter   int                             AXI4_LEN_WIDTH   = 8,
            parameter   int                             AXI4_QOS_WIDTH   = 4,
            parameter   logic   [AXI4_DATA_WIDTH-1:0]  READ_VALUE       = '0
        )
        (
            input   var logic                           s_axi4_aresetn,
            input   var logic                           s_axi4_aclk,

            input   var logic   [AXI4_ID_WIDTH-1:0]    s_axi4_awid,
            input   var logic   [AXI4_ADDR_WIDTH-1:0]  s_axi4_awaddr,
            input   var logic   [AXI4_LEN_WIDTH-1:0]   s_axi4_awlen,
            input   var logic   [2:0]                   s_axi4_awsize,
            input   var logic   [1:0]                   s_axi4_awburst,
            input   var logic   [0:0]                   s_axi4_awlock,
            input   var logic   [3:0]                   s_axi4_awcache,
            input   var logic   [2:0]                   s_axi4_awprot,
            input   var logic   [AXI4_QOS_WIDTH-1:0]   s_axi4_awqos,
            input   var logic   [3:0]                   s_axi4_awregion,
            input   var logic                           s_axi4_awvalid,
            output  var logic                           s_axi4_awready,

            input   var logic   [AXI4_DATA_WIDTH-1:0]  s_axi4_wdata,
            input   var logic   [AXI4_STRB_WIDTH-1:0]  s_axi4_wstrb,
            input   var logic                           s_axi4_wlast,
            input   var logic                           s_axi4_wvalid,
            output  var logic                           s_axi4_wready,

            output  var logic   [AXI4_ID_WIDTH-1:0]    s_axi4_bid,
            output  var logic   [1:0]                   s_axi4_bresp,
            output  var logic                           s_axi4_bvalid,
            input   var logic                           s_axi4_bready,

            input   var logic   [AXI4_ID_WIDTH-1:0]    s_axi4_arid,
            input   var logic   [AXI4_ADDR_WIDTH-1:0]  s_axi4_araddr,
            input   var logic   [AXI4_LEN_WIDTH-1:0]   s_axi4_arlen,
            input   var logic   [2:0]                   s_axi4_arsize,
            input   var logic   [1:0]                   s_axi4_arburst,
            input   var logic   [0:0]                   s_axi4_arlock,
            input   var logic   [3:0]                   s_axi4_arcache,
            input   var logic   [2:0]                   s_axi4_arprot,
            input   var logic   [AXI4_QOS_WIDTH-1:0]   s_axi4_arqos,
            input   var logic   [3:0]                   s_axi4_arregion,
            input   var logic                           s_axi4_arvalid,
            output  var logic                           s_axi4_arready,

            output  var logic   [AXI4_ID_WIDTH-1:0]    s_axi4_rid,
            output  var logic   [AXI4_DATA_WIDTH-1:0]  s_axi4_rdata,
            output  var logic   [1:0]                   s_axi4_rresp,
            output  var logic                           s_axi4_rlast,
            output  var logic                           s_axi4_rvalid,
            input   var logic                           s_axi4_rready
        );

    jelly2_axi4_write_terminator
            #(
                .AXI4_ID_WIDTH      (AXI4_ID_WIDTH),
                .AXI4_ADDR_WIDTH    (AXI4_ADDR_WIDTH),
                .AXI4_DATA_SIZE     (AXI4_DATA_SIZE),
                .AXI4_DATA_WIDTH    (AXI4_DATA_WIDTH),
                .AXI4_STRB_WIDTH    (AXI4_STRB_WIDTH),
                .AXI4_LEN_WIDTH     (AXI4_LEN_WIDTH),
                .AXI4_QOS_WIDTH     (AXI4_QOS_WIDTH)
            )
        i_axi4_write_terminator
            (
                .s_axi4_aresetn     (s_axi4_aresetn),
                .s_axi4_aclk        (s_axi4_aclk),
                .s_axi4_awid        (s_axi4_awid),
                .s_axi4_awaddr      (s_axi4_awaddr),
                .s_axi4_awlen       (s_axi4_awlen),
                .s_axi4_awsize      (s_axi4_awsize),
                .s_axi4_awburst     (s_axi4_awburst),
                .s_axi4_awlock      (s_axi4_awlock),
                .s_axi4_awcache     (s_axi4_awcache),
                .s_axi4_awprot      (s_axi4_awprot),
                .s_axi4_awqos       (s_axi4_awqos),
                .s_axi4_awregion    (s_axi4_awregion),
                .s_axi4_awvalid     (s_axi4_awvalid),
                .s_axi4_awready     (s_axi4_awready),
                .s_axi4_wdata       (s_axi4_wdata),
                .s_axi4_wstrb       (s_axi4_wstrb),
                .s_axi4_wlast       (s_axi4_wlast),
                .s_axi4_wvalid      (s_axi4_wvalid),
                .s_axi4_wready      (s_axi4_wready),
                .s_axi4_bid         (s_axi4_bid),
                .s_axi4_bresp       (s_axi4_bresp),
                .s_axi4_bvalid      (s_axi4_bvalid),
                .s_axi4_bready      (s_axi4_bready)
            );

    jelly2_axi4_read_terminator
            #(
                .AXI4_ID_WIDTH      (AXI4_ID_WIDTH),
                .AXI4_ADDR_WIDTH    (AXI4_ADDR_WIDTH),
                .AXI4_DATA_SIZE     (AXI4_DATA_SIZE),
                .AXI4_DATA_WIDTH    (AXI4_DATA_WIDTH),
                .AXI4_LEN_WIDTH     (AXI4_LEN_WIDTH),
                .AXI4_QOS_WIDTH     (AXI4_QOS_WIDTH),
                .READ_VALUE         (READ_VALUE)
            )
        i_axi4_read_terminator
            (
                .s_axi4_aresetn     (s_axi4_aresetn),
                .s_axi4_aclk        (s_axi4_aclk),
                .s_axi4_arid        (s_axi4_arid),
                .s_axi4_araddr      (s_axi4_araddr),
                .s_axi4_arlen       (s_axi4_arlen),
                .s_axi4_arsize      (s_axi4_arsize),
                .s_axi4_arburst     (s_axi4_arburst),
                .s_axi4_arlock      (s_axi4_arlock),
                .s_axi4_arcache     (s_axi4_arcache),
                .s_axi4_arprot      (s_axi4_arprot),
                .s_axi4_arqos       (s_axi4_arqos),
                .s_axi4_arregion    (s_axi4_arregion),
                .s_axi4_arvalid     (s_axi4_arvalid),
                .s_axi4_arready     (s_axi4_arready),
                .s_axi4_rid         (s_axi4_rid),
                .s_axi4_rdata       (s_axi4_rdata),
                .s_axi4_rresp       (s_axi4_rresp),
                .s_axi4_rlast       (s_axi4_rlast),
                .s_axi4_rvalid      (s_axi4_rvalid),
                .s_axi4_rready      (s_axi4_rready)
            );

endmodule


`default_nettype wire


// end of file