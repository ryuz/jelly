
`timescale 1ns / 1ps
`default_nettype none


module tb_sim_main
        (
            input   wire                        reset,
            input   wire                        clk
        );
    

    localparam int                   IBUS_ADDR_WIDTH = 14;
    localparam int                   DBUS_ADDR_WIDTH = 14;
    localparam int                   PC_WIDTH        = IBUS_ADDR_WIDTH;
    localparam bit   [PC_WIDTH-1:0]  RESET_PC_ADDR   = '0;

    logic                          cke = 1'b1;

    logic  [IBUS_ADDR_WIDTH-1:0]   ibus_addr;
    logic  [31:0]                  ibus_rdata;

    logic  [DBUS_ADDR_WIDTH-1:0]   dbus_addr;
    logic                          dbus_rd;
    logic  [3:0]                   dbus_we;
    logic  [31:0]                  dbus_wdata;
    logic  [31:0]                  dbus_rdata;

    jelly2_riscv_simple_core
            #(
                .IBUS_ADDR_WIDTH    (IBUS_ADDR_WIDTH),
                .DBUS_ADDR_WIDTH    (DBUS_ADDR_WIDTH),
                .PC_WIDTH           (PC_WIDTH),
                .RESET_PC_ADDR      (RESET_PC_ADDR)
            )
        i_riscv_simple_core
            (
                .reset,
                .clk,
                .cke,

                .ibus_addr,
                .ibus_rdata,

                .dbus_addr,
                .dbus_rd,
                .dbus_we,
                .dbus_wdata,
                .dbus_rdata
            );


    jelly2_ram_dualport
            #(
                .ADDR_WIDTH     (14),
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
                .port0_addr     (ibus_addr),
                .port0_din      (32'd0),
                .port0_dout     (ibus_rdata),

                .port1_clk      (clk),
                .port1_en       (cke),
                .port1_regcke   (cke),
                .port1_we       (dbus_we),
                .port1_addr     (dbus_addr),
                .port1_din      (dbus_wdata),
                .port1_dout     (dbus_rdata)
            );
    
endmodule


`default_nettype wire


// end of file
