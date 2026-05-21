// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4_mem_check
        #(
            parameter   bit     SHOW_MATCH      = 0,
            parameter   bit     SHOW_SKIP       = 0,
            parameter   bit     CHECK_BRESP     = 1,
            parameter   bit     CHECK_RRESP     = 1,
            parameter   bit     CHECK_WLAST     = 1,
            parameter   bit     CHECK_RLAST     = 1
        )
        (
            jelly3_axi4_if.mon  mon_axi4
        );

    localparam  int     ID_BITS     = mon_axi4.ID_BITS;
    localparam  int     ADDR_BITS   = mon_axi4.ADDR_BITS;
    localparam  int     LEN_BITS    = mon_axi4.LEN_BITS;
    localparam  int     SIZE_BITS   = mon_axi4.SIZE_BITS;
    localparam  int     BURST_BITS  = mon_axi4.BURST_BITS;
    localparam  int     BYTE_BITS   = mon_axi4.BYTE_BITS;
    localparam  int     DATA_BITS   = mon_axi4.DATA_BITS;
    localparam  int     STRB_BITS   = mon_axi4.STRB_BITS;
    localparam  int     RESP_BITS   = mon_axi4.RESP_BITS;
    localparam  int     DATA_BYTES  = STRB_BITS;
    localparam  int     ADDR_LSB    = STRB_BITS > 1 ? $clog2(STRB_BITS) : 0;

    localparam  type    id_t           = logic  [ID_BITS-1:0]   ;
    localparam  type    addr_t         = logic  [ADDR_BITS-1:0] ;
    localparam  type    len_t          = logic  [LEN_BITS-1:0]  ;
    localparam  type    size_t         = logic  [SIZE_BITS-1:0] ;
    localparam  type    burst_t        = logic  [BURST_BITS-1:0];
    localparam  type    byte_t         = logic  [BYTE_BITS-1:0] ;
    localparam  type    data_t         = byte_t [DATA_BYTES-1:0];
    localparam  type    strb_t         = logic  [STRB_BITS-1:0] ;
    localparam  type    resp_t         = logic  [RESP_BITS-1:0] ;

    typedef struct packed {
        int         writers;
        strb_t      strb;
        data_t      data;
    } memory_t;

    typedef struct packed {
        addr_t      addr;
        logic       dirty;
    } read_t;

    memory_t mem [addr_t];

    read_t   read_queue [$];

    // 書き込み要求した時点で、完了までそのアドレスは無効
    task write_start (
        input addr_t  addr,
        input strb_t  strb,
        input data_t  data
    );
        // 書き込み予約
        if ( mem.exists(addr) ) begin
            mem[addr].writers++;
        end
        else begin
            mem[addr].writers = 1;
            mem[addr].strb = 'x;
            mem[addr].data = 'x;
        end

        // 読み出し待ちが居れば無効化
        for ( int i = 0; i < read_queue.size(); i++ ) begin
            if ( read_queue[i].addr == addr ) begin
                read_queue[i].dirty = 1'b1;
            end
        end
//      $display("write_start: addr=%h strb=%b data=%h, writers=%0d", addr, strb, data, mem[addr].writers);
    endtask

    // 書き込みが完了したときに、メモリに反映
    task write_complete (
        input addr_t  addr,
        input strb_t  strb,
        input data_t  data
    );
        if ( !mem.exists(addr) || mem[addr].writers <= 0 ) begin
            $display("%t ERROR: write to non-existing address %h", $time(), addr);
        end
//      $display("write_complete: addr=%h strb=%b data=%h, writers=%0d", addr, strb, data, mem[addr].writers);

        // 書き込みを反映させる
        mem[addr].writers--;
        for ( int i = 0; i < DATA_BYTES; i = i + 1 ) begin
            if ( strb[i] ) begin
                mem[addr].strb[i] = 1'b1;
                mem[addr].data[i] = data[i];
            end
        end
    endtask

    task read_start (
        input addr_t  addr,
        input len_t   len
    );
        for ( int i = 0; i < int'(len) + 1; i++ ) begin
            if ( mem.exists(addr) && mem[addr].writers > 0 ) begin
                read_queue.push_back( '{ addr, 1'b1 } );
            end
            else begin
                read_queue.push_back( '{ addr, 1'b0 } );
            end
            addr += DATA_BYTES;
        end
    endtask

    task read_complete (
        input data_t  data
    );
        automatic bit match = 0;
        automatic bit error = 0;
        automatic addr_t addr;

        // キューの先頭からアドレスを取り出す
        addr = read_queue[0].addr;

        // 内容チェック
        if ( !read_queue[0].dirty && mem.exists(addr) && mem[addr].writers == 0 ) begin
            for ( int i = 0; i < DATA_BYTES; i++ ) begin
                if ( mem[addr].strb[i] ) begin
                    if ( mem[addr].data[i] != data[i] ) begin
                        error = 1;
                    end
                    else begin
                        match = 1;
                    end
                end
            end
            if ( error ) begin
                $display("%t ERROR(miss match): addr=%h strb=%b data=%h expected=%h", $time(), addr, mem[addr].strb, data, mem[addr].data);
            end
            else if ( SHOW_MATCH && match ) begin
                $display("MATCH: addr=%h strb=%b data=%h expected=%h", addr, mem[addr].strb, data, mem[addr].data);
            end
        end
        read_queue.pop_front();

        if ( SHOW_SKIP && !match && !error ) begin
            $display("SKIP: addr=%h data=%h", addr, data);
        end
    endtask



    typedef struct packed {
        addr_t  awaddr  ;
        len_t   awlen   ;
    } aw_t;

    typedef struct packed {
        logic   wlast   ;
        strb_t  wstrb   ;
        data_t  wdata   ;
    } w_t;

    typedef struct packed {
        addr_t  waddr   ;
        strb_t  wstrb   ;
        data_t  wdata   ;
    } write_t;

    typedef struct packed {
        addr_t  araddr  ;
        len_t   arlen   ;
    } ar_t;

    aw_t    aw_queue [$];
    w_t     w_queue  [$];
    write_t write_queue [$];
    len_t   b_queue  [$];
