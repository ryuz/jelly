// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_video_overlay_bram
        #(
            parameter   int                         TUSER_WIDTH        = 1,
            parameter   int                         TDATA_WIDTH        = 24,
            parameter   int                         IMG_X_WIDTH        = 12,
            parameter   int                         IMG_Y_WIDTH        = 12,
            parameter   int                         MEM_X_WIDTH        = 8,
            parameter   int                         MEM_Y_WIDTH        = 7,

            parameter   int                         WB_ADR_WIDTH       = 20,
            parameter   int                         WB_DAT_WIDTH       = 32,
            parameter   int                         WB_SEL_WIDTH       = (WB_DAT_WIDTH / 8),

            parameter   bit     [31:0]              CORE_ID            = 32'h527a_2400,
            parameter   bit     [31:0]              CORE_VERSION       = 32'h0001_0000,
            parameter   int                         INDEX_WIDTH        = 1,
            
            parameter   bit     [WB_ADR_WIDTH-1:0]  MEM_OFFSET         = (1 << (MEM_X_WIDTH + MEM_Y_WIDTH)),
            parameter                               RAM_TYPE           = "block",

            parameter   bit     [1:0]               INIT_CTL_CONTROL   = 2'b00,
            parameter   bit     [IMG_X_WIDTH-1:0]   INIT_PARAM_X       = '0,
            parameter   bit     [IMG_Y_WIDTH-1:0]   INIT_PARAM_Y       = '0,
            parameter   bit     [IMG_X_WIDTH-1:0]   INIT_PARAM_WIDTH   = '0,
            parameter   bit     [IMG_Y_WIDTH-1:0]   INIT_PARAM_HEIGHT  = '0,
            parameter   bit                         INIT_PARAM_BG_EN   = '0,
            parameter   bit     [TDATA_WIDTH-1:0]   INIT_PARAM_BG_DATA = '0
        )
        (
            input   wire                            aresetn,
            input   wire                            aclk,
            input   wire                            aclken,

            input   wire                            in_update_req,

            input   wire    [TUSER_WIDTH-1:0]       s_axi4s_tuser,
            input   wire                            s_axi4s_tlast,
            input   wire    [TDATA_WIDTH-1:0]       s_axi4s_tdata,
            input   wire                            s_axi4s_tvalid,
            output  reg                             s_axi4s_tready,

            output  reg     [TUSER_WIDTH-1:0]       m_axi4s_tuser,
            output  reg                             m_axi4s_tlast,
            output  reg     [TDATA_WIDTH-1:0]       m_axi4s_tdata,
            output  reg                             m_axi4s_tvalid,
            input   wire                            m_axi4s_tready,

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
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CORE_ID         = WB_ADR_WIDTH'('h00);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CORE_VERSION    = WB_ADR_WIDTH'('h01);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CTL_CONTROL     = WB_ADR_WIDTH'('h04);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CTL_STATUS      = WB_ADR_WIDTH'('h05);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CTL_INDEX       = WB_ADR_WIDTH'('h07);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_X         = WB_ADR_WIDTH'('h08);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_Y         = WB_ADR_WIDTH'('h09);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_WIDTH     = WB_ADR_WIDTH'('h0a);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_HEIGHT    = WB_ADR_WIDTH'('h0b);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_BG_EN     = WB_ADR_WIDTH'('h0e);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_BG_DATA   = WB_ADR_WIDTH'('h0f);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CFG_MEM_OFFSET  = WB_ADR_WIDTH'('h20);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CFG_MEM_X_WIDTH = WB_ADR_WIDTH'('h22);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CFG_MEM_Y_WIDTH = WB_ADR_WIDTH'('h23);

    // registers
    logic   [1:0]               reg_ctl_control;
    logic   [IMG_X_WIDTH-1:0]   reg_param_x;
    logic   [IMG_Y_WIDTH-1:0]   reg_param_y;
    logic   [IMG_X_WIDTH-1:0]   reg_param_width;
    logic   [IMG_Y_WIDTH-1:0]   reg_param_height;
    logic                       reg_param_bg_en;
    logic   [TDATA_WIDTH-1:0]   reg_param_bg_data;
    
    // shadow registers(core domain)
    logic   [0:0]               core_ctl_control;
    logic   [IMG_X_WIDTH-1:0]   core_param_x;
    logic   [IMG_Y_WIDTH-1:0]   core_param_y;
    logic   [IMG_X_WIDTH-1:0]   core_param_width;
    logic   [IMG_Y_WIDTH-1:0]   core_param_height;
    logic                       core_param_bg_en;
    logic   [TDATA_WIDTH-1:0]   core_param_bg_data;
    

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
    always @(posedge s_wb_clk_i) begin
        if ( s_wb_rst_i ) begin
            reg_ctl_control   <= INIT_CTL_CONTROL;
            reg_param_x       <= INIT_PARAM_X;
            reg_param_y       <= INIT_PARAM_Y;
            reg_param_width   <= INIT_PARAM_WIDTH;
            reg_param_height  <= INIT_PARAM_HEIGHT;
            reg_param_bg_en   <= INIT_PARAM_BG_EN;
            reg_param_bg_data <= INIT_PARAM_BG_DATA;
        end
        else begin
            if ( update_ack ) begin
                reg_ctl_control[1] <= 1'b0;     // auto clear
            end
            
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_CTL_CONTROL:  reg_ctl_control   <=           2'(write_mask(WB_DAT_WIDTH'(reg_ctl_control  ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_X:        reg_param_x       <= IMG_X_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_x      ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_Y:        reg_param_y       <= IMG_Y_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_y      ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_WIDTH:    reg_param_width   <= IMG_X_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_width  ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_HEIGHT:   reg_param_height  <= IMG_Y_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_height ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_BG_EN:    reg_param_bg_en   <=           1'(write_mask(WB_DAT_WIDTH'(reg_param_bg_en  ), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_BG_DATA:  reg_param_bg_data <= TDATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_bg_data), s_wb_dat_i, s_wb_sel_i));
                default: ;
                endcase
            end
        end
    end
    
    // read
    always_comb begin
        s_wb_dat_o = '0;
        case ( s_wb_adr_i )
        ADR_CORE_ID:            s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID           );
        ADR_CORE_VERSION:       s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION      );
        ADR_CTL_CONTROL:        s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_control   );
        ADR_CTL_STATUS:         s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_control[0]);
        ADR_CTL_INDEX:          s_wb_dat_o = WB_DAT_WIDTH'(ctl_index         );
        ADR_PARAM_X:            s_wb_dat_o = WB_DAT_WIDTH'(reg_param_x       );
        ADR_PARAM_Y:            s_wb_dat_o = WB_DAT_WIDTH'(reg_param_y       );
        ADR_PARAM_WIDTH:        s_wb_dat_o = WB_DAT_WIDTH'(reg_param_width   );
        ADR_PARAM_HEIGHT:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_height  );
        ADR_PARAM_BG_EN:        s_wb_dat_o = WB_DAT_WIDTH'(reg_param_bg_en   );
        ADR_PARAM_BG_DATA:      s_wb_dat_o = WB_DAT_WIDTH'(reg_param_bg_data );
        ADR_CFG_MEM_OFFSET:     s_wb_dat_o = WB_DAT_WIDTH'(MEM_OFFSET);
        ADR_CFG_MEM_X_WIDTH:    s_wb_dat_o = WB_DAT_WIDTH'(MEM_X_WIDTH);
        ADR_CFG_MEM_Y_WIDTH:    s_wb_dat_o = WB_DAT_WIDTH'(MEM_Y_WIDTH);

        default: ;
        endcase
    end
    
    always_comb s_wb_ack_o = s_wb_stb_i;
    

    // -------------------------------------
    //  memory
    // -------------------------------------

    localparam  MEM_ADDR_WIDTH = MEM_Y_WIDTH + MEM_X_WIDTH;
    localparam  MEM_DATA_WIDTH = TDATA_WIDTH;

    logic                               port0_en;
    logic   [0:0]                       port0_we;
    logic   [MEM_ADDR_WIDTH-1:0]        port0_addr;
    logic   [MEM_DATA_WIDTH-1:0]        port0_din;

    logic                               port1_en;
    logic   [MEM_X_WIDTH-1:0]           port1_addr_x;
    logic   [MEM_Y_WIDTH-1:0]           port1_addr_y;
    logic   [MEM_DATA_WIDTH-1:0]        port1_dout;

    jelly2_ram_dualport
            #(
                .ADDR_WIDTH     (MEM_ADDR_WIDTH),
                .DATA_WIDTH     (TDATA_WIDTH),
                .RAM_TYPE       (RAM_TYPE),
                .DOUT_REGS0     (0),
                .DOUT_REGS1     (0)
            )
        i_ram_dualport
            (
                .port0_clk      (s_wb_clk_i),
                .port0_en       (port0_en),
                .port0_regcke   (1'b0),
                .port0_we       (port0_we),
                .port0_addr     (port0_addr),
                .port0_din      (port0_din),
                .port0_dout     (),
                
                .port1_clk      (aclk),
                .port1_en       (port1_en),
                .port1_regcke   (1'b0),
                .port1_we       ('0),
                .port1_addr     ({port1_addr_y, port1_addr_x}),
                .port1_din      ('0),
                .port1_dout     (port1_dout)
            );
    
    always_comb port0_en   = s_wb_stb_i && (s_wb_adr_i >= MEM_OFFSET);
    always_comb port0_we   = s_wb_we_i;
    always_comb port0_addr = s_wb_adr_i[MEM_ADDR_WIDTH-1:0];
    always_comb port0_din  = s_wb_dat_i[MEM_DATA_WIDTH-1:0];

    
    
    // -------------------------------------
    //  core domain
    // -------------------------------------
    
    // handshake with registers domain
    logic           update_trig;
    logic           update_en;
    
    always_comb update_trig = (s_axi4s_tuser[0] && s_axi4s_tvalid & s_axi4s_tready);

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
    logic           update_req;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            update_req         <= 1'b0;
            core_ctl_control   <= INIT_CTL_CONTROL[0];
            core_param_x       <= INIT_PARAM_X;
            core_param_y       <= INIT_PARAM_Y;
            core_param_width   <= INIT_PARAM_WIDTH;
            core_param_height  <= INIT_PARAM_HEIGHT;
            core_param_bg_en   <= INIT_PARAM_BG_EN;
            core_param_bg_data <= INIT_PARAM_BG_DATA;
        end
        else begin
            if ( in_update_req ) begin
                update_req <= 1'b1;
            end

            if ( aclken ) begin
                if ( update_req & update_trig & update_en ) begin
                    update_req      <= 1'b0;
                    core_ctl_control   <= reg_ctl_control[0];
                    core_param_x       <= reg_param_x;
                    core_param_y       <= reg_param_y;
                    core_param_width   <= reg_param_width;
                    core_param_height  <= reg_param_height;
                    core_param_bg_en   <= reg_param_bg_en;
                    core_param_bg_data <= reg_param_bg_data;
                end
            end
        end
    end
    
    
    // core
    jelly2_video_overlay_bram_core
            #(
                .TUSER_WIDTH    (TUSER_WIDTH),
                .TDATA_WIDTH    (TDATA_WIDTH),
                .IMG_X_WIDTH    (IMG_X_WIDTH),
                .IMG_Y_WIDTH    (IMG_Y_WIDTH),
                .MEM_X_WIDTH    (MEM_X_WIDTH),
                .MEM_Y_WIDTH    (MEM_Y_WIDTH)
            )
        i_video_overlay_bram_core
            (
                .aresetn,
                .aclk,
                .aclken,
                
                .enable         (core_ctl_control[0]),

                .param_x        (core_param_x),
                .param_y        (core_param_y),
                .param_width    (core_param_width),
                .param_height   (core_param_height),
                .param_bg_en    (core_param_bg_en),
                .param_bg_data  (core_param_bg_data),

                .mem_en         (port1_en),
                .mem_addrx      (port1_addr_x),
                .mem_addry      (port1_addr_y),
                .mem_dout       (port1_dout),
                
                .s_axi4s_tuser,
                .s_axi4s_tlast,
                .s_axi4s_tdata,
                .s_axi4s_tvalid,
                .s_axi4s_tready,
                
                .m_axi4s_tuser,
                .m_axi4s_tlast,
                .m_axi4s_tdata,
                .m_axi4s_tvalid,
                .m_axi4s_tready
            );
    
    
endmodule


`default_nettype wire


// end of file
