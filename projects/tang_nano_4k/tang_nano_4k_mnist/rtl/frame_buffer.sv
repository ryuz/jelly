
`default_nettype none

module frame_buffer
        (
            input   var logic           reset           ,
            input   var logic           clk             ,
            input   var logic           mem_clk         ,
            input   var logic           mem_pll_lock    ,

            input   var logic           vin_clk         ,
            input   var logic           vin_vs_n        ,
            input   var logic           vin_de          ,
            input   var logic   [15:0]  vin_data        ,
            output  var logic           vin_fifo_full   ,

            input   var logic           vout_clk        ,
            input   var logic           vout_vs_n       ,
            input   var logic           vout_de         ,
            output  var logic           vout_den        ,
            output  var logic   [15:0]  vout_data       ,
            output  var logic           vout_fifo_empty ,

            output  var logic   [0:0]   O_hpram_ck      ,
            output  var logic   [0:0]   O_hpram_ck_n    ,
            output  var logic   [0:0]   O_hpram_cs_n    ,
            output  var logic   [0:0]   O_hpram_reset_n ,
            inout   tri logic   [7:0]   IO_hpram_dq     ,
            inout   tri logic   [0:0]   IO_hpram_rwds   
        );


    logic   [31:0]      wr_data         ;
    logic   [31:0]      rd_data         ;
    logic               rd_data_valid   ;
    logic   [21:0]      addr            ;
    logic               cmd             ;
    logic               cmd_en          ;
    logic               init_calib      ;
    logic               dma_clk         ;
    logic   [3:0]       data_mask       ;

    HyperRAM_Memory_Interface_Top
        u_HyperRAM_Memory_Interface_Top
            (
                .clk                (clk                ),
                .memory_clk         (mem_clk            ),
                .pll_lock           (mem_pll_lock       ),
                .rst_n              (~reset             ),
                .O_hpram_ck         (O_hpram_ck         ),
                .O_hpram_ck_n       (O_hpram_ck_n       ),
                .IO_hpram_rwds      (IO_hpram_rwds      ),
                .IO_hpram_dq        (IO_hpram_dq        ),
                .O_hpram_reset_n    (O_hpram_reset_n    ),
                .O_hpram_cs_n       (O_hpram_cs_n       ),
                .wr_data            (wr_data            ),
                .rd_data            (rd_data            ),
                .rd_data_valid      (rd_data_valid      ),
                .addr               (addr               ),
                .cmd                (cmd                ),
                .cmd_en             (cmd_en             ),
                .clk_out            (dma_clk            ),
                .data_mask          (data_mask          ),
                .init_calib         (init_calib         )
            ); 

    Video_Frame_Buffer_Top
        u_Video_Frame_Buffer_Top_inst
            ( 
                .I_rst_n            (init_calib         ),
                .I_dma_clk          (dma_clk            ),
                .I_wr_halt          (1'd0               ),
                .I_rd_halt          (1'd0               ),

                .I_vin0_clk         (vin_clk            ),
                .I_vin0_vs_n        (vin_vs_n           ),
                .I_vin0_de          (vin_de             ),
                .I_vin0_data        (vin_data           ),
                .O_vin0_fifo_full   (vin_fifo_full      ),

                .I_vout0_clk        (vout_clk           ),
                .I_vout0_vs_n       (vout_vs_n          ),
                .I_vout0_de         (vout_de            ),
                .O_vout0_den        (vout_den           ),
                .O_vout0_data       (vout_data          ),
                .O_vout0_fifo_empty (vout_fifo_empty    ),
                
                .O_cmd              (cmd                ),
                .O_cmd_en           (cmd_en             ),
                .O_addr             (addr               ),
                .O_wr_data          (wr_data            ),
                .O_data_mask        (data_mask          ),
                .I_rd_data_valid    (rd_data_valid      ),
                .I_rd_data          (rd_data            ),
                .I_init_calib       (init_calib         )
            ); 

endmodule


`default_nettype wire
