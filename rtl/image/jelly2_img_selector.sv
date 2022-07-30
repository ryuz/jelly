// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_img_selector
        #(
            parameter   int                         NUM             = 2,
            parameter   int                         SEL_WIDTH       = $clog2(NUM),
            parameter   int                         USER_WIDTH      = 0,
            parameter   int                         DATA_WIDTH      = 32,

            parameter   int                         WB_ADR_WIDTH    = 8,
            parameter   int                         WB_DAT_WIDTH    = 32,
            parameter   int                         WB_SEL_WIDTH    = (WB_DAT_WIDTH / 8),

            parameter   int                         CORE_ID         = 32'h527a_2f10,
            parameter   int                         CORE_VERSION    = 32'h0001_0000,

            parameter   bit     [SEL_WIDTH-1:0]     INIT_CTL_SELECT = 0,
            
            localparam  int                         USER_BITS       = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,
            
            input   wire    [NUM-1:0]                   s_img_row_first,
            input   wire    [NUM-1:0]                   s_img_row_last,
            input   wire    [NUM-1:0]                   s_img_col_first,
            input   wire    [NUM-1:0]                   s_img_col_last,
            input   wire    [NUM-1:0]                   s_img_de,
            input   wire    [NUM-1:0][USER_BITS-1:0]    s_img_user,
            input   wire    [NUM-1:0][DATA_WIDTH-1:0]   s_img_data,
            input   wire    [NUM-1:0]                   s_img_valid,
            
            output  wire                                m_img_row_first,
            output  wire                                m_img_row_last,
            output  wire                                m_img_col_first,
            output  wire                                m_img_col_last,
            output  wire                                m_img_de,
            output  wire    [USER_BITS-1:0]             m_img_user,
            output  wire    [DATA_WIDTH-1:0]            m_img_data,
            output  wire                                m_img_valid,

            input   wire                                s_wb_rst_i,
            input   wire                                s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]          s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]          s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]          s_wb_dat_o,
            input   wire                                s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]          s_wb_sel_i,
            input   wire                                s_wb_stb_i,
            output  reg                                 s_wb_ack_o
        );
    
    
    // ---------------------------------
    //  Register
    // ---------------------------------
    
    // register address offset
    localparam  ADR_CORE_ID      = WB_ADR_WIDTH'('h00);
    localparam  ADR_CORE_VERSION = WB_ADR_WIDTH'('h01);
    localparam  ADR_CTL_SELECT   = WB_ADR_WIDTH'('h08);
    localparam  ADR_CONFIG_NUM   = WB_ADR_WIDTH'('h10);
    
    // registers
    reg     [SEL_WIDTH-1:0]     reg_ctl_select;
    
    function [WB_DAT_WIDTH-1:0] write_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] wdat,
                                        input [WB_SEL_WIDTH-1:0] msk
                                    );
    integer i;
    begin
        for ( i = 0; i < WB_DAT_WIDTH; i = i+1 ) begin
            write_mask[i] = msk[i/8] ? wdat[i] : org[i];
        end
    end
    endfunction
    
    always_ff @(posedge s_wb_clk_i) begin
        if ( s_wb_rst_i ) begin
            reg_ctl_select <= INIT_CTL_SELECT;
        end
        else begin
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_CTL_SELECT:    reg_ctl_select <= SEL_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_ctl_select), s_wb_dat_i, s_wb_sel_i));
                default: ;
                endcase
            end
        end
    end
    
    always_comb begin
        s_wb_dat_o = '0;
        case ( s_wb_adr_i )
        ADR_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID);
        ADR_CORE_VERSION:   s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION);
        ADR_CTL_SELECT:     s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_select);
        ADR_CONFIG_NUM:     s_wb_dat_o = WB_DAT_WIDTH'(NUM);
        default: ;
        endcase
    end

    always_comb s_wb_ack_o = s_wb_stb_i;
    
    
    
    // ---------------------------------
    //  Core
    // ---------------------------------
    
    jelly2_img_selector_core
            #(
                .NUM                (NUM),
                .SEL_WIDTH          (SEL_WIDTH),
                .USER_WIDTH         (USER_WIDTH),
                .DATA_WIDTH         (DATA_WIDTH)
            )
        i_img_selector_core
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .sel                (reg_ctl_select),
                
                .s_img_row_first    (s_img_row_first),
                .s_img_row_last     (s_img_row_last),
                .s_img_col_first    (s_img_col_first),
                .s_img_col_last     (s_img_col_last),
                .s_img_de           (s_img_de),
                .s_img_user         (s_img_user),
                .s_img_data         (s_img_data),
                .s_img_valid        (s_img_valid),
                
                .m_img_row_first    (m_img_row_first),
                .m_img_row_last     (m_img_row_last),
                .m_img_col_first    (m_img_col_first),
                .m_img_col_last     (m_img_col_last),
                .m_img_de           (m_img_de),
                .m_img_user         (m_img_user),
                .m_img_data         (m_img_data),
                .m_img_valid        (m_img_valid)
            );
    
endmodule


`default_nettype wire


// end of file
