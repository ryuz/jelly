// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_binarizer
        #(
            parameter   int                                             USER_WIDTH        = 0,
            parameter   int                                             S_COMPONENTS      = 1,
            parameter   int                                             S_DATA_WIDTH      = 8,
            parameter   int                                             M_COMPONENTS      = 1,
            parameter   int                                             M_DATA_WIDTH      = 1,
            parameter   bit                                             WRAP_AROUND       = 1,
            parameter   bit                                             USE_VALID         = 1'b1,

            parameter   bit     [31:0]                                  CORE_ID           = 32'h527a_2133,
            parameter   bit     [31:0]                                  CORE_VERSION      = 32'h0001_0000,
            parameter   int                                             INDEX_WIDTH       = 1,
            
            parameter   int                                             WB_ADR_WIDTH      = 8,
            parameter   int                                             WB_DAT_WIDTH      = 32,
            parameter   int                                             WB_SEL_WIDTH      = (WB_DAT_WIDTH / 8),
            
            parameter   bit     [WB_ADR_WIDTH-1:0]                      OFFSET_PARAM_S    = WB_ADR_WIDTH'('h20),
            parameter   bit     [WB_ADR_WIDTH-1:0]                      STEP_PARAM_S      = WB_ADR_WIDTH'(4),
            parameter   bit     [WB_ADR_WIDTH-1:0]                      OFFSET_PARAM_M    = WB_ADR_WIDTH'('h40),
            parameter   bit     [WB_ADR_WIDTH-1:0]                      STEP_PARAM_M      = WB_ADR_WIDTH'(4),

            parameter   bit     [1:0]                                   INIT_CTL_CONTROL  = 2'b00,
            parameter   bit                                             INIT_PARAM_OR     = 1'b0,
            parameter   bit     [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    INIT_PARAM_TH0    = '0,
            parameter   bit     [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    INIT_PARAM_TH1    = '1,
            parameter   bit     [S_COMPONENTS-1:0]                      INIT_PARAM_INV    = '0,
            parameter   bit     [M_COMPONENTS-1:0][M_DATA_WIDTH-1:0]    INIT_PARAM_VAL0   = '0,
            parameter   bit     [M_COMPONENTS-1:0][M_DATA_WIDTH-1:0]    INIT_PARAM_VAL1   = '1,

            parameter   int                                             USER_BITS         = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                                            reset,
            input   wire                                            clk,
            input   wire                                            cke,
            
            input   wire                                            in_update_req,
            
            input   wire                                            s_wb_rst_i,
            input   wire                                            s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]                      s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]                      s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]                      s_wb_dat_o,
            input   wire                                            s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]                      s_wb_sel_i,
            input   wire                                            s_wb_stb_i,
            output  reg                                             s_wb_ack_o,
            
            input   wire                                            s_img_row_first,
            input   wire                                            s_img_row_last,
            input   wire                                            s_img_col_first,
            input   wire                                            s_img_col_last,
            input   wire                                            s_img_de,
            input   wire    [USER_BITS-1:0]                         s_img_user,
            input   wire    [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    s_img_data,
            input   wire                                            s_img_valid,
            
            output  wire                                            m_img_row_first,
            output  wire                                            m_img_row_last,
            output  wire                                            m_img_col_first,
            output  wire                                            m_img_col_last,
            output  wire                                            m_img_de,
            output  wire    [USER_BITS-1:0]                         m_img_user,
            output  wire    [M_COMPONENTS-1:0][M_DATA_WIDTH-1:0]    m_img_data,
            output  wire                                            m_img_valid
        );
    
    
    
    // -------------------------------------
    //  registers domain
    // -------------------------------------
    
    // register address offset
    localparam  bit     [WB_ADR_WIDTH-1:0]     ADR_CORE_ID        = WB_ADR_WIDTH'('h00);
    localparam  bit     [WB_ADR_WIDTH-1:0]     ADR_CORE_VERSION   = WB_ADR_WIDTH'('h01);
    localparam  bit     [WB_ADR_WIDTH-1:0]     ADR_CTL_CONTROL    = WB_ADR_WIDTH'('h04);
    localparam  bit     [WB_ADR_WIDTH-1:0]     ADR_CTL_STATUS     = WB_ADR_WIDTH'('h05);
    localparam  bit     [WB_ADR_WIDTH-1:0]     ADR_CTL_INDEX      = WB_ADR_WIDTH'('h07);
    localparam  bit     [WB_ADR_WIDTH-1:0]     ADR_PARAM_OR       = WB_ADR_WIDTH'('h10);
    localparam  bit     [WB_ADR_WIDTH-1:0]     ADR_PARAM_TH0      = WB_ADR_WIDTH'('h0);
    localparam  bit     [WB_ADR_WIDTH-1:0]     ADR_PARAM_TH1      = WB_ADR_WIDTH'('h1);
    localparam  bit     [WB_ADR_WIDTH-1:0]     ADR_PARAM_INV      = WB_ADR_WIDTH'('h2);
    localparam  bit     [WB_ADR_WIDTH-1:0]     ADR_PARAM_VAL0     = WB_ADR_WIDTH'('h0);
    localparam  bit     [WB_ADR_WIDTH-1:0]     ADR_PARAM_VAL1     = WB_ADR_WIDTH'('h1);
    
    // registers
    logic   [1:0]                                   reg_ctl_control;    // bit[0]:enable, bit[1]:update
    logic                                           reg_param_or;
    logic   [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    reg_param_th0;
    logic   [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    reg_param_th1;
    logic   [S_COMPONENTS-1:0]                      reg_param_inv;
    logic   [M_COMPONENTS-1:0][M_DATA_WIDTH-1:0]    reg_param_val0;
    logic   [M_COMPONENTS-1:0][M_DATA_WIDTH-1:0]    reg_param_val1;
    
    // shadow registers(core domain)
    logic                                           core_param_or;
    logic   [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    core_param_th0;
    logic   [S_COMPONENTS-1:0][S_DATA_WIDTH-1:0]    core_param_th1;
    logic   [S_COMPONENTS-1:0]                      core_param_inv;
    logic   [M_COMPONENTS-1:0][M_DATA_WIDTH-1:0]    core_param_val0;
    logic   [M_COMPONENTS-1:0][M_DATA_WIDTH-1:0]    core_param_val1;
    
    // handshake with core domain
    logic    [INDEX_WIDTH-1:0]                      update_index;
    logic                                           update_ack;
    logic    [INDEX_WIDTH-1:0]                      ctl_index;
    
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
    integer i;
    begin
        for ( i = 0; i < WB_DAT_WIDTH; i = i+1 ) begin
            write_mask[i] = msk[i/8] ? wdat[i] : org[i];
        end
    end
    endfunction
    
    // registers control
    always_ff @(posedge s_wb_clk_i) begin
        if ( s_wb_rst_i ) begin
            reg_ctl_control <= INIT_CTL_CONTROL;
            reg_param_or    <= INIT_PARAM_OR;
            reg_param_th0   <= INIT_PARAM_TH0;
            reg_param_th1   <= INIT_PARAM_TH1;
            reg_param_inv   <= INIT_PARAM_INV;
            reg_param_val0  <= INIT_PARAM_VAL0;
            reg_param_val1  <= INIT_PARAM_VAL1;
        end
        else begin
            // auto clear
            if ( update_ack ) begin
                reg_ctl_control[1] <= 1'b0;
            end
            
            // write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_CTL_CONTROL:    reg_ctl_control <= 2'(write_mask(WB_DAT_WIDTH'(reg_ctl_control), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_OR:       reg_param_or    <= 1'(write_mask(WB_DAT_WIDTH'(reg_param_or   ), s_wb_dat_i, s_wb_sel_i));
                default: ;
                endcase

                for ( int i = 0; i < S_COMPONENTS; ++i ) begin
                    case ( s_wb_adr_i - OFFSET_PARAM_S - i*STEP_PARAM_S )
                    ADR_PARAM_TH0:  reg_param_th0[i] <= S_DATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_th0[i]), s_wb_dat_i, s_wb_sel_i));
                    ADR_PARAM_TH1:  reg_param_th1[i] <= S_DATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_th1[i]), s_wb_dat_i, s_wb_sel_i));
                    ADR_PARAM_INV:  reg_param_inv[i] <=            1'(write_mask(WB_DAT_WIDTH'(reg_param_inv[i]), s_wb_dat_i, s_wb_sel_i));
                    default: ;
                    endcase
                end

                for ( int i = 0; i < M_COMPONENTS; ++i ) begin
                    case ( s_wb_adr_i - OFFSET_PARAM_M - i*STEP_PARAM_M )
                    ADR_PARAM_VAL0:  reg_param_th0[i] <= S_DATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_th0[i]), s_wb_dat_i, s_wb_sel_i));
                    ADR_PARAM_VAL1:  reg_param_th1[i] <= S_DATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_th1[i]), s_wb_dat_i, s_wb_sel_i));
                    default: ;
                    endcase
                end
            end
        end
    end
    
    // read
    always_comb begin
        s_wb_dat_o = '0;
        case ( s_wb_adr_i )
        ADR_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID);
        ADR_CORE_VERSION:   s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION);
        ADR_CTL_CONTROL:    s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_control);
        ADR_CTL_STATUS:     s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_control[0]);
        ADR_CTL_INDEX:      s_wb_dat_o = WB_DAT_WIDTH'(ctl_index);
        ADR_PARAM_OR:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_or);
        default: ;
        endcase
        
        for ( int i = 0; i < S_COMPONENTS; ++i ) begin
            case ( s_wb_adr_i - OFFSET_PARAM_S - i*STEP_PARAM_S )
            ADR_PARAM_TH0:  s_wb_dat_o = WB_DAT_WIDTH'(reg_param_th0[i]);
            ADR_PARAM_TH1:  s_wb_dat_o = WB_DAT_WIDTH'(reg_param_th1[i]);
            ADR_PARAM_INV:  s_wb_dat_o = WB_DAT_WIDTH'(reg_param_inv[i]);
            default: ;
            endcase
        end

        for ( int i = 0; i < M_COMPONENTS; ++i ) begin
            case ( s_wb_adr_i - OFFSET_PARAM_M - i*STEP_PARAM_M )
            ADR_PARAM_VAL0: s_wb_dat_o = WB_DAT_WIDTH'(reg_param_th0[i]);
            ADR_PARAM_VAL1: s_wb_dat_o = WB_DAT_WIDTH'(reg_param_th1[i]);
            default: ;
            endcase
        end
    end

    // ack
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
    reg                 core_update_req;
    always @(posedge clk) begin
        if ( reset ) begin
            core_update_req  <= 1'b0;
            core_param_or    <= INIT_PARAM_OR;
            core_param_th0   <= INIT_PARAM_TH0;
            core_param_th1   <= INIT_PARAM_TH1;
            core_param_inv   <= INIT_PARAM_INV;
            core_param_val0  <= INIT_PARAM_VAL0;
            core_param_val1  <= INIT_PARAM_VAL1;
        end
        else begin
            if ( in_update_req ) begin
                core_update_req <= 1'b1;
            end
            
            if ( cke ) begin
                if ( core_update_req & update_trig & update_en ) begin
                    core_update_req <= 1'b0;
                    core_param_or   <= reg_param_or;
                    core_param_th0  <= reg_param_th0;
                    core_param_th1  <= reg_param_th1;
                    core_param_inv  <= reg_param_inv;
                    core_param_val0 <= reg_param_val0;
                    core_param_val1 <= reg_param_val1;
                end
            end
        end
    end
    
    
    // core
    jelly2_img_binarizer_core
            #(
                .USER_WIDTH         (USER_WIDTH),
                .S_COMPONENTS       (S_COMPONENTS),
                .S_DATA_WIDTH       (S_DATA_WIDTH),
                .M_COMPONENTS       (M_COMPONENTS),
                .M_DATA_WIDTH       (M_DATA_WIDTH),
                .WRAP_AROUND        (WRAP_AROUND),
                .USE_VALID          (USE_VALID)
            )
        i_img_binarizer_core
            (
                .reset,
                .clk,
                .cke,
                
                .param_or           (core_param_or),
                .param_th0          (core_param_th0),
                .param_th1          (core_param_th1),
                .param_inv          (core_param_inv),
                .param_val0         (core_param_val0),
                .param_val1         (core_param_val1),
                
                .s_img_row_first,
                .s_img_row_last,
                .s_img_col_first,
                .s_img_col_last,
                .s_img_de,
                .s_img_user,
                .s_img_data,
                .s_img_valid,
                
                .m_img_row_first,
                .m_img_row_last,
                .m_img_col_first,
                .m_img_col_last,
                .m_img_de,
                .m_img_user,
                .m_img_data,
                .m_img_valid
            );
    
    
endmodule


`default_nettype wire


// end of file
