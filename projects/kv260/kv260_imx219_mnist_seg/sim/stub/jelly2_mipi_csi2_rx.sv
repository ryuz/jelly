

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
