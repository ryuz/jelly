// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// shift register
module jelly3_shift_register
        #(
            parameter   int     DEPTH      = 32                     ,
            parameter   int     ADDR_WIDTH = $clog2(DEPTH)          ,
            parameter   type    addr_t     = logic [ADDR_WIDTH-1:0] ,
            parameter   int     DATA_WIDTH = 8                      ,
            parameter   type    data_t     = logic [DATA_WIDTH-1:0] ,
            parameter           DEVICE     = "RTL"                  ,
            parameter           SIMULATION = "false"                ,
            parameter           DEBUG      = "false"        
        )
        (
            input   var logic     clk       ,
            input   var logic     cke       ,
            
            input   var addr_t    addr      ,
            input   var data_t    in_data   ,
            output  var data_t    out_data  
        );
    
    
    if ( DEPTH > 1 && DEPTH <= 32
          && ( string'(DEVICE) == "SPARTAN6"
            || string'(DEVICE) == "VIRTEX6"
            || string'(DEVICE) == "7SERIES"
            || string'(DEVICE) == "ULTRASCALE"
            || string'(DEVICE) == "ULTRASCALE_PLUS"
            || string'(DEVICE) == "ULTRASCALE_PLUS_ES1"
            || string'(DEVICE) == "ULTRASCALE_PLUS_ES2"
            || string'(DEVICE) == "VERSAL_AI_CORE"
            || string'(DEVICE) == "VERSAL_AI_CORE_ES1"
            || string'(DEVICE) == "VERSAL_AI_CORE_ES2"
            || string'(DEVICE) == "VERSAL_PRIME"
            || string'(DEVICE) == "VERSAL_PRIME_ES1"
            || string'(DEVICE) == "VERSAL_PRIME_ES2" ) ) begin : xilinx
        if ( DEPTH <= 16 ) begin : srl16e
            logic   [3:0]   a;
            assign a = 4'(addr);
            for ( genvar i = 0; i < $bits(data_t); i++ ) begin : srl16e
                // XILINX
                SRL16E
                        #(
                            .INIT   (16'h0000       )
                        )
                    u_srl16e
                        (
                            .CE     (cke            ),
                            .CLK    (clk            ),
                            .D      (in_data[i]     ),
                            .Q      (out_data[i]    ),
                            .A0     (a[0]           ),
                            .A1     (a[1]           ),
                            .A2     (a[2]           ),
                            .A3     (a[3]           )
                        );
            end
        end
        else begin
            logic   [4:0]   a;
            assign a = 5'(addr);
            for ( genvar i = 0; i < $bits(data_t); i++ ) begin : srlc32e
                // XILINX
                SRLC32E
                        #(
                            .INIT   (32'h00000000   )
                        )
                    u_srlc32e
                        (
                            .Q      (out_data[i]    ),
                            .Q31    (               ),
                            .A      (a              ),
                            .CE     (cke            ),
                            .CLK    (clk            ),
                            .D      (in_data[i]     )
                        );
            end
        end
    end
    else if ( DEPTH > 1 && DEPTH <= 8
          && ( string'(DEVICE) == "Topaz"
            || string'(DEVICE) == "Titanium" ) ) begin : efinix
        logic   [2:0]   a;
        assign a = 3'(addr);
        for ( genvar i = 0; i < $bits(data_t); i++ ) begin : srl8
            logic   q;
            EFX_SRL8
                    #(
                        .INIT   (8'h00          )
                    )
                u_srl16e
                    (
                        .D      (in_data[i]     ),
                        .CE     (cke            ),
                        .CLK    (clk            ),
                        .A      (~a             ),
                        .Q      (q              ),
                        .Q7     (               )
                    );
            assign out_data[i] = ~q;
        end
    end
    else begin : rtl
        // RTL
        data_t  [DEPTH-1:0] reg_data;
        always_ff @(posedge clk) begin
            if ( cke ) begin
                reg_data <= (DEPTH * $bits(data_t))'({reg_data, in_data});
            end
        end
        
        assign out_data = reg_data[addr];
    end
    
endmodule


// end of file
