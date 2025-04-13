
`timescale 1ns / 1ps
`default_nettype none

module tang_mega_138k_pro_imx219
        #(
            parameter JFIVE_TCM_READMEMH     = 1'b1         ,
            parameter JFIVE_TCM_READMEM_FIlE = "mem.hex"    
        )
        (
            input   var logic           reset       ,
            input   var logic           clk         ,   // 50MHz

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

    logic   [15:0]  csi0_d0ln_hsrxd         ;
    logic   [15:0]  csi0_d1ln_hsrxd         ;
    logic           csi0_d0ln_hsrxd_vld     ;
    logic           csi0_d1ln_hsrxd_vld     ;
    logic           csi0_di_lprx0_n         ;
    logic           csi0_di_lprx0_p         ;
    logic           csi0_di_lprx1_n         ;
    logic           csi0_di_lprx1_p         ;
    logic           csi0_di_lprxck_n        ;
    logic           csi0_di_lprxck_p        ;
    logic           csi0_deskew_error       ;
    logic           csi0_d0ln_deskew_done   ;
    logic           csi0_d1ln_deskew_done   ;

    logic           csi0_rx_clk             ;
    logic           csi0_drst_n             ;

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
    wire    logic           csi0_rx_clk_1x           = csi0_rx_clk  ;
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

    Gowin_MIPI_DPHY_RX
        u_MIPI_DPHY_RX
            (
                .d0ln_hsrxd         (csi0_d0ln_hsrxd        ), //output [15:0] d0ln_hsrxd
                .d1ln_hsrxd         (csi0_d1ln_hsrxd        ), //output [15:0] d1ln_hsrxd
                .d0ln_hsrxd_vld     (csi0_d0ln_hsrxd_vld    ), //output d0ln_hsrxd_vld
                .d1ln_hsrxd_vld     (csi0_d1ln_hsrxd_vld    ), //output d1ln_hsrxd_vld
                .di_lprx0_n         (csi0_di_lprx0_n        ), //output di_lprx0_n
                .di_lprx0_p         (csi0_di_lprx0_p        ), //output di_lprx0_p
                .di_lprx1_n         (csi0_di_lprx1_n        ), //output di_lprx1_n
                .di_lprx1_p         (csi0_di_lprx1_p        ), //output di_lprx1_p
                .di_lprxck_n        (csi0_di_lprxck_n       ), //output di_lprxck_n
                .di_lprxck_p        (csi0_di_lprxck_p       ), //output di_lprxck_p
                .rx_clk_o           (csi0_rx_clk            ), //output rx_clk_o
                .deskew_error       (csi0_deskew_error      ), //output deskew_error
                .d0ln_deskew_done   (csi0_d0ln_deskew_done  ), //output d0ln_deskew_done
                .d1ln_deskew_done   (csi0_d1ln_deskew_done  ), //output d1ln_deskew_done
                .ck_n               (csi0_clk_n             ),  //inout ck_n
                .ck_p               (csi0_clk_p             ),  //inout ck_p
                .rx0_n              (csi0_data_n[0]         ),  //inout rx0_n
                .rx0_p              (csi0_data_p[0]         ),  //inout rx0_p
                .rx1_n              (csi0_data_n[1]         ),  //inout rx1_n
                .rx1_p              (csi0_data_p[1]         ),  //inout rx1_p
                .lprx_en_ck         (csi0_lprx_en_ck        ), //input lprx_en_ck
                .lprx_en_d0         (csi0_lprx_en_d0        ), //input lprx_en_d0
                .lprx_en_d1         (csi0_lprx_en_d1        ), //input lprx_en_d1
                .hsrx_odten_ck      (csi0_hsrx_odten_ck     ), //input hsrx_odten_ck
                .hsrx_odten_d0      (csi0_hsrx_odten_d0     ), //input hsrx_odten_d0
                .hsrx_odten_d1      (csi0_hsrx_odten_d1     ), //input hsrx_odten_d1
                .d0ln_hsrx_dren     (csi0_d0ln_hsrx_dren    ), //input d0ln_hsrx_dren
                .d1ln_hsrx_dren     (csi0_d1ln_hsrx_dren    ), //input d1ln_hsrx_dren
                .hsrx_en_ck         (csi0_hsrx_en_ck        ), //input hsrx_en_ck
                .hs_8bit_mode       (csi0_hs_8bit_mode      ), //input hs_8bit_mode
                .rx_clk_1x          (csi0_rx_clk_1x         ), //input rx_clk_1x
                .rx_invert          (csi0_rx_invert         ), //input rx_invert
                .lalign_en          (csi0_lalign_en         ), //input lalign_en
                .walign_by          (csi0_walign_by         ), //input walign_by
                .do_lptx0_n         (csi0_do_lptx0_n        ), //input do_lptx0_n
                .do_lptx0_p         (csi0_do_lptx0_p        ), //input do_lptx0_p
                .do_lptx1_n         (csi0_do_lptx1_n        ), //input do_lptx1_n
                .do_lptx1_p         (csi0_do_lptx1_p        ), //input do_lptx1_p
                .do_lptxck_n        (csi0_do_lptxck_n       ), //input do_lptxck_n
                .do_lptxck_p        (csi0_do_lptxck_p       ), //input do_lptxck_p
                .lptx_en_ck         (csi0_lptx_en_ck        ), //input lptx_en_ck
                .lptx_en_d0         (csi0_lptx_en_d0        ), //input lptx_en_d0
                .lptx_en_d1         (csi0_lptx_en_d1        ), //input lptx_en_d1
                .byte_lendian       (csi0_byte_lendian      ), //input byte_lendian
                .hsrx_stop          (csi0_hsrx_stop         ), //input hsrx_stop
                .pwron              (csi0_pwron             ), //input pwron
                .reset              (csi0_reset             ), //input reset
                .deskew_lnsel       (csi0_deskew_lnsel      ), //input [2:0] deskew_lnsel
                .deskew_mth         (csi0_deskew_mth        ), //input [12:0] deskew_mth
                .deskew_owval       (csi0_deskew_owval      ), //input [6:0] deskew_owval
                .deskew_req         (csi0_deskew_req        ), //input deskew_req
                .drst_n             (csi0_drst_n            ), //input drst_n
                .one_byte0_match    (csi0_one_byte0_match   ), //input one_byte0_match
                .word_lendian       (csi0_word_lendian      ), //input word_lendian
                .fifo_rd_std        (csi0_fifo_rd_std       ), //input [2:0] fifo_rd_std
                .deskew_by          (csi0_deskew_by         ), //input deskew_by
                .deskew_en_oedge    (csi0_deskew_en_oedge   ), //input deskew_en_oedge
                .deskew_half_opening(csi0_deskew_half_opening), //input [5:0] deskew_half_opening
                .deskew_lsb_mode    (csi0_deskew_lsb_mode   ), //input [1:0] deskew_lsb_mode
                .deskew_m           (csi0_deskew_m          ), //input [2:0] deskew_m
                .deskew_mset        (csi0_deskew_mset       ), //input [6:0] deskew_mset
                .deskew_oclkedg_en  (csi0_deskew_oclkedg_en ), //input deskew_oclkedg_en
                .eqcs_lane0         (csi0_eqcs_lane0        ), //input [2:0] eqcs_lane0
                .eqcs_lane1         (csi0_eqcs_lane1        ), //input [2:0] eqcs_lane1
                .eqcs_ck            (csi0_eqcs_ck           ), //input [2:0] eqcs_ck
                .eqrs_lane0         (csi0_eqrs_lane0        ), //input [2:0] eqrs_lane0
                .eqrs_lane1         (csi0_eqrs_lane1        ), //input [2:0] eqrs_lane1
                .eqrs_ck            (csi0_eqrs_ck           ), //input [2:0] eqrs_ck
                .hsrx_dlydir_lane0  (csi0_hsrx_dlydir_lane0 ), //input hsrx_dlydir_lane0
                .hsrx_dlydir_lane1  (csi0_hsrx_dlydir_lane1 ), //input hsrx_dlydir_lane1
                .hsrx_dlydir_ck     (csi0_hsrx_dlydir_ck    ), //input hsrx_dlydir_ck
                .hsrx_dlyldn_lane0  (csi0_hsrx_dlyldn_lane0 ), //input hsrx_dlyldn_lane0
                .hsrx_dlyldn_lane1  (csi0_hsrx_dlyldn_lane1 ), //input hsrx_dlyldn_lane1
                .hsrx_dlyldn_ck     (csi0_hsrx_dlyldn_ck    ), //input hsrx_dlyldn_ck
                .hsrx_dlymv_lane0   (csi0_hsrx_dlymv_lane0  ), //input hsrx_dlymv_lane0
                .hsrx_dlymv_lane1   (csi0_hsrx_dlymv_lane1  ), //input hsrx_dlymv_lane1
                .hsrx_dlymv_ck      (csi0_hsrx_dlymv_ck     ), //input hsrx_dlymv_ck
                .walign_dvld        (csi0_walign_dvld       ) //input walign_dvld
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
