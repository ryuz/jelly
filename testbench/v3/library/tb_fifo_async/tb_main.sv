
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset0  ,
            input   var logic   clk0    ,
            input   var logic   reset1  ,
            input   var logic   clk1    
        );
    

    parameter   int     PTR_BITS   = 5                      ;
    localparam  int     FIFO_SIZE  = 2 ** PTR_BITS          ;
    parameter   int     SIZE_BITS  = $clog2(FIFO_SIZE + 1)  ;
    parameter   type    size_t     = logic [SIZE_BITS-1:0]  ;
    parameter   int     DATA_BITS  = 8                      ;
    parameter   type    data_t     = logic [DATA_BITS-1:0]  ;
    parameter   int     WR_SYNC_FF = 2                      ;
    parameter   int     RD_SYNC_FF = 2                      ;
    parameter           RAM_TYPE   = "block"                ;
    parameter   bit     DOUT_REG   = 1'b0                   ;
    parameter           DEVICE     = "RTL"                  ;
    parameter           SIMULATION = "false"                ;
    parameter           DEBUG      = "false"                ;

    logic       wr_reset        ;
    logic       wr_clk          ;
    logic       wr_cke          ;
    logic       wr_en           ;
    data_t      wr_data         ;
    logic       wr_full         ;
    size_t      wr_free_size    ;
    
    logic       rd_reset        ;
    logic       rd_clk          ;
    logic       rd_cke          ;
    logic       rd_en           ;
    logic       rd_regcke       ;
    data_t      rd_data         ;
    logic       rd_empty        ;
    size_t      rd_data_size    ;

    assign wr_reset = reset0    ;
    assign wr_clk   = clk0      ;
    assign wr_cke   = 1'b1      ;

    assign rd_reset = reset1    ;
    assign rd_clk   = clk1      ;
    assign rd_cke   = 1'b1      ;


    jelly3_fifo_async
            #(
                .PTR_BITS       (PTR_BITS       ),
                .SIZE_BITS      (SIZE_BITS      ),
                .size_t         (size_t         ),
                .DATA_BITS      (DATA_BITS      ),
                .data_t         (data_t         ),
                .WR_SYNC_FF     (WR_SYNC_FF     ),
                .RD_SYNC_FF     (RD_SYNC_FF     ),
                .RAM_TYPE       (RAM_TYPE       ),
                .DOUT_REG       (DOUT_REG       ),
                .DEVICE         (DEVICE         ),
                .SIMULATION     (SIMULATION     ),
                .DEBUG          (DEBUG          )
            )
        u_fifo_async
            (
                .wr_reset       ,
                .wr_clk         ,
                .wr_cke         ,
                .wr_en          ,
                .wr_data        ,
                .wr_full        ,
                .wr_free_size   ,

                .rd_reset       ,
                .rd_clk         ,
                .rd_cke         ,
                .rd_en          ,
                .rd_regcke      ,
                .rd_data        ,
                .rd_empty       ,
                .rd_data_size   
        );

    
    // write
    data_t      reg_data;
    logic       reg_valid;
    always_ff @(posedge wr_clk) begin
        if ( wr_reset ) begin
            reg_data  <= 0;
            reg_valid <= 1'b0;
        end
        else if ( wr_cke ) begin
            if ( !(reg_valid && wr_full) ) begin
                reg_valid <= 1'($random);
            end
            
            if ( wr_en ) begin
                reg_data <= reg_data + 1'b1;
            end
        end
    end
    assign wr_en   = reg_valid & !wr_full;
    assign wr_data = reg_data;
    
    
    // read
    integer     fp;
    initial begin
        fp = $fopen("log.txt", "w");
    end
    
    assign rd_en     = !rd_empty;
    assign rd_regcke = 1'b1; 

    /*
    data_t      reg_expectation_value;
    logic       reg_ready;
    always_ff @(posedge rd_clk) begin
        if ( rd_reset ) begin
            reg_expectation_value  <= 0;
            reg_ready              <= 1'b0;
        end
        else begin
            reg_ready <= 1'($random);
            
            if ( m_valid && m_ready ) begin
                $fdisplay(fp, "%h %h", m_data, reg_expectation_value);
                if ( m_data != reg_expectation_value ) begin
                    $display("error! %h %h", m_data, reg_expectation_value);
                end
                
                reg_expectation_value <= reg_expectation_value + 1'b1;
            end
        end
    end
    assign m_ready = reg_ready;
    */

    
endmodule


`default_nettype wire


// end of file
