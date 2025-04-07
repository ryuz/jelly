// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module output_dac
        #(
            parameter   int     DIV_BITS    = 4                             ,
            parameter   int     SHIFT       = 8                             ,
            parameter   int     DX_BITS     = 32                            ,
            parameter   type    dx_t        = logic signed  [DX_BITS-1:0]   ,
            parameter   int     DY_BITS     = 32                            ,
            parameter   type    dy_t        = logic signed  [DY_BITS-1:0]   
        )
        (
            input   var logic   reset       ,
            input   var logic   clk         ,
            input   var logic   cke         ,

            input   var dx_t    s_of_dx     ,
            input   var dy_t    s_of_dy     ,
            input   var logic   s_of_valid  ,
            
            output  var logic   dac_sync_n  ,
            output  var logic   dac_dina    ,
            output  var logic   dac_dinb    ,
            output  var logic   dac_sclk    
        );

    // Clock divider
    logic [DIV_BITS-1:0] clk_div;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_div <= '1;
        end
        else if (cke) begin
            clk_div <= clk_div - 1'b1;
        end
    end
    assign dac_sclk = clk_div[DIV_BITS-1];

    // DAC data
    dx_t    in_of_dx    ;
    dy_t    in_of_dy    ;
    assign in_of_dx = s_of_dx >>> SHIFT;
    assign in_of_dy = s_of_dy >>> SHIFT;

    dx_t    of_dx       ;
    dy_t    of_dy       ;
    logic   of_valid    ;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            of_dx    <= '0;
            of_dy    <= '0;
            of_valid <= 1'b0;
        end
        else if ( cke ) begin
            of_dx    <= in_of_dx;
            if ( in_of_dx < dx_t'(-2047) ) of_dx <= dx_t'(-2047) ;
            if ( in_of_dx > dx_t'(+2047) ) of_dx <= dx_t'(+2047) ;

            of_dy    <= in_of_dy;
            if ( in_of_dy < dy_t'(-2047) ) of_dy <= dy_t'(-2047) ;
            if ( in_of_dy > dy_t'(+2047) ) of_dy <= dy_t'(+2047) ;

            of_valid <= s_of_valid;
        end
    end

    logic   [11:0]  out_data0;
    logic   [11:0]  out_data1;
    assign out_data0 = 12'(of_dx + 2048);
    assign out_data1 = 12'(of_dy + 2048);

    // SPI signals
    logic [16:0] spi_sync_n ;
    logic [16:0] spi_data0  ;
    logic [16:0] spi_data1  ;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            spi_sync_n <= '1;
            spi_data0  <= '0;
            spi_data1  <= '0;
        end
        else if ( cke ) begin
            if ( of_valid ) begin
                spi_sync_n <= 17'h10000;
                spi_data0  <= { 1'b0, 2'b00, 2'b00, out_data0 };
                spi_data1  <= { 1'b0, 2'b00, 2'b00, out_data1 };
            end
            else begin
                if ( clk_div == '0 ) begin
                    spi_sync_n <= { spi_sync_n[15:0], 1'b1 };
                    spi_data0  <= { spi_data0[15:0], 1'b0 };
                    spi_data1  <= { spi_data1[15:0], 1'b0 };
                end
            end
        end
    end
    assign dac_sync_n = spi_sync_n[16];
    assign dac_dina   = spi_data0 [16];
    assign dac_dinb   = spi_data1 [16];

endmodule


`default_nettype wire



// end of file
