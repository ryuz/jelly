// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_img_binarizer
        #(
            parameter   USER_WIDTH     = 0,
            parameter   DATA_WIDTH     = 8,
            
            parameter   WB_ADR_WIDTH   = 8,
            parameter   WB_DAT_WIDTH   = 32,
            parameter   WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8),
            parameter   INIT_PARAM_TH  = 127,
            parameter   INIT_PARAM_INV = 0,
            
            parameter   USER_BITS      = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,
            
            input   wire                            s_img_line_first,
            input   wire                            s_img_line_last,
            input   wire                            s_img_pixel_first,
            input   wire                            s_img_pixel_last,
            input   wire                            s_img_de,
            input   wire    [USER_BITS-1:0]         s_img_user,
            input   wire    [DATA_WIDTH-1:0]        s_img_data,
            input   wire                            s_img_valid,
            
            output  wire                            m_img_line_first,
            output  wire                            m_img_line_last,
            output  wire                            m_img_pixel_first,
            output  wire                            m_img_pixel_last,
            output  wire                            m_img_de,
            output  wire    [USER_BITS-1:0]         m_img_user,
            output  wire    [DATA_WIDTH-1:0]        m_img_data,
            output  wire                            m_img_binary,
            output  wire                            m_img_valid,
            
            input   wire                            s_wb_rst_i,
            input   wire                            s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]      s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_o,
            input   wire                            s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]      s_wb_sel_i,
            input   wire                            s_wb_stb_i,
            output  wire                            s_wb_ack_o
        );
    
    reg     [DATA_WIDTH-1:0]        reg_param_th;
    reg     [0:0]                   reg_param_inv;
    always @(posedge s_wb_clk_i) begin
        if ( s_wb_rst_i ) begin
            reg_param_th  <= INIT_PARAM_TH;
            reg_param_inv <= INIT_PARAM_INV;
        end
        else begin
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                0:  reg_param_th  <= s_wb_dat_i;
                1:  reg_param_inv <= s_wb_dat_i;
                endcase
            end
        end
    end
    
    assign s_wb_dat_o = (s_wb_adr_i == 0) ? reg_param_th  :
                        (s_wb_adr_i == 1) ? reg_param_inv :
                        0;
    assign s_wb_ack_o = s_wb_stb_i;
    
    
    (* ASYNC_REG="true" *)  reg         [DATA_WIDTH-1:0]    ff0_param_th,  ff1_param_th;
    (* ASYNC_REG="true" *)  reg         [0:0]               ff0_param_inv, ff1_param_inv;
    always @(posedge clk) begin
        ff0_param_th  <= reg_param_th;
        ff1_param_th  <= ff0_param_th;
        
        ff0_param_inv <= reg_param_inv;
        ff1_param_inv <= ff0_param_inv;
    end
    
    
    jelly_img_binarizer_core
            #(
                .USER_WIDTH         (USER_WIDTH),
                .DATA_WIDTH         (DATA_WIDTH)
            )
        i_img_binarizer_core
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .param_th           (ff1_param_th),
                .param_inv          (ff1_param_inv),
                
                .s_img_line_first   (s_img_line_first),
                .s_img_line_last    (s_img_line_last),
                .s_img_pixel_first  (s_img_pixel_first),
                .s_img_pixel_last   (s_img_pixel_last),
                .s_img_de           (s_img_de),
                .s_img_user         (s_img_user),
                .s_img_data         (s_img_data),
                .s_img_valid        (s_img_valid),
                
                .m_img_line_first   (m_img_line_first),
                .m_img_line_last    (m_img_line_last),
                .m_img_pixel_first  (m_img_pixel_first),
                .m_img_pixel_last   (m_img_pixel_last),
                .m_img_de           (m_img_de),
                .m_img_user         (m_img_user),
                .m_img_data         (m_img_data),
                .m_img_binary       (m_img_binary),
                .m_img_valid        (m_img_valid)
            );
    
    
endmodule


`default_nettype wire


// end of file
