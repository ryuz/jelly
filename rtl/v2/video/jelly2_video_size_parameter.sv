// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none

module jelly2_video_size_parameter
        #(
            parameter   int                     TUSER_WIDTH       = 1,
            parameter   int                     TDATA_WIDTH       = 24,
            parameter   int                     X_WIDTH           = 14,
            parameter   int                     Y_WIDTH           = 12,

            parameter   int                     WB_ADR_WIDTH      = 8,
            parameter   int                     WB_DAT_WIDTH      = 32,
            parameter   int                     WB_SEL_WIDTH      = (WB_DAT_WIDTH / 8),


            parameter   int                     INDEX_WIDTH       = 1,
            parameter   bit     [31:0]          CORE_ID           = 32'h527A1230,
            parameter   bit     [31:0]          CORE_VERSION      = 32'h00000000,
            parameter   bit     [2:0]           INIT_CTL_CONTROL  = 3'b011,
            parameter   bit     [X_WIDTH-1:0]   INIT_PARAM_X_SIZE = 0,
            parameter   bit     [Y_WIDTH-1:0]   INIT_PARAM_Y_SIZE = 0
        )
        (
            input   wire                        aresetn,
            input   wire                        aclk,
            input   wire                        aclken,
            
            input   wire                        in_update_req,
            
            input   wire    [TUSER_WIDTH-1:0]   s_axi4s_tuser,
            input   wire                        s_axi4s_tlast,
            input   wire    [TDATA_WIDTH-1:0]   s_axi4s_tdata,
            input   wire                        s_axi4s_tvalid,
            output  reg                         s_axi4s_tready,

            output  reg     [X_WIDTH-1:0]       m_axi4s_x_size,
            output  reg     [Y_WIDTH-1:0]       m_axi4s_y_size,
            output  reg     [TUSER_WIDTH-1:0]   m_axi4s_tuser,
            output  reg                         m_axi4s_tlast,
            output  reg     [TDATA_WIDTH-1:0]   m_axi4s_tdata,
            output  reg                         m_axi4s_tvalid,
            input   wire                        m_axi4s_tready,

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
    
    // register address offset
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_ID      = WB_ADR_WIDTH'('h00);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_VERSION = WB_ADR_WIDTH'('h01);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_CONTROL  = WB_ADR_WIDTH'('h04);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_STATUS   = WB_ADR_WIDTH'('h05);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_INDEX    = WB_ADR_WIDTH'('h07);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_X_SIZE = WB_ADR_WIDTH'('h10);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_Y_SIZE = WB_ADR_WIDTH'('h11);

    // registers
    logic   [2:0]                   reg_ctl_control; 
    logic   [X_WIDTH-1:0]           reg_param_x_size;
    logic   [Y_WIDTH-1:0]           reg_param_y_size;
    
    // shadow registers(core domain)
    logic   [0:0]                   core_ctl_control; 
    logic   [X_WIDTH-1:0]           core_param_x_size;
    logic   [Y_WIDTH-1:0]           core_param_y_size;
    
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
            reg_ctl_control   <= INIT_CTL_CONTROL;
            reg_param_x_size  <= INIT_PARAM_X_SIZE;
            reg_param_y_size  <= INIT_PARAM_Y_SIZE;
        end
        else begin
            // auto clear
            if ( update_ack && !reg_ctl_control[2] ) begin
                reg_ctl_control[1] <= 1'b0;
            end
            
            // write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_CTL_CONTROL:    reg_ctl_control   <=        3'(write_mask(WB_DAT_WIDTH'(reg_ctl_control ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_X_SIZE:   reg_param_x_size  <=  X_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_x_size), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_Y_SIZE:   reg_param_y_size  <=  Y_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_y_size), s_wb_dat_i, s_wb_sel_i));
                default: ;
                endcase
            end
        end
    end
    
    // read (shadow register は クロック同期してないのであくまでデバッグ用)
    always_comb begin
        s_wb_dat_o = '0;
        case ( s_wb_adr_i )
        ADR_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID         );
        ADR_CORE_VERSION:   s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION    );
        ADR_CTL_CONTROL:    s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_control );
        ADR_CTL_STATUS:     s_wb_dat_o = WB_DAT_WIDTH'(1               );
        ADR_CTL_INDEX:      s_wb_dat_o = WB_DAT_WIDTH'(ctl_index       );
        ADR_PARAM_X_SIZE:   s_wb_dat_o = WB_DAT_WIDTH'(reg_param_x_size);
        ADR_PARAM_Y_SIZE:   s_wb_dat_o = WB_DAT_WIDTH'(reg_param_y_size);
        default: ;
        endcase
    end
    
    always_comb s_wb_ack_o = s_wb_stb_i;
    
    
    
    
    // -------------------------------------
    //  core domain
    // -------------------------------------
    
    // handshake with registers domain
    wire    update_trig = (s_axi4s_tuser & s_axi4s_tvalid & s_axi4s_tready);
    wire    update_en;
    
    jelly_param_update_slave
            #(
                .INDEX_WIDTH    (INDEX_WIDTH)
            )
        i_param_update_slave
            (
                .reset          (~aresetn),
                .clk            (aclk),
                .cke            (aclken),
                
                .in_trigger     (update_trig),
                .in_update      (reg_ctl_control[1]),
                
                .out_update     (update_en),
                .out_index      (update_index)
            );
    
    // wait for frame start to update parameters
    reg                 reg_update_req;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            reg_update_req    <= 1'b0;
            core_ctl_control  <= INIT_CTL_CONTROL[0];
            core_param_x_size <= INIT_PARAM_X_SIZE;
            core_param_y_size <= INIT_PARAM_Y_SIZE;
        end
        else if ( aclken ) begin
            if ( in_update_req ) begin
                reg_update_req <= 1'b1;
            end
        
            if ( reg_update_req & update_trig & update_en ) begin
                reg_update_req    <= 1'b0;
                core_ctl_control  <= reg_ctl_control[0];
                core_param_x_size <= reg_param_x_size;
                core_param_y_size <= reg_param_y_size;
            end
        end
    end
    
    logic   [TUSER_WIDTH-1:0]   core_tuser;
    logic                       core_tlast;
    logic   [TDATA_WIDTH-1:0]   core_tdata;
    logic                       core_tvalid;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            core_tuser  <= 'x;
            core_tlast  <= 'x;
            core_tdata  <= 'x;
            core_tvalid <= 1'b0;
        end
        else if ( aclken ) begin
            if ( s_axi4s_tready ) begin
                core_tuser  <= s_axi4s_tuser;
                core_tlast  <= s_axi4s_tlast;
                core_tdata  <= s_axi4s_tdata;
                core_tvalid <= s_axi4s_tvalid;
            end
        end
    end

    always_comb s_axi4s_tready = m_axi4s_tready;

    always_comb m_axi4s_x_size = core_param_x_size;
    always_comb m_axi4s_y_size = core_param_y_size;
    always_comb m_axi4s_tuser  = core_tuser;
    always_comb m_axi4s_tlast  = core_tlast;
    always_comb m_axi4s_tdata  = core_tdata;
    always_comb m_axi4s_tvalid = core_tvalid & core_ctl_control[0];
    
endmodule


`default_nettype wire


// end of file
