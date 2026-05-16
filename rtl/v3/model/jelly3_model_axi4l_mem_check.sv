// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4l_mem_check
        #(
            parameter   int                 MEM_ADDR_BITS    = 10                   ,
            parameter   int                 MEM_SIZE         = (1 << MEM_ADDR_BITS) ,
            parameter   longint unsigned    ADDR_BASE        = 0                    ,
            parameter   bit                 SHOW_MATCH       = 0                    ,
            parameter   bit                 SHOW_SKIP        = 0                    ,
            parameter   bit                 CHECK_BRESP      = 1                    ,
            parameter   bit                 CHECK_RRESP      = 1                    
        )
        (
            jelly3_axi4l_if.mon    mon_axi4l
        );

    localparam  int     AXI_ADDR_BITS    = mon_axi4l.ADDR_BITS                          ;
    localparam  int     AXI_DATA_BITS    = mon_axi4l.DATA_BITS                          ;
    localparam  int     AXI_STRB_BITS    = mon_axi4l.STRB_BITS                          ;
    localparam  int     AXI_RESP_BITS    = mon_axi4l.RESP_BITS                          ;
    localparam  int     AXI_DATA_BYTES   = AXI_STRB_BITS                                ;
    localparam  int     AXI_ADDR_LSB     = AXI_STRB_BITS > 1 ? $clog2(AXI_STRB_BITS) : 0;
    localparam  int     AW_QUEUE_LIMIT   = mon_axi4l.LIMIT_AW > 0 ? mon_axi4l.LIMIT_AW : 1;
    localparam  int     W_QUEUE_LIMIT    = mon_axi4l.LIMIT_W  > 0 ? mon_axi4l.LIMIT_W  : 1;
    localparam  int     WR_QUEUE_LIMIT   = (AW_QUEUE_LIMIT > W_QUEUE_LIMIT) ? AW_QUEUE_LIMIT : W_QUEUE_LIMIT;
    localparam  int     AR_QUEUE_LIMIT   = mon_axi4l.LIMIT_AR > 0 ? mon_axi4l.LIMIT_AR : 1;

    localparam  type    addr_t           = logic [AXI_ADDR_BITS-1:0]  ;
    localparam  type    data_t           = logic [AXI_DATA_BITS-1:0]  ;
    localparam  type    strb_t           = logic [AXI_STRB_BITS-1:0]  ;
    localparam  type    resp_t           = logic [AXI_RESP_BITS-1:0]  ;
    localparam  type    mem_index_t      = logic [MEM_ADDR_BITS-1:0]  ;

    addr_t                  aw_queue[$];
    data_t                  wdata_queue[$];
    strb_t                  wstrb_queue[$];
    addr_t                  wr_addr_queue[$];
    data_t                  wr_data_queue[$];
    strb_t                  wr_strb_queue[$];
    logic                   wr_track_queue[$];
    addr_t                  rd_addr_queue[$];
    data_t                  rd_expect_queue[$];
    logic                   rd_track_queue[$];
    logic                   mem_valid            [MEM_SIZE-1:0];
    data_t                  mem_data             [MEM_SIZE-1:0];
    int unsigned            pending_write_count  [MEM_SIZE-1:0];


    function automatic addr_t align_addr
            (
                input   addr_t  addr
            );
        if ( AXI_ADDR_LSB > 0 ) begin
            align_addr = addr_t'({addr[AXI_ADDR_BITS-1:AXI_ADDR_LSB], {AXI_ADDR_LSB{1'b0}}});
        end
        else begin
            align_addr = addr;
        end
    endfunction

    function automatic bit in_range
            (
                input   addr_t  addr
            );
        longint unsigned start_addr;
        longint unsigned end_addr;
        longint unsigned byte_span;
    begin
        byte_span   = longint'(MEM_SIZE) * AXI_DATA_BYTES;
        start_addr  = ADDR_BASE;
        end_addr    = ADDR_BASE + (byte_span == 0 ? 0 : (byte_span - 1));
        in_range    = (longint'(addr) >= start_addr) && (longint'(addr) <= end_addr);
    end
    endfunction

    function automatic mem_index_t get_index
            (
                input   addr_t  addr
            );
        longint unsigned offset;
    begin
        offset    = (longint'(addr) - ADDR_BASE) >> AXI_ADDR_LSB;
        get_index = mem_index_t'(offset);
    end
    endfunction


    wire    issue_aw = mon_axi4l.awvalid && mon_axi4l.awready;
    wire    issue_w  = mon_axi4l.wvalid  && mon_axi4l.wready ;
    wire    issue_b  = mon_axi4l.bvalid  && mon_axi4l.bready ;
    wire    issue_ar = mon_axi4l.arvalid && mon_axi4l.arready;
    wire    issue_r  = mon_axi4l.rvalid  && mon_axi4l.rready ;


    always @(posedge mon_axi4l.aclk) begin
        addr_t          addr;
        mem_index_t     index;
        data_t          wr_data;
        strb_t          wr_strb;
        data_t          rd_expect;
        logic           wr_track;
        logic           rd_track;

        if ( ~mon_axi4l.aresetn ) begin
            aw_queue.delete();
            wdata_queue.delete();
            wstrb_queue.delete();
            wr_addr_queue.delete();
            wr_data_queue.delete();
            wr_strb_queue.delete();
            wr_track_queue.delete();
            rd_addr_queue.delete();
            rd_expect_queue.delete();
            rd_track_queue.delete();
            for ( int i = 0; i < MEM_SIZE; ++i ) begin
                mem_data[i]            <= '0;
                mem_valid[i]           <= '0;
                pending_write_count[i] <= '0;
            end
        end
        else if ( mon_axi4l.aclken ) begin
            if ( issue_aw ) begin
                assert (aw_queue.size() < AW_QUEUE_LIMIT)
                    else $error("ERROR: %m: aw queue overflow size=%0d", aw_queue.size());
                addr = align_addr(mon_axi4l.awaddr);
                aw_queue.push_back(addr);
                if ( in_range(addr) ) begin
                    index = get_index(addr);
                    mem_valid[index] <= 1'b0;
                    if ( SHOW_SKIP ) begin
                        $display("[%m(%t)] write issue invalidate addr=%h", $time, addr);
                    end
                end
                else if ( SHOW_SKIP ) begin
                    $display("[%m(%t)] write issue out of checker range addr=%h", $time, addr);
                end
            end

            if ( issue_w ) begin
                assert (wdata_queue.size() < W_QUEUE_LIMIT)
                    else $error("ERROR: %m: w queue overflow size=%0d", wdata_queue.size());
                wdata_queue.push_back(mon_axi4l.wdata);
                wstrb_queue.push_back(mon_axi4l.wstrb);
            end

            if ( aw_queue.size() > 0 && wdata_queue.size() > 0 && wstrb_queue.size() > 0 ) begin
                addr = aw_queue.pop_front();
                wr_data = wdata_queue.pop_front();
                wr_strb = wstrb_queue.pop_front();
                wr_track = in_range(addr);

                wr_addr_queue.push_back(addr);
                wr_data_queue.push_back(wr_data);
                wr_strb_queue.push_back(wr_strb);
                wr_track_queue.push_back(wr_track);

                if ( wr_track ) begin
                    index = get_index(addr);
                    pending_write_count[index] <= pending_write_count[index] + 1;
                end

                assert (wr_addr_queue.size() <= WR_QUEUE_LIMIT)
                    else $error("ERROR: %m: write-response queue overflow size=%0d", wr_addr_queue.size());
            end

            if ( issue_ar ) begin
                addr = align_addr(mon_axi4l.araddr);
                if ( in_range(addr) ) begin
                    index = get_index(addr);
                    rd_addr_queue.push_back(addr);
                    rd_expect_queue.push_back(mem_data[index]);
                    rd_track_queue.push_back((pending_write_count[index] == 0) && mem_valid[index]);

                    if ( SHOW_SKIP && !((pending_write_count[index] == 0) && mem_valid[index]) ) begin
                        $display("[%m(%t)] read issue skip-check addr=%h valid=%b pending=%0d", $time, addr, mem_valid[index], pending_write_count[index]);
                    end
                end
                else begin
                    rd_addr_queue.push_back(addr);
                    rd_expect_queue.push_back('0);
                    rd_track_queue.push_back(1'b0);
                    if ( SHOW_SKIP ) begin
                        $display("[%m(%t)] read issue out of checker range addr=%h", $time, addr);
                    end
                end

                assert (rd_addr_queue.size() <= AR_QUEUE_LIMIT)
                    else $error("ERROR: %m: read-response queue overflow size=%0d", rd_addr_queue.size());
            end

            if ( issue_b ) begin
                assert (wr_addr_queue.size() > 0)
                    else $error("ERROR: %m: b response without pending write command");
                if ( wr_addr_queue.size() > 0 ) begin
                    addr = wr_addr_queue.pop_front();
                    wr_data  = wr_data_queue.pop_front();
                    wr_strb  = wr_strb_queue.pop_front();
                    wr_track = wr_track_queue.pop_front();
                    if ( wr_track ) begin
                        index = get_index(addr);
                        if ( pending_write_count[index] > 0 ) begin
                            pending_write_count[index] <= pending_write_count[index] - 1;
                        end

                        if ( !CHECK_BRESP || mon_axi4l.bresp == resp_t'(2'b00) ) begin
                            for ( int i = 0; i < AXI_STRB_BITS; ++i ) begin
                                if ( wr_strb[i] ) begin
                                    mem_data[index][i*8 +: 8]  <= wr_data[i*8 +: 8];
                                end
                            end
                            if ( pending_write_count[index] == 1 ) begin
                                mem_valid[index] <= 1'b1;
                            end
                        end
                        else begin
                            $error("ERROR: %m: bresp error addr=%h resp=%0d", addr, mon_axi4l.bresp);
                        end
                    end
                end
            end

            if ( issue_r ) begin
                assert (rd_addr_queue.size() > 0)
                    else $error("ERROR: %m: r response without pending read command");
                if ( rd_addr_queue.size() > 0 ) begin
                    addr = rd_addr_queue.pop_front();
                    rd_expect = rd_expect_queue.pop_front();
                    rd_track  = rd_track_queue.pop_front();
                    if ( rd_track ) begin
                        index = get_index(addr);
                        if ( CHECK_RRESP && mon_axi4l.rresp != resp_t'(2'b00) ) begin
                            $error("ERROR: %m: rresp error addr=%h resp=%0d", addr, mon_axi4l.rresp);
                        end
                        else if ( mon_axi4l.rdata !== rd_expect ) begin
                            $error("ERROR: %m: read data mismatch addr=%h expected=%h actual=%h", addr, rd_expect, mon_axi4l.rdata);
                        end
                        else if ( SHOW_MATCH ) begin
                            $display("[%m(%t)] read match addr=%h data=%h", $time, addr, mon_axi4l.rdata);
                        end
                    end
                end
            end
        end
    end

endmodule


`default_nettype wire


// end of file
