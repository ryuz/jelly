// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// 1レーン分の受信
module jelly_csi2_rx_lane_recv
        #(
            parameter PRE_DELAY      = 0,
            parameter FIFO_PTR_WIDTH = 5,
            parameter FIFO_RAM_TYPE  = "distributed",
            parameter M_AXI4S_REGS   = 0
        )
        (
            // input
            input   wire            rxreseths,
            input   wire            rxbyteclkhs,
            input   wire    [7:0]   rxdatahs,
            input   wire            rxvalidhs,
            input   wire            rxactivehs,
            input   wire            rxsynchs,
            
            // output
            input   wire            aresetn,
            input   wire            aclk,
            output  wire    [0:0]   m_axi4s_tuser,
            output  wire    [7:0]   m_axi4s_tdata,
            output  wire            m_axi4s_tvalid,
            input   wire            m_axi4s_tready,
            
            input   wire            request_sync
        );
    
    wire    in_rx_valid = (rxactivehs & (rxsynchs | rxvalidhs));
    
    
    // pre-delay
    wire    [7:0]       dly_data;
    wire                dly_sync;
    wire                dly_valid;
    wire                dly_ready;
    
    jelly_data_delay
            #(
                .LATENCY        (PRE_DELAY),
                .DATA_WIDTH     (8+1+1),
                .DATA_INIT      (10'bxxxxxxxx_x_0)
            )
        i_data_delay
            (
                .reset          (rxreseths),
                .clk            (rxbyteclkhs),
                .cke            (1'b1),
                
                .in_data        ({rxdatahs, rxsynchs, in_rx_valid}),
                
                .out_data       ({dly_data, dly_sync, dly_valid})
            );
    
    (* MARK_DEBUG = "true" *)   reg     reg_overfloaw;
    always @(posedge rxbyteclkhs) begin
        reg_overfloaw <= (dly_valid && !dly_ready);
    end
    
    
    // FIFO
    wire    [7:0]       fifo_data;
    wire                fifo_sync;
    wire                fifo_valid;
    wire                fifo_ready;
    
    jelly_fifo_generic_fwtf
            #(
                .ASYNC          (1),
                .DATA_WIDTH     (8+1),
                .PTR_WIDTH      (FIFO_PTR_WIDTH),
                .DOUT_REGS      (0),
                .RAM_TYPE       (FIFO_RAM_TYPE),
                .LOW_DEALY      (0),
                .SLAVE_REGS     (0),
                .MASTER_REGS    (1)
            )
        i_fifo_generic_fwtf
            (
                .s_reset        (rxreseths),
                .s_clk          (rxbyteclkhs),
                .s_data         ({dly_data, dly_sync}),
                .s_valid        (dly_valid),
                .s_ready        (dly_ready),
                .s_free_count   (),
                
                .m_reset        (~aresetn),
                .m_clk          (aclk),
                .m_data         ({fifo_data, fifo_sync}),
                .m_valid        (fifo_valid),
                .m_ready        (fifo_ready),
                .m_data_count   ()
            );
    
    
    // receive logic
    reg     reg_busy;
    always @(posedge aclk) begin
        if ( ~aresetn ) begin
            reg_busy <= 1'b0;
        end
        else begin
            if ( fifo_valid && fifo_ready && fifo_sync ) begin
                reg_busy <= 1'b1;
            end
            
            if ( request_sync ) begin
                reg_busy <= 1'b0;
            end
        end
    end
    
    wire            axi4s_tuser  = fifo_sync;
    wire    [7:0]   axi4s_tdata  = fifo_data;
    wire            axi4s_tvalid = fifo_valid & (reg_busy | fifo_sync);
    wire            axi4s_tready;
    
    assign fifo_ready = axi4s_tready | (~reg_busy & ~fifo_sync);
    
    
    // insert FF
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH     (1+8),
                .SLAVE_REGS     (M_AXI4S_REGS),
                .MASTER_REGS    (0)
            )
        i_pipeline_insert_ff
            (
                .reset          (~aresetn),
                .clk            (aclk),
                .cke            (1'b1),
                
                .s_data         ({axi4s_tuser, axi4s_tdata}),
                .s_valid        (axi4s_tvalid),
                .s_ready        (axi4s_tready),
                
                .m_data         ({m_axi4s_tuser, m_axi4s_tdata}),
                .m_valid        (m_axi4s_tvalid),
                .m_ready        (m_axi4s_tready),
                
                .buffered       (),
                .s_ready_next   ()
            );
    
    
    
endmodule


`default_nettype wire


// end of file
