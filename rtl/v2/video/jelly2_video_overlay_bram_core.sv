// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   math
//
//                                 Copyright (C) 2008-2022 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_video_overlay_bram_core
        #(
            parameter   int     TUSER_WIDTH = 1,
            parameter   int     TDATA_WIDTH = 24,
            parameter   int     IMG_X_WIDTH = 12,
            parameter   int     IMG_Y_WIDTH = 12,
            parameter   int     MEM_X_WIDTH = 8,
            parameter   int     MEM_Y_WIDTH = 7
        )
        (
            input   wire                        aresetn,
            input   wire                        aclk,
            input   wire                        aclken,
            
            input   wire                        enable,

            input   wire    [IMG_X_WIDTH-1:0]   param_x,
            input   wire    [IMG_Y_WIDTH-1:0]   param_y,
            input   wire    [IMG_X_WIDTH-1:0]   param_width,
            input   wire    [IMG_Y_WIDTH-1:0]   param_height,
            input   wire                        param_bg_en,
            input   wire    [TDATA_WIDTH-1:0]   param_bg_data,

            output  reg                         mem_en,
            output  reg     [MEM_X_WIDTH-1:0]   mem_addrx,
            output  reg     [MEM_Y_WIDTH-1:0]   mem_addry,
            input   wire    [TDATA_WIDTH-1:0]   mem_dout,
            
            input   wire    [TUSER_WIDTH-1:0]   s_axi4s_tuser,
            input   wire                        s_axi4s_tlast,
            input   wire    [TDATA_WIDTH-1:0]   s_axi4s_tdata,
            input   wire                        s_axi4s_tvalid,
            output  reg                         s_axi4s_tready,
            
            output  reg     [TUSER_WIDTH-1:0]   m_axi4s_tuser,
            output  reg                         m_axi4s_tlast,
            output  reg     [TDATA_WIDTH-1:0]   m_axi4s_tdata,
            output  reg                         m_axi4s_tvalid,
            input   wire                        m_axi4s_tready
        );
    

    logic   [IMG_X_WIDTH-1:0]       st0_img_x;
    logic   [IMG_Y_WIDTH-1:0]       st0_img_y;
    logic   [TUSER_WIDTH-1:0]       st0_tuser;
    logic                           st0_tlast;
    logic   [TDATA_WIDTH-1:0]       st0_tdata;
    logic                           st0_tvalid;

    logic                           st1_overlay;
    logic   [IMG_X_WIDTH-1:0]       st1_mem_x;
    logic   [IMG_Y_WIDTH-1:0]       st1_mem_y;
    logic   [TUSER_WIDTH-1:0]       st1_tuser;
    logic                           st1_tlast;
    logic   [TDATA_WIDTH-1:0]       st1_tdata;
    logic                           st1_tvalid;

    logic                           st2_overlay;
    logic   [TUSER_WIDTH-1:0]       st2_tuser;
    logic                           st2_tlast;
    logic   [TDATA_WIDTH-1:0]       st2_tdata;
    logic                           st2_tvalid;

    logic   [TUSER_WIDTH-1:0]       st3_tuser;
    logic                           st3_tlast;
    logic   [TDATA_WIDTH-1:0]       st3_tdata;
    logic                           st3_tvalid;

    always_ff @ (posedge aclk) begin
        if ( ~aresetn ) begin
            st0_tvalid <= 1'b0;
            st1_tvalid <= 1'b0;
            st3_tvalid <= 1'b0;
            st2_tvalid <= 1'b0;
        end
        else if ( aclken ) begin
            if ( s_axi4s_tready ) begin
                st0_tvalid <= s_axi4s_tvalid;
                st1_tvalid <= st0_tvalid;
                st3_tvalid <= st1_tvalid;
                st2_tvalid <= st1_tvalid;
            end
        end
    end
    
    always_ff @ (posedge aclk) begin
        if ( aclken ) begin
            if ( s_axi4s_tready ) begin
                // stage0 (paramは使わないこと)
                if ( s_axi4s_tvalid && s_axi4s_tuser[0] ) begin
                    st0_img_x <= '0;
                    st0_img_y <= '0;
                end
                else if ( st0_tvalid && st0_tlast ) begin
                    st0_img_x <= '0;
                    st0_img_y <= st0_img_y + 1'b1;
                end
                else if ( s_axi4s_tvalid ) begin
                    st0_img_x <= st0_img_x + 1'b1;
                end
                st0_tuser  <= s_axi4s_tuser;
                st0_tlast  <= s_axi4s_tlast;
                st0_tdata  <= s_axi4s_tdata;

                // stage 1
                st1_overlay <= (st0_img_x >= param_x) && (st0_img_y >= param_y);
                st1_mem_x   <= st0_img_x - param_x;
                st1_mem_y   <= st0_img_y - param_y;
                st1_tuser   <= st0_tuser;
                st1_tlast   <= st0_tlast;
                st1_tdata   <= st0_tdata;

                // stage 2
                st2_overlay <= st1_overlay && (st1_mem_x < param_width) && (st1_mem_y < param_height);
                st2_tuser   <= st1_tuser;
                st2_tlast   <= st1_tlast;
                st2_tdata   <= st1_tdata;

                // stage 3
                st3_tuser   <= st1_tuser;
                st3_tlast   <= st1_tlast;
                st3_tdata   <= st1_tdata;
                if ( enable ) begin
                    if ( st2_overlay ) begin
                        st3_tdata <= mem_dout;
                    end
                    else if ( param_bg_en ) begin
                        st3_tdata <= param_bg_data;
                    end
                end
            end
        end
    end

    always_comb mem_en         = s_axi4s_tready && aclken;
    always_comb mem_addrx      = st1_mem_x[MEM_X_WIDTH-1:0];
    always_comb mem_addry      = st1_mem_y[MEM_Y_WIDTH-1:0];
    
    always_comb s_axi4s_tready = !m_axi4s_tvalid || m_axi4s_tready;

    always_comb m_axi4s_tuser  = st3_tuser;
    always_comb m_axi4s_tdata  = st3_tdata;
    always_comb m_axi4s_tlast  = st3_tlast;
    always_comb m_axi4s_tvalid = st3_tvalid;

endmodule


`default_nettype wire


// end of file
