// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// Singleport-RAM
module jelly3_ram_singleport
        #(
            parameter   int     ADDR_BITS    = 10                           ,
            parameter   type    addr_t       = logic    [ADDR_BITS-1:0]     ,
            parameter   int     WE_BITS      = 1                            ,
            parameter   type    we_t         = logic    [WE_BITS-1:0]       ,
            parameter   int     DATA_BITS    = 8                            ,
            parameter   type    data_t       = logic    [DATA_BITS-1:0]     ,
            parameter   int     WORD_BITS    = $bits(data_t) / $bits(we_t)  ,
            parameter   type    word_t       = logic    [WORD_BITS-1:0]     ,
            parameter   int     MEM_DEPTH    = 2 ** $bits(addr_t)           ,
            parameter           RAM_TYPE     = "block"                      ,
            parameter           MODE         = "NO_CHANGE"                  ,
            parameter   bit     DOUT_REG     = 1'b0                         ,
            parameter   bit     FILLMEM      = 1'b0                         ,
            parameter   data_t  FILLMEM_DATA = '0                           ,
            parameter   bit     READMEMB     = 1'b0                         ,
            parameter   bit     READMEMH     = 1'b0                         ,
            parameter           READMEM_FILE = ""                           ,
            parameter           DEVICE       = "RTL"                        ,
            parameter           SIMULATION   = "false"                      ,
            parameter           DEBUG        = "false"                      
        )
        (
            input   var logic       clk     ,
            input   var logic       en      ,
            input   var logic       regcke  ,
            input   var we_t        we      ,
            input   var addr_t      addr    ,
            input   var data_t      din     ,
            output  var data_t      dout    
        );
    
    // memory
    (* ram_style = RAM_TYPE *)
    logic   [$bits(data_t)-1:0]     mem [0:MEM_DEPTH-1];
    
    logic   [$bits(data_t)-1:0]     tmp_dout;
    
    if ( string'(MODE) == "WRITE_FIRST" ) begin : blk_wf
        // write first
        for ( genvar i = 0; i < $bits(we_t); i++ ) begin : loop_we
            always_ff @ ( posedge clk ) begin
                if ( en ) begin
                    if ( we[i] ) begin
                        mem[addr][i*$bits(word_t) +: $bits(word_t)] <= din[i*$bits(word_t) +: $bits(word_t)];
                        tmp_dout [i*$bits(word_t) +: $bits(word_t)] <= din[i*$bits(word_t) +: $bits(word_t)];
                    end
                    else begin
                        tmp_dout [i*$bits(word_t) +: $bits(word_t)] <= mem[addr][i*$bits(word_t) +: $bits(word_t)];
                    end
                end
            end
        end
    end
    else if ( string'(MODE) == "READ_FIRST" ) begin : blk_rf
        // read first
        for ( genvar i = 0; i < $bits(we_t); i++ ) begin : loop_we
            always_ff @( posedge clk ) begin
                if ( en ) begin
                    if ( we[i] ) begin
                        mem[addr][i*$bits(word_t) +: $bits(word_t)] <= din[i*$bits(word_t) +: $bits(word_t)];
                    end
                    tmp_dout[i*$bits(word_t) +: $bits(word_t)] <= mem[addr][i*$bits(word_t) +: $bits(word_t)];
                end
            end
        end
    end
    else if ( string'(MODE) == "NO_CHANGE" ) begin : blk_nc1
        // no change
        for ( genvar i = 0; i < $bits(we_t); i++ ) begin : loop_we1
            always_ff @ ( posedge clk ) begin
                if ( en ) begin
                    if ( we[i] ) begin
                        mem[addr][i*$bits(word_t) +: $bits(word_t)] <= din[i*$bits(word_t) +: $bits(word_t)] ;
                    end
                end
            end
        end
        always_ff @ ( posedge clk ) begin
            if ( en ) begin
                if ( ~|we ) begin
                    tmp_dout <= mem[addr];
                end
            end
        end
    end
    else begin
        // error
        initial begin
            $display("!!![ERROR]!!! jelly3_ram_singleport: parameter error");
            $stop();
        end
    end
    
    
    // DOUT FF insert
    if ( DOUT_REG ) begin : blk_dout_reg
        logic   [$bits(data_t)-1:0] reg_dout;
        always_ff @(posedge clk) begin
            if ( regcke ) begin
                reg_dout <= tmp_dout;
            end
        end
        assign dout = reg_dout;
    end
    else begin: blk_dout
        assign dout = tmp_dout;
    end
    
    
    // initialize
    initial begin
        if ( FILLMEM ) begin
            for ( int i = 0; i < MEM_DEPTH; i = i + 1 ) begin
                mem[i] = FILLMEM_DATA;
            end
        end
        
        if ( READMEMB ) begin
            $display("readmemb:%s", READMEM_FILE);
            $readmemb(READMEM_FILE, mem);
        end
        
        if ( READMEMH ) begin
            $display("readmemh:%s", READMEM_FILE);
            $readmemh(              READMEM_FILE, mem);
        end
    end
    
endmodule


`default_nettype wire


// end of file
