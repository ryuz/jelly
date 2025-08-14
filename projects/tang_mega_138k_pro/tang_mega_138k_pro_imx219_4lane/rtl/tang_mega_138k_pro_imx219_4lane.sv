
`timescale 1ns / 1ps
`default_nettype none

module tang_mega_138k_pro_imx219_4lane
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
            inout   tri logic   [3:0]   mipi0_data_p    ,
            inout   tri logic   [3:0]   mipi0_data_n    ,
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
    //  Clock and Reset
    // ---------------------------------

    logic   sys_lock    ;
    logic   sys_clk     ;
    logic   cam_clk     ;
    Gowin_PLL
        u_Gowin_PLL
            (
                .init_clk   (in_clk50   ),
                .clkout0    (sys_clk    ),
                .clkout1    (cam_clk    ),
                .clkin      (in_clk50   ),
                .lock       (sys_lock   )
            );

    logic   clk;
    assign clk = sys_clk;

    logic   sys_reset;
    jelly_reset
            #(
                .IN_LOW_ACTIVE      (1                      ),
                .OUT_LOW_ACTIVE     (0                      ),
                .INPUT_REGS         (2                      )
            )
        u_reset
            (
                .clk                (clk                    ),
                .in_reset           (~in_reset & sys_lock   ),   // asyncrnous reset
                .out_reset          (sys_reset              )    // syncrnous reset
            );

    // PLL
    logic   dvi_clk     ;
    logic   dvi_clk_x5  ;
    logic   dvi_lock    ;
    Gowin_PLL_dvi_vga
        u_Gowin_PLL_dvi
            (
                .init_clk   (in_clk50   ),
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
                .clk                (clk                ),
                
                .uart_reset         (sys_reset          ),
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
                .reset              (sys_reset          ),
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
    always_ff @(posedge clk) begin
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

    logic               cam0_fv     ;
    logic               cam0_lv     ;
    logic   [3:0][9:0]  cam0_pixel  ;

    imx219_mipi_rx_4lane
        u_imx219_mipi_rx_4lane
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


    // ---------------------------------
    //  RAM
    // ---------------------------------

    logic               mem0_clk    ;
    logic               mem0_en     ;
    logic               mem0_regcke ;
    logic               mem0_we     ;
    logic   [13:0]      mem0_addr   ;
    logic   [3:0][9:0]  mem0_din    ;
    logic   [3:0][9:0]  mem0_dout   ;

    logic               mem1_clk    ;
    logic               mem1_en     ;
    logic               mem1_regcke ;
    logic               mem1_we     ;
    logic   [13:0]      mem1_addr   ;
    logic   [3:0][9:0]  mem1_din    ;
    logic   [3:0][9:0]  mem1_dout   ;

    jelly2_ram_dualport
            #(
                .ADDR_WIDTH     (16-2           ),
                .DATA_WIDTH     (4*10           ),
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
    logic               cam0_src_fv     ;
    logic               cam0_src_lv     ;
    logic [3:0][9:0]    cam0_src_pixel  ;

    logic               cam0_lv0        ;
    logic [1:0]         cam0_y_count    ;
    always_ff @(posedge cam_clk) begin
        cam0_lv0 <= cam0_lv;
        if ( {cam0_lv0, cam0_lv} == 2'b10 && !cam0_y_count[1] ) begin
            cam0_y_count <= cam0_y_count + 1;
        end

        if ( cam0_fv == 1'b0 ) begin
            cam0_y_count <= '0;
        end
    end

    assign cam0_src_fv    = cam0_fv                         ;
    assign cam0_src_lv    = cam0_lv    && cam0_y_count[1]   ;
    assign cam0_src_pixel = cam0_pixel                      ;

    
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
    assign mem0_we     = (cam0_src_x < 256/4) && (cam0_src_y < 256) ;
    assign mem0_addr   = {cam0_src_y[7:0], cam0_src_x[5:0]}         ;
    assign mem0_din    = cam0_src_pixel                             ;


    // ---------------------------------
    //  DVI output
    // ---------------------------------

    // generate video sync
    logic                           syncgen_vsync;
    logic                           syncgen_hsync;
    logic                           syncgen_de;
    jelly_vsync_generator_core
            #(
                .V_COUNTER_WIDTH    (10             ),
                .H_COUNTER_WIDTH    (10             )
            )
        u_vsync_generator_core
            (
                .reset              (dvi_reset      ),
                .clk                (dvi_clk        ),
                
                .ctl_enable         (1'b1           ),
                .ctl_busy           (               ),
                
                .param_htotal       (10'(96 + 16 + 640 + 48 )),
                .param_hdisp_start  (10'(96 + 16            )),
                .param_hdisp_end    (10'(96 + 16 + 640      )),
                .param_hsync_start  (10'(0                  )),
                .param_hsync_end    (10'(96                 )),
                .param_hsync_pol    (1'b0                    ), // 0:n 1:p
                .param_vtotal       (10'(2 + 10 + 480 + 33  )),
                .param_vdisp_start  (10'(2 + 10             )),
                .param_vdisp_end    (10'(2 + 10 + 480       )),
                .param_vsync_start  (10'(0                  )),
                .param_vsync_end    (10'(2                  )),
                .param_vsync_pol    (1'b0                    ), // 0:n 1:p
                
                .out_vsync          (syncgen_vsync  ),
                .out_hsync          (syncgen_hsync  ),
                .out_de             (syncgen_de     )
        );

    // 読み出しアドレス生成
    logic           prev_de;
    logic   [10:0]  syncgen_x;
    logic   [10:0]  syncgen_y;
    always_ff @(posedge dvi_clk) begin
        prev_de <= syncgen_de;
        if ( syncgen_vsync == 1'b0 ) begin
            syncgen_y <= 0;
        end
        else if ( {prev_de, syncgen_de} == 2'b10 ) begin
            syncgen_y <= syncgen_y + 1;
        end

        if ( syncgen_hsync == 1'b0 ) begin
            syncgen_x <= 0;
        end
        else if ( syncgen_de ) begin
            syncgen_x <= syncgen_x + 1;
        end
    end
    

    assign mem1_clk    = dvi_clk                            ;
    assign mem1_en     = 1'b1                               ;
    assign mem1_regcke = 1'b1                               ;
    assign mem1_we     = 1'b0                               ;
    assign mem1_addr   = {syncgen_y[7:0], syncgen_x[7:2]}   ;
    assign mem1_din    = '0                                 ;

    logic   [1:0]       syncgen_vsync_ff;
    logic   [1:0]       syncgen_hsync_ff;
    logic   [1:0]       syncgen_de_ff   ;
    logic   [1:0][1:0]  syncgen_x_ff    ;
    always_ff @(posedge dvi_clk) begin
        syncgen_vsync_ff <= {syncgen_vsync_ff[0:0], syncgen_vsync};
        syncgen_hsync_ff <= {syncgen_hsync_ff[0:0], syncgen_hsync};
        syncgen_de_ff    <= {syncgen_de_ff   [0:0], syncgen_de   };
        syncgen_x_ff[0]  <= syncgen_x[1:0]  ;
        syncgen_x_ff[1]  <= syncgen_x_ff[0] ;
    end

    logic   [9:0]  raw_dout;
    assign raw_dout = mem1_dout[syncgen_x_ff[1]];

    // DVI TX
    dvi_tx
        u_dvi_tx
            (
                .reset          (dvi_reset          ),
                .clk            (dvi_clk            ),
                .clk_x5         (dvi_clk_x5         ),

                .in_vsync       (syncgen_vsync_ff[1]),
                .in_hsync       (syncgen_hsync_ff[1]),
                .in_de          (syncgen_de_ff[1]   ),
                .in_data        ({3{raw_dout[9:2]}} ),
                .in_ctl         ('0                 ),

                .out_clk_p      (dvi_tx_clk_p       ),
                .out_clk_n      (dvi_tx_clk_n       ),
                .out_data_p     (dvi_tx_data_p      ),
                .out_data_n     (dvi_tx_data_n      )
            );
    

    // ---------------------------------
    //  Health check
    // ---------------------------------

    logic   [24:0]  counter = '0;
    always_ff @(posedge clk or posedge sys_reset) begin
        if ( sys_reset ) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end

    assign led_n[0] = ~i2c_scl_i;
    assign led_n[1] = ~i2c_scl_t;
    assign led_n[2] = ~i2c_sda_i;
    assign led_n[3] = ~0;;
    assign led_n[4] = ~counter[24];
    assign led_n[5] = ~sys_reset;

    assign pmod1[7:0] = 0;
    assign pmod2[7:0] = counter[15:8];

endmodule


`default_nettype wire


// End of file
