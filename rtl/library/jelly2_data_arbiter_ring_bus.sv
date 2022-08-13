// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// ring bus unit
module jelly2_data_arbiter_ring_bus
        #(
            parameter   int     S_NUM         = 8,
            parameter   int     S_ID_WIDTH    = 3,
            parameter   int     M_NUM         = 4,
            parameter   int     M_ID_WIDTH    = 2,
            parameter   int     DATA_WIDTH    = 32,
            parameter   bit     NO_RING       = 0
        )
        (
            input   wire                                    reset,
            input   wire                                    clk,
            input   wire                                    cke,

            input   wire    [S_NUM-1:0][M_ID_WIDTH-1:0]     s_id_to,
            input   wire    [S_NUM-1:0][DATA_WIDTH-1:0]     s_data,
            input   wire    [S_NUM-1:0]                     s_valid,
            output  wire    [S_NUM-1:0]                     s_ready,

            output  wire    [M_NUM-1:0][S_ID_WIDTH-1:0]     m_id_from,
            output  wire    [M_NUM-1:0][DATA_WIDTH-1:0]     m_data,
            output  wire    [M_NUM-1:0]                     m_valid,
            input   wire    [M_NUM-1:0]                     m_ready
        );
    
    // verilator lint_off UNOPTFLAT
    logic   [(S_NUM+1)-1:0][M_ID_WIDTH-1:0]     ringbus_s_id_to;
    logic   [(S_NUM+1)-1:0][S_ID_WIDTH-1:0]     ringbus_s_id_from;
    logic   [(S_NUM+1)-1:0][DATA_WIDTH-1:0]     ringbus_s_data;
    logic   [(S_NUM+1)-1:0]                     ringbus_s_valid;
    // verilator lint_on UNOPTFLAT
    
    logic   [(M_NUM+1)-1:0][M_ID_WIDTH-1:0]     ringbus_m_id_to;
    logic   [(M_NUM+1)-1:0][S_ID_WIDTH-1:0]     ringbus_m_id_from;
    logic   [(M_NUM+1)-1:0][DATA_WIDTH-1:0]     ringbus_m_data;
    logic   [(M_NUM+1)-1:0]                     ringbus_m_valid;
    
    generate
    for ( genvar i = 0; i < S_NUM; ++i ) begin : loop_s
        jelly2_ring_bus_unit
                #(
                    .DATA_WIDTH             (DATA_WIDTH),
                    .ID_TO_WIDTH            (M_ID_WIDTH),
                    .ID_FROM_WIDTH          (S_ID_WIDTH),
                    .UNIT_ID_TO             (0),
                    .UNIT_ID_FROM           (i)
                )
            i_ring_bus_unit_s
                (
                    .reset                  (reset),
                    .clk                    (clk),
                    .cke                    (cke),
                    
                    .s_id_to                (s_id_to[i]),
                    .s_data                 (s_data [i]),
                    .s_valid                (s_valid[i]),
                    .s_ready                (s_ready[i]),
                    
                    .m_id_from              (),
                    .m_data                 (),
                    .m_valid                (),
                    .m_ready                (1'b0),
                    
                    .src_id_to              (ringbus_s_id_to  [(i+1)]),
                    .src_id_from            (ringbus_s_id_from[(i+1)]),
                    .src_data               (ringbus_s_data   [(i+1)]),
                    .src_valid              (ringbus_s_valid  [(i+1)]),
                    
                    .sink_id_to             (ringbus_s_id_to  [(i+0)]),
                    .sink_id_from           (ringbus_s_id_from[(i+0)]),
                    .sink_data              (ringbus_s_data   [(i+0)]),
                    .sink_valid             (ringbus_s_valid  [(i+0)])
                );
    end
    
    for ( genvar i = 0; i < M_NUM; ++i ) begin : loop_m
        jelly2_ring_bus_unit
                #(
                    .DATA_WIDTH             (DATA_WIDTH),
                    .ID_TO_WIDTH            (M_ID_WIDTH),
                    .ID_FROM_WIDTH          (S_ID_WIDTH),
                    .UNIT_ID_TO             (i),
                    .UNIT_ID_FROM           (0)
                )
            i_ring_bus_unit_m
                (
                    .reset                  (reset),
                    .clk                    (clk),
                    .cke                    (cke),
                    
                    .s_id_to                ({M_ID_WIDTH{1'b0}}),
                    .s_data                 ({DATA_WIDTH{1'b0}}),
                    .s_valid                (1'b0),
                    .s_ready                (),
                    
                    .m_id_from              (m_id_from[i]),
                    .m_data                 (m_data   [i]),
                    .m_valid                (m_valid  [i]),
                    .m_ready                (m_ready  [i]),
                    
                    .src_id_to              (ringbus_m_id_to  [(i+1)]),
                    .src_id_from            (ringbus_m_id_from[(i+1)]),
                    .src_data               (ringbus_m_data   [(i+1)]),
                    .src_valid              (ringbus_m_valid  [(i+1)]),
                    
                    .sink_id_to             (ringbus_m_id_to  [(i+0)]),
                    .sink_id_from           (ringbus_m_id_from[(i+0)]),
                    .sink_data              (ringbus_m_data   [(i+0)]),
                    .sink_valid             (ringbus_m_valid  [(i+0)])
                );
    end
    endgenerate
    
    
    generate
    if ( NO_RING ) begin : blk_no_ring
        assign ringbus_m_id_to  [M_NUM] = {M_ID_WIDTH{1'bx}};
        assign ringbus_m_id_from[M_NUM] = {S_ID_WIDTH{1'bx}};
        assign ringbus_m_data   [M_NUM] = {DATA_WIDTH{1'bx}};
        assign ringbus_m_valid  [M_NUM] = 1'b0;
        
        assign ringbus_s_id_to  [S_NUM] = {M_ID_WIDTH{1'bx}};
        assign ringbus_s_id_from[S_NUM] = {S_ID_WIDTH{1'bx}};
        assign ringbus_s_data   [S_NUM] = {DATA_WIDTH{1'bx}};
        assign ringbus_s_valid  [S_NUM] = 1'b0;
    end
    else begin : blk_ring
        assign ringbus_m_id_to  [M_NUM] = ringbus_s_id_to  [0];
        assign ringbus_m_id_from[M_NUM] = ringbus_s_id_from[0];
        assign ringbus_m_data   [M_NUM] = ringbus_s_data   [0];
        assign ringbus_m_valid  [M_NUM] = ringbus_s_valid  [0];
        
        assign ringbus_s_id_to  [S_NUM] = ringbus_m_id_to  [0];
        assign ringbus_s_id_from[S_NUM] = ringbus_m_id_from[0];
        assign ringbus_s_data   [S_NUM] = ringbus_m_data   [0];
        assign ringbus_s_valid  [S_NUM] = ringbus_m_valid  [0];
    end
    endgenerate
    

endmodule



`default_nettype wire


// end of file
