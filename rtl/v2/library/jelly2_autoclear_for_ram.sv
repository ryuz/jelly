// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// auto clear for RAM
module jelly2_autoclear_for_ram
        #(
            parameter   int     BANK_NUM        = 4,
            parameter   int     BANK_WIDTH      = $clog2(BANK_NUM),
            parameter   int     ADDR_WIDTH      = 9,
            parameter   int     DATA_WIDTH      = 8,
            parameter   int     MEM_SIZE        = (1 << ADDR_WIDTH),
            parameter   bit     DOUT_REGS       = 0
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,

            input   wire    [DATA_WIDTH-1:0]                    clear_din,
            input   wire                                        clear_start,
            output  reg                                         clear_busy,

            input   wire                                        en,
            input   wire                                        regcke,
            input   wire                                        we,
            input   wire    [BANK_WIDTH+ADDR_WIDTH-1:0]         addr,
            input   wire    [DATA_WIDTH-1:0]                    din,
            output  wire    [DATA_WIDTH-1:0]                    dout,

            output  reg     [BANK_NUM-1:0]                      ram_en,
            output  reg     [BANK_NUM-1:0]                      ram_regcke,
            output  reg     [BANK_NUM-1:0]                      ram_we,
            output  reg     [BANK_NUM-1:0][ADDR_WIDTH-1:0]      ram_addr,
            output  reg     [BANK_NUM-1:0][DATA_WIDTH-1:0]      ram_din,
            input   wire    [BANK_NUM-1:0][DATA_WIDTH-1:0]      ram_dout
        );
    
    localparam  BANK_BITS = BANK_WIDTH > 0 ? BANK_WIDTH : 1;

    // clear
    logic  [ADDR_WIDTH-1:0]     clear_addr;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            clear_busy <= 1'b0;
            clear_addr <= 'x;
        end
        else begin
            if ( clear_busy ) begin
                clear_addr <= clear_addr + 1'b1;
                if ( clear_addr == ADDR_WIDTH'(MEM_SIZE - 1) ) begin
                    clear_busy <= 1'b0;
                end
            end
            else begin
                clear_busy <= clear_start;
                clear_addr <= '0;
            end
        end
    end
    
    wire    [BANK_BITS-1:0]     st0_bank = BANK_BITS'(addr >> ADDR_WIDTH);
    always_comb begin : blk_ram
        for ( int i = 0; i < BANK_NUM; ++i ) begin
            ram_en    [i] = clear_busy ? 1'b1       : en;
            ram_regcke[i] = regcke;
            ram_we    [i] = clear_busy ? 1'b1       : (we && (int'(st0_bank) == i));
            ram_addr  [i] = clear_busy ? clear_addr : addr[ADDR_WIDTH-1:0];
            ram_din   [i] = clear_busy ? clear_din  : din;
        end
    end
    
    logic   [BANK_BITS-1:0]     bank;
    
    logic   [BANK_BITS-1:0]     st1_bank;
    always_ff @(posedge clk) begin
        if ( en ) begin
            st1_bank <= st0_bank;
        end
    end
    
    generate
    if ( DOUT_REGS ) begin : blk_regs
        logic   [BANK_BITS-1:0]     st2_bank;
        always_ff @(posedge clk) begin
            if ( regcke ) begin
                st2_bank <= st1_bank;
            end
        end
        assign bank = st2_bank;
    end
    else begin : blk_dout
        assign bank = st1_bank;
    end
    endgenerate
    
    
    assign dout = ram_dout[bank];
    
    
endmodule


`default_nettype wire


// End of file
