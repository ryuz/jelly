// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// demosaic with ACPI
module jelly2_img_demosaic_acpi
        #(
            parameter   int                 USER_WIDTH       = 0,
            parameter   int                 DATA_WIDTH       = 10,
            parameter   int                 MAX_COLS         = 4096,
            parameter   bit                 USE_VALID        = 1,
            parameter                       RAM_TYPE         = "block",
                    
            parameter                       CORE_ID          = 32'h527a_2110,
            parameter                       CORE_VERSION     = 32'h0001_0000,
            parameter   int                 INDEX_WIDTH      = 1,
                    
            parameter   int                 WB_ADR_WIDTH     = 8,
            parameter   int                 WB_DAT_WIDTH     = 32,
            parameter   int                 WB_SEL_WIDTH     = (WB_DAT_WIDTH / 8),
        
            parameter   bit     [1:0]       INIT_CTL_CONTROL = 2'b01,
            parameter   bit     [1:0]       INIT_PARAM_PHASE = 2'b00,
        
            localparam  int                 USER_BITS        = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,
            
            input   wire                            in_update_req,
                        
            input   wire                            s_img_row_first,
            input   wire                            s_img_row_last,
            input   wire                            s_img_col_first,
            input   wire                            s_img_col_last,
            input   wire                            s_img_de,
            input   wire    [USER_BITS-1:0]         s_img_user,
            input   wire    [DATA_WIDTH-1:0]        s_img_raw,
            input   wire                            s_img_valid,
            
            output  wire                            m_img_row_first,
            output  wire                            m_img_row_last,
            output  wire                            m_img_col_first,
            output  wire                            m_img_col_last,
            output  wire                            m_img_de,
            output  wire    [USER_BITS-1:0]         m_img_user,
            output  wire    [DATA_WIDTH-1:0]        m_img_raw,
            output  wire    [DATA_WIDTH-1:0]        m_img_r,
            output  wire    [DATA_WIDTH-1:0]        m_img_g,
            output  wire    [DATA_WIDTH-1:0]        m_img_b,
            output  wire                            m_img_valid,

            input   wire                            s_wb_rst_i,
            input   wire                            s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]      s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]      s_wb_dat_o,
            input   wire                            s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]      s_wb_sel_i,
            input   wire                            s_wb_stb_i,
            output  reg                             s_wb_ack_o
        );
    
    
    
    // -------------------------------------
    //  registers domain
    // -------------------------------------
    
    // register address offset
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_ID       = WB_ADR_WIDTH'('h00);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_VERSION  = WB_ADR_WIDTH'('h01);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_CONTROL   = WB_ADR_WIDTH'('h04);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_STATUS    = WB_ADR_WIDTH'('h05);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_INDEX     = WB_ADR_WIDTH'('h07);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_PHASE   = WB_ADR_WIDTH'('h08);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CURRENT_PHASE = WB_ADR_WIDTH'('h18);
    
    // registers
    reg     [1:0]       reg_ctl_control;    // bit[0]:enable, bit[1]:update
    reg     [1:0]       reg_param_phase;
    
    // shadow registers(core domain)
    reg     [0:0]       core_ctl_control;
    reg     [1:0]       core_param_phase;
    
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
            reg_param_phase <= INIT_PARAM_PHASE;
        end
        else begin
            // auto clear
            if ( update_ack ) begin
                reg_ctl_control[1] <= 1'b0;
            end
            
            // write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_CTL_CONTROL:   reg_ctl_control <= 2'(write_mask(WB_DAT_WIDTH'(reg_ctl_control), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_PHASE:   reg_param_phase <= 2'(write_mask(WB_DAT_WIDTH'(reg_param_phase), s_wb_dat_i, s_wb_sel_i));
                default: ;
                endcase
            end
        end
    end
    
    // read
    always_comb begin
        s_wb_dat_o = '0;
        case (s_wb_adr_i )
        ADR_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID);
        ADR_CORE_VERSION:   s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION);
        ADR_CTL_CONTROL:    s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_control);
        ADR_CTL_STATUS:     s_wb_dat_o = WB_DAT_WIDTH'(core_ctl_control);   // debug use only
        ADR_CTL_INDEX:      s_wb_dat_o = WB_DAT_WIDTH'(ctl_index);
        ADR_PARAM_PHASE:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_phase);
        ADR_CURRENT_PHASE:  s_wb_dat_o = WB_DAT_WIDTH'(core_param_phase);   // debug use only
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
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_update_req   <= 1'b0;
            
            core_ctl_control <= 1'b0;
            core_param_phase <= INIT_PARAM_PHASE;
        end
        else begin
            if ( in_update_req ) begin
                reg_update_req <= 1'b1;
            end
            
            if ( cke ) begin
                if ( reg_update_req & update_trig & update_en ) begin
                    reg_update_req     <= 1'b0;
                    
                    core_ctl_control <= reg_ctl_control[0];
                    core_param_phase <= reg_param_phase;
                end
            end
        end
    end
    
    
    // core
    jelly2_img_demosaic_acpi_core
            #(
                .USER_WIDTH         (USER_WIDTH),
                .DATA_WIDTH         (DATA_WIDTH),
                .MAX_COLS           (MAX_COLS),
                .USE_VALID          (USE_VALID),
                .RAM_TYPE           (RAM_TYPE)
            )
        i_img_demosaic_acpi_core
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .param_phase        (core_param_phase),
                .param_bypass       (~core_ctl_control[0]),
                
                .s_img_row_first    (s_img_row_first),
                .s_img_row_last     (s_img_row_last),
                .s_img_col_first    (s_img_col_first),
                .s_img_col_last     (s_img_col_last),
                .s_img_de           (s_img_de),
                .s_img_user         (s_img_user),
                .s_img_raw          (s_img_raw),
                .s_img_valid        (s_img_valid),
                
                .m_img_row_first    (m_img_row_first),
                .m_img_row_last     (m_img_row_last),
                .m_img_col_first    (m_img_col_first),
                .m_img_col_last     (m_img_col_last),
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
