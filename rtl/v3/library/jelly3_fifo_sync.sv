// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// syncronous FIFO
module jelly3_fifo_sync
        #(
            parameter   int     PTR_BITS   = 5                      ,
            localparam  int     FIFO_SIZE  = 2 ** PTR_BITS          ,
            parameter   int     SIZE_BITS  = $clog2(FIFO_SIZE + 1)  ,
            parameter   type    size_t     = logic [SIZE_BITS-1:0]  ,
            parameter   int     DATA_BITS  = 8                      ,
            parameter   type    data_t     = logic [DATA_BITS-1:0]  ,
            parameter           RAM_TYPE   = "block"                ,
            parameter   bit     DOUT_REG   = 1'b0                   ,
            parameter           DEVICE     = "RTL"                  ,
            parameter           SIMULATION = "false"                ,
            parameter           DEBUG      = "false"                
        )
        (
            input   var logic       reset           ,
            input   var logic       clk             ,
            input   var logic       cke             ,

            input   var logic       wr_en           ,
            input   var data_t      wr_data         ,
            output  var logic       wr_full         ,
            output  var size_t      wr_free_size    ,
            
            input   var logic       rd_en           ,
            input   var logic       rd_regcke       ,
            output  var data_t      rd_data         ,
            output  var logic       rd_empty        ,
            output  var size_t      rd_data_size    
        );

    // ---------------------------------
    //  localparam
    // ---------------------------------

    // Full と Empty でポインタが一周するので 1bit 多く定義
    localparam  type    ptr_t     = logic [PTR_BITS:0]      ;

    localparam  int     ADDR_BITS = PTR_BITS                ;
    localparam  type    addr_t    = logic [ADDR_BITS-1:0]   ;
    

    // ---------------------------------
    //  RAM
    // ---------------------------------
    
    logic       ram_wr_en   ;
    addr_t      ram_wr_addr ;
    data_t      ram_wr_data ;
    
    logic       ram_rd_en   ;
    addr_t      ram_rd_addr ;
    data_t      ram_rd_data ;

    jelly3_ram_simple_dualport
            #(
                .ADDR_BITS  ($bits(addr_t)      ),
                .addr_t     (addr_t             ),
                .DATA_BITS  ($bits(data_t)      ),
                .data_t     (data_t             ),
                .MEM_DEPTH  (FIFO_SIZE          ),
                .RAM_TYPE   (RAM_TYPE           ),
                .DOUT_REG   (DOUT_REG           ),
                .DEVICE     (DEVICE             ),
                .SIMULATION (SIMULATION         ),
                .DEBUG      (DEBUG              )

            )
        u_ram_simple_dualport
            (
                .wr_clk      (clk               ),
                .wr_en       (ram_wr_en & cke   ),
                .wr_addr     (ram_wr_addr       ),
                .wr_din      (ram_wr_data       ),

                .rd_clk      (clk               ),
                .rd_en       (ram_rd_en & cke   ),
                .rd_regcke   (rd_regcke & cke   ),
                .rd_addr     (ram_rd_addr       ),
                .rd_dout     (ram_rd_data       )
            );
    
    
    // ---------------------------------
    //  Control
    // ---------------------------------

    // pointer
    ptr_t   wr_ptr              ;
    ptr_t   rd_ptr              ;

    // write side
    ptr_t   next_wr_ptr         ;
    logic   next_wr_full        ;
    size_t  next_wr_free_size   ;
    always_comb begin
        next_wr_ptr       = wr_ptr     ;
        next_wr_full      = wr_full     ;
        next_wr_free_size = wr_free_size;
        if ( ram_wr_en ) begin
            next_wr_ptr = wr_ptr + 1'b1;
        end
        next_wr_full      = (next_wr_ptr[PTR_BITS] != rd_ptr[PTR_BITS]) && (next_wr_ptr[PTR_BITS-1:0] == rd_ptr[PTR_BITS-1:0]);
        next_wr_free_size = ((rd_ptr - next_wr_ptr) + size_t'(FIFO_SIZE));
    end
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            wr_ptr       <= 0   ;
            wr_full      <= 1'b1;   // リセット期間中は書き込みできないのでfullとする
            wr_free_size <= 0   ;
        end
        else if ( cke ) begin
            wr_ptr       <= next_wr_ptr         ;
            wr_full      <= next_wr_full        ;
            wr_free_size <= next_wr_free_size   ;
        end
    end
    
    assign ram_wr_en   = wr_en & ~wr_full       ;
    assign ram_wr_addr = wr_ptr[ADDR_BITS-1:0]  ;
    assign ram_wr_data = wr_data                ;
    
    
    // read side
    ptr_t   next_rd_ptr         ;
    logic   next_rd_empty       ;
    size_t  next_rd_data_size   ;
    always_comb begin
        next_rd_ptr       = rd_ptr      ;
        next_rd_empty     = rd_empty    ;
        next_rd_data_size = rd_data_size;
        if ( ram_rd_en ) begin
            next_rd_ptr = rd_ptr + 1'b1;
        end
        next_rd_empty     = (wr_ptr == next_rd_ptr) ;
        next_rd_data_size = (wr_ptr - next_rd_ptr)  ;
    end
    
    always_ff @ ( posedge clk ) begin
        if ( reset ) begin
            rd_ptr       <= 0   ;
            rd_empty     <= 1'b1;
            rd_data_size <= 0   ;
        end
        else if ( cke ) begin
            rd_ptr       <= next_rd_ptr         ;
            rd_empty     <= next_rd_empty       ;
            rd_data_size <= next_rd_data_size   ;
        end
    end
    
    assign ram_rd_en    = rd_en & ~rd_empty     ;
    assign ram_rd_addr  = rd_ptr[ADDR_BITS-1:0] ;
    assign rd_data      = ram_rd_data           ;
    
endmodule


`default_nettype wire


// end of file
