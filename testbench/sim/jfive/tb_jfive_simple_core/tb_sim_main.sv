
`timescale 1ns / 1ps
`default_nettype none


module tb_sim_main
        (
            input   wire                        reset,
            input   wire                        clk
        );
    

    localparam int                  IBUS_ADDR_WIDTH = 16;
    localparam int                  DBUS_ADDR_WIDTH = 32;
    localparam int                  PC_WIDTH        = IBUS_ADDR_WIDTH;
    localparam bit  [PC_WIDTH-1:0]  RESET_PC_ADDR   = '0;

    logic                           cke = 1'b1;

    logic   [IBUS_ADDR_WIDTH-1:0]   ibus_addr;
    logic   [31:0]                  ibus_rdata;

    logic   [DBUS_ADDR_WIDTH-1:0]   dbus_addr;
    logic                           dbus_rd;
    logic                           dbus_wr;
    logic   [3:0]                   dbus_sel;
    logic   [31:0]                  dbus_wdata;
    logic   [31:0]                  dbus_rdata;

    jelly2_jfive_simple_core
            #(
                .IBUS_ADDR_WIDTH    (IBUS_ADDR_WIDTH),
                .DBUS_ADDR_WIDTH    (DBUS_ADDR_WIDTH),
                .PC_WIDTH           (PC_WIDTH),
                .RESET_PC_ADDR      (RESET_PC_ADDR)
            )
        i_jfive_simple_core
            (
                .reset,
                .clk,
                .cke,

                .ibus_addr,
                .ibus_rdata,

                .dbus_addr,
                .dbus_rd,
                .dbus_wr,
                .dbus_sel,
                .dbus_wdata,
                .dbus_rdata
            );

    localparam MEM_ADDR_WIDTH = 14;

    logic   [MEM_ADDR_WIDTH-1:0]    mem_addr;
    logic                           mem_en;
    logic   [3:0]                   mem_we;
    logic   [31:0]                  mem_wdata;
    logic   [31:0]                  mem_rdata;

    assign mem_addr  = MEM_ADDR_WIDTH'(dbus_addr >> 2);
    assign mem_we    = dbus_wr ? 4'(dbus_sel << dbus_addr[1:0]) : 4'd0;
    assign mem_wdata = 32'(mem_wdata << (dbus_addr[1:0] * 8));

    jelly2_ram_dualport
            #(
                .ADDR_WIDTH     (MEM_ADDR_WIDTH),
                .DATA_WIDTH     (32),
                .WE_WIDTH       (4),
                .WORD_WIDTH     (8),
                .RAM_TYPE       ("block"),
                .DOUT_REGS0     (0),
                .DOUT_REGS1     (0),
                .MODE0          ("WRITE_FIRST"),
                .MODE1          ("WRITE_FIRST"),

                .FILLMEM        (0),
                .FILLMEM_DATA   (0),
                .READMEMB       (0),
                .READMEMH       (1),
                .READMEM_FIlE   ("../mem.hex")
            )
        i_ram_dualport
            (
                .port0_clk      (clk),
                .port0_en       (cke),
                .port0_regcke   (cke),
                .port0_we       (4'd0),
                .port0_addr     (ibus_addr[15:2]),
                .port0_din      (32'd0),
                .port0_dout     (ibus_rdata),

                .port1_clk      (clk),
                .port1_en       (cke),
                .port1_regcke   (cke),
                .port1_we       (mem_we),
                .port1_addr     (mem_addr),
                .port1_din      (mem_wdata),
                .port1_dout     (mem_rdata)
            );
    
    logic   [1:0]   mem_shift;
    always_ff @(posedge clk) begin
        mem_shift <= dbus_addr[1:0];
    end
    assign dbus_rdata = 32'(mem_rdata >> (mem_shift * 8));


    // IO
    wire mmio_valid = dbus_wr && (dbus_addr[31:24] == 8'hf0);

    always_ff @(posedge clk) begin
        if ( !reset && mmio_valid ) begin
            $display("write: %h %10d %b", dbus_addr, $signed(dbus_wdata), dbus_sel);
        end
    end

endmodule


`default_nettype wire


// end of file
