
`timescale 1ns / 1ps
`default_nettype none

module imx219_mipi_rx_4lane
        (
            input   var logic               in_reset    ,

            inout   tri logic               mipi_clk_p  ,   // 912MHz
            inout   tri logic               mipi_clk_n  ,
            inout   tri logic   [3:0]       mipi_data_p ,
            inout   tri logic   [3:0]       mipi_data_n ,

            input   var logic               out_clk     ,
            output  var logic               out_fv      ,
            output  var logic               out_lv      ,
            output  var logic   [3:0][9:0]  out_pixel   
        );


    // ---------------------------------
    //  MIPI CSI2 RX
    // ---------------------------------

    logic           dphy_rx_clk             ;
    logic           dphy_drst_n             ;

    logic   [15:0]  dphy_d0ln_hsrxd         ;
    logic   [15:0]  dphy_d1ln_hsrxd         ;
    logic   [15:0]  dphy_d2ln_hsrxd         ;
    logic   [15:0]  dphy_d3ln_hsrxd         ;
    logic   [3:0]   dphy_hsrxd_vld          ;
    logic   [3:0]   dphy_hsrx_odten         ;

    logic   [1:0]   dphy_di_lprxck          ;
    logic   [1:0]   dphy_di_lprx0           ;
    logic   [1:0]   dphy_di_lprx1           ;
    logic   [1:0]   dphy_di_lprx2           ;
    logic   [1:0]   dphy_di_lprx3           ;

    logic           dphy_deskew_error       ;
    logic           dphy_d0ln_deskew_done   ;
    logic           dphy_d1ln_deskew_done   ;
    logic           dphy_d2ln_deskew_done   ;
    logic           dphy_d3ln_deskew_done   ;

    Gowin_MIPI_DPHY_RX
        u_MIPI_DPHY_RX
            (
                .ck_n               (mipi_clk_n             ),  //inout
                .ck_p               (mipi_clk_p             ),  //inout
                .rx0_n              (mipi_data_n[0]         ),  //inout
                .rx0_p              (mipi_data_p[0]         ),  //inout
                .rx1_n              (mipi_data_n[1]         ),  //inout
                .rx1_p              (mipi_data_p[1]         ),  //inout
                .rx2_n              (mipi_data_n[2]         ),  //inout
                .rx2_p              (mipi_data_p[2]         ),  //inout
                .rx3_n              (mipi_data_n[3]         ),  //inout
                .rx3_p              (mipi_data_p[3]         ),  //inout

                .rx_clk_o           (dphy_rx_clk            ),  //output
                .rx_clk_1x          (dphy_rx_clk            ),  //input

                .drst_n             (dphy_drst_n            ),  //input
                .pwron              (1'b1                   ),  //input
                .reset              (in_reset               ),  //input
                .hsrx_stop          (1'b0                   ),  //input

                .hs_8bit_mode       (1'b1                   ),  //input
                .rx_invert          (1'b0                   ),  //input
                .byte_lendian       (1'b1                   ),  //input
                .lalign_en          (1'b1                   ),  //input

                .walign_by          (1'b0                   ),  //input
                .one_byte0_match    (1'b0                   ),  //input
                .word_lendian       (1'b1                   ),  //input
                .fifo_rd_std        (3'b001                 ),  //input
                .walign_dvld        (1'b0                   ),  //input

                .hsrx_en_ck         (1'b1                   ),  //input
                .d0ln_hsrx_dren     (1'b1                   ),  //input
                .d1ln_hsrx_dren     (1'b1                   ),  //input
                .d2ln_hsrx_dren     (1'b1                   ),  //input
                .d3ln_hsrx_dren     (1'b1                   ),  //input
                .hsrx_odten_ck      (1'b1                   ),  //input
                .hsrx_odten_d0      (dphy_hsrx_odten[0]     ),  //input
                .hsrx_odten_d1      (dphy_hsrx_odten[1]     ),  //input
                .hsrx_odten_d2      (dphy_hsrx_odten[2]     ),  //input
                .hsrx_odten_d3      (dphy_hsrx_odten[3]     ),  //input
                .d0ln_hsrxd_vld     (dphy_hsrxd_vld[0]      ),  //output
                .d1ln_hsrxd_vld     (dphy_hsrxd_vld[1]      ),  //output
                .d2ln_hsrxd_vld     (dphy_hsrxd_vld[2]      ),  //output
                .d3ln_hsrxd_vld     (dphy_hsrxd_vld[3]      ),  //output
                .d0ln_hsrxd         (dphy_d0ln_hsrxd        ),  //output
                .d1ln_hsrxd         (dphy_d1ln_hsrxd        ),  //output
                .d2ln_hsrxd         (dphy_d2ln_hsrxd        ),  //output
                .d3ln_hsrxd         (dphy_d3ln_hsrxd        ),  //output

                .lprx_en_ck         (1'b1                   ),  //input
                .lprx_en_d0         (1'b1                   ),  //input
                .lprx_en_d1         (1'b1                   ),  //input
                .lprx_en_d2         (1'b1                   ),  //input
                .lprx_en_d3         (1'b1                   ),  //input
                .di_lprxck_n        (dphy_di_lprxck[0]      ),  //output
                .di_lprxck_p        (dphy_di_lprxck[1]      ),  //output
                .di_lprx0_n         (dphy_di_lprx0[0]       ),  //output
                .di_lprx0_p         (dphy_di_lprx0[1]       ),  //output
                .di_lprx1_n         (dphy_di_lprx1[0]       ),  //output
                .di_lprx1_p         (dphy_di_lprx1[1]       ),  //output
                .di_lprx2_n         (dphy_di_lprx2[0]       ),  //output
                .di_lprx2_p         (dphy_di_lprx2[1]       ),  //output
                .di_lprx3_n         (dphy_di_lprx3[0]       ),  //output
                .di_lprx3_p         (dphy_di_lprx3[1]       ),  //output

                .lptx_en_ck         (1'b0                   ),  //input
                .lptx_en_d0         (1'b0                   ),  //input
                .lptx_en_d1         (1'b0                   ),  //input
                .lptx_en_d2         (1'b0                   ),  //input
                .lptx_en_d3         (1'b0                   ),  //input
                .do_lptxck_n        (1'b0                   ),  //input
                .do_lptxck_p        (1'b0                   ),  //input
                .do_lptx0_n         (1'b0                   ),  //input
                .do_lptx0_p         (1'b0                   ),  //input
                .do_lptx1_n         (1'b0                   ),  //input
                .do_lptx1_p         (1'b0                   ),  //input
                .do_lptx2_n         (1'b0                   ),  //input
                .do_lptx2_p         (1'b0                   ),  //input
                .do_lptx3_n         (1'b0                   ),  //input
                .do_lptx3_p         (1'b0                   ),  //input

                .deskew_by          (1'b1                   ),  //input
                .deskew_en_oedge    (1'b0                   ),  //input
                .deskew_req         (1'b0                   ),  //input
                .deskew_lnsel       ('0                     ),  //input [2:0]
                .deskew_lsb_mode    ('0                     ),  //input [1:0]
                .deskew_m           ('0                     ),  //input [2:0]
                .deskew_mset        ('0                     ),  //input [6:0]
                .deskew_mth         ('0                     ),  //input [12:0]
                .deskew_owval       ('0                     ),  //input [6:0]
                .deskew_half_opening('0                     ),  //input [5:0]
                .deskew_oclkedg_en  (1'b0                   ),  //input
                .deskew_error       (dphy_deskew_error      ), //output
                .d0ln_deskew_done   (dphy_d0ln_deskew_done  ), //output
                .d1ln_deskew_done   (dphy_d1ln_deskew_done  ), //output
                .d2ln_deskew_done   (dphy_d2ln_deskew_done  ), //output
                .d3ln_deskew_done   (dphy_d3ln_deskew_done  ), //output

                .eqcs_ck            (3'b100                 ),  //input [2:0]
                .eqcs_lane0         (3'b100                 ),  //input [2:0]
                .eqcs_lane1         (3'b100                 ),  //input [2:0]
                .eqcs_lane2         (3'b100                 ),  //input [2:0]
                .eqcs_lane3         (3'b100                 ),  //input [2:0]
                .eqrs_ck            (3'b100                 ),  //input [2:0]
                .eqrs_lane0         (3'b100                 ),  //input [2:0]
                .eqrs_lane1         (3'b100                 ),  //input [2:0]
                .eqrs_lane2         (3'b100                 ),  //input [2:0]
                .eqrs_lane3         (3'b100                 ),  //input [2:0]
                .hsrx_dlydir_ck     (1'b0                   ),  //input
                .hsrx_dlydir_lane0  (1'b0                   ),  //input
                .hsrx_dlydir_lane1  (1'b0                   ),  //input
                .hsrx_dlydir_lane2  (1'b0                   ),  //input
                .hsrx_dlydir_lane3  (1'b0                   ),  //input
                .hsrx_dlyldn_ck     (1'b0                   ),  //input
                .hsrx_dlyldn_lane0  (1'b0                   ),  //input
                .hsrx_dlyldn_lane1  (1'b0                   ),  //input
                .hsrx_dlyldn_lane2  (1'b0                   ),  //input
                .hsrx_dlyldn_lane3  (1'b0                   ),  //input
                .hsrx_dlymv_ck      (1'b0                   ),  //input
                .hsrx_dlymv_lane0   (1'b0                   ),  //input
                .hsrx_dlymv_lane1   (1'b0                   ),  //input
                .hsrx_dlymv_lane2   (1'b0                   ),  //input
                .hsrx_dlymv_lane3   (1'b0                   )   //input
            );

    logic               dphy_byte_ready  ;
    logic   [7:0]       dphy_byte_d0     ;
    logic   [7:0]       dphy_byte_d1     ;
    logic   [7:0]       dphy_byte_d2     ;
    logic   [7:0]       dphy_byte_d3     ;
    logic   [1:0]       dphy_lp0_reg_0   = 2'b11;
    logic   [1:0]       dphy_lp0_reg_1   = 2'b11;
    logic               dphy_odt_en_msk  = '0;
    logic               dphy_hsrx_en_msk = 1'b0;
    logic   [5:0]       dphy_hsrx_cnt    = 'b0;
    logic               dphy_reg3to1     = 1'b0;

    wire logic          dphy_from0to3    = (dphy_lp0_reg_1==0)&(dphy_lp0_reg_0==3);
    wire logic          dphy_from1to0    = (dphy_lp0_reg_1==1)&(dphy_lp0_reg_0==0);
    wire logic          dphy_from1to2    = (dphy_lp0_reg_1==1)&(dphy_lp0_reg_0==2);
    wire logic          dphy_from1to3    = (dphy_lp0_reg_1==1)&(dphy_lp0_reg_0==3);
    wire logic          dphy_from3to1    = (dphy_lp0_reg_1==3)&(dphy_lp0_reg_0==1);
    wire logic          dphy_fromXto3    = (dphy_lp0_reg_1!=3)&(dphy_lp0_reg_0==3);
    wire logic          dphy_from1toX    = (dphy_lp0_reg_1==1)&(dphy_lp0_reg_0!=1);
    wire logic  [ 3:0]  dphy_odt_en      = {(dphy_di_lprx3==0), (dphy_di_lprx2==0), (dphy_di_lprx1==0), (dphy_di_lprx0==0)} & {4{dphy_odt_en_msk}};

    always_ff @(posedge dphy_rx_clk or posedge in_reset) begin
        if      (in_reset)            dphy_odt_en_msk <= 'b0;
        else if (~dphy_odt_en_msk)    dphy_odt_en_msk <= dphy_from3to1;
        else if (1)                   dphy_odt_en_msk <= !(dphy_from1to2|dphy_from1to3|dphy_fromXto3);

        if      (in_reset)            dphy_reg3to1 <= 'b0;
        else if (~dphy_reg3to1)       dphy_reg3to1 <= dphy_from3to1;
        else if (1)                   dphy_reg3to1 <= ~dphy_from1toX;

        if      (in_reset)            dphy_hsrx_cnt <= 'b0;
        else if (|dphy_odt_en)        dphy_hsrx_cnt <= 6'd10;
        else if (dphy_hsrx_cnt>0)     dphy_hsrx_cnt <= dphy_hsrx_cnt - 6'd1;
    end

    always_ff @(posedge dphy_rx_clk) begin
        dphy_lp0_reg_0   <= dphy_di_lprx0;
        dphy_lp0_reg_1   <= dphy_lp0_reg_0;
        dphy_drst_n      <= ~(dphy_reg3to1&dphy_from1to0);
        dphy_hsrx_en_msk <= (dphy_hsrx_cnt>0);
        dphy_byte_ready  <= dphy_hsrx_en_msk & dphy_hsrxd_vld[0];
        dphy_byte_d0     <= dphy_d0ln_hsrxd[7:0];
        dphy_byte_d1     <= dphy_d1ln_hsrxd[7:0];
        dphy_byte_d2     <= dphy_d3ln_hsrxd[7:0];
        dphy_byte_d3     <= dphy_d2ln_hsrxd[7:0];
    end
    assign dphy_hsrx_odten = {(dphy_di_lprx3==0), (dphy_di_lprx2==0), (dphy_di_lprx1==0), (dphy_di_lprx0==0)} & {4{dphy_odt_en_msk}};


    // MIPI CSI RX
    logic               mipi_csi_rx_sp_en       /* synthesis syn_keep = 1 */;
    logic               mipi_csi_rx_lp_en       /* synthesis syn_keep = 1 */;
    logic               mipi_csi_rx_lp_av_en    /* synthesis syn_keep = 1 */;
    logic               mipi_csi_rx_ecc_ok      ;
    logic   [15:0]      mipi_csi_rx_wc          ;
    logic   [ 1:0]      mipi_csi_rx_vc          ;
    logic   [ 5:0]      mipi_csi_rx_dt          ;
    logic   [ 7:0]      mipi_csi_rx_ecc         ;
    logic   [ 3:0]      mipi_csi_rx_payload_dv  /* synthesis syn_keep = 1 */;
    logic   [31:0]      mipi_csi_rx_payload     /* synthesis syn_keep = 1 */;

    MIPI_DSI_CSI2_RX_Top
        u_MIPI_DSI_CSI2_RX
            (
                .I_RSTN         (~in_reset              ),  //input
                .I_BYTE_CLK     (dphy_rx_clk            ),  //input
                .I_REF_DT       (6'h2b                  ),  //input [5:0]
                .I_READY        (dphy_byte_ready        ),  //input
                .I_DATA0        (dphy_byte_d0           ),  //input [7:0]
                .I_DATA1        (dphy_byte_d1           ),  //input [7:0]
                .I_DATA2        (dphy_byte_d2           ),  //input [7:0]
                .I_DATA3        (dphy_byte_d3           ),  //input [7:0]
                .O_SP_EN        (mipi_csi_rx_sp_en      ),  //output
                .O_LP_EN        (mipi_csi_rx_lp_en      ),  //output
                .O_LP_AV_EN     (mipi_csi_rx_lp_av_en   ),  //output
                .O_ECC_OK       (mipi_csi_rx_ecc_ok     ),  //output
                .O_ECC          (mipi_csi_rx_ecc        ),  //output [7:0]
                .O_WC           (mipi_csi_rx_wc         ),  //output [15:0]
                .O_VC           (mipi_csi_rx_vc         ),  //output [1:0]
                .O_DT           (mipi_csi_rx_dt         ),  //output [5:0]
                .O_PAYLOAD_DV   (mipi_csi_rx_payload_dv ),  //output [3:0]
                .O_PAYLOAD      (mipi_csi_rx_payload    )   //output [31:0]
            );

    // MIPI Byte to Video Signal
    logic               video_fv      ;
    logic               video_lv      ;
    logic   [3:0][9:0]  video_pixel   ;
    MIPI_Byte_to_Pixel_Converter_Top
        u_MIPI_Byte_to_Pixel_Converter_Top
            (
                .I_RSTN         (~in_reset              ),  //input
                .I_BYTE_CLK     (dphy_rx_clk            ),  //input
                .I_PIXEL_CLK    (out_clk                ),  //input
                .I_SP_EN        (mipi_csi_rx_sp_en      ),  //input
                .I_LP_AV_EN     (mipi_csi_rx_lp_av_en   ),  //input
                .I_DT           (mipi_csi_rx_dt         ),  //input [5:0]
                .I_WC           (mipi_csi_rx_wc         ),  //input [15:0]
                .I_PAYLOAD_DV   (mipi_csi_rx_payload_dv ),  //input [3:0]
                .I_PAYLOAD      (mipi_csi_rx_payload    ),  //input [31:0]
                .O_FV           (video_fv               ),  //output
                .O_LV           (video_lv               ),  //output
                .O_PIXEL        (video_pixel            )   //output [39:0]
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
