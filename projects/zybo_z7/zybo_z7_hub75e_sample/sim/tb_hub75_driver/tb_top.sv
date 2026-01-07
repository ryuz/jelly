
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
    
    #10000000
        $finish;
    end
    

    // -----------------------------
    //  reset & clock
    // -----------------------------

    localparam RATE = 1000.0/100.00;

    logic       reset = 1;
    initial #(RATE*100) reset = 0;

    logic       clk = 1'b1;
    initial forever #RATE clk = ~clk;

    // -----------------------------
    //  DTU
    // -----------------------------

    parameter   int     CLK_DIV      = 4                        ;
    parameter   int     DISP_BITS    = 16                       ;
    parameter   type    disp_t       = logic [DISP_BITS-1:0]    ;
    parameter   int     N            = 2                        ;
    parameter   int     WIDTH        = 64                       ;
    parameter   int     HEIGHT       = 32                       ;
    parameter   int     SEL_BITS     = $clog2(HEIGHT)           ;
    parameter   type    sel_t        = logic [DATA_BITS-1:0]    ;
    parameter   int     DATA_BITS    = 8                        ;
    parameter   type    data_t       = logic [DATA_BITS-1:0]    ;
    parameter   int     DEPTH        = N * HEIGHT * WIDTH       ;
    parameter   int     ADDR_BITS    = $clog2(DEPTH)            ;
    parameter   type    addr_t       = logic [ADDR_BITS-1:0]    ;
    parameter           RAM_TYPE     = "block"                  ;
    parameter   bit     READMEMB     = 1'b0                     ;
    parameter   bit     READMEMH     = 1'b0                     ;
    parameter           READMEM_FILE = ""                       ;

    logic           enable      = 1     ;
    disp_t          disp        = 16    ;
    logic           hub75_cke   ;
    logic           hub75_oe_n  ;
    logic           hub75_lat   ;
    sel_t           hub75_sel   ;
    logic   [N-1:0] hub75_r     ;
    logic   [N-1:0] hub75_g     ;
    logic   [N-1:0] hub75_b     ;
    logic           mem_clk     = clk;
    logic           mem_we      = 0;
    addr_t          mem_addr    = 0;
    data_t          mem_r       = 0;
    data_t          mem_g       = 0;
    data_t          mem_b       = 0;

    hub75_driver
            #(
                .CLK_DIV        (CLK_DIV        ),
                .DISP_BITS      (DISP_BITS      ),
                .disp_t         (disp_t         ),
                .N              (N              ),
                .WIDTH          (WIDTH          ),
                .HEIGHT         (HEIGHT         ),
                .SEL_BITS       (SEL_BITS       ),
                .sel_t          (sel_t          ),
                .DATA_BITS      (DATA_BITS      ),
                .data_t         (data_t         ),
                .DEPTH          (DEPTH          ),
                .ADDR_BITS      (ADDR_BITS      ),
                .addr_t         (addr_t         ),
                .RAM_TYPE       (RAM_TYPE       ),
                .READMEMB       (READMEMB       ),
                .READMEMH       (READMEMH       ),
                .READMEM_FILE   (READMEM_FILE   )
            )
        u_hub75_driver
            (
                .reset          ,
                .clk            ,
                .enable         ,
                .disp           ,
                .hub75_cke      ,
                .hub75_oe_n     ,
                .hub75_lat      ,
                .hub75_sel      ,
                .hub75_r        ,
                .hub75_g        ,
                .hub75_b        ,
                .mem_clk        ,
                .mem_we         ,
                .mem_addr       ,
                .mem_r          ,
                .mem_g          ,
                .mem_b          
            );

endmodule


`default_nettype wire


// end of file
