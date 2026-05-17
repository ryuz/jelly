// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4_m
        #(
            parameter   longint unsigned  WRITE_ADDR_LOW   = 0                    ,
            parameter   longint unsigned  WRITE_ADDR_HIGH  = 4095                 ,
            parameter   longint unsigned  READ_ADDR_LOW    = 0                    ,
            parameter   longint unsigned  READ_ADDR_HIGH   = 4095                 ,
            parameter   int               WRITE_LEN_MIN    = 0                    ,
            parameter   int               WRITE_LEN_MAX    = 15                   ,
            parameter   int               READ_LEN_MIN     = 0                    ,
            parameter   int               READ_LEN_MAX     = 15                   ,
            parameter   int               WRITE_ISSUE_RATE = 20                   ,
            parameter   int               READ_ISSUE_RATE  = 20                   ,
            parameter   int               AW_BUSY_RATE     = 0                    ,
            parameter   int               W_BUSY_RATE      = 0                    ,
            parameter   int               B_BUSY_RATE      = 0                    ,
            parameter   int               AR_BUSY_RATE     = 0                    ,
            parameter   int               R_BUSY_RATE      = 0                    ,
            parameter   int               WRITE_ID         = 0                    ,
            parameter   int               READ_ID          = 0                    ,
            parameter   string            WRITE_LOG_FILE   = ""                   ,
            parameter   string            READ_LOG_FILE    = ""                   ,
            parameter   int               WRITE_RAND_SEED  = 0                    ,
            parameter   int               READ_RAND_SEED   = 1                    ,
            parameter   int               AW_RAND_SEED     = 2                    ,
            parameter   int               W_RAND_SEED      = 3                    ,
            parameter   int               B_RAND_SEED      = 4                    ,
            parameter   int               AR_RAND_SEED     = 5                    ,
            parameter   int               R_RAND_SEED      = 6
        )
        (
            input   var logic       enable      ,
            output  var logic       busy        ,
            output  var logic       write_busy  ,
            output  var logic       read_busy   ,
            jelly3_axi4_if.m        m_axi4
        );

    localparam  int     AXI_ID_BITS     = m_axi4.ID_BITS           ;
    localparam  int     AXI_ADDR_BITS   = m_axi4.ADDR_BITS         ;
    localparam  int     AXI_LEN_BITS    = m_axi4.LEN_BITS          ;
    localparam  int     AXI_SIZE_BITS   = m_axi4.SIZE_BITS         ;
    localparam  int     AXI_BURST_BITS  = m_axi4.BURST_BITS        ;
    localparam  int     AXI_LOCK_BITS   = m_axi4.LOCK_BITS         ;
    localparam  int     AXI_CACHE_BITS  = m_axi4.CACHE_BITS        ;
    localparam  int     AXI_PROT_BITS   = m_axi4.PROT_BITS         ;
    localparam  int     AXI_QOS_BITS    = m_axi4.QOS_BITS          ;
    localparam  int     AXI_REGION_BITS = m_axi4.REGION_BITS       ;
    localparam  int     AXI_DATA_BITS   = m_axi4.DATA_BITS         ;
    localparam  int     AXI_STRB_BITS   = m_axi4.STRB_BITS         ;
    localparam  int     AXI_RESP_BITS   = m_axi4.RESP_BITS         ;
    localparam  int     AXI_AWUSER_BITS = m_axi4.AWUSER_BITS       ;
    localparam  int     AXI_WUSER_BITS  = m_axi4.WUSER_BITS        ;
    localparam  int     AXI_BUSER_BITS  = m_axi4.BUSER_BITS        ;
    localparam  int     AXI_ARUSER_BITS = m_axi4.ARUSER_BITS       ;
    localparam  int     AXI_RUSER_BITS  = m_axi4.RUSER_BITS        ;
    localparam  int     AXI_DATA_BYTES  = AXI_STRB_BITS            ;
    localparam  longint unsigned AXI_DATA_BYTES_L = longint'(AXI_DATA_BYTES);
    localparam  int     AXI_SIZE        = AXI_STRB_BITS > 1 ? $clog2(AXI_STRB_BITS) : 0;

    localparam  type    id_t            = logic [AXI_ID_BITS-1:0]      ;
    localparam  type    addr_t          = logic [AXI_ADDR_BITS-1:0]    ;
    localparam  type    len_t           = logic [AXI_LEN_BITS-1:0]     ;
    localparam  type    size_t          = logic [AXI_SIZE_BITS-1:0]    ;
    localparam  type    burst_t         = logic [AXI_BURST_BITS-1:0]   ;
    localparam  type    lock_t          = logic [AXI_LOCK_BITS-1:0]    ;
    localparam  type    cache_t         = logic [AXI_CACHE_BITS-1:0]   ;
    localparam  type    prot_t          = logic [AXI_PROT_BITS-1:0]    ;
    localparam  type    qos_t           = logic [AXI_QOS_BITS-1:0]     ;
    localparam  type    region_t        = logic [AXI_REGION_BITS-1:0]  ;
    localparam  type    data_t          = logic [AXI_DATA_BITS-1:0]    ;
    localparam  type    strb_t          = logic [AXI_STRB_BITS-1:0]    ;
    localparam  type    resp_t          = logic [AXI_RESP_BITS-1:0]    ;
    localparam  type    awuser_t        = logic [AXI_AWUSER_BITS-1:0]  ;
    localparam  type    wuser_t         = logic [AXI_WUSER_BITS-1:0]   ;
    localparam  type    buser_t         = logic [AXI_BUSER_BITS-1:0]   ;
    localparam  type    aruser_t        = logic [AXI_ARUSER_BITS-1:0]  ;
    localparam  type    ruser_t         = logic [AXI_RUSER_BITS-1:0]   ;

    localparam  longint unsigned  WRITE_ALIGN_LOW   = ((WRITE_ADDR_LOW + AXI_DATA_BYTES_L - 1) / AXI_DATA_BYTES_L) * AXI_DATA_BYTES_L;
    localparam  longint unsigned  WRITE_ALIGN_HIGH  = (WRITE_ADDR_HIGH / AXI_DATA_BYTES_L) * AXI_DATA_BYTES_L;
    localparam  longint unsigned  READ_ALIGN_LOW    = ((READ_ADDR_LOW  + AXI_DATA_BYTES_L - 1) / AXI_DATA_BYTES_L) * AXI_DATA_BYTES_L;
    localparam  longint unsigned  READ_ALIGN_HIGH   = (READ_ADDR_HIGH  / AXI_DATA_BYTES_L) * AXI_DATA_BYTES_L;
    localparam  bit               WRITE_RANGE_VALID = (WRITE_ADDR_HIGH >= WRITE_ADDR_LOW) && (WRITE_ALIGN_HIGH >= WRITE_ALIGN_LOW);
    localparam  bit               READ_RANGE_VALID  = (READ_ADDR_HIGH  >= READ_ADDR_LOW ) && (READ_ALIGN_HIGH  >= READ_ALIGN_LOW );
    localparam  int               WRITE_BEAT_CAP    = WRITE_RANGE_VALID ? int'(((WRITE_ALIGN_HIGH - WRITE_ALIGN_LOW) / AXI_DATA_BYTES_L) + 1) : 0;
    localparam  int               READ_BEAT_CAP     = READ_RANGE_VALID  ? int'(((READ_ALIGN_HIGH  - READ_ALIGN_LOW ) / AXI_DATA_BYTES_L) + 1) : 0;

    function automatic int rand_mod
            (
                input   int     modulus,
                inout   integer seed
            );
        int value;
    begin
        if ( modulus <= 0 ) begin
            return 0;
        end
        value = $random(seed);
        rand_mod = int'((value & 32'h7fff_ffff) % modulus);
    end
    endfunction

    function automatic int rand_range
            (
                input   int     min_value,
                input   int     max_value,
                inout   integer seed
            );
    begin
        if ( max_value <= min_value ) begin
            return min_value;
        end
        rand_range = min_value + rand_mod(max_value - min_value + 1, seed);
    end
    endfunction

    function automatic logic rand_hit
            (
                input   int     rate,
                inout   integer seed
            );
    begin
        if ( rate <= 0 ) begin
            return 1'b0;
        end
        if ( rate >= 100 ) begin
            return 1'b1;
        end
        rand_hit = (rand_mod(100, seed) < rate);
    end
    endfunction

    function automatic data_t make_write_data
            (
                input   addr_t      addr,
                input   int         beat_index,
                inout   integer     seed
            );
        int random_value;
    begin
        random_value    = $random(seed);
        make_write_data = data_t'(addr) ^ data_t'(beat_index) ^ data_t'(random_value & 32'h7fff_ffff);
    end
    endfunction


    int     write_fp        = 0                ;
    int     read_fp         = 0                ;
    integer rand_write_txn  = WRITE_RAND_SEED  ;
    integer rand_read_txn   = READ_RAND_SEED   ;
    integer rand_aw_busy    = AW_RAND_SEED     ;
    integer rand_w_busy     = W_RAND_SEED      ;
    integer rand_b_busy     = B_RAND_SEED      ;
    integer rand_ar_busy    = AR_RAND_SEED     ;
    integer rand_r_busy     = R_RAND_SEED      ;

    initial begin
        if ( WRITE_LOG_FILE != "" ) begin
            write_fp = $fopen(WRITE_LOG_FILE, "w");
        end
        if ( READ_LOG_FILE != "" ) begin
            read_fp = $fopen(READ_LOG_FILE, "w");
        end
    end


    logic   reg_busy_aw = 1'b0;
    logic   reg_busy_w  = 1'b0;
    logic   reg_busy_b  = 1'b0;
    logic   reg_busy_ar = 1'b0;
    logic   reg_busy_r  = 1'b0;

    always_ff @(posedge m_axi4.aclk) begin
        if ( !m_axi4.aresetn ) begin
            reg_busy_aw <= 1'b0;
            reg_busy_w  <= 1'b0;
            reg_busy_b  <= 1'b0;
            reg_busy_ar <= 1'b0;
            reg_busy_r  <= 1'b0;
        end
        else if ( m_axi4.aclken ) begin
            if ( !m_axi4.awvalid || m_axi4.awready ) begin
                reg_busy_aw <= AW_BUSY_RATE > 0 ? rand_hit(AW_BUSY_RATE, rand_aw_busy) : 1'b0;
            end
            if ( !m_axi4.wvalid || m_axi4.wready ) begin
                reg_busy_w <= W_BUSY_RATE > 0 ? rand_hit(W_BUSY_RATE, rand_w_busy) : 1'b0;
            end
            reg_busy_b  <= B_BUSY_RATE  > 0 ? rand_hit(B_BUSY_RATE,  rand_b_busy)  : 1'b0;
            if ( !m_axi4.arvalid || m_axi4.arready ) begin
                reg_busy_ar <= AR_BUSY_RATE > 0 ? rand_hit(AR_BUSY_RATE, rand_ar_busy) : 1'b0;
            end
            reg_busy_r  <= R_BUSY_RATE  > 0 ? rand_hit(R_BUSY_RATE,  rand_r_busy)  : 1'b0;
        end
    end


    id_t        awid            ;
    addr_t      awaddr          ;
    len_t       awlen           ;
    size_t      awsize          ;
    burst_t     awburst         ;
    lock_t      awlock          ;
    cache_t     awcache         ;
    prot_t      awprot          ;
    qos_t       awqos           ;
    region_t    awregion        ;
    awuser_t    awuser          ;
    logic       awvalid = 1'b0  ;

    data_t      wdata           ;
    strb_t      wstrb           ;
    logic       wlast           ;
    wuser_t     wuser           ;
    logic       wvalid = 1'b0   ;

    logic       bready = 1'b0   ;

    id_t        arid            ;
    addr_t      araddr          ;
    len_t       arlen           ;
    size_t      arsize          ;
    burst_t     arburst         ;
    lock_t      arlock          ;
    cache_t     arcache         ;
    prot_t      arprot          ;
    qos_t       arqos           ;
    region_t    arregion        ;
    aruser_t    aruser          ;
    logic       arvalid = 1'b0  ;

    logic       rready = 1'b0   ;

    assign m_axi4.awid     = awvalid ? awid     : 'x;
    assign m_axi4.awaddr   = awvalid ? awaddr   : 'x;
    assign m_axi4.awlen    = awvalid ? awlen    : 'x;
    assign m_axi4.awsize   = awvalid ? awsize   : 'x;
    assign m_axi4.awburst  = awvalid ? awburst  : 'x;
    assign m_axi4.awlock   = awvalid ? awlock   : 'x;
    assign m_axi4.awcache  = awvalid ? awcache  : 'x;
    assign m_axi4.awprot   = awvalid ? awprot   : 'x;
    assign m_axi4.awqos    = awvalid ? awqos    : 'x;
    assign m_axi4.awregion = awvalid ? awregion : 'x;
    assign m_axi4.awuser   = awvalid ? awuser   : 'x;
    assign m_axi4.awvalid  = awvalid && !reg_busy_aw;

    assign m_axi4.wdata    = wvalid ? wdata : 'x;
    assign m_axi4.wstrb    = wvalid ? wstrb : 'x;
    assign m_axi4.wlast    = wvalid ? wlast : 'x;
    assign m_axi4.wuser    = wvalid ? wuser : 'x;
    assign m_axi4.wvalid   = wvalid && !reg_busy_w;

    assign m_axi4.bready   = bready && !reg_busy_b;

    assign m_axi4.arid     = arvalid ? arid     : 'x;
    assign m_axi4.araddr   = arvalid ? araddr   : 'x;
    assign m_axi4.arlen    = arvalid ? arlen    : 'x;
    assign m_axi4.arsize   = arvalid ? arsize   : 'x;
    assign m_axi4.arburst  = arvalid ? arburst  : 'x;
    assign m_axi4.arlock   = arvalid ? arlock   : 'x;
    assign m_axi4.arcache  = arvalid ? arcache  : 'x;
    assign m_axi4.arprot   = arvalid ? arprot   : 'x;
    assign m_axi4.arqos    = arvalid ? arqos    : 'x;
    assign m_axi4.arregion = arvalid ? arregion : 'x;
    assign m_axi4.aruser   = arvalid ? aruser   : 'x;
    assign m_axi4.arvalid  = arvalid && !reg_busy_ar;

    assign m_axi4.rready   = rready && !reg_busy_r;

    wire    issue_aw = m_axi4.awvalid && m_axi4.awready;
    wire    issue_w  = m_axi4.wvalid  && m_axi4.wready ;
    wire    issue_b  = m_axi4.bvalid  && m_axi4.bready ;
    wire    issue_ar = m_axi4.arvalid && m_axi4.arready;
    wire    issue_r  = m_axi4.rvalid  && m_axi4.rready ;


    int     write_beats_total = 0;
    int     write_beat_index  = 0;
    addr_t  write_curr_addr   = '0;
    logic   write_resp_wait   = 1'b0;

    int     read_beats_total  = 0;
    int     read_beat_index   = 0;
    logic   read_resp_wait    = 1'b0;

    always_comb begin
        write_busy = awvalid || wvalid || write_resp_wait;
        read_busy  = arvalid || read_resp_wait;
        busy       = write_busy || read_busy;
    end


    always_ff @(posedge m_axi4.aclk) begin
        if ( !m_axi4.aresetn ) begin
            awid            <= '0;
            awaddr          <= '0;
            awlen           <= '0;
            awsize          <= size_t'(AXI_SIZE);
            awburst         <= burst_t'(2'b01);
            awlock          <= '0;
            awcache         <= '0;
            awprot          <= '0;
            awqos           <= '0;
            awregion        <= '0;
            awuser          <= '0;
            awvalid         <= 1'b0;
            wdata           <= '0;
            wstrb           <= '0;
            wlast           <= 1'b0;
            wuser           <= '0;
            wvalid          <= 1'b0;
            bready          <= 1'b0;
            write_beats_total <= 0;
            write_beat_index  <= 0;
            write_curr_addr   <= '0;
            write_resp_wait   <= 1'b0;
        end
        else if ( m_axi4.aclken ) begin
            if ( issue_aw ) begin
                awvalid <= 1'b0;
            end

            if ( issue_w ) begin
                if ( write_fp != 0 ) begin
                    $fdisplay(write_fp, "W %h %h %h %0d %0d", write_curr_addr, wdata, wstrb, write_beat_index, write_beats_total);
                end

                if ( write_beat_index + 1 >= write_beats_total ) begin
                    wvalid          <= 1'b0;
                    wlast           <= 1'b0;
                    write_resp_wait <= 1'b1;
                end
                else begin
                    write_beat_index <= write_beat_index + 1;
                    write_curr_addr  <= write_curr_addr + addr_t'(AXI_DATA_BYTES);
                    wdata            <= make_write_data(write_curr_addr + addr_t'(AXI_DATA_BYTES), write_beat_index + 1, rand_write_txn);
                    wstrb            <= '1;
                    wlast            <= ((write_beat_index + 2) >= write_beats_total);
                    wvalid           <= 1'b1;
                end
            end

            if ( write_resp_wait ) begin
                bready <= 1'b1;
                if ( issue_b ) begin
                    if ( write_fp != 0 ) begin
                        $fdisplay(write_fp, "B %h %0d", m_axi4.bid, m_axi4.bresp);
                    end
                    write_resp_wait <= 1'b0;
                    bready          <= 1'b0;
                end
            end
            else begin
                bready <= 1'b0;
            end

            if ( !awvalid && !wvalid && !write_resp_wait && enable && WRITE_RANGE_VALID ) begin
                int burst_min;
                int burst_max;
                int burst_beats;
                int start_max;
                int start_index;
                addr_t start_addr;

                if ( rand_hit(WRITE_ISSUE_RATE, rand_write_txn) ) begin
                    burst_min = WRITE_LEN_MIN + 1;
                    burst_max = WRITE_LEN_MAX + 1;
                    if ( burst_min < 1 ) begin
                        burst_min = 1;
                    end
                    if ( burst_max > WRITE_BEAT_CAP ) begin
                        burst_max = WRITE_BEAT_CAP;
                    end
                    if ( burst_min > burst_max ) begin
                        burst_min = burst_max;
                    end

                    burst_beats = rand_range(burst_min, burst_max, rand_write_txn);
                    start_max   = WRITE_BEAT_CAP - burst_beats;
                    start_index = start_max > 0 ? rand_range(0, start_max, rand_write_txn) : 0;
                    start_addr  = addr_t'(WRITE_ALIGN_LOW + (start_index * AXI_DATA_BYTES));

                    awid            <= id_t'(WRITE_ID);
                    awaddr          <= start_addr;
                    awlen           <= len_t'(burst_beats - 1);
                    awsize          <= size_t'(AXI_SIZE);
                    awburst         <= burst_t'(2'b01);
                    awlock          <= '0;
                    awcache         <= '0;
                    awprot          <= '0;
                    awqos           <= '0;
                    awregion        <= '0;
                    awuser          <= '0;
                    awvalid         <= 1'b1;

                    write_beats_total <= burst_beats;
                    write_beat_index  <= 0;
                    write_curr_addr   <= start_addr;
                    wdata             <= make_write_data(start_addr, 0, rand_write_txn);
                    wstrb             <= '1;
                    wlast             <= (burst_beats <= 1);
                    wuser             <= '0;
                    wvalid            <= 1'b1;

                    if ( write_fp != 0 ) begin
                        $fdisplay(write_fp, "AW %h %0d", start_addr, burst_beats - 1);
                    end
                end
            end
        end
    end


    always_ff @(posedge m_axi4.aclk) begin
        if ( !m_axi4.aresetn ) begin
            arid            <= '0;
            araddr          <= '0;
            arlen           <= '0;
            arsize          <= size_t'(AXI_SIZE);
            arburst         <= burst_t'(2'b01);
            arlock          <= '0;
            arcache         <= '0;
            arprot          <= '0;
            arqos           <= '0;
            arregion        <= '0;
            aruser          <= '0;
            arvalid         <= 1'b0;
            rready          <= 1'b0;
            read_beats_total <= 0;
            read_beat_index  <= 0;
            read_resp_wait   <= 1'b0;
        end
        else if ( m_axi4.aclken ) begin
            if ( issue_ar ) begin
                arvalid        <= 1'b0;
                read_resp_wait <= 1'b1;
                rready         <= 1'b1;
            end

            if ( read_resp_wait ) begin
                rready <= 1'b1;
                if ( issue_r ) begin
                    if ( read_fp != 0 ) begin
                        $fdisplay(read_fp, "R %h %h %0d %0d", m_axi4.rid, m_axi4.rdata, read_beat_index, read_beats_total);
                    end

                    if ( m_axi4.rlast ) begin
                        if ( (read_beat_index + 1) != read_beats_total ) begin
                            $display("[%m(%t)] read burst length mismatch : expect=%0d actual=%0d", $time, read_beats_total, read_beat_index + 1);
                        end
                        read_resp_wait <= 1'b0;
                        read_beat_index <= 0;
                        rready <= 1'b0;
                    end
                    else begin
                        read_beat_index <= read_beat_index + 1;
                    end
                end
            end
            else begin
                rready <= 1'b0;
            end

            if ( !arvalid && !read_resp_wait && enable && READ_RANGE_VALID ) begin
                int burst_min;
                int burst_max;
                int burst_beats;
                int start_max;
                int start_index;
                addr_t start_addr;

                if ( rand_hit(READ_ISSUE_RATE, rand_read_txn) ) begin
                    burst_min = READ_LEN_MIN + 1;
                    burst_max = READ_LEN_MAX + 1;
                    if ( burst_min < 1 ) begin
                        burst_min = 1;
                    end
                    if ( burst_max > READ_BEAT_CAP ) begin
                        burst_max = READ_BEAT_CAP;
                    end
                    if ( burst_min > burst_max ) begin
                        burst_min = burst_max;
                    end

                    burst_beats = rand_range(burst_min, burst_max, rand_read_txn);
                    start_max   = READ_BEAT_CAP - burst_beats;
                    start_index = start_max > 0 ? rand_range(0, start_max, rand_read_txn) : 0;
                    start_addr  = addr_t'(READ_ALIGN_LOW + (start_index * AXI_DATA_BYTES));

                    arid            <= id_t'(READ_ID);
                    araddr          <= start_addr;
                    arlen           <= len_t'(burst_beats - 1);
                    arsize          <= size_t'(AXI_SIZE);
                    arburst         <= burst_t'(2'b01);
                    arlock          <= '0;
                    arcache         <= '0;
                    arprot          <= '0;
                    arqos           <= '0;
                    arregion        <= '0;
                    aruser          <= '0;
                    arvalid         <= 1'b1;
                    read_beats_total <= burst_beats;
                    read_beat_index  <= 0;

                    if ( read_fp != 0 ) begin
                        $fdisplay(read_fp, "AR %h %0d", start_addr, burst_beats - 1);
                    end
                end
            end
        end
    end

endmodule


`default_nettype wire


// end of file