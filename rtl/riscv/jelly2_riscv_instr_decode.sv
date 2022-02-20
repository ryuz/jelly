// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_riscv_instr_decode
        #(
            parameter int   PC_WIDTH   = 32,
            parameter int   INST_WIDTH = 32,
            parameter int   DATA_WIDTH = 32
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,

            input   wire    [PC_WIDTH-1:0]          instruction,
            input   wire    [INST_WIDTH-1:0]        s_ibus_instr,
            input   wire                            s_ibus_valid,

            output  wire    [DBUS_ADDR_WIDTH-1:0]   m_dbus_addr,
            output  wire    [DBUS_DATA_WIDTH-1:0]   m_dbus_data,
            output  wire    [DBUS_STRB_WIDTH-1:0]   m_dbus_strb,
            output  wire                            m_dbus_we,
            output  wire                            m_dbus_valid,
            input   wire                            m_dbus_ready,

            input   wire    [PC_WIDTH-1:0]          s_dbus_pc,
            input   wire    [IBUS_WIDTH-1:0]        s_dbus_instr,
            input   wire                            s_dbus_valid,
            output  wire                            s_dbus_ready
        );


    logic   [PC_WIDTH-1:0][DATA_WIDTH-1:0]  st0_pc;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_pc <= '0;
        end
        else if ( cke ) begin
            st0_pc <= st0_pc + PC_WIDTH'4;
        end
    end

    assign m_ibus_pc    = st0_pc;
    assign m_ibus_valid = 1'b1;





endmodule


`default_nettype wire


// End of file
