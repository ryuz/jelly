

// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_axi4_master
        #(
            parameter   int unsigned    AXI4_ID_WIDTH   = 6,
            parameter   int unsigned    AXI4_ADDR_WIDTH = 64,
            parameter   int unsigned    AXI4_DATA_WIDTH = 64,
            parameter   int unsigned    AXI4_STRB_WIDTH = AXI4_DATA_WIDTH / 8,
            parameter   int unsigned    AXI4_LEN_WIDTH  = 8,
            parameter   int unsigned    AXI4_QOS_WIDTH  = 4
        )
        (
            input   var logic                           aresetn                     ,
            input   var logic                           aclk                        ,
            input   var logic                           aclken                      ,

            input   var logic   [7:0]                   s_axi4_awnode               ,
            input   var logic                           s_axi4_awacken              ,
            input   var logic   [AXI4_ID_WIDTH-1:0]     s_axi4_awid                 ,
            input   var logic   [AXI4_ADDR_WIDTH-1:0]   s_axi4_awaddr               ,
            input   var logic   [AXI4_LEN_WIDTH-1:0]    s_axi4_awlen                ,
            input   var logic   [2:0]                   s_axi4_awsize               ,
            input   var logic   [1:0]                   s_axi4_awburst              ,
            input   var logic   [0:0]                   s_axi4_awlock               ,
            input   var logic   [3:0]                   s_axi4_awcache              ,
            input   var logic   [2:0]                   s_axi4_awprot               ,
            input   var logic   [AXI4_QOS_WIDTH-1:0]    s_axi4_awqos                ,
            input   var logic   [3:0]                   s_axi4_awregion             ,
            input   var logic                           s_axi4_awvalid              ,
            output  var logic                           s_axi4_awready              ,
            input   var logic   [AXI4_DATA_WIDTH-1:0]   s_axi4_wdata                ,
            input   var logic   [AXI4_STRB_WIDTH-1:0]   s_axi4_wstrb                ,
            input   var logic                           s_axi4_wlast                ,
            input   var logic                           s_axi4_wvalid               ,
            output  var logic                           s_axi4_wready               ,
            output  var logic   [AXI4_ID_WIDTH-1:0]     s_axi4_bid                  ,
            output  var logic   [1:0]                   s_axi4_bresp                ,
            output  var logic                           s_axi4_bvalid               ,
            input   var logic                           s_axi4_bready               ,

            output  var logic   [7:0]                   m_msg_tx_dst_node           ,
            output  var logic   [7:0]                   m_msg_tx_data               ,
            output  var logic                           m_msg_tx_valid              ,
            input   var logic                           m_msg_tx_ready              ,

            input   var logic                           s_msg_rx_first              ,
            input   var logic                           s_msg_rx_last               ,
            input   var logic   [7:0]                   s_msg_rx_src_node           ,
            input   var logic   [7:0]                   s_msg_rx_data               ,
            input   var logic                           s_msg_rx_valid              
        );

    // state control
    logic                           tx_busy;
    logic                           tx_enable;
    logic                           addr_enable;
    logic                           data_enable;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            tx_busy     <= 1'b0;
            tx_enable   <= 1'b0;
            addr_enable <= 1'b0;
            data_enable <= 1'b0;
        end
        else if ( aclken ) begin
            if ( s_axi4_awvalid && s_axi4_awready ) begin
                addr_enable <= 1'b1;
            end
            if ( s_axi4_wlast && s_axi4_wvalid && s_axi4_wready ) begin
                data_enable <= 1'b1;
            end

            if ( !tx_busy && addr_enable && data_enable && ~m_msg_tx_ready ) begin
                tx_busy     <= 1'b0;
            end

            if ( tx_busy && ~m_msg_tx_ready ) begin
                addr_enable <= 1'b0;
                data_enable <= 1'b0;
            end
        end
    end

    
    // data
    logic                           w_busy;

    logic   [AXI4_DATA_WIDTH-1:0]   fifo_wdata  ;
    logic   [AXI4_STRB_WIDTH-1:0]   fifo_wstrb  ;
    logic                           fifo_wlast  ;
    logic                           fifo_wvalid ;
    logic                           fifo_wready ;

    jelly2_fifo_fwtf
            #(
                .DATA_WIDTH     (AXI4_STRB_WIDTH + AXI4_DATA_WIDTH  ),
                .PTR_WIDTH      (AXI4_LEN_WIDTH                     ),
                .DOUT_REGS      (0                                  ),
                .RAM_TYPE       ("distributer"                      ),
                .LOW_DEALY      (0                                  ),
                .S_REGS         (0                                  ),
                .M_REGS         (0                                  )
            )
        i_fifo_fwtf
            (
                .reset          (~aresetn                           ),
                .clk            (aclk                               ),
                .cke            (aclken                             ),

                .s_data         ({s_axi4_wstrb, s_axi4_wdata}       ),
                .s_valid        (s_axi4_wvalid & s_axi4_wready      ),
                .s_ready        (),
                .s_free_count   (),
                
                .m_data         (),
                .m_valid        (),
                .m_ready        (),
                .m_data_count   ()
            );


    logic   [15:0][7:0]      tx_msg_cmd;

    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            tx_msg_cmd <= 'x;
        end
        else if ( aclken ) begin
            if ( s_axi4_awvalid && s_axi4_awready ) begin
                tx_msg_cmd[ 0] <= 8'h10;
                tx_msg_cmd[ 1] <= 8'(16'(s_axi4_awid  ) >> (8*0));
                tx_msg_cmd[ 2] <= 8'(16'(s_axi4_awid  ) >> (8*1));
                tx_msg_cmd[ 3] <= 8'(64'(s_axi4_awaddr) >> (8*0));
                tx_msg_cmd[ 4] <= 8'(64'(s_axi4_awaddr) >> (8*1));
                tx_msg_cmd[ 5] <= 8'(64'(s_axi4_awaddr) >> (8*2));
                tx_msg_cmd[ 6] <= 8'(64'(s_axi4_awaddr) >> (8*3));
                tx_msg_cmd[ 7] <= 8'(64'(s_axi4_awaddr) >> (8*4));
                tx_msg_cmd[ 8] <= 8'(64'(s_axi4_awaddr) >> (8*5));
                tx_msg_cmd[ 9] <= 8'(64'(s_axi4_awaddr) >> (8*6));
                tx_msg_cmd[10] <= 8'(64'(s_axi4_awaddr) >> (8*7));
                tx_msg_cmd[11] <= 8'(s_axi4_awlen);
                tx_msg_cmd[12] <= {1'b0, s_axi4_awprot, 1'b0, s_axi4_awlock, s_axi4_awburst};
                tx_msg_cmd[13] <= 8'(s_axi4_awsize);
                tx_msg_cmd[14] <= {s_axi4_awregion, s_axi4_awcache};
                tx_msg_cmd[15] <= 8'(s_axi4_awqos);
            end
        end
    end




endmodule


`default_nettype wire


// end of file

