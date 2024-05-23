// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4l_register
    #(
        parameter   int                             NUM  = 4,
        parameter   int                             BITS = 32,
        parameter   logic   [NUM-1:0][BITS-1:0]     INIT = '0
    )
    (
        jelly3_axi4l_if.s                       s_axi4l,
        output  logic   [NUM-1:0][BITS-1:0]     value
    );

    
    localparam  int     REG_ADDR_BITS = $clog2(NUM);
    localparam  int     REG_DATA_BITS = BITS;
    localparam  int     AXI_ADDR_BITS = s_axi4l.ADDR_BITS;
    localparam  int     AXI_DATA_BITS = s_axi4l.DATA_BITS;
    localparam  int     AXI_STRB_BITS = s_axi4l.STRB_BITS;
    localparam  int     AXI_UNIT_BITS = $clog2(s_axi4l.STRB_BITS);

    typedef logic   [REG_ADDR_BITS-1:0]        reg_addr_t;
    typedef logic   [REG_DATA_BITS-1:0]        reg_data_t;
    typedef logic   [s_axi4l.DATA_BITS-1:0]    axi_data_t;

    // write mask
    function [AXI_DATA_BITS-1:0] write_mask(
                                        input [AXI_DATA_BITS-1:0] org,
                                        input [AXI_DATA_BITS-1:0] wdat,
                                        input [AXI_STRB_BITS-1:0] msk
                                    );
    begin
        for ( int i = 0; i < AXI_DATA_BITS; ++i ) begin
            write_mask[i] = msk[i/8] ? wdat[i] : org[i];
        end
    end
    endfunction


    // address
    reg_addr_t  reg_waddr;
    reg_addr_t  reg_raddr;
    assign reg_waddr = s_axi4l.awaddr[AXI_UNIT_BITS +: REG_ADDR_BITS];
    assign reg_raddr = s_axi4l.araddr[AXI_UNIT_BITS +: REG_ADDR_BITS];

    // register
    reg_data_t  reg_data    [0:NUM-1];

    always_comb begin
        for ( int i = 0; i < NUM; i++ ) begin
            value[i] = reg_data[i];
        end
    end


    // write
    logic       bvalid;
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            for ( int i = 0; i < NUM; i++ ) begin
                reg_data[i] <= INIT[i];
            end
            bvalid <= 0;
        end
        else begin
            if ( s_axi4l.bready ) begin
                bvalid <= 0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready ) begin
                reg_data[reg_waddr] <= reg_data_t'(write_mask(axi_data_t'(reg_data[reg_waddr]), s_axi4l.wdata, s_axi4l.wstrb));
                bvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.awready = (~bvalid || s_axi4l.bready) && s_axi4l.wvalid;
    assign s_axi4l.wready  = (~bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;
    assign s_axi4l.bvalid  = bvalid;


    // read
    axi_data_t  rdata;
    logic       rvalid;
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            rdata  <= 'x;
            rvalid <= 1'b0;
        end
        else begin
            if ( s_axi4l.rready ) begin
                rdata  <= 'x;
                rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                rdata  <= reg_data[reg_raddr];
                rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.arready = ~rvalid || s_axi4l.rready;

    assign s_axi4l.rdata  = rdata;
    assign s_axi4l.rresp  = '0;
    assign s_axi4l.rvalid = rvalid;

endmodule


`default_nettype wire


// end of file
