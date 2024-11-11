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
            jelly3_axi4_if.s        s_axi4  ,
            jelly3_bram_if.m        m_bram  
        );

    wire    logic   reset = ~s_axi4.aresetn || m_bram.reset ;
    wire    logic   clk   = s_axi4.aclk                     ;
    wire    logic   cke   = s_axi4.aclken                   ;

    localparam int  ADDR_UNIT    = s_axi4.STRB_BITS;

    localparam type axi4_id_t    = logic [s_axi4.ID_BITS-1:0]   ;
    localparam type axi4_addr_t  = logic [s_axi4.ADDR_BITS-1:0] ;
    localparam type axi4_len_t   = logic [s_axi4.LEN_BITS-1:0]  ;
    localparam type axi4_size_t  = logic [s_axi4.SIZE_BITS-1:0] ;
    localparam type axi4_burst_t = logic [s_axi4.BURST_BITS-1:0];
    localparam type axi4_data_t  = logic [s_axi4.DATA_BITS-1:0] ;
    localparam type axi4_strb_t  = logic [s_axi4.STRB_BITS-1:0] ;

    localparam type bram_id_t    = logic [m_bram.ID_BITS-1:0]   ;
    localparam type bram_addr_t  = logic [m_bram.ADDR_BITS-1:0] ;
    localparam type bram_data_t  = logic [m_bram.DATA_BITS-1:0] ;
    localparam type bram_strb_t  = logic [m_bram.STRB_BITS-1:0] ;

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

    // command
    logic           busy    ;
    logic           busyw   ;
    logic           busyr   ;
    axi4_id_t       id      ;
    axi4_addr_t     addr    ;
    axi4_len_t      len     ;
    axi4_addr_t     inc     ;
    axi4_addr_t     mask    ;
    logic           last    ;
    logic           cvalid  ;
    logic           cready  ;
    always_ff @(posedge clk) begin
        if (reset) begin
            busy  <= 1'b0   ;
            busyw <= 1'b0   ;
            busyr <= 1'b0   ;
            id    <= 'x     ;
            addr  <= 'x     ;
            len   <= 'x     ;
            last  <= 'x     ;
            inc   <= 'x     ;
            mask  <= 'x     ;
        end
        else if ( cke ) begin
            if ( s_axi4.awvalid && s_axi4.awready ) begin
                busy  <= 1'b1               ;
                busyw <= 1'b1               ;
                busyr <= 1'b0               ;
                id    <= s_axi4.awid        ;
                addr  <= s_axi4.awaddr      ;
                len   <= s_axi4.awlen       ;
                last  <= s_axi4.awlen == '0 ;
                inc   <= calc_inc(s_axi4.awburst, s_axi4.awsize);
                mask  <= calc_mask(s_axi4.awburst, s_axi4.awlen);
            end
            else if ( s_axi4.arvalid && s_axi4.arready ) begin
                busy  <= 1'b1               ;
                busyw <= 1'b0               ;
                busyr <= 1'b1               ;
                id    <= s_axi4.arid        ;
                addr  <= s_axi4.araddr      ;
                len   <= s_axi4.arlen       ;
                last  <= s_axi4.arlen == '0 ;
                inc   <= calc_inc(s_axi4.arburst, s_axi4.arsize);
                mask  <= calc_mask(s_axi4.arburst, s_axi4.arlen);
            end
            else if ( cvalid && cready ) begin
                addr <= (addr & ~mask) | ((addr + inc) & mask);
                len  <= len - 1;
                last <= len == 1;
                if ( last ) begin
                    addr  <= 'x     ;
                    len   <= 'x     ;
                    last  <= 'x     ;
                    busy  <= 1'b0   ;
                    busyw <= 1'b0   ;
                    busyr <= 1'b0   ;
                end
            end
        end
    end

    assign cvalid = (busyw && s_axi4.wvalid) || busyr;
    assign cready = m_bram.cready;

    assign m_bram.cid    = id;
    assign m_bram.cread  = busyr;
    assign m_bram.cwrite = (busyw && s_axi4.wvalid);
    assign m_bram.caddr  = bram_addr_t'(addr / ADDR_UNIT);
    assign m_bram.clast  = last;
    assign m_bram.cstrb  = busyw ? bram_strb_t'(s_axi4.wstrb) : '0;
    assign m_bram.cdata  = bram_data_t'(s_axi4.wdata);
    assign m_bram.cvalid = cvalid;

    assign s_axi4.awready = (!busy || (cready && last)) && !(s_axi4.bvalid && !s_axi4.bready);
    assign s_axi4.wready  = busyw && m_bram.cready;
    assign s_axi4.arready = (!busy || (cready && last)) && !s_axi4.awvalid;

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
                s_axi4.bid    <= id;
                s_axi4.bvalid <= 1'b1;
            end
        end
    end
    assign s_axi4.bresp = 2'b00;


    // read response
    assign s_axi4.rid    = m_bram.rid   ;
    assign s_axi4.rresp  = 2'b00        ;
    assign s_axi4.rlast  = m_bram.rlast ;
    assign s_axi4.rdata  = axi4_data_t'(m_bram.rdata);
    assign s_axi4.rvalid = m_bram.rvalid;
    assign m_bram.rready = s_axi4.rready;


    initial begin
//      if ( $bits(bram_data_t) != $bits(axi4_data_t) ) begin
//          $error("ERROR: DATA_BITS of bram and axi4 must be same");
//      end
        if ( $bits(bram_id_t) != $bits(axi4_id_t) ) begin
            $error("ERROR: ID_BITS of bram and axi4 must be same");
        end
    end

    if ( SIMULATION == "true" ) begin
        always_comb begin
            sva_clk : assert (s_axi4.aclk   === m_bram.clk);
            sva_cke : assert (s_axi4.aclken === m_bram.cke);
        end
    end

endmodule


`default_nettype wire


// end of file
