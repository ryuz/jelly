

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
            input   wire                        aresetn,
            input   wire                        aclk,
            
            output  wire                        ecc_corrected,
            output  wire                        ecc_error,
            output  wire                        ecc_valid,
            output  wire                        crc_error,
            output  wire                        crc_valid,
            output  wire                        packet_lost,
            output  wire                        fifo_overflow,
            
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
    
    logic                       axi4s_aresetn ;
    logic                       axi4s_aclk    ;
    logic   [0:0]               axi4s_tuser   ;
    logic                       axi4s_tlast   ;
    logic   [DATA_WIDTH-1:0]    axi4s_tdata   ;
    logic   [0:0]               axi4s_tvalid  ;
    logic                       axi4s_tready  ;

    assign axi4s_aresetn = m_axi4s_aresetn ;
    assign axi4s_aclk    = m_axi4s_aclk    ;
    assign m_axi4s_tuser   = axi4s_tuser   ;
    assign m_axi4s_tlast   = axi4s_tlast   ;
    assign m_axi4s_tdata   = axi4s_tdata   ;
    assign m_axi4s_tvalid  = axi4s_tvalid  ;
    assign axi4s_tready  = m_axi4s_tready  ;

endmodule


`default_nettype wire


// end of file
