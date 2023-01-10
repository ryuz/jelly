


`timescale 1ns / 1ps
`default_nettype none


module zybo_z7_lan8720
        (
            input   wire            in_clk125,
            input   wire    [3:0]   push_sw,
            input   wire    [3:0]   dip_sw,
            output  wire    [3:0]   led,
            
            input   wire    [7:0]   pmod_a,
            input   wire    [4:1]   pmod_jb_p,
            input   wire    [4:1]   pmod_jb_n,
            input   wire    [1:1]   pmod_jc_p,

            inout   wire    [14:0]  DDR_addr,
            inout   wire    [2:0]   DDR_ba,
            inout   wire            DDR_cas_n,
            inout   wire            DDR_ck_n,
            inout   wire            DDR_ck_p,
            inout   wire            DDR_cke,
            inout   wire            DDR_cs_n,
            inout   wire    [3:0]   DDR_dm,
            inout   wire    [31:0]  DDR_dq,
            inout   wire    [3:0]   DDR_dqs_n,
            inout   wire    [3:0]   DDR_dqs_p,
            inout   wire            DDR_odt,
            inout   wire            DDR_ras_n,
            inout   wire            DDR_reset_n,
            inout   wire            DDR_we_n,
            inout   wire            FIXED_IO_ddr_vrn,
            inout   wire            FIXED_IO_ddr_vrp,
            inout   wire    [53:0]  FIXED_IO_mio,
            inout   wire            FIXED_IO_ps_clk,
            inout   wire            FIXED_IO_ps_porb,
            inout   wire            FIXED_IO_ps_srstb
        );

    logic           lan_clk;
    logic   [1:0]   lan_txd;
    logic           lan_txen;
    logic   [1:0]   lan_rxd;
    logic           lan_crs;
    logic           lan_mdc;
    logic           lan_mdio;
    
    always_comb lan_txd[0] = pmod_jb_p[1];
    always_comb lan_rxd[1] = pmod_jb_n[1];
    always_comb lan_crs    = pmod_jb_p[2];
    always_comb lan_mdc    = pmod_jb_n[2];
    always_comb lan_txen   = pmod_jb_p[3];
    always_comb lan_rxd[0] = pmod_jb_n[3];
    always_comb lan_clk    = pmod_jb_p[4];
    always_comb lan_mdio   = pmod_jb_n[4];
    always_comb lan_txd[1] = pmod_jc_p[1];

    (* mark_debug="true" *) logic   [1:0]   dbg_lan_txd;
    (* mark_debug="true" *) logic           dbg_lan_txen;
    (* mark_debug="true" *) logic   [1:0]   dbg_lan_rxd;
    (* mark_debug="true" *) logic           dbg_lan_crs;
    (* mark_debug="true" *) logic           dbg_lan_mdc;
    (* mark_debug="true" *) logic           dbg_lan_mdio;

    always_ff @(posedge lan_clk) begin
        dbg_lan_txd  <= lan_txd ;
        dbg_lan_txen <= lan_txen;
        dbg_lan_rxd  <= lan_rxd ;
        dbg_lan_crs  <= lan_crs ;
        dbg_lan_mdc  <= lan_mdc ;
        dbg_lan_mdio <= lan_mdio;
    end

    (* mark_debug="true" *) logic           mon_lan_clk;
    (* mark_debug="true" *) logic   [1:0]   mon_lan_txd;
    (* mark_debug="true" *) logic           mon_lan_txen;
    (* mark_debug="true" *) logic   [1:0]   mon_lan_rxd;
    (* mark_debug="true" *) logic           mon_lan_crs;
    (* mark_debug="true" *) logic           mon_lan_mdc;
    (* mark_debug="true" *) logic           mon_lan_mdio;
    always_ff @(posedge in_clk125) begin
        mon_lan_clk  <= lan_clk;
        mon_lan_txd  <= lan_txd ;
        mon_lan_txen <= lan_txen;
        mon_lan_rxd  <= lan_rxd ;
        mon_lan_crs  <= lan_crs ;
        mon_lan_mdc  <= lan_mdc ;
        mon_lan_mdio <= lan_mdio;
    end

    design_1
        i_design_1
            (
                .DDR_addr               (DDR_addr),
                .DDR_ba                 (DDR_ba),
                .DDR_cas_n              (DDR_cas_n),
                .DDR_ck_n               (DDR_ck_n),
                .DDR_ck_p               (DDR_ck_p),
                .DDR_cke                (DDR_cke),
                .DDR_cs_n               (DDR_cs_n),
                .DDR_dm                 (DDR_dm),
                .DDR_dq                 (DDR_dq),
                .DDR_dqs_n              (DDR_dqs_n),
                .DDR_dqs_p              (DDR_dqs_p),
                .DDR_odt                (DDR_odt),
                .DDR_ras_n              (DDR_ras_n),
                .DDR_reset_n            (DDR_reset_n),
                .DDR_we_n               (DDR_we_n),
                
                .FIXED_IO_ddr_vrn       (FIXED_IO_ddr_vrn),
                .FIXED_IO_ddr_vrp       (FIXED_IO_ddr_vrp),
                .FIXED_IO_mio           (FIXED_IO_mio),
                .FIXED_IO_ps_clk        (FIXED_IO_ps_clk),
                .FIXED_IO_ps_porb       (FIXED_IO_ps_porb),
                .FIXED_IO_ps_srstb      (FIXED_IO_ps_srstb)
            );

    logic   [25:0]      clk_count;
    logic   [25:0]      lan_count;
    always_ff @(posedge in_clk125)  clk_count <= clk_count + 1;
    always_ff @(posedge lan_clk)    lan_count <= lan_count + 1;

    assign led[1:0] = clk_count[25:24];
    assign led[3:2] = lan_count[25:24];

endmodule


`default_nettype wire

