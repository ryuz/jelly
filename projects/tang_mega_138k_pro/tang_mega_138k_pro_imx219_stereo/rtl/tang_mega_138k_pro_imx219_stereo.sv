
`timescale 1ns / 1ps
`default_nettype none

module tang_mega_138k_pro_imx219_stereo
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
            inout   tri logic           mipi1_clk_p     ,   // 912MHz
            inout   tri logic           mipi1_clk_n     ,
            inout   tri logic   [1:0]   mipi1_data_p    ,
            inout   tri logic   [1:0]   mipi1_data_n    ,
            output  var logic           mipi1_rstn      ,
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

    logic   sys_lock    ;
    logic   sys_clk     ;
    logic   cam_clk     ;
    Gowin_PLL
        u_Gowin_PLL
            (
                .lock               (sys_lock               ),
                .clkout0            (sys_clk                ),
                .clkout1            (cam_clk                ),
                .clkin              (in_clk50               )
            );

    logic   sys_reset;
    jelly_reset
            #(
                .IN_LOW_ACTIVE      (1                      ),
                .OUT_LOW_ACTIVE     (0                      ),
                .INPUT_REGS         (2                      )
            )
        u_reset_sys
            (
                .clk                (sys_clk                ),
                .in_reset           (~in_reset & sys_lock   ),
                .out_reset          (sys_reset              )
            );

    logic   cam_reset;
    jelly_reset
            #(
                .IN_LOW_ACTIVE      (1                      ),
                .OUT_LOW_ACTIVE     (0                      ),
                .INPUT_REGS         (2                      )
            )
        u_reset_cam
            (
                .clk                (cam_clk                ),
                .in_reset           (~in_reset & sys_lock   ),
                .out_reset          (cam_reset              )
            );


    logic   dvi_clk     ;
    logic   dvi_clk_x5  ;
    logic   dvi_lock    ;
    Gowin_PLL_dvi
        u_Gowin_PLL_dvi
            (
                .clkin              (in_clk50               ),
                .clkout0            (dvi_clk                ),
                .clkout1            (dvi_clk_x5             ),
                .lock               (dvi_lock               )
            );

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
                .in_reset           (~in_reset & dvi_lock   ),
                .out_reset          (dvi_reset              )
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
                .TCM_SIZE           (32'h0001_0000          ),
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
    

    // GPIO
    logic   [WB_DAT_WIDTH-1:0]  wb_gpio_dat_o;
    logic                       wb_gpio_stb_i;
    logic                       wb_gpio_ack_o;

    logic   [7:0]               reg_gpio0;
    logic   [7:0]               reg_gpio1;
    logic   [7:0]               reg_gpio2;
    logic   [7:0]               reg_gpio3;
    always_ff @(posedge sys_clk) begin
        if ( sys_reset ) begin
            reg_gpio0 <= 8'h0;
            reg_gpio1 <= 8'h0;
            reg_gpio2 <= 8'h6;
            reg_gpio3 <= 8'h0;
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
    assign mipi1_rstn = reg_gpio1[1];
    assign i2c_sel    = reg_gpio2[2:0];

//  assign i2c_sel = 3'b110;    // mipi0
//  assign i2c_sel = 3'b111;    // mipi1


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

    logic           cam0_fv     ;
    logic           cam0_lv     ;
    logic   [9:0]   cam0_pixel  ;

    imx219_mipi_rx
        u_imx219_mipi_rx_cam0
            (
                .in_reset       (sys_reset      ),

                .mipi_clk_p     (mipi0_clk_p    ),
                .mipi_clk_n     (mipi0_clk_n    ),
                .mipi_data_p    (mipi0_data_p   ),
                .mipi_data_n    (mipi0_data_n   ),

                .out_clk        (cam_clk        ),
                .out_fv         (cam0_fv        ),
                .out_lv         (cam0_lv        ),
                .out_pixel      (cam0_pixel     )
            );


    logic           cam1_fv     ;
    logic           cam1_lv     ;
    logic   [9:0]   cam1_pixel  ;

    imx219_mipi_rx
        u_imx219_mipi_rx_cam1
            (
                .in_reset       (sys_reset      ),

                .mipi_clk_p     (mipi1_clk_p    ),
                .mipi_clk_n     (mipi1_clk_n    ),
                .mipi_data_p    (mipi1_data_p   ),
                .mipi_data_n    (mipi1_data_n   ),

                .out_clk        (cam_clk        ),
                .out_fv         (cam1_fv        ),
                .out_lv         (cam1_lv        ),
                .out_pixel      (cam1_pixel     )
            );
    


    // ---------------------------------
    //  RAM
    // ---------------------------------

    logic               mem0_port0_clk    ;
    logic               mem0_port0_en     ;
    logic               mem0_port0_regcke ;
    logic               mem0_port0_we     ;
    logic   [15:0]      mem0_port0_addr   ;
    logic   [7:0]       mem0_port0_din    ;
    logic   [7:0]       mem0_port0_dout   ;

    logic               mem0_port1_clk    ;
    logic               mem0_port1_en     ;
    logic               mem0_port1_regcke ;
    logic               mem0_port1_we     ;
    logic   [15:0]      mem0_port1_addr   ;
    logic   [7:0]       mem0_port1_din    ;
    logic   [7:0]       mem0_port1_dout   ;

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
        u_ram_dualport_cam0
            (
                .port0_clk      (mem0_port0_clk       ),
                .port0_en       (mem0_port0_en        ),
                .port0_regcke   (mem0_port0_regcke    ),
                .port0_we       (mem0_port0_we        ),
                .port0_addr     (mem0_port0_addr      ),
                .port0_din      (mem0_port0_din       ),
                .port0_dout     (mem0_port0_dout      ),

                .port1_clk      (mem0_port1_clk       ),
                .port1_en       (mem0_port1_en        ),
                .port1_regcke   (mem0_port1_regcke    ),
                .port1_we       (mem0_port1_we        ),
                .port1_addr     (mem0_port1_addr      ),
                .port1_din      (mem0_port1_din       ),
                .port1_dout     (mem0_port1_dout      )
            );

    
    logic           cam0_lv_prev;
    logic   [13:0]  cam0_y;
    logic   [13:0]  cam0_x;
    always_ff @(posedge cam_clk) begin
        cam0_lv_prev <= cam0_lv;
        if ( cam0_fv == 1'b0 ) begin
            cam0_y <= '0;
        end
        if ( {cam0_lv_prev, cam0_lv} == 2'b10 ) begin
            cam0_y <= cam0_y + 1;
        end
        cam0_x <= cam0_lv ? cam0_x + 1 : '0;
    end

    assign mem0_port0_clk    = cam_clk                                    ;
    assign mem0_port0_en     = cam0_lv                                    ;
    assign mem0_port0_regcke = 1'b1                                       ;
//  assign mem0_port0_we     = (cam0_src_x < 256) && (cam0_src_y < 256)   ;
    assign mem0_port0_we     =  (cam0_x >= 1280-256) && (cam0_x < 1280)
                             && (cam0_y >= 720-256)  && (cam0_y < 720);
    assign mem0_port0_addr   = {cam0_y[7:0], cam0_x[7:0]}             ;
    assign mem0_port0_din    = cam0_pixel[9:2]                        ;




    logic               mem1_port0_clk    ;
    logic               mem1_port0_en     ;
    logic               mem1_port0_regcke ;
    logic               mem1_port0_we     ;
    logic   [15:0]      mem1_port0_addr   ;
    logic   [7:0]       mem1_port0_din    ;
    logic   [7:0]       mem1_port0_dout   ;

    logic               mem1_port1_clk    ;
    logic               mem1_port1_en     ;
    logic               mem1_port1_regcke ;
    logic               mem1_port1_we     ;
    logic   [15:0]      mem1_port1_addr   ;
    logic   [7:0]       mem1_port1_din    ;
    logic   [7:0]       mem1_port1_dout   ;

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
        u_ram_dualport_cam1
            (
                .port0_clk      (mem1_port0_clk       ),
                .port0_en       (mem1_port0_en        ),
                .port0_regcke   (mem1_port0_regcke    ),
                .port0_we       (mem1_port0_we        ),
                .port0_addr     (mem1_port0_addr      ),
                .port0_din      (mem1_port0_din       ),
                .port0_dout     (mem1_port0_dout      ),

                .port1_clk      (mem1_port1_clk       ),
                .port1_en       (mem1_port1_en        ),
                .port1_regcke   (mem1_port1_regcke    ),
                .port1_we       (mem1_port1_we        ),
                .port1_addr     (mem1_port1_addr      ),
                .port1_din      (mem1_port1_din       ),
                .port1_dout     (mem1_port1_dout      )
            );

    logic           cam1_lv_prev;
    logic   [13:0]  cam1_y;
    logic   [13:0]  cam1_x;
    always_ff @(posedge cam_clk) begin
        cam1_lv_prev <= cam1_lv;
        if ( cam1_fv == 1'b0 ) begin
            cam1_y <= '0;
        end
        if ( {cam1_lv_prev, cam1_lv} == 2'b10 ) begin
            cam1_y <= cam1_y + 1;
        end
        cam1_x <= cam1_lv ? cam1_x + 1 : '0;
    end

    assign mem1_port0_clk    = cam_clk                                    ;
    assign mem1_port0_en     = cam1_lv                                    ;
    assign mem1_port0_regcke = 1'b1                                       ;
//  assign mem1_port0_we     = (cam1_src_x < 256) && (cam1_src_y < 256)   ;
    assign mem1_port0_we     =  (cam1_x >= 1280-256) && (cam1_x < 1280)
                             && (cam1_y >= 720-256)  && (cam1_y < 720);
    assign mem1_port0_addr   = {cam1_y[7:0], cam1_x[7:0]}             ;
    assign mem1_port0_din    = cam1_pixel[9:2]                        ;





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


    assign mem0_port1_clk    = dvi_clk                            ;
    assign mem0_port1_en     = 1'b1                               ;
    assign mem0_port1_regcke = 1'b1                               ;
    assign mem0_port1_we     = 1'b0                               ;
    assign mem0_port1_addr   = {syncgen_y[7:0], syncgen_x[7:0]}   ;
    assign mem0_port1_din    = '0                                 ;

    assign mem1_port1_clk    = dvi_clk                            ;
    assign mem1_port1_en     = 1'b1                               ;
    assign mem1_port1_regcke = 1'b1                               ;
    assign mem1_port1_we     = 1'b0                               ;
    assign mem1_port1_addr   = {syncgen_y[7:0], syncgen_x[7:0]}   ;
    assign mem1_port1_din    = '0                                 ;


    logic   [1:0]   syncgen_vsync_ff;
    logic   [1:0]   syncgen_hsync_ff;
    logic   [1:0]   syncgen_de_ff   ;
    logic   [1:0]   syncgen_sel_ff  ;
    always_ff @(posedge dvi_clk) begin
        syncgen_vsync_ff <= {syncgen_vsync_ff[0:0], syncgen_vsync};
        syncgen_hsync_ff <= {syncgen_hsync_ff[0:0], syncgen_hsync};
        syncgen_de_ff    <= {syncgen_de_ff   [0:0], syncgen_de   };
        syncgen_sel_ff   <= {syncgen_sel_ff  [0:0], syncgen_x[8] };
    end


    // DVI TX
    dvi_tx
        u_dvi_tx
            (
                .reset          (dvi_reset      ),
                .clk            (dvi_clk        ),
                .clk_x5         (dvi_clk_x5     ),

                .in_vsync       (syncgen_vsync_ff[1]  ),
                .in_hsync       (syncgen_hsync_ff[1]  ),
                .in_de          (syncgen_de_ff   [1]     ),
//              .in_data        (syncgen_rgb    ),
                .in_data        (syncgen_sel_ff[1] ? {3{mem0_port1_dout}} : {3{mem1_port1_dout}}),
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

//    logic   [24:0]  mipi0_dphy_counter = '0;
//    always_ff @(posedge mipi0_dphy_rx_clk) begin
//        mipi0_dphy_counter <= mipi0_dphy_counter + 1;
//    end


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

    assign pmod1[7:0] = '0;//mipi0_dphy_d0ln_hsrxd[7:0];
    assign pmod2 = counter[15:8];


endmodule


`default_nettype wire


// End of file
