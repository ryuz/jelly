
`timescale 1ns / 1ps
`default_nettype none

module tang_mega_138k_pro_imx219_720p
        #(
            parameter JFIVE_TCM_READMEMH     = 1'b1         ,
            parameter JFIVE_TCM_READMEM_FIlE = "mem.hex"    
        )
        (
            input   var logic           in_reset        ,
            input   var logic           in_clk50        ,   // 50MHz

            input   var logic           uart_rx         ,
            output  var logic           uart_tx         ,

            inout   tri logic           mipi0_clk_p     ,   // 912MHz
            inout   tri logic           mipi0_clk_n     ,
            inout   tri logic   [1:0]   mipi0_data_p    ,
            inout   tri logic   [1:0]   mipi0_data_n    ,
            output  var logic           mipi0_rstn      ,
            inout   tri logic           i2c_scl         ,
            inout   tri logic           i2c_sda         ,
            output  var logic   [2:0]   i2c_sel         ,

            output  var logic           dvi_tx_clk_p    ,
            output  var logic           dvi_tx_clk_n    ,
            output  var logic   [2:0]   dvi_tx_data_p   ,
            output  var logic   [2:0]   dvi_tx_data_n   ,


//          output  var logic   [7:0]   pmod0           ,
            output  var logic   [7:0]   pmod1           ,
            output  var logic   [7:0]   pmod2           ,

            input   var logic   [3:0]   push_sw_n       ,
            output  var logic   [5:0]   led_n           
        );

    // ---------------------------------
    //  parameters
    // ---------------------------------

    localparam  int     CAM_WIDTH  = 1280                   ;
    localparam  int     CAM_HEIGHT = 720                    ;
    localparam  int     CAM_H_BITS = $clog2(CAM_WIDTH )     ;
    localparam  int     CAM_V_BITS = $clog2(CAM_HEIGHT)     ;
    localparam  type    cam_h_t    = logic [CAM_H_BITS-1:0] ;
    localparam  type    cam_v_t    = logic [CAM_V_BITS-1:0] ;

    localparam  int     DVI_WIDTH  = 1280                   ;
    localparam  int     DVI_HEIGHT = 720                    ;
    localparam  int     DVI_H_BITS = $clog2(DVI_WIDTH )     ;
    localparam  int     DVI_V_BITS = $clog2(DVI_HEIGHT)     ;
    localparam  type    dvi_h_t    = logic [DVI_H_BITS-1:0] ;
    localparam  type    dvi_v_t    = logic [DVI_V_BITS-1:0] ;


    // ---------------------------------
    //  Clock and Reset
    // ---------------------------------

    logic   lock        ;
    logic   sys_clk     ;
    logic   cam_clk     ;
    Gowin_PLL
        u_Gowin_PLL
            (
                .lock       (lock       ),  //output lock
                .clkout0    (sys_clk    ),  //output clkout0
                .clkout1    (cam_clk    ),  //output clkout1
                .clkin      (in_clk50   )   //input clkin
            );

    logic   sys_reset;
    jelly_reset
            #(
                .IN_LOW_ACTIVE      (1                  ),
                .OUT_LOW_ACTIVE     (0                  ),
                .INPUT_REGS         (2                  )
            )
        u_reset_sys
            (
                .clk                (sys_clk            ),
                .in_reset           (~in_reset & lock   ),   // asyncrnous reset
                .out_reset          (sys_reset          )    // syncrnous reset
            );

    logic   cam_reset;
    jelly_reset
            #(
                .IN_LOW_ACTIVE      (1                  ),
                .OUT_LOW_ACTIVE     (0                  ),
                .INPUT_REGS         (2                  )
            )
        u_reset_cam
            (
                .clk                (cam_clk            ),
                .in_reset           (~in_reset & lock   ),   // asyncrnous reset
                .out_reset          (cam_reset          )    // syncrnous reset
            );
    
    // PLL
    logic   dvi_clk     ;
    logic   dvi_clk_x5  ;
    logic   dvi_lock    ;
    Gowin_PLL_dvi
        u_Gowin_PLL_dvi
            (
                .clkin      (in_clk50   ),
                .clkout0    (dvi_clk    ),
                .clkout1    (dvi_clk_x5 ),
                .lock       (dvi_lock   )
            );

    // reset sync
    logic   dvi_reset;
    jelly_reset
            #(
                .IN_LOW_ACTIVE      (1                      ),
                .OUT_LOW_ACTIVE     (0                      ),
                .INPUT_REGS         (2                      )
            )
        u_reset_dvi
            (
                .clk                (dvi_clk                ),
                .in_reset           (~in_reset & dvi_lock   ),   // asyncrnous reset
                .out_reset          (dvi_reset              )    // syncrnous reset
            );


    // ---------------------------------
    //  Micro controller (RISC-V)
    // ---------------------------------

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
                .reset              (sys_reset              ),
                .clk                (sys_clk                ),
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


    // UART
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
                .reset              (sys_reset          ),
                .clk                (sys_clk            ),
                
                .uart_reset         (sys_reset          ),
                .uart_clk           (sys_clk            ),
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
                .reset              (sys_reset          ),
                .clk                (sys_clk            ),
                
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
        u_iobuf_mipi0_dphy_scl
            (
                .OEN            (i2c_scl_t ),
                .I              (1'b0      ),
                .IO             (i2c_scl   ),
                .O              (i2c_scl_i )
            );

    IOBUF
        u_iobuf_mipi0_dphy_sda
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
    always_ff @(posedge sys_clk) begin
        if ( sys_reset ) begin
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


    assign mipi0_rstn = reg_gpio1[0];

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


    // ---------------------------------
    //  MIPI CSI2 RX
    // ---------------------------------

    logic           mipi0_dphy_rx_clk             ;
    logic           mipi0_dphy_drst_n             ;

    logic   [15:0]  mipi0_dphy_d0ln_hsrxd         ;
    logic   [15:0]  mipi0_dphy_d1ln_hsrxd         ;
    logic   [1:0]   mipi0_dphy_hsrxd_vld          ;
    logic   [1:0]   mipi0_dphy_hsrx_odten         ;

    logic   [1:0]   mipi0_dphy_di_lprxck          ;
    logic   [1:0]   mipi0_dphy_di_lprx0           ;
    logic   [1:0]   mipi0_dphy_di_lprx1           ;

    logic           mipi0_dphy_deskew_error       ;
    logic           mipi0_dphy_d0ln_deskew_done   ;
    logic           mipi0_dphy_d1ln_deskew_done   ;

    Gowin_MIPI_DPHY_RX
        u_MIPI_DPHY_RX
            (
                .ck_n               (mipi0_clk_n                ),  //inout ck_n
                .ck_p               (mipi0_clk_p                ),  //inout ck_p
                .rx0_n              (mipi0_data_n[0]            ),  //inout rx0_n
                .rx0_p              (mipi0_data_p[0]            ),  //inout rx0_p
                .rx1_n              (mipi0_data_n[1]            ),  //inout rx1_n
                .rx1_p              (mipi0_data_p[1]            ),  //inout rx1_p

                .rx_clk_o           (mipi0_dphy_rx_clk          ), //output rx_clk_o
                .rx_clk_1x          (mipi0_dphy_rx_clk          ), //input rx_clk_1x

                .drst_n             (mipi0_dphy_drst_n          ), //input drst_n
                .pwron              (1'b1                       ), //input pwron
                .reset              (sys_reset                  ), //input reset
                .hsrx_stop          (1'b0                       ), //input hsrx_stop

                .hs_8bit_mode       (1'b1                       ), //input hs_8bit_mode
                .rx_invert          (1'b0                       ), //input rx_invert
                .byte_lendian       (1'b1                       ), //input byte_lendian
                .lalign_en          (1'b1                       ), //input lalign_en

                .walign_by          (1'b0                       ), //input walign_by
                .one_byte0_match    (1'b0                       ), //input one_byte0_match
                .word_lendian       (1'b1                       ), //input word_lendian
                .fifo_rd_std        (3'b001                     ), //input [2:0] fifo_rd_std
                .walign_dvld        (1'b0                       ), //input walign_dvld

                .hsrx_en_ck         (1'b1                       ), //input hsrx_en_ck
                .d0ln_hsrx_dren     (1'b1                       ), //input d0ln_hsrx_dren
                .d1ln_hsrx_dren     (1'b1                       ), //input d1ln_hsrx_dren
                .hsrx_odten_ck      (1'b1                       ), //input hsrx_odten_ck
                .hsrx_odten_d0      (mipi0_dphy_hsrx_odten[0]   ), //input hsrx_odten_d0
                .hsrx_odten_d1      (mipi0_dphy_hsrx_odten[1]   ), //input hsrx_odten_d1
                .d0ln_hsrxd_vld     (mipi0_dphy_hsrxd_vld[0]    ), //output d0ln_hsrxd_vld
                .d1ln_hsrxd_vld     (mipi0_dphy_hsrxd_vld[1]    ), //output d1ln_hsrxd_vld
                .d0ln_hsrxd         (mipi0_dphy_d0ln_hsrxd      ), //output [15:0] d0ln_hsrxd
                .d1ln_hsrxd         (mipi0_dphy_d1ln_hsrxd      ), //output [15:0] d1ln_hsrxd

                .lprx_en_ck         (1'b1                       ), //input lprx_en_ck
                .lprx_en_d0         (1'b1                       ), //input lprx_en_d0
                .lprx_en_d1         (1'b1                       ), //input lprx_en_d1
                .di_lprxck_n        (mipi0_dphy_di_lprxck[0]    ), //output di_lprxck_n
                .di_lprxck_p        (mipi0_dphy_di_lprxck[1]    ), //output di_lprxck_p
                .di_lprx0_n         (mipi0_dphy_di_lprx0[0]     ), //output di_lprx0_n
                .di_lprx0_p         (mipi0_dphy_di_lprx0[1]     ), //output di_lprx0_p
                .di_lprx1_n         (mipi0_dphy_di_lprx1[0]     ), //output di_lprx1_n
                .di_lprx1_p         (mipi0_dphy_di_lprx1[1]     ), //output di_lprx1_p

                .lptx_en_ck         (1'b0                       ), //input lptx_en_ck
                .lptx_en_d0         (1'b0                       ), //input lptx_en_d0
                .lptx_en_d1         (1'b0                       ), //input lptx_en_d1
                .do_lptxck_n        (1'b0                       ), //input do_lptxck_n
                .do_lptxck_p        (1'b0                       ), //input do_lptxck_p
                .do_lptx0_n         (1'b0                       ), //input do_lptx0_n
                .do_lptx0_p         (1'b0                       ), //input do_lptx0_p
                .do_lptx1_n         (1'b0                       ), //input do_lptx1_n
                .do_lptx1_p         (1'b0                       ), //input do_lptx1_p

                .deskew_by          (1'b1                       ), //input deskew_by
                .deskew_en_oedge    (1'b0                       ), //input deskew_en_oedge
                .deskew_req         (1'b0                       ), //input deskew_req
                .deskew_lnsel       ('0                         ), //input [2:0] deskew_lnsel
                .deskew_lsb_mode    ('0                         ), //input [1:0] deskew_lsb_mode
                .deskew_m           ('0                         ), //input [2:0] deskew_m
                .deskew_mset        ('0                         ), //input [6:0] deskew_mset
                .deskew_mth         ('0                         ), //input [12:0] deskew_mth
                .deskew_owval       ('0                         ), //input [6:0] deskew_owval
                .deskew_half_opening('0                         ), //input [5:0] deskew_half_opening
                .deskew_oclkedg_en  (1'b0                       ), //input deskew_oclkedg_en
                .deskew_error       (mipi0_dphy_deskew_error    ), //output deskew_error
                .d0ln_deskew_done   (mipi0_dphy_d0ln_deskew_done), //output d0ln_deskew_done
                .d1ln_deskew_done   (mipi0_dphy_d1ln_deskew_done), //output d1ln_deskew_done

                .eqcs_ck            (3'b100                     ), //input [2:0] eqcs_ck
                .eqcs_lane0         (3'b100                     ), //input [2:0] eqcs_lane0
                .eqcs_lane1         (3'b100                     ), //input [2:0] eqcs_lane1
                .eqrs_ck            (3'b100                     ), //input [2:0] eqrs_ck
                .eqrs_lane0         (3'b100                     ), //input [2:0] eqrs_lane0
                .eqrs_lane1         (3'b100                     ), //input [2:0] eqrs_lane1
                .hsrx_dlydir_ck     (1'b0                       ), //input hsrx_dlydir_ck
                .hsrx_dlydir_lane0  (1'b0                       ), //input hsrx_dlydir_lane0
                .hsrx_dlydir_lane1  (1'b0                       ), //input hsrx_dlydir_lane1
                .hsrx_dlyldn_ck     (1'b0                       ), //input hsrx_dlyldn_ck
                .hsrx_dlyldn_lane0  (1'b0                       ), //input hsrx_dlyldn_lane0
                .hsrx_dlyldn_lane1  (1'b0                       ), //input hsrx_dlyldn_lane1
                .hsrx_dlymv_ck      (1'b0                       ), //input hsrx_dlymv_ck
                .hsrx_dlymv_lane0   (1'b0                       ), //input hsrx_dlymv_lane0
                .hsrx_dlymv_lane1   (1'b0                       )  //input hsrx_dlymv_lane1
            );

    logic               mipi0_dphy_byte_ready  ;
    logic   [7:0]       mipi0_dphy_byte_d0     ;
    logic   [7:0]       mipi0_dphy_byte_d1     ;
    logic   [1:0]       mipi0_dphy_lp0_reg_0   = 2'b11;
    logic   [1:0]       mipi0_dphy_lp0_reg_1   = 2'b11;
    logic               mipi0_dphy_odt_en_msk  = '0;
    logic               mipi0_dphy_hsrx_en_msk = 1'b0;
    logic   [5:0]       mipi0_dphy_hsrx_cnt    = 'b0;
    logic               mipi0_dphy_reg3to1     = 1'b0;

    wire logic          mipi0_dphy_from0to3    = (mipi0_dphy_lp0_reg_1==0)&(mipi0_dphy_lp0_reg_0==3);
    wire logic          mipi0_dphy_from1to0    = (mipi0_dphy_lp0_reg_1==1)&(mipi0_dphy_lp0_reg_0==0);
    wire logic          mipi0_dphy_from1to2    = (mipi0_dphy_lp0_reg_1==1)&(mipi0_dphy_lp0_reg_0==2);
    wire logic          mipi0_dphy_from1to3    = (mipi0_dphy_lp0_reg_1==1)&(mipi0_dphy_lp0_reg_0==3);
    wire logic          mipi0_dphy_from3to1    = (mipi0_dphy_lp0_reg_1==3)&(mipi0_dphy_lp0_reg_0==1);
    wire logic          mipi0_dphy_fromXto3    = (mipi0_dphy_lp0_reg_1!=3)&(mipi0_dphy_lp0_reg_0==3);
    wire logic          mipi0_dphy_from1toX    = (mipi0_dphy_lp0_reg_1==1)&(mipi0_dphy_lp0_reg_0!=1);
    wire logic  [ 1:0]  mipi0_dphy_odt_en      = {(mipi0_dphy_di_lprx1==0), (mipi0_dphy_di_lprx0==0)} & {2{mipi0_dphy_odt_en_msk}};

    always_ff @(posedge mipi0_dphy_rx_clk or posedge sys_reset) begin
        if (sys_reset)                      mipi0_dphy_odt_en_msk <= 'b0;
        else if (~mipi0_dphy_odt_en_msk)    mipi0_dphy_odt_en_msk <= mipi0_dphy_from3to1;
        else if (1)                         mipi0_dphy_odt_en_msk <= !(mipi0_dphy_from1to2|mipi0_dphy_from1to3|mipi0_dphy_fromXto3);

        if (sys_reset)                      mipi0_dphy_reg3to1 <= 'b0;
        else if (~mipi0_dphy_reg3to1)       mipi0_dphy_reg3to1 <= mipi0_dphy_from3to1;
        else if (1)                         mipi0_dphy_reg3to1 <= ~mipi0_dphy_from1toX;

        if (sys_reset)                      mipi0_dphy_hsrx_cnt <= 'b0;
        else if (|mipi0_dphy_odt_en)        mipi0_dphy_hsrx_cnt <= 6'd10;
        else if (mipi0_dphy_hsrx_cnt>0)     mipi0_dphy_hsrx_cnt <= mipi0_dphy_hsrx_cnt - 6'd1;
    end

    always_ff @(posedge mipi0_dphy_rx_clk) begin
        mipi0_dphy_lp0_reg_0   <= mipi0_dphy_di_lprx0;
        mipi0_dphy_lp0_reg_1   <= mipi0_dphy_lp0_reg_0;
        mipi0_dphy_drst_n      <= ~(mipi0_dphy_reg3to1&mipi0_dphy_from1to0);
        mipi0_dphy_hsrx_en_msk <= (mipi0_dphy_hsrx_cnt>0);
        mipi0_dphy_byte_ready  <= mipi0_dphy_hsrx_en_msk & mipi0_dphy_hsrxd_vld[0];
        mipi0_dphy_byte_d0     <= mipi0_dphy_d0ln_hsrxd[7:0];
        mipi0_dphy_byte_d1     <= mipi0_dphy_d1ln_hsrxd[7:0];
    end
    assign mipi0_dphy_hsrx_odten = {(mipi0_dphy_di_lprx1==0), (mipi0_dphy_di_lprx0==0)} & {2{mipi0_dphy_odt_en_msk}};


    // MIPI CSI RX
    logic               mipi0_csi_rx_sp_en       /* synthesis syn_keep = 1 */;
    logic               mipi0_csi_rx_lp_en       /* synthesis syn_keep = 1 */;
    logic               mipi0_csi_rx_lp_av_en    /* synthesis syn_keep = 1 */;
    logic               mipi0_csi_rx_ecc_ok      ;
    logic   [15:0]      mipi0_csi_rx_wc          ;
    logic   [ 1:0]      mipi0_csi_rx_vc          ;
    logic   [ 5:0]      mipi0_csi_rx_dt          ;
    logic   [ 7:0]      mipi0_csi_rx_ecc         ;
    logic   [ 1:0]      mipi0_csi_rx_payload_dv  /* synthesis syn_keep = 1 */;
    logic   [15:0]      mipi0_csi_rx_payload     /* synthesis syn_keep = 1 */;

    MIPI_DSI_CSI2_RX_Top
        u_MIPI_DSI_CSI2_RX
            (
                .I_RSTN         (~sys_reset             ), //input I_RSTN
                .I_BYTE_CLK     (mipi0_dphy_rx_clk      ), //input I_BYTE_CLK
                .I_REF_DT       (6'h2b                  ), //input [5:0] I_REF_DT  RAW10
                .I_READY        (mipi0_dphy_byte_ready  ), //input I_READY
                .I_DATA0        (mipi0_dphy_byte_d0     ), //input [7:0] I_DATA0
                .I_DATA1        (mipi0_dphy_byte_d1     ), //input [7:0] I_DATA1
                .O_SP_EN        (mipi0_csi_rx_sp_en     ), //output O_SP_EN
                .O_LP_EN        (mipi0_csi_rx_lp_en     ), //output O_LP_EN
                .O_LP_AV_EN     (mipi0_csi_rx_lp_av_en  ), //output O_LP_AV_EN
                .O_ECC_OK       (mipi0_csi_rx_ecc_ok    ), //output O_ECC_OK
                .O_ECC          (mipi0_csi_rx_ecc       ), //output [7:0] O_ECC
                .O_WC           (mipi0_csi_rx_wc        ), //output [15:0] O_WC
                .O_VC           (mipi0_csi_rx_vc        ), //output [1:0] O_VC
                .O_DT           (mipi0_csi_rx_dt        ), //output [5:0] O_DT
                .O_PAYLOAD_DV   (mipi0_csi_rx_payload_dv), //output [1:0] O_PAYLOAD_DV
                .O_PAYLOAD      (mipi0_csi_rx_payload   )  //output [15:0] O_PAYLOAD
            );

    // MIPI Byte_to_Pixel
    logic           cam0_in_fv      ;
    logic           cam0_in_lv      ;
    logic [9:0]     cam0_in_pixel   ;
    MIPI_Byte_to_Pixel_Converter_Top
        u_MIPI_Byte_to_Pixel_Converter_Top
            (
                .I_RSTN         (~cam_reset             ),  //input I_RSTN
                .I_BYTE_CLK     (mipi0_dphy_rx_clk      ),  //input I_BYTE_CLK
                .I_PIXEL_CLK    (cam_clk                ),  //input I_PIXEL_CLK
                .I_SP_EN        (mipi0_csi_rx_sp_en     ),  //input I_SP_EN
                .I_LP_AV_EN     (mipi0_csi_rx_lp_av_en  ),  //input I_LP_AV_EN
                .I_DT           (mipi0_csi_rx_dt        ),  //input [5:0] I_DT
                .I_WC           (mipi0_csi_rx_wc        ),  //input [15:0] I_WC
                .I_PAYLOAD_DV   (mipi0_csi_rx_payload_dv),  //input [1:0] I_PAYLOAD_DV
                .I_PAYLOAD      (mipi0_csi_rx_payload   ),  //input [15:0] I_PAYLOAD
                .O_FV           (cam0_in_fv             ),  //output O_FV
                .O_LV           (cam0_in_lv             ),  //output O_LV
                .O_PIXEL        (cam0_in_pixel          )   //output [9:0] O_PIXEL
            );


    // ---------------------------------
    //  RAM
    // ---------------------------------

    logic               mem0_clk    ;
    logic               mem0_en     ;
    logic               mem0_regcke ;
    logic               mem0_we     ;
    logic   [15:0]      mem0_addr   ;
    logic   [7:0]       mem0_din    ;
    logic   [7:0]       mem0_dout   ;

    logic               mem1_clk    ;
    logic               mem1_en     ;
    logic               mem1_regcke ;
    logic               mem1_we     ;
    logic   [15:0]      mem1_addr   ;
    logic   [7:0]       mem1_din    ;
    logic   [7:0]       mem1_dout   ;

    jelly2_ram_dualport
            #(
                .ADDR_WIDTH     (16             ),
                .DATA_WIDTH     (8              ),
                .WE_WIDTH       (1              ),
                .DOUT_REGS0     (0              ),
                .DOUT_REGS1     (1              ),
                .MODE0          ("NORMAL"       ),
                .MODE1          ("NORMAL"       )
            )
        u_ram_dualport
            (
                .port0_clk      (mem0_clk       ),
                .port0_en       (mem0_en        ),
                .port0_regcke   (mem0_regcke    ),
                .port0_we       (mem0_we        ),
                .port0_addr     (mem0_addr      ),
                .port0_din      (mem0_din       ),
                .port0_dout     (mem0_dout      ),

                .port1_clk      (mem1_clk       ),
                .port1_en       (mem1_en        ),
                .port1_regcke   (mem1_regcke    ),
                .port1_we       (mem1_we        ),
                .port1_addr     (mem1_addr      ),
                .port1_din      (mem1_din       ),
                .port1_dout     (mem1_dout      )
            );


    // Remove Embedded data line
    logic           cam0_src_fv     ;
    logic           cam0_src_lv     ;
    logic [9:0]     cam0_src_pixel  ;

    logic           cam0_in_lv0     ;
    logic [1:0]     cam0_in_y_count ;
    always_ff @(posedge cam_clk) begin
        cam0_in_lv0 <= cam0_in_lv;
        if ( {cam0_in_lv0, cam0_in_lv} == 2'b10 && !cam0_in_y_count[1] ) begin
            cam0_in_y_count <= cam0_in_y_count + 1;
        end

        if ( cam0_in_fv == 1'b0 ) begin
            cam0_in_y_count <= '0;
        end
    end

    assign cam0_src_fv    = cam0_in_fv                          ;
    assign cam0_src_lv    = cam0_in_lv    && cam0_in_y_count[1] ;
    assign cam0_src_pixel = cam0_in_pixel                       ;

    
    logic           cam0_src_lv0;
    logic   [13:0]  cam0_src_x;
    logic   [13:0]  cam0_src_y;
    always_ff @(posedge cam_clk) begin
        cam0_src_lv0 <= cam0_src_lv;
        if ( cam0_src_fv == 1'b0 ) begin
            cam0_src_x   <= '0;
            cam0_src_y   <= '0;
        end
        else begin
            if ( cam0_src_lv ) begin
                cam0_src_x <= cam0_src_x + 1;
            end
            else begin
                cam0_src_x <= '0;
            end
        end
        if ( {cam0_src_lv0, cam0_src_lv} == 2'b10 ) begin
            cam0_src_y <= cam0_src_y + 1;
        end
    end

    assign mem0_clk    = cam_clk                                    ;
    assign mem0_en     = cam0_src_lv                                ;
    assign mem0_regcke = 1'b1                                       ;
//  assign mem0_we     = (cam0_src_x < 256) && (cam0_src_y < 256)   ;
    assign mem0_we     =  (cam0_src_x >= 1280-256) && (cam0_src_x < 1280)
                       && (cam0_src_y >= 720-256) && (cam0_src_y < 720);
    assign mem0_addr   = {cam0_src_y[7:0], cam0_src_x[7:0]}         ;
    assign mem0_din    = cam0_src_pixel[9:2]                        ;


    logic   [0:0]   axi4s_cam0_tuser    ;
    logic           axi4s_cam0_tlast    ;
    logic   [9:0]   axi4s_cam0_tdata    ;
    logic           axi4s_cam0_tvalid   ;
    always_ff @(posedge cam_clk) begin
        if ( cam0_src_fv == 1'b0 ) begin
            axi4s_cam0_tuser  <= 1'b1;
        end
        else if ( axi4s_cam0_tvalid ) begin
            axi4s_cam0_tuser <= 1'b0;
        end
        axi4s_cam0_tdata  <= cam0_src_pixel;
        axi4s_cam0_tvalid <= cam0_src_lv & cam0_src_fv;
    end
    assign axi4s_cam0_tlast = axi4s_cam0_tvalid && !cam0_src_lv;




    // ---------------------------------
    //  DVI output
    // ---------------------------------

    // generate video sync
    logic                           syncgen_vsync;
    logic                           syncgen_hsync;
    logic                           syncgen_de;
    jelly_vsync_generator_core
            #(
                .H_COUNTER_WIDTH    (DVI_H_BITS     ),
                .V_COUNTER_WIDTH    (DVI_V_BITS     )
            )
        u_vsync_generator_core
            (
                .reset              (dvi_reset      ),
                .clk                (dvi_clk        ),
                
                .ctl_enable         (1'b1           ),
                .ctl_busy           (               ),
                
                .param_htotal       (11'd1650       ),
                .param_hdisp_start  (11'd0          ),
                .param_hdisp_end    (11'd1280       ),
                .param_hsync_start  (11'd1390       ),
                .param_hsync_end    (11'd1430       ),
                .param_hsync_pol    (1'b1           ),
                .param_vtotal       (10'd750        ),
                .param_vdisp_start  (10'd0          ),
                .param_vdisp_end    (10'd720        ),
                .param_vsync_start  (10'd725        ),
                .param_vsync_end    (10'd730        ),
                .param_vsync_pol    (1'b1           ),
                
                .out_vsync          (syncgen_vsync  ),
                .out_hsync          (syncgen_hsync  ),
                .out_de             (syncgen_de     )
        );



    // 適当にパターンを作る
    logic       prev_de     ;
    dvi_h_t     syncgen_x   ;
    dvi_v_t     syncgen_y   ;
    always_ff @(posedge dvi_clk) begin
        prev_de <= syncgen_de;
        if ( syncgen_vsync == 1'b1 ) begin
            syncgen_y <= 0;
        end
        else if ( {prev_de, syncgen_de} == 2'b10 ) begin
            syncgen_y <= syncgen_y + 1;
        end

        if ( syncgen_hsync == 1'b1 ) begin
            syncgen_x <= 0;
        end
        else if ( syncgen_de ) begin
            syncgen_x <= syncgen_x + 1;
        end
    end
    
    logic   [7:0]   xy;
    assign xy  = 8'(syncgen_x + syncgen_y);
    logic   [23:0]  syncgen_rgb;
    assign syncgen_rgb = {xy, syncgen_y[7:0], syncgen_x[7:0]};


    assign mem1_clk    = dvi_clk                            ;
    assign mem1_en     = 1'b1                               ;
    assign mem1_regcke = 1'b1                               ;
    assign mem1_we     = 1'b0                               ;
    assign mem1_addr   = {syncgen_y[7:0], syncgen_x[7:0]}   ;
    assign mem1_din    = '0                                 ;

    logic   [1:0]   syncgen_vsync_ff;
    logic   [1:0]   syncgen_hsync_ff;
    logic   [1:0]   syncgen_de_ff   ;
    always_ff @(posedge dvi_clk) begin
        syncgen_vsync_ff <= {syncgen_vsync_ff[0:0], syncgen_vsync};
        syncgen_hsync_ff <= {syncgen_hsync_ff[0:0], syncgen_hsync};
        syncgen_de_ff    <= {syncgen_de_ff   [0:0], syncgen_de   };
    end


    // DVI TX
    dvi_tx
        u_dvi_tx
            (
                .reset          (dvi_reset      ),
                .clk            (dvi_clk        ),
                .clk_x5         (dvi_clk_x5     ),

                .in_vsync       (syncgen_vsync  ),
                .in_hsync       (syncgen_hsync  ),
                .in_de          (syncgen_de     ),
//              .in_data        (syncgen_rgb    ),
                .in_data        ({3{mem1_dout}} ),
                .in_ctl         ('0             ),

                .out_clk_p      (dvi_tx_clk_p   ),
                .out_clk_n      (dvi_tx_clk_n   ),
                .out_data_p     (dvi_tx_data_p  ),
                .out_data_n     (dvi_tx_data_n  )
            );
    

    // ---------------------------------
    //  Health check
    // ---------------------------------

    logic   [24:0]  counter = '0;
    always_ff @(posedge sys_clk or posedge sys_reset) begin
        if ( sys_reset ) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end

    logic   [24:0]  mipi0_dphy_counter = '0;
    always_ff @(posedge mipi0_dphy_rx_clk) begin
        mipi0_dphy_counter <= mipi0_dphy_counter + 1;
    end


    logic   [25:0]  dvi_clk1_counter = '0;
    logic   [25:0]  dvi_clk5_counter = '0;
    always_ff @(posedge dvi_clk) begin
        dvi_clk1_counter <= dvi_clk1_counter + 1;
    end
    always_ff @(posedge dvi_clk_x5) begin
        dvi_clk5_counter <= dvi_clk5_counter + 1;
    end

    assign led_n[0] = ~dvi_clk1_counter[25];
    assign led_n[1] = ~dvi_clk5_counter[25];
    assign led_n[2] = ~dvi_reset;
    assign led_n[3] = ~1'b0;
    assign led_n[4] = ~1'b0;
    assign led_n[5] = ~1'b0;

    /*
    assign led_n[0] = ~i2c_scl_i;
    assign led_n[1] = ~i2c_scl_t;
    assign led_n[2] = ~i2c_sda_i;
    assign led_n[3] = ~mipi0_dphy_counter[24];
    assign led_n[4] = ~counter[24];
    assign led_n[5] = ~reset;
    */

    assign pmod1[7:0] = mipi0_dphy_d0ln_hsrxd[7:0];
    assign pmod2 = counter[15:8];


endmodule


`default_nettype wire


// End of file
