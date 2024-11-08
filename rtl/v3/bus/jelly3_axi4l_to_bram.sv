// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4_to_bram
        #(
            parameter           DEVICE     = "RTL"      ,
            parameter           SIMULATION = "false"    ,
            parameter           DEBUG      = "false"    
        )
        (
            jelly3_axi4l_if.s       s_axi4l ,
            jelly3_bram_if.m        m_bram  
        );

    wire    logic   reset = ~s_axi4l.aresetn || m_bram.reset ;
    wire    logic   clk   = s_axi4l.aclk                     ;
    wire    logic   cke   = s_axi4l.aclken                   ;

    localparam int  ADDR_UNIT    = s_axi4.STRB_BITS;

    localparam type axi4l_addr_t = logic [s_axi4l.ADDR_BITS-1:0] ;
    localparam type axi4l_data_t = logic [s_axi4l.DATA_BITS-1:0] ;
    localparam type axi4l_strb_t = logic [s_axi4l.STRB_BITS-1:0] ;

    localparam type bram_id_t    = logic [m_bram.ID_BITS-1:0]   ;
    localparam type bram_addr_t  = logic [m_bram.ADDR_BITS-1:0] ;
    localparam type bram_data_t  = logic [m_bram.DATA_BITS-1:0] ;
    localparam type bram_strb_t  = logic [m_bram.STRB_BITS-1:0] ;
    
    // command
    logic           busy    ;
    logic           busyw   ;
    logic           busyr   ;
    axi4l_addr_t    addr    ;
    logic           cvalid  ;
    logic           cready  ;
    always_ff @(posedge clk) begin
        if (reset) begin
            busy  <= 1'b0   ;
            busyw <= 1'b0   ;
            busyr <= 1'b0   ;
            addr  <= 'x     ;
        end
        else if ( cke ) begin
            if ( s_axi4l.awvalid && s_axi4l.awready ) begin
                busy  <= 1'b1               ;
                busyw <= 1'b1               ;
                busyr <= 1'b0               ;
                addr  <= s_axi4l.awaddr     ;
            end
            else if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                busy  <= 1'b1               ;
                busyw <= 1'b0               ;
                busyr <= 1'b1               ;
                addr  <= s_axi4l.araddr     ;
            end
            else if ( cvalid && cready ) begin
                busy  <= 1'b0;
                busyw <= 1'b0;
                busyr <= 1'b0;
            end
        end
    end

    assign cvalid = (busyw && s_axi4l.wvalid) || busyr;
    assign cready = m_bram.cready;

    assign m_bram.cid    = '0;
    assign m_bram.cread  = busyr;
    assign m_bram.cwrite = (busyw && s_axi4l.wvalid);
    assign m_bram.caddr  = bram_addr_t'(addr / ADDR_UNIT);
    assign m_bram.clast  = 1'b1;
    assign m_bram.cstrb  = busyw ? s_axi4l.wstrb : '0;
    assign m_bram.cdata  = s_axi4l.wdata;
    assign m_bram.cvalid = cvalid;

    assign s_axi4l.awready = (!busy || cready) && !(s_axi4l.bvalid && !s_axi4l.bready);
    assign s_axi4l.wready  = busyw && m_bram.cready;
    assign s_axi4l.arready = (!busy || cready) && !s_axi4l.awvalid;

    // write response
    always_ff @(posedge clk) begin
        if (reset) begin
            s_axi4l.bvalid <= 1'b0;
        end
        else if ( cke ) begin
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 1'b0;
            end
            if ( s_axi4l.wvalid && s_axi4l.wready ) begin
                s_axi4l.bvalid <= 1'b1;
            end
        end
    end
    assign s_axi4l.bresp = 2'b00;


    // read response
    assign s_axi4l.rresp  = 2'b00        ;
    assign s_axi4l.rdata  = m_bram.rdata ;
    assign s_axi4l.rvalid = m_bram.rvalid;
    assign m_bram.rready = s_axi4l.rready;

    initial begin
        if ( $bits(bram_data_t) != $bits(axi4l_data_t) ) begin
            $error("ERROR: DATA_BITS of bram and axi4l must be same");
        end
    end

    if ( SIMULATION == "true" ) begin
        always_comb begin
            sva_clk : assert (s_axi4l.aclk   === m_bram.clk);
            sva_cke : assert (s_axi4l.aclken === m_bram.cke);
        end
    end

endmodule


`default_nettype wire


// end of file
