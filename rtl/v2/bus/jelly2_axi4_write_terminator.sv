// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_axi4_write_terminator
        #(
            parameter   int                             AXI4_ID_WIDTH    = 6,
            parameter   int                             AXI4_ADDR_WIDTH  = 32,
            parameter   int                             AXI4_DATA_SIZE   = 2,
            parameter   int                             AXI4_DATA_WIDTH  = (8 << AXI4_DATA_SIZE),
            parameter   int                             AXI4_STRB_WIDTH  = AXI4_DATA_WIDTH / 8,
            parameter   int                             AXI4_LEN_WIDTH   = 8,
            parameter   int                             AXI4_QOS_WIDTH   = 4
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
            input   var logic                           s_axi4_bready
        );

    logic   [AXI4_ID_WIDTH-1:0]    reg_awid;
    logic   [AXI4_LEN_WIDTH-1:0]   reg_awlen;
    logic                           reg_wbusy;

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

endmodule


`default_nettype wire


// end of file