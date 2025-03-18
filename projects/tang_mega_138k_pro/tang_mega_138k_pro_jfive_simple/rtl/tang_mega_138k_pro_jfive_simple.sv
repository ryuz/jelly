
`timescale 1ns / 1ps
`default_nettype none

module tang_mega_138k_pro_jfive_simple
        #(
            parameter JFIVE_TCM_READMEMH     = 1'b1         ,
            parameter JFIVE_TCM_READMEM_FIlE = "mem.hex"    
        )
        (
            input   var logic           reset    ,
            input   var logic           clk      ,   // 50MHz

            input   var logic           uart_rx  ,
            output  var logic           uart_tx  ,

            output  var logic   [5:0]   led_n
        );

//  assign uart_tx = uart_rx;

    logic   [29:0]  counter;
    always_ff @(posedge clk or posedge reset) begin
        if ( reset ) begin
            counter <= 0;
        end
        else begin
            if ( ~uart_rx ) begin
                counter <= counter + 1;
            end
        end
    end
//  assign led_n[5:0] = counter[29:24];
    assign led_n[5:0] = counter[5:0];


    // -----------------------------
    //  Micro controller (RISC-V)
    // -----------------------------

    // WISHBONE-BUS
    localparam  int  WB_ADR_WIDTH   = 16;
    localparam  int  WB_DAT_WIDTH   = 32;
    localparam  int  WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8);

    logic   [WB_ADR_WIDTH-1:0]      wb_adr_o;
    logic   [WB_DAT_WIDTH-1:0]      wb_dat_i;
    logic   [WB_DAT_WIDTH-1:0]      wb_dat_o;
    logic   [WB_SEL_WIDTH-1:0]      wb_sel_o;
    logic                           wb_we_o;
    logic                           wb_stb_o;
    logic                           wb_ack_i;
    
    jelly2_jfive_simple_controller
            #(
                .S_WB_ADR_WIDTH     (24                     ),
                .S_WB_DAT_WIDTH     (32                     ),
                .S_WB_TCM_ADR       (24'h0001_0000          ),

                .M_WB_DECODE_MASK   (32'hf000_0000          ),
                .M_WB_DECODE_ADDR   (32'h1000_0000          ),
                .M_WB_ADR_WIDTH     (16                     ),

                .TCM_DECODE_MASK    (32'hff00_0000          ),
                .TCM_DECODE_ADDR    (32'h8000_0000          ),
                .TCM_SIZE           (8192                   ),
//              .TCM_RAM_MODE       ("NO_CHANGE"            ),
                .TCM_RAM_MODE       ("WRITE_FIRST"          ),
                .TCM_READMEMH       (JFIVE_TCM_READMEMH     ),
                .TCM_READMEM_FIlE   (JFIVE_TCM_READMEM_FIlE ),

                .PC_WIDTH           (32                     ),
                .INIT_PC_ADDR       (32'h8000_0000          ),
                .INIT_CTL_RESET     (1'b0                   ),

                .SIMULATION         (1'b0                   ),
                .LOG_EXE_ENABLE     (1'b0                   ),
                .LOG_MEM_ENABLE     (1'b0                   )
            )
        u_jfive_simple_controller
            (
                .reset              (reset                  ),
                .clk                (clk                    ),
                .cke                (1'b1                   ),

                .s_wb_adr_i         ('0                     ),
                .s_wb_dat_o         (                       ),
                .s_wb_dat_i         ('0                     ),
                .s_wb_sel_i         ('0                     ),
                .s_wb_we_i          ('0                     ),
                .s_wb_stb_i         ('0                     ),
                .s_wb_ack_o         (                       ),

                .m_wb_adr_o         (wb_adr_o               ),
                .m_wb_dat_i         (wb_dat_i               ),
                .m_wb_dat_o         (wb_dat_o               ),
                .m_wb_sel_o         (wb_sel_o               ),
                .m_wb_we_o          (wb_we_o                ),
                .m_wb_stb_o         (wb_stb_o               ),
                .m_wb_ack_i         (wb_ack_i               )
            );

//    assign wb_ack_i = wb_stb_o;

    // uart
    jelly2_uart
            #(
                .ASYNC              (0              ),
                .TX_FIFO_PTR_WIDTH  (2              ),
                .RX_FIFO_PTR_WIDTH  (2              ),
                .WB_ADR_WIDTH       (2              ),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH   ),

                .DIVIDER_WIDTH      (8              ),
                .DIVIDER_INIT       (54-1           ),
                .SIMULATION         (0              ),
                .DEBUG              (1              )
            )
        u_uart
            (
                .reset              (reset          ),
                .clk                (clk            ),
                
                .uart_reset         (reset          ),
                .uart_clk           (clk            ),
                .uart_tx            (uart_tx        ),
                .uart_rx            (uart_rx        ),
                
                .irq_rx             (               ),
                .irq_tx             (               ),
                
                .s_wb_adr_i         (wb_adr_o[1:0]  ),
                .s_wb_dat_o         (wb_dat_i       ),
                .s_wb_dat_i         (wb_dat_o       ),
                .s_wb_we_i          (wb_we_o        ),
                .s_wb_sel_i         (wb_sel_o       ),
                .s_wb_stb_i         (wb_stb_o       ),
                .s_wb_ack_o         (wb_ack_i       )
            );

    /*
    logic   [7:0]   tx_data   ;
    logic           tx_valid  ;
    logic           tx_ready  ;
    logic   [7:0]   rx_data   ;
    logic           rx_valid  ;
    logic           rx_ready  ;

    jelly2_uart_core
        #(
                .ASYNC              (0          ),
                .TX_FIFO_PTR_WIDTH  (2          ),
                .RX_FIFO_PTR_WIDTH  (2          ),
                .DIVIDER_WIDTH      (8          ),
                .SIMULATION         (0          ),
                .DEBUG              (1          )
            )
        u_uart_core
            (
                .reset              (reset      ),
                .clk                (clk        ),

                .uart_reset         (reset      ),
                .uart_clk           (clk        ),
                .uart_tx            (uart_tx    ),
                .uart_rx            (uart_rx    ),

                .divider            (8'd53      ),  // 115.2kbps @ 50MHz

                .tx_data            (tx_data    ),
                .tx_valid           (tx_valid   ),
                .tx_ready           (tx_ready   ),
                .rx_data            (rx_data    ),
                .rx_valid           (rx_valid   ),
                .rx_ready           (rx_ready   ),
                .tx_fifo_free_count (           ),
                .rx_fifo_data_count (           )
            );
    
    assign tx_data  = rx_data + 1;
    assign tx_valid = rx_valid;
    assign rx_ready = tx_ready;
    */

endmodule


`default_nettype wire
