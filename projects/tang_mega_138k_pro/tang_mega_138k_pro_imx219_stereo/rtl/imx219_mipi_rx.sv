
`timescale 1ns / 1ps
`default_nettype none

module imx219_mipi_rx
        (
            input   var logic           in_reset    ,

            inout   tri logic           mipi_clk_p  ,   // 912MHz
            inout   tri logic           mipi_clk_n  ,
            inout   tri logic   [1:0]   mipi_data_p ,
            inout   tri logic   [1:0]   mipi_data_n ,

            input   var logic           out_clk     ,
            output  var logic           out_fv      ,
            output  var logic           out_lv      ,
            output  var logic   [9:0]   out_pixel   
        );


    // ---------------------------------
    //  MIPI CSI2 RX
    // ---------------------------------

    logic           mipi_dphy_rx_clk             ;
    logic           mipi_dphy_drst_n             ;

    logic   [15:0]  mipi_dphy_d0ln_hsrxd         ;
    logic   [15:0]  mipi_dphy_d1ln_hsrxd         ;
    logic   [1:0]   mipi_dphy_hsrxd_vld          ;
    logic   [1:0]   mipi_dphy_hsrx_odten         ;

    logic   [1:0]   mipi_dphy_di_lprxck          ;
    logic   [1:0]   mipi_dphy_di_lprx0           ;
    logic   [1:0]   mipi_dphy_di_lprx1           ;

    logic           mipi_dphy_deskew_error       ;
    logic           mipi_dphy_d0ln_deskew_done   ;
    logic           mipi_dphy_d1ln_deskew_done   ;

    Gowin_MIPI_DPHY_RX
        u_MIPI_DPHY_RX
            (
                .ck_n               (mipi_clk_n                 ),  // inout
                .ck_p               (mipi_clk_p                 ),  // inout
                .rx0_n              (mipi_data_n[0]             ),  // inout
                .rx0_p              (mipi_data_p[0]             ),  // inout
                .rx1_n              (mipi_data_n[1]             ),  // inout
                .rx1_p              (mipi_data_p[1]             ),  // inout

                .rx_clk_o           (mipi_dphy_rx_clk           ),  // output
                .rx_clk_1x          (mipi_dphy_rx_clk           ),  // input

                .drst_n             (mipi_dphy_drst_n           ),  // input
                .pwron              (1'b1                       ),  // input
                .reset              (in_reset                   ),  // input
                .hsrx_stop          (1'b0                       ),  // input

                .hs_8bit_mode       (1'b1                       ),  // input
                .rx_invert          (1'b0                       ),  // input
                .byte_lendian       (1'b1                       ),  // input
                .lalign_en          (1'b1                       ),  // input

                .walign_by          (1'b0                       ),  // input
                .one_byte0_match    (1'b0                       ),  // input
                .word_lendian       (1'b1                       ),  // input
                .fifo_rd_std        (3'b001                     ),  // input [2:0]
                .walign_dvld        (1'b0                       ),  // input

                .hsrx_en_ck         (1'b1                       ),  // input
                .d0ln_hsrx_dren     (1'b1                       ),  // input
                .d1ln_hsrx_dren     (1'b1                       ),  // input
                .hsrx_odten_ck      (1'b1                       ),  // input
                .hsrx_odten_d0      (mipi_dphy_hsrx_odten[0]    ),  // input
                .hsrx_odten_d1      (mipi_dphy_hsrx_odten[1]    ),  // input
                .d0ln_hsrxd_vld     (mipi_dphy_hsrxd_vld[0]     ),  // output
                .d1ln_hsrxd_vld     (mipi_dphy_hsrxd_vld[1]     ),  // output
                .d0ln_hsrxd         (mipi_dphy_d0ln_hsrxd       ),  // output [15:0]
                .d1ln_hsrxd         (mipi_dphy_d1ln_hsrxd       ),  // output [15:0]

                .lprx_en_ck         (1'b1                       ),  // input
                .lprx_en_d0         (1'b1                       ),  // input
                .lprx_en_d1         (1'b1                       ),  // input
                .di_lprxck_n        (mipi_dphy_di_lprxck[0]     ),  // output
                .di_lprxck_p        (mipi_dphy_di_lprxck[1]     ),  // output
                .di_lprx0_n         (mipi_dphy_di_lprx0[0]      ),  // output
                .di_lprx0_p         (mipi_dphy_di_lprx0[1]      ),  // output
                .di_lprx1_n         (mipi_dphy_di_lprx1[0]      ),  // output
                .di_lprx1_p         (mipi_dphy_di_lprx1[1]      ),  // output

                .lptx_en_ck         (1'b0                       ),  // input
                .lptx_en_d0         (1'b0                       ),  // input
                .lptx_en_d1         (1'b0                       ),  // input
                .do_lptxck_n        (1'b0                       ),  // input
                .do_lptxck_p        (1'b0                       ),  // input
                .do_lptx0_n         (1'b0                       ),  // input
                .do_lptx0_p         (1'b0                       ),  // input
                .do_lptx1_n         (1'b0                       ),  // input
                .do_lptx1_p         (1'b0                       ),  // input

                .deskew_by          (1'b1                       ),  // input
                .deskew_en_oedge    (1'b0                       ),  // input
                .deskew_req         (1'b0                       ),  // input
                .deskew_lnsel       ('0                         ),  // input [2:0]
                .deskew_lsb_mode    ('0                         ),  // input [1:0]
                .deskew_m           ('0                         ),  // input [2:0]
                .deskew_mset        ('0                         ),  // input [6:0]
                .deskew_mth         ('0                         ),  // input [12:0]
                .deskew_owval       ('0                         ),  // input [6:0]
                .deskew_half_opening('0                         ),  // input [5:0]
                .deskew_oclkedg_en  (1'b0                       ),  // input
                .deskew_error       (mipi_dphy_deskew_error     ),  // output
                .d0ln_deskew_done   (mipi_dphy_d0ln_deskew_done ),  // output
                .d1ln_deskew_done   (mipi_dphy_d1ln_deskew_done ),  // output

                .eqcs_ck            (3'b100                     ),  // input [2:0]
                .eqcs_lane0         (3'b100                     ),  // input [2:0]
                .eqcs_lane1         (3'b100                     ),  // input [2:0]
                .eqrs_ck            (3'b100                     ),  // input [2:0]
                .eqrs_lane0         (3'b100                     ),  // input [2:0]
                .eqrs_lane1         (3'b100                     ),  // input [2:0]
                .hsrx_dlydir_ck     (1'b0                       ),  // input
                .hsrx_dlydir_lane0  (1'b0                       ),  // input
                .hsrx_dlydir_lane1  (1'b0                       ),  // input
                .hsrx_dlyldn_ck     (1'b0                       ),  // input
                .hsrx_dlyldn_lane0  (1'b0                       ),  // input
                .hsrx_dlyldn_lane1  (1'b0                       ),  // input
                .hsrx_dlymv_ck      (1'b0                       ),  // input
                .hsrx_dlymv_lane0   (1'b0                       ),  // input
                .hsrx_dlymv_lane1   (1'b0                       )   // input
            );

    logic               mipi_dphy_byte_ready  ;
    logic   [7:0]       mipi_dphy_byte_d0     ;
    logic   [7:0]       mipi_dphy_byte_d1     ;
    logic   [1:0]       mipi_dphy_lp0_reg_0   = 2'b11   ;
    logic   [1:0]       mipi_dphy_lp0_reg_1   = 2'b11   ;
    logic               mipi_dphy_odt_en_msk  = '0      ;
    logic               mipi_dphy_hsrx_en_msk = 1'b0    ;
    logic   [5:0]       mipi_dphy_hsrx_cnt    = 'b0     ;
    logic               mipi_dphy_reg3to1     = 1'b0    ;

    wire logic          mipi_dphy_from0to3    = (mipi_dphy_lp0_reg_1==0)&(mipi_dphy_lp0_reg_0==3);
    wire logic          mipi_dphy_from1to0    = (mipi_dphy_lp0_reg_1==1)&(mipi_dphy_lp0_reg_0==0);
    wire logic          mipi_dphy_from1to2    = (mipi_dphy_lp0_reg_1==1)&(mipi_dphy_lp0_reg_0==2);
    wire logic          mipi_dphy_from1to3    = (mipi_dphy_lp0_reg_1==1)&(mipi_dphy_lp0_reg_0==3);
    wire logic          mipi_dphy_from3to1    = (mipi_dphy_lp0_reg_1==3)&(mipi_dphy_lp0_reg_0==1);
    wire logic          mipi_dphy_fromXto3    = (mipi_dphy_lp0_reg_1!=3)&(mipi_dphy_lp0_reg_0==3);
    wire logic          mipi_dphy_from1toX    = (mipi_dphy_lp0_reg_1==1)&(mipi_dphy_lp0_reg_0!=1);
    wire logic  [ 1:0]  mipi_dphy_odt_en      = {(mipi_dphy_di_lprx1==0), (mipi_dphy_di_lprx0==0)} & {2{mipi_dphy_odt_en_msk}};

    always_ff @(posedge mipi_dphy_rx_clk or posedge in_reset) begin
        if (in_reset)                   mipi_dphy_odt_en_msk <= 'b0;
        else if (~mipi_dphy_odt_en_msk) mipi_dphy_odt_en_msk <= mipi_dphy_from3to1;
        else if (1)                     mipi_dphy_odt_en_msk <= !(mipi_dphy_from1to2|mipi_dphy_from1to3|mipi_dphy_fromXto3);

        if (in_reset)                   mipi_dphy_reg3to1 <= 'b0;
        else if (~mipi_dphy_reg3to1)    mipi_dphy_reg3to1 <= mipi_dphy_from3to1;
        else if (1)                     mipi_dphy_reg3to1 <= ~mipi_dphy_from1toX;

        if (in_reset)                   mipi_dphy_hsrx_cnt <= 'b0;
        else if (|mipi_dphy_odt_en)     mipi_dphy_hsrx_cnt <= 6'd10;
        else if (mipi_dphy_hsrx_cnt>0)  mipi_dphy_hsrx_cnt <= mipi_dphy_hsrx_cnt - 6'd1;
    end

    always_ff @(posedge mipi_dphy_rx_clk) begin
        mipi_dphy_lp0_reg_0   <= mipi_dphy_di_lprx0;
        mipi_dphy_lp0_reg_1   <= mipi_dphy_lp0_reg_0;
        mipi_dphy_drst_n      <= ~(mipi_dphy_reg3to1&mipi_dphy_from1to0);
        mipi_dphy_hsrx_en_msk <= (mipi_dphy_hsrx_cnt>0);
        mipi_dphy_byte_ready  <= mipi_dphy_hsrx_en_msk & mipi_dphy_hsrxd_vld[0];
        mipi_dphy_byte_d0     <= mipi_dphy_d0ln_hsrxd[7:0];
        mipi_dphy_byte_d1     <= mipi_dphy_d1ln_hsrxd[7:0];
    end
    assign mipi_dphy_hsrx_odten = {(mipi_dphy_di_lprx1==0), (mipi_dphy_di_lprx0==0)} & {2{mipi_dphy_odt_en_msk}};


    // MIPI CSI RX
    logic               mipi_csi_rx_sp_en       /* synthesis syn_keep = 1 */;
    logic               mipi_csi_rx_lp_en       /* synthesis syn_keep = 1 */;
    logic               mipi_csi_rx_lp_av_en    /* synthesis syn_keep = 1 */;
    logic               mipi_csi_rx_ecc_ok      ;
    logic   [15:0]      mipi_csi_rx_wc          ;
    logic   [ 1:0]      mipi_csi_rx_vc          ;
    logic   [ 5:0]      mipi_csi_rx_dt          ;
    logic   [ 7:0]      mipi_csi_rx_ecc         ;
    logic   [ 1:0]      mipi_csi_rx_payload_dv  /* synthesis syn_keep = 1 */;
    logic   [15:0]      mipi_csi_rx_payload     /* synthesis syn_keep = 1 */;

    MIPI_DSI_CSI2_RX_Top
        u_MIPI_DSI_CSI2_RX
            (
                .I_RSTN         (~in_reset              ), // input
                .I_BYTE_CLK     (mipi_dphy_rx_clk       ), // input
                .I_REF_DT       (6'h2b                  ), // input [5:0]
                .I_READY        (mipi_dphy_byte_ready   ), // input
                .I_DATA0        (mipi_dphy_byte_d0      ), // input [7:0]
                .I_DATA1        (mipi_dphy_byte_d1      ), // input [7:0]
                .O_SP_EN        (mipi_csi_rx_sp_en      ), // output
                .O_LP_EN        (mipi_csi_rx_lp_en      ), // output
                .O_LP_AV_EN     (mipi_csi_rx_lp_av_en   ), // output
                .O_ECC_OK       (mipi_csi_rx_ecc_ok     ), // output
                .O_ECC          (mipi_csi_rx_ecc        ), // output [7:0]
                .O_WC           (mipi_csi_rx_wc         ), // output [15:0]
                .O_VC           (mipi_csi_rx_vc         ), // output [1:0]
                .O_DT           (mipi_csi_rx_dt         ), // output [5:0]
                .O_PAYLOAD_DV   (mipi_csi_rx_payload_dv ), // output [1:0]
                .O_PAYLOAD      (mipi_csi_rx_payload    )  // output [15:0]
            );

    // MIPI Byte to Video Signal
    logic               video_fv      ;
    logic               video_lv      ;
    logic   [9:0]       video_pixel   ;
    MIPI_Byte_to_Pixel_Converter_Top
        u_MIPI_Byte_to_Pixel_Converter_Top
            (
                .I_RSTN         (~in_reset              ),  // input
                .I_BYTE_CLK     (mipi_dphy_rx_clk       ),  // input
                .I_PIXEL_CLK    (out_clk                ),  // input
                .I_SP_EN        (mipi_csi_rx_sp_en      ),  // input
                .I_LP_AV_EN     (mipi_csi_rx_lp_av_en   ),  // input
                .I_DT           (mipi_csi_rx_dt         ),  // input [5:0]
                .I_WC           (mipi_csi_rx_wc         ),  // input [15:0]
                .I_PAYLOAD_DV   (mipi_csi_rx_payload_dv ),  // input [1:0]
                .I_PAYLOAD      (mipi_csi_rx_payload    ),  // input [15:0]
                .O_FV           (video_fv               ),  // output
                .O_LV           (video_lv               ),  // output
                .O_PIXEL        (video_pixel            )   // output [9:0]
            );

    // Remove Embedded data line
    logic [1:0]     out_y_count ;
    logic           out_lv_prev ;
    always_ff @(posedge out_clk) begin
        out_lv_prev <= video_lv;
        if ( video_fv == 1'b0 ) begin
            out_y_count <= '0;
        end
        else if ( {out_lv_prev, video_lv} == 2'b10 && !out_y_count[1] ) begin
            out_y_count <= out_y_count + 1;
        end
        out_fv    <= video_fv    ;
        out_lv    <= video_lv && out_y_count[1];
        out_pixel <= video_pixel ;
    end

endmodule


`default_nettype wire


// End of file
