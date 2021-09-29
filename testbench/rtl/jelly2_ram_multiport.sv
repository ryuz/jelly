// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale          1ns / 1ps
`default_nettype    none

// Multiport-RAM
module jelly2_ram_multiport
        #(
            parameter   int                                     PORTS        = 1,
            parameter   int                                     ADDR_WIDTH   = 9,
            parameter   int                                     WE_WIDTH     = 1,
            parameter   int                                     DATA_WIDTH   = 8,
            parameter   int                                     USER_WIDTH   = 0,
            parameter   int                                     MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                                           RAM_TYPE     = "block", // "distributed",
            parameter                                           MODE         = "WRITE_FIRST",
            parameter   int                                     PIPELINES    = 1,
            
            parameter   bit     [DATA_WIDTH-1:0][WE_WIDTH-1:0]  INIT_DATA    = 'x,
            parameter   bit     [PORTS-1:0][USER_WIDTH-1:0]     INIT_USER    = 'x,
            
            parameter   bit                                     FILLMEM      = 0,
            parameter   bit     [DATA_WIDTH-1:0][WE_WIDTH-1:0]  FILLMEM_DATA = 0,
            parameter   bit                                     READMEMB     = 0,
            parameter   bit                                     READMEMH     = 0,
            parameter                                           READMEM_FIlE = "",
            
            localparam  int                                     CKE_BITS     = PIPELINES  > 0 ? PIPELINES  : 1,
            localparam  int                                     USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input       wire    [PORTS-1:0]                                 reset,
            input       wire    [PORTS-1:0]                                 clk,
            input       wire    [PORTS-1:0][CKE_BITS-1:0]                   ckes,
            
            input       wire    [PORTS-1:0][WE_WIDTH-1:0]                   s_we,
            input       wire    [PORTS-1:0][ADDR_WIDTH-1:0]                 s_addr,
            input       wire    [PORTS-1:0][WE_WIDTH-1:0][DATA_WIDTH-1:0]   s_data,
            input       wire    [PORTS-1:0][USER_BITS-1:0]                  s_user,
            input       wire    [PORTS-1:0]                                 s_valid,
            
            output      wire    [PORTS-1:0][WE_WIDTH-1:0][DATA_WIDTH-1:0]   m_data,
            output      wire    [PORTS-1:0][USER_BITS-1:0]                  m_user,
            output      wire    [PORTS-1:0]                                 m_valid
        );
    
    // memory
    (* ram_style = RAM_TYPE *)
    logic   [WE_WIDTH-1:0][DATA_WIDTH-1:0]   mem [0:MEM_SIZE-1];
    
    generate
    for ( genvar i = 0; i < PORTS; ++i ) begin : loop_port
        logic   [PIPELINES:0]   data;
        logic   [PIPELINES:0]   user;
        logic   [PIPELINES:0]   valid;
        
        // write
        always_ff @(posedge clk[i]) begin
            if ( ckes[i][0] ) begin
                for ( int j = 0; j < WE_WIDTH; ++j ) begin
                    if ( s_we[i][j] ) begin
                        mem[s_addr[i]] <= s_data[i];
                    end
                end
            end
        end
        
        // read
        always_comb begin : stage0
            data[0] = mem[s_addr[i]];
            if ( MODE == "WRITE_FIRST" && ckes[i][0] && s_we[i] ) begin
                data[0] = s_data;
            end
            else if ( MODE == "NO_CHANGE" && PIPELINES > 0 ) begin
                data[0] = data[1];
            end
            user[0]  = s_user[i];
            valid[0] = s_valid[i];
        end
        
        // pipelines
        always_ff @(posedge clk[i]) begin
            for ( int j = 0; j < PIPELINES; ++j ) begin
                if ( reset[i] ) begin
                    data[j]  <= INIT_DATA;
                    user[j]  <= INIT_USER[i];
                    valid[j] <= 1'b0;
                end
                else if ( ckes[i][j] ) begin
                    data[j+1]  <= data[j];
                    user[j+1]  <= user[j];
                    valid[j+1] <= valid[j];
                end
            end
        end
        
        assign m_data[i]  = data[PIPELINES];
        assign m_user[i]  = user[PIPELINES];
        assign m_valid[i] = valid[PIPELINES];
    end
    endgenerate
    
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


`default_nettype    wire


// End of file
