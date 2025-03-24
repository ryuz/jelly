// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// Dualport-RAM
module jelly2_ram_dualport
        #(
            parameter   int                                 ADDR_WIDTH   = 10,
            parameter   int                                 DATA_WIDTH   = 32,
            parameter   int                                 WE_WIDTH     = 1,
            parameter   int                                 WORD_WIDTH   = DATA_WIDTH/WE_WIDTH,
            parameter   int                                 MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                                       RAM_TYPE     = "block",
            parameter   bit                                 DOUT_REGS0   = 0,
            parameter   bit                                 DOUT_REGS1   = 0,
            parameter                                       MODE0        = "NO_CHANGE",
            parameter                                       MODE1        = "NO_CHANGE",

            parameter   bit                                 FILLMEM      = 0,
            parameter   logic   [WE_WIDTH*WORD_WIDTH-1:0]   FILLMEM_DATA = 0,
            parameter   bit                                 READMEMB     = 0,
            parameter   bit                                 READMEMH     = 0,
            parameter                                       READMEM_FIlE = ""
        )
        (
            // port0
            input   var logic                               port0_clk,
            input   var logic                               port0_en,
            input   var logic                               port0_regcke,
            input   var logic   [WE_WIDTH-1:0]              port0_we,
            input   var logic   [ADDR_WIDTH-1:0]            port0_addr,
            input   var logic   [WE_WIDTH*WORD_WIDTH-1:0]   port0_din,
            output  var logic   [WE_WIDTH*WORD_WIDTH-1:0]   port0_dout,
            
            // port1
            input   var logic                               port1_clk,
            input   var logic                               port1_en,
            input   var logic                               port1_regcke,
            input   var logic   [WE_WIDTH-1:0]              port1_we,
            input   var logic   [ADDR_WIDTH-1:0]            port1_addr,
            input   var logic   [WE_WIDTH*WORD_WIDTH-1:0]   port1_din,
            output  var logic   [WE_WIDTH*WORD_WIDTH-1:0]   port1_dout
        );
    
    // verilator lint_off MULTIDRIVEN
    
    // memory
    (* ram_style = RAM_TYPE *)
    logic   [WE_WIDTH*WORD_WIDTH-1:0]   mem [0:MEM_SIZE-1];
    
    // dout
    logic   [WE_WIDTH*WORD_WIDTH-1:0]   tmp_port0_dout;
    logic   [WE_WIDTH*WORD_WIDTH-1:0]   tmp_port1_dout;
    
    
    // port0
    generate
    if ( 256'(MODE0) == 256'("WRITE_FIRST") ) begin : blk_wf0
        // write first
        for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_we0
            always_ff @ ( posedge port0_clk ) begin
                if ( port0_en ) begin
                    if ( port0_we[i] ) begin
                        mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port0_din[i*WORD_WIDTH +: WORD_WIDTH] ;
                        tmp_port0_dout[i*WORD_WIDTH +: WORD_WIDTH]  <= port0_din[i*WORD_WIDTH +: WORD_WIDTH] ;
                    end
                    else begin
                        tmp_port0_dout[i*WORD_WIDTH +: WORD_WIDTH]  <= mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH];
                    end
                end
            end
        end
    end
    else if ( 256'(MODE0) == 256'("READ_FIRST") ) begin : blk_rf0
        // read first
        for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_we0
            always_ff @ ( posedge port0_clk ) begin
                if ( port0_en ) begin
                    if ( port0_we[i] ) begin
                        mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port0_din[i*WORD_WIDTH +: WORD_WIDTH];
                    end
                    tmp_port0_dout[i*WORD_WIDTH +: WORD_WIDTH] <= mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH];
                end
            end
        end
    end
    else if ( 256'(MODE0) == 256'("NO_CHANGE") ) begin : blk_nc0
        // no change
        for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_we0
            always_ff @ ( posedge port0_clk ) begin
                if ( port0_en ) begin
                    if ( port0_we[i] ) begin
                        mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port0_din[i*WORD_WIDTH +: WORD_WIDTH] ;
                    end
                end
            end
        end
        always_ff @ ( posedge port0_clk ) begin
            if ( port0_en ) begin
                if ( ~|port0_we ) begin
                    tmp_port0_dout <= mem[port0_addr];
                end
            end
        end
    end
    else if ( 256'(MODE0) == 256'("NORMAL") ) begin : blk_norm0
        // normal
        for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_we0
            always_ff @ ( posedge port0_clk ) begin
                if ( port0_en ) begin
                    if ( port0_we[i] ) begin
                        mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port0_din[i*WORD_WIDTH +: WORD_WIDTH] ;
                    end
                    else begin
                        tmp_port0_dout[i*WORD_WIDTH +: WORD_WIDTH]  <= mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH];
                    end
                end
            end
        end
    end
    else begin
        // error
        initial begin
            $display("!!![ERROR]!!! jelly2_ram_dualport:parameter error");
            $stop();
        end
    end

    // DOUT FF insert
    if ( DOUT_REGS0 ) begin
        logic   [WE_WIDTH*WORD_WIDTH-1:0]  reg_port0_dout;
        always_ff @(posedge port0_clk) begin
            if ( port0_regcke ) begin
                reg_port0_dout <= tmp_port0_dout;
            end
        end
        assign port0_dout = reg_port0_dout;
    end
    else begin
        assign port0_dout = tmp_port0_dout;
    end
    endgenerate
    
    
    // port1
    generate
    if ( 256'(MODE1) == 256'("WRITE_FIRST") ) begin : blk_wf1
        // write first
        for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_we1
            always_ff @ ( posedge port1_clk ) begin
                if ( port1_en ) begin
                    if ( port1_we[i] ) begin
                        mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port1_din[i*WORD_WIDTH +: WORD_WIDTH];
                        tmp_port1_dout[i*WORD_WIDTH +: WORD_WIDTH] <= port1_din[i*WORD_WIDTH +: WORD_WIDTH];
                    end
                    else begin
                        tmp_port1_dout[i*WORD_WIDTH +: WORD_WIDTH] <= mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH];
                    end
                end
            end
        end
    end
    else if ( 256'(MODE1) == 256'("READ_FIRST")) begin : blk_rf1
        // read first
        for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_we1
            always_ff @ ( posedge port1_clk ) begin
                if ( port1_en ) begin
                    if ( port1_we[i] ) begin
                        mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port1_din[i*WORD_WIDTH +: WORD_WIDTH];
                    end
                    tmp_port1_dout[i*WORD_WIDTH +: WORD_WIDTH] <= mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH];
                end
            end
        end
    end
    else if ( 256'(MODE1) == 256'("NO_CHANGE") ) begin : blk_nc1
        // no change
        for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_we1
            always_ff @ ( posedge port1_clk ) begin
                if ( port1_en ) begin
                    if ( port1_we[i] ) begin
                        mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port1_din[i*WORD_WIDTH +: WORD_WIDTH] ;
                    end
                end
            end
        end
        always_ff @ ( posedge port1_clk ) begin
            if ( port1_en ) begin
                    if ( ~|port1_we ) begin
                    tmp_port1_dout <= mem[port1_addr];
                    end
            end
        end
    end
    else if ( 256'(MODE1) == 256'("NORMAL") ) begin : blk_norm1
        // normal
        for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_we1
            always_ff @ ( posedge port1_clk ) begin
                if ( port1_en ) begin
                    if ( port1_we[i] ) begin
                        mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port1_din[i*WORD_WIDTH +: WORD_WIDTH];
                    end
                    else begin
                        tmp_port1_dout[i*WORD_WIDTH +: WORD_WIDTH] <= mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH];
                    end
                end
            end
        end
    end
    else begin
        // error
        initial begin
            $display("!!![ERROR]!!! jelly2_ram_dualport:parameter error");
            $stop();
        end
    end
        
    // DOUT FF insert
    if ( DOUT_REGS1 ) begin
        logic   [WE_WIDTH*WORD_WIDTH-1:0]   reg_port1_dout;
        always_ff @(posedge port1_clk) begin
            if ( port1_regcke ) begin
                reg_port1_dout <= tmp_port1_dout;
            end
        end
        assign port1_dout = reg_port1_dout;
    end
    else begin
        assign port1_dout = tmp_port1_dout;
    end
    endgenerate
    
    // verilator lint_on MULTIDRIVEN
    
    
    // initialize
    initial begin
        if ( FILLMEM ) begin
            for ( int i = 0; i < MEM_SIZE; i = i + 1 ) begin
                mem[i] = FILLMEM_DATA;
            end
        end
        
        if ( READMEMB ) begin
            $readmemb(READMEM_FIlE, mem);
        end
        if ( READMEMH ) begin
            $readmemh(READMEM_FIlE, mem);
        end
    end
    
endmodule


`default_nettype wire


// End of file
