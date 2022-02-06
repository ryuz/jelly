


`timescale 1ns / 1ps
`default_nettype none


module video_filter_hls
        #(
            parameter   WB_ADR_WIDTH       = 17,
            parameter   WB_DAT_WIDTH       = 32,
            parameter   WB_SEL_WIDTH       = (WB_DAT_WIDTH / 8),
               
            parameter   X_WIDTH            = 16,
            parameter   Y_WIDTH            = 16,
            parameter   DATA_WIDTH         = 24,

            parameter   INIT_PARAM_ENABLE  = 0
        )
        (
            input   wire                            aresetn,
            input   wire                            aclk,
            
            input   wire    [0:0]                   s_axi4s_tuser,
            input   wire                            s_axi4s_tlast,
            input   wire    [DATA_WIDTH-1:0]        s_axi4s_tdata,
            input   wire                            s_axi4s_tvalid,
            output  wire                            s_axi4s_tready,

            output  wire    [0:0]                   m_axi4s_tuser,
            output  wire                            m_axi4s_tlast,
            output  wire    [DATA_WIDTH-1:0]        m_axi4s_tdata,
            output  wire                            m_axi4s_tvalid,
            input   wire                            m_axi4s_tready,

            input   wire    [X_WIDTH-1:0]           param_width,
            input   wire    [Y_WIDTH-1:0]           param_height,

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



    // -------------------------------------
    //  registers domain
    // -------------------------------------
    
    // register address offset
    localparam  ADR_CORE_ID       = 'h00;
    localparam  ADR_CORE_VERSION  = 'h01;
    localparam  ADR_PARAM_ENABLE  = 'h08;
    
    // registers
    reg     [0:0]                   reg_param_enable;
    
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
            reg_param_enable <= INIT_PARAM_ENABLE;
        end
        else begin
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_PARAM_ENABLE: reg_param_enable <= 1'(write_mask(WB_DAT_WIDTH'(reg_param_enable), s_wb_dat_i, s_wb_sel_i));
                endcase
            end
        end
    end
    
    // read
    assign s_wb_dat_o = (int'(s_wb_adr_i) == ADR_CORE_ID)      ? WB_DAT_WIDTH'(32'hffff_fff1   ) :
                        (int'(s_wb_adr_i) == ADR_CORE_VERSION) ? WB_DAT_WIDTH'(32'h0001_0000   ) :
                        (int'(s_wb_adr_i) == ADR_PARAM_ENABLE) ? WB_DAT_WIDTH'(reg_param_enable) :
                        {WB_DAT_WIDTH{1'b0}};
    assign s_wb_ack_o = s_wb_stb_i;
    
    
    video_filter_0
        i_video_filter_0
            (
                .ap_clk             (aclk),
                .ap_rst_n           (aresetn),
                
                .ap_start           (1'b1),
                .ap_done            (),
                .ap_idle            (),
                .ap_ready           (),

                .s_axi4s_TDATA      (s_axi4s_tdata),
                .s_axi4s_TVALID     (s_axi4s_tvalid),
                .s_axi4s_TREADY     (s_axi4s_tready),
                .s_axi4s_TKEEP      (),
                .s_axi4s_TSTRB      (),
                .s_axi4s_TUSER      (s_axi4s_tuser),
                .s_axi4s_TLAST      (s_axi4s_tlast),
                .s_axi4s_TID        (),
                .s_axi4s_TDEST      (),

                .m_axi4s_TDATA      (m_axi4s_tdata),
                .m_axi4s_TVALID     (m_axi4s_tvalid),
                .m_axi4s_TREADY     (m_axi4s_tready),
                .m_axi4s_TKEEP      (),
                .m_axi4s_TSTRB      (),
                .m_axi4s_TUSER      (m_axi4s_tuser),
                .m_axi4s_TLAST      (m_axi4s_tlast),
                .m_axi4s_TID        (),
                .m_axi4s_TDEST      (),
                
                .width_V            (param_width),
                .height_V           (param_height),
                .enable             (reg_param_enable)
            );

endmodule

`default_nettype wire 

