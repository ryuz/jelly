
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );


    parameter   int     DATA_BITS   = 16                    ;
    parameter   type    data_t      = logic [DATA_BITS-1:0] ;
    parameter   data_t  INIT        = 16'hace1              ;

    logic   cke         = 1;

    logic   update      = 1;
    logic   clear       = 0;
    data_t  clear_value = 0;
    data_t  polynomial  = 16'h002d;
    data_t  dout        ;

    jelly3_lfsr
            #(
                .DATA_BITS      (DATA_BITS  ),
                .data_t         (data_t     ),
                .INIT           (INIT       )
            )
       u_lfsr
            (
                .reset       ,
                .clk         ,
                .cke         ,

                .update      ,
                .clear       ,
                .clear_value ,
                .polynomial  ,

                .dout        
            );


    logic   [15:0]  lfsr_reg;
    logic           p;
    assign p = lfsr_reg[5] ^ lfsr_reg[3] ^ lfsr_reg[2] ^ lfsr_reg[0];
    always_ff @ (posedge clk) begin
        if ( reset ) begin
            lfsr_reg <= 16'hace1;
        end
        else begin
            lfsr_reg <= {p, lfsr_reg[15:1]};
        end
    end

    always_ff @ (posedge clk) begin
        if ( !reset ) begin
            assert (dout == lfsr_reg) else $display("error dout=%h, (expected: %h)", dout, lfsr_reg);
        end
    end

    
endmodule


`default_nettype wire


// end of file
