// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// Simple Dualport-RAM
module jelly3_ram_simple_dualport
        #(
            parameter   int     ADDR_BITS    = 6                            ,
            parameter   type    addr_t       = logic    [ADDR_BITS-1:0]     ,
            parameter   int     WE_BITS      = 1                            ,
            parameter   type    we_t         = logic    [WE_BITS-1:0]       ,
            parameter   int     DATA_BITS    = 8                            ,
            parameter   type    data_t       = logic    [DATA_BITS-1:0]     ,
            parameter   int     WORD_BITS    = $bits(data_t) / $bits(we_t)  ,
            parameter   type    word_t       = logic    [WORD_BITS-1:0]     ,
            parameter   int     MEM_DEPTH    = 2 ** $bits(addr_t)           ,
            parameter           RAM_TYPE     = "distributed"                ,
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
            // write port
            input   var logic       wr_clk      ,
            input   var we_t        wr_en       ,
            input   var addr_t      wr_addr     ,
            input   var data_t      wr_din      ,
            
            // read port
            input   var logic       rd_clk      ,
            input   var logic       rd_en       ,
            input   var logic       rd_regcke   ,
            input   var addr_t      rd_addr     ,
            output  var data_t      rd_dout     
        );
    
    // memory
    (* ram_style = RAM_TYPE *)
    logic   [$bits(data_t)-1:0] mem [0:MEM_DEPTH-1];
    
    
    // write port
    for ( genvar i = 0; i < $bits(we_t); i++ ) begin : loop_we0
        always_ff @ ( posedge wr_clk ) begin
            if ( wr_en[i] ) begin
                mem[wr_addr][i*$bits(word_t) +: $bits(word_t)] <= wr_din[i*$bits(word_t) +: $bits(word_t)];
            end
        end
    end
    
    
    // read port
    logic   [$bits(data_t)-1:0] tmp_dout;
    always_ff @(posedge rd_clk ) begin
        if ( rd_en ) begin
            tmp_dout <= mem[rd_addr];
        end
    end
    
    // DOUT FF insert
    if ( DOUT_REG ) begin : blk_reg
        logic   [$bits(data_t)-1:0] reg_dout;
        always_ff @(posedge rd_clk) begin
            if ( rd_regcke ) begin
                reg_dout <= tmp_dout;
            end
        end
        assign rd_dout = reg_dout;
    end
    else begin : blk_no_reg
        assign rd_dout = tmp_dout;
    end
    

    // initialize
    initial begin
        if ( FILLMEM ) begin
            for ( int i = 0; i < MEM_DEPTH; i++ ) begin
                mem[i] = FILLMEM_DATA;
            end
        end
        
        if ( READMEMB ) begin
            $display("readmemb:%s", READMEM_FILE);
            $readmemb(READMEM_FILE, mem);
        end
        if ( READMEMH ) begin
            $display("readmemh:%s", READMEM_FILE);
            $readmemh(READMEM_FILE, mem);
        end
    end
    
endmodule


// End of file
