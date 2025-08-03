
`timescale 1ns / 1ps
`default_nettype none

module imx219_mipi_rx
        #(
            parameter   bit     DEVICE          = "RTL" ,
            parameter   bit     SIMULATION      = 0     ,
            parameter   bit     DEBUG           = 0     
        )
        (
            input   var logic           in_reset    ,

            inout   tri logic           mipi_clk_p  ,   // 912MHz
            inout   tri logic           mipi_clk_n  ,
            inout   tri logic   [1:0]   mipi_data_p ,
            inout   tri logic   [1:0]   mipi_data_n ,

            jelly3_axi4s_if.m           m_axi4s     
        );

    // ---------------------------------
    //  parameters
    // ---------------------------------
/*
    localparam  int     CAM_WIDTH  = 1280                   ;
    localparam  int     CAM_HEIGHT = 720                    ;
    localparam  int     CAM_H_BITS = $clog2(CAM_WIDTH )     ;
    localparam  int     CAM_V_BITS = $clog2(CAM_HEIGHT)     ;
    localparam  type    cam_h_t    = logic [CAM_H_BITS-1:0] ;
    localparam  type    cam_v_t    = logic [CAM_V_BITS-1:0] ;
*/

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
                .ck_n               (mipi_clk_n                 ),  // inout ck_n
                .ck_p               (mipi_clk_p                 ),  // inout ck_p
                .rx0_n              (mipi_data_n[0]             ),  // inout rx0_n
                .rx0_p              (mipi_data_p[0]             ),  // inout rx0_p
                .rx1_n              (mipi_data_n[1]             ),  // inout rx1_n
                .rx1_p              (mipi_data_p[1]             ),  // inout rx1_p

                .rx_clk_o           (mipi_dphy_rx_clk           ),  // output rx_clk_o
                .rx_clk_1x          (mipi_dphy_rx_clk           ),  // input rx_clk_1x

                .drst_n             (mipi_dphy_drst_n           ),  // input drst_n
                .pwron              (1'b1                       ),  // input pwron
                .reset              (in_reset                   ),  // input reset
                .hsrx_stop          (1'b0                       ),  // input hsrx_stop

                .hs_8bit_mode       (1'b1                       ),  // input hs_8bit_mode
                .rx_invert          (1'b0                       ),  // input rx_invert
                .byte_lendian       (1'b1                       ),  // input byte_lendian
                .lalign_en          (1'b1                       ),  // input lalign_en

                .walign_by          (1'b0                       ),  // input walign_by
                .one_byte0_match    (1'b0                       ),  // input one_byte0_match
                .word_lendian       (1'b1                       ),  // input word_lendian
                .fifo_rd_std        (3'b001                     ),  // input [2:0] fifo_rd_std
                .walign_dvld        (1'b0                       ),  // input walign_dvld

                .hsrx_en_ck         (1'b1                       ),  // input hsrx_en_ck
                .d0ln_hsrx_dren     (1'b1                       ),  // input d0ln_hsrx_dren
                .d1ln_hsrx_dren     (1'b1                       ),  // input d1ln_hsrx_dren
                .hsrx_odten_ck      (1'b1                       ),  // input hsrx_odten_ck
                .hsrx_odten_d0      (mipi_dphy_hsrx_odten[0]    ),  // input hsrx_odten_d0
                .hsrx_odten_d1      (mipi_dphy_hsrx_odten[1]    ),  // input hsrx_odten_d1
                .d0ln_hsrxd_vld     (mipi_dphy_hsrxd_vld[0]     ),  // output d0ln_hsrxd_vld
                .d1ln_hsrxd_vld     (mipi_dphy_hsrxd_vld[1]     ),  // output d1ln_hsrxd_vld
                .d0ln_hsrxd         (mipi_dphy_d0ln_hsrxd       ),  // output [15:0] d0ln_hsrxd
                .d1ln_hsrxd         (mipi_dphy_d1ln_hsrxd       ),  // output [15:0] d1ln_hsrxd

                .lprx_en_ck         (1'b1                       ),  // input lprx_en_ck
                .lprx_en_d0         (1'b1                       ),  // input lprx_en_d0
                .lprx_en_d1         (1'b1                       ),  // input lprx_en_d1
                .di_lprxck_n        (mipi_dphy_di_lprxck[0]     ),  // output di_lprxck_n
                .di_lprxck_p        (mipi_dphy_di_lprxck[1]     ),  // output di_lprxck_p
                .di_lprx0_n         (mipi_dphy_di_lprx0[0]      ),  // output di_lprx0_n
                .di_lprx0_p         (mipi_dphy_di_lprx0[1]      ),  // output di_lprx0_p
                .di_lprx1_n         (mipi_dphy_di_lprx1[0]      ),  // output di_lprx1_n
                .di_lprx1_p         (mipi_dphy_di_lprx1[1]      ),  // output di_lprx1_p

                .lptx_en_ck         (1'b0                       ),  // input lptx_en_ck
                .lptx_en_d0         (1'b0                       ),  // input lptx_en_d0
                .lptx_en_d1         (1'b0                       ),  // input lptx_en_d1
                .do_lptxck_n        (1'b0                       ),  // input do_lptxck_n
                .do_lptxck_p        (1'b0                       ),  // input do_lptxck_p
                .do_lptx0_n         (1'b0                       ),  // input do_lptx0_n
                .do_lptx0_p         (1'b0                       ),  // input do_lptx0_p
                .do_lptx1_n         (1'b0                       ),  // input do_lptx1_n
                .do_lptx1_p         (1'b0                       ),  // input do_lptx1_p

                .deskew_by          (1'b1                       ),  // input deskew_by
                .deskew_en_oedge    (1'b0                       ),  // input deskew_en_oedge
                .deskew_req         (1'b0                       ),  // input deskew_req
                .deskew_lnsel       ('0                         ),  // input [2:0] deskew_lnsel
                .deskew_lsb_mode    ('0                         ),  // input [1:0] deskew_lsb_mode
                .deskew_m           ('0                         ),  // input [2:0] deskew_m
                .deskew_mset        ('0                         ),  // input [6:0] deskew_mset
                .deskew_mth         ('0                         ),  // input [12:0] deskew_mth
                .deskew_owval       ('0                         ),  // input [6:0] deskew_owval
                .deskew_half_opening('0                         ),  // input [5:0] deskew_half_opening
                .deskew_oclkedg_en  (1'b0                       ),  // input deskew_oclkedg_en
                .deskew_error       (mipi_dphy_deskew_error     ),  // output deskew_error
                .d0ln_deskew_done   (mipi_dphy_d0ln_deskew_done ),  // output d0ln_deskew_done
                .d1ln_deskew_done   (mipi_dphy_d1ln_deskew_done ),  // output d1ln_deskew_done

                .eqcs_ck            (3'b100                     ),  // input [2:0] eqcs_ck
                .eqcs_lane0         (3'b100                     ),  // input [2:0] eqcs_lane0
                .eqcs_lane1         (3'b100                     ),  // input [2:0] eqcs_lane1
                .eqrs_ck            (3'b100                     ),  // input [2:0] eqrs_ck
                .eqrs_lane0         (3'b100                     ),  // input [2:0] eqrs_lane0
                .eqrs_lane1         (3'b100                     ),  // input [2:0] eqrs_lane1
                .hsrx_dlydir_ck     (1'b0                       ),  // input hsrx_dlydir_ck
                .hsrx_dlydir_lane0  (1'b0                       ),  // input hsrx_dlydir_lane0
                .hsrx_dlydir_lane1  (1'b0                       ),  // input hsrx_dlydir_lane1
                .hsrx_dlyldn_ck     (1'b0                       ),  // input hsrx_dlyldn_ck
                .hsrx_dlyldn_lane0  (1'b0                       ),  // input hsrx_dlyldn_lane0
                .hsrx_dlyldn_lane1  (1'b0                       ),  // input hsrx_dlyldn_lane1
                .hsrx_dlymv_ck      (1'b0                       ),  // input hsrx_dlymv_ck
                .hsrx_dlymv_lane0   (1'b0                       ),  // input hsrx_dlymv_lane0
                .hsrx_dlymv_lane1   (1'b0                       )   // input hsrx_dlymv_lane1
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



    wire    logic   dphy_clk   = mipi_dphy_rx_clk;
    wire    logic   dphy_reset;
    jelly3_reset
            #(
                .IN_LOW_ACTIVE      (0              ),
                .OUT_LOW_ACTIVE     (0              ),
                .INPUT_REGS         (2              ),
                .ADDITIONAL_CYCLE   (0              ) 
            )
        u_reset
            (
                .clk                (dphy_clk       ),
                .cke                (1'b1           ),
                .in_reset           (in_reset       ),
                .out_reset          (dphy_reset     )
            );
    
    

    // ----------------------------------------
    //  DPHY Recv
    // ----------------------------------------

    localparam LANES = 2;

    jelly3_axi4s_if
            #(
                .DATA_BITS  (2*8            ),
                .DEBUG      (DEBUG          )
            )
        axi4s_rx_dphy
            (
                .aresetn    (~dphy_reset    ),
                .aclk       (dphy_clk       ),
                .aclken     (1'b1           )
            );

    always_ff @(posedge dphy_clk ) begin
        if ( dphy_reset ) begin
            axi4s_rx_dphy.tuser  <= 1'b1;
            axi4s_rx_dphy.tdata  <= 'x  ;
            axi4s_rx_dphy.tvalid <= '0  ;
        end else begin
            axi4s_rx_dphy.tuser  <= ~axi4s_rx_dphy.tvalid;
            axi4s_rx_dphy.tdata  <= {mipi_dphy_byte_d1, mipi_dphy_byte_d0};
            axi4s_rx_dphy.tvalid <= mipi_dphy_byte_ready;
        end
    end
    assign axi4s_rx_dphy.tlast = (axi4s_rx_dphy.tvalid && ~mipi_dphy_byte_ready);
//  assign axi4s_rx_dphy.tvalid = mipi_dphy_byte_ready;


    // ----------------------------------------
    //  DPHY Recv
    // ----------------------------------------

    // rx_fifo
    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (LANES*8            )
            )
        axi4s_rx_fifo
            (
                .aresetn        (m_axi4s.aresetn    ),
                .aclk           (m_axi4s.aclk       ),
                .aclken         (m_axi4s.aclken     )
            );

    jelly3_axi4s_fifo
            #(
                .ASYNC          (1                  ),
                .PTR_BITS       (8                  ),
                .RAM_TYPE       ("block"            ),
                .DOUT_REG       (1                  ),
                .S_REG          (1                  ),
                .M_REG          (1                  )
            )
        u_axi4s_fifo_rx
            (
                .s_axi4s        (axi4s_rx_dphy.s    ),
                .m_axi4s        (axi4s_rx_fifo.m    ),

                .s_free_size    (                   ),
                .m_data_size    (                   )
            );
    

    // ----------------------------------------
    //  CSI-2 RX
    // ----------------------------------------

    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (LANES*8            )
            )
        axi4s_rx_packet
            (
                .aresetn        (m_axi4s.aresetn    ),
                .aclk           (m_axi4s.aclk       ),
                .aclken         (m_axi4s.aclken     )
            );
    
    logic           rx_frame_start      ;
    logic           rx_frame_end        ;
    logic           rx_ecc_corrected    ;
    logic           rx_ecc_error        ;
    logic           rx_ecc_valid        ;
    logic           rx_crc_error        ;
    logic           rx_crc_valid        ;
    logic           rx_packet_lost      ;

    jelly3_mipi_csi2_rx_packet_2lane
        u_mipi_csi2_rx_packet_2lane
            (
                .param_data_type    (8'h2b              ),
                
                .out_frame_start    (rx_frame_start     ),
                .out_frame_end      (rx_frame_end       ),
                .out_ecc_corrected  (rx_ecc_corrected   ),
                .out_ecc_error      (rx_ecc_error       ),
                .out_ecc_valid      (rx_ecc_valid       ),
                .out_crc_error      (rx_crc_error       ),
                .out_crc_valid      (rx_crc_valid       ),
                .out_packet_lost    (rx_packet_lost     ),

                .s_axi4s            (axi4s_rx_fifo.s    ),
                .m_axi4s            (axi4s_rx_packet.m  )
            );

    // to RAW10
    /*
    jelly3_mipi_csi2_rx_byte_to_raw10
        u_mipi_csi2_rx_byte_to_raw10
            (
                .s_axi4s        (axi4s_rx_packet.s  ),
                .m_axi4s        (m_axi4s            )
            );
    */

    assign m_axi4s.tuser  = axi4s_rx_packet.tuser;
    assign m_axi4s.tlast  = axi4s_rx_packet.tlast;
    assign m_axi4s.tdata  = axi4s_rx_packet.tdata;
    assign m_axi4s.tvalid = axi4s_rx_packet.tvalid;
    assign axi4s_rx_packet.tready = m_axi4s.tready;

/*
    // MIPI CSI RX
    logic           mipi_ecc_corrected  ;
    logic           mipi_ecc_error      ;
    logic           mipi_ecc_valid      ;
    logic           mipi_crc_error      ;
    logic           mipi_crc_valid      ;
    logic           mipi_packet_lost    ;
    logic           mipi_fifo_overflow  ;
    jelly2_mipi_csi2_rx
            #(
                .LANES              (2                      ),
                .DATA_WIDTH         (10                     ),
                .M_FIFO_ASYNC       (1                      ),
                .M_FIFO_PTR_WIDTH   (10                     )
            )
        u_mipi_csi2_rx
            (
                .aresetn            (~sys_reset             ),
                .aclk               (sys_clk250             ),

                .param_data_type    (8'h2b                  ),

                .ecc_corrected      (mipi_ecc_corrected     ),
                .ecc_error          (mipi_ecc_error         ),
                .ecc_valid          (mipi_ecc_valid         ),
                .crc_error          (mipi_crc_error         ),
                .crc_valid          (mipi_crc_valid         ),
                .packet_lost        (mipi_packet_lost       ),
                .fifo_overflow      (mipi_fifo_overflow     ),
                
                .rxreseths          (mipi_dphy_rx_reset     ),
                .rxbyteclkhs        (mipi_dphy_rx_clk       ),
                .rxdatahs           ({mipi_dphy_byte_d1, mipi_dphy_byte_d0  }),
                .rxvalidhs          ({mipi_dphy_byte_ready, mipi_dphy_byte_ready }),
                .rxactivehs         ({mipi_dphy_byte_ready, mipi_dphy_byte_ready}),
                .rxsynchs           ('0                                         ),
                
                .m_axi4s_aresetn    (axi4s_cam_aresetn  ),
                .m_axi4s_aclk       (axi4s_cam_aclk     ),
                .m_axi4s_tuser      (axi4s_csi2.tuser   ),
                .m_axi4s_tlast      (axi4s_csi2.tlast   ),
                .m_axi4s_tdata      (axi4s_csi2.tdata   ),
                .m_axi4s_tvalid     (axi4s_csi2.tvalid  ),
                .m_axi4s_tready     (1'b1)  // (axi4s_csi2.tready)
            );

    // MIPI CSI RX
    logic               mipi_csi_rx_sp_en       ;
    logic               mipi_csi_rx_lp_en       ;
    logic               mipi_csi_rx_lp_av_en    ;
    logic               mipi_csi_rx_ecc_ok      ;
    logic   [15:0]      mipi_csi_rx_wc          ;
    logic   [ 1:0]      mipi_csi_rx_vc          ;
    logic   [ 5:0]      mipi_csi_rx_dt          ;
    logic   [ 7:0]      mipi_csi_rx_ecc         ;
    logic   [ 1:0]      mipi_csi_rx_payload_dv  ;
    logic   [15:0]      mipi_csi_rx_payload     ;

    MIPI_DSI_CSI2_RX_Top
        u_MIPI_DSI_CSI2_RX
            (
                .I_RSTN         (~in_reset              ), // input I_RSTN
                .I_BYTE_CLK     (mipi_dphy_rx_clk       ), // input I_BYTE_CLK
                .I_REF_DT       (6'h2b                  ), // input [5:0] I_REF_DT  RAW10
                .I_READY        (mipi_dphy_byte_ready   ), // input I_READY
                .I_DATA0        (mipi_dphy_byte_d0      ), // input [7:0] I_DATA0
                .I_DATA1        (mipi_dphy_byte_d1      ), // input [7:0] I_DATA1
                .O_SP_EN        (mipi_csi_rx_sp_en      ), // output O_SP_EN
                .O_LP_EN        (mipi_csi_rx_lp_en      ), // output O_LP_EN
                .O_LP_AV_EN     (mipi_csi_rx_lp_av_en   ), // output O_LP_AV_EN
                .O_ECC_OK       (mipi_csi_rx_ecc_ok     ), // output O_ECC_OK
                .O_ECC          (mipi_csi_rx_ecc        ), // output [7:0] O_ECC
                .O_WC           (mipi_csi_rx_wc         ), // output [15:0] O_WC
                .O_VC           (mipi_csi_rx_vc         ), // output [1:0] O_VC
                .O_DT           (mipi_csi_rx_dt         ), // output [5:0] O_DT
                .O_PAYLOAD_DV   (mipi_csi_rx_payload_dv ), // output [1:0] O_PAYLOAD_DV
                .O_PAYLOAD      (mipi_csi_rx_payload    )  // output [15:0] O_PAYLOAD
            );

    // MIPI Byte to Video Signal
    logic               video_fv      ;
    logic               video_lv      ;
    logic   [9:0]       video_pixel   ;
    MIPI_Byte_to_Pixel_Converter_Top
        u_MIPI_Byte_to_Pixel_Converter_Top
            (
                .I_RSTN         (~in_reset              ),  // input I_RSTN
                .I_BYTE_CLK     (mipi_dphy_rx_clk       ),  // input I_BYTE_CLK
                .I_PIXEL_CLK    (out_clk                ),  // input I_PIXEL_CLK
                .I_SP_EN        (mipi_csi_rx_sp_en      ),  // input I_SP_EN
                .I_LP_AV_EN     (mipi_csi_rx_lp_av_en   ),  // input I_LP_AV_EN
                .I_DT           (mipi_csi_rx_dt         ),  // input [5:0] I_DT
                .I_WC           (mipi_csi_rx_wc         ),  // input [15:0] I_WC
                .I_PAYLOAD_DV   (mipi_csi_rx_payload_dv ),  // input [1:0] I_PAYLOAD_DV
                .I_PAYLOAD      (mipi_csi_rx_payload    ),  // input [15:0] I_PAYLOAD
                .O_FV           (video_fv               ),  // output O_FV
                .O_LV           (video_lv               ),  // output O_LV
                .O_PIXEL        (video_pixel            )   // output [9:0] O_PIXEL
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
    */

endmodule


`default_nettype wire


// End of file
