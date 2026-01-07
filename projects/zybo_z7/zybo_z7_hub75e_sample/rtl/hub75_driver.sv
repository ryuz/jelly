// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  Ultra96V2 udmabuf test
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

module hub75_driver
            #(
                parameter   int     CLK_DIV      = 4                    ,
                parameter   int     DISP_BITS    = 16                   ,
                parameter   type    disp_t       = logic [DISP_BITS-1:0],
                parameter   int     N            = 2                    ,
                parameter   int     WIDTH        = 64                   ,
                parameter   int     HEIGHT       = 32                   ,
                parameter   int     SEL_BITS     = $clog2(HEIGHT)       ,
                parameter   type    sel_t        = logic [SEL_BITS-1:0] ,
                parameter   int     DATA_BITS    = 8                    ,
                parameter   type    data_t       = logic [DATA_BITS-1:0],
                parameter   int     DEPTH        = N * HEIGHT * WIDTH   ,
                parameter   int     ADDR_BITS    = $clog2(DEPTH)        ,
                parameter   type    addr_t       = logic [ADDR_BITS-1:0],
                parameter           RAM_TYPE     = "block"              ,
                parameter   bit     READMEMB     = 1'b0                 ,
                parameter   bit     READMEMH     = 1'b0                 ,
                parameter           READMEM_FILE = ""                   

            )
            (
                input   var logic           reset               ,
                input   var logic           clk                 ,
                input   var logic           enable              ,
                input   var disp_t          disp                ,
                output  var logic           hub75_cke           ,
                output  var logic           hub75_oe_n          ,
                output  var logic           hub75_lat           ,
                output  var sel_t           hub75_sel           ,
                output  var logic   [N-1:0] hub75_r             ,
                output  var logic   [N-1:0] hub75_g             ,
                output  var logic   [N-1:0] hub75_b             ,

                input   var logic           mem_clk             ,
                input   var logic           mem_we              ,
                input   var addr_t          mem_addr            ,
                input   var data_t          mem_r               ,
                input   var data_t          mem_g               ,
                input   var data_t          mem_b               
            );
    
    localparam  int     MEM_DEPTH     = HEIGHT * WIDTH                  ;
    localparam  int     MEM_ADDR_BITS = $clog2(MEM_DEPTH)               ;
    localparam  type    mem_addr_t    = logic       [MEM_ADDR_BITS-1:0] ;
    localparam  type    mem_we_t      = logic       [N-1:0]             ;
    localparam  type    mem_word_t    = data_t      [2:0]               ;
    localparam  type    mem_data_t    = mem_word_t  [N-1:0]             ;

    mem_we_t        mem_wr_en       ;
    mem_addr_t      mem_wr_addr     ;
    mem_data_t      mem_wr_din      ;
    logic           mem_rd_clk      ;
    mem_addr_t      mem_rd_addr     ;
    mem_data_t      mem_rd_dout     ;

    jelly3_ram_simple_dualport
            #(
                .ADDR_BITS      (MEM_ADDR_BITS      ),
                .addr_t         (mem_addr_t         ),
                .WE_BITS        (N                  ),
                .we_t           (mem_we_t           ),
                .DATA_BITS      ($bits(mem_data_t)  ),
                .data_t         (mem_data_t         ),
                .WORD_BITS      ($bits(mem_word_t)  ),
                .word_t         (mem_word_t         ),
                .MEM_DEPTH      (MEM_DEPTH          ),
                .RAM_TYPE       (RAM_TYPE           ),
                .DOUT_REG       (1'b1               ),
                .READMEMB       (READMEMB           ),
                .READMEMH       (READMEMH           ),
                .READMEM_FILE   (READMEM_FILE       )
            )
        u_ram_simple_dualport
            (
                .wr_clk         (mem_clk            ),
                .wr_en          (mem_wr_en          ),
                .wr_addr        (mem_wr_addr        ),
                .wr_din         (mem_wr_din         ),
                
                .rd_clk         (mem_rd_clk         ),
                .rd_en          (1'b1               ),
                .rd_regcke      (1'b1               ),
                .rd_addr        (mem_rd_addr        ),
                .rd_dout        (mem_rd_dout        )
            );
    
    assign mem_wr_en   = mem_we ? (1 << (mem_addr >> MEM_ADDR_BITS)) : '0;
    assign mem_wr_addr = mem_addr_t'(mem_addr);
    assign mem_wr_din  = {N{mem_r, mem_g, mem_b}};

    localparam  type    div_t  = logic [$clog2(CLK_DIV)-1:0];
    localparam  type    x_t    = logic [$clog2(WIDTH )-1:0] ;
    localparam  type    y_t    = logic [$clog2(HEIGHT)-1:0] ;
    localparam  int     F_BITS = $clog2($bits(data_t))      ;
    localparam  type    f_t    = logic [F_BITS-1:0]         ;

    // clock div

    div_t   clk_count   ;
    logic   div_clk     ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            clk_count <= '0;
            div_clk   <= 1'b0;
        end
        else begin
            clk_count <= clk_count + 1;
            if ( clk_count == div_t'(CLK_DIV - 1) ) begin
                clk_count <= '0;
                div_clk   <= 1'b0;
            end
        end
    end
    
    typedef enum {
        IDLE,
        SETUP,
        TRANS,
        LAT
    } state_t;


    div_t       st0_div     ;
    state_t     st0_state   ;
    logic       st0_cke     ;
    logic       st0_lat     ;
    logic       st0_oe_n    ;
    x_t         st0_x       ;
    y_t         st0_y       ;
    f_t         st0_f       ;
    f_t         st0_cnt     ;
    disp_t      st0_disp    ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_div   <= '0    ;
            st0_state <= IDLE  ;
            st0_cke   <= 1'b0  ;
            st0_lat   <= 1'b0  ;
            st0_oe_n  <= 1'b1  ;
            st0_x     <= '0    ;
            st0_y     <= '0    ;
            st0_f     <= '1    ;
            st0_cnt   <= '1    ;
            st0_disp  <= '1    ;
        end
        else begin
            // stage 0
            if ( st0_state == TRANS ) begin
                st0_disp <= st0_disp - 1;
                if ( st0_disp == '0 ) begin
                    st0_disp <= disp;
                    st0_cnt  <= st0_cnt - 1;
                    if ( st0_cnt == '0 ) begin
                        st0_oe_n <= 1'b1  ;
                    end
                end
            end

            st0_div <= st0_div + 1;
            if ( st0_div == div_t'(CLK_DIV - 1) ) begin
                st0_div   <= '0     ;
                case ( st0_state )
                IDLE:
                    begin
                        if ( enable ) begin
                            st0_state <= SETUP  ;
                        end
                        st0_cke   <= 1'b0   ;
                        st0_lat   <= 1'b0   ;
                        st0_oe_n  <= 1'b1   ;
                        st0_disp  <= disp   ;
                    end
                
                SETUP:
                    begin
                        st0_state <= TRANS  ;
                        st0_cke   <= 1'b0   ;
                        st0_lat   <= 1'b0   ;
                        st0_oe_n  <= 1'b0   ;
                    end

                TRANS:
                    begin
                        st0_cke <= ~st0_cke;
                        if ( st0_cke ) begin
                            st0_x <= st0_x + 1;
                            if ( st0_x == x_t'(WIDTH-1) ) begin
                                st0_state <= LAT    ;
                                st0_lat   <= 1'b1   ;
                                st0_oe_n  <= 1'b1   ;
                                st0_x     <= '0     ;
                                st0_y     <= st0_y + 1;
                                st0_cnt   <= st0_f  ;
                                if ( st0_y == y_t'(HEIGHT-1) ) begin
                                    st0_y   <= '0;
                                    st0_f   <= st0_f + 1;
                                    if ( st0_f == f_t'($bits(data_t)-1) ) begin
                                        st0_f <= '0;
                                    end
                                end
                            end
                        end
                    end

                LAT:
                    begin
                        st0_state <= IDLE   ;
                        st0_lat   <= 1'b1   ;
                        st0_oe_n  <= 1'b1   ;
                    end
                endcase
            end
        end
    end


endmodule



`default_nettype wire


// end of file
