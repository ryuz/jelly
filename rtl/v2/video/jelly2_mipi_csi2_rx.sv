// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2018 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_mipi_csi2_rx
        #(
            parameter LANES            = 2,
            parameter DATA_WIDTH       = 10,
            parameter M_FIFO_ASYNC     = 1,
            parameter M_FIFO_PTR_WIDTH = M_FIFO_ASYNC ? 6 : 0,
            parameter M_FIFO_RAM_TYPE  = "distributed"
        )
        (
            input   var logic                       aresetn,
            input   var logic                       aclk,

            input   var logic   [7:0]               param_data_type,

            output  var logic                       ecc_corrected,
            output  var logic                       ecc_error,
            output  var logic                       ecc_valid,
            output  var logic                       crc_error,
            output  var logic                       crc_valid,
            output  var logic                       packet_lost,
            output  var logic                       fifo_overflow,
            
            // input
            input   var logic                       rxreseths,
            input   var logic                       rxbyteclkhs,
            input   var logic   [LANES*8-1:0]       rxdatahs,
            input   var logic   [LANES-1:0]         rxvalidhs,
            input   var logic   [LANES-1:0]         rxactivehs,
            input   var logic   [LANES-1:0]         rxsynchs,
            
            
            // output
            input   var logic                       m_axi4s_aresetn,
            input   var logic                       m_axi4s_aclk,
            output  var logic   [0:0]               m_axi4s_tuser,
            output  var logic                       m_axi4s_tlast,
            output  var logic   [DATA_WIDTH-1:0]    m_axi4s_tdata,
            output  var logic   [0:0]               m_axi4s_tvalid,
            input   var logic                       m_axi4s_tready
        );
    
    
    // MIPI lane reciver
    logic   [0:0]               axi4s_lane_tuser;
    logic                       axi4s_lane_tlast;
    logic   [7:0]               axi4s_lane_tdata;
    logic                       axi4s_lane_tvalid;
    logic                       axi4s_lane_tready;
    
    jelly2_mipi_rx_lane
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
    
    
    // MIPI low layer parser
    logic                       frame_start;
    logic                       frame_end;
    
    logic                       axi4s_low_tuser;
    logic                       axi4s_low_tlast;
    logic   [7:0]               axi4s_low_tdata;
    logic                       axi4s_low_tvalid;
    logic                       axi4s_low_tready;

    jelly_mipi_csi2_rx_low_layer
        i_mipi_csi2_rx_low_layer
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                
                .param_data_type    (param_data_type), // (8'h2b),
                
                .out_frame_start    (frame_start),
                .out_frame_end      (frame_end),
                
                .out_ecc_corrected  (ecc_corrected),
                .out_ecc_error      (ecc_error),
                .out_ecc_valid      (ecc_valid),
                .out_crc_error      (crc_error),
                .out_crc_valid      (crc_valid),
                .out_packet_lost    (packet_lost),
                
                .s_axi4s_tuser      (axi4s_lane_tuser),
                .s_axi4s_tlast      (axi4s_lane_tlast),
                .s_axi4s_tdata      (axi4s_lane_tdata),
                .s_axi4s_tvalid     (axi4s_lane_tvalid),
                .s_axi4s_tready     (axi4s_lane_tready),
                
                .m_axi4s_tuser      (axi4s_low_tuser),
                .m_axi4s_tlast      (axi4s_low_tlast),
                .m_axi4s_tdata      (axi4s_low_tdata),
                .m_axi4s_tvalid     (axi4s_low_tvalid),
                .m_axi4s_tready     (axi4s_low_tready)
            );

    logic                       axi4s_low_tready_raw8;
    logic                       axi4s_low_tready_raw10;
    always_comb begin
        case ( param_data_type )
        8'h2a:      axi4s_low_tready = axi4s_low_tready_raw8;
        8'h2b:      axi4s_low_tready = axi4s_low_tready_raw10;
        default:    axi4s_low_tready = 1'b1;
        endcase
    end

    // RAW8
    logic   [0:0]               axi4s_raw8_tuser;
    logic                       axi4s_raw8_tlast;
    logic   [DATA_WIDTH-1:0]    axi4s_raw8_tdata;
    logic   [0:0]               axi4s_raw8_tvalid;
    logic                       axi4s_raw8_tready;

    assign axi4s_raw8_tuser  = axi4s_low_tuser;
    assign axi4s_raw8_tlast  = axi4s_low_tlast;
    assign axi4s_raw8_tdata  = DATA_WIDTH'({axi4s_low_tdata, axi4s_low_tdata} >> (16 - DATA_WIDTH));
    assign axi4s_raw8_tvalid = axi4s_low_tvalid;

    assign axi4s_low_tready_raw8 = axi4s_raw8_tready;

    
    // RAW10 decoder
    logic   [0:0]               axi4s_raw10_tuser;
    logic                       axi4s_raw10_tlast;
    logic   [DATA_WIDTH-1:0]    axi4s_raw10_tdata;
    logic   [0:0]               axi4s_raw10_tvalid;
    logic                       axi4s_raw10_tready;
    
    jelly2_mipi_csi2_rx_raw10
            #(
                .S_AXI4S_REGS       (1),
                .M_AXI4S_REGS       (1)
            )
        i_mipi_csi2_rx_raw10
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                
                .s_axi4s_tuser      (axi4s_low_tuser),
                .s_axi4s_tlast      (axi4s_low_tlast),
                .s_axi4s_tdata      (axi4s_low_tdata),
                .s_axi4s_tvalid     (axi4s_low_tvalid),
                .s_axi4s_tready     (axi4s_low_tready_raw10),
                
                .m_axi4s_tuser      (axi4s_raw10_tuser),
                .m_axi4s_tlast      (axi4s_raw10_tlast),
                .m_axi4s_tdata      (axi4s_raw10_tdata),
                .m_axi4s_tvalid     (axi4s_raw10_tvalid),
                .m_axi4s_tready     (axi4s_raw10_tready)
            );
    
    
    // output
    logic   [0:0]               axi4s_out_tuser;
    logic                       axi4s_out_tlast;
    logic   [DATA_WIDTH-1:0]    axi4s_out_tdata;
    logic   [0:0]               axi4s_out_tvalid;
    logic                       axi4s_out_tready;

    // frame start
    reg         reg_out_tuser;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            reg_out_tuser <= 1'b0;
        end
        else begin
            if ( frame_start || frame_end ) begin
                reg_out_tuser <= 1'b1;
            end
            
            if ( axi4s_out_tvalid && axi4s_out_tready ) begin
                reg_out_tuser <= 1'b0;
            end
        end
    end
    
    assign axi4s_out_tuser    = reg_out_tuser;
    assign axi4s_out_tlast    = param_data_type == 8'h2a ? axi4s_raw8_tlast  : axi4s_raw10_tlast;
    assign axi4s_out_tdata    = param_data_type == 8'h2a ? axi4s_raw8_tdata  : axi4s_raw10_tdata;
    assign axi4s_out_tvalid   = param_data_type == 8'h2a ? axi4s_raw8_tvalid : axi4s_raw10_tvalid;
    assign axi4s_raw8_tready  = 1'b1;
    assign axi4s_raw10_tready = 1'b1;
    

    
    // output fifo
    assign  fifo_overflow = (axi4s_out_tvalid & !axi4s_out_tready);
    
    jelly2_fifo_generic_fwtf
            #(
                .ASYNC              (M_FIFO_ASYNC),
                .DATA_WIDTH         (2+DATA_WIDTH),
                .PTR_WIDTH          (M_FIFO_PTR_WIDTH),
                .DOUT_REGS          (0),
                .RAM_TYPE           (M_FIFO_RAM_TYPE),
                .LOW_DEALY          (0),
                .S_REGS             (0),
                .M_REGS             (1)
            )
        i_fifo_generic_fwtf
            (
                .s_reset            (~aresetn),
                .s_clk              (aclk),
                .s_cke              (1'b1),
                .s_data             ({axi4s_out_tuser, axi4s_out_tlast, axi4s_out_tdata}),
                .s_valid            (axi4s_out_tvalid),
                .s_ready            (axi4s_out_tready),
                .s_free_count       (),
                
                .m_reset            (~m_axi4s_aresetn),
                .m_clk              (m_axi4s_aclk),
                .m_cke              (1'b1),
                .m_data             ({m_axi4s_tuser, m_axi4s_tlast, m_axi4s_tdata}),
                .m_valid            (m_axi4s_tvalid),
                .m_ready            (m_axi4s_tready),
                .m_data_count       ()
            );
    
    
endmodule


`default_nettype wire


// end of file
