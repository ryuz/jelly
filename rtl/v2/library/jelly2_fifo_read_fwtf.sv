// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// First-Word Fall-Through read
module jelly2_fifo_read_fwtf
        #(
            parameter   int     DATA_WIDTH  = 8,
            parameter   int     PTR_WIDTH   = 8,
            parameter   bit     DOUT_REGS   = 0,
            parameter   bit     M_REGS      = 1,

            localparam  int     COUNT_WIDTH = PTR_WIDTH + 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            output  wire                        rd_en,
            output  wire                        rd_regcke,
            input   wire    [DATA_WIDTH-1:0]    rd_data,
            input   wire                        rd_empty,
            input   wire    [COUNT_WIDTH-1:0]   rd_count,
            
            output  wire    [DATA_WIDTH-1:0]    m_data,
            output  wire                        m_valid,
            input   wire                        m_ready,
            output  wire    [COUNT_WIDTH-1:0]   m_count
        );
    
    localparam  PIPELINE_STAGES = 1 + DOUT_REGS;

    logic   [PIPELINE_STAGES-1:0]   stage_cke;
    logic   [PIPELINE_STAGES-1:0]   stage_valid;
    logic                           buffered;
    
    jelly_pipeline_control
            #(
                .PIPELINE_STAGES    (PIPELINE_STAGES),
                .S_DATA_WIDTH       (1),
                .M_DATA_WIDTH       (DATA_WIDTH),
                .AUTO_VALID         (1),
                .MASTER_IN_REGS     (M_REGS),
                .MASTER_OUT_REGS    (M_REGS)
            )
        i_pipeline_control
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data             (1'b0),
                .s_valid            (!rd_empty),
                .s_ready            (),
                
                .m_data             (m_data),
                .m_valid            (m_valid),
                .m_ready            (m_ready),
                
                .stage_cke          (stage_cke),
                .stage_valid        (stage_valid),
                .next_valid         ({PIPELINE_STAGES{1'bx}}),
                .src_data           (),
                .src_valid          (),
                .sink_data          (rd_data),
                .buffered           (buffered)
            );
    
    assign rd_en   = stage_cke[0];
    
    generate
    if ( DOUT_REGS ) begin : blk_dout_reg
        assign rd_regcke = stage_cke[1];
        assign m_count   = rd_count + COUNT_WIDTH'(m_valid) + COUNT_WIDTH'(buffered) + COUNT_WIDTH'(stage_valid[0]) + COUNT_WIDTH'(stage_valid[1]);
    end
    else begin : bypass_dout_reg
        assign rd_regcke = 1'b0;
        assign m_count   = rd_count + COUNT_WIDTH'(m_valid) + COUNT_WIDTH'(buffered) + COUNT_WIDTH'(stage_valid[0]);
    end
    endgenerate
    
    
endmodule


`default_nettype wire


// end of file
