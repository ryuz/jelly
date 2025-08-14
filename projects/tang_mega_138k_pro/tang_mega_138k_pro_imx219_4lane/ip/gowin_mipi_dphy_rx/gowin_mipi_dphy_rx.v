//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11.03 (64-bit)
//Part Number: GW5AST-LV138FPG676AES
//Device: GW5AST-138
//Device Version: B
//Created Time: Sat Aug  9 19:29:06 2025

module Gowin_MIPI_DPHY_RX (d0ln_hsrxd, d1ln_hsrxd, d2ln_hsrxd, d3ln_hsrxd, d0ln_hsrxd_vld, d1ln_hsrxd_vld, d2ln_hsrxd_vld, d3ln_hsrxd_vld, di_lprx0_n, di_lprx0_p, di_lprx1_n, di_lprx1_p, di_lprx2_n, di_lprx2_p, di_lprx3_n, di_lprx3_p, di_lprxck_n, di_lprxck_p, rx_clk_o, deskew_error, d0ln_deskew_done, d1ln_deskew_done, d2ln_deskew_done, d3ln_deskew_done, ck_n, ck_p, rx0_n, rx0_p, rx1_n, rx1_p, rx2_n, rx2_p, rx3_n, rx3_p, lprx_en_ck, lprx_en_d0, lprx_en_d1, lprx_en_d2, lprx_en_d3, hsrx_odten_ck, hsrx_odten_d0, hsrx_odten_d1, hsrx_odten_d2, hsrx_odten_d3, d0ln_hsrx_dren, d1ln_hsrx_dren, d2ln_hsrx_dren, d3ln_hsrx_dren, hsrx_en_ck, hs_8bit_mode, rx_clk_1x, rx_invert, lalign_en, walign_by, do_lptx0_n, do_lptx0_p, do_lptx1_n, do_lptx1_p, do_lptx2_n, do_lptx2_p, do_lptx3_n, do_lptx3_p, do_lptxck_n, do_lptxck_p, lptx_en_ck, lptx_en_d0, lptx_en_d1, lptx_en_d2, lptx_en_d3, byte_lendian, hsrx_stop, pwron, reset, deskew_lnsel, deskew_mth, deskew_owval, deskew_req, drst_n, one_byte0_match, word_lendian, fifo_rd_std, deskew_by, deskew_en_oedge, deskew_half_opening, deskew_lsb_mode, deskew_m, deskew_mset, deskew_oclkedg_en, eqcs_lane0, eqcs_lane1, eqcs_lane2, eqcs_lane3, eqcs_ck, eqrs_lane0, eqrs_lane1, eqrs_lane2, eqrs_lane3, eqrs_ck, hsrx_dlydir_lane0, hsrx_dlydir_lane1, hsrx_dlydir_lane2, hsrx_dlydir_lane3, hsrx_dlydir_ck, hsrx_dlyldn_lane0, hsrx_dlyldn_lane1, hsrx_dlyldn_lane2, hsrx_dlyldn_lane3, hsrx_dlyldn_ck, hsrx_dlymv_lane0, hsrx_dlymv_lane1, hsrx_dlymv_lane2, hsrx_dlymv_lane3, hsrx_dlymv_ck, walign_dvld);

