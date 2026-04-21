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

    logic   [AXI4_ID_WIDTH-1:0]    reg_awid;
    logic   [AXI4_LEN_WIDTH-1:0]   reg_awlen;
    logic                           reg_wbusy;

    logic   [AXI4_ID_WIDTH-1:0]    reg_arid;
    logic   [AXI4_LEN_WIDTH-1:0]   reg_arlen;
    logic                           reg_rbusy;


    // write
    always_ff @(posedge s_axi4_aclk) begin
        if ( ~s_axi4_aresetn ) begin
            reg_awid      <= 'x;
            reg_awlen     <= 'x;
            reg_wbusy     <= 1'b0;
            s_axi4_bid    <= 'x;
            s_axi4_bvalid <= 1'b0;
        end
        else begin
            if ( s_axi4_bvalid && s_axi4_bready ) begin
                s_axi4_bvalid <= 1'b0;
            end

            if ( s_axi4_awvalid && s_axi4_awready ) begin
                reg_awid  <= s_axi4_awid;
                reg_awlen <= s_axi4_awlen;
                reg_wbusy <= 1'b1;
            end

            if ( s_axi4_wvalid && s_axi4_wready ) begin
                if ( reg_awlen == '0 ) begin
                    reg_wbusy     <= 1'b0;
                    s_axi4_bid    <= reg_awid;
                    s_axi4_bvalid <= 1'b1;
                end
                else begin
                    reg_awlen <= reg_awlen - AXI4_LEN_WIDTH'(1);
                end
            end
        end
    end

    assign s_axi4_awready = !reg_wbusy && !(s_axi4_bvalid && !s_axi4_bready);
    assign s_axi4_wready  = reg_wbusy;
    assign s_axi4_bresp   = '0;


    // read
    always_ff @(posedge s_axi4_aclk) begin
        if ( ~s_axi4_aresetn ) begin
            reg_arid      <= 'x;
            reg_arlen     <= 'x;
            reg_rbusy     <= 1'b0;
            s_axi4_rvalid <= 1'b0;
        end
        else begin
            if ( s_axi4_arvalid && s_axi4_arready ) begin
                reg_arid      <= s_axi4_arid;
                reg_arlen     <= s_axi4_arlen;
                reg_rbusy     <= 1'b1;
                s_axi4_rvalid <= 1'b1;
            end
            else if ( s_axi4_rvalid && s_axi4_rready ) begin
                if ( reg_arlen == '0 ) begin
                    reg_rbusy     <= 1'b0;
                    s_axi4_rvalid <= 1'b0;
                end
                else begin
                    reg_arlen <= reg_arlen - AXI4_LEN_WIDTH'(1);
                end
            end
        end
    end

    assign s_axi4_arready = !reg_rbusy;
    assign s_axi4_rid     = reg_arid;
    assign s_axi4_rdata   = READ_VALUE;
    assign s_axi4_rresp   = '0;
    assign s_axi4_rlast   = (reg_arlen == '0);

endmodule


`default_nettype wire


// end of file