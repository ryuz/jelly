// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_axi4l_terminator
        #(
            parameter   int                             AXI4L_ADDR_WIDTH = 32,
            parameter   int                             AXI4L_DATA_SIZE  = 2,   // 0:8bit, 1:16bit, 2:32bit ...
            parameter   int                             AXI4L_DATA_WIDTH = (8 << AXI4L_DATA_SIZE),
            parameter   int                             AXI4L_STRB_WIDTH = AXI4L_DATA_WIDTH / 8,
            parameter   logic   [AXI4L_DATA_WIDTH-1:0]  READ_VALUE       = '0
        )
        (
            input   var logic                           s_axi4l_aresetn,
            input   var logic                           s_axi4l_aclk,
            input   var logic   [AXI4L_ADDR_WIDTH-1:0]  s_axi4l_awaddr,
            input   var logic   [2:0]                   s_axi4l_awprot,
            input   var logic                           s_axi4l_awvalid,
            output  var logic                           s_axi4l_awready,
            input   var logic   [AXI4L_STRB_WIDTH-1:0]  s_axi4l_wstrb,
            input   var logic   [AXI4L_DATA_WIDTH-1:0]  s_axi4l_wdata,
            input   var logic                           s_axi4l_wvalid,
            output  var logic                           s_axi4l_wready,
            output  var logic   [1:0]                   s_axi4l_bresp,
            output  var logic                           s_axi4l_bvalid,
            input   var logic                           s_axi4l_bready,
            input   var logic   [AXI4L_ADDR_WIDTH-1:0]  s_axi4l_araddr,
            input   var logic   [2:0]                   s_axi4l_arprot,
            input   var logic                           s_axi4l_arvalid,
            output  var logic                           s_axi4l_arready,
            output  var logic   [AXI4L_DATA_WIDTH-1:0]  s_axi4l_rdata,
            output  var logic   [1:0]                   s_axi4l_rresp,
            output  var logic                           s_axi4l_rvalid,
            input   var logic                           s_axi4l_rready
        );

    // write
    logic       bvalid;
    always_ff @(posedge s_axi4l_aclk ) begin
        if ( ~s_axi4l_aresetn ) begin
            s_axi4l_bvalid <= 0;
        end
        else begin
            if ( s_axi4l_bready ) begin
                s_axi4l_bvalid <= 0;
            end
            if ( s_axi4l_awvalid && s_axi4l_awready ) begin
                s_axi4l_bvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l_awready = (~bvalid || s_axi4l_bready) && s_axi4l_wvalid;
    assign s_axi4l_wready  = (~bvalid || s_axi4l_bready) && s_axi4l_awvalid;
    assign s_axi4l_bresp   = '0;


    // read
    always_ff @(posedge s_axi4l_aclk ) begin
        if ( ~s_axi4l_aresetn ) begin
            s_axi4l_rvalid <= 1'b0;
        end
        else begin
            if ( s_axi4l_rready ) begin
                s_axi4l_rvalid <= 1'b0;
            end
            if ( s_axi4l_arvalid && s_axi4l_arready ) begin
                s_axi4l_rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l_arready = ~s_axi4l_rvalid || s_axi4l_rready;
    assign s_axi4l_rdata  = READ_VALUE;
    assign s_axi4l_rresp  = '0;

endmodule


`default_nettype wire


// end of file
