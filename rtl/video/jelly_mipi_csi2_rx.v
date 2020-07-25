// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_mipi_csi2_rx
        #(
            parameter LANES            = 2,
            parameter DATA_WIDTH       = 10,
            parameter M_FIFO_ASYNC     = 1,
            parameter M_FIFO_PTR_WIDTH = M_FIFO_ASYNC ? 6 : 0,
            parameter M_FIFO_RAM_TYPE  = "distributed"
        )
        (
            input   wire                        aresetn,
            input   wire                        aclk,
            
            output  wire                        overflow,
            
            // input
            input   wire                        rxreseths,
            input   wire                        rxbyteclkhs,
            input   wire    [LANES*8-1:0]       rxdatahs,
            input   wire    [LANES-1:0]         rxvalidhs,
            input   wire    [LANES-1:0]         rxactivehs,
            input   wire    [LANES-1:0]         rxsynchs,
            
            
            // output
            input   wire                        m_axi4s_aresetn,
            input   wire                        m_axi4s_aclk,
            output  wire    [0:0]               m_axi4s_tuser,
            output  wire                        m_axi4s_tlast,
            output  wire    [DATA_WIDTH-1:0]    m_axi4s_tdata,
            output  wire    [0:0]               m_axi4s_tvalid,
            input   wire                        m_axi4s_tready
        );
    
    
    wire    [0:0]               axi4s_lane_tuser;
    wire                        axi4s_lane_tlast;
    wire    [7:0]               axi4s_lane_tdata;
    wire                        axi4s_lane_tvalid;
    wire                        axi4s_lane_tready;
    
    
    jelly_mipi_rx_lane
            #(
                .LANES              (LANES)
            )
        i_mipi_rx_lane
            (
                .rxreseths          (rxreseths),
                .rxbyteclkhs        (rxbyteclkhs),
                .rxdatahs           (rxdatahs),
                .rxvalidhs          (rxvalidhs),
                .rxactivehs         (rxactivehs),
                .rxsynchs           (rxsynchs),
                
                .aresetn            (aresetn),
                .aclk               (aclk),
                .m_axi4s_tuser      (axi4s_lane_tuser),
                .m_axi4s_tlast      (axi4s_lane_tlast),
                .m_axi4s_tdata      (axi4s_lane_tdata),
                .m_axi4s_tvalid     (axi4s_lane_tvalid),
                .m_axi4s_tready     (axi4s_lane_tready)
            );
    
    
    wire                        frame_start;
    wire                        frame_end;
    wire                        crc_error;
    
    wire                        axi4s_low_tlast;
    wire    [7:0]               axi4s_low_tdata;
    wire                        axi4s_low_tvalid;
    wire                        axi4s_low_tready;
    
    jelly_mipi_csi2_rx_low_layer
        i_mipi_csi2_rx_low_layer
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                
                .param_data_type    (8'h2b),
                
                .out_frame_start    (frame_start),
                .out_frame_end      (frame_end),
                .out_crc_error      (crc_error),
                
                .s_axi4s_tuser      (axi4s_lane_tuser),
                .s_axi4s_tlast      (axi4s_lane_tlast),
                .s_axi4s_tdata      (axi4s_lane_tdata),
                .s_axi4s_tvalid     (axi4s_lane_tvalid),
                .s_axi4s_tready     (axi4s_lane_tready),
                
                .m_axi4s_tlast      (axi4s_low_tlast),
                .m_axi4s_tdata      (axi4s_low_tdata),
                .m_axi4s_tvalid     (axi4s_low_tvalid),
                .m_axi4s_tready     (axi4s_low_tready)
            );
    
    reg         reg_low_tuser;
    always @(posedge aclk) begin
        if ( ~aresetn ) begin
            reg_low_tuser <= 1'b1;
        end
        else begin
            if ( frame_start || frame_end ) begin
                reg_low_tuser <= 1'b1;
            end
            
            if ( axi4s_low_tvalid && axi4s_low_tready ) begin
                reg_low_tuser <= 1'b0;
            end
        end
    end
    
    
    // RAW10
    wire    [0:0]               axi4s_out_tuser;
    wire                        axi4s_out_tlast;
    wire    [DATA_WIDTH-1:0]    axi4s_out_tdata;
    wire    [0:0]               axi4s_out_tvalid;
    wire                        axi4s_out_tready;
    
    jelly_mipi_csi2_rx_raw10
            #(
                .S_AXI4S_REGS       (1),
                .M_AXI4S_REGS       (1)
            )
        i_mipi_csi2_rx_raw10
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                
                .s_axi4s_tuser      (reg_low_tuser),
                .s_axi4s_tlast      (axi4s_low_tlast),
                .s_axi4s_tdata      (axi4s_low_tdata),
                .s_axi4s_tvalid     (axi4s_low_tvalid),
                .s_axi4s_tready     (axi4s_low_tready),
                
                .m_axi4s_tuser      (axi4s_out_tuser),
                .m_axi4s_tlast      (axi4s_out_tlast),
                .m_axi4s_tdata      (axi4s_out_tdata),
                .m_axi4s_tvalid     (axi4s_out_tvalid),
                .m_axi4s_tready     (1'b1)
            );
    
    assign  overflow = (axi4s_out_tvalid & !axi4s_out_tready);
    
    
    jelly_fifo_generic_fwtf
            #(
                .ASYNC              (M_FIFO_ASYNC),
                .DATA_WIDTH         (2+DATA_WIDTH),
                .PTR_WIDTH          (M_FIFO_PTR_WIDTH),
                .DOUT_REGS          (0),
                .RAM_TYPE           (M_FIFO_RAM_TYPE),
                .LOW_DEALY          (0),
                .SLAVE_REGS         (0),
                .MASTER_REGS        (1)
            )
        i_fifo_generic_fwtf
            (
                .s_reset            (~aresetn),
                .s_clk              (aclk),
                .s_data             ({axi4s_out_tuser, axi4s_out_tlast, axi4s_out_tdata}),
                .s_valid            (axi4s_out_tvalid),
                .s_ready            (axi4s_out_tready),
                .s_free_count       (),
                
                .m_reset            (~m_axi4s_aresetn),
                .m_clk              (m_axi4s_aclk),
                .m_data             ({m_axi4s_tuser, m_axi4s_tlast, m_axi4s_tdata}),
                .m_valid            (m_axi4s_tvalid),
                .m_ready            (m_axi4s_tready),
                .m_data_count       ()
            );
    
    
    
    // debug
    jelly_axi4s_debug_monitor
            #(
                .TUSER_WIDTH        (1),
                .TDATA_WIDTH        (8),
                .TIMER_WIDTH        (16),
                .FRAME_WIDTH        (16),
                .PIXEL_WIDTH        (16),
                .X_WIDTH            (16),
                .Y_WIDTH            (8)
            )
        i_axi4s_debug_monitor_lane
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                .aclken             (1'b1),
                
                .axi4s_tuser        (axi4s_lane_tuser),
                .axi4s_tlast        (axi4s_lane_tlast),
                .axi4s_tdata        (axi4s_lane_tdata),
                .axi4s_tvalid       (axi4s_lane_tvalid),
                .axi4s_tready       (axi4s_lane_tready)
            );
    
    jelly_axi4s_debug_monitor
            #(
                .TUSER_WIDTH        (1),
                .TDATA_WIDTH        (8),
                .TIMER_WIDTH        (16),
                .FRAME_WIDTH        (16),
                .PIXEL_WIDTH        (24),
                .X_WIDTH            (16),
                .Y_WIDTH            (16)
            )
        i_axi4s_debug_monitor_low
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                .aclken             (1'b1),
                
                .axi4s_tuser        (reg_low_tuser),
                .axi4s_tlast        (axi4s_low_tlast),
                .axi4s_tdata        (axi4s_low_tdata),
                .axi4s_tvalid       (axi4s_low_tvalid),
                .axi4s_tready       (axi4s_low_tready)
            );
    
    jelly_axi4s_debug_monitor
            #(
                .TUSER_WIDTH        (1),
                .TDATA_WIDTH        (10),
                .TIMER_WIDTH        (16),
                .FRAME_WIDTH        (16),
                .PIXEL_WIDTH        (16),
                .X_WIDTH            (16),
                .Y_WIDTH            (8)
            )
        i_axi4s_debug_monitor_out
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                .aclken             (1'b1),
                
                .axi4s_tuser        (axi4s_out_tuser),
                .axi4s_tlast        (axi4s_out_tlast),
                .axi4s_tdata        (axi4s_out_tdata),
                .axi4s_tvalid       (axi4s_out_tvalid),
                .axi4s_tready       (axi4s_out_tready)
            );
    
    jelly_axi4s_debug_monitor
            #(
                .TUSER_WIDTH        (1),
                .TDATA_WIDTH        (10),
                .TIMER_WIDTH        (16),
                .FRAME_WIDTH        (16),
                .PIXEL_WIDTH        (16),
                .X_WIDTH            (16),
                .Y_WIDTH            (8)
            )
        i_axi4s_debug_monitor_m
            (
                .aresetn            (m_axi4s_aresetn),
                .aclk               (m_axi4s_aclk),
                .aclken             (1'b1),
                
                .axi4s_tuser        (m_axi4s_tuser),
                .axi4s_tlast        (m_axi4s_tlast),
                .axi4s_tdata        (m_axi4s_tdata),
                .axi4s_tvalid       (m_axi4s_tvalid),
                .axi4s_tready       (m_axi4s_tready)
            );
    
    
    
    
endmodule


`default_nettype wire


// end of file
