// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_axi4s_width_converter
        #(
            parameter   UNIT_WIDTH       = 8,
            parameter   BYTE_WIDTH       = 8,
            parameter   S_DATA_WIDTH     = 8,
            parameter   M_DATA_WIDTH     = 32,
            parameter   USER_UNIT        = 1,
            parameter   S_USER_WIDTH     = 0,
            
            parameter   WITH_FIRST       = 1,
            parameter   WITH_LAST        = 1,
            parameter   WITH_STRB        = 1,
            parameter   WITH_KEEP        = 1,
            
            parameter   FIRST_FORCE_LAST = 1,  // firstで前方吐き出し時に残変換があれば強制的にlastを付与
            parameter   FIRST_OVERWRITE  = 0,  // first時前方に残変換があれば吐き出さずに上書き
            
            parameter   S_REGS           = 1,
            
            // local
            parameter   STRB_UNIT        = UNIT_WIDTH / BYTE_WIDTH,
            parameter   KEEP_UNIT        = UNIT_WIDTH / BYTE_WIDTH,
            parameter   S_USER_BITS      = S_USER_WIDTH > 0 ? S_USER_WIDTH : 1,
            parameter   S_STRB_WIDTH     = S_DATA_WIDTH / BYTE_WIDTH,
            parameter   S_KEEP_WIDTH     = S_DATA_WIDTH / BYTE_WIDTH,
            parameter   M_USER_WIDTH     = S_USER_WIDTH * M_DATA_WIDTH / S_DATA_WIDTH,
            parameter   M_USER_BITS      = M_USER_WIDTH > 0 ? M_USER_WIDTH : 1,
            parameter   M_STRB_WIDTH     = M_DATA_WIDTH / BYTE_WIDTH,
            parameter   M_KEEP_WIDTH     = M_DATA_WIDTH / BYTE_WIDTH
        )
        (
            input   wire                        aresetn,
            input   wire                        aclk,
            input   wire                        cke,
            input   wire                        endian,
            
            input   wire    [S_USER_BITS-1:0]   s_axi4s_tuser,
            input   wire    [S_DATA_WIDTH-1:0]  s_axi4s_tdata,
            input   wire    [S_STRB_WIDTH-1:0]  s_axi4s_tstrb,
            input   wire    [S_KEEP_WIDTH-1:0]  s_axi4s_tkeep,
            input   wire                        s_axi4s_tfirst,   // 独自仕様
            input   wire                        s_axi4s_tlast,
            input   wire                        s_axi4s_tvalid,
            output  wire                        s_axi4s_tready,
            
            output  wire    [M_USER_BITS-1:0]   m_axi4s_tuser,
            output  wire    [M_DATA_WIDTH-1:0]  m_axi4s_tdata,
            output  wire    [M_STRB_WIDTH-1:0]  m_axi4s_tstrb,
            output  wire    [M_KEEP_WIDTH-1:0]  m_axi4s_tkeep,
            output  wire                        m_axi4s_tfirst,   // 独自仕様
            output  wire                        m_axi4s_tlast,
            output  wire                        m_axi4s_tvalid,
            input   wire                        m_axi4s_tready
        );
    
    // tdata
    jelly_data_packing
            #(
                .UNIT_WIDTH         (UNIT_WIDTH),
                .S_NUM              (S_DATA_WIDTH / UNIT_WIDTH),
                .M_NUM              (M_DATA_WIDTH / UNIT_WIDTH),
                .PADDING_DATA       ({M_DATA_WIDTH{1'bx}}),
                .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                .FIRST_OVERWRITE    (FIRST_OVERWRITE),
                .S_REGS             (S_REGS)
            )
        i_data_packing_data
            (
                .reset              (~aresetn),
                .clk                (aclk),
                .cke                (cke),
                
                .endian             (endian),
                
                .s_first            (s_axi4s_tfirst & WITH_FIRST),
                .s_last             (s_axi4s_tlast  & WITH_LAST),
                .s_data             (s_axi4s_tdata),
                .s_valid            (s_axi4s_tvalid),
                .s_ready            (s_axi4s_tready),
                
                .m_first            (m_axi4s_tfirst),
                .m_last             (m_axi4s_tlast),
                .m_data             (m_axi4s_tdata),
                .m_valid            (m_axi4s_tvalid),
                .m_ready            (m_axi4s_tready)
            );
    
    // tuser
    generate
    if ( S_USER_WIDTH > 0 ) begin : blk_user
        jelly_data_packing
                #(
                    .UNIT_WIDTH         (USER_UNIT),
                    .S_NUM              (S_USER_WIDTH / USER_UNIT),
                    .M_NUM              (M_USER_WIDTH / USER_UNIT),
                    .PADDING_DATA       ({M_USER_WIDTH{1'bx}}),
                    .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                    .FIRST_OVERWRITE    (FIRST_OVERWRITE),
                    .S_REGS             (S_REGS)
                )
            i_data_packing_user
                (
                    .reset              (~aresetn),
                    .clk                (aclk),
                    .cke                (cke),
                    
                    .endian             (endian),
                    
                    .s_first            (s_axi4s_tfirst & WITH_FIRST),
                    .s_last             (s_axi4s_tlast  & WITH_LAST),
                    .s_data             (s_axi4s_tuser),
                    .s_valid            (s_axi4s_tvalid & s_axi4s_tready),
                    .s_ready            (),
                    
                    .m_first            (),
                    .m_last             (),
                    .m_data             (m_axi4s_tuser),
                    .m_valid            (),
                    .m_ready            (m_axi4s_tready)
                );
    end
    else begin : blk_without_user
        assign m_axi4s_tuser = {M_USER_WIDTH{1'bx}};
    end
    endgenerate
    
    
    // tstrb
    generate
    if ( WITH_STRB ) begin : blk_strb
        jelly_data_packing
                #(
                    .UNIT_WIDTH         (STRB_UNIT),
                    .S_NUM              (S_STRB_WIDTH / STRB_UNIT),
                    .M_NUM              (M_STRB_WIDTH / STRB_UNIT),
                    .PADDING_DATA       ({M_STRB_WIDTH{1'b0}}),
                    .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                    .FIRST_OVERWRITE    (FIRST_OVERWRITE),
                    .S_REGS             (S_REGS)
                )
            i_data_packing_strb
                (
                    .reset              (~aresetn),
                    .clk                (aclk),
                    .cke                (cke),
                    
                    .endian             (endian),
                    
                    .s_first            (s_axi4s_tfirst & WITH_FIRST),
                    .s_last             (s_axi4s_tlast  & WITH_LAST),
                    .s_data             (s_axi4s_tstrb),
                    .s_valid            (s_axi4s_tvalid & s_axi4s_tready),
                    .s_ready            (),
                    
                    .m_first            (),
                    .m_last             (),
                    .m_data             (m_axi4s_tstrb),
                    .m_valid            (),
                    .m_ready            (m_axi4s_tready)
                );
    end
    else begin : blk_without_strb
        assign m_axi4s_tstrb = {M_STRB_WIDTH{1'b0}};
    end
    endgenerate
    
    
    // tkeep
    generate
    if ( WITH_KEEP ) begin : blk_keep
        jelly_data_packing
                #(
                    .UNIT_WIDTH         (KEEP_UNIT),
                    .S_NUM              (S_KEEP_WIDTH / KEEP_UNIT),
                    .M_NUM              (M_KEEP_WIDTH / KEEP_UNIT),
                    .PADDING_DATA       ({M_KEEP_WIDTH{1'b0}}),
                    .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                    .FIRST_OVERWRITE    (FIRST_OVERWRITE),
                    .S_REGS             (S_REGS)
                )
            i_data_packing_keep
                (
                    .reset              (~aresetn),
                    .clk                (aclk),
                    .cke                (cke),
                    
                    .endian             (endian),
                    
                    .s_first            (s_axi4s_tfirst & WITH_FIRST),
                    .s_last             (s_axi4s_tlast  & WITH_LAST),
                    .s_data             (s_axi4s_tkeep),
                    .s_valid            (s_axi4s_tvalid & s_axi4s_tready),
                    .s_ready            (),
                    
                    .m_first            (),
                    .m_last             (),
                    .m_data             (m_axi4s_tkeep),
                    .m_valid            (),
                    .m_ready            (m_axi4s_tready)
                );
    end
    else begin : blk_without_keep
        assign m_axi4s_tkeep = {M_KEEP_WIDTH{1'b0}};
    end
    endgenerate
    
    
endmodule


`default_nettype wire


// end of file
