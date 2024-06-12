// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// バッファ割り当て
module jelly2_buffer_allocator
        #(
            parameter   int     NUM          = 1,
            parameter   int     ADDR_WIDTH   = 32,
            parameter   int     INDEX_WIDTH  = 4,
            
            parameter   int     WB_ADR_WIDTH = 8,
            parameter   int     WB_DAT_WIDTH = 32,
            parameter   int     WB_SEL_WIDTH = (WB_DAT_WIDTH / 8),
            
            parameter           CORE_ID      = 32'h527a_0008,
            parameter           CORE_VERSION = 32'h0000_0000
        )
        (
            input   wire                                    s_wb_rst_i,
            input   wire                                    s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]              s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]              s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]              s_wb_dat_o,
            input   wire                                    s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]              s_wb_sel_i,
            input   wire                                    s_wb_stb_i,
            output  reg                                     s_wb_ack_o,
            
            output  reg     [NUM-1:0]                       buffer_request,
            output  reg     [NUM-1:0]                       buffer_release,
            input   wire    [NUM-1:0][ADDR_WIDTH-1:0]       buffer_addr,
            input   wire    [NUM-1:0][INDEX_WIDTH-1:0]      buffer_index
        );
    
    
    // ---------------------------------
    //  Register
    // ---------------------------------
    
    // register address offset
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CORE_ID          = WB_ADR_WIDTH'('h00);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CORE_VERSION     = WB_ADR_WIDTH'('h01);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CORE_CONFIG      = WB_ADR_WIDTH'('h03);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_BUFFER0_REQUEST  = WB_ADR_WIDTH'('h20);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_BUFFER0_RELEASE  = WB_ADR_WIDTH'('h21);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_BUFFER0_ADDR     = WB_ADR_WIDTH'('h22);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_BUFFER0_INDEX    = WB_ADR_WIDTH'('h23);
    
    logic       [NUM-1:0]       reg_request;
    logic       [NUM-1:0]       reg_release;
    
    always_ff @(posedge s_wb_clk_i) begin
        if ( s_wb_rst_i ) begin
            reg_request <= {NUM{1'b0}};
            reg_release <= {NUM{1'b0}};
        end
        else begin
            reg_request <= {NUM{1'b0}};
            reg_release <= {NUM{1'b0}};
            if ( s_wb_stb_i && s_wb_we_i && s_wb_sel_i[0] ) begin
                for ( int j = 0; j < NUM; ++j ) begin
                    if ( s_wb_adr_i == ADR_BUFFER0_REQUEST + WB_ADR_WIDTH'(4*j) )  reg_request[j] <= 1'b1;
                    if ( s_wb_adr_i == ADR_BUFFER0_RELEASE + WB_ADR_WIDTH'(4*j) )  reg_release[j] <= 1'b1;
                end
            end
        end
    end
    
    always_comb begin
        s_wb_dat_o = {WB_DAT_WIDTH{1'b0}};
        
        case ( s_wb_adr_i )
        ADR_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID);
        ADR_CORE_VERSION:   s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION);
        ADR_CORE_CONFIG:    s_wb_dat_o = WB_DAT_WIDTH'(NUM);
        default: ;
        endcase
        
        for ( int j = 0; j < NUM; ++j ) begin
            if ( s_wb_adr_i == ADR_BUFFER0_ADDR  + WB_ADR_WIDTH'(4*j) )    s_wb_dat_o = WB_DAT_WIDTH'(buffer_addr [j]);
            if ( s_wb_adr_i == ADR_BUFFER0_INDEX + WB_ADR_WIDTH'(4*j) )    s_wb_dat_o = WB_DAT_WIDTH'(buffer_index[j]);
        end
    end
    
    always_comb s_wb_ack_o = s_wb_stb_i;
    
    
    always_comb buffer_request = reg_request;
    always_comb buffer_release = reg_release;
    
    
endmodule


`default_nettype wire


// end of file
