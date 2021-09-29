

`timescale          1ns / 1ps
`default_nettype    none

module tb_verilator(
            input   wire    reset0,
            input   wire    clk0,
            input   wire    reset1,
            input   wire    clk1
        );

    parameter   int                         ADDR_WIDTH      = 10;
    parameter   int                         DATA_WIDTH      = 16;
    parameter   int                         MEM_SIZE        = (1 << ADDR_WIDTH);
    parameter                               RAM_TYPE        = "block";
    parameter   int                         DOUT_REGS0      = 0;
    parameter   int                         DOUT_REGS1      = 0;
    parameter                               MODE0           = "READ_FIRST";
    parameter                               MODE1           = "READ_FIRST";
    parameter   bit                         FILLMEM         = 0;
    parameter   logic   [DATA_WIDTH-1:0]    FILLMEM_DATA    = 0;
    parameter   bit                         READMEMB        = 0;
    parameter   bit                         READMEMH        = 0;
    parameter                               READMEM_FIlE    = "";
    parameter   int                         RAM_ADDR_WIDTH  = 8;

    logic   [1:0]                   reset;
    logic   [1:0]                   clk;
    logic   [1:0]                   en;
    logic   [1:0]                   regcke;
    logic   [1:0]                   we;
    logic   [1:0][ADDR_WIDTH-1:0]   addr;
    logic   [1:0][DATA_WIDTH-1:0]   din;
    logic   [1:0][DATA_WIDTH-1:0]   dout;
    logic   [1:0][DATA_WIDTH-1:0]   clear_din;
    logic   [1:0]                   clear_start;
    logic   [1:0]                   clear_busy;

    jelly2_ram_with_autoclear
            #(
                .ADDR_WIDTH         (ADDR_WIDTH     ),
                .DATA_WIDTH         (DATA_WIDTH     ),
                .MEM_SIZE           (MEM_SIZE       ),
                .RAM_TYPE           (RAM_TYPE       ),
                .DOUT_REGS0         (DOUT_REGS0     ),
                .DOUT_REGS1         (DOUT_REGS1     ),
                .MODE0              (MODE0          ),
                .MODE1              (MODE1          ),
                .FILLMEM            (FILLMEM        ),
                .FILLMEM_DATA       (FILLMEM_DATA   ),
                .READMEMB           (READMEMB       ),
                .READMEMH           (READMEMH       ),
                .READMEM_FIlE       (READMEM_FIlE   ),
                .RAM_ADDR_WIDTH     (RAM_ADDR_WIDTH )
            )
        i_ram_with_autoclear
            (
                .*
            );

    logic                       we0;
    logic   [ADDR_WIDTH-1:0]    addr0;
    logic   [DATA_WIDTH-1:0]    data0;
    always_ff @(posedge clk0) begin
        if ( reset0 ) begin
            we0   <= 1'b1;
            addr0 <= 0;
            data0 <= 0;
        end
        else begin
            addr0 <= addr0 + 1'b1;
            data0 <= DATA_WIDTH'(addr0); // data0 + 1'b1;

            if ( clear_busy[0] ) begin
                we0 <= 1'b0;
            end
        end
    end

    logic   [ADDR_WIDTH-1:0]    addr1;
    always_ff @(posedge clk1) begin
        if ( reset1 ) begin
            addr1 <= 0;
        end
        else begin
            addr1 <= addr1 + 1'b1;
        end
    end

    assign reset      [0] = reset0;
    assign clk        [0] = clk0;
    assign en         [0] = 1'b1;
    assign regcke     [0] = 1'b1;
    assign we         [0] = we0;
    assign addr       [0] = addr0;
    assign din        [0] = data0;
    assign clear_din  [0] = '0;
    assign clear_start[0] = '0;//(addr1 == '1);

    assign reset      [1] = reset1;
    assign clk        [1] = clk1;
    assign en         [1] = '1;
    assign regcke     [1] = '1;
    assign we         [1] = '0;
    assign addr       [1] = addr1;
    assign din        [1] = '0;
    assign clear_din  [1] = '0;
    assign clear_start[1] = '0;

endmodule


`default_nettype    wire


// end of file
