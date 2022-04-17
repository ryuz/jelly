
`timescale 1ns / 1ps
`default_nettype none


module tb_main(
            input   wire    reset,
            input   wire    clk
        );
    

    // setting
    localparam          FILE_NAME        = "../../../../data/Penguins_640x480.ppm";
//  localparam          FILE_NAME        = "../../../../data/Chrysanthemum_640x480.ppm";
    localparam  int     COMPONENTS       = 3;
    localparam  int     DATA_SIZE        = 0;
    localparam  int     DATA_WIDTH       = (8 << DATA_SIZE);
    localparam  int     X_NUM            = 640;
    localparam  int     Y_NUM            = 480;

    localparam  int     BLK_X_SIZE       = 4;  // 0:1pixel; 1:2pixel; 2:4pixel; 3:8pixel ...
    localparam  int     BLK_Y_SIZE       = 4;  // 0:1pixel; 1:2pixel; 2:4pixel; 3:8pixel ...
    localparam  int     STEP_Y_SIZE      = 2;

    localparam  int     AXI4_ID_WIDTH    = 6;
    localparam  int     AXI4_ADDR_WIDTH  = 32;
    localparam  int     AXI4_DATA_SIZE   = 4; // 0:8bit, 1:16bit, 2:32bit, 3:64bit, ... ...
    localparam  int     AXI4_DATA_WIDTH  = (8 << AXI4_DATA_SIZE);
    localparam  int     AXI4_STRB_WIDTH  = (1 << AXI4_DATA_SIZE);
    localparam  int     AXI4_LEN_WIDTH   = 8;
    localparam  int     AXI4_QOS_WIDTH   = 4;
    
    logic   [AXI4_ID_WIDTH-1:0]         axi4_awid;
    logic   [AXI4_ADDR_WIDTH-1:0]       axi4_awaddr;
    logic   [AXI4_LEN_WIDTH-1:0]        axi4_awlen;
    logic   [2:0]                       axi4_awsize;
    logic   [1:0]                       axi4_awburst;
    logic   [0:0]                       axi4_awlock;
    logic   [3:0]                       axi4_awcache;
    logic   [2:0]                       axi4_awprot;
    logic   [AXI4_QOS_WIDTH-1:0]        axi4_awqos;
    logic   [3:0]                       axi4_awregion;
    logic                               axi4_awvalid;
    logic                               axi4_awready;
    logic   [AXI4_DATA_WIDTH-1:0]       axi4_wdata;
    logic   [AXI4_STRB_WIDTH-1:0]       axi4_wstrb;
    logic                               axi4_wlast;
    logic                               axi4_wvalid;
    logic                               axi4_wready;
    logic   [AXI4_ID_WIDTH-1:0]         axi4_bid;
    logic   [1:0]                       axi4_bresp;
    logic                               axi4_bvalid;
    logic                               axi4_bready;
    logic   [AXI4_ID_WIDTH-1:0]         axi4_arid;
    logic   [AXI4_ADDR_WIDTH-1:0]       axi4_araddr;
    logic   [AXI4_LEN_WIDTH-1:0]        axi4_arlen;
    logic   [2:0]                       axi4_arsize;
    logic   [1:0]                       axi4_arburst;
    logic   [0:0]                       axi4_arlock;
    logic   [3:0]                       axi4_arcache;
    logic   [2:0]                       axi4_arprot;
    logic   [AXI4_QOS_WIDTH-1:0]        axi4_arqos;
    logic   [3:0]                       axi4_arregion;
    logic                               axi4_arvalid;
    logic                               axi4_arready;
    logic   [AXI4_ID_WIDTH-1:0]         axi4_rid;
    logic   [AXI4_DATA_WIDTH-1:0]       axi4_rdata;
    logic   [1:0]                       axi4_rresp;
    logic                               axi4_rlast;
    logic                               axi4_rvalid;
    logic                               axi4_rready;


    // ---------------------------------------------
    //  source image
    // ---------------------------------------------

    logic                               src_enable;
    logic                               src_busy;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            src_enable <= 1'b1;
        end
        else begin
            if ( src_busy ) begin
                src_enable <= 1'b0;
            end
        end
    end

    logic      [0:0]                    axi4s_src_tuser;
    logic                               axi4s_src_tlast;
    logic      [23:0]                   axi4s_src_tdata;
    logic                               axi4s_src_tvalid;
    logic                               axi4s_src_tready;
   
    jelly2_axi4s_master_model
            #(
                .COMPONENTS             (COMPONENTS),
                .DATA_WIDTH             (DATA_WIDTH),
                .X_NUM                  (X_NUM),
                .Y_NUM                  (Y_NUM),
                .X_BLANK                (64),
                .Y_BLANK                (32),
                .X_WIDTH                (32),
                .Y_WIDTH                (32),
                .F_WIDTH                (32),
                .FILE_NAME              (FILE_NAME),
                .FILE_EXT               (""),
                .FILE_X_NUM             (X_NUM),
                .FILE_Y_NUM             (Y_NUM),
                .SEQUENTIAL_FILE        (0),
                .BUSY_RATE              (0),
                .RANDOM_SEED            (0),
                .ENDIAN                 (0)
            )
        i_axi4s_master_model
            (
                .aresetn                (~reset),
                .aclk                   (clk),
                .aclken                 (1'b1),
                
                .enable                 (src_enable),
                .busy                   (src_busy),

                .m_axi4s_tuser          (axi4s_src_tuser),
                .m_axi4s_tlast          (axi4s_src_tlast),
                .m_axi4s_tdata          (axi4s_src_tdata),
                .m_axi4s_tx             (),
                .m_axi4s_ty             (),
                .m_axi4s_tf             (),
                .m_axi4s_tvalid         (axi4s_src_tvalid),
                .m_axi4s_tready         (axi4s_src_tready)
            );
    

    // ---------------------------------------------
    //  textrute writer
    // ---------------------------------------------

    localparam X_WIDTH                = 10;
    localparam Y_WIDTH                = 9;
    localparam STRIDE_C_WIDTH         = 14;
    localparam STRIDE_X_WIDTH         = 14;
    localparam STRIDE_Y_WIDTH         = 15;

    logic                               writer_enable;
    logic                               writer_busy;

    logic   [STRIDE_C_WIDTH-1:0]        param_stride_c = (1 << BLK_X_SIZE) * (1 << BLK_Y_SIZE);
    logic   [STRIDE_X_WIDTH-1:0]        param_stride_x = (1 << BLK_X_SIZE) * (1 << BLK_Y_SIZE) * COMPONENTS;
    logic   [STRIDE_Y_WIDTH-1:0]        param_stride_y = X_NUM             * (1 << BLK_Y_SIZE) * COMPONENTS;

    initial begin
        $display("param_stride_c : %d", param_stride_c);
        $display("param_stride_x : %d", param_stride_x);
        $display("param_stride_y : %d", param_stride_y);
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            writer_enable <= 1'b1;
        end
        else begin
            if ( writer_busy ) begin
                writer_enable <= 1'b0;
            end
        end
    end

    jelly_texture_writer_core
            #(
                .COMPONENT_NUM          (COMPONENTS),
                .COMPONENT_DATA_WIDTH   (DATA_WIDTH),
                
                .M_AXI4_ID_WIDTH        (AXI4_ID_WIDTH),
                .M_AXI4_ADDR_WIDTH      (AXI4_ADDR_WIDTH),
                .M_AXI4_DATA_SIZE       (AXI4_DATA_SIZE),       // 8^n (0:8bit, 1:16bit, 2:32bit, 3:64bit, ...)
                .M_AXI4_LEN_WIDTH       (AXI4_LEN_WIDTH),
                .M_AXI4_QOS_WIDTH       (AXI4_QOS_WIDTH),
                
                .BLK_X_SIZE             (BLK_X_SIZE),   // 2^n (0:1, 1:2, 2:4, 3:8, ... )
                .BLK_Y_SIZE             (BLK_Y_SIZE),   // 2^n (0:1, 1:2, 2:4, 3:8, ... )
                .STEP_Y_SIZE            (STEP_Y_SIZE),  // 2^n (0:1, 1:2, 2:4, 3:8, ... )
                
                .X_WIDTH                (X_WIDTH),
                .Y_WIDTH                (Y_WIDTH),
                .STRIDE_C_WIDTH         (STRIDE_C_WIDTH),
                .STRIDE_X_WIDTH         (STRIDE_X_WIDTH),
                .STRIDE_Y_WIDTH         (STRIDE_Y_WIDTH),
                
                .BUF_ADDR_WIDTH         (12+1),
                .BUF_RAM_TYPE           ("block")
            )
        i_texture_writer_core
            (
                .reset                  (reset),
                .clk                    (clk),
                
                .endian                 (0),
                
                .enable                 (writer_enable),
                .busy                   (writer_busy),
                
                .param_addr             (32'h0000_0000),
                .param_awlen            (32'h03),
                .param_width            (X_NUM),
                .param_height           (Y_NUM),
                .param_stride_c         (param_stride_c),
                .param_stride_x         (param_stride_x),
                .param_stride_y         (param_stride_y),
                
                .s_axi4s_tuser          (axi4s_src_tuser),
                .s_axi4s_tlast          (axi4s_src_tlast),
                .s_axi4s_tdata          (axi4s_src_tdata),
                .s_axi4s_tvalid         (axi4s_src_tvalid),
                .s_axi4s_tready         (axi4s_src_tready),
                
                .m_axi4_awid            (axi4_awid),
                .m_axi4_awaddr          (axi4_awaddr),
                .m_axi4_awlen           (axi4_awlen),
                .m_axi4_awsize          (axi4_awsize),
                .m_axi4_awburst         (axi4_awburst),
                .m_axi4_awlock          (axi4_awlock),
                .m_axi4_awcache         (axi4_awcache),
                .m_axi4_awprot          (axi4_awprot),
                .m_axi4_awqos           (axi4_awqos),
                .m_axi4_awregion        (axi4_awregion),
                .m_axi4_awvalid         (axi4_awvalid),
                .m_axi4_awready         (axi4_awready),
                .m_axi4_wdata           (axi4_wdata),
                .m_axi4_wstrb           (axi4_wstrb),
                .m_axi4_wlast           (axi4_wlast),
                .m_axi4_wvalid          (axi4_wvalid),
                .m_axi4_wready          (axi4_wready),
                .m_axi4_bid             (axi4_bid),
                .m_axi4_bresp           (axi4_bresp),
                .m_axi4_bvalid          (axi4_bvalid),
                .m_axi4_bready          (axi4_bready)
            );
    


    // ---------------------------------------------
    //  textrute sampler
    // ---------------------------------------------
    
//  parameter   DATA_WIDTH                    = 8;
    parameter   ADDR_WIDTH                    = 24;
    parameter   ADDR_X_WIDTH                  = 12;
    parameter   ADDR_Y_WIDTH                  = 12;
//    parameter   STRIDE_C_WIDTH                = 12;
//    parameter   STRIDE_X_WIDTH                = 13;
//    parameter   STRIDE_Y_WIDTH                = 14;
    
    parameter   USE_BILINEAR                  = 1;
    parameter   USE_BORDER                    = 1;
    
    parameter   SAMPLER1D_NUM                 = 0;
    
    parameter   SAMPLER2D_NUM                 = 12;
    parameter   SAMPLER2D_USER_WIDTH          = 0;
    parameter   SAMPLER2D_X_INT_WIDTH         = ADDR_X_WIDTH+2;
    parameter   SAMPLER2D_X_FRAC_WIDTH        = 4;
    parameter   SAMPLER2D_Y_INT_WIDTH         = ADDR_Y_WIDTH+2;
    parameter   SAMPLER2D_Y_FRAC_WIDTH        = 4;
    parameter   SAMPLER2D_COEFF_INT_WIDTH     = 1;
    parameter   SAMPLER2D_COEFF_FRAC_WIDTH    = SAMPLER2D_X_FRAC_WIDTH + SAMPLER2D_Y_FRAC_WIDTH;
    parameter   SAMPLER2D_S_REGS              = 1;
    parameter   SAMPLER2D_M_REGS              = 1;
    parameter   SAMPLER2D_USER_FIFO_PTR_WIDTH = 6;
    parameter   SAMPLER2D_USER_FIFO_RAM_TYPE  = "distributed";
    parameter   SAMPLER2D_USER_FIFO_M_REGS    = 0;
    parameter   SAMPLER2D_X_WIDTH             = SAMPLER2D_X_INT_WIDTH + SAMPLER2D_X_FRAC_WIDTH;
    parameter   SAMPLER2D_Y_WIDTH             = SAMPLER2D_Y_INT_WIDTH + SAMPLER2D_Y_FRAC_WIDTH;
    parameter   SAMPLER2D_COEFF_WIDTH         = SAMPLER2D_COEFF_INT_WIDTH + SAMPLER2D_COEFF_FRAC_WIDTH;
    parameter   SAMPLER2D_USER_BITS           = SAMPLER2D_USER_WIDTH > 0 ? SAMPLER2D_USER_WIDTH : 1;
    
    parameter   SAMPLER3D_NUM                 = 0;
    
    parameter   L1_CACHE_NUM                  = SAMPLER1D_NUM + SAMPLER2D_NUM + SAMPLER3D_NUM;
    parameter   L1_USE_LOOK_AHEAD             = 0;
    parameter   L1_QUE_FIFO_PTR_WIDTH         = 6;
    parameter   L1_AR_FIFO_PTR_WIDTH          = 0;
    parameter   L1_R_FIFO_PTR_WIDTH           = 6;
    parameter   L1_WAY_NUM                    = 4;
    parameter   L1_TAG_ADDR_WIDTH             = 4;
    parameter   L1_TAG_ALGORITHM              = "NORMAL"; // L2_PARALLEL_SIZE > 0 ? "SUDOKU" : "TWIST";
    parameter   L1_BLK_X_SIZE                 = 2;  // 0:1pixel; 1:2pixel; 2:4pixel; 3:8pixel ...
    parameter   L1_BLK_Y_SIZE                 = 2;  // 0:1pixel; 1:2pixel; 2:4pixel; 3:8pixel ...
    parameter   L1_TAG_RAM_TYPE               = "distributed";
    parameter   L1_MEM_RAM_TYPE               = "block";
    parameter   L1_DATA_SIZE                  = 2;
    
    parameter   L2_PARALLEL_SIZE              = 2;
    parameter   L2_USE_LOOK_AHEAD             = 0;
    parameter   L2_QUE_FIFO_PTR_WIDTH         = 6;
    parameter   L2_AR_FIFO_PTR_WIDTH          = 0;
    parameter   L2_R_FIFO_PTR_WIDTH           = 6;
    parameter   L2_CACHE_NUM                  = (1 << L2_PARALLEL_SIZE);
    parameter   L2_WAY_NUM                    = 4;
    parameter   L2_TAG_ADDR_WIDTH             = 6;
    parameter   L2_TAG_ALGORITHM              = "NORMAL";    // L2_PARALLEL_SIZE > 0 ? "SUDOKU" : "TWIST";
    parameter   L2_BLK_X_SIZE                 = BLK_X_SIZE;  // 0:1pixel; 1:2pixel; 2:4pixel; 3:8pixel ...
    parameter   L2_BLK_Y_SIZE                 = BLK_Y_SIZE;  // 0:1pixel; 1:2pixel; 2:4pixel; 3:8pixel ...
    parameter   L2_TAG_RAM_TYPE               = "distributed";
    parameter   L2_MEM_RAM_TYPE               = "block";
    
    /*
    parameter   M_AXI4_ID_WIDTH               = 6;
    parameter   M_AXI4_ADDR_WIDTH             = 32;
    parameter   M_AXI4_DATA_SIZE              = 3;  // 0:8bit; 1:16bit; 2:32bit; 3:64bit ...
    parameter   M_AXI4_DATA_WIDTH             = (8 << M_AXI4_DATA_SIZE);
    parameter   M_AXI4_LEN_WIDTH              = 8;
    parameter   M_AXI4_QOS_WIDTH              = 4;
    */
    parameter   M_AXI4_ARID                   = {AXI4_ID_WIDTH{1'b0}};
    parameter   M_AXI4_ARSIZE                 = AXI4_DATA_SIZE;
    parameter   M_AXI4_ARBURST                = 2'b01;
    parameter   M_AXI4_ARLOCK                 = 1'b0;
    parameter   M_AXI4_ARCACHE                = 4'b0001;
    parameter   M_AXI4_ARPROT                 = 3'b000;
    parameter   M_AXI4_ARQOS                  = 0;
    parameter   M_AXI4_ARREGION               = 4'b0000;
    parameter   M_AXI4_REGS                   = 1;

    parameter   DEVICE                        = "RTL";
    
    
    logic   [L1_CACHE_NUM-1:0]                              status_l1_idle;
    logic   [L1_CACHE_NUM-1:0]                              status_l1_stall;
    logic   [L1_CACHE_NUM-1:0]                              status_l1_access;
    logic   [L1_CACHE_NUM-1:0]                              status_l1_hit;
    logic   [L1_CACHE_NUM-1:0]                              status_l1_miss;
    logic   [L1_CACHE_NUM-1:0]                              status_l1_blank;
    logic   [L2_CACHE_NUM-1:0]                              status_l2_idle;
    logic   [L2_CACHE_NUM-1:0]                              status_l2_stall;
    logic   [L2_CACHE_NUM-1:0]                              status_l2_access;
    logic   [L2_CACHE_NUM-1:0]                              status_l2_hit;
    logic   [L2_CACHE_NUM-1:0]                              status_l2_miss;
    logic   [L2_CACHE_NUM-1:0]                              status_l2_blank;
    
    // 2D sampler
    logic   [SAMPLER2D_NUM*SAMPLER2D_USER_BITS-1:0]         s_sampler2d_user;
    logic   [SAMPLER2D_NUM*SAMPLER2D_X_WIDTH-1:0]           s_sampler2d_x;
    logic   [SAMPLER2D_NUM*SAMPLER2D_Y_WIDTH-1:0]           s_sampler2d_y;
    logic   [SAMPLER2D_NUM-1:0]                             s_sampler2d_strb = {SAMPLER2D_NUM{1'b1}};
    logic   [SAMPLER2D_NUM-1:0]                             s_sampler2d_valid;
    logic   [SAMPLER2D_NUM-1:0]                             s_sampler2d_ready;
    
    logic   [SAMPLER2D_NUM*SAMPLER2D_USER_BITS-1:0]         m_sampler2d_user;
    logic   [SAMPLER2D_NUM-1:0]                             m_sampler2d_border;
    logic   [SAMPLER2D_NUM*COMPONENTS*DATA_WIDTH-1:0]       m_sampler2d_data;
    logic   [SAMPLER2D_NUM-1:0]                             m_sampler2d_strb;
    logic   [SAMPLER2D_NUM-1:0]                             m_sampler2d_valid;
    logic   [SAMPLER2D_NUM-1:0]                             m_sampler2d_ready;
    
    
    parameter   LINE_SIZE     = 640;
    parameter   UNIT_SIZE     = (LINE_SIZE + (SAMPLER2D_NUM-1)) / SAMPLER2D_NUM;
    
    wire    [SAMPLER2D_NUM*(SAMPLER2D_Y_WIDTH+SAMPLER2D_X_WIDTH)-1:0]   s_samoler2d_packet;
    

    // texture address
    logic                                           txtadr_enbale;

    logic   [SAMPLER2D_Y_WIDTH-1:0]                 txtadr_x;
    logic   [SAMPLER2D_X_WIDTH-1:0]                 txtadr_y;
    logic                                           txtadr_valid;
    logic                                           txtadr_ready;
    
    integer     m00, m01, m02;
    integer     m10, m11, m12;
    initial begin
        m00 = $rtoi(16 *  0.7071);
        m01 = $rtoi(16 * -0.7071);
        m02 = $rtoi(16 * 263.42);
        m10 = $rtoi(16 * 0.7071);
        m11 = $rtoi(16 * 0.707);
        m12 = $rtoi(16 * -155.97);
        
//      m00 = $rtoi(16 * 1.0);
//      m01 = $rtoi(16 * 0.0);
//      m02 = $rtoi(16 * 0.0);
//      m10 = $rtoi(16 * 0.0);
//      m11 = $rtoi(16 * 1.0);
//      m12 = $rtoi(16 * 0.0);
    end
    
    wire        [SAMPLER2D_X_WIDTH-1:0]             txtadr_x_tmp = SAMPLER2D_X_WIDTH'(m00 * txtadr_x + m01 * txtadr_y + m02);
    wire        [SAMPLER2D_Y_WIDTH-1:0]             txtadr_y_tmp = SAMPLER2D_Y_WIDTH'(m10 * txtadr_x + m11 * txtadr_y + m12);
//  wire        [SAMPLER2D_X_WIDTH-1:0]             txtadr_x_tmp = 16 * txtadr_x;
//  wire        [SAMPLER2D_Y_WIDTH-1:0]             txtadr_y_tmp = 16 * txtadr_y;
    
    always @(posedge clk) begin
        if ( reset ) begin
            txtadr_enbale <= 1'b1;
            txtadr_x      <= 0;
            txtadr_y      <= 0;
            txtadr_valid  <= 0;
        end
        else begin
            if ( txtadr_enbale ) begin
                txtadr_valid <= !(writer_enable || writer_busy);
                if ( txtadr_valid && txtadr_ready ) begin
                    txtadr_x <= txtadr_x + 1;
                    if ( int'(txtadr_x) == X_NUM-1 ) begin
                        txtadr_x <= 0;
                        txtadr_y <= txtadr_y + 1;
                        if ( int'(txtadr_y) == Y_NUM-1 ) begin
                            txtadr_x <= 0;
                            txtadr_y <= 0;
                            txtadr_valid <= 0;
                            txtadr_enbale <= 0;
                            $writememh("axi4_mem.txt", i_axi4_slave_model.mem);
                        end
                    end
                end
            end
            else begin
                txtadr_valid <= 0;
            end
        end
    end
    

    wire    [COMPONENTS*DATA_WIDTH-1:0]             sink_data;
    wire                                            sink_valid;
    reg                                             sink_ready = 1;
    
    jelly_data_scatter
            #(
                .PORT_NUM       (SAMPLER2D_NUM),
                .DATA_WIDTH     (SAMPLER2D_Y_WIDTH+SAMPLER2D_X_WIDTH),
                .LINE_SIZE      (LINE_SIZE),
                .UNIT_SIZE      (UNIT_SIZE),
                .FIFO_PTR_WIDTH (12)
            )
        i_data_scatter
            (
                .reset          (reset),
                .clk            (clk),
                
                .s_data         ({txtadr_y_tmp, txtadr_x_tmp}),
                .s_valid        (txtadr_valid),
                .s_ready        (txtadr_ready),
                
                .m_data         (s_samoler2d_packet),
                .m_valid        (s_sampler2d_valid),
                .m_ready        (s_sampler2d_ready)
            );
    
    genvar  i;
    generate
    for ( i = 0; i < SAMPLER2D_NUM; i = i+1 ) begin : loop_packet
        assign s_sampler2d_x[i*SAMPLER2D_X_WIDTH +: SAMPLER2D_X_WIDTH] = s_samoler2d_packet[i*(SAMPLER2D_Y_WIDTH+SAMPLER2D_X_WIDTH)+0                 +: SAMPLER2D_X_WIDTH];
        assign s_sampler2d_y[i*SAMPLER2D_Y_WIDTH +: SAMPLER2D_Y_WIDTH] = s_samoler2d_packet[i*(SAMPLER2D_Y_WIDTH+SAMPLER2D_X_WIDTH)+SAMPLER2D_X_WIDTH +: SAMPLER2D_Y_WIDTH];
    end
    endgenerate
    
    
    jelly_data_gather
            #(
                .PORT_NUM       (SAMPLER2D_NUM),
                .DATA_WIDTH     (COMPONENTS*DATA_WIDTH),
                .LINE_SIZE      (LINE_SIZE),
                .UNIT_SIZE      (UNIT_SIZE),
                .FIFO_PTR_WIDTH (12)
            )
        i_data_gather
            (
                .reset          (reset),
                .clk            (clk),
                
                .s_data         (m_sampler2d_data),
                .s_valid        (m_sampler2d_valid),
                .s_ready        (m_sampler2d_ready),
                
                .m_data         (sink_data),
                .m_valid        (sink_valid),
                .m_ready        (sink_ready)
            );
    
    
    integer     fp;
    initial begin
        if ( COMPONENTS == 1 ) begin
            fp = $fopen("out.pgm");
            $fdisplay(fp, "P2");
        end
        else begin
            fp = $fopen("out.ppm");
            $fdisplay(fp, "P3");
        end
        $fdisplay(fp, "640 480");
        $fdisplay(fp, "255");
        $display("file open");
    end
    
    always @(posedge clk) begin
        if ( !reset ) begin
            if ( sink_valid && sink_ready ) begin
                if ( COMPONENTS == 1 ) begin
                    $fdisplay(fp,  "%d", sink_data[7:0]);
                end
                else begin
                    $fdisplay(fp,  "%d %d %d", sink_data[7:0], sink_data[15:8], sink_data[23:16]);
                end
            end
        end
    end
    

    //  core
    jelly_texture_sampler
            #(
                .COMPONENT_NUM                  (COMPONENTS),
                .DATA_SIZE                      (DATA_SIZE),
        //      .DATA_WIDTH                     (DATA_WIDTH),
                
                .ADDR_WIDTH                     (ADDR_WIDTH),
                .ADDR_X_WIDTH                   (ADDR_X_WIDTH),
                .ADDR_Y_WIDTH                   (ADDR_Y_WIDTH),
                .STRIDE_C_WIDTH                 (STRIDE_C_WIDTH),
                .STRIDE_X_WIDTH                 (STRIDE_X_WIDTH),
                .STRIDE_Y_WIDTH                 (STRIDE_Y_WIDTH),
                
                .USE_BILINEAR                   (USE_BILINEAR),
                .USE_BORDER                     (USE_BORDER),
                                                
                .SAMPLER1D_NUM                  (SAMPLER1D_NUM),
                                                
                .SAMPLER2D_NUM                  (SAMPLER2D_NUM),
                .SAMPLER2D_USER_WIDTH           (SAMPLER2D_USER_WIDTH),
                .SAMPLER2D_X_INT_WIDTH          (SAMPLER2D_X_INT_WIDTH),
                .SAMPLER2D_X_FRAC_WIDTH         (SAMPLER2D_X_FRAC_WIDTH),
                .SAMPLER2D_Y_INT_WIDTH          (SAMPLER2D_Y_INT_WIDTH),
                .SAMPLER2D_Y_FRAC_WIDTH         (SAMPLER2D_Y_FRAC_WIDTH),
                .SAMPLER2D_COEFF_INT_WIDTH      (SAMPLER2D_COEFF_INT_WIDTH),
                .SAMPLER2D_COEFF_FRAC_WIDTH     (SAMPLER2D_COEFF_FRAC_WIDTH),
                .SAMPLER2D_S_REGS               (SAMPLER2D_S_REGS),
                .SAMPLER2D_M_REGS               (SAMPLER2D_M_REGS),
                .SAMPLER2D_USER_FIFO_PTR_WIDTH  (SAMPLER2D_USER_FIFO_PTR_WIDTH),
                .SAMPLER2D_USER_FIFO_RAM_TYPE   (SAMPLER2D_USER_FIFO_RAM_TYPE),
                .SAMPLER2D_USER_FIFO_M_REGS     (SAMPLER2D_USER_FIFO_M_REGS),
                .SAMPLER2D_X_WIDTH              (SAMPLER2D_X_WIDTH),
                .SAMPLER2D_Y_WIDTH              (SAMPLER2D_Y_WIDTH),
                .SAMPLER2D_COEFF_WIDTH          (SAMPLER2D_COEFF_WIDTH),
                .SAMPLER2D_USER_BITS            (SAMPLER2D_USER_BITS),
                
                .SAMPLER3D_NUM                  (SAMPLER3D_NUM),
                
                .L1_USE_LOOK_AHEAD              (L1_USE_LOOK_AHEAD),
                .L1_QUE_FIFO_PTR_WIDTH          (L1_QUE_FIFO_PTR_WIDTH),
                .L1_AR_FIFO_PTR_WIDTH           (L1_AR_FIFO_PTR_WIDTH),
                .L1_R_FIFO_PTR_WIDTH            (L1_R_FIFO_PTR_WIDTH),
                .L1_CACHE_NUM                   (L1_CACHE_NUM),
                .L1_WAY_NUM                     (L1_WAY_NUM),
                .L1_TAG_ADDR_WIDTH              (L1_TAG_ADDR_WIDTH),
                .L1_TAG_ALGORITHM               (L1_TAG_ALGORITHM),
                .L1_BLK_X_SIZE                  (L1_BLK_X_SIZE),
                .L1_BLK_Y_SIZE                  (L1_BLK_Y_SIZE),
                .L1_TAG_RAM_TYPE                (L1_TAG_RAM_TYPE),
                .L1_MEM_RAM_TYPE                (L1_MEM_RAM_TYPE),
                .L1_DATA_SIZE                   (L1_DATA_SIZE),
                
                .L2_PARALLEL_SIZE               (L2_PARALLEL_SIZE),
                .L2_USE_LOOK_AHEAD              (L2_USE_LOOK_AHEAD),
                .L2_QUE_FIFO_PTR_WIDTH          (L2_QUE_FIFO_PTR_WIDTH),
                .L2_AR_FIFO_PTR_WIDTH           (L2_AR_FIFO_PTR_WIDTH),
                .L2_R_FIFO_PTR_WIDTH            (L2_R_FIFO_PTR_WIDTH),
                .L2_WAY_NUM                     (L2_WAY_NUM),
                .L2_TAG_ADDR_WIDTH              (L2_TAG_ADDR_WIDTH),
                .L2_TAG_ALGORITHM               (L2_TAG_ALGORITHM),
                .L2_BLK_X_SIZE                  (L2_BLK_X_SIZE),
                .L2_BLK_Y_SIZE                  (L2_BLK_Y_SIZE),
                .L2_TAG_RAM_TYPE                (L2_TAG_RAM_TYPE),
                .L2_MEM_RAM_TYPE                (L2_MEM_RAM_TYPE),
                
                .M_AXI4_ID_WIDTH                (AXI4_ID_WIDTH),
                .M_AXI4_ADDR_WIDTH              (AXI4_ADDR_WIDTH),
                .M_AXI4_DATA_SIZE               (AXI4_DATA_SIZE),
                .M_AXI4_DATA_WIDTH              (AXI4_DATA_WIDTH),
                .M_AXI4_LEN_WIDTH               (AXI4_LEN_WIDTH),
                .M_AXI4_QOS_WIDTH               (AXI4_QOS_WIDTH),
                .M_AXI4_ARID                    (M_AXI4_ARID),
                .M_AXI4_ARSIZE                  (M_AXI4_ARSIZE),
                .M_AXI4_ARBURST                 (M_AXI4_ARBURST),
                .M_AXI4_ARLOCK                  (M_AXI4_ARLOCK),
                .M_AXI4_ARCACHE                 (M_AXI4_ARCACHE),
                .M_AXI4_ARPROT                  (M_AXI4_ARPROT),
                .M_AXI4_ARQOS                   (M_AXI4_ARQOS),
                .M_AXI4_ARREGION                (M_AXI4_ARREGION),
                .M_AXI4_REGS                    (M_AXI4_REGS),
                
                .DEVICE                         (DEVICE),
                
                .L1_LOG_ENABLE                  (0),
                .L2_LOG_ENABLE                  (1)
            )
        i_texture_sampler
            (
                .reset                          (reset),
                .clk                            (clk),
                
                .endian                         (1'b0),
                
                .param_addr                     (32'h0000_0000),
                .param_width                    (X_NUM),
                .param_height                   (Y_NUM),
                .param_stride_c                 ((1 << BLK_X_SIZE) * (1 << BLK_Y_SIZE)),
                .param_stride_x                 ((1 << BLK_X_SIZE) * (1 << BLK_Y_SIZE) * COMPONENTS),
                .param_stride_y                 (X_NUM             * (1 << BLK_Y_SIZE) * COMPONENTS),
                .param_border_value             (24'h000000),
                .param_x_op                     (3'b000),
                .param_y_op                     (3'b000),
                .param_nearestneighbor          (0),
                .clear_start                    (0),
                .clear_busy                     (),
                
                .status_l1_idle                 (status_l1_idle),
                .status_l1_stall                (status_l1_stall),
                .status_l1_access               (status_l1_access),
                .status_l1_hit                  (status_l1_hit),
                .status_l1_miss                 (status_l1_miss),
                .status_l1_blank                (status_l1_blank),
                .status_l2_idle                 (status_l2_idle),
                .status_l2_stall                (status_l2_stall),
                .status_l2_access               (status_l2_access),
                .status_l2_hit                  (status_l2_hit),
                .status_l2_miss                 (status_l2_miss),
                .status_l2_blank                (status_l2_blank),
                
                .s_sampler2d_user               (s_sampler2d_user),
                .s_sampler2d_x                  (s_sampler2d_x),
                .s_sampler2d_y                  (s_sampler2d_y),
                .s_sampler2d_strb               (s_sampler2d_strb),
                .s_sampler2d_valid              (s_sampler2d_valid),
                .s_sampler2d_ready              (s_sampler2d_ready),
                
                .m_sampler2d_user               (m_sampler2d_user),
                .m_sampler2d_border             (m_sampler2d_border),
                .m_sampler2d_data               (m_sampler2d_data),
                .m_sampler2d_valid              (m_sampler2d_valid),
                .m_sampler2d_ready              (m_sampler2d_ready),
                
                .m_axi4_arid                    (axi4_arid),
                .m_axi4_araddr                  (axi4_araddr),
                .m_axi4_arlen                   (axi4_arlen),
                .m_axi4_arsize                  (axi4_arsize),
                .m_axi4_arburst                 (axi4_arburst),
                .m_axi4_arlock                  (axi4_arlock),
                .m_axi4_arcache                 (axi4_arcache),
                .m_axi4_arprot                  (axi4_arprot),
                .m_axi4_arqos                   (axi4_arqos),
                .m_axi4_arregion                (axi4_arregion),
                .m_axi4_arvalid                 (axi4_arvalid),
                .m_axi4_arready                 (axi4_arready),
                .m_axi4_rid                     (axi4_rid),
                .m_axi4_rdata                   (axi4_rdata),
                .m_axi4_rresp                   (axi4_rresp),
                .m_axi4_rlast                   (axi4_rlast),
                .m_axi4_rvalid                  (axi4_rvalid),
                .m_axi4_rready                  (axi4_rready)
            );
    

    
    jelly_axi4_slave_model
            #(
                .AXI_ID_WIDTH                   (AXI4_ID_WIDTH),
                .AXI_ADDR_WIDTH                 (AXI4_ADDR_WIDTH),
                .AXI_QOS_WIDTH                  (AXI4_QOS_WIDTH),
                .AXI_LEN_WIDTH                  (AXI4_LEN_WIDTH),
                .AXI_DATA_SIZE                  (AXI4_DATA_SIZE),
                .MEM_WIDTH                      (17),
                
                .WRITE_LOG_FILE                 ("axi4_write.txt"),
                .READ_LOG_FILE                  ("axi4_read.txt"),
                
                .AW_DELAY                       (0),
                .AR_DELAY                       (0),
                
                .AW_FIFO_PTR_WIDTH              (4),
                .W_FIFO_PTR_WIDTH               (4),
                .B_FIFO_PTR_WIDTH               (4),
                .AR_FIFO_PTR_WIDTH              (4),
                .R_FIFO_PTR_WIDTH               (4),
                
                .AW_BUSY_RATE                   (0),
                .W_BUSY_RATE                    (0),
                .B_BUSY_RATE                    (0),
                .AR_BUSY_RATE                   (0),
                .R_BUSY_RATE                    (0)
            )
        i_axi4_slave_model
            (
                .aresetn                        (~reset),
                .aclk                           (clk),
                
                .s_axi4_awid                    (axi4_awid),
                .s_axi4_awaddr                  (axi4_awaddr),
                .s_axi4_awlen                   (axi4_awlen),
                .s_axi4_awsize                  (axi4_awsize),
                .s_axi4_awburst                 (axi4_awburst),
                .s_axi4_awlock                  (axi4_awlock),
                .s_axi4_awcache                 (axi4_awcache),
                .s_axi4_awprot                  (axi4_awprot),
                .s_axi4_awqos                   (axi4_awqos),
                .s_axi4_awvalid                 (axi4_awvalid),
                .s_axi4_awready                 (axi4_awready),
                .s_axi4_wdata                   (axi4_wdata),
                .s_axi4_wstrb                   (axi4_wstrb),
                .s_axi4_wlast                   (axi4_wlast),
                .s_axi4_wvalid                  (axi4_wvalid),
                .s_axi4_wready                  (axi4_wready),
                .s_axi4_bid                     (axi4_bid),
                .s_axi4_bresp                   (axi4_bresp),
                .s_axi4_bvalid                  (axi4_bvalid),
                .s_axi4_bready                  (axi4_bready),

                .s_axi4_arid                    (axi4_arid),
                .s_axi4_araddr                  (axi4_araddr),
                .s_axi4_arlen                   (axi4_arlen),
                .s_axi4_arsize                  (axi4_arsize),
                .s_axi4_arburst                 (axi4_arburst),
                .s_axi4_arlock                  (axi4_arlock),
                .s_axi4_arcache                 (axi4_arcache),
                .s_axi4_arprot                  (axi4_arprot),
                .s_axi4_arqos                   (axi4_arqos),
                .s_axi4_arvalid                 (axi4_arvalid),
                .s_axi4_arready                 (axi4_arready),
                .s_axi4_rid                     (axi4_rid),
                .s_axi4_rdata                   (axi4_rdata),
                .s_axi4_rresp                   (axi4_rresp),
                .s_axi4_rlast                   (axi4_rlast),
                .s_axi4_rvalid                  (axi4_rvalid),
                .s_axi4_rready                  (axi4_rready)
            );
    
endmodule


`default_nettype wire


// end of file