output [15:0] d0ln_hsrxd;
output [15:0] d1ln_hsrxd;
output [15:0] d2ln_hsrxd;
output [15:0] d3ln_hsrxd;
output d0ln_hsrxd_vld;
output d1ln_hsrxd_vld;
output d2ln_hsrxd_vld;
output d3ln_hsrxd_vld;
output di_lprx0_n;
output di_lprx0_p;
output di_lprx1_n;
output di_lprx1_p;
output di_lprx2_n;
output di_lprx2_p;
output di_lprx3_n;
output di_lprx3_p;
output di_lprxck_n;
output di_lprxck_p;
output rx_clk_o;
output deskew_error;
output d0ln_deskew_done;
output d1ln_deskew_done;
output d2ln_deskew_done;
output d3ln_deskew_done;
inout ck_n;
inout ck_p;
inout rx0_n;
inout rx0_p;
inout rx1_n;
inout rx1_p;
inout rx2_n;
inout rx2_p;
inout rx3_n;
inout rx3_p;
input lprx_en_ck;
input lprx_en_d0;
input lprx_en_d1;
input lprx_en_d2;
input lprx_en_d3;
input hsrx_odten_ck;
input hsrx_odten_d0;
input hsrx_odten_d1;
input hsrx_odten_d2;
input hsrx_odten_d3;
input d0ln_hsrx_dren;
input d1ln_hsrx_dren;
input d2ln_hsrx_dren;
input d3ln_hsrx_dren;
input hsrx_en_ck;
input hs_8bit_mode;
input rx_clk_1x;
input rx_invert;
input lalign_en;
input walign_by;
input do_lptx0_n;
input do_lptx0_p;
input do_lptx1_n;
input do_lptx1_p;
input do_lptx2_n;
input do_lptx2_p;
input do_lptx3_n;
input do_lptx3_p;
input do_lptxck_n;
input do_lptxck_p;
input lptx_en_ck;
input lptx_en_d0;
input lptx_en_d1;
input lptx_en_d2;
input lptx_en_d3;
input byte_lendian;
input hsrx_stop;
input pwron;
input reset;
input [2:0] deskew_lnsel;
input [12:0] deskew_mth;
input [6:0] deskew_owval;
input deskew_req;
input drst_n;
input one_byte0_match;
input word_lendian;
input [2:0] fifo_rd_std;
input deskew_by;
input deskew_en_oedge;
input [5:0] deskew_half_opening;
input [1:0] deskew_lsb_mode;
input [2:0] deskew_m;
input [6:0] deskew_mset;
input deskew_oclkedg_en;
input [2:0] eqcs_lane0;
input [2:0] eqcs_lane1;
input [2:0] eqcs_lane2;
input [2:0] eqcs_lane3;
input [2:0] eqcs_ck;
input [2:0] eqrs_lane0;
input [2:0] eqrs_lane1;
input [2:0] eqrs_lane2;
input [2:0] eqrs_lane3;
input [2:0] eqrs_ck;
input hsrx_dlydir_lane0;
input hsrx_dlydir_lane1;
input hsrx_dlydir_lane2;
input hsrx_dlydir_lane3;
input hsrx_dlydir_ck;
input hsrx_dlyldn_lane0;
input hsrx_dlyldn_lane1;
input hsrx_dlyldn_lane2;
input hsrx_dlyldn_lane3;
input hsrx_dlyldn_ck;
input hsrx_dlymv_lane0;
input hsrx_dlymv_lane1;
input hsrx_dlymv_lane2;
input hsrx_dlymv_lane3;
input hsrx_dlymv_ck;
input walign_dvld;

