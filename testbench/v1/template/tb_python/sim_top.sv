// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2022 by Ryuji Fuchikami 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module sim_top
        #(
            parameter   int     TUSER_WIDTH   = 1,
            parameter   int     COMPONENTS    = 3,
            parameter   int     DATA_WIDTH    = 8,
            parameter   int     IMG_X_WIDTH   = 10,
            parameter   int     IMG_Y_WIDTH   = 9,
            parameter   int     WB_ADR_WIDTH  = 8,
            parameter   int     WB_DAT_WIDTH  = 32,
            parameter   int     WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
        )
        (
            input   wire                                        aresetn,
            input   wire                                        aclk,

            input   wire    [IMG_X_WIDTH-1:0]                   param_img_width,
            input   wire    [IMG_Y_WIDTH-1:0]                   param_img_height,

            input   wire    [TUSER_WIDTH-1:0]                   s_axi4s_tuser,
            input   wire                                        s_axi4s_tlast,
            input   wire    [COMPONENTS-1:0][DATA_WIDTH-1:0]    s_axi4s_tdata,
            input   wire                                        s_axi4s_tvalid,
            output  wire                                        s_axi4s_tready,

            output  wire    [TUSER_WIDTH-1:0]                   m_axi4s_tuser,
            output  wire                                        m_axi4s_tlast,
            output  wire    [COMPONENTS-1:0][DATA_WIDTH-1:0]    m_axi4s_tdata,
            output  wire                                        m_axi4s_tvalid,
            input   wire                                        m_axi4s_tready,

            input   wire                                        s_wb_rst_i,
            input   wire                                        s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]                  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]                  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]                  s_wb_dat_o,
            input   wire                                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]                  s_wb_sel_i,
            input   wire                                        s_wb_stb_i,
            output  wire                                        s_wb_ack_o
        );
    
    int     cycle = 0;
    always_ff @(posedge aclk) begin
        cycle <= cycle + 1;
    end

    logic   [WB_DAT_WIDTH-1:0]      counter;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            counter <= '0;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end

    assign s_wb_dat_o = counter;
    assign s_wb_ack_o = s_wb_stb_i;


    assign m_axi4s_tuser  = s_axi4s_tuser;
    assign m_axi4s_tlast  = s_axi4s_tlast;
    assign m_axi4s_tdata  = ~s_axi4s_tdata;
    assign m_axi4s_tvalid = s_axi4s_tvalid;
    assign s_axi4s_tready = m_axi4s_tready;

endmodule


`default_nettype wire


// end of file
