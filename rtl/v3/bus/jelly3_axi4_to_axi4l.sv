// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// AXI4 to AXI4-Lite bridge
//
// Converts AXI4 burst transactions to a sequence of AXI4-Lite single-beat
// transactions.  Write and read paths are independent and may run concurrently.
//
// Restrictions:
//   - DATA_BITS and ADDR_BITS must match between s_axi4 and m_axi4l.
//   - One burst at a time per direction (no write-channel interleaving).

module jelly3_axi4_to_axi4l
        #(
            parameter           DEVICE     = "RTL"      ,
            parameter           SIMULATION = "false"    ,
            parameter           DEBUG      = "false"    
        )
        (
            jelly3_axi4_if.s    s_axi4  ,
            jelly3_axi4l_if.m   m_axi4l 
        );

    wire    logic   reset = ~s_axi4.aresetn ;
    wire    logic   clk   = s_axi4.aclk     ;
    wire    logic   cke   = s_axi4.aclken   ;

    localparam int  ADDR_UNIT    = s_axi4.STRB_BITS;

    localparam type id_t     = logic [s_axi4.ID_BITS   -1:0];
    localparam type addr_t   = logic [s_axi4.ADDR_BITS -1:0];
    localparam type len_t    = logic [s_axi4.LEN_BITS  -1:0];
    localparam type size_t   = logic [s_axi4.SIZE_BITS -1:0];
    localparam type burst_t  = logic [s_axi4.BURST_BITS-1:0];
    localparam type data_t   = logic [s_axi4.DATA_BITS -1:0];
    localparam type strb_t   = logic [s_axi4.STRB_BITS -1:0];
    localparam type prot_t   = logic [s_axi4.PROT_BITS -1:0];

    localparam addr_t ADDR_MASK = addr_t'('h0fff);

    function addr_t calc_inc(burst_t burst, size_t size);
        case (burst)
            2'b00: return '0;                     // FIXED
            2'b01: return addr_t'(1 << size);      // INCR
            2'b10: return addr_t'(1 << size);      // WRAP
            default: return 'x;
        endcase
    endfunction

    function addr_t calc_mask(burst_t burst, len_t len);
        case (burst)
            2'b00: return ADDR_MASK;              // FIXED
            2'b01: return ADDR_MASK;              // INCR
            2'b10:                                 // WRAP
                case (len)
                len_t'(1):  return addr_t'(ADDR_UNIT *  2 - 1);
                len_t'(3):  return addr_t'(ADDR_UNIT *  4 - 1);
                len_t'(7):  return addr_t'(ADDR_UNIT *  8 - 1);
                len_t'(15): return addr_t'(ADDR_UNIT * 16 - 1);
                default:    return 'x;
                endcase
            default: return 'x;
        endcase
    endfunction


    // -------------------------------------------------------------------------
    //  Write path
    // -------------------------------------------------------------------------
    //  Accepts one AXI4 AW transaction, then for each AXI4 W beat:
    //    1. Latches the W data.
    //    2. Issues an AXI4-Lite AW + W (channels are independent; each
    //       handshakes independently).
    //    3. Waits for the AXI4-Lite B response before accepting the next beat.
    //  After the last beat, issues a single AXI4 B response.
    // -------------------------------------------------------------------------

    // Write burst state
    logic   w_busy  ;   // processing a write burst
    id_t    w_id    ;
    addr_t  w_addr  ;   // address of next beat to issue
    len_t   w_len   ;   // remaining beats minus 1 (same encoding as awlen)
    addr_t  w_inc   ;
    addr_t  w_mask  ;
    prot_t  w_prot  ;

    // AXI4-Lite write beat in flight
    logic   wt_awvalid ;   // AXI4L AW not yet accepted
    logic   wt_wvalid  ;   // AXI4L W  not yet accepted
    logic   wt_pending ;   // waiting for AXI4L B response
    logic   wt_last    ;   // this beat is the last of the burst
    addr_t  wt_addr    ;   // address for current AXI4L beat
    data_t  wt_data    ;
    strb_t  wt_strb    ;

    always_ff @(posedge clk) begin
        if (reset) begin
            w_busy     <= 1'b0 ;
            w_id       <= 'x   ;
            w_addr     <= 'x   ;
            w_len      <= 'x   ;
            w_inc      <= 'x   ;
            w_mask     <= 'x   ;
            w_prot     <= 'x   ;
            wt_awvalid <= 1'b0 ;
            wt_wvalid  <= 1'b0 ;
            wt_pending <= 1'b0 ;
            wt_last    <= 'x   ;
            wt_addr    <= 'x   ;
            wt_data    <= 'x   ;
            wt_strb    <= 'x   ;
            s_axi4.bvalid <= 1'b0 ;
            s_axi4.bid    <= 'x   ;
        end
        else if (cke) begin
            // AXI4 B consumed by master
            if (s_axi4.bvalid && s_axi4.bready) begin
                s_axi4.bvalid <= 1'b0 ;
            end

            // AXI4-Lite AW channel handshake
            if (wt_awvalid && m_axi4l.awready) begin
                wt_awvalid <= 1'b0 ;
            end

            // AXI4-Lite W channel handshake
            if (wt_wvalid && m_axi4l.wready) begin
                wt_wvalid <= 1'b0 ;
            end

            // AXI4-Lite B response → beat complete
            if (m_axi4l.bvalid) begin   // bready is always 1
                wt_pending <= 1'b0 ;
                if (wt_last) begin
                    w_busy        <= 1'b0 ;
                    s_axi4.bvalid <= 1'b1 ;
                    s_axi4.bid    <= w_id ;
                end
            end

            // AXI4 W beat accepted → latch data and issue AXI4-Lite beat
            if (s_axi4.wvalid && s_axi4.wready) begin
                wt_awvalid <= 1'b1          ;
                wt_wvalid  <= 1'b1          ;
                wt_pending <= 1'b1          ;
                wt_last    <= (w_len == '0) ;   // is this the last beat?
                wt_addr    <= w_addr        ;
                wt_data    <= s_axi4.wdata  ;
                wt_strb    <= s_axi4.wstrb  ;
                w_addr     <= (w_addr & ~w_mask) | ((w_addr + w_inc) & w_mask) ;
                w_len      <= w_len - len_t'(1) ;
            end

            // AXI4 AW accepted
            if (s_axi4.awvalid && s_axi4.awready) begin
                w_busy <= 1'b1                            ;
                w_id   <= s_axi4.awid                     ;
                w_addr <= s_axi4.awaddr                   ;
                w_len  <= s_axi4.awlen                    ;
                w_inc  <= calc_inc(s_axi4.awburst, s_axi4.awsize) ;
                w_mask <= calc_mask(s_axi4.awburst, s_axi4.awlen) ;
                w_prot <= s_axi4.awprot                   ;
            end
        end
    end

    // AW: accept when not busy and no pending B to deliver
    assign s_axi4.awready  = !w_busy && !(s_axi4.bvalid && !s_axi4.bready) ;
    // W: accept when burst is active and no AXI4-Lite transaction in flight
    assign s_axi4.wready   = w_busy && !wt_pending && !wt_awvalid && !wt_wvalid ;
    assign s_axi4.bresp    = 2'b00 ;

    assign m_axi4l.awvalid = wt_awvalid ;
    assign m_axi4l.awaddr  = wt_addr    ;
    assign m_axi4l.awprot  = w_prot     ;
    assign m_axi4l.wvalid  = wt_wvalid  ;
    assign m_axi4l.wdata   = wt_data    ;
    assign m_axi4l.wstrb   = wt_strb    ;
    assign m_axi4l.bready  = 1'b1       ;


    // -------------------------------------------------------------------------
    //  Read path
    // -------------------------------------------------------------------------
    //  Accepts one AXI4 AR transaction, then for each beat:
    //    1. Issues one AXI4-Lite AR.
    //    2. Waits for AXI4-Lite R, forwards it to AXI4 R with rid/rlast.
    //    3. Issues the next AXI4-Lite AR (address incremented per burst type).
    // -------------------------------------------------------------------------

    // Read burst state
    logic   r_busy  ;   // processing a read burst
    id_t    r_id    ;
    addr_t  r_addr  ;   // address of next AR to issue
    len_t   r_len   ;   // remaining beats minus 1
    addr_t  r_inc   ;
    addr_t  r_mask  ;
    prot_t  r_prot  ;

    // Current in-flight AXI4-Lite read beat
    logic   ra_pending ;   // AXI4-Lite AR issued, waiting for R
    logic   ra_last    ;   // the in-flight beat is the last of the burst

    always_ff @(posedge clk) begin
        if (reset) begin
            r_busy     <= 1'b0 ;
            r_id       <= 'x   ;
            r_addr     <= 'x   ;
            r_len      <= 'x   ;
            r_inc      <= 'x   ;
            r_mask     <= 'x   ;
            r_prot     <= 'x   ;
            ra_pending <= 1'b0 ;
            ra_last    <= 'x   ;
        end
        else if (cke) begin
            // AXI4-Lite AR handshake → mark beat as in-flight, advance address
            if (m_axi4l.arvalid && m_axi4l.arready) begin
                ra_pending <= 1'b1          ;
                ra_last    <= (r_len == '0) ;   // is this the last beat?
                r_addr     <= (r_addr & ~r_mask) | ((r_addr + r_inc) & r_mask) ;
                r_len      <= r_len - len_t'(1) ;
            end

            // AXI4-Lite R response → beat complete
            if (m_axi4l.rvalid && m_axi4l.rready) begin
                ra_pending <= 1'b0 ;
                if (ra_last) begin
                    r_busy <= 1'b0 ;
                end
            end

            // AXI4 AR accepted
            if (s_axi4.arvalid && s_axi4.arready) begin
                r_busy <= 1'b1                            ;
                r_id   <= s_axi4.arid                     ;
                r_addr <= s_axi4.araddr                   ;
                r_len  <= s_axi4.arlen                    ;
                r_inc  <= calc_inc(s_axi4.arburst, s_axi4.arsize) ;
                r_mask <= calc_mask(s_axi4.arburst, s_axi4.arlen) ;
                r_prot <= s_axi4.arprot                   ;
            end
        end
    end

    assign s_axi4.arready  = !r_busy ;

    // Issue one AXI4-Lite AR per beat; hold off until previous beat's R arrives
    assign m_axi4l.arvalid = r_busy && !ra_pending ;
    assign m_axi4l.araddr  = r_addr                ;
    assign m_axi4l.arprot  = r_prot                ;
    assign m_axi4l.rready  = s_axi4.rready         ;

    assign s_axi4.rid      = r_id              ;
    assign s_axi4.rdata    = m_axi4l.rdata     ;
    assign s_axi4.rresp    = m_axi4l.rresp     ;
    assign s_axi4.rlast    = ra_last           ;
    assign s_axi4.rvalid   = m_axi4l.rvalid   ;


    // -------------------------------------------------------------------------
    //  Sanity checks
    // -------------------------------------------------------------------------
    initial begin
        if (s_axi4.DATA_BITS != m_axi4l.DATA_BITS) begin
            $error("ERROR: DATA_BITS of axi4 and axi4l must be same");
        end
        if (s_axi4.ADDR_BITS != m_axi4l.ADDR_BITS) begin
            $error("ERROR: ADDR_BITS of axi4 and axi4l must be same");
        end
    end

    if (SIMULATION == "true") begin
        always_comb begin
            sva_clk : assert (s_axi4.aclk   === m_axi4l.aclk   );
            sva_cke : assert (s_axi4.aclken === m_axi4l.aclken );
        end
    end

endmodule


`default_nettype wire


// end of file