MIPI_DPHY_RX mipi_dphy_rx_inst (
    .D0LN_HSRXD(d0ln_hsrxd),
    .D1LN_HSRXD(d1ln_hsrxd),
    .D2LN_HSRXD(d2ln_hsrxd),
    .D3LN_HSRXD(d3ln_hsrxd),
    .D0LN_HSRXD_VLD(d0ln_hsrxd_vld),
    .D1LN_HSRXD_VLD(d1ln_hsrxd_vld),
    .D2LN_HSRXD_VLD(d2ln_hsrxd_vld),
    .D3LN_HSRXD_VLD(d3ln_hsrxd_vld),
    .DI_LPRX0_N(di_lprx0_n),
    .DI_LPRX0_P(di_lprx0_p),
    .DI_LPRX1_N(di_lprx1_n),
    .DI_LPRX1_P(di_lprx1_p),
    .DI_LPRX2_N(di_lprx2_n),
    .DI_LPRX2_P(di_lprx2_p),
    .DI_LPRX3_N(di_lprx3_n),
    .DI_LPRX3_P(di_lprx3_p),
    .DI_LPRXCK_N(di_lprxck_n),
    .DI_LPRXCK_P(di_lprxck_p),
    .RX_CLK_O(rx_clk_o),
    .DESKEW_ERROR(deskew_error),
    .D0LN_DESKEW_DONE(d0ln_deskew_done),
    .D1LN_DESKEW_DONE(d1ln_deskew_done),
    .D2LN_DESKEW_DONE(d2ln_deskew_done),
    .D3LN_DESKEW_DONE(d3ln_deskew_done),
    .CK_N(ck_n),
    .CK_P(ck_p),
    .RX0_N(rx0_n),
    .RX0_P(rx0_p),
    .RX1_N(rx1_n),
    .RX1_P(rx1_p),
    .RX2_N(rx2_n),
    .RX2_P(rx2_p),
    .RX3_N(rx3_n),
    .RX3_P(rx3_p),
    .LPRX_EN_CK(lprx_en_ck),
    .LPRX_EN_D0(lprx_en_d0),
    .LPRX_EN_D1(lprx_en_d1),
    .LPRX_EN_D2(lprx_en_d2),
    .LPRX_EN_D3(lprx_en_d3),
    .HSRX_ODTEN_CK(hsrx_odten_ck),
    .HSRX_ODTEN_D0(hsrx_odten_d0),
    .HSRX_ODTEN_D1(hsrx_odten_d1),
    .HSRX_ODTEN_D2(hsrx_odten_d2),
    .HSRX_ODTEN_D3(hsrx_odten_d3),
    .D0LN_HSRX_DREN(d0ln_hsrx_dren),
    .D1LN_HSRX_DREN(d1ln_hsrx_dren),
    .D2LN_HSRX_DREN(d2ln_hsrx_dren),
    .D3LN_HSRX_DREN(d3ln_hsrx_dren),
    .HSRX_EN_CK(hsrx_en_ck),
    .HS_8BIT_MODE(hs_8bit_mode),
    .RX_CLK_1X(rx_clk_1x),
    .RX_INVERT(rx_invert),
    .LALIGN_EN(lalign_en),
    .WALIGN_BY(walign_by),
    .DO_LPTX0_N(do_lptx0_n),
    .DO_LPTX0_P(do_lptx0_p),
    .DO_LPTX1_N(do_lptx1_n),
    .DO_LPTX1_P(do_lptx1_p),
    .DO_LPTX2_N(do_lptx2_n),
    .DO_LPTX2_P(do_lptx2_p),
    .DO_LPTX3_N(do_lptx3_n),
    .DO_LPTX3_P(do_lptx3_p),
    .DO_LPTXCK_N(do_lptxck_n),
    .DO_LPTXCK_P(do_lptxck_p),
    .LPTX_EN_CK(lptx_en_ck),
    .LPTX_EN_D0(lptx_en_d0),
    .LPTX_EN_D1(lptx_en_d1),
    .LPTX_EN_D2(lptx_en_d2),
    .LPTX_EN_D3(lptx_en_d3),
    .BYTE_LENDIAN(byte_lendian),
    .HSRX_STOP(hsrx_stop),
    .PWRON(pwron),
    .RESET(reset),
    .DESKEW_LNSEL(deskew_lnsel),
    .DESKEW_MTH(deskew_mth),
    .DESKEW_OWVAL(deskew_owval),
    .DESKEW_REQ(deskew_req),
    .DRST_N(drst_n),
    .ONE_BYTE0_MATCH(one_byte0_match),
    .WORD_LENDIAN(word_lendian),
    .FIFO_RD_STD(fifo_rd_std),
    .DESKEW_BY(deskew_by),
    .DESKEW_EN_OEDGE(deskew_en_oedge),
    .DESKEW_HALF_OPENING(deskew_half_opening),
    .DESKEW_LSB_MODE(deskew_lsb_mode),
    .DESKEW_M(deskew_m),
    .DESKEW_MSET(deskew_mset),
    .DESKEW_OCLKEDG_EN(deskew_oclkedg_en),
    .EQCS_LANE0(eqcs_lane0),
    .EQCS_LANE1(eqcs_lane1),
    .EQCS_LANE2(eqcs_lane2),
    .EQCS_LANE3(eqcs_lane3),
    .EQCS_CK(eqcs_ck),
    .EQRS_LANE0(eqrs_lane0),
    .EQRS_LANE1(eqrs_lane1),
    .EQRS_LANE2(eqrs_lane2),
    .EQRS_LANE3(eqrs_lane3),
    .EQRS_CK(eqrs_ck),
    .HSRX_DLYDIR_LANE0(hsrx_dlydir_lane0),
    .HSRX_DLYDIR_LANE1(hsrx_dlydir_lane1),
    .HSRX_DLYDIR_LANE2(hsrx_dlydir_lane2),
    .HSRX_DLYDIR_LANE3(hsrx_dlydir_lane3),
    .HSRX_DLYDIR_CK(hsrx_dlydir_ck),
    .HSRX_DLYLDN_LANE0(hsrx_dlyldn_lane0),
    .HSRX_DLYLDN_LANE1(hsrx_dlyldn_lane1),
    .HSRX_DLYLDN_LANE2(hsrx_dlyldn_lane2),
    .HSRX_DLYLDN_LANE3(hsrx_dlyldn_lane3),
    .HSRX_DLYLDN_CK(hsrx_dlyldn_ck),
    .HSRX_DLYMV_LANE0(hsrx_dlymv_lane0),
    .HSRX_DLYMV_LANE1(hsrx_dlymv_lane1),
    .HSRX_DLYMV_LANE2(hsrx_dlymv_lane2),
    .HSRX_DLYMV_LANE3(hsrx_dlymv_lane3),
    .HSRX_DLYMV_CK(hsrx_dlymv_ck),
    .WALIGN_DVLD(walign_dvld)
);

