// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_data_combin_pack
        #(
            parameter NUM         = 1,
            parameter DATA0_WIDTH = 8,
            parameter DATA1_WIDTH = 8,
            parameter DATA2_WIDTH = 0,
            parameter DATA3_WIDTH = 0,
            parameter DATA4_WIDTH = 0,
            parameter DATA5_WIDTH = 0,
            parameter DATA6_WIDTH = 0,
            parameter DATA7_WIDTH = 0,
            parameter DATA8_WIDTH = 0,
            parameter DATA9_WIDTH = 0,
            parameter S_REGS      = 1,
            parameter M_REGS      = 1,
            
            // local
            parameter DATA0_BITS  = DATA0_WIDTH > 0 ? DATA0_WIDTH : 1,
            parameter DATA1_BITS  = DATA1_WIDTH > 0 ? DATA1_WIDTH : 1,
            parameter DATA2_BITS  = DATA2_WIDTH > 0 ? DATA2_WIDTH : 1,
            parameter DATA3_BITS  = DATA3_WIDTH > 0 ? DATA3_WIDTH : 1,
            parameter DATA4_BITS  = DATA4_WIDTH > 0 ? DATA4_WIDTH : 1,
            parameter DATA5_BITS  = DATA5_WIDTH > 0 ? DATA5_WIDTH : 1,
            parameter DATA6_BITS  = DATA6_WIDTH > 0 ? DATA6_WIDTH : 1,
            parameter DATA7_BITS  = DATA7_WIDTH > 0 ? DATA7_WIDTH : 1,
            parameter DATA8_BITS  = DATA8_WIDTH > 0 ? DATA8_WIDTH : 1,
            parameter DATA9_BITS  = DATA9_WIDTH > 0 ? DATA9_WIDTH : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire    [DATA0_BITS-1:0]    s0_data,
            input   wire                        s0_valid,
            output  wire                        s0_ready,
            
            input   wire    [DATA1_BITS-1:0]    s1_data,
            input   wire                        s1_valid,
            output  wire                        s1_ready,
            
            input   wire    [DATA2_BITS-1:0]    s2_data,
            input   wire                        s2_valid,
            output  wire                        s2_ready,
            
            input   wire    [DATA3_BITS-1:0]    s3_data,
            input   wire                        s3_valid,
            output  wire                        s3_ready,
            
            input   wire    [DATA4_BITS-1:0]    s4_data,
            input   wire                        s4_valid,
            output  wire                        s4_ready,
            
            input   wire    [DATA5_BITS-1:0]    s5_data,
            input   wire                        s5_valid,
            output  wire                        s5_ready,
            
            input   wire    [DATA6_BITS-1:0]    s6_data,
            input   wire                        s6_valid,
            output  wire                        s6_ready,
            
            input   wire    [DATA7_BITS-1:0]    s7_data,
            input   wire                        s7_valid,
            output  wire                        s7_ready,
            
            input   wire    [DATA8_BITS-1:0]    s8_data,
            input   wire                        s8_valid,
            output  wire                        s8_ready,
            
            input   wire    [DATA9_BITS-1:0]    s9_data,
            input   wire                        s9_valid,
            output  wire                        s9_ready,
            
            
            output  wire    [DATA0_BITS-1:0]    m_data0,
            output  wire    [DATA1_BITS-1:0]    m_data1,
            output  wire    [DATA2_BITS-1:0]    m_data2,
            output  wire    [DATA3_BITS-1:0]    m_data3,
            output  wire    [DATA4_BITS-1:0]    m_data4,
            output  wire    [DATA5_BITS-1:0]    m_data5,
            output  wire    [DATA6_BITS-1:0]    m_data6,
            output  wire    [DATA7_BITS-1:0]    m_data7,
            output  wire    [DATA8_BITS-1:0]    m_data8,
            output  wire    [DATA9_BITS-1:0]    m_data9,
            output  wire                        m_valid,
            input   wire                        m_ready
        );
    
    
    // pack
    localparam PACK_WIDTH   = DATA0_WIDTH
                            + DATA1_WIDTH
                            + DATA2_WIDTH
                            + DATA3_WIDTH
                            + DATA4_WIDTH
                            + DATA5_WIDTH
                            + DATA6_WIDTH
                            + DATA7_WIDTH
                            + DATA8_WIDTH
                            + DATA9_WIDTH;
    
    localparam PACK_BITS    = PACK_WIDTH > 0 ? PACK_WIDTH : 1;
    
    wire    [PACK_BITS-1:0]     s_pack;
    wire    [NUM-1:0]           s_valid;
    wire    [NUM-1:0]           s_ready;
    
    wire    [PACK_BITS-1:0]     m_pack;
    
    assign s_valid = {s9_valid, s8_valid, s7_valid, s6_valid, s5_valid, s4_valid, s3_valid, s2_valid, s1_valid, s0_valid};
    assign {s9_ready, s8_ready, s7_ready, s6_ready, s5_ready, s4_ready, s3_ready, s2_ready, s1_ready, s0_ready} = s_ready;
    
    jelly_func_pack
            #(
                .N          (1),
                .W0         (DATA0_WIDTH),
                .W1         (DATA1_WIDTH),
                .W2         (DATA2_WIDTH),
                .W3         (DATA3_WIDTH),
                .W4         (DATA4_WIDTH),
                .W5         (DATA5_WIDTH),
                .W6         (DATA6_WIDTH),
                .W7         (DATA7_WIDTH),
                .W8         (DATA8_WIDTH),
                .W9         (DATA9_WIDTH)
            )
        i_func_pack
            (
                .in0        (s0_data),
                .in1        (s1_data),
                .in2        (s2_data),
                .in3        (s3_data),
                .in4        (s4_data),
                .in5        (s5_data),
                .in6        (s6_data),
                .in7        (s7_data),
                .in8        (s8_data),
                .in9        (s9_data),
                .out        (s_pack)
            );
    
    jelly_func_unpack
            #(
                .N          (1),
                .W0         (DATA0_WIDTH),
                .W1         (DATA1_WIDTH),
                .W2         (DATA2_WIDTH),
                .W3         (DATA3_WIDTH),
                .W4         (DATA4_WIDTH),
                .W5         (DATA5_WIDTH),
                .W6         (DATA6_WIDTH),
                .W7         (DATA7_WIDTH),
                .W8         (DATA8_WIDTH),
                .W9         (DATA9_WIDTH)
            )
        i_func_unpack
            (
                .in         (m_pack),
                .out0       (m_data0),
                .out1       (m_data1),
                .out2       (m_data2),
                .out3       (m_data3),
                .out4       (m_data4),
                .out5       (m_data5),
                .out6       (m_data6),
                .out7       (m_data7),
                .out8       (m_data8),
                .out9       (m_data9)
            );
    
    // combiner
    jelly_data_combin
            #(
                .NUM        (NUM),
                .DATA_WIDTH (PACK_WIDTH),
                .S_REGS     (S_REGS),
                .M_REGS     (M_REGS)
            )
        i_data_combin
            (
                .reset      (reset),
                .clk        (clk),
                .cke        (cke),
                
                .s_data     (s_pack),
                .s_valid    (s_valid),
                .s_ready    (s_ready),
                
                .m_data     (m_pack),
                .m_valid    (m_valid),
                .m_ready    (m_ready)
            );
    
    
endmodule


`default_nettype wire


// end of file
