// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4_to_bram_dp
        #(
            parameter           DEVICE     = "RTL"      ,
            parameter           SIMULATION = "false"    ,
            parameter           DEBUG      = "false"    
        )
        (
            jelly3_axi4_if.s        s_axi4  ,
            jelly3_bram_if.m        m_bram_w,
            jelly3_bram_if.m        m_bram_r
        );

    wire    logic   reset = ~s_axi4.aresetn || m_bram_w.reset || m_bram_r.reset ;
    wire    logic   clk   = s_axi4.aclk                                         ;
    wire    logic   cke   = s_axi4.aclken                                       ;

    localparam int  ADDR_UNIT    = s_axi4.STRB_BITS;

    localparam type axi4_id_t    = logic [s_axi4.ID_BITS-1:0]       ;
    localparam type axi4_addr_t  = logic [s_axi4.ADDR_BITS-1:0]     ;
    localparam type axi4_len_t   = logic [s_axi4.LEN_BITS-1:0]      ;
    localparam type axi4_size_t  = logic [s_axi4.SIZE_BITS-1:0]     ;
    localparam type axi4_burst_t = logic [s_axi4.BURST_BITS-1:0]    ;
    localparam type axi4_data_t  = logic [s_axi4.DATA_BITS-1:0]     ;
    localparam type axi4_strb_t  = logic [s_axi4.STRB_BITS-1:0]     ;

    localparam type bram_id_t    = logic [m_bram_w.ID_BITS-1:0]     ;
    localparam type bram_addr_t  = logic [m_bram_w.ADDR_BITS-1:0]   ;
    localparam type bram_data_t  = logic [m_bram_w.DATA_BITS-1:0]   ;
    localparam type bram_strb_t  = logic [m_bram_w.STRB_BITS-1:0]   ;

    localparam axi4_addr_t  ADDR_MASK = axi4_addr_t'('h0fff);

    function axi4_addr_t calc_inc(axi4_burst_t busrt, axi4_size_t size);
        case ( busrt )
            2'b00: return '0;          // FIXED
            2'b01: return (1 << size); // INCR
            2'b10: return (1 << size); // WRAP
            default: return 'x;        // reserved
        endcase
    endfunction

    function axi4_addr_t calc_mask(axi4_burst_t busrt, axi4_len_t len);
        case ( busrt )
            2'b00: return ADDR_MASK; // FIXED
            2'b01: return ADDR_MASK; // INCR
            2'b10: // WRAP
                case ( len )
                axi4_len_t'(1):  return ADDR_UNIT *  2 - 1;  // 2
                axi4_len_t'(3):  return ADDR_UNIT *  4 - 1;  // 4
                axi4_len_t'(7):  return ADDR_UNIT *  8 - 1;  // 8
                axi4_len_t'(15): return ADDR_UNIT * 16 - 1;  // 16
                default: return 'x;
                endcase
            default: return 'x; // reserved
        endcase
    endfunction


    // ---------------------------------
    //  Write
    // ---------------------------------

    // command
    logic           w_busy  ;
    axi4_id_t       w_id    ;
    axi4_addr_t     w_addr  ;
    axi4_len_t      w_len   ;
    axi4_addr_t     w_inc   ;
    axi4_addr_t     w_mask  ;
    logic           w_last  ;
    logic           w_cvalid;
    logic           w_cready;
    always_ff @(posedge clk) begin
        if (reset) begin
            w_busy  <= 1'b0   ;
            w_id    <= 'x     ;
            w_addr  <= 'x     ;
            w_len   <= 'x     ;
            w_last  <= 'x     ;
            w_inc   <= 'x     ;
            w_mask  <= 'x     ;
        end
        else if ( cke ) begin
            if ( s_axi4.awvalid && s_axi4.awready ) begin
                w_busy  <= 1'b1               ;
                w_id    <= s_axi4.awid        ;
                w_addr  <= s_axi4.awaddr      ;
                w_len   <= s_axi4.awlen       ;
                w_last  <= s_axi4.awlen == '0 ;
                w_inc   <= calc_inc(s_axi4.awburst, s_axi4.awsize);
                w_mask  <= calc_mask(s_axi4.awburst, s_axi4.awlen);
            end
            else if ( w_cvalid && w_cready ) begin
                w_addr <= (w_addr & ~w_mask) | ((w_addr + w_inc) & w_mask);
                w_len  <= w_len - 1;
                w_last <= w_len == 1;
                if ( w_last ) begin
                    w_addr <= 'x    ;
                    w_len  <= 'x    ;
                    w_busy <= 1'b0  ;
                end
            end
        end
    end

    assign w_cvalid = (w_busy && s_axi4.wvalid);
    assign w_cready = m_bram_w.cready;

    assign m_bram_w.cid    = w_id;
    assign m_bram_w.cread  = 1'b0;
    assign m_bram_w.cwrite = w_busy && s_axi4.wvalid;
    assign m_bram_w.caddr  = bram_addr_t'(w_addr / ADDR_UNIT);
    assign m_bram_w.clast  = w_last;
    assign m_bram_w.cstrb  = w_busy ? s_axi4.wstrb : '0;
    assign m_bram_w.cdata  = s_axi4.wdata;
    assign m_bram_w.cvalid = w_cvalid;

    assign s_axi4.awready = (!w_busy || (w_cready && w_last)) && !(s_axi4.bvalid && !s_axi4.bready);
    assign s_axi4.wready  = w_busy && m_bram_w.cready;
    assign s_axi4.arready = (!w_busy || (w_cready && w_last)) && !s_axi4.awvalid;

    // write response
    always_ff @(posedge clk) begin
        if (reset) begin
            s_axi4.bid    <= 'x;
            s_axi4.bvalid <= 1'b0;
        end
        else if ( cke ) begin
            if ( s_axi4.bready ) begin
                s_axi4.bid    <= 'x;
                s_axi4.bvalid <= 1'b0;
            end
            if ( s_axi4.wlast && s_axi4.wvalid && s_axi4.wready ) begin
                s_axi4.bid    <= w_id;
                s_axi4.bvalid <= 1'b1;
            end
        end
    end
    assign s_axi4.bresp = 2'b00;


    // ---------------------------------
    //  Read
    // ---------------------------------

    // command
    logic           r_busy  ;
    axi4_id_t       r_id    ;
    axi4_addr_t     r_addr  ;
    axi4_len_t      r_len   ;
    axi4_addr_t     r_inc   ;
    axi4_addr_t     r_mask  ;
    logic           r_last  ;
    logic           r_cvalid;
    logic           r_cready;
    always_ff @(posedge clk) begin
        if (reset) begin
            r_busy  <= 1'b0 ;
            r_id    <= 'x   ;
            r_addr  <= 'x   ;
            r_len   <= 'x   ;
            r_last  <= 'x   ;
            r_inc   <= 'x   ;
            r_mask  <= 'x   ;
        end
        else if ( cke ) begin
            if ( s_axi4.arvalid && s_axi4.arready ) begin
                r_busy  <= 1'b1                 ;
                r_id    <= s_axi4.arid          ;
                r_addr  <= s_axi4.araddr        ;
                r_len   <= s_axi4.arlen         ;
                r_last  <= s_axi4.arlen == '0   ;
                r_inc   <= calc_inc(s_axi4.arburst, s_axi4.arsize);
                r_mask  <= calc_mask(s_axi4.arburst, s_axi4.arlen);
            end
            else if ( r_cvalid && r_cready ) begin
                r_addr <= (r_addr & ~r_mask) | ((r_addr + r_inc) & r_mask);
                r_len  <= r_len - 1;
                r_last <= r_len == 1;
                if ( r_last ) begin
                    r_addr <= 'x;
                    r_len  <= 'x;
                    r_last <= 'x;
                    r_busy <= 1'b0;
                end
            end
        end
    end

    assign r_cvalid = r_busy;
    assign r_cready = m_bram_r.cready;

    assign m_bram_r.cid    = r_id;
    assign m_bram_r.cread  = r_busy;
    assign m_bram_r.cwrite = 1'b0;
    assign m_bram_r.caddr  = bram_addr_t'(r_addr / ADDR_UNIT);
    assign m_bram_r.clast  = r_last;
    assign m_bram_r.cstrb  = '0;
    assign m_bram_r.cdata  = '0;
    assign m_bram_r.cvalid = r_cvalid;

    assign s_axi4.arready  = !r_busy || (r_cready && r_last);

    // read response
    assign s_axi4.rid      = m_bram_r.rid   ;
    assign s_axi4.rresp    = 2'b00          ;
    assign s_axi4.rlast    = m_bram_r.rlast ;
    assign s_axi4.rdata    = m_bram_r.rdata ;
    assign s_axi4.rvalid   = m_bram_r.rvalid;
    assign m_bram_r.rready = s_axi4.rready  ;



    initial begin
        if ( $bits(bram_data_t) != $bits(axi4_data_t) ) begin
            $error("ERROR: DATA_BITS of bram and axi4 must be same");
        end
        if ( $bits(bram_id_t) != $bits(axi4_id_t) ) begin
            $error("ERROR: ID_BITS of bram and axi4 must be same");
        end
    end

    if ( SIMULATION == "true" ) begin
        always_comb begin
            sva_clk_w : assert (s_axi4.aclk   === m_bram_w.clk);
            sva_cke_w : assert (s_axi4.aclken === m_bram_w.cke);
            sva_clk_r : assert (s_axi4.aclk   === m_bram_r.clk);
            sva_cke_r : assert (s_axi4.aclken === m_bram_r.cke);
        end
    end

endmodule


`default_nettype wire


// end of file
