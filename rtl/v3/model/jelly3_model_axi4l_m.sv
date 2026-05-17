// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4l_m
        #(
            parameter   longint unsigned    WRITE_ADDR_LOW   = 64'd0                ,
            parameter   longint unsigned    WRITE_ADDR_HIGH  = 64'd4095             ,
            parameter   longint unsigned    READ_ADDR_LOW    = 64'd0                ,
            parameter   longint unsigned    READ_ADDR_HIGH   = 64'd4095             ,
            parameter   int                 WRITE_ISSUE_RATE = 50                   ,
            parameter   int                 READ_ISSUE_RATE  = 50                   ,
            parameter   int                 WRITE_RAND_SEED  = 0                    ,
            parameter   int                 READ_RAND_SEED   = 1                    
        )
        (
            input   var logic       enable      ,
            output  var logic       busy        ,
            output  var logic       write_busy  ,
            output  var logic       read_busy   ,
            jelly3_axi4l_if.m       m_axi4l
        );

    localparam  int     AXI_ADDR_BITS   = m_axi4l.ADDR_BITS                          ;
    localparam  int     AXI_DATA_BITS   = m_axi4l.DATA_BITS                           ;
    localparam  int     AXI_STRB_BITS   = m_axi4l.STRB_BITS                           ;
    localparam  int     AXI_DATA_BYTES  = AXI_STRB_BITS                               ;
    localparam  int     AXI_ADDR_LSB    = AXI_STRB_BITS > 1 ? $clog2(AXI_STRB_BITS) : 0;
    localparam  int     AXI_STRB_MASK   = (1 << AXI_STRB_BITS) - 1                    ;

    localparam  type    addr_t          = logic [AXI_ADDR_BITS-1:0]                  ;
    localparam  type    data_t          = logic [AXI_DATA_BITS-1:0]                  ;
    localparam  type    strb_t          = logic [AXI_STRB_BITS-1:0]                  ;
    localparam  type    prot_t          = logic [m_axi4l.PROT_BITS-1:0]              ;

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_WRITE,
        ST_WRITE_RESP,
        ST_READ,
        ST_READ_RESP
    } state_t;

    integer rand_write = WRITE_RAND_SEED;
    integer rand_read  = READ_RAND_SEED;

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

    function automatic bit rand_hit
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
        rand_hit = rand_mod(100, seed) < rate;
    end
    endfunction

    function automatic addr_t rand_addr
            (
                input   longint unsigned    low_addr,
                input   longint unsigned    high_addr,
                inout   integer             seed
            );
        longint unsigned low_align;
        longint unsigned high_align;
        longint unsigned index;
        longint unsigned count;
        longint unsigned bytes;
    begin
        bytes      = longint'(AXI_DATA_BYTES);
        low_align  = (low_addr  + bytes - 1) / bytes * bytes;
        high_align = (high_addr / bytes) * bytes;
        if ( high_align < low_align ) begin
            rand_addr = addr_t'(low_align);
        end
        else begin
            count     = ((high_align - low_align) / bytes) + 1;
            index     = longint'(rand_mod(int'(count), seed));
            rand_addr = addr_t'(low_align + index * bytes);
        end
    end
    endfunction

    function automatic data_t make_write_data
            (
                input   addr_t      addr,
                inout   integer     seed
            );
        int random_value;
    begin
        random_value   = $random(seed);
        make_write_data = data_t'(addr) ^ data_t'(random_value & 32'h7fff_ffff);
    end
    endfunction

    function automatic strb_t make_write_strb
            (
                inout   integer     seed
            );
        int value;
    begin
        value = rand_mod(AXI_STRB_MASK, seed) + 1;
        make_write_strb = strb_t'(value);
    end
    endfunction

    state_t     state       = ST_IDLE;
    addr_t      awaddr      = '0;
    addr_t      araddr      = '0;
    data_t      wdata       = '0;
    strb_t      wstrb       = '0;
    prot_t      awprot      = '0;
    prot_t      arprot      = '0;
    logic       awvalid     = 1'b0;
    logic       wvalid      = 1'b0;
    logic       bready      = 1'b0;
    logic       arvalid     = 1'b0;
    logic       rready      = 1'b0;

    assign m_axi4l.awaddr  = awvalid ? awaddr : 'x;
    assign m_axi4l.awprot  = awvalid ? awprot : 'x;
    assign m_axi4l.awvalid = awvalid;

    assign m_axi4l.wdata   = wvalid ? wdata : 'x;
    assign m_axi4l.wstrb   = wvalid ? wstrb : 'x;
    assign m_axi4l.wvalid  = wvalid;

    assign m_axi4l.bready  = bready;

    assign m_axi4l.araddr  = arvalid ? araddr : 'x;
    assign m_axi4l.arprot  = arvalid ? arprot : 'x;
    assign m_axi4l.arvalid = arvalid;

    assign m_axi4l.rready  = rready;

    always_ff @(posedge m_axi4l.aclk) begin
        addr_t  next_addr;
        if ( !m_axi4l.aresetn ) begin
            state   <= ST_IDLE;
            awaddr  <= '0;
            araddr  <= '0;
            wdata   <= '0;
            wstrb   <= '0;
            awprot  <= '0;
            arprot  <= '0;
            awvalid <= 1'b0;
            wvalid  <= 1'b0;
            bready  <= 1'b0;
            arvalid <= 1'b0;
            rready  <= 1'b0;
        end
        else if ( m_axi4l.aclken ) begin
            unique case ( state )
                ST_IDLE: begin
                    awvalid <= 1'b0;
                    wvalid  <= 1'b0;
                    bready  <= 1'b0;
                    arvalid <= 1'b0;
                    rready  <= 1'b0;

                    if ( enable ) begin
                        if ( rand_hit(WRITE_ISSUE_RATE, rand_write) ) begin
                                next_addr = rand_addr(WRITE_ADDR_LOW, WRITE_ADDR_HIGH, rand_write);
                                awaddr  <= next_addr;
                                wdata   <= make_write_data(next_addr, rand_write);
                            wstrb   <= make_write_strb(rand_write);
                            awprot  <= '0;
                            awvalid <= 1'b1;
                            wvalid  <= 1'b1;
                            state   <= ST_WRITE;
                        end
                        else if ( rand_hit(READ_ISSUE_RATE, rand_read) ) begin
                            araddr  <= rand_addr(READ_ADDR_LOW, READ_ADDR_HIGH, rand_read);
                            arprot  <= '0;
                            arvalid <= 1'b1;
                            state   <= ST_READ;
                        end
                    end
                end

                ST_WRITE: begin
                    if ( awvalid && m_axi4l.awready ) begin
                        awvalid <= 1'b0;
                    end
                    if ( wvalid && m_axi4l.wready ) begin
                        wvalid <= 1'b0;
                    end
                    if ( !awvalid && !wvalid ) begin
                        bready <= 1'b1;
                        state  <= ST_WRITE_RESP;
                    end
                end

                ST_WRITE_RESP: begin
                    if ( m_axi4l.bvalid && m_axi4l.bready ) begin
                        bready <= 1'b0;
                        state  <= ST_IDLE;
                    end
                end

                ST_READ: begin
                    if ( arvalid && m_axi4l.arready ) begin
                        arvalid <= 1'b0;
                        rready  <= 1'b1;
                        state   <= ST_READ_RESP;
                    end
                end

                ST_READ_RESP: begin
                    if ( m_axi4l.rvalid && m_axi4l.rready ) begin
                        rready <= 1'b0;
                        state  <= ST_IDLE;
                    end
                end
            endcase
        end
    end

    always_comb begin
        write_busy = (state == ST_WRITE) || (state == ST_WRITE_RESP);
        read_busy  = (state == ST_READ) || (state == ST_READ_RESP);
        busy       = write_busy || read_busy;
    end

endmodule


`default_nettype wire


// end of file
