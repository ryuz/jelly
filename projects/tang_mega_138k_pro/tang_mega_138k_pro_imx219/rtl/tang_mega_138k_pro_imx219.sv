
`timescale 1ns / 1ps
`default_nettype none

module tang_mega_138k_pro_imx219
        #(
            parameter JFIVE_TCM_READMEMH     = 1'b1         ,
            parameter JFIVE_TCM_READMEM_FIlE = "mem.hex"    
        )
        (
            input   var logic           in_reset    ,
            input   var logic           in_clk50    ,   // 50MHz

            input   var logic           uart_rx     ,
            output  var logic           uart_tx     ,

            inout   tri logic           csi0_clk_p  ,
            inout   tri logic           csi0_clk_n  ,
            inout   tri logic   [1:0]   csi0_data_p ,
            inout   tri logic   [1:0]   csi0_data_n ,

            output  var logic           csi0_rstn   ,
            inout   tri logic           i2c_scl     ,
            inout   tri logic           i2c_sda     ,
            output  var logic   [2:0]   i2c_sel     ,

//          output  var logic   [7:0]   pmod0       ,
            output  var logic   [7:0]   pmod1       ,
            output  var logic   [7:0]   pmod2       ,

            output  var logic   [5:0]   led_n
        );

    logic   lock    ;
    logic   clk50   ;
    logic   clk250  ;
    Gowin_PLL
        u_Gowin_PLL
            (
                .lock       (lock       ), //output lock
                .clkout0    (clk50      ), //output clkout0
                .clkout1    (clk250     ), //output clkout1
                .clkin      (in_clk50   ) //input clkin
            );

    logic   clk;
    assign clk = clk50;

    logic   reset;
    assign reset = in_reset || !lock;


    logic           csi0_rx_clk             ;
    logic           csi0_drst_n             ;

    logic   [15:0]  csi0_d0ln_hsrxd         ;
    logic   [15:0]  csi0_d1ln_hsrxd         ;
    logic   [1:0]   csi0_hsrxd_vld          ;
    logic   [1:0]   csi0_hsrx_odten         ;

    logic   [1:0]   csi0_di_lprxck          ;
    logic   [1:0]   csi0_di_lprx0           ;
    logic   [1:0]   csi0_di_lprx1           ;

    logic           csi0_deskew_error       ;
    logic           csi0_d0ln_deskew_done   ;
    logic           csi0_d1ln_deskew_done   ;


    /*
    wire    logic           csi0_lprx_en_ck          = 1'b1         ;
    wire    logic           csi0_lprx_en_d0          = 1'b1         ;
    wire    logic           csi0_lprx_en_d1          = 1'b1         ;
    wire    logic           csi0_hsrx_odten_ck       = 1'b1         ;
    wire    logic           csi0_hsrx_odten_d0       = 1'b1         ;
    wire    logic           csi0_hsrx_odten_d1       = 1'b1         ;
    wire    logic           csi0_d0ln_hsrx_dren      = 1'b1         ;
    wire    logic           csi0_d1ln_hsrx_dren      = 1'b1         ;
    wire    logic           csi0_hsrx_en_ck          = 1'b1         ;
    wire    logic           csi0_hs_8bit_mode        = 1'b1         ;
//  wire    logic           csi0_rx_clk_1x           = csi0_rx_clk  ;
    wire    logic           csi0_rx_invert           = '0           ;
    wire    logic           csi0_lalign_en           = 1'b1         ;
    wire    logic           csi0_walign_by           = '0           ;
    wire    logic           csi0_do_lptx0_n          = '0           ;
    wire    logic           csi0_do_lptx0_p          = '0           ;
    wire    logic           csi0_do_lptx1_n          = '0           ;
    wire    logic           csi0_do_lptx1_p          = '0           ;
    wire    logic           csi0_do_lptxck_n         = '0           ;
    wire    logic           csi0_do_lptxck_p         = '0           ;
    wire    logic           csi0_lptx_en_ck          = '0           ;
    wire    logic           csi0_lptx_en_d0          = '0           ;
    wire    logic           csi0_lptx_en_d1          = '0           ;
    wire    logic           csi0_byte_lendian        = '0           ;
    wire    logic           csi0_hsrx_stop           = '0           ;
    wire    logic           csi0_pwron               = 1'b1         ;
    wire    logic           csi0_reset               = reset        ;
    wire    logic   [2:0]   csi0_deskew_lnsel        = '0           ;
    wire    logic   [12:0]  csi0_deskew_mth          = '0           ;
    wire    logic   [6:0]   csi0_deskew_owval        = '0           ;
    wire    logic           csi0_deskew_req          = '0           ;
//  wire    logic           csi0_drst_n              = ~reset       ;
    wire    logic           csi0_one_byte0_match     = '0           ;
    wire    logic           csi0_word_lendian        = '0           ;
    wire    logic   [2:0]   csi0_fifo_rd_std         = 3'd1         ;
    wire    logic           csi0_deskew_by           = '0           ;
    wire    logic           csi0_deskew_en_oedge     = '0           ;
    wire    logic   [5:0]   csi0_deskew_half_opening = '0           ;
    wire    logic   [1:0]   csi0_deskew_lsb_mode     = '0           ;
    wire    logic   [2:0]   csi0_deskew_m            = '0           ;
    wire    logic   [6:0]   csi0_deskew_mset         = '0           ;
    wire    logic           csi0_deskew_oclkedg_en   = '0           ;
    wire    logic   [2:0]   csi0_eqcs_lane0          = 3'b100       ;
    wire    logic   [2:0]   csi0_eqcs_lane1          = 3'b100       ;
    wire    logic   [2:0]   csi0_eqcs_ck             = 3'b100       ;
    wire    logic   [2:0]   csi0_eqrs_lane0          = 3'b100       ;
    wire    logic   [2:0]   csi0_eqrs_lane1          = 3'b100       ;
    wire    logic   [2:0]   csi0_eqrs_ck             = 3'b100       ;
    wire    logic           csi0_hsrx_dlydir_lane0   = '0           ;
    wire    logic           csi0_hsrx_dlydir_lane1   = '0           ;
    wire    logic           csi0_hsrx_dlydir_ck      = '0           ;
    wire    logic           csi0_hsrx_dlyldn_lane0   = '0           ;
    wire    logic           csi0_hsrx_dlyldn_lane1   = '0           ;
    wire    logic           csi0_hsrx_dlyldn_ck      = '0           ;
    wire    logic           csi0_hsrx_dlymv_lane0    = '0           ;
    wire    logic           csi0_hsrx_dlymv_lane1    = '0           ;
    wire    logic           csi0_hsrx_dlymv_ck       = '0           ;
    wire    logic           csi0_walign_dvld         = '0           ;
    */

    Gowin_MIPI_DPHY_RX
        u_MIPI_DPHY_RX
            (
                .ck_n               (csi0_clk_n             ),  //inout ck_n
                .ck_p               (csi0_clk_p             ),  //inout ck_p
                .rx0_n              (csi0_data_n[0]         ),  //inout rx0_n
                .rx0_p              (csi0_data_p[0]         ),  //inout rx0_p
                .rx1_n              (csi0_data_n[1]         ),  //inout rx1_n
                .rx1_p              (csi0_data_p[1]         ),  //inout rx1_p

                .rx_clk_o           (csi0_rx_clk            ), //output rx_clk_o
                .rx_clk_1x          (csi0_rx_clk            ), //input rx_clk_1x

                .drst_n             (csi0_drst_n            ), //input drst_n
                .pwron              (1'b1                   ), //input pwron
                .reset              (reset                  ), //input reset
                .hsrx_stop          (1'b0                   ), //input hsrx_stop

                .hs_8bit_mode       (1'b1                   ), //input hs_8bit_mode
                .rx_invert          (1'b0                   ), //input rx_invert
                .byte_lendian       (1'b1                   ), //input byte_lendian
                .lalign_en          (1'b1                   ), //input lalign_en

                .walign_by          (1'b0                   ), //input walign_by
                .one_byte0_match    (1'b0                   ), //input one_byte0_match
                .word_lendian       (1'b1                   ), //input word_lendian
                .fifo_rd_std        (3'b001                 ), //input [2:0] fifo_rd_std
                .walign_dvld        (1'b0                   ), //input walign_dvld

                .hsrx_en_ck         (1'b1                   ), //input hsrx_en_ck
                .d0ln_hsrx_dren     (1'b1                   ), //input d0ln_hsrx_dren
                .d1ln_hsrx_dren     (1'b1                   ), //input d1ln_hsrx_dren
                .hsrx_odten_ck      (1'b1                   ), //input hsrx_odten_ck
                .hsrx_odten_d0      (csi0_hsrx_odten[0]     ), //input hsrx_odten_d0
                .hsrx_odten_d1      (csi0_hsrx_odten[1]     ), //input hsrx_odten_d1
                .d0ln_hsrxd_vld     (csi0_hsrxd_vld[0]      ), //output d0ln_hsrxd_vld
                .d1ln_hsrxd_vld     (csi0_hsrxd_vld[1]      ), //output d1ln_hsrxd_vld
                .d0ln_hsrxd         (csi0_d0ln_hsrxd        ), //output [15:0] d0ln_hsrxd
                .d1ln_hsrxd         (csi0_d1ln_hsrxd        ), //output [15:0] d1ln_hsrxd

                .lprx_en_ck         (1'b1                   ), //input lprx_en_ck
                .lprx_en_d0         (1'b1                   ), //input lprx_en_d0
                .lprx_en_d1         (1'b1                   ), //input lprx_en_d1
                .di_lprxck_n        (csi0_di_lprxck[0]      ), //output di_lprxck_n
                .di_lprxck_p        (csi0_di_lprxck[1]      ), //output di_lprxck_p
                .di_lprx0_n         (csi0_di_lprx0[0]       ), //output di_lprx0_n
                .di_lprx0_p         (csi0_di_lprx0[1]       ), //output di_lprx0_p
                .di_lprx1_n         (csi0_di_lprx1[0]       ), //output di_lprx1_n
                .di_lprx1_p         (csi0_di_lprx1[1]       ), //output di_lprx1_p

                .lptx_en_ck         (1'b0                   ), //input lptx_en_ck
                .lptx_en_d0         (1'b0                   ), //input lptx_en_d0
                .lptx_en_d1         (1'b0                   ), //input lptx_en_d1
                .do_lptxck_n        (1'b0                   ), //input do_lptxck_n
                .do_lptxck_p        (1'b0                   ), //input do_lptxck_p
                .do_lptx0_n         (1'b0                   ), //input do_lptx0_n
                .do_lptx0_p         (1'b0                   ), //input do_lptx0_p
                .do_lptx1_n         (1'b0                   ), //input do_lptx1_n
                .do_lptx1_p         (1'b0                   ), //input do_lptx1_p

                .deskew_by          (1'b1                   ), //input deskew_by
                .deskew_en_oedge    (1'b0                   ), //input deskew_en_oedge
                .deskew_req         (1'b0                   ), //input deskew_req
                .deskew_lnsel       ('0                     ), //input [2:0] deskew_lnsel
                .deskew_lsb_mode    ('0                     ), //input [1:0] deskew_lsb_mode
                .deskew_m           ('0                     ), //input [2:0] deskew_m
                .deskew_mset        ('0                     ), //input [6:0] deskew_mset
                .deskew_mth         ('0                     ), //input [12:0] deskew_mth
                .deskew_owval       ('0                     ), //input [6:0] deskew_owval
                .deskew_half_opening('0                     ), //input [5:0] deskew_half_opening
                .deskew_oclkedg_en  (1'b0                   ), //input deskew_oclkedg_en
                .deskew_error       (csi0_deskew_error      ), //output deskew_error
                .d0ln_deskew_done   (csi0_d0ln_deskew_done  ), //output d0ln_deskew_done
                .d1ln_deskew_done   (csi0_d1ln_deskew_done  ), //output d1ln_deskew_done

                .eqcs_ck            (3'b100                 ), //input [2:0] eqcs_ck
                .eqcs_lane0         (3'b100                 ), //input [2:0] eqcs_lane0
                .eqcs_lane1         (3'b100                 ), //input [2:0] eqcs_lane1
                .eqrs_ck            (3'b100                 ), //input [2:0] eqrs_ck
                .eqrs_lane0         (3'b100                 ), //input [2:0] eqrs_lane0
                .eqrs_lane1         (3'b100                 ), //input [2:0] eqrs_lane1
                .hsrx_dlydir_ck     (1'b0                   ), //input hsrx_dlydir_ck
                .hsrx_dlydir_lane0  (1'b0                   ), //input hsrx_dlydir_lane0
                .hsrx_dlydir_lane1  (1'b0                   ), //input hsrx_dlydir_lane1
                .hsrx_dlyldn_ck     (1'b0                   ), //input hsrx_dlyldn_ck
                .hsrx_dlyldn_lane0  (1'b0                   ), //input hsrx_dlyldn_lane0
                .hsrx_dlyldn_lane1  (1'b0                   ), //input hsrx_dlyldn_lane1
                .hsrx_dlymv_ck      (1'b0                   ), //input hsrx_dlymv_ck
                .hsrx_dlymv_lane0   (1'b0                   ), //input hsrx_dlymv_lane0
                .hsrx_dlymv_lane1   (1'b0                   )  //input hsrx_dlymv_lane1
            );

    logic               csi0_byte_ready  ;
    logic   [7:0]       csi0_byte_d0     ;
    logic   [7:0]       csi0_byte_d1     ;
    logic   [1:0]       csi0_lp0_reg_0   = 2'b11;
    logic   [1:0]       csi0_lp0_reg_1   = 2'b11;
    logic               csi0_odt_en_msk  = '0;
    logic               csi0_hsrx_en_msk = 1'b0;
    logic   [5:0]       csi0_hsrx_cnt    = 'b0;
    logic               csi0_reg3to1     = 1'b0;

    wire logic          csi0_from0to3    = (csi0_lp0_reg_1==0)&(csi0_lp0_reg_0==3);
    wire logic          csi0_from1to0    = (csi0_lp0_reg_1==1)&(csi0_lp0_reg_0==0);
    wire logic          csi0_from1to2    = (csi0_lp0_reg_1==1)&(csi0_lp0_reg_0==2);
    wire logic          csi0_from1to3    = (csi0_lp0_reg_1==1)&(csi0_lp0_reg_0==3);
    wire logic          csi0_from3to1    = (csi0_lp0_reg_1==3)&(csi0_lp0_reg_0==1);
    wire logic          csi0_fromXto3    = (csi0_lp0_reg_1!=3)&(csi0_lp0_reg_0==3);
    wire logic          csi0_from1toX    = (csi0_lp0_reg_1==1)&(csi0_lp0_reg_0!=1);
    wire logic  [ 1:0]  csi0_odt_en      = {(csi0_di_lprx1==0), (csi0_di_lprx0==0)} & {2{csi0_odt_en_msk}};

    always_ff @(posedge csi0_rx_clk or posedge reset) begin
        if (reset)                  csi0_odt_en_msk  <= 'b0;
        else if (~csi0_odt_en_msk)  csi0_odt_en_msk  <= csi0_from3to1;
        else if (1)                 csi0_odt_en_msk  <= !(csi0_from1to2|csi0_from1to3|csi0_fromXto3);
    //!______________________________________________________________________________
        if (reset)                  csi0_reg3to1 <= 'b0;
        else if (~csi0_reg3to1)     csi0_reg3to1 <= csi0_from3to1;
        else if (1)                 csi0_reg3to1 <= ~csi0_from1toX;
    //!______________________________________________________________________________
        if (reset)                  csi0_hsrx_cnt    <= 'b0;
        else if (|csi0_odt_en)      csi0_hsrx_cnt    <= 6'd10;
        else if (csi0_hsrx_cnt>0)   csi0_hsrx_cnt    <= csi0_hsrx_cnt - 6'd1;
    end

    always_ff @(posedge csi0_rx_clk) begin
        csi0_lp0_reg_0   <= csi0_di_lprx0;
    //    lp1_reg_0   <= lp_data1;
        csi0_lp0_reg_1   <= csi0_lp0_reg_0;
    //!______________________________________________________________________________
        csi0_drst_n      <= ~(csi0_reg3to1&csi0_from1to0);
    //    rx_drst_n   <= ~from3to1;
    //!______________________________________________________________________________
    //    odt_en      <= {(lp1_reg_0==0), (lp0_reg_0==0)} & {2{odt_en_msk}};
    //!______________________________________________________________________________
        csi0_hsrx_en_msk <= (csi0_hsrx_cnt>0);
        csi0_byte_ready  <= csi0_hsrx_en_msk & csi0_hsrxd_vld[0];
        csi0_byte_d0     <= csi0_d0ln_hsrxd[7:0];
        csi0_byte_d1     <= csi0_d1ln_hsrxd[7:0];
    end
    
    assign csi0_hsrx_odten = {(csi0_di_lprx1==0), (csi0_di_lprx0==0)} & {2{csi0_odt_en_msk}};


    wire            csi_rx_sp_en       /* synthesis syn_keep = 1 */;
    wire            csi_rx_lp_en       /* synthesis syn_keep = 1 */;
    wire            csi_rx_lp_av_en    /* synthesis syn_keep = 1 */;
    wire            csi_rx_ecc_ok      ;
    wire [15:0]     csi_rx_wc          ;
    wire [ 1:0]     csi_rx_vc          ;
    wire [ 5:0]     csi_rx_dt          ;
    wire [ 7:0]     csi_rx_ecc         ;
    wire [ 1:0]     csi_rx_payload_dv  /* synthesis syn_keep = 1 */;
    wire [15:0]     csi_rx_payload     /* synthesis syn_keep = 1 */;

    MIPI_DSI_CSI2_RX_Top
        u_MIPI_DSI_CSI2_RX
            (
                .I_RSTN         (~reset         ), //input I_RSTN
                .I_BYTE_CLK     (csi0_rx_clk    ), //input I_BYTE_CLK
                .I_REF_DT       (6'h2b          ), //input [5:0] I_REF_DT  RAW10
                .I_READY        (csi0_byte_ready), //input I_READY
                .I_DATA0        (csi0_byte_d0   ), //input [7:0] I_DATA0
                .I_DATA1        (csi0_byte_d1   ), //input [7:0] I_DATA1
                .O_SP_EN        (csi_rx_sp_en          ), //output O_SP_EN
                .O_LP_EN        (csi_rx_lp_en          ), //output O_LP_EN
                .O_LP_AV_EN     (csi_rx_lp_av_en       ), //output O_LP_AV_EN
                .O_ECC_OK       (csi_rx_ecc_ok         ), //output O_ECC_OK
                .O_ECC          (csi_rx_ecc            ), //output [7:0] O_ECC
                .O_WC           (csi_rx_wc             ), //output [15:0] O_WC
                .O_VC           (csi_rx_vc             ), //output [1:0] O_VC
                .O_DT           (csi_rx_dt             ), //output [5:0] O_DT
                .O_PAYLOAD_DV   (csi_rx_payload_dv     ), //output [1:0] O_PAYLOAD_DV
                .O_PAYLOAD      (csi_rx_payload        )  //output [15:0] O_PAYLOAD
            );

    logic       video_fv;
    logic       video_lv;
    logic [9:0] video_pixel;
    MIPI_Byte_to_Pixel_Converter_Top
        u_MIPI_Byte_to_Pixel_Converter_Top
            (
                .I_RSTN         (~reset             ),  //input I_RSTN
                .I_BYTE_CLK     (csi0_rx_clk        ),  //input I_BYTE_CLK
                .I_PIXEL_CLK    (clk250             ),  //input I_PIXEL_CLK
                .I_SP_EN        (csi_rx_sp_en       ),  //input I_SP_EN
                .I_LP_AV_EN     (csi_rx_lp_av_en    ),  //input I_LP_AV_EN
                .I_DT           (csi_rx_dt          ),  //input [5:0] I_DT
                .I_WC           (csi_rx_wc          ),  //input [15:0] I_WC
                .I_PAYLOAD_DV   (csi_rx_payload_dv  ),  //input [1:0] I_PAYLOAD_DV
                .I_PAYLOAD      (csi_rx_payload     ),  //input [15:0] I_PAYLOAD
                .O_FV           (video_fv           ),  //output O_FV
                .O_LV           (video_lv           ),  //output O_LV
                .O_PIXEL        (video_pixel        )   //output [9:0] O_PIXEL
            );


    /*
    logic           lp_clk_out          ;
    logic           clk_byte_out        ;
    logic [7:0]     data_out0           ;
    logic [7:0]     data_out1           ;
    logic [1:0]     lp_data0_out        ;
    logic [1:0]     lp_data1_out        ;
    logic           clk_hs_en    = 1'b1 ;
    logic           data_hs_en   = 1'b1 ;
    logic           clk_term_en  = 1'b1 ;
    logic           data_term_en = 1'b1 ;
    logic           ready               ;
    
	MIPI_RX_Advance_Top
        u_mipi_rx
            (
                .reset_n            (csi0_rstn      ),  //input reset_n
                .MIPI_CLK_P         (csi0_clk_p     ),  //inout MIPI_COMB_CLK_P
                .MIPI_CLK_N         (csi0_clk_n     ),  //inout MIPI_COMB_CLK_N
                .lp_clk_out         (lp_clk_out     ),  //output [1:0] lp_clk_out
                .lp_clk_in          (2'b00          ),  //input [1:0] lp_clk_in
                .lp_clk_dir         (1'b0           ),  //input lp_clk_dir
                .clk_byte_out       (clk_byte_out   ),  //output clk_byte_out
                .MIPI_LANE1_P       (csi0_data_p[1] ),  //inout MIPI_LANE1_P
                .MIPI_LANE1_N       (csi0_data_n[1] ),  //inout MIPI_LANE1_N
                .data_out1          (data_out1      ),  //output [7:0] data_out1
                .lp_data1_out       (lp_data1_out   ),  //output [1:0] lp_data1_out
                .lp_data1_in        (2'b00          ),  //input [1:0] lp_data1_in
                .lp_data1_dir       (1'b0           ),  //input lp_data1_dir
                .MIPI_LANE0_P       (csi0_data_p[0] ),  //inout MIPI_LANE0_P
                .MIPI_LANE0_N       (csi0_data_n[0] ),  //inout MIPI_LANE0_N
                .data_out0          (data_out0      ),  //output [7:0] data_out0
                .lp_data0_out       (lp_data0_out   ),  //output [1:0] lp_data0_out
                .lp_data0_in        (2'b00          ),  //input [1:0] lp_data0_in
                .lp_data0_dir       (1'b0           ),  //input lp_data0_dir
                .clk_hs_en          (clk_hs_en      ),  //input clk_hs_en
                .data_hs_en         (data_hs_en     ),  //input data_hs_en
                .clk_term_en        (clk_term_en    ),  //input clk_term_en
                .data_term_en       (data_term_en   ),  //input data_term_en
                .ready              (ready          )   //output ready
            );
    */

    // -----------------------------
    //  Micro controller (RISC-V)
    // -----------------------------

    // WISHBONE-BUS
    localparam  int  WB_ADR_WIDTH   = 16;
    localparam  int  WB_DAT_WIDTH   = 32;
    localparam  int  WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8);

    wire logic   [WB_ADR_WIDTH-1:0]      wb_mcu_adr_o;
    wire logic   [WB_DAT_WIDTH-1:0]      wb_mcu_dat_i;
    wire logic   [WB_DAT_WIDTH-1:0]      wb_mcu_dat_o;
    wire logic   [WB_SEL_WIDTH-1:0]      wb_mcu_sel_o;
    wire logic                           wb_mcu_we_o ;
    wire logic                           wb_mcu_stb_o;
    wire logic                           wb_mcu_ack_i;
    
    jfive_simple_controller
            #(
                .S_WB_ADR_WIDTH     (24                     ),
                .S_WB_DAT_WIDTH     (32                     ),
                .S_WB_TCM_ADR       (24'h0001_0000          ),

                .M_WB_DECODE_MASK   (32'hf000_0000          ),
                .M_WB_DECODE_ADDR   (32'h1000_0000          ),
                .M_WB_ADR_WIDTH     (16                     ),

                .TCM_DECODE_MASK    (32'hff00_0000          ),
                .TCM_DECODE_ADDR    (32'h8000_0000          ),
                .TCM_SIZE           (8192*4                 ),
                .TCM_RAM_MODE       ("NORMAL"               ),
                .TCM_READMEMH       (JFIVE_TCM_READMEMH     ),
                .TCM_READMEM_FIlE   (JFIVE_TCM_READMEM_FIlE ),

                .PC_WIDTH           (32                     ),
                .INIT_PC_ADDR       (32'h8000_0000          ),
                .INIT_CTL_RESET     (1'b0                   ),

                .SIMULATION         (1'b0                   ),
                .LOG_EXE_ENABLE     (1'b0                   ),
                .LOG_MEM_ENABLE     (1'b0                   )
            )
        u_jfive_simple_controller
            (
                .reset              (reset                  ),
                .clk                (clk                    ),
                .cke                (1'b1                   ),

                .s_wb_adr_i         ('0                     ),
                .s_wb_dat_o         (                       ),
                .s_wb_dat_i         ('0                     ),
                .s_wb_sel_i         ('0                     ),
                .s_wb_we_i          ('0                     ),
                .s_wb_stb_i         ('0                     ),
                .s_wb_ack_o         (                       ),

                .m_wb_adr_o         (wb_mcu_adr_o           ),
                .m_wb_dat_i         (wb_mcu_dat_i           ),
                .m_wb_dat_o         (wb_mcu_dat_o           ),
                .m_wb_sel_o         (wb_mcu_sel_o           ),
                .m_wb_we_o          (wb_mcu_we_o            ),
                .m_wb_stb_o         (wb_mcu_stb_o           ),
                .m_wb_ack_i         (wb_mcu_ack_i           )
            );


    // uart
    logic   [WB_DAT_WIDTH-1:0]  wb_uart_dat_o;
    logic                       wb_uart_stb_i;
    logic                       wb_uart_ack_o;

    jelly2_uart
            #(
                .ASYNC              (0                  ),
                .TX_FIFO_PTR_WIDTH  (2                  ),
                .RX_FIFO_PTR_WIDTH  (2                  ),
                .WB_ADR_WIDTH       (2                  ),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH       ),
                .DIVIDER_WIDTH      (8                  ),
                .DIVIDER_INIT       (54-1               ),
                .SIMULATION         (0                  ),
                .DEBUG              (1                  )
            )
        u_uart
            (
                .reset              (reset              ),
                .clk                (clk                ),
                
                .uart_reset         (reset              ),
                .uart_clk           (clk                ),
                .uart_tx            (uart_tx            ),
                .uart_rx            (uart_rx            ),
                
                .irq_rx             (                   ),
                .irq_tx             (                   ),
                
                .s_wb_adr_i         (wb_mcu_adr_o[1:0]  ),
                .s_wb_dat_o         (wb_uart_dat_o      ),
                .s_wb_dat_i         (wb_mcu_dat_o       ),
                .s_wb_we_i          (wb_mcu_we_o        ),
                .s_wb_sel_i         (wb_mcu_sel_o       ),
                .s_wb_stb_i         (wb_uart_stb_i      ),
                .s_wb_ack_o         (wb_uart_ack_o      )
            );


    // I2C
    logic   [WB_DAT_WIDTH-1:0]  wb_i2c_dat_o;
    logic                       wb_i2c_stb_i;
    logic                       wb_i2c_ack_o;

    logic                       i2c_scl_t;
    logic                       i2c_scl_i;
    logic                       i2c_sda_t;
    logic                       i2c_sda_i;

    jelly_i2c
            #(
                .DIVIDER_WIDTH      (16                 ),
                .DIVIDER_INIT       (1000               ),
                .WB_ADR_WIDTH       (3                  ),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH       )
            )
        u_i2c
            (
                .reset              (reset              ),
                .clk                (clk                ),
                
                .i2c_scl_t          (i2c_scl_t          ),
                .i2c_scl_i          (i2c_scl_i          ),
                .i2c_sda_t          (i2c_sda_t          ),
                .i2c_sda_i          (i2c_sda_i          ),

                .s_wb_adr_i         (wb_mcu_adr_o[2:0]  ),
                .s_wb_dat_o         (wb_i2c_dat_o       ),
                .s_wb_dat_i         (wb_mcu_dat_o       ),
                .s_wb_we_i          (wb_mcu_we_o        ),
                .s_wb_sel_i         (wb_mcu_sel_o       ),
                .s_wb_stb_i         (wb_i2c_stb_i       ),
                .s_wb_ack_o         (wb_i2c_ack_o       ),
                
                .irq                (                   )
            );

    IOBUF
        u_iobuf_csi0_scl
            (
                .OEN            (i2c_scl_t ),
                .I              (1'b0      ),
                .IO             (i2c_scl   ),
                .O              (i2c_scl_i )
            );

    IOBUF
        u_iobuf_csi0_sda
            (
                .OEN            (i2c_sda_t ),
                .I              (1'b0      ),
                .IO             (i2c_sda   ),
                .O              (i2c_sda_i )
            );
    
    assign i2c_sel = 3'b110;


    // GPIO
    logic   [WB_DAT_WIDTH-1:0]  wb_gpio_dat_o;
    logic                       wb_gpio_stb_i;
    logic                       wb_gpio_ack_o;

    logic   [3:0]               reg_gpio0;
    logic   [7:0]               reg_gpio1;
    logic   [7:0]               reg_gpio2;
    logic   [7:0]               reg_gpio3;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_gpio0 <= '0;
            reg_gpio1 <= '0;
            reg_gpio2 <= '0;
            reg_gpio3 <= '0;
        end
        else begin
            if ( wb_gpio_stb_i ) begin
                case ( wb_mcu_adr_o[1:0] )
                2'd0: reg_gpio0 <= wb_mcu_dat_o[3:0];
                2'd1: reg_gpio1 <= wb_mcu_dat_o[7:0];
                2'd2: reg_gpio2 <= wb_mcu_dat_o[7:0];
                2'd3: reg_gpio3 <= wb_mcu_dat_o[7:0];
                endcase
            end
        end
    end
    always_comb begin
        wb_gpio_dat_o = '0;
        case ( wb_mcu_adr_o[1:0] )
            2'd0: wb_gpio_dat_o = 32'(reg_gpio0);
            2'd1: wb_gpio_dat_o = 32'(reg_gpio1);
            2'd2: wb_gpio_dat_o = 32'(reg_gpio2);
            2'd3: wb_gpio_dat_o = 32'(reg_gpio3);
        endcase
    end
    assign wb_gpio_ack_o = wb_gpio_stb_i;


    assign csi0_rstn = reg_gpio1[0];


    // address decode
    assign wb_uart_stb_i = wb_mcu_stb_o && (wb_mcu_adr_o[9:6] == 4'h0);
    assign wb_gpio_stb_i = wb_mcu_stb_o && (wb_mcu_adr_o[9:6] == 4'h1);
    assign wb_i2c_stb_i  = wb_mcu_stb_o && (wb_mcu_adr_o[9:6] == 4'h2);

    assign wb_mcu_dat_i  = wb_uart_stb_i ? wb_uart_dat_o :
                           wb_gpio_stb_i ? wb_gpio_dat_o :
                           wb_i2c_stb_i  ? wb_i2c_dat_o  :
                           '0;

    assign wb_mcu_ack_i  = wb_uart_stb_i ? wb_uart_ack_o :
                           wb_gpio_stb_i ? wb_gpio_ack_o :
                           wb_i2c_stb_i  ? wb_i2c_ack_o  :
                           wb_mcu_stb_o;


    // Health check
    logic   [24:0]  counter = '0;
    always_ff @(posedge clk or posedge reset) begin
        if ( reset ) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end

    logic   [24:0]  csi0_counter = '0;
    always_ff @(posedge csi0_rx_clk) begin
        csi0_counter <= csi0_counter + 1;
    end


//  assign led_n[3:0] = reg_gpio0[3:0];
    assign led_n[0] = ~i2c_scl_i;
    assign led_n[1] = ~i2c_scl_t;
    assign led_n[2] = ~i2c_sda_i;
    assign led_n[3] = ~csi0_counter[24];
    assign led_n[4] = ~counter[24];
    assign led_n[5] = ~reset;

    /*
    assign pmod1[0] = i2c_scl_i;
    assign pmod1[1] = i2c_sda_i;
//    assign pmod1[2] = csi0_rstn;
//    assign pmod1[7:3] = counter[7:3];
//    assign pmod1[7:2] = csi0_d0ln_hsrxd;
    assign pmod1[7:2] = csi0_d1ln_hsrxd;
    */
    assign pmod1[7:0] = csi0_d0ln_hsrxd[7:0];

//    assign pmod1 = counter[15:8];
    assign pmod2 = counter[15:8];
//  assign pmod2 = reg_gpio3;


endmodule


`default_nettype wire


// End of file
