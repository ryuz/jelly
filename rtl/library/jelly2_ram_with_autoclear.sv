// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// RAM with auto clear
module jelly2_ram_with_autoclear
        #(
            parameter   int                         ADDR_WIDTH      = 12,
            parameter   int                         DATA_WIDTH      = 8,
            parameter   int                         MEM_SIZE        = (1 << ADDR_WIDTH),
            parameter                               RAM_TYPE        = "block",
            parameter   bit                         DOUT_REGS0      = 0,
            parameter   bit                         DOUT_REGS1      = 0,
            parameter                               MODE0           = "WRITE_FIRST",
            parameter                               MODE1           = "WRITE_FIRST",
            parameter   bit                         FILLMEM         = 0,
            parameter   logic   [DATA_WIDTH-1:0]    FILLMEM_DATA    = 0,
            parameter   bit                         READMEMB        = 0,
            parameter   bit                         READMEMH        = 0,
            parameter                               READMEM_FIlE    = "",
            parameter   int                         UNIT_ADDR_WIDTH = ADDR_WIDTH > 9 ? 9 : ADDR_WIDTH
        )
        (
            input   wire    [1:0]                   reset,
            input   wire    [1:0]                   clk,
            input   wire    [1:0]                   en,
            input   wire    [1:0]                   regcke,
            input   wire    [1:0]                   we,
            input   wire    [1:0][ADDR_WIDTH-1:0]   addr,
            input   wire    [1:0][DATA_WIDTH-1:0]   din,
            output  wire    [1:0][DATA_WIDTH-1:0]   dout,
            input   wire    [1:0][DATA_WIDTH-1:0]   clear_din,
            input   wire    [1:0]                   clear_start,
            output  reg     [1:0]                   clear_busy
        );
    
    // RAM
    localparam  UNIT_MEM_SIZE = MEM_SIZE < (1 << UNIT_ADDR_WIDTH) ? MEM_SIZE : (1 << UNIT_ADDR_WIDTH);
    localparam  N             = (MEM_SIZE + UNIT_MEM_SIZE - 1) / UNIT_MEM_SIZE;
    localparam  SEL_WIDTH     = $clog2(N);

    logic    [1:0]                              dout_regs;
    assign dout_regs[0] = DOUT_REGS0;
    assign dout_regs[1] = DOUT_REGS1;

    logic    [1:0]                              unit_en;
    logic    [1:0][N-1:0]                       unit_we;
    logic    [1:0]       [UNIT_ADDR_WIDTH-1:0]  unit_addr;
    logic    [1:0]       [DATA_WIDTH-1:0]       unit_din;
    logic    [1:0][N-1:0][DATA_WIDTH-1:0]       unit_dout;

    generate
    for ( genvar i = 0; i < N; ++i ) begin : loop_ram
        jelly2_ram_dualport
                #(
                    .ADDR_WIDTH     (UNIT_ADDR_WIDTH),
                    .DATA_WIDTH     (DATA_WIDTH),
                    .MEM_SIZE       (UNIT_MEM_SIZE),
                    .RAM_TYPE       (RAM_TYPE),
                    .DOUT_REGS0     (DOUT_REGS0),
                    .DOUT_REGS1     (DOUT_REGS1),
                    .MODE0          (MODE0),
                    .MODE1          (MODE1),
                    .FILLMEM        (FILLMEM),
                    .FILLMEM_DATA   (FILLMEM_DATA),
                    .READMEMB       (READMEMB),
                    .READMEMH       (READMEMH),
                    .READMEM_FIlE   (READMEM_FIlE)
                )
            i_ram_dualport
                (
                    .clk0           (clk[0]),
                    .en0            (unit_en[0]),
                    .regcke0        (regcke[0]),
                    .we0            (unit_we[0][i]),
                    .addr0          (unit_addr[0]),
                    .din0           (unit_din[0]),
                    .dout0          (unit_dout[0][i]),

                    .clk1           (clk[1]),
                    .en1            (unit_en[1]),
                    .regcke1        (regcke[1]),
                    .we1            (unit_we[1][i]),
                    .addr1          (unit_addr[1]),
                    .din1           (unit_din[1]),
                    .dout1          (unit_dout[1][i])
                );
    end
    endgenerate

    // verilator lint_off MULTIDRIVEN
    
    generate
    for ( genvar i = 0; i < 2; ++i ) begin : loop_control
        // clear
        logic  [UNIT_ADDR_WIDTH-1:0]    clear_addr;
        always @(posedge clk[i]) begin
            if ( reset[i] ) begin
                clear_busy[i] <= 1'b0;
                clear_addr    <= 'x;
            end
            else begin
                if ( clear_busy[i] ) begin
                    clear_addr <= clear_addr + 1'b1;
                    if ( clear_addr == UNIT_ADDR_WIDTH'(UNIT_MEM_SIZE - 1) ) begin
                        clear_busy[i] <= 1'b0;
                    end
                end
                else begin
                    clear_busy[i] <= clear_start[i];
                    clear_addr    <= '0;
                end
            end
        end

        assign {st0_sel, unit_addr[i]} = addr[i];
        always_comb begin : blk_port0
            unit_en[i]   = clear_busy[i] ? 1'b1         : en[i];
            unit_din[i]  = clear_busy[i] ? clear_din[i] : din[i];
            unit_addr[i] = clear_busy[i] ? clear_addr   : addr[i][UNIT_ADDR_WIDTH-1:0];
            for ( int j = 0; j < N; ++j ) begin
                unit_we[i][j] = clear_busy[i] ? 1'b1 : (we[i] && (int'(st0_sel) == j));
            end
        end

        wire    [SEL_WIDTH-1:0]     st0_sel = SEL_WIDTH'(addr[i] >> UNIT_ADDR_WIDTH);
        logic   [SEL_WIDTH-1:0]     st1_sel;
        logic   [SEL_WIDTH-1:0]     st2_sel;
        always_ff @(posedge clk[i]) begin
            if ( en[i] ) begin
                st1_sel <= st0_sel;
            end
            if ( regcke[i] ) begin
                st2_sel <= st1_sel;
            end
        end
        wire    [SEL_WIDTH-1:0]     sel = dout_regs[i] ? st2_sel : st1_sel;

        assign dout[i] = unit_dout[i][sel];
    end
    endgenerate
 
    // verilator lint_on MULTIDRIVEN

endmodule


`default_nettype wire


// End of file
