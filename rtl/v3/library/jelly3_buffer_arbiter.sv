// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// バッファ割り当て調停
module jelly3_buffer_arbiter
        #(
            parameter   int     BUFFER_NUM    = 3                               ,
            parameter   int     READER_NUM    = 1                               ,
            parameter   int     ADDR_BITS     = 32                              ,
            parameter   type    addr_t        = logic [ADDR_BITS-1:0]           ,
            parameter   int     REFCNT_BITS   = 4                               ,
            parameter   type    refcnt_t      = logic [REFCNT_BITS-1:0]         ,
            parameter   int     INDEX_BITS    = $clog2(BUFFER_NUM)              ,
            parameter   type    index_t       = logic [INDEX_BITS-1:0]
        )
        (
            input   var logic                               reset               ,
            input   var logic                               clk                 ,
            input   var logic                               cke                 ,

            input   var addr_t  [BUFFER_NUM-1:0]            param_buf_addr      ,

            input   var logic                               writer_request      ,
            input   var logic                               writer_release      ,
            output  var addr_t                              writer_addr         ,
            output  var index_t                             writer_index        ,

            input   var logic   [READER_NUM-1:0]            reader_request      ,
            input   var logic   [READER_NUM-1:0]            reader_release      ,
            output  var addr_t  [READER_NUM-1:0]            reader_addr         ,
            output  var index_t [READER_NUM-1:0]            reader_index        ,

            output  var addr_t                              newest_addr         ,
            output  var index_t                             newest_index        ,

            output  var refcnt_t [BUFFER_NUM-1:0]           status_refcnt
        );


    // status
    logic                       reg_writer_busy;
    logic   [READER_NUM-1:0]    reg_reader_busy;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_writer_busy <= 1'b0;
            reg_reader_busy <= '0;
        end
        else if ( cke ) begin
            if ( writer_request ) begin
                reg_writer_busy <= 1'b1;
                if ( reg_writer_busy ) begin
                    $display("ERROR(buffer_arbiter): illegal writer_request");
                end
            end
            if ( writer_release ) begin
                reg_writer_busy <= 1'b0;
            end

            for ( int k = 0; k < READER_NUM; ++k ) begin
                if ( reader_request[k] ) begin
                    reg_reader_busy[k] <= 1'b1;
                    if ( reg_reader_busy[k] ) begin
                        $display("ERROR(buffer_arbiter): illegal reader_request(%d)", k);
                    end
                end
                if ( reader_release[k] ) begin
                    reg_reader_busy[k] <= 1'b0;
                end
            end
        end
    end


    // control
    index_t                     reg_newest,  next_newest;
    refcnt_t [BUFFER_NUM-1:0]   reg_refcnt,  next_refcnt;
    logic    [BUFFER_NUM-1:0]   reg_bufbusy, next_bufbusy;
    index_t                     reg_writing, next_writing;
    index_t  [READER_NUM-1:0]   reg_reading, next_reading;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_newest  <= '0;
            reg_refcnt  <= '0;
            reg_bufbusy <= '0;
            reg_writing <= '0;
            reg_reading <= '0;
        end
        else if ( cke ) begin
            reg_newest  <= next_newest;
            reg_refcnt  <= next_refcnt;
            reg_bufbusy <= next_bufbusy;
            reg_writing <= next_writing;
            reg_reading <= next_reading;
        end
    end

    always_comb begin
        next_newest  = reg_newest;
        next_refcnt  = reg_refcnt;
        next_bufbusy = reg_bufbusy;
        next_writing = reg_writing;
        next_reading = reg_reading;

        if ( reg_writer_busy && writer_release ) begin
            // 書き終わったら最新にマーク
            next_newest = next_writing;

            // 未使用のバッファ割り当て
            begin : loop_writer
                for ( int i = 0; i < BUFFER_NUM; ++i ) begin
                    if ( !next_bufbusy[i] && index_t'(i) != next_newest ) begin
                        next_writing = index_t'(i);
                        disable loop_writer;
                    end
                end
                $display("ERROR(buffer_arbiter): error write_alloc");
            end
        end

        // reader release
        for ( int i = 0; i < READER_NUM; ++i ) begin
            if ( reg_reader_busy[i] && reader_release[i] ) begin
                next_refcnt[next_reading[i]] = next_refcnt[next_reading[i]] - 1'b1;
            end
        end

        // reader request
        for ( int i = 0; i < READER_NUM; ++i ) begin
            if ( !reg_reader_busy[i] && reader_request[i] ) begin
                next_reading[i] = next_newest;
                next_refcnt[next_newest] = next_refcnt[next_newest] + 1'b1;
            end
        end

        // busy
        for ( int i = 0; i < BUFFER_NUM; ++i ) begin
            next_bufbusy[i] = (next_refcnt[i] != '0);
        end
    end


    // assign
    always_comb begin
        writer_index = reg_writing;
        writer_addr  = param_buf_addr[next_writing];
        reader_index = reg_reading;
        for ( int j = 0; j < READER_NUM; ++j ) begin
            reader_addr[j] = param_buf_addr[next_reading[j]];
        end
    end

    assign newest_addr   = param_buf_addr[reg_newest];
    assign newest_index  = reg_newest;

    assign status_refcnt = reg_refcnt;


endmodule


`default_nettype wire


// end of file
