// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_color_matrix
        #(
            parameter   int                                 USER_WIDTH           = 0,
            parameter   int                                 DATA_WIDTH           = 10,
            parameter   int                                 INTERNAL_WIDTH       = DATA_WIDTH + 2,


            parameter   int                                 COEFF_INT_WIDTH      = 17,
            parameter   int                                 COEFF_FRAC_WIDTH     = 8,
            parameter   int                                 COEFF3_INT_WIDTH     = COEFF_INT_WIDTH,
            parameter   int                                 COEFF3_FRAC_WIDTH    = COEFF_FRAC_WIDTH,
            parameter   bit                                 STATIC_COEFF         = 1,
            parameter                                       DEVICE               = "RTL", // "RTL" or "7SERIES"

            parameter   int                                 WB_ADR_WIDTH         = 8,
            parameter   int                                 WB_DAT_WIDTH         = 32,
            parameter   int                                 WB_SEL_WIDTH         = (WB_DAT_WIDTH / 8),

            parameter   int                                 INDEX_WIDTH          = 1,

            parameter                                       CORE_ID              = 32'h527a_2130,
            parameter                                       CORE_VERSION         = 32'h0001_0000,

            localparam  int                                 COEFF_WIDTH          = COEFF_INT_WIDTH + COEFF_FRAC_WIDTH,
            localparam  int                                 COEFF3_WIDTH         = COEFF3_INT_WIDTH + COEFF3_FRAC_WIDTH,

            parameter   bit             [2:0]               INIT_CTL_CONTROL     = 1,
            parameter   bit     signed  [COEFF_WIDTH-1:0]   INIT_PARAM_MATRIX00  = COEFF_WIDTH'(1 << COEFF_FRAC_WIDTH),
            parameter   bit     signed  [COEFF_WIDTH-1:0]   INIT_PARAM_MATRIX01  = 0,
            parameter   bit     signed  [COEFF_WIDTH-1:0]   INIT_PARAM_MATRIX02  = 0,
            parameter   bit     signed  [COEFF3_WIDTH-1:0]  INIT_PARAM_MATRIX03  = 0,
            parameter   bit     signed  [COEFF_WIDTH-1:0]   INIT_PARAM_MATRIX10  = 0,
            parameter   bit     signed  [COEFF_WIDTH-1:0]   INIT_PARAM_MATRIX11  = COEFF_WIDTH'(1 << COEFF_FRAC_WIDTH),
            parameter   bit     signed  [COEFF_WIDTH-1:0]   INIT_PARAM_MATRIX12  = 0,
            parameter   bit     signed  [COEFF3_WIDTH-1:0]  INIT_PARAM_MATRIX13  = 0,
            parameter   bit     signed  [COEFF_WIDTH-1:0]   INIT_PARAM_MATRIX20  = 0,
            parameter   bit     signed  [COEFF_WIDTH-1:0]   INIT_PARAM_MATRIX21  = 0,
            parameter   bit     signed  [COEFF_WIDTH-1:0]   INIT_PARAM_MATRIX22  = COEFF_WIDTH'(1 << COEFF_FRAC_WIDTH),
            parameter   bit     signed  [COEFF3_WIDTH-1:0]  INIT_PARAM_MATRIX23  = 0,
            parameter   bit             [DATA_WIDTH-1:0]    INIT_PARAM_CLIP_MIN0 = {DATA_WIDTH{1'b0}},
            parameter   bit             [DATA_WIDTH-1:0]    INIT_PARAM_CLIP_MAX0 = {DATA_WIDTH{1'b1}},
            parameter   bit             [DATA_WIDTH-1:0]    INIT_PARAM_CLIP_MIN1 = {DATA_WIDTH{1'b0}},
            parameter   bit             [DATA_WIDTH-1:0]    INIT_PARAM_CLIP_MAX1 = {DATA_WIDTH{1'b1}},
            parameter   bit             [DATA_WIDTH-1:0]    INIT_PARAM_CLIP_MIN2 = {DATA_WIDTH{1'b0}},
            parameter   bit             [DATA_WIDTH-1:0]    INIT_PARAM_CLIP_MAX2 = {DATA_WIDTH{1'b1}},
            
            localparam  int                                 USER_BITS            = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire                        in_update_req,
            
            input   wire                        s_img_row_first,
            input   wire                        s_img_row_last,
            input   wire                        s_img_col_first,
            input   wire                        s_img_col_last,
            input   wire                        s_img_de,
            input   wire    [USER_BITS-1:0]     s_img_user,
            input   wire    [DATA_WIDTH-1:0]    s_img_color0,
            input   wire    [DATA_WIDTH-1:0]    s_img_color1,
            input   wire    [DATA_WIDTH-1:0]    s_img_color2,
            input   wire                        s_img_valid,
            
            output  wire                        m_img_row_first,
            output  wire                        m_img_row_last,
            output  wire                        m_img_col_first,
            output  wire                        m_img_col_last,
            output  wire                        m_img_de,
            output  wire    [USER_BITS-1:0]     m_img_user,
            output  wire    [DATA_WIDTH-1:0]    m_img_color0,
            output  wire    [DATA_WIDTH-1:0]    m_img_color1,
            output  wire    [DATA_WIDTH-1:0]    m_img_color2,
            output  wire                        m_img_valid,

            input   wire                        s_wb_rst_i,
            input   wire                        s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  reg                         s_wb_ack_o
        );
    
    
    // -------------------------------------
    //  registers domain
    // -------------------------------------

    initial if ( WB_ADR_WIDTH < 8 ) $error();
    
    // register address offset
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_ID               = WB_ADR_WIDTH'('h00);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_VERSION          = WB_ADR_WIDTH'('h01);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_CONTROL           = WB_ADR_WIDTH'('h04);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_STATUS            = WB_ADR_WIDTH'('h05);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_INDEX             = WB_ADR_WIDTH'('h07);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX00        = WB_ADR_WIDTH'('h10);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX01        = WB_ADR_WIDTH'('h11);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX02        = WB_ADR_WIDTH'('h12);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX03        = WB_ADR_WIDTH'('h13);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX10        = WB_ADR_WIDTH'('h14);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX11        = WB_ADR_WIDTH'('h15);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX12        = WB_ADR_WIDTH'('h16);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX13        = WB_ADR_WIDTH'('h17);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX20        = WB_ADR_WIDTH'('h18);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX21        = WB_ADR_WIDTH'('h19);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX22        = WB_ADR_WIDTH'('h1a);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_MATRIX23        = WB_ADR_WIDTH'('h1b);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_CLIP_MIN0       = WB_ADR_WIDTH'('h20);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_CLIP_MAX0       = WB_ADR_WIDTH'('h21);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_CLIP_MIN1       = WB_ADR_WIDTH'('h22);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_CLIP_MAX1       = WB_ADR_WIDTH'('h23);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_CLIP_MIN2       = WB_ADR_WIDTH'('h24);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_CLIP_MAX2       = WB_ADR_WIDTH'('h25);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CFG_COEFF0_WIDTH      = WB_ADR_WIDTH'('h40);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CFG_COEFF1_WIDTH      = WB_ADR_WIDTH'('h41);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CFG_COEFF2_WIDTH      = WB_ADR_WIDTH'('h42);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CFG_COEFF3_WIDTH      = WB_ADR_WIDTH'('h43);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CFG_COEFF0_FRAC_WIDTH = WB_ADR_WIDTH'('h44);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CFG_COEFF1_FRAC_WIDTH = WB_ADR_WIDTH'('h45);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CFG_COEFF2_FRAC_WIDTH = WB_ADR_WIDTH'('h46);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CFG_COEFF3_FRAC_WIDTH = WB_ADR_WIDTH'('h47);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX00      = WB_ADR_WIDTH'('h90);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX01      = WB_ADR_WIDTH'('h91);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX02      = WB_ADR_WIDTH'('h92);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX03      = WB_ADR_WIDTH'('h93);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX10      = WB_ADR_WIDTH'('h94);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX11      = WB_ADR_WIDTH'('h95);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX12      = WB_ADR_WIDTH'('h96);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX13      = WB_ADR_WIDTH'('h97);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX20      = WB_ADR_WIDTH'('h98);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX21      = WB_ADR_WIDTH'('h99);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX22      = WB_ADR_WIDTH'('h9a);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_MATRIX23      = WB_ADR_WIDTH'('h9b);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_CLIP_MIN0     = WB_ADR_WIDTH'('ha0);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_CLIP_MAX0     = WB_ADR_WIDTH'('ha1);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_CLIP_MIN1     = WB_ADR_WIDTH'('ha2);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_CLIP_MAX1     = WB_ADR_WIDTH'('ha3);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_CLIP_MIN2     = WB_ADR_WIDTH'('ha4);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_CLIP_MAX2     = WB_ADR_WIDTH'('ha5);
    

    // registers
    logic           [2:0]               reg_ctl_control; 
    logic   signed  [COEFF_WIDTH-1:0]   reg_param_matrix00;
    logic   signed  [COEFF_WIDTH-1:0]   reg_param_matrix01;
    logic   signed  [COEFF_WIDTH-1:0]   reg_param_matrix02;
    logic   signed  [COEFF3_WIDTH-1:0]  reg_param_matrix03;
    logic   signed  [COEFF_WIDTH-1:0]   reg_param_matrix10;
    logic   signed  [COEFF_WIDTH-1:0]   reg_param_matrix11;
    logic   signed  [COEFF_WIDTH-1:0]   reg_param_matrix12;
    logic   signed  [COEFF3_WIDTH-1:0]  reg_param_matrix13;
    logic   signed  [COEFF_WIDTH-1:0]   reg_param_matrix20;
    logic   signed  [COEFF_WIDTH-1:0]   reg_param_matrix21;
    logic   signed  [COEFF_WIDTH-1:0]   reg_param_matrix22;
    logic   signed  [COEFF3_WIDTH-1:0]  reg_param_matrix23;
    logic           [DATA_WIDTH-1:0]    reg_param_clip_min0;
    logic           [DATA_WIDTH-1:0]    reg_param_clip_max0;
    logic           [DATA_WIDTH-1:0]    reg_param_clip_min1;
    logic           [DATA_WIDTH-1:0]    reg_param_clip_max1;
    logic           [DATA_WIDTH-1:0]    reg_param_clip_min2;
    logic           [DATA_WIDTH-1:0]    reg_param_clip_max2;
    
    // shadow registers(core domain)
    logic   signed  [COEFF_WIDTH-1:0]   core_param_matrix00;
    logic   signed  [COEFF_WIDTH-1:0]   core_param_matrix01;
    logic   signed  [COEFF_WIDTH-1:0]   core_param_matrix02;
    logic   signed  [COEFF3_WIDTH-1:0]  core_param_matrix03;
    logic   signed  [COEFF_WIDTH-1:0]   core_param_matrix10;
    logic   signed  [COEFF_WIDTH-1:0]   core_param_matrix11;
    logic   signed  [COEFF_WIDTH-1:0]   core_param_matrix12;
    logic   signed  [COEFF3_WIDTH-1:0]  core_param_matrix13;
    logic   signed  [COEFF_WIDTH-1:0]   core_param_matrix20;
    logic   signed  [COEFF_WIDTH-1:0]   core_param_matrix21;
    logic   signed  [COEFF_WIDTH-1:0]   core_param_matrix22;
    logic   signed  [COEFF3_WIDTH-1:0]  core_param_matrix23;
    logic           [DATA_WIDTH-1:0]    core_param_clip_min0;
    logic           [DATA_WIDTH-1:0]    core_param_clip_max0;
    logic           [DATA_WIDTH-1:0]    core_param_clip_min1;
    logic           [DATA_WIDTH-1:0]    core_param_clip_max1;
    logic           [DATA_WIDTH-1:0]    core_param_clip_min2;
    logic           [DATA_WIDTH-1:0]    core_param_clip_max2;
    
    // handshake with core domain
    wire    [INDEX_WIDTH-1:0]   update_index;
    wire                        update_ack;
    wire    [INDEX_WIDTH-1:0]   ctl_index;
    
    jelly_param_update_master
            #(
                .INDEX_WIDTH    (INDEX_WIDTH)
            )
        i_param_update_master
            (
                .reset          (s_wb_rst_i),
                .clk            (s_wb_clk_i),
                .cke            (1'b1),
                .in_index       (update_index),
                .out_ack        (update_ack),
                .out_index      (ctl_index)
            );
    
    // write mask
    function [WB_DAT_WIDTH-1:0] write_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] wdat,
                                        input [WB_SEL_WIDTH-1:0] msk
                                    );
    begin
        for ( int i = 0; i < WB_DAT_WIDTH; ++i ) begin
            write_mask[i] = msk[i/8] ? wdat[i] : org[i];
        end
    end
    endfunction
    
    // registers control
    always_ff @(posedge s_wb_clk_i) begin
        if ( s_wb_rst_i ) begin
            reg_ctl_control     <= INIT_CTL_CONTROL | 3'b001;
            reg_param_matrix00  <= INIT_PARAM_MATRIX00;
            reg_param_matrix01  <= INIT_PARAM_MATRIX01;
            reg_param_matrix02  <= INIT_PARAM_MATRIX02;
            reg_param_matrix03  <= INIT_PARAM_MATRIX03;
            reg_param_matrix10  <= INIT_PARAM_MATRIX10;
            reg_param_matrix11  <= INIT_PARAM_MATRIX11;
            reg_param_matrix12  <= INIT_PARAM_MATRIX12;
            reg_param_matrix13  <= INIT_PARAM_MATRIX13;
            reg_param_matrix20  <= INIT_PARAM_MATRIX20;
            reg_param_matrix21  <= INIT_PARAM_MATRIX21;
            reg_param_matrix22  <= INIT_PARAM_MATRIX22;
            reg_param_matrix23  <= INIT_PARAM_MATRIX23;
            reg_param_clip_min0 <= INIT_PARAM_CLIP_MIN0;
            reg_param_clip_max0 <= INIT_PARAM_CLIP_MAX0;
            reg_param_clip_min1 <= INIT_PARAM_CLIP_MIN1;
            reg_param_clip_max1 <= INIT_PARAM_CLIP_MAX1;
            reg_param_clip_min2 <= INIT_PARAM_CLIP_MIN2;
            reg_param_clip_max2 <= INIT_PARAM_CLIP_MAX2;
        end
        else begin
            // auto clear
            if ( update_ack && !reg_ctl_control[2] ) begin
                reg_ctl_control[1] <= 1'b0;
            end
            
            // write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_CTL_CONTROL:       reg_ctl_control     <=            3'(write_mask(WB_DAT_WIDTH'(reg_ctl_control    ), s_wb_dat_i, s_wb_sel_i)) | 3'b001;
                ADR_PARAM_MATRIX00:    reg_param_matrix00  <=  COEFF_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix00 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_MATRIX01:    reg_param_matrix01  <=  COEFF_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix01 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_MATRIX02:    reg_param_matrix02  <=  COEFF_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix02 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_MATRIX03:    reg_param_matrix03  <= COEFF3_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix03 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_MATRIX10:    reg_param_matrix10  <=  COEFF_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix10 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_MATRIX11:    reg_param_matrix11  <=  COEFF_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix11 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_MATRIX12:    reg_param_matrix12  <=  COEFF_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix12 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_MATRIX13:    reg_param_matrix13  <= COEFF3_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix13 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_MATRIX20:    reg_param_matrix20  <=  COEFF_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix20 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_MATRIX21:    reg_param_matrix21  <=  COEFF_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix21 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_MATRIX22:    reg_param_matrix22  <=  COEFF_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix22 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_MATRIX23:    reg_param_matrix23  <= COEFF3_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_matrix23 ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_CLIP_MIN0:   reg_param_clip_min0 <=   DATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_clip_min0), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_CLIP_MAX0:   reg_param_clip_max0 <=   DATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_clip_max0), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_CLIP_MIN1:   reg_param_clip_min1 <=   DATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_clip_min1), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_CLIP_MAX1:   reg_param_clip_max1 <=   DATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_clip_max1), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_CLIP_MIN2:   reg_param_clip_min2 <=   DATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_clip_min2), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_CLIP_MAX2:   reg_param_clip_max2 <=   DATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_clip_max2), s_wb_dat_i, s_wb_sel_i));
                default: ;
                endcase
            end
        end
    end
    
    // read (shadow register は クロック同期してないのであくまでデバッグ用)
    always_comb begin
        s_wb_dat_o = '0;
        case ( s_wb_adr_i )
        ADR_CORE_ID:                s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID             );
        ADR_CORE_VERSION:           s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION        );
        ADR_CTL_CONTROL:            s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_control     );
        ADR_CTL_STATUS:             s_wb_dat_o = WB_DAT_WIDTH'(1                   );
        ADR_CTL_INDEX:              s_wb_dat_o = WB_DAT_WIDTH'(ctl_index           );
        ADR_PARAM_MATRIX00:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix00  );
        ADR_PARAM_MATRIX01:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix01  );
        ADR_PARAM_MATRIX02:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix02  );
        ADR_PARAM_MATRIX03:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix03  );
        ADR_PARAM_MATRIX10:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix10  );
        ADR_PARAM_MATRIX11:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix11  );
        ADR_PARAM_MATRIX12:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix12  );
        ADR_PARAM_MATRIX13:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix13  );
        ADR_PARAM_MATRIX20:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix20  );
        ADR_PARAM_MATRIX21:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix21  );
        ADR_PARAM_MATRIX22:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix22  );
        ADR_PARAM_MATRIX23:         s_wb_dat_o = WB_DAT_WIDTH'(reg_param_matrix23  );
        ADR_PARAM_CLIP_MIN0:        s_wb_dat_o = WB_DAT_WIDTH'(reg_param_clip_min0 );
        ADR_PARAM_CLIP_MAX0:        s_wb_dat_o = WB_DAT_WIDTH'(reg_param_clip_max0 );
        ADR_PARAM_CLIP_MIN1:        s_wb_dat_o = WB_DAT_WIDTH'(reg_param_clip_min1 );
        ADR_PARAM_CLIP_MAX1:        s_wb_dat_o = WB_DAT_WIDTH'(reg_param_clip_max1 );
        ADR_PARAM_CLIP_MIN2:        s_wb_dat_o = WB_DAT_WIDTH'(reg_param_clip_min2 );
        ADR_PARAM_CLIP_MAX2:        s_wb_dat_o = WB_DAT_WIDTH'(reg_param_clip_max2 );
        ADR_CFG_COEFF0_WIDTH:       s_wb_dat_o = WB_DAT_WIDTH'(COEFF_WIDTH         );
        ADR_CFG_COEFF1_WIDTH:       s_wb_dat_o = WB_DAT_WIDTH'(COEFF_WIDTH         );
        ADR_CFG_COEFF2_WIDTH:       s_wb_dat_o = WB_DAT_WIDTH'(COEFF_WIDTH         );
        ADR_CFG_COEFF3_WIDTH:       s_wb_dat_o = WB_DAT_WIDTH'(COEFF3_WIDTH        );
        ADR_CFG_COEFF0_FRAC_WIDTH:  s_wb_dat_o = WB_DAT_WIDTH'(COEFF_FRAC_WIDTH    );
        ADR_CFG_COEFF1_FRAC_WIDTH:  s_wb_dat_o = WB_DAT_WIDTH'(COEFF_FRAC_WIDTH    );
        ADR_CFG_COEFF2_FRAC_WIDTH:  s_wb_dat_o = WB_DAT_WIDTH'(COEFF_FRAC_WIDTH    );
        ADR_CFG_COEFF3_FRAC_WIDTH:  s_wb_dat_o = WB_DAT_WIDTH'(COEFF3_FRAC_WIDTH   );
        ADR_CURRENT_MATRIX00:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix00 );   // for debug
        ADR_CURRENT_MATRIX01:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix01 );   // for debug
        ADR_CURRENT_MATRIX02:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix02 );   // for debug
        ADR_CURRENT_MATRIX03:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix03 );   // for debug
        ADR_CURRENT_MATRIX10:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix10 );   // for debug
        ADR_CURRENT_MATRIX11:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix11 );   // for debug
        ADR_CURRENT_MATRIX12:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix12 );   // for debug
        ADR_CURRENT_MATRIX13:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix13 );   // for debug
        ADR_CURRENT_MATRIX20:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix20 );   // for debug
        ADR_CURRENT_MATRIX21:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix21 );   // for debug
        ADR_CURRENT_MATRIX22:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix22 );   // for debug
        ADR_CURRENT_MATRIX23:       s_wb_dat_o = WB_DAT_WIDTH'(core_param_matrix23 );   // for debug
        ADR_CURRENT_CLIP_MIN0:      s_wb_dat_o = WB_DAT_WIDTH'(core_param_clip_min0);   // for debug
        ADR_CURRENT_CLIP_MAX0:      s_wb_dat_o = WB_DAT_WIDTH'(core_param_clip_max0);   // for debug
        ADR_CURRENT_CLIP_MIN1:      s_wb_dat_o = WB_DAT_WIDTH'(core_param_clip_min1);   // for debug
        ADR_CURRENT_CLIP_MAX1:      s_wb_dat_o = WB_DAT_WIDTH'(core_param_clip_max1);   // for debug
        ADR_CURRENT_CLIP_MIN2:      s_wb_dat_o = WB_DAT_WIDTH'(core_param_clip_min2);   // for debug
        ADR_CURRENT_CLIP_MAX2:      s_wb_dat_o = WB_DAT_WIDTH'(core_param_clip_max2);   // for debug
        default: ;
        endcase
    end
    
    always_comb s_wb_ack_o = s_wb_stb_i;
    
    
    
    
    // -------------------------------------
    //  core domain
    // -------------------------------------
    
    // handshake with registers domain
    wire    update_trig = (s_img_valid & s_img_row_first & s_img_col_first);
    wire    update_en;
    
    jelly_param_update_slave
            #(
                .INDEX_WIDTH    (INDEX_WIDTH)
            )
        i_param_update_slave
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .in_trigger     (update_trig),
                .in_update      (reg_ctl_control[1]),
                
                .out_update     (update_en),
                .out_index      (update_index)
            );
    
    // wait for frame start to update parameters
    reg                 reg_update_req;
    always @(posedge clk) begin
        if ( reset ) begin
            reg_update_req       <= 1'b0;
            
            core_param_matrix00  <= INIT_PARAM_MATRIX00;
            core_param_matrix01  <= INIT_PARAM_MATRIX01;
            core_param_matrix02  <= INIT_PARAM_MATRIX02;
            core_param_matrix03  <= INIT_PARAM_MATRIX03;
            core_param_matrix10  <= INIT_PARAM_MATRIX10;
            core_param_matrix11  <= INIT_PARAM_MATRIX11;
            core_param_matrix12  <= INIT_PARAM_MATRIX12;
            core_param_matrix13  <= INIT_PARAM_MATRIX13;
            core_param_matrix20  <= INIT_PARAM_MATRIX20;
            core_param_matrix21  <= INIT_PARAM_MATRIX21;
            core_param_matrix22  <= INIT_PARAM_MATRIX22;
            core_param_matrix23  <= INIT_PARAM_MATRIX23;
            core_param_clip_min0 <= INIT_PARAM_CLIP_MIN0;
            core_param_clip_max0 <= INIT_PARAM_CLIP_MAX0;
            core_param_clip_min1 <= INIT_PARAM_CLIP_MIN1;
            core_param_clip_max1 <= INIT_PARAM_CLIP_MAX1;
            core_param_clip_min2 <= INIT_PARAM_CLIP_MIN2;
            core_param_clip_max2 <= INIT_PARAM_CLIP_MAX2;
        end
        else begin
            if ( in_update_req ) begin
                reg_update_req <= 1'b1;
            end
            
            if ( cke ) begin
                if ( reg_update_req & update_trig & update_en ) begin
                    reg_update_req        <= 1'b0;
                    
                    core_param_matrix00  <= reg_param_matrix00;
                    core_param_matrix01  <= reg_param_matrix01;
                    core_param_matrix02  <= reg_param_matrix02;
                    core_param_matrix03  <= reg_param_matrix03;
                    core_param_matrix10  <= reg_param_matrix10;
                    core_param_matrix11  <= reg_param_matrix11;
                    core_param_matrix12  <= reg_param_matrix12;
                    core_param_matrix13  <= reg_param_matrix13;
                    core_param_matrix20  <= reg_param_matrix20;
                    core_param_matrix21  <= reg_param_matrix21;
                    core_param_matrix22  <= reg_param_matrix22;
                    core_param_matrix23  <= reg_param_matrix23;
                    core_param_clip_min0 <= reg_param_clip_min0;
                    core_param_clip_max0 <= reg_param_clip_max0;
                    core_param_clip_min1 <= reg_param_clip_min1;
                    core_param_clip_max1 <= reg_param_clip_max1;
                    core_param_clip_min2 <= reg_param_clip_min2;
                    core_param_clip_max2 <= reg_param_clip_max2;
                end
            end
        end
    end
    
    
    // core
    jelly2_img_color_matrix_core
            #(
                .USER_WIDTH             (USER_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH),
                .INTERNAL_WIDTH         (INTERNAL_WIDTH),
                
                .COEFF_INT_WIDTH        (COEFF_INT_WIDTH),
                .COEFF_FRAC_WIDTH       (COEFF_FRAC_WIDTH),
                .COEFF3_INT_WIDTH       (COEFF3_INT_WIDTH),
                .COEFF3_FRAC_WIDTH      (COEFF3_FRAC_WIDTH),
                .STATIC_COEFF           (STATIC_COEFF),
                .DEVICE                 (DEVICE)
            )
        i_img_color_matrix_core
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .param_matrix00         (core_param_matrix00),
                .param_matrix01         (core_param_matrix01),
                .param_matrix02         (core_param_matrix02),
                .param_matrix03         (core_param_matrix03),
                .param_matrix10         (core_param_matrix10),
                .param_matrix11         (core_param_matrix11),
                .param_matrix12         (core_param_matrix12),
                .param_matrix13         (core_param_matrix13),
                .param_matrix20         (core_param_matrix20),
                .param_matrix21         (core_param_matrix21),
                .param_matrix22         (core_param_matrix22),
                .param_matrix23         (core_param_matrix23),
                .param_clip_min0        (core_param_clip_min0),
                .param_clip_max0        (core_param_clip_max0),
                .param_clip_min1        (core_param_clip_min1),
                .param_clip_max1        (core_param_clip_max1),
                .param_clip_min2        (core_param_clip_min2),
                .param_clip_max2        (core_param_clip_max2),
                
                .s_img_row_first        (s_img_row_first),
                .s_img_row_last         (s_img_row_last),
                .s_img_col_first        (s_img_col_first),
                .s_img_col_last         (s_img_col_last),
                .s_img_de               (s_img_de),
                .s_img_user             (s_img_user),
                .s_img_color0           (s_img_color0),
                .s_img_color1           (s_img_color1),
                .s_img_color2           (s_img_color2),
                .s_img_valid            (s_img_valid),
                
                .m_img_row_first        (m_img_row_first),
                .m_img_row_last         (m_img_row_last),
                .m_img_col_first        (m_img_col_first),
                .m_img_col_last         (m_img_col_last),
                .m_img_de               (m_img_de),
                .m_img_user             (m_img_user),
                .m_img_color0           (m_img_color0),
                .m_img_color1           (m_img_color1),
                .m_img_color2           (m_img_color2),
                .m_img_valid            (m_img_valid)
            );
    
    
endmodule


`default_nettype wire


// end of file
