// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_img_demosaic_acpi
        #(
            parameter   USER_WIDTH        = 0,
            parameter   DATA_WIDTH        = 10,
            parameter   MAX_X_NUM         = 4096,
            parameter   USE_VALID         = 0,
            parameter   RAM_TYPE          = "block",
            
            parameter   WB_ADR_WIDTH      = 8,
            parameter   WB_DAT_WIDTH      = 32,
            parameter   WB_SEL_WIDTH      = (WB_DAT_WIDTH / 8),
            parameter   INIT_PARAM_PHASE  = 2'b11,
            parameter   INIT_PARAM_BYPASS = 1'b0,
            
            parameter   USER_BITS         = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,
            
            input   wire                            s_wb_rst_i,
            input   wire                            s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]      s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_o,
            input   wire                            s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]      s_wb_sel_i,
            input   wire                            s_wb_stb_i,
            output  wire                            s_wb_ack_o,
            
            input   wire                            s_img_line_first,
            input   wire                            s_img_line_last,
            input   wire                            s_img_pixel_first,
            input   wire                            s_img_pixel_last,
            input   wire                            s_img_de,
            input   wire    [USER_BITS-1:0]         s_img_user,
            input   wire    [DATA_WIDTH-1:0]        s_img_raw,
            input   wire                            s_img_valid,
            
            output  wire                            m_img_line_first,
            output  wire                            m_img_line_last,
            output  wire                            m_img_pixel_first,
            output  wire                            m_img_pixel_last,
            output  wire                            m_img_de,
            output  wire    [USER_BITS-1:0]         m_img_user,
            output  wire    [DATA_WIDTH-1:0]        m_img_raw,
            output  wire    [DATA_WIDTH-1:0]        m_img_r,
            output  wire    [DATA_WIDTH-1:0]        m_img_g,
            output  wire    [DATA_WIDTH-1:0]        m_img_b,
            output  wire                            m_img_valid
        );
    
    // register
    localparam  ADR_PARAM_PHASE  = 8'h00;
    localparam  ADR_PARAM_BYPASS = 8'h01;
    
    reg     [1:0]       reg_param_phase;
    reg     [0:0]       reg_param_bypass;
    
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
            reg_param_phase  <= INIT_PARAM_PHASE;
            reg_param_bypass <= INIT_PARAM_BYPASS;
        end
        else begin
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_PARAM_PHASE:    reg_param_phase  <= reg_mask(reg_param_phase,  s_wb_dat_i, s_wb_sel_i);
                ADR_PARAM_BYPASS:   reg_param_bypass <= reg_mask(reg_param_bypass, s_wb_dat_i, s_wb_sel_i);
                endcase
            end
        end
    end
    
    assign s_wb_dat_o = (s_wb_adr_i == ADR_PARAM_PHASE)  ? reg_param_phase  :
                        (s_wb_adr_i == ADR_PARAM_BYPASS) ? reg_param_bypass :
                        0;
    assign s_wb_ack_o = s_wb_stb_i;
    
    
    (* ASYNC_REG="true" *)  reg         [1:0]   ff0_param_phase,  ff1_param_phase;
    (* ASYNC_REG="true" *)  reg         [0:0]   ff0_param_bypass, ff1_param_bypass;
    always @(posedge clk) begin
        ff0_param_phase  <= reg_param_phase;
        ff1_param_phase  <= ff0_param_phase;
        
        ff0_param_bypass <= reg_param_bypass;
        ff1_param_bypass <= ff0_param_bypass;
    end
    
    
    jelly_img_demosaic_acpi_core
            #(
                .USER_WIDTH         (USER_WIDTH),
                .DATA_WIDTH         (DATA_WIDTH),
                .MAX_X_NUM          (MAX_X_NUM),
                .USE_VALID          (USE_VALID),
                .RAM_TYPE           (RAM_TYPE)
            )
        i_img_demosaic_acpi_core
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .param_phase        (ff1_param_phase),
                .param_bypass       (ff1_param_bypass),
                
                .s_img_line_first   (s_img_line_first),
                .s_img_line_last    (s_img_line_last),
                .s_img_pixel_first  (s_img_pixel_first),
                .s_img_pixel_last   (s_img_pixel_last),
                .s_img_de           (s_img_de),
                .s_img_user         (s_img_user),
                .s_img_raw          (s_img_raw),
                .s_img_valid        (s_img_valid),
                
                .m_img_line_first   (m_img_line_first),
                .m_img_line_last    (m_img_line_last),
                .m_img_pixel_first  (m_img_pixel_first),
                .m_img_pixel_last   (m_img_pixel_last),
                .m_img_de           (m_img_de),
                .m_img_user         (m_img_user),
                .m_img_raw          (m_img_raw),
                .m_img_r            (m_img_r),
                .m_img_g            (m_img_g),
                .m_img_b            (m_img_b),
                .m_img_valid        (m_img_valid)
            );
    
    
endmodule


`default_nettype wire


// end of file
