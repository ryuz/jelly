
`timescale 1ns / 1ps
`default_nettype none

module jfive_tcm
        #(
            parameter   int                                 ADDR_WIDTH   = 14,
            parameter   int                                 DATA_WIDTH   = 32,
            parameter   int                                 WE_WIDTH     = 4,
            parameter   int                                 WORD_WIDTH   = DATA_WIDTH/WE_WIDTH,
            parameter   int                                 MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                                       READMEM_FIlE = "./mem.hex"
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
//  (* ram_style = RAM_TYPE *)
    logic   [WE_WIDTH*WORD_WIDTH-1:0]   mem [0:MEM_SIZE-1];

    // port0
    for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_we0
        always_ff @ ( posedge port0_clk ) begin
            if ( port0_en ) begin
                if ( port0_we[i] ) begin
                    mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port0_din[i*WORD_WIDTH +: WORD_WIDTH] ;
                end
                else begin
                    port0_dout[i*WORD_WIDTH +: WORD_WIDTH]  <= mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH];
                end
            end
        end
    end

    // port1
    for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_we1
        always_ff @ ( posedge port1_clk ) begin
            if ( port1_en ) begin
                if ( port1_we[i] ) begin
                    mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port1_din[i*WORD_WIDTH +: WORD_WIDTH];
                end
                else begin
                    port1_dout[i*WORD_WIDTH +: WORD_WIDTH] <= mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH];
                end
            end
        end
    end
    
    // verilator lint_on MULTIDRIVEN
    
    
    // initialize
    initial begin
        $readmemh(READMEM_FIlE, mem);
    end
    
endmodule

`default_nettype wire

// End of file
