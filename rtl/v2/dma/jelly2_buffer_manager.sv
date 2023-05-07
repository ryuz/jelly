// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// バッファ管理
module jelly2_buffer_manager
        #(
            parameter   int                                         BUFFER_NUM   = 3,
            parameter   int                                         READER_NUM   = 1,
            parameter   int                                         ADDR_WIDTH   = 32,
            parameter   int                                         REFCNT_WIDTH = 4,
            parameter   int                                         INDEX_WIDTH  = $clog2(BUFFER_NUM),

            parameter   int                                         WB_ADR_WIDTH = 8,
            parameter   int                                         WB_DAT_WIDTH = 32,
            parameter   int                                         WB_SEL_WIDTH = (WB_DAT_WIDTH / 8),

            parameter                                               CORE_ID      = 32'h527a_0004,
            parameter                                               CORE_VERSION = 32'h0000_0000,
            
            parameter   bit     [BUFFER_NUM-1:0][ADDR_WIDTH-1:0]    INIT_ADDR = '0
        )
        (
            input   wire                                        s_wb_rst_i,
            input   wire                                        s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]                  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]                  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]                  s_wb_dat_o,
            input   wire                                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]                  s_wb_sel_i,
            input   wire                                        s_wb_stb_i,
            output  wire                                        s_wb_ack_o,
            
            input   wire                                        writer_request,
            input   wire                                        writer_release,
            output  wire    [ADDR_WIDTH-1:0]                    writer_addr,
            output  wire    [INDEX_WIDTH-1:0]                   writer_index,
            
            input   wire    [READER_NUM-1:0]                    reader_request,
            input   wire    [READER_NUM-1:0]                    reader_release,
            output  wire    [READER_NUM-1:0][ADDR_WIDTH-1:0]    reader_addr,
            output  wire    [READER_NUM-1:0][INDEX_WIDTH-1:0]   reader_index,
            
            output  wire    [ADDR_WIDTH-1:0]                    newest_addr,
            output  wire    [INDEX_WIDTH-1:0]                   newest_index,
            
            output  wire    [BUFFER_NUM-1:0][REFCNT_WIDTH-1:0]  status_refcnt
        );
    
    
    
    // ---------------------------------
    //  Register
    // ---------------------------------
    
    // register address offset
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_ID          = WB_ADR_WIDTH'('h00);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_VERSION     = WB_ADR_WIDTH'('h01);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_CONFIG      = WB_ADR_WIDTH'('h03);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_NEWEST_INDEX     = WB_ADR_WIDTH'('h20);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_WRITER_INDEX     = WB_ADR_WIDTH'('h21);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_BUFFER0_ADDR     = WB_ADR_WIDTH'('h40);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_BUFFER0_REFCNT   = WB_ADR_WIDTH'('h80);
    
    // registers
    logic   [BUFFER_NUM-1:0][ADDR_WIDTH-1:0]    reg_addr;
    
    function [WB_DAT_WIDTH-1:0] write_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] dat,
                                        input [WB_SEL_WIDTH-1:0] sel
                                    );
    integer i;
    begin
        for ( i = 0; i < WB_DAT_WIDTH; i = i+1 ) begin
            write_mask[i] = sel[i/8] ? dat[i] : org[i];
        end
    end
    endfunction
    
    
    always_ff @(posedge s_wb_clk_i ) begin
        if ( s_wb_rst_i ) begin
            reg_addr <= INIT_ADDR;
        end
        else begin
            // register write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                for ( int i = 0; i < BUFFER_NUM; ++i ) begin
                    if ( s_wb_adr_i == ADR_BUFFER0_ADDR + WB_ADR_WIDTH'(i) ) begin
                        reg_addr[i] <= ADDR_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_addr[i]), s_wb_dat_i, s_wb_sel_i));
                    end
                end
            end
        end
    end
    
    reg     [WB_DAT_WIDTH-1:0]  wb_dat_o;
    always_comb begin
        wb_dat_o = {WB_DAT_WIDTH{1'b0}};
        
        case ( s_wb_adr_i )
        ADR_CORE_ID:        wb_dat_o = WB_DAT_WIDTH'(CORE_ID);
        ADR_CORE_VERSION:   wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION);
        ADR_CORE_CONFIG:    wb_dat_o = WB_DAT_WIDTH'(BUFFER_NUM);
        ADR_NEWEST_INDEX:   wb_dat_o = WB_DAT_WIDTH'(newest_index);
        ADR_WRITER_INDEX:   wb_dat_o = WB_DAT_WIDTH'(writer_index);
        default: ;
        endcase
        
        for ( int i = 0; i < BUFFER_NUM; ++i ) begin
            if ( s_wb_adr_i == ADR_BUFFER0_ADDR + WB_ADR_WIDTH'(i) ) begin
                wb_dat_o = WB_DAT_WIDTH'(reg_addr[i]);
            end
            if ( s_wb_adr_i == ADR_BUFFER0_REFCNT + WB_ADR_WIDTH'(i) ) begin
                wb_dat_o = WB_DAT_WIDTH'(status_refcnt[i]);
            end
        end
    end
    
    assign s_wb_dat_o = wb_dat_o;
    assign s_wb_ack_o = s_wb_stb_i;
    
    
    // バッファ割り当てコア
    jelly2_buffer_arbiter
            #(
                .BUFFER_NUM     (BUFFER_NUM),
                .READER_NUM     (READER_NUM),
                .ADDR_WIDTH     (ADDR_WIDTH),
                .REFCNT_WIDTH   (REFCNT_WIDTH),
                .INDEX_WIDTH    (INDEX_WIDTH)
            )
        i_buffer_arbiter
            (
                .reset          (s_wb_rst_i),
                .clk            (s_wb_clk_i),
                .cke            (1'b1),
                
                .param_buf_addr (reg_addr),
                
                .writer_request (writer_request),
                .writer_release (writer_release),
                .writer_addr    (writer_addr),
                .writer_index   (writer_index),
                
                .reader_request (reader_request),
                .reader_release (reader_release),
                .reader_addr    (reader_addr),
                .reader_index   (reader_index),
                
                .newest_addr    (newest_addr),
                .newest_index   (newest_index),
                
                .status_refcnt  (status_refcnt)
            );
    
endmodule


`default_nettype wire


// end of file
