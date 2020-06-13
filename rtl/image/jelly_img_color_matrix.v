// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_img_color_matrix
        #(
            parameter   USER_WIDTH           = 0,
            parameter   DATA_WIDTH           = 10,
            parameter   INTERNAL_WIDTH       = DATA_WIDTH + 2,
            
            parameter   COEFF_INT_WIDTH      = 17,
            parameter   COEFF_FRAC_WIDTH     = 8,
            parameter   COEFF3_INT_WIDTH     = COEFF_INT_WIDTH,
            parameter   COEFF3_FRAC_WIDTH    = COEFF_FRAC_WIDTH,
            parameter   STATIC_COEFF         = 1,
            parameter   DEVICE               = "7SERIES", // "RTL" or "7SERIES"
            
            parameter   WB_ADR_WIDTH         = 8,
            parameter   WB_DAT_WIDTH         = 32,
            parameter   WB_SEL_WIDTH         = (WB_DAT_WIDTH / 8),
            
            parameter   INIT_PARAM_MATRIX00  = (1 << COEFF_FRAC_WIDTH),
            parameter   INIT_PARAM_MATRIX01  = 0,
            parameter   INIT_PARAM_MATRIX02  = 0,
            parameter   INIT_PARAM_MATRIX03  = 0,
            parameter   INIT_PARAM_MATRIX10  = 0,
            parameter   INIT_PARAM_MATRIX11  = (1 << COEFF_FRAC_WIDTH),
            parameter   INIT_PARAM_MATRIX12  = 0,
            parameter   INIT_PARAM_MATRIX13  = 0,
            parameter   INIT_PARAM_MATRIX20  = 0,
            parameter   INIT_PARAM_MATRIX21  = 0,
            parameter   INIT_PARAM_MATRIX22  = (1 << COEFF_FRAC_WIDTH),
            parameter   INIT_PARAM_MATRIX23  = 0,
            parameter   INIT_PARAM_CLIP_MIN0 = {DATA_WIDTH{1'b0}},
            parameter   INIT_PARAM_CLIP_MAX0 = {DATA_WIDTH{1'b1}},
            parameter   INIT_PARAM_CLIP_MIN1 = {DATA_WIDTH{1'b0}},
            parameter   INIT_PARAM_CLIP_MAX1 = {DATA_WIDTH{1'b1}},
            parameter   INIT_PARAM_CLIP_MIN2 = {DATA_WIDTH{1'b0}},
            parameter   INIT_PARAM_CLIP_MAX2 = {DATA_WIDTH{1'b1}},
            
            // local
            parameter   COEFF_WIDTH          = COEFF_INT_WIDTH + COEFF_FRAC_WIDTH,
            parameter   COEFF3_WIDTH         = COEFF3_INT_WIDTH + COEFF3_FRAC_WIDTH,
            parameter   USER_BITS            = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire                        s_wb_rst_i,
            input   wire                        s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o,
            
            input   wire                        s_img_line_first,
            input   wire                        s_img_line_last,
            input   wire                        s_img_pixel_first,
            input   wire                        s_img_pixel_last,
            input   wire                        s_img_de,
            input   wire    [USER_BITS-1:0]     s_img_user,
            input   wire    [DATA_WIDTH-1:0]    s_img_color0,
            input   wire    [DATA_WIDTH-1:0]    s_img_color1,
            input   wire    [DATA_WIDTH-1:0]    s_img_color2,
            input   wire                        s_img_valid,
            
            output  wire                        m_img_line_first,
            output  wire                        m_img_line_last,
            output  wire                        m_img_pixel_first,
            output  wire                        m_img_pixel_last,
            output  wire                        m_img_de,
            output  wire    [USER_BITS-1:0]     m_img_user,
            output  wire    [DATA_WIDTH-1:0]    m_img_color0,
            output  wire    [DATA_WIDTH-1:0]    m_img_color1,
            output  wire    [DATA_WIDTH-1:0]    m_img_color2,
            output  wire                        m_img_valid
        );
    
    
    
    // register
    localparam  ADR_PARAM_MATRIX00  = 8'h00;
    localparam  ADR_PARAM_MATRIX01  = 8'h01;
    localparam  ADR_PARAM_MATRIX02  = 8'h02;
    localparam  ADR_PARAM_MATRIX03  = 8'h03;
    localparam  ADR_PARAM_MATRIX10  = 8'h04;
    localparam  ADR_PARAM_MATRIX11  = 8'h05;
    localparam  ADR_PARAM_MATRIX12  = 8'h06;
    localparam  ADR_PARAM_MATRIX13  = 8'h07;
    localparam  ADR_PARAM_MATRIX20  = 8'h08;
    localparam  ADR_PARAM_MATRIX21  = 8'h09;
    localparam  ADR_PARAM_MATRIX22  = 8'h0a;
    localparam  ADR_PARAM_MATRIX23  = 8'h0b;
    localparam  ADR_PARAM_CLIP_MIN0 = 8'h10;
    localparam  ADR_PARAM_CLIP_MAX0 = 8'h11;
    localparam  ADR_PARAM_CLIP_MIN1 = 8'h12;
    localparam  ADR_PARAM_CLIP_MAX1 = 8'h13;
    localparam  ADR_PARAM_CLIP_MIN2 = 8'h14;
    localparam  ADR_PARAM_CLIP_MAX2 = 8'h15;
    
    
    reg     signed  [COEFF_WIDTH-1:0]   reg_param_matrix00;
    reg     signed  [COEFF_WIDTH-1:0]   reg_param_matrix01;
    reg     signed  [COEFF_WIDTH-1:0]   reg_param_matrix02;
    reg     signed  [COEFF3_WIDTH-1:0]  reg_param_matrix03;
    reg     signed  [COEFF_WIDTH-1:0]   reg_param_matrix10;
    reg     signed  [COEFF_WIDTH-1:0]   reg_param_matrix11;
    reg     signed  [COEFF_WIDTH-1:0]   reg_param_matrix12;
    reg     signed  [COEFF3_WIDTH-1:0]  reg_param_matrix13;
    reg     signed  [COEFF_WIDTH-1:0]   reg_param_matrix20;
    reg     signed  [COEFF_WIDTH-1:0]   reg_param_matrix21;
    reg     signed  [COEFF_WIDTH-1:0]   reg_param_matrix22;
    reg     signed  [COEFF3_WIDTH-1:0]  reg_param_matrix23;
    reg             [DATA_WIDTH-1:0]    reg_param_clip_min0;
    reg             [DATA_WIDTH-1:0]    reg_param_clip_max0;
    reg             [DATA_WIDTH-1:0]    reg_param_clip_min1;
    reg             [DATA_WIDTH-1:0]    reg_param_clip_max1;
    reg             [DATA_WIDTH-1:0]    reg_param_clip_min2;
    reg             [DATA_WIDTH-1:0]    reg_param_clip_max2;
    
    
    function [WB_DAT_WIDTH-1:0] reg_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] wdat,
                                        input [WB_SEL_WIDTH-1:0] msk
                                    );
    integer i;
    begin
        for ( i = 0; i < WB_DAT_WIDTH; i = i+1 ) begin
            reg_mask[i] = msk[i/8] ? wdat[i] : org[i];
        end
    end
    endfunction
    
    always @(posedge s_wb_clk_i) begin
        if ( s_wb_rst_i ) begin
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
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_PARAM_MATRIX00:    reg_param_matrix00  <= reg_mask(reg_param_matrix00 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_MATRIX01:    reg_param_matrix01  <= reg_mask(reg_param_matrix01 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_MATRIX02:    reg_param_matrix02  <= reg_mask(reg_param_matrix02 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_MATRIX03:    reg_param_matrix03  <= reg_mask(reg_param_matrix03 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_MATRIX10:    reg_param_matrix10  <= reg_mask(reg_param_matrix10 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_MATRIX11:    reg_param_matrix11  <= reg_mask(reg_param_matrix11 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_MATRIX12:    reg_param_matrix12  <= reg_mask(reg_param_matrix12 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_MATRIX13:    reg_param_matrix13  <= reg_mask(reg_param_matrix13 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_MATRIX20:    reg_param_matrix20  <= reg_mask(reg_param_matrix20 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_MATRIX21:    reg_param_matrix21  <= reg_mask(reg_param_matrix21 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_MATRIX22:    reg_param_matrix22  <= reg_mask(reg_param_matrix22 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_MATRIX23:    reg_param_matrix23  <= reg_mask(reg_param_matrix23 , s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_CLIP_MIN0:   reg_param_clip_min0 <= reg_mask(reg_param_clip_min0, s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_CLIP_MAX0:   reg_param_clip_max0 <= reg_mask(reg_param_clip_max0, s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_CLIP_MIN1:   reg_param_clip_min1 <= reg_mask(reg_param_clip_min1, s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_CLIP_MAX1:   reg_param_clip_max1 <= reg_mask(reg_param_clip_max1, s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_CLIP_MIN2:   reg_param_clip_min2 <= reg_mask(reg_param_clip_min2, s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_CLIP_MAX2:   reg_param_clip_max2 <= reg_mask(reg_param_clip_max2, s_wb_dat_i, s_wb_sel_i);
                endcase
            end
        end
    end
    
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix00 = reg_param_matrix00;
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix01 = reg_param_matrix01;
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix02 = reg_param_matrix02;
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix03 = reg_param_matrix03;
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix10 = reg_param_matrix10;
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix11 = reg_param_matrix11;
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix12 = reg_param_matrix12;
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix13 = reg_param_matrix13;
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix20 = reg_param_matrix20;
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix21 = reg_param_matrix21;
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix22 = reg_param_matrix22;
    wire    signed  [WB_DAT_WIDTH-1:0]  signed_param_matrix23 = reg_param_matrix23;
    
    reg             [WB_DAT_WIDTH-1:0]  tmp_wb_dat_o;
    always @* begin
        tmp_wb_dat_o = {WB_DAT_WIDTH{1'b0}};
        case ( s_wb_adr_i )
        ADR_PARAM_MATRIX00:    tmp_wb_dat_o = signed_param_matrix00;
        ADR_PARAM_MATRIX01:    tmp_wb_dat_o = signed_param_matrix01;
        ADR_PARAM_MATRIX02:    tmp_wb_dat_o = signed_param_matrix02;
        ADR_PARAM_MATRIX03:    tmp_wb_dat_o = signed_param_matrix03;
        ADR_PARAM_MATRIX10:    tmp_wb_dat_o = signed_param_matrix10;
        ADR_PARAM_MATRIX11:    tmp_wb_dat_o = signed_param_matrix11;
        ADR_PARAM_MATRIX12:    tmp_wb_dat_o = signed_param_matrix12;
        ADR_PARAM_MATRIX13:    tmp_wb_dat_o = signed_param_matrix13;
        ADR_PARAM_MATRIX20:    tmp_wb_dat_o = signed_param_matrix20;
        ADR_PARAM_MATRIX21:    tmp_wb_dat_o = signed_param_matrix21;
        ADR_PARAM_MATRIX22:    tmp_wb_dat_o = signed_param_matrix22;
        ADR_PARAM_MATRIX23:    tmp_wb_dat_o = signed_param_matrix23;
        ADR_PARAM_CLIP_MIN0:   tmp_wb_dat_o = reg_param_clip_min0;
        ADR_PARAM_CLIP_MAX0:   tmp_wb_dat_o = reg_param_clip_max0;
        ADR_PARAM_CLIP_MIN1:   tmp_wb_dat_o = reg_param_clip_min1;
        ADR_PARAM_CLIP_MAX1:   tmp_wb_dat_o = reg_param_clip_max1;
        ADR_PARAM_CLIP_MIN2:   tmp_wb_dat_o = reg_param_clip_min2;
        ADR_PARAM_CLIP_MAX2:   tmp_wb_dat_o = reg_param_clip_max2;
        endcase
    end
    
    assign s_wb_dat_o = tmp_wb_dat_o;
    assign s_wb_ack_o = s_wb_stb_i;
    
    
    
    
    // core
    (* ASYNC_REG="true" *)  reg     signed  [COEFF_WIDTH-1:0]   ff0_param_matrix00,  ff1_param_matrix00;
    (* ASYNC_REG="true" *)  reg     signed  [COEFF_WIDTH-1:0]   ff0_param_matrix01,  ff1_param_matrix01;
    (* ASYNC_REG="true" *)  reg     signed  [COEFF_WIDTH-1:0]   ff0_param_matrix02,  ff1_param_matrix02;
    (* ASYNC_REG="true" *)  reg     signed  [COEFF3_WIDTH-1:0]  ff0_param_matrix03,  ff1_param_matrix03;
    (* ASYNC_REG="true" *)  reg     signed  [COEFF_WIDTH-1:0]   ff0_param_matrix10,  ff1_param_matrix10;
    (* ASYNC_REG="true" *)  reg     signed  [COEFF_WIDTH-1:0]   ff0_param_matrix11,  ff1_param_matrix11;
    (* ASYNC_REG="true" *)  reg     signed  [COEFF_WIDTH-1:0]   ff0_param_matrix12,  ff1_param_matrix12;
    (* ASYNC_REG="true" *)  reg     signed  [COEFF3_WIDTH-1:0]  ff0_param_matrix13,  ff1_param_matrix13;
    (* ASYNC_REG="true" *)  reg     signed  [COEFF_WIDTH-1:0]   ff0_param_matrix20,  ff1_param_matrix20;
    (* ASYNC_REG="true" *)  reg     signed  [COEFF_WIDTH-1:0]   ff0_param_matrix21,  ff1_param_matrix21;
    (* ASYNC_REG="true" *)  reg     signed  [COEFF_WIDTH-1:0]   ff0_param_matrix22,  ff1_param_matrix22;
    (* ASYNC_REG="true" *)  reg     signed  [COEFF3_WIDTH-1:0]  ff0_param_matrix23,  ff1_param_matrix23;
    (* ASYNC_REG="true" *)  reg             [DATA_WIDTH-1:0]    ff0_param_clip_min0, ff1_param_clip_min0;
    (* ASYNC_REG="true" *)  reg             [DATA_WIDTH-1:0]    ff0_param_clip_max0, ff1_param_clip_max0;
    (* ASYNC_REG="true" *)  reg             [DATA_WIDTH-1:0]    ff0_param_clip_min1, ff1_param_clip_min1;
    (* ASYNC_REG="true" *)  reg             [DATA_WIDTH-1:0]    ff0_param_clip_max1, ff1_param_clip_max1;
    (* ASYNC_REG="true" *)  reg             [DATA_WIDTH-1:0]    ff0_param_clip_min2, ff1_param_clip_min2;
    (* ASYNC_REG="true" *)  reg             [DATA_WIDTH-1:0]    ff0_param_clip_max2, ff1_param_clip_max2;
    always @(posedge clk) begin
        ff0_param_matrix00  <= reg_param_matrix00;
        ff0_param_matrix01  <= reg_param_matrix01;
        ff0_param_matrix02  <= reg_param_matrix02;
        ff0_param_matrix03  <= reg_param_matrix03;
        ff0_param_matrix10  <= reg_param_matrix10;
        ff0_param_matrix11  <= reg_param_matrix11;
        ff0_param_matrix12  <= reg_param_matrix12;
        ff0_param_matrix13  <= reg_param_matrix13;
        ff0_param_matrix20  <= reg_param_matrix20;
        ff0_param_matrix21  <= reg_param_matrix21;
        ff0_param_matrix22  <= reg_param_matrix22;
        ff0_param_matrix23  <= reg_param_matrix23;
        ff0_param_clip_min0 <= reg_param_clip_min0;
        ff0_param_clip_max0 <= reg_param_clip_max0;
        ff0_param_clip_min1 <= reg_param_clip_min1;
        ff0_param_clip_max1 <= reg_param_clip_max1;
        ff0_param_clip_min2 <= reg_param_clip_min2;
        ff0_param_clip_max2 <= reg_param_clip_max2;
        
        ff1_param_matrix00  <= ff0_param_matrix00;
        ff1_param_matrix01  <= ff0_param_matrix01;
        ff1_param_matrix02  <= ff0_param_matrix02;
        ff1_param_matrix03  <= ff0_param_matrix03;
        ff1_param_matrix10  <= ff0_param_matrix10;
        ff1_param_matrix11  <= ff0_param_matrix11;
        ff1_param_matrix12  <= ff0_param_matrix12;
        ff1_param_matrix13  <= ff0_param_matrix13;
        ff1_param_matrix20  <= ff0_param_matrix20;
        ff1_param_matrix21  <= ff0_param_matrix21;
        ff1_param_matrix22  <= ff0_param_matrix22;
        ff1_param_matrix23  <= ff0_param_matrix23;
        ff1_param_clip_min0 <= ff0_param_clip_min0;
        ff1_param_clip_max0 <= ff0_param_clip_max0;
        ff1_param_clip_min1 <= ff0_param_clip_min1;
        ff1_param_clip_max1 <= ff0_param_clip_max1;
        ff1_param_clip_min2 <= ff0_param_clip_min2;
        ff1_param_clip_max2 <= ff0_param_clip_max2;
    end
    
    
    jelly_img_color_matrix_core
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
                
                .param_matrix00         (ff1_param_matrix00),
                .param_matrix01         (ff1_param_matrix01),
                .param_matrix02         (ff1_param_matrix02),
                .param_matrix03         (ff1_param_matrix03),
                .param_matrix10         (ff1_param_matrix10),
                .param_matrix11         (ff1_param_matrix11),
                .param_matrix12         (ff1_param_matrix12),
                .param_matrix13         (ff1_param_matrix13),
                .param_matrix20         (ff1_param_matrix20),
                .param_matrix21         (ff1_param_matrix21),
                .param_matrix22         (ff1_param_matrix22),
                .param_matrix23         (ff1_param_matrix23),
                
                .param_clip_min0        (ff1_param_clip_min0),
                .param_clip_max0        (ff1_param_clip_max0),
                .param_clip_min1        (ff1_param_clip_min1),
                .param_clip_max1        (ff1_param_clip_max1),
                .param_clip_min2        (ff1_param_clip_min2),
                .param_clip_max2        (ff1_param_clip_max2),
                
                .s_img_line_first       (s_img_line_first),
                .s_img_line_last        (s_img_line_last),
                .s_img_pixel_first      (s_img_pixel_first),
                .s_img_pixel_last       (s_img_pixel_last),
                .s_img_de               (s_img_de),
                .s_img_user             (s_img_user),
                .s_img_color0           (s_img_color0),
                .s_img_color1           (s_img_color1),
                .s_img_color2           (s_img_color2),
                .s_img_valid            (s_img_valid),
                
                .m_img_line_first       (m_img_line_first),
                .m_img_line_last        (m_img_line_last),
                .m_img_pixel_first      (m_img_pixel_first),
                .m_img_pixel_last       (m_img_pixel_last),
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
