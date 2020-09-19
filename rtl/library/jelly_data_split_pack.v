// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_data_split_pack
        #(
            parameter NUM         = 10,
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
            
            input   wire    [DATA0_BITS-1:0]    s_data0,
            input   wire    [DATA1_BITS-1:0]    s_data1,
            input   wire    [DATA2_BITS-1:0]    s_data2,
            input   wire    [DATA3_BITS-1:0]    s_data3,
            input   wire    [DATA4_BITS-1:0]    s_data4,
            input   wire    [DATA5_BITS-1:0]    s_data5,
            input   wire    [DATA6_BITS-1:0]    s_data6,
            input   wire    [DATA7_BITS-1:0]    s_data7,
            input   wire    [DATA8_BITS-1:0]    s_data8,
            input   wire    [DATA9_BITS-1:0]    s_data9,
            input   wire                        s_valid,
            output  wire                        s_ready,
            
            output  wire    [DATA0_BITS-1:0]    m0_data,
            output  wire                        m0_valid,
            input   wire                        m0_ready,
            
            output  wire    [DATA1_BITS-1:0]    m1_data,
            output  wire                        m1_valid,
            input   wire                        m1_ready,
            
            output  wire    [DATA2_BITS-1:0]    m2_data,
            output  wire                        m2_valid,
            input   wire                        m2_ready,
            
            output  wire    [DATA3_BITS-1:0]    m3_data,
            output  wire                        m3_valid,
            input   wire                        m3_ready,
            
            output  wire    [DATA4_BITS-1:0]    m4_data,
            output  wire                        m4_valid,
            input   wire                        m4_ready,
            
            output  wire    [DATA5_BITS-1:0]    m5_data,
            output  wire                        m5_valid,
            input   wire                        m5_ready,
            
            output  wire    [DATA6_BITS-1:0]    m6_data,
            output  wire                        m6_valid,
            input   wire                        m6_ready,
            
            output  wire    [DATA7_BITS-1:0]    m7_data,
            output  wire                        m7_valid,
            input   wire                        m7_ready,
            
            output  wire    [DATA8_BITS-1:0]    m8_data,
            output  wire                        m8_valid,
            input   wire                        m8_ready,
            
            output  wire    [DATA9_BITS-1:0]    m9_data,
            output  wire                        m9_valid,
            input   wire                        m9_ready
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
    
    wire    [PACK_BITS-1:0]     m_pack;
    wire    [NUM-1:0]           m_valid;
    wire    [NUM-1:0]           m_ready;
    
    assign {m9_valid, m8_valid, m7_valid, m6_valid, m5_valid, m4_valid, m3_valid, m2_valid, m1_valid, m0_valid} = m_valid;
    assign m_ready = {m9_ready, m8_ready, m7_ready, m6_ready, m5_ready, m4_ready, m3_ready, m2_ready, m1_ready, m0_ready};
    
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
                .in0        (s_data0),
                .in1        (s_data1),
                .in2        (s_data2),
                .in3        (s_data3),
                .in4        (s_data4),
                .in5        (s_data5),
                .in6        (s_data6),
                .in7        (s_data7),
                .in8        (s_data8),
                .in9        (s_data9),
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
                .out0       (m0_data),
                .out1       (m1_data),
                .out2       (m2_data),
                .out3       (m3_data),
                .out4       (m4_data),
                .out5       (m5_data),
                .out6       (m6_data),
                .out7       (m7_data),
                .out8       (m8_data),
                .out9       (m9_data)
            );
    
    // split
    jelly_data_split
            #(
                .NUM        (NUM),
                .DATA_WIDTH (PACK_WIDTH),
                .S_REGS     (S_REGS)
            )
        i_data_split
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
