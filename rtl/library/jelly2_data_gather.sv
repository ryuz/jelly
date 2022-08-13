// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_data_gather
        #(
            parameter   int     PORT_NUM       = 4,
            parameter   int     DATA_WIDTH     = 32,
            parameter   int     LINE_SIZE      = 640,
            parameter   int     UNIT_SIZE      = (LINE_SIZE + (PORT_NUM-1)) / PORT_NUM,
            parameter   int     FIFO_PTR_WIDTH = 6,
            parameter           FIFO_RAM_TYPE  = "distributed",
            parameter   bit     S_REGS         = 1,
            parameter   bit     M_REGS         = 1,
            parameter   bit     INTERNAL_REGS  = (PORT_NUM > 32)
        )
        (
            input   wire                                    reset,
            input   wire                                    clk,
            
            input   wire    [PORT_NUM-1:0][DATA_WIDTH-1:0]  s_data,
            input   wire    [PORT_NUM-1:0]                  s_valid,
            output  wire    [PORT_NUM-1:0]                  s_ready,
            
            output  wire    [DATA_WIDTH-1:0]                m_data,
            output  wire                                    m_valid,
            input   wire                                    m_ready
            
        );
    
    localparam  SEL_WIDTH        = $clog2(PORT_NUM)  > 0 ? $clog2(PORT_NUM)  : 1;
    localparam  UNIT_COUNT_WIDTH = $clog2(UNIT_SIZE) > 0 ? $clog2(UNIT_SIZE) : 1;
    localparam  LINE_COUNT_WIDTH = $clog2(LINE_SIZE) > 0 ? $clog2(LINE_SIZE) : 1;
    
    
    genvar      i;
    
    generate
    if ( PORT_NUM < 2 ) begin : blk_bypass
        assign m_data  = s_data;
        assign m_valid = s_valid;
        assign s_ready = m_ready;
    end
    else begin : blk_gather
        // FIFO
        wire    [PORT_NUM-1:0][DATA_WIDTH-1:0]  fifo_data;
        wire    [PORT_NUM-1:0]                  fifo_valid;
        wire    [PORT_NUM-1:0]                  fifo_ready;
        
        for ( i = 0; i < PORT_NUM; i = i+1 ) begin : loop_fifo
            wire    [DATA_WIDTH-1:0]    s_ff_data;
            wire                        s_ff_valid;
            wire                        s_ff_ready;
            
            jelly_pipeline_insert_ff
                    #(
                        .DATA_WIDTH     (DATA_WIDTH),
                        .SLAVE_REGS     (S_REGS),
                        .MASTER_REGS    (S_REGS)
                    )
                i_pipeline_insert_ff
                    (
                        .reset          (reset),
                        .clk            (clk),
                        .cke            (1'b1),
                        
                        .s_data         (s_data[i]),
                        .s_valid        (s_valid[i]),
                        .s_ready        (s_ready[i]),
                        
                        .m_data         (s_ff_data),
                        .m_valid        (s_ff_valid),
                        .m_ready        (s_ff_ready),
                        
                        .buffered       (),
                        .s_ready_next   ()
                    );
            
            jelly2_fifo_fwtf
                    #(
                        .DATA_WIDTH     (DATA_WIDTH),
                        .PTR_WIDTH      (FIFO_PTR_WIDTH),
                        .DOUT_REGS      (0),
                        .RAM_TYPE       (FIFO_RAM_TYPE),
                        .M_REGS         (INTERNAL_REGS)
                    )
                i_fifo_fwtf
                    (
                        .reset          (reset),
                        .clk            (clk),
                        .cke            (1'b1),
                        
                        .s_data         (s_ff_data),
                        .s_valid        (s_ff_valid),
                        .s_ready        (s_ff_ready),
                        .s_free_count   (),
                        
                        .m_data         (fifo_data[i]),
                        .m_valid        (fifo_valid[i]),
                        .m_ready        (fifo_ready[i]),
                        .m_data_count   ()
                    );
        end
        
        
        // selector
        reg     [SEL_WIDTH-1:0]         reg_sel;
        reg     [UNIT_COUNT_WIDTH-1:0]  reg_unit_count;
        reg     [LINE_COUNT_WIDTH-1:0]  reg_line_count;
        
        wire    [DATA_WIDTH-1:0]        m_ff_data;
        wire                            m_ff_valid;
        wire                            m_ff_ready;
        
        assign m_ff_data  = fifo_data[reg_sel];
        assign m_ff_valid = fifo_valid[reg_sel];
        assign fifo_ready = ({{(PORT_NUM-1){1'b0}}, m_ff_ready} << reg_sel);
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_sel        <= {SEL_WIDTH{1'b0}};
                reg_unit_count <= {UNIT_COUNT_WIDTH{1'b0}};
                reg_line_count <= {LINE_COUNT_WIDTH{1'b0}};
            end
            else begin
                if ( m_ff_valid && m_ff_ready ) begin
                    reg_unit_count <= reg_unit_count + 1'b1;
                    reg_line_count <= reg_line_count + 1'b1;
                    
                    if ( reg_unit_count == UNIT_COUNT_WIDTH'(UNIT_SIZE-1) ) begin
                        reg_sel        <= reg_sel + 1'b1;
                        reg_unit_count <= {UNIT_COUNT_WIDTH{1'b0}};
                    end
                    
                    if ( reg_line_count == LINE_COUNT_WIDTH'(LINE_SIZE-1) ) begin
                        reg_sel        <= {SEL_WIDTH{1'b0}};
                        reg_unit_count <= {UNIT_COUNT_WIDTH{1'b0}};
                        reg_line_count <= {LINE_COUNT_WIDTH{1'b0}};
                    end
                end
            end
        end
        
        // insert FF
        jelly_pipeline_insert_ff
                #(
                    .DATA_WIDTH     (DATA_WIDTH),
                    .SLAVE_REGS     (M_REGS),
                    .MASTER_REGS    (M_REGS)
                )
            i_pipeline_insert_ff
                (
                    .reset          (reset),
                    .clk            (clk),
                    .cke            (1'b1),
                    
                    .s_data         (m_ff_data),
                    .s_valid        (m_ff_valid),
                    .s_ready        (m_ff_ready),
                    
                    .m_data         (m_data),
                    .m_valid        (m_valid),
                    .m_ready        (m_ready),
                    
                    .buffered       (),
                    .s_ready_next   ()
                );
        
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