//  ar_t    ar_queue [$];

    logic   wbusy ;
    addr_t  waddr ;
    len_t   wlen  ;
    logic   rbusy ;
    addr_t  raddr ;
    len_t   rlen  ;

    always @( posedge mon_axi4.aclk ) begin
        if ( !mon_axi4.aresetn ) begin
            mem.delete();
            aw_queue.delete();
            w_queue.delete();
//          ar_queue.delete();
            wbusy <= 1'b0;
            rbusy <= 1'b0;
        end
        else if ( mon_axi4.aclken ) begin
            if ( mon_axi4.awvalid && mon_axi4.awready ) begin
//              $display("awaddr=%h awlen=%h", mon_axi4.awaddr, mon_axi4.awlen);
                aw_queue.push_back( '{ mon_axi4.awaddr, mon_axi4.awlen } );
                b_queue.push_back( mon_axi4.awlen );
            end
            if ( mon_axi4.wvalid && mon_axi4.wready ) begin
                w_queue.push_back( '{ mon_axi4.wlast, mon_axi4.wstrb, mon_axi4.wdata} );
            end
            if ( mon_axi4.arvalid && mon_axi4.arready ) begin
//              ar_queue.push_back( '{ mon_axi4.araddr, mon_axi4.arlen } );
                read_start( mon_axi4.araddr, mon_axi4.arlen );
            end

            // 書き込み成立したら書き込み要求処理
            while ( aw_queue.size() > 0 && w_queue.size() > 0 ) begin
                if ( !wbusy ) begin
                    waddr = aw_queue[0].awaddr;
                    wlen  = aw_queue[0].awlen;
                    wbusy = 1'b1;
                end

                write_start(waddr, w_queue[0].wstrb, w_queue[0].wdata);
                write_queue.push_back( '{ waddr, w_queue[0].wstrb, w_queue[0].wdata } );

                if ( wlen == 0 ) begin
                    if ( CHECK_WLAST && !w_queue[0].wlast ) begin
                        $display("%t ERROR: wlast=%b (expected:1)", $time(), w_queue[0].wlast);
                    end
                    aw_queue.pop_front();
                    wbusy = 1'b0;
                end
                else begin
                    if ( CHECK_WLAST && w_queue[0].wlast ) begin
                        $display("%t ERROR: wlast=%b (expected:0)", $time(), w_queue[0].wlast);
                    end
                    waddr += DATA_BYTES;
                    wlen  -= 1;
                end
                w_queue.pop_front();
            end

            if ( mon_axi4.bvalid && mon_axi4.bready ) begin
                if ( CHECK_BRESP && mon_axi4.bresp != 2'b00 ) begin
                    $display("ERROR: bresp=%b expected=00", mon_axi4.bresp);
                end
                if ( b_queue.size() <= 0 ) begin
                    $display("%t ERROR: unexpected bvalid", $time());
//                  $finish;
                end

                for ( int i = 0; i < int'(b_queue[0]) + 1; i++ ) begin
                    write_complete(write_queue[0].waddr, write_queue[0].wstrb, write_queue[0].wdata);
                    write_queue.pop_front();
                end
                b_queue.pop_front();
            end

            if ( mon_axi4.rvalid && mon_axi4.rready ) begin
                read_complete(mon_axi4.rdata);
                /*
                if ( CHECK_RRESP && mon_axi4.rresp != 2'b00 ) begin
                    $display("%t ERROR: rresp=%b expected=00", $time(), mon_axi4.rresp);
                end

                if ( !rbusy ) begin
                    raddr = ar_queue[0].araddr;
                    rlen  = ar_queue[0].arlen;
                    rbusy = 1'b1;
                end

                read_check(raddr, mon_axi4.rdata);

                if ( rlen == 0 ) begin
                    if ( CHECK_RLAST && !mon_axi4.rlast ) begin
                        $display("ERROR: rlast expected at addr=%h", ar_queue[0].araddr);
                    end
                    ar_queue.pop_front();
                    rbusy = 1'b0;
                end
                else begin
                    raddr += DATA_BYTES;
                    rlen  -= 1;
                end
                */
            end
        end
    end

endmodule


`default_nettype wire


// end of file
