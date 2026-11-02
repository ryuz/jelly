// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// Split INCR bursts crossing a 4KB boundary into AXI4-compliant bursts.
// Assumes a single ID (in-order responses); FIXED/WRAP bursts pass through.
module jelly3_axi4_burst_splitter
        #(
            parameter   int     FIFO_PTR_BITS  = 5              ,
            parameter           FIFO_RAM_TYPE  = "distributed"  ,
            parameter   bit     FIFO_DOUT_REG  = 1'b0           ,
            parameter           DEVICE         = "RTL"          ,
            parameter           SIMULATION     = "false"        ,
            parameter           DEBUG          = "false"        
        )
        (
            jelly3_axi4_if.s    s_axi4,
            jelly3_axi4_if.m    m_axi4
        );

    localparam  int     ADDR_BITS = s_axi4.ADDR_BITS;
    localparam  int     LEN_BITS  = s_axi4.LEN_BITS ;
    localparam  int     BND_BITS  = 12;     // 4KB boundary
    localparam  int     CNT_BITS  = LEN_BITS > BND_BITS ? LEN_BITS : BND_BITS;

    localparam type id_t     = logic [s_axi4.ID_BITS    -1:0];
    localparam type addr_t   = logic [ADDR_BITS         -1:0];
    localparam type len_t    = logic [LEN_BITS          -1:0];
    localparam type size_t   = logic [s_axi4.SIZE_BITS  -1:0];
    localparam type burst_t  = logic [s_axi4.BURST_BITS -1:0];
    localparam type lock_t   = logic [s_axi4.LOCK_BITS  -1:0];
    localparam type cache_t  = logic [s_axi4.CACHE_BITS -1:0];
    localparam type prot_t   = logic [s_axi4.PROT_BITS  -1:0];
    localparam type qos_t    = logic [s_axi4.QOS_BITS   -1:0];
    localparam type region_t = logic [s_axi4.REGION_BITS-1:0];
    localparam type resp_t   = logic [s_axi4.RESP_BITS  -1:0];
    localparam type awuser_t = logic [s_axi4.AWUSER_BITS-1:0];
    localparam type buser_t  = logic [s_axi4.BUSER_BITS -1:0];
    localparam type aruser_t = logic [s_axi4.ARUSER_BITS-1:0];
    localparam type bnd_t    = logic [BND_BITS          -1:0];
    localparam type cnt_t    = logic [CNT_BITS          -1:0];
    localparam type flag_t   = logic [0:0];

    localparam  burst_t BURST_INCR = burst_t'(2'b01);

    typedef struct packed {
        id_t        id      ;
        size_t      size    ;
        burst_t     burst   ;
        lock_t      lock    ;
        cache_t     cache   ;
        prot_t      prot    ;
        qos_t       qos     ;
        region_t    region  ;
        awuser_t    user    ;
    } aw_t;

    typedef struct packed {
        id_t        id      ;
        size_t      size    ;
        burst_t     burst   ;
        lock_t      lock    ;
        cache_t     cache   ;
        prot_t      prot    ;
        qos_t       qos     ;
        region_t    region  ;
        aruser_t    user    ;
    } ar_t;

    // (beats to the next 4KB boundary) - 1 ; unaligned low bits are shifted out
    function automatic bnd_t calc_bnd_len(input bnd_t addr_low, input size_t size);
        return (~addr_low) >> size;
    endfunction

    // whole burst fits before the next 4KB boundary
    function automatic logic calc_fit(input bnd_t addr_low, input len_t len, input size_t size, input burst_t burst);
        return (burst != BURST_INCR) || (cnt_t'(len) <= cnt_t'(calc_bnd_len(addr_low, size)));
    endfunction


    // ---------------------------------------------
    //  Write address
    // ---------------------------------------------

    // chunk FIFOs
    len_t       wfifo_s_data    ;
    logic       wfifo_s_valid   ;
    logic       wfifo_s_ready   ;
    len_t       wfifo_m_data    ;
    logic       wfifo_m_valid   ;
    logic       wfifo_m_ready   ;

    jelly3_stream_fifo
            #(
                .ASYNC          (0                  ),
                .PTR_BITS       (FIFO_PTR_BITS      ),
                .DATA_BITS      ($bits(len_t)       ),
                .data_t         (len_t              ),
                .RAM_TYPE       (FIFO_RAM_TYPE      ),
                .DOUT_REG       (FIFO_DOUT_REG      ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_stream_fifo_w
            (
                .s_reset        (~s_axi4.aresetn    ),
                .s_clk          (s_axi4.aclk        ),
                .s_cke          (s_axi4.aclken      ),
                .s_data         (wfifo_s_data       ),
                .s_valid        (wfifo_s_valid      ),
                .s_ready        (wfifo_s_ready      ),
                .s_free_size    (                   ),

                .m_reset        (~s_axi4.aresetn    ),
                .m_clk          (s_axi4.aclk        ),
                .m_cke          (s_axi4.aclken      ),
                .m_data         (wfifo_m_data       ),
                .m_valid        (wfifo_m_valid      ),
                .m_ready        (wfifo_m_ready      ),
                .m_data_size    (                   )
            );

    flag_t      bfifo_s_data    ;
    logic       bfifo_s_valid   ;
    logic       bfifo_s_ready   ;
    flag_t      bfifo_m_data    ;
    logic       bfifo_m_valid   ;
    logic       bfifo_m_ready   ;

    jelly3_stream_fifo
            #(
                .ASYNC          (0                  ),
                .PTR_BITS       (FIFO_PTR_BITS      ),
                .DATA_BITS      (1                  ),
                .data_t         (flag_t             ),
                .RAM_TYPE       (FIFO_RAM_TYPE      ),
                .DOUT_REG       (FIFO_DOUT_REG      ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_stream_fifo_b
            (
                .s_reset        (~s_axi4.aresetn    ),
                .s_clk          (s_axi4.aclk        ),
                .s_cke          (s_axi4.aclken      ),
                .s_data         (bfifo_s_data       ),
                .s_valid        (bfifo_s_valid      ),
                .s_ready        (bfifo_s_ready      ),
                .s_free_size    (                   ),

                .m_reset        (~s_axi4.aresetn    ),
                .m_clk          (s_axi4.aclk        ),
                .m_cke          (s_axi4.aclken      ),
                .m_data         (bfifo_m_data       ),
                .m_valid        (bfifo_m_valid      ),
                .m_ready        (bfifo_m_ready      ),
                .m_data_size    (                   )
            );

    // stage 0 : burst iteration
    logic       aw0_valid       ;
    logic       aw0_fit         ;   // registered: needs no split at all
    addr_t      aw0_addr        ;
    len_t       aw0_len         ;   // remaining beats - 1
    aw_t        aw0_aw          ;
    bnd_t       aw0_bnd_len     ;
    logic       aw0_last        ;
    len_t       aw0_chunk_len   ;
    len_t       aw0_next_len    ;
    addr_t      aw0_next_addr   ;
    logic       aw0_ready       ;
    logic       aw0_fire        ;

    // stage 1 : output register
    logic       aw1_valid       ;
    addr_t      aw1_addr        ;
    len_t       aw1_len         ;
    aw_t        aw1_aw          ;
    logic       aw1_ready       ;

    always_comb begin
        aw0_bnd_len   = calc_bnd_len(aw0_addr[BND_BITS-1:0], aw0_aw.size);
        aw0_last      = (aw0_aw.burst != BURST_INCR) || (cnt_t'(aw0_len) <= cnt_t'(aw0_bnd_len));
        aw0_chunk_len = aw0_last ? aw0_len : len_t'(aw0_bnd_len);
        aw0_next_len  = aw0_len - len_t'(aw0_bnd_len) - len_t'(1);
        aw0_next_addr = {aw0_addr[ADDR_BITS-1:BND_BITS] + 1'b1, {BND_BITS{1'b0}}};
    end

    assign aw1_ready = !aw1_valid || m_axi4.awready;
    assign aw0_ready = aw1_ready && wfifo_s_ready && bfifo_s_ready;
    assign aw0_fire  = aw0_valid && aw0_ready;

    assign s_axi4.awready = !aw0_valid || (aw0_fit && aw0_ready);

    assign wfifo_s_data  = aw0_chunk_len;
    assign wfifo_s_valid = aw0_fire;
    assign bfifo_s_data  = flag_t'(aw0_last);
    assign bfifo_s_valid = aw0_fire;

    always_ff @(posedge s_axi4.aclk) begin
        if ( ~s_axi4.aresetn ) begin
            aw0_valid <= 1'b0;
            aw0_fit   <= 'x;
            aw0_addr  <= 'x;
            aw0_len   <= 'x;
            aw0_aw    <= 'x;
            aw1_valid <= 1'b0;
            aw1_addr  <= 'x;
            aw1_len   <= 'x;
            aw1_aw    <= 'x;
        end
        else if ( s_axi4.aclken ) begin
            // stage 0
            if ( aw0_fire ) begin
                if ( aw0_last ) begin
                    aw0_valid <= 1'b0;
                end
                else begin
                    aw0_addr <= aw0_next_addr;
                    aw0_len  <= aw0_next_len;
                end
            end
            if ( s_axi4.awvalid && s_axi4.awready ) begin
                aw0_valid     <= 1'b1;
                aw0_fit       <= calc_fit(s_axi4.awaddr[BND_BITS-1:0], s_axi4.awlen, s_axi4.awsize, s_axi4.awburst);
                aw0_addr      <= s_axi4.awaddr  ;
                aw0_len       <= s_axi4.awlen   ;
                aw0_aw.id     <= s_axi4.awid    ;
                aw0_aw.size   <= s_axi4.awsize  ;
                aw0_aw.burst  <= s_axi4.awburst ;
                aw0_aw.lock   <= s_axi4.awlock  ;
                aw0_aw.cache  <= s_axi4.awcache ;
                aw0_aw.prot   <= s_axi4.awprot  ;
                aw0_aw.qos    <= s_axi4.awqos   ;
                aw0_aw.region <= s_axi4.awregion;
                aw0_aw.user   <= s_axi4.awuser  ;
            end

            // stage 1
            if ( aw1_ready ) begin
                aw1_valid <= aw0_fire;
                aw1_addr  <= aw0_addr;
                aw1_len   <= aw0_chunk_len;
                aw1_aw    <= aw0_aw;
            end
        end
    end

    assign m_axi4.awid     = aw1_aw.id      ;
    assign m_axi4.awaddr   = aw1_addr       ;
    assign m_axi4.awlen    = aw1_len        ;
    assign m_axi4.awsize   = aw1_aw.size    ;
    assign m_axi4.awburst  = aw1_aw.burst   ;
    assign m_axi4.awlock   = aw1_aw.lock    ;
    assign m_axi4.awcache  = aw1_aw.cache   ;
    assign m_axi4.awprot   = aw1_aw.prot    ;
    assign m_axi4.awqos    = aw1_aw.qos     ;
    assign m_axi4.awregion = aw1_aw.region  ;
    assign m_axi4.awuser   = aw1_aw.user    ;
    assign m_axi4.awvalid  = aw1_valid      ;


    // ---------------------------------------------
    //  Write data (regenerate WLAST per chunk)
    // ---------------------------------------------

    len_t       w_count     ;
    logic       w_last      ;

    assign w_last = (w_count == wfifo_m_data);

    assign s_axi4.wready  = wfifo_m_valid && m_axi4.wready;
    assign m_axi4.wdata   = s_axi4.wdata  ;
    assign m_axi4.wstrb   = s_axi4.wstrb  ;
    assign m_axi4.wlast   = w_last        ;
    assign m_axi4.wuser   = s_axi4.wuser  ;
    assign m_axi4.wvalid  = wfifo_m_valid && s_axi4.wvalid;

    assign wfifo_m_ready  = s_axi4.wvalid && m_axi4.wready && w_last;

    always_ff @(posedge s_axi4.aclk) begin
        if ( ~s_axi4.aresetn ) begin
            w_count <= '0;
        end
        else if ( s_axi4.aclken ) begin
            if ( m_axi4.wvalid && m_axi4.wready ) begin
                w_count <= w_last ? '0 : w_count + len_t'(1);
            end
        end
    end


    // ---------------------------------------------
    //  Write response (merge chunk responses)
    // ---------------------------------------------

    logic       b_valid     ;
    id_t        b_id        ;
    resp_t      b_resp      ;
    buser_t     b_user      ;
    resp_t      b_accum     ;
    resp_t      b_merged    ;

    assign b_merged = (m_axi4.bresp > b_accum) ? m_axi4.bresp : b_accum;

    assign m_axi4.bready = bfifo_m_valid && (!bfifo_m_data[0] || !b_valid || s_axi4.bready);
    assign bfifo_m_ready = m_axi4.bvalid && m_axi4.bready;

    always_ff @(posedge s_axi4.aclk) begin
        if ( ~s_axi4.aresetn ) begin
            b_valid <= 1'b0;
            b_id    <= 'x;
            b_resp  <= 'x;
            b_user  <= 'x;
            b_accum <= '0;
        end
        else if ( s_axi4.aclken ) begin
            if ( s_axi4.bvalid && s_axi4.bready ) begin
                b_valid <= 1'b0;
            end
            if ( m_axi4.bvalid && m_axi4.bready ) begin
                if ( bfifo_m_data[0] ) begin
                    b_valid <= 1'b1;
                    b_id    <= m_axi4.bid;
                    b_resp  <= b_merged;
                    b_user  <= m_axi4.buser;
                    b_accum <= '0;
                end
                else begin
                    b_accum <= b_merged;
                end
            end
        end
    end

    assign s_axi4.bid    = b_id     ;
    assign s_axi4.bresp  = b_resp   ;
    assign s_axi4.buser  = b_user   ;
    assign s_axi4.bvalid = b_valid  ;


    // ---------------------------------------------
    //  Read address
    // ---------------------------------------------

    flag_t      rfifo_s_data    ;
    logic       rfifo_s_valid   ;
    logic       rfifo_s_ready   ;
    flag_t      rfifo_m_data    ;
    logic       rfifo_m_valid   ;
    logic       rfifo_m_ready   ;

    jelly3_stream_fifo
            #(
                .ASYNC          (0                  ),
                .PTR_BITS       (FIFO_PTR_BITS      ),
                .DATA_BITS      (1                  ),
                .data_t         (flag_t             ),
                .RAM_TYPE       (FIFO_RAM_TYPE      ),
                .DOUT_REG       (FIFO_DOUT_REG      ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_stream_fifo_r
            (
                .s_reset        (~s_axi4.aresetn    ),
                .s_clk          (s_axi4.aclk        ),
                .s_cke          (s_axi4.aclken      ),
                .s_data         (rfifo_s_data       ),
                .s_valid        (rfifo_s_valid      ),
                .s_ready        (rfifo_s_ready      ),
                .s_free_size    (                   ),

                .m_reset        (~s_axi4.aresetn    ),
                .m_clk          (s_axi4.aclk        ),
                .m_cke          (s_axi4.aclken      ),
                .m_data         (rfifo_m_data       ),
                .m_valid        (rfifo_m_valid      ),
                .m_ready        (rfifo_m_ready      ),
                .m_data_size    (                   )
            );

    // stage 0 : burst iteration
    logic       ar0_valid       ;
    logic       ar0_fit         ;
    addr_t      ar0_addr        ;
    len_t       ar0_len         ;
    ar_t        ar0_ar          ;
    bnd_t       ar0_bnd_len     ;
    logic       ar0_last        ;
    len_t       ar0_chunk_len   ;
    len_t       ar0_next_len    ;
    addr_t      ar0_next_addr   ;
    logic       ar0_ready       ;
    logic       ar0_fire        ;

    // stage 1 : output register
    logic       ar1_valid       ;
    addr_t      ar1_addr        ;
    len_t       ar1_len         ;
    ar_t        ar1_ar          ;
    logic       ar1_ready       ;

    always_comb begin
        ar0_bnd_len   = calc_bnd_len(ar0_addr[BND_BITS-1:0], ar0_ar.size);
        ar0_last      = (ar0_ar.burst != BURST_INCR) || (cnt_t'(ar0_len) <= cnt_t'(ar0_bnd_len));
        ar0_chunk_len = ar0_last ? ar0_len : len_t'(ar0_bnd_len);
        ar0_next_len  = ar0_len - len_t'(ar0_bnd_len) - len_t'(1);
        ar0_next_addr = {ar0_addr[ADDR_BITS-1:BND_BITS] + 1'b1, {BND_BITS{1'b0}}};
    end

    assign ar1_ready = !ar1_valid || m_axi4.arready;
    assign ar0_ready = ar1_ready && rfifo_s_ready;
    assign ar0_fire  = ar0_valid && ar0_ready;

    assign s_axi4.arready = !ar0_valid || (ar0_fit && ar0_ready);

    assign rfifo_s_data  = flag_t'(ar0_last);
    assign rfifo_s_valid = ar0_fire;

    always_ff @(posedge s_axi4.aclk) begin
        if ( ~s_axi4.aresetn ) begin
            ar0_valid <= 1'b0;
            ar0_fit   <= 'x;
            ar0_addr  <= 'x;
            ar0_len   <= 'x;
            ar0_ar    <= 'x;
            ar1_valid <= 1'b0;
            ar1_addr  <= 'x;
            ar1_len   <= 'x;
            ar1_ar    <= 'x;
        end
        else if ( s_axi4.aclken ) begin
            // stage 0
            if ( ar0_fire ) begin
                if ( ar0_last ) begin
                    ar0_valid <= 1'b0;
                end
                else begin
                    ar0_addr <= ar0_next_addr;
                    ar0_len  <= ar0_next_len;
                end
            end
            if ( s_axi4.arvalid && s_axi4.arready ) begin
                ar0_valid     <= 1'b1;
                ar0_fit       <= calc_fit(s_axi4.araddr[BND_BITS-1:0], s_axi4.arlen, s_axi4.arsize, s_axi4.arburst);
                ar0_addr      <= s_axi4.araddr  ;
                ar0_len       <= s_axi4.arlen   ;
                ar0_ar.id     <= s_axi4.arid    ;
                ar0_ar.size   <= s_axi4.arsize  ;
                ar0_ar.burst  <= s_axi4.arburst ;
                ar0_ar.lock   <= s_axi4.arlock  ;
                ar0_ar.cache  <= s_axi4.arcache ;
                ar0_ar.prot   <= s_axi4.arprot  ;
                ar0_ar.qos    <= s_axi4.arqos   ;
                ar0_ar.region <= s_axi4.arregion;
                ar0_ar.user   <= s_axi4.aruser  ;
            end

            // stage 1
            if ( ar1_ready ) begin
                ar1_valid <= ar0_fire;
                ar1_addr  <= ar0_addr;
                ar1_len   <= ar0_chunk_len;
                ar1_ar    <= ar0_ar;
            end
        end
    end

    assign m_axi4.arid     = ar1_ar.id      ;
    assign m_axi4.araddr   = ar1_addr       ;
    assign m_axi4.arlen    = ar1_len        ;
    assign m_axi4.arsize   = ar1_ar.size    ;
    assign m_axi4.arburst  = ar1_ar.burst   ;
    assign m_axi4.arlock   = ar1_ar.lock    ;
    assign m_axi4.arcache  = ar1_ar.cache   ;
    assign m_axi4.arprot   = ar1_ar.prot    ;
    assign m_axi4.arqos    = ar1_ar.qos     ;
    assign m_axi4.arregion = ar1_ar.region  ;
    assign m_axi4.aruser   = ar1_ar.user    ;
    assign m_axi4.arvalid  = ar1_valid      ;


    // ---------------------------------------------
    //  Read data (mask RLAST of non-final chunks)
    // ---------------------------------------------

    assign m_axi4.rready = rfifo_m_valid && s_axi4.rready;
    assign s_axi4.rid    = m_axi4.rid   ;
    assign s_axi4.rdata  = m_axi4.rdata ;
    assign s_axi4.rresp  = m_axi4.rresp ;
    assign s_axi4.rlast  = m_axi4.rlast && rfifo_m_data[0];
    assign s_axi4.ruser  = m_axi4.ruser ;
    assign s_axi4.rvalid = rfifo_m_valid && m_axi4.rvalid;

    assign rfifo_m_ready = m_axi4.rvalid && m_axi4.rready && m_axi4.rlast;


    if ( SIMULATION == "true" ) begin
        always_comb begin
            sva_resetn : assert (s_axi4.aresetn === m_axi4.aresetn);
            sva_clk    : assert (s_axi4.aclk    === m_axi4.aclk   );
            sva_cke    : assert (s_axi4.aclken  === m_axi4.aclken );
        end
    end

endmodule


`default_nettype wire


// end of file