defparam mipi_dphy_rx_inst.ALIGN_BYTE = 8'b10111000;
defparam mipi_dphy_rx_inst.MIPI_LANE0_EN = 1'b1;
defparam mipi_dphy_rx_inst.MIPI_LANE1_EN = 1'b1;
defparam mipi_dphy_rx_inst.MIPI_LANE2_EN = 1'b1;
defparam mipi_dphy_rx_inst.MIPI_LANE3_EN = 1'b1;
defparam mipi_dphy_rx_inst.MIPI_CK_EN = 1'b1;
defparam mipi_dphy_rx_inst.SYNC_CLK_SEL = 1'b1;
defparam mipi_dphy_rx_inst.EN_CLKB1X = 1'b1;
defparam mipi_dphy_rx_inst.EQ_ADPSEL_LANE0 = 1'b0;
defparam mipi_dphy_rx_inst.EQ_ADPSEL_LANE1 = 1'b0;
defparam mipi_dphy_rx_inst.EQ_ADPSEL_LANE2 = 1'b0;
defparam mipi_dphy_rx_inst.EQ_ADPSEL_LANE3 = 1'b0;
defparam mipi_dphy_rx_inst.EQ_ADPSEL_CK = 1'b0;
defparam mipi_dphy_rx_inst.EQ_CS_LANE0 = 3'b100;
defparam mipi_dphy_rx_inst.EQ_CS_LANE1 = 3'b100;
defparam mipi_dphy_rx_inst.EQ_CS_LANE2 = 3'b100;
defparam mipi_dphy_rx_inst.EQ_CS_LANE3 = 3'b100;
defparam mipi_dphy_rx_inst.EQ_CS_CK = 3'b100;
defparam mipi_dphy_rx_inst.EQ_PBIAS_LANE0 = 4'b0100;
defparam mipi_dphy_rx_inst.EQ_PBIAS_LANE1 = 4'b0100;
defparam mipi_dphy_rx_inst.EQ_PBIAS_LANE2 = 4'b0100;
defparam mipi_dphy_rx_inst.EQ_PBIAS_LANE3 = 4'b0100;
defparam mipi_dphy_rx_inst.EQ_PBIAS_CK = 4'b0100;
defparam mipi_dphy_rx_inst.EQ_RS_LANE0 = 3'b100;
defparam mipi_dphy_rx_inst.EQ_RS_LANE1 = 3'b100;
defparam mipi_dphy_rx_inst.EQ_RS_LANE2 = 3'b100;
defparam mipi_dphy_rx_inst.EQ_RS_LANE3 = 3'b100;
defparam mipi_dphy_rx_inst.EQ_RS_CK = 3'b100;
defparam mipi_dphy_rx_inst.EQ_ZLD_LANE0 = 4'b1000;
defparam mipi_dphy_rx_inst.EQ_ZLD_LANE1 = 4'b1000;
defparam mipi_dphy_rx_inst.EQ_ZLD_LANE2 = 4'b1000;
defparam mipi_dphy_rx_inst.EQ_ZLD_LANE3 = 4'b1000;
defparam mipi_dphy_rx_inst.EQ_ZLD_CK = 4'b1000;
defparam mipi_dphy_rx_inst.HIGH_BW_LANE0 = 1'b1;
defparam mipi_dphy_rx_inst.HIGH_BW_LANE1 = 1'b1;
defparam mipi_dphy_rx_inst.HIGH_BW_LANE2 = 1'b1;
defparam mipi_dphy_rx_inst.HIGH_BW_LANE3 = 1'b1;
defparam mipi_dphy_rx_inst.HIGH_BW_CK = 1'b1;
defparam mipi_dphy_rx_inst.HSRX_DLYCTL_CK = 7'b0000000;
defparam mipi_dphy_rx_inst.HSRX_DLYCTL_LANE0 = 7'b0000000;
defparam mipi_dphy_rx_inst.HSRX_DLYCTL_LANE1 = 7'b0000000;
defparam mipi_dphy_rx_inst.HSRX_DLYCTL_LANE2 = 7'b0000000;
defparam mipi_dphy_rx_inst.HSRX_DLYCTL_LANE3 = 7'b0000000;
defparam mipi_dphy_rx_inst.HSRX_DLY_SEL = 1'b0;
defparam mipi_dphy_rx_inst.HSRX_DUTY_LANE0 = 4'b1000;
defparam mipi_dphy_rx_inst.HSRX_DUTY_LANE1 = 4'b1000;
defparam mipi_dphy_rx_inst.HSRX_DUTY_LANE2 = 4'b1000;
defparam mipi_dphy_rx_inst.HSRX_DUTY_LANE3 = 4'b1000;
defparam mipi_dphy_rx_inst.HSRX_DUTY_CK = 4'b1000;
defparam mipi_dphy_rx_inst.HSRX_EN = 1'b1;
defparam mipi_dphy_rx_inst.HSRX_EQ_EN_LANE0 = 1'b1;
defparam mipi_dphy_rx_inst.HSRX_EQ_EN_LANE1 = 1'b1;
defparam mipi_dphy_rx_inst.HSRX_EQ_EN_LANE2 = 1'b1;
defparam mipi_dphy_rx_inst.HSRX_EQ_EN_LANE3 = 1'b1;
defparam mipi_dphy_rx_inst.HSRX_EQ_EN_CK = 1'b1;
defparam mipi_dphy_rx_inst.HSRX_IBIAS = 4'b0011;
defparam mipi_dphy_rx_inst.HSRX_IMARG_EN = 1'b1;
defparam mipi_dphy_rx_inst.HSRX_ODT_EN = 1'b1;
defparam mipi_dphy_rx_inst.HSRX_ODT_TST = 4'b0000;
defparam mipi_dphy_rx_inst.HSRX_ODT_TST_CK = 1'b0;
defparam mipi_dphy_rx_inst.HSRX_STOP_EN = 1'b0;
defparam mipi_dphy_rx_inst.HSRX_TST = 4'b0000;
defparam mipi_dphy_rx_inst.HSRX_TST_CK = 1'b0;
defparam mipi_dphy_rx_inst.HSRX_WAIT4EDGE = 1'b0;
defparam mipi_dphy_rx_inst.HYST_NCTL = 2'b01;
defparam mipi_dphy_rx_inst.HYST_PCTL = 2'b01;
defparam mipi_dphy_rx_inst.LOW_LPRX_VTH = 1'b0;
defparam mipi_dphy_rx_inst.LPRX_EN = 1'b1;
defparam mipi_dphy_rx_inst.LPRX_TST = 4'b0000;
defparam mipi_dphy_rx_inst.LPRX_TST_CK = 1'b0;
defparam mipi_dphy_rx_inst.LPTX_EN = 1'b1;
defparam mipi_dphy_rx_inst.LPTX_SW_LANE0 = 3'b100;
defparam mipi_dphy_rx_inst.LPTX_SW_LANE1 = 3'b100;
defparam mipi_dphy_rx_inst.LPTX_SW_LANE2 = 3'b100;
defparam mipi_dphy_rx_inst.LPTX_SW_LANE3 = 3'b100;
defparam mipi_dphy_rx_inst.LPTX_SW_CK = 3'b100;
defparam mipi_dphy_rx_inst.LPTX_TST = 4'b0000;
defparam mipi_dphy_rx_inst.LPTX_TST_CK = 1'b0;
defparam mipi_dphy_rx_inst.MIPI_DIS_N = 1'b1;
defparam mipi_dphy_rx_inst.PGA_BIAS_LANE0 = 4'b1000;
defparam mipi_dphy_rx_inst.PGA_BIAS_LANE1 = 4'b1000;
defparam mipi_dphy_rx_inst.PGA_BIAS_LANE2 = 4'b1000;
defparam mipi_dphy_rx_inst.PGA_BIAS_LANE3 = 4'b1000;
defparam mipi_dphy_rx_inst.PGA_BIAS_CK = 4'b1000;
defparam mipi_dphy_rx_inst.PGA_GAIN_LANE0 = 4'b1000;
defparam mipi_dphy_rx_inst.PGA_GAIN_LANE1 = 4'b1000;
defparam mipi_dphy_rx_inst.PGA_GAIN_LANE2 = 4'b1000;
defparam mipi_dphy_rx_inst.PGA_GAIN_LANE3 = 4'b1000;
defparam mipi_dphy_rx_inst.PGA_GAIN_CK = 4'b1000;
defparam mipi_dphy_rx_inst.RX_CLK1X_SYNC_SEL = 1'b0;
defparam mipi_dphy_rx_inst.RX_ODT_TRIM_LANE0 = 4'b0111;
defparam mipi_dphy_rx_inst.RX_ODT_TRIM_LANE1 = 4'b0111;
defparam mipi_dphy_rx_inst.RX_ODT_TRIM_LANE2 = 4'b0111;
defparam mipi_dphy_rx_inst.RX_ODT_TRIM_LANE3 = 4'b0111;
defparam mipi_dphy_rx_inst.RX_ODT_TRIM_CK = 4'b0111;
defparam mipi_dphy_rx_inst.STP_UNIT = 2'b00;
defparam mipi_dphy_rx_inst.WALIGN_DVLD_SRC_SEL = 1'b0;
endmodule //Gowin_MIPI_DPHY_RX
