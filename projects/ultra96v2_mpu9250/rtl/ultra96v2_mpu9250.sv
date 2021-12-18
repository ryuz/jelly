// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  Ultra96V2 MPU-9250
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module ultra96v2_mpu9250
            (
                inout   wire            imu_sck,
                inout   wire            imu_sda,
                
                output  wire    [1:0]   led
            );
    
    
    
    // -----------------------------
    //  ZynqMP PS
    // -----------------------------
    
    logic           aresetn;
    logic           aclk;
    logic   [39:0]  axi4l_peri_awaddr;
    logic   [2:0]   axi4l_peri_awprot;
    logic           axi4l_peri_awvalid;
    logic           axi4l_peri_awready;
    logic   [63:0]  axi4l_peri_wdata;
    logic   [7:0]   axi4l_peri_wstrb;
    logic           axi4l_peri_wvalid;
    logic           axi4l_peri_wready;
    logic   [1:0]   axi4l_peri_bresp;
    logic           axi4l_peri_bvalid;
    logic           axi4l_peri_bready;
    logic   [39:0]  axi4l_peri_araddr;
    logic   [2:0]   axi4l_peri_arprot;
    logic           axi4l_peri_arvalid;
    logic           axi4l_peri_arready;
    logic   [63:0]  axi4l_peri_rdata;
    logic   [1:0]   axi4l_peri_rresp;
    logic           axi4l_peri_rvalid;
    logic           axi4l_peri_rready;

    logic           nirq0_lpd_rpu;
    logic   [7:0]   irq0;
    
    design_1
        i_design_1
            (
                .m_axi4l_peri_aresetn   (aresetn),
                .m_axi4l_peri_aclk      (aclk),
                .m_axi4l_peri_awaddr    (axi4l_peri_awaddr),
                .m_axi4l_peri_awprot    (axi4l_peri_awprot),
                .m_axi4l_peri_awvalid   (axi4l_peri_awvalid),
                .m_axi4l_peri_awready   (axi4l_peri_awready),
                .m_axi4l_peri_wdata     (axi4l_peri_wdata),
                .m_axi4l_peri_wstrb     (axi4l_peri_wstrb),
                .m_axi4l_peri_wvalid    (axi4l_peri_wvalid),
                .m_axi4l_peri_wready    (axi4l_peri_wready),
                .m_axi4l_peri_bresp     (axi4l_peri_bresp),
                .m_axi4l_peri_bvalid    (axi4l_peri_bvalid),
                .m_axi4l_peri_bready    (axi4l_peri_bready),
                .m_axi4l_peri_araddr    (axi4l_peri_araddr),
                .m_axi4l_peri_arprot    (axi4l_peri_arprot),
                .m_axi4l_peri_arvalid   (axi4l_peri_arvalid),
                .m_axi4l_peri_arready   (axi4l_peri_arready),
                .m_axi4l_peri_rdata     (axi4l_peri_rdata),
                .m_axi4l_peri_rresp     (axi4l_peri_rresp),
                .m_axi4l_peri_rvalid    (axi4l_peri_rvalid),
                .m_axi4l_peri_rready    (axi4l_peri_rready),
                
                .nirq0_lpd_rpu          (nirq0_lpd_rpu),
                .nfiq0_lpd_rpu          (1'b1),
                .nirq1_lpd_rpu          (1'b1),
                .nfiq1_lpd_rpu          (1'b1),
                
                .in_irq0                (irq0)
            );
    
    
    // -----------------------------
    //  Peripheral BUS (WISHBONE)
    // -----------------------------
    
    localparam  int WB_DAT_SIZE  = 3;
    localparam  int WB_ADR_WIDTH = 40 - WB_DAT_SIZE;
    localparam  int WB_DAT_WIDTH = (8 << WB_DAT_SIZE);
    localparam  int WB_SEL_WIDTH = (1 << WB_DAT_SIZE);
    
    wire                            wb_peri_rst_i;
    wire                            wb_peri_clk_i;
    wire    [WB_ADR_WIDTH-1:0]      wb_peri_adr_i;
    wire    [WB_DAT_WIDTH-1:0]      wb_peri_dat_i;
    wire    [WB_DAT_WIDTH-1:0]      wb_peri_dat_o;
    wire                            wb_peri_we_i;
    wire    [WB_SEL_WIDTH-1:0]      wb_peri_sel_i;
    wire                            wb_peri_stb_i;
    wire                            wb_peri_ack_o;
    
    jelly_axi4l_to_wishbone
            #(
                .AXI4L_ADDR_WIDTH       (40),
                .AXI4L_DATA_SIZE        (3)     // 0:8bit, 1:16bit, 2:32bit, 3:64bit, ...
            )
        i_axi4l_to_wishbone
            (
                .s_axi4l_aresetn        (aresetn),
                .s_axi4l_aclk           (aclk),
                .s_axi4l_awaddr         (axi4l_peri_awaddr),
                .s_axi4l_awprot         (axi4l_peri_awprot),
                .s_axi4l_awvalid        (axi4l_peri_awvalid),
                .s_axi4l_awready        (axi4l_peri_awready),
                .s_axi4l_wstrb          (axi4l_peri_wstrb),
                .s_axi4l_wdata          (axi4l_peri_wdata),
                .s_axi4l_wvalid         (axi4l_peri_wvalid),
                .s_axi4l_wready         (axi4l_peri_wready),
                .s_axi4l_bresp          (axi4l_peri_bresp),
                .s_axi4l_bvalid         (axi4l_peri_bvalid),
                .s_axi4l_bready         (axi4l_peri_bready),
                .s_axi4l_araddr         (axi4l_peri_araddr),
                .s_axi4l_arprot         (axi4l_peri_arprot),
                .s_axi4l_arvalid        (axi4l_peri_arvalid),
                .s_axi4l_arready        (axi4l_peri_arready),
                .s_axi4l_rdata          (axi4l_peri_rdata),
                .s_axi4l_rresp          (axi4l_peri_rresp),
                .s_axi4l_rvalid         (axi4l_peri_rvalid),
                .s_axi4l_rready         (axi4l_peri_rready),
                
                .m_wb_rst_o             (wb_peri_rst_i),
                .m_wb_clk_o             (wb_peri_clk_i),
                .m_wb_adr_o             (wb_peri_adr_i),
                .m_wb_dat_o             (wb_peri_dat_i),
                .m_wb_dat_i             (wb_peri_dat_o),
                .m_wb_we_o              (wb_peri_we_i),
                .m_wb_sel_o             (wb_peri_sel_i),
                .m_wb_stb_o             (wb_peri_stb_i),
                .m_wb_ack_i             (wb_peri_ack_o)
            );
    
    
    // -----------------------------
    //  RTOS
    // -----------------------------
    
    localparam  int                     TMAX_TSKID         = 3;
    localparam  int                     TMAX_SEMID         = 3;
    localparam  int                     TMAX_FLGID         = 1;
    localparam  int                     TSKPRI_WIDTH       = 4;
    localparam  int                     WUPCNT_WIDTH       = 1;
    localparam  int                     SUSCNT_WIDTH       = 1;
    localparam  int                     SEMCNT_WIDTH       = 4;
    localparam  int                     FLGPTN_WIDTH       = 8;
    localparam  int                     SYSTIM_WIDTH       = 64;
    localparam  int                     RELTIM_WIDTH       = 32;
    localparam  int                     TTS_WIDTH          = 4;
    localparam  int                     TTW_WIDTH          = 4;
    localparam  int                     QUECNT_WIDTH       = $clog2(TMAX_TSKID);
    localparam  int                     TSKID_WIDTH        = $clog2(TMAX_TSKID+1);
    localparam  int                     SEMID_WIDTH        = $clog2(TMAX_SEMID+1);
    

    (* mark_debug = "true" *)   logic                                       rtos_irq;

                                logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    rtos_set_flg;
    
    (* mark_debug = "true" *)   logic   [TSKID_WIDTH-1:0]                   monitor_run_tskid;
                                logic   [TSKPRI_WIDTH-1:0]                  monitor_run_tskpri;
    (* mark_debug = "true" *)   logic   [TSKID_WIDTH-1:0]                   monitor_top_tskid;
                                logic   [TMAX_TSKID:1][TTS_WIDTH-1:0]       monitor_tsk_tskstat;
                                logic   [TMAX_TSKID:1][TTW_WIDTH-1:0]       monitor_tsk_tskwait;
                                logic   [TMAX_TSKID:1][WUPCNT_WIDTH-1:0]    monitor_tsk_wupcnt;
                                logic   [TMAX_TSKID:1][SUSCNT_WIDTH-1:0]    monitor_tsk_suscnt;
                                logic   [TMAX_SEMID:1][QUECNT_WIDTH-1:0]    monitor_sem_quecnt;
                                logic   [TMAX_SEMID:1][SEMCNT_WIDTH-1:0]    monitor_sem_semcnt;
    (* mark_debug = "true" *)   logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    monitor_flg_flgptn;
    (* mark_debug = "true" *)   logic   [31:0]                              monitor_scratch0;
                                logic   [31:0]                              monitor_scratch1;
                                logic   [31:0]                              monitor_scratch2;
                                logic   [31:0]                              monitor_scratch3;
                                
                                logic   [31:0]                              wb_rtos_dat_o_tmp;
                                logic   [WB_DAT_WIDTH-1:0]                  wb_rtos_dat_o;
    (* mark_debug = "true" *)   logic                                       wb_rtos_stb_i;
    (* mark_debug = "true" *)   logic                                       wb_rtos_ack_o;
    
    jelly2_rtos
            #(
                .WB_ADR_WIDTH           (16),
                .WB_DAT_WIDTH           (32),   // RPUからもアクセスできるようにする
                .TMAX_TSKID             (TMAX_TSKID),
                .TMAX_SEMID             (TMAX_SEMID),
                .TSKPRI_WIDTH           (TSKPRI_WIDTH),
                .WUPCNT_WIDTH           (WUPCNT_WIDTH),
                .SUSCNT_WIDTH           (SUSCNT_WIDTH),
                .SEMCNT_WIDTH           (SEMCNT_WIDTH),
                .FLGPTN_WIDTH           (FLGPTN_WIDTH),
                .SYSTIM_WIDTH           (SYSTIM_WIDTH),
                .RELTIM_WIDTH           (RELTIM_WIDTH),
                .TTS_WIDTH              (TTS_WIDTH),
                .TTW_WIDTH              (TTW_WIDTH),
                .QUECNT_WIDTH           (QUECNT_WIDTH),
                .TSKID_WIDTH            (TSKID_WIDTH),
                .SEMID_WIDTH            (SEMID_WIDTH),
                .CLOCK_RATE             (250_000_000)   // 100MHz
            )   
        i_rtos
            (   
                .reset                  (wb_peri_rst_i),
                .clk                    (wb_peri_clk_i),
                .cke                    (1'b1),
                
                .s_wb_adr_i             (wb_peri_adr_i[15:0]),
                .s_wb_dat_i             (wb_peri_dat_i[31:0]),
                .s_wb_dat_o             (wb_rtos_dat_o_tmp),
                .s_wb_we_i              (wb_peri_we_i),
                .s_wb_sel_i             (wb_peri_sel_i[3:0]),
                .s_wb_stb_i             (wb_rtos_stb_i),
                .s_wb_ack_o             (wb_rtos_ack_o),
                
                .irq                    (rtos_irq),
                
                .ext_set_flg            (rtos_set_flg),
                
                .monitor_top_tskid      (monitor_top_tskid), 
                .monitor_run_tskid      (monitor_run_tskid), 
                .monitor_run_tskpri     (monitor_run_tskpri), 
                .monitor_tsk_tskstat    (monitor_tsk_tskstat),
                .monitor_tsk_tskwait    (monitor_tsk_tskwait),
                .monitor_tsk_wupcnt     (monitor_tsk_wupcnt),
                .monitor_tsk_suscnt     (monitor_tsk_suscnt),
                .monitor_sem_quecnt     (monitor_sem_quecnt),
                .monitor_sem_semcnt     (monitor_sem_semcnt),
                .monitor_flg_flgptn     (monitor_flg_flgptn),
                .monitor_scratch0       (monitor_scratch0),
                .monitor_scratch1       (monitor_scratch1),
                .monitor_scratch2       (monitor_scratch2),
                .monitor_scratch3       (monitor_scratch3)
            );
    
    assign wb_rtos_dat_o = WB_DAT_WIDTH'(wb_rtos_dat_o_tmp);
    
    
    // -----------------------------
    //  communication
    // -----------------------------
    
    localparam COM_NUM = 4;

    logic   [WB_DAT_WIDTH-1:0]      wb_com_dat_o;
    logic                           wb_com_stb_i;
    logic                           wb_com_ack_o;

    logic   [COM_NUM-1:0]           com_irq_tx;
    logic   [COM_NUM-1:0]           com_irq_rx;

    jelly2_communication_pipes
            #(
                .NUM                (COM_NUM),
                .FIFO_PTR_WIDTH     (9),
                .FIFO_RAM_TYPE      ("block"),
                .SUB_ADR_WIDTH      (8),
                .WB_ADR_WIDTH       (16),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH),
                .INIT_TX_IRQ_ENABLE (2'b00),
                .INIT_RX_IRQ_ENABLE (2'b00)
            )
        i_communication_pipes
            (
                .s_wb_rst_i         (wb_peri_rst_i),
                .s_wb_clk_i         (wb_peri_clk_i),
                .s_wb_adr_i         (wb_peri_adr_i[15:0]),
                .s_wb_dat_o         (wb_com_dat_o),
                .s_wb_dat_i         (wb_peri_dat_i),
                .s_wb_we_i          (wb_peri_we_i ),
                .s_wb_sel_i         (wb_peri_sel_i),
                .s_wb_stb_i         (wb_com_stb_i),
                .s_wb_ack_o         (wb_com_ack_o),

                .irq_tx             (com_irq_tx),
                .irq_rx             (com_irq_rx)
            );
    
    
    // -----------------------------
    //  I2C
    // -----------------------------
    
    logic                           i2c_scl_t;
    logic                           i2c_scl_i;
    logic                           i2c_sda_t;
    logic                           i2c_sda_i;
    
    logic   [WB_DAT_WIDTH-1:0]      wb_i2c_dat_o;
    logic                           wb_i2c_stb_i;
    logic                           wb_i2c_ack_o;
    
    logic                           i2c_irq;

    jelly_i2c
            #(
                .DIVIDER_WIDTH          (16),
                .DIVIDER_INIT           (2000),
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH)
            )
        i_i2c
            (
                .reset                  (wb_peri_rst_i),
                .clk                    (wb_peri_clk_i),
                
                .i2c_scl_t              (i2c_scl_t),
                .i2c_scl_i              (i2c_scl_i),
                .i2c_sda_t              (i2c_sda_t),
                .i2c_sda_i              (i2c_sda_i),
                
                .s_wb_adr_i             (wb_peri_adr_i[7:0]),
                .s_wb_dat_o             (wb_i2c_dat_o),
                .s_wb_dat_i             (wb_peri_dat_i),
                .s_wb_we_i              (wb_peri_we_i ),
                .s_wb_sel_i             (wb_peri_sel_i),
                .s_wb_stb_i             (wb_i2c_stb_i),
                .s_wb_ack_o             (wb_i2c_ack_o),
                
                .irq                    (i2c_irq)
            );
    
    IOBUF i_iobuf_scl   (.IO(imu_sck), .I(1'b0), .O(i2c_scl_i), .T(i2c_scl_t));
    IOBUF i_iobuf_sda   (.IO(imu_sda), .I(1'b0), .O(i2c_sda_i), .T(i2c_sda_t));
    
    
    
    // -----------------------------
    //  Test LED
    // -----------------------------
    
    logic   [WB_DAT_WIDTH-1:0]      wb_led_dat_o;
    logic                           wb_led_stb_i;
    logic                           wb_led_ack_o;
    
    logic   [0:0]                   reg_led;
    always @(posedge wb_peri_clk_i) begin
        if ( wb_peri_rst_i ) begin
            reg_led <= 0;
        end
        else begin
            if (wb_led_stb_i && wb_peri_we_i && wb_peri_sel_i[0]) begin
                reg_led <= wb_peri_dat_i[0:0];
            end
        end
    end
    
    assign wb_led_dat_o = WB_DAT_WIDTH'(reg_led);
    assign wb_led_ack_o = wb_led_stb_i;
    
    
    reg     [25:0]  reg_clk_count;
    always @(posedge wb_peri_clk_i) begin
        if ( wb_peri_rst_i ) begin
            reg_clk_count <= 0;
        end
        else begin
            reg_clk_count <= reg_clk_count + 1;
        end
    end
    
    assign led[0] = reg_led;
    assign led[1] = reg_clk_count[25];
    
    

    // -----------------------------
    //  IRQ
    // -----------------------------

    assign nirq0_lpd_rpu = ~rtos_irq;

    always_comb begin
        irq0 = '0;
        irq0[0] = com_irq_rx[0];    // RPU->APU
        irq0[1] = com_irq_tx[1];    // APU->RPU
        irq0[2] = com_irq_rx[2];    // RPU->APU
        irq0[3] = com_irq_tx[3];    // APU->RPU
        irq0[4] = i2c_irq;
    end

    // イベントフラグで受ける
    always_comb begin
        rtos_set_flg = '0;
        rtos_set_flg[1][0] = com_irq_tx[0]; // RPU->APU
        rtos_set_flg[1][1] = com_irq_rx[1]; // APU->RPU
        rtos_set_flg[1][2] = com_irq_tx[2]; // RPU->APU
        rtos_set_flg[1][3] = com_irq_rx[3]; // APU->RPU
        rtos_set_flg[1][4] = i2c_irq;
    end


    // -----------------------------
    //  WISHBONE address decode
    // -----------------------------
    
    assign wb_rtos_stb_i  = wb_peri_stb_i & (wb_peri_adr_i[23:16] == 8'h00);
    assign wb_com_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[23:16] == 8'h01);
    assign wb_i2c_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[23:16] == 8'h10);
    assign wb_led_stb_i   = wb_peri_stb_i & (wb_peri_adr_i[23:16] == 8'h11);
    
    assign wb_peri_dat_o  = wb_rtos_stb_i ? wb_rtos_dat_o :
                            wb_com_stb_i  ? wb_com_dat_o  :
                            wb_i2c_stb_i  ? wb_i2c_dat_o  :
                            wb_led_stb_i  ? wb_led_dat_o  :
                            {WB_DAT_WIDTH{1'b0}};
    
    assign wb_peri_ack_o  = wb_rtos_stb_i ? wb_rtos_ack_o :
                            wb_com_stb_i  ? wb_com_ack_o  :
                            wb_i2c_stb_i  ? wb_i2c_ack_o  :
                            wb_led_stb_i  ? wb_led_ack_o  :
                            wb_peri_stb_i;
    
    
    // -----------------------------
    //  debug
    // -----------------------------
    
    (* mark_debug="true" *) reg     dbg_irq_rtos;
    (* mark_debug="true" *) reg     dbg_irq_i2c;
    (* mark_debug="true" *) reg     dbg_scl_t;
    (* mark_debug="true" *) reg     dbg_scl_i;
    (* mark_debug="true" *) reg     dbg_sda_t;
    (* mark_debug="true" *) reg     dbg_sda_i;
    
    always @(posedge wb_peri_clk_i) begin
        dbg_irq_rtos <= rtos_irq;
        dbg_irq_i2c  <= i2c_irq;
        dbg_scl_t    <= i2c_scl_t;
        dbg_scl_i    <= i2c_scl_i;
        dbg_sda_t    <= i2c_sda_t;
        dbg_sda_i    <= i2c_sda_i;
    end
    
    
endmodule



`default_nettype wire


// end of file
