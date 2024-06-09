// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// ring bus unit
module jelly2_data_switch
        #(
            parameter   int     NUM           = 16,
            parameter   int     ID_WIDTH      = 2,
            parameter   int     DATA_WIDTH    = 32,
            parameter   bit     S_REGS        = 1,
            parameter   bit     M_REGS        = 1,
            parameter   bit     S_SLAVE_REGS  = S_REGS,
            parameter   bit     S_MASTER_REGS = 0,
            parameter   bit     M_SLAVE_REGS  = 0,
            parameter   bit     M_MASTER_REGS = M_REGS
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,

            input   wire    [ID_WIDTH-1:0]              s_id,
            input   wire    [DATA_WIDTH-1:0]            s_data,
            input   wire                                s_valid,
            output  wire                                s_ready,
            
            output  wire    [NUM-1:0][DATA_WIDTH-1:0]   m_data,
            output  wire    [NUM-1:0]                   m_valid,
            input   wire    [NUM-1:0]                   m_ready
        );
    
    
    // -----------------------------------------
    //  insert FF
    // -----------------------------------------
    
    logic   [ID_WIDTH-1:0]              ff_s_id;
    logic   [DATA_WIDTH-1:0]            ff_s_data;
    logic                               ff_s_valid;
    logic                               ff_s_ready;
    
    logic   [NUM-1:0][DATA_WIDTH-1:0]   ff_m_data;
    logic   [NUM-1:0]                   ff_m_valid;
    logic   [NUM-1:0]                   ff_m_ready;
    
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH     (ID_WIDTH + DATA_WIDTH),
                .SLAVE_REGS     (S_SLAVE_REGS),
                .MASTER_REGS    (S_MASTER_REGS)
            )
        i_pipeline_insert_ff_s
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data         ({s_id, s_data}),
                .s_valid        (s_valid),
                .s_ready        (s_ready),
                
                .m_data         ({ff_s_id, ff_s_data}),
                .m_valid        (ff_s_valid),
                .m_ready        (ff_s_ready),
                
                .buffered       (),
                .s_ready_next   ()
            );
    
    
    generate
    for ( genvar i = 0; i < NUM; ++i ) begin : loop_ff_m
        jelly_pipeline_insert_ff
                #(
                    .DATA_WIDTH     (DATA_WIDTH),
                    .SLAVE_REGS     (M_SLAVE_REGS),
                    .MASTER_REGS    (M_MASTER_REGS)
                )
            i_pipeline_insert_ff_m
                (
                    .reset          (reset),
                    .clk            (clk),
                    .cke            (cke),
                    
                    .s_data         (ff_m_data [i]),
                    .s_valid        (ff_m_valid[i]),
                    .s_ready        (ff_m_ready[i]),
                    
                    .m_data         (m_data [i]),
                    .m_valid        (m_valid[i]),
                    .m_ready        (m_ready[i]),
                    
                    .buffered       (),
                    .s_ready_next   ()
                );
    end
    endgenerate
    
    
    
    // -----------------------------------------
    //  switch
    // -----------------------------------------
    
    reg                             sig_s_ready;
    reg     [NUM-1:0]               sig_m_valid;
        
    always_comb begin
        sig_s_ready = 1'b0;
        sig_m_valid = {NUM{1'b0}};
        
        for ( int j = 0; j < NUM; ++j ) begin
            if ( ff_s_id == ID_WIDTH'(j) ) begin
                sig_s_ready    = ff_m_ready[j];
                sig_m_valid[j] = ff_s_valid;
            end
        end
    end
    
    assign ff_s_ready = sig_s_ready;
    
    assign ff_m_data  = {NUM{ff_s_data}};
    assign ff_m_valid = sig_m_valid;
    
    
endmodule



`default_nettype wire


// end of file
