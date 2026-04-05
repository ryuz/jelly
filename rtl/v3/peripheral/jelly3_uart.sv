// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// uart
module jelly3_uart
        #(
            parameter   bit         ASYNC            = 1                        ,
            parameter   int         TX_FIFO_PTR_BITS = 4                        ,
            parameter   int         RX_FIFO_PTR_BITS = 4                        ,
            parameter               RAM_TYPE         = "distributed"            ,
            parameter   int         DIVIDER_BITS     = 8                        ,
            parameter   type        divider_t        = logic [DIVIDER_BITS-1:0] ,
            parameter   divider_t   INIT_DIVIDER     = 54-1                     ,
            parameter               DEVICE           = "RTL"                    ,
            parameter               SIMULATION       = "false"                  ,
            parameter               DEBUG            = "false"                  
        )
        (
            // UART
            input   var logic                       uart_reset  ,
            input   var logic                       uart_clk    ,
            output  var logic                       uart_tx     ,
            input   var logic                       uart_rx     ,

            jelly3_axi4l_if.s                       s_axi4l     ,
            output  var logic                       irq_rx      ,
            output  var logic                       irq_tx      
        );
    
    // FIFO size
    localparam  TX_FIFO_SIZE = (1 << TX_FIFO_PTR_BITS);
    localparam  RX_FIFO_SIZE = (1 << RX_FIFO_PTR_BITS);
    
    // register address
    parameter   type        regadr_t = logic [1:0];

    localparam  regadr_t    REGADR_TX      = 2'b00;
    localparam  regadr_t    REGADR_RX      = 2'b00;
    localparam  regadr_t    REGADR_STATUS  = 2'b01;
    localparam  regadr_t    REGADR_DIVIDER = 2'b10;

    localparam type axi4l_data_t = logic [s_axi4l.DATA_BITS-1:0];



    // -------------------------
    //   Core
    // -------------------------
    
    divider_t                       divider ;
    
    logic   [7:0]                   tx_data ;
    logic                           tx_valid;
    logic                           tx_ready;

    logic   [7:0]                   rx_data ;
    logic                           rx_valid;
    logic                           rx_ready;
    
    logic   [TX_FIFO_PTR_BITS:0]    tx_fifo_free_count;
    logic   [RX_FIFO_PTR_BITS:0]    rx_fifo_data_count;
    


    jelly2_uart_core
            #(
                .ASYNC              (ASYNC                  ),
                .TX_FIFO_PTR_WIDTH  (TX_FIFO_PTR_BITS       ),
                .RX_FIFO_PTR_WIDTH  (RX_FIFO_PTR_BITS       ),
                .RAM_TYPE           (RAM_TYPE               ),
                .DIVIDER_WIDTH      ($bits(divider_t)       ),
                .SIMULATION         (SIMULATION == "true"   ),
                .DEBUG              (DEBUG == "true"        )
            )
        u_uart_core
            (
                .uart_reset         (uart_reset             ),
                .uart_clk           (uart_clk               ),
                .uart_tx            (uart_tx                ),
                .uart_rx            (uart_rx                ),
                .divider            (divider                ),

                .reset              (~s_axi4l.aresetn       ),
                .clk                (s_axi4l.aclk           ),

                .tx_data            (tx_data                ),
                .tx_valid           (tx_valid               ),
                .tx_ready           (tx_ready               ),
                
                .rx_data            (rx_data                ),
                .rx_valid           (rx_valid               ),
                .rx_ready           (rx_ready               ),
                
                .tx_fifo_free_count (tx_fifo_free_count     ),
                .rx_fifo_data_count (rx_fifo_data_count     )
            );
    
    
    // irq
    assign irq_tx = (tx_fifo_free_count >= TX_FIFO_SIZE);
    assign irq_rx = rx_valid;
    
    
    // -------------------------
    //  register
    // -------------------------

    function [s_axi4l.DATA_BITS-1:0] write_mask(
                                        input [s_axi4l.DATA_BITS-1:0] org   ,
                                        input [s_axi4l.DATA_BITS-1:0] data  ,
                                        input [s_axi4l.STRB_BITS-1:0] strb  
                                    );
        for ( int i = 0; i < s_axi4l.DATA_BITS; i++ ) begin
            write_mask[i] = strb[i/8] ? data[i] : org[i];
        end
    endfunction

    regadr_t  regadr_write;
    regadr_t  regadr_read;
    assign regadr_write = regadr_t'(s_axi4l.awaddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));
    assign regadr_read  = regadr_t'(s_axi4l.araddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));

    // TX
    assign tx_valid = s_axi4l.aclken
                        && s_axi4l.awvalid && s_axi4l.awready
                        && s_axi4l.wvalid && s_axi4l.wready
                        && (regadr_write == REGADR_TX)
                        && s_axi4l.wstrb[0];
    assign tx_data  = s_axi4l.wdata[7:0];
    
    // RX
    assign rx_ready = s_axi4l.aclken
                        && s_axi4l.arvalid && s_axi4l.arready
                        && (regadr_read == REGADR_RX);
    

    // write
    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            divider <= INIT_DIVIDER;
        end
        else if ( s_axi4l.aclken ) begin
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_DIVIDER  : divider <= divider_t'(write_mask(axi4l_data_t'(divider), s_axi4l.wdata, s_axi4l.wstrb));
                default: ;
                endcase
            end
        end
    end

    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            s_axi4l.bvalid <= 0;
        end
        else begin
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready ) begin
                s_axi4l.bvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid  ;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid ;
    assign s_axi4l.bresp   = '0;

    // read
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( s_axi4l.arvalid && s_axi4l.arready ) begin
            case ( regadr_read )
            REGADR_RX       : s_axi4l.rdata <= axi4l_data_t'(rx_data                );
            REGADR_STATUS   : s_axi4l.rdata <= axi4l_data_t'({tx_ready, rx_valid}   );
            REGADR_DIVIDER  : s_axi4l.rdata <= axi4l_data_t'(divider                );
            default:          s_axi4l.rdata <= '0;
            endcase
        end
    end

    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            s_axi4l.rvalid <= 1'b0;
        end
        else begin
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                s_axi4l.rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.arready = ~s_axi4l.rvalid || s_axi4l.rready;
    assign s_axi4l.rresp   = '0;
    
    
endmodule

`default_nettype wire

// end of file
