// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// バッファ割り当て調停
module jelly2_buffer_arbiter
        #(
            parameter   int     BUFFER_NUM   = 3,
            parameter   int     READER_NUM   = 1,
            parameter   int     ADDR_WIDTH   = 32,
            parameter   int     REFCNT_WIDTH = 4,
            parameter   int     INDEX_WIDTH  = $clog2(BUFFER_NUM)
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,
            
            input   wire    [BUFFER_NUM-1:0][ADDR_WIDTH-1:0]    param_buf_addr,
            
            input   wire                                        writer_request,
            input   wire                                        writer_release,
            output  reg     [ADDR_WIDTH-1:0]                    writer_addr,
            output  reg     [INDEX_WIDTH-1:0]                   writer_index,
            
            input   wire    [READER_NUM-1:0]                    reader_request,
            input   wire    [READER_NUM-1:0]                    reader_release,
            output  reg     [READER_NUM-1:0][ADDR_WIDTH-1:0]    reader_addr,
            output  reg     [READER_NUM-1:0][INDEX_WIDTH-1:0]   reader_index,
            
            output  wire    [ADDR_WIDTH-1:0]                    newest_addr,
            output  wire    [INDEX_WIDTH-1:0]                   newest_index,
            
            output  wire    [BUFFER_NUM-1:0][REFCNT_WIDTH-1:0]  status_refcnt
        );
    
    
    // status
    reg                         reg_writer_busy;
    reg     [READER_NUM-1:0]    reg_reader_busy;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_writer_busy <= 0;
            reg_reader_busy  <= 0;
        end
        else if ( cke ) begin
            if ( writer_request ) begin
                reg_writer_busy <= 1'b1;
                if ( reg_writer_busy ) begin
                    $display("ERROR(buffer_allocator): illegal writer_request");
                end
            end
            if ( writer_release ) begin
                reg_writer_busy <= 1'b0;
    //          if ( !reg_writer_busy ) begin
    //              $display("ERROR(buffer_allocator): illegal writer_release");
    //          end
            end
            
            for ( int k = 0; k < READER_NUM; ++k ) begin
                if ( reader_request[k] ) begin
                    reg_reader_busy[k] <= 1'b1;
                    if ( reg_reader_busy[k] ) begin
                        $display("ERROR(buffer_allocator): illegal reader_request(%d)", k);
                    end
                end
                if ( reader_release[k] ) begin
                    reg_reader_busy[k] <= 1'b0;
    //              if ( !reg_reader_busy[k] ) begin
    //                  $display("ERROR(buffer_allocator): illegal reader_release(%d)", k);
    //              end
                end
            end
        end
    end
    
    
    // control
    logic                   [INDEX_WIDTH-1:0]   reg_newest,  next_newest;
    logic   [BUFFER_NUM-1:0][REFCNT_WIDTH-1:0]  reg_refcnt,  next_refcnt;
    logic   [BUFFER_NUM-1:0]                    reg_bufbusy, next_bufbusy;
    logic                   [INDEX_WIDTH-1:0]   reg_writing, next_writing;
    logic   [READER_NUM-1:0][INDEX_WIDTH-1:0]   reg_reading, next_reading;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_newest  <= 0;
            reg_refcnt  <= 0;
            reg_bufbusy <= 0;
            reg_writing <= 0;
            reg_reading <= 0;
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
                    if ( !next_bufbusy[i] && INDEX_WIDTH'(i) != next_newest ) begin
                        next_writing = INDEX_WIDTH'(i);
                        disable loop_writer; 
                    end
                end
                $display("ERROR(buffer_allocator): error write_alloc");
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
            next_bufbusy[i] = (next_refcnt[i] != 0);
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
    
    assign newest_addr  = param_buf_addr[reg_newest];
    assign newest_index = reg_newest;
    
    assign status_refcnt = reg_refcnt;
    
    
endmodule


`default_nettype wire


// end of file
