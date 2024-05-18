// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_flipflops
        #(
            parameter   bit     BYPASS            = 1'b0                    ,
            parameter   bit     ASYNC_RESET       = 1'b0                    ,
            parameter   int     DATA_BITS         = 1                       ,
            parameter   type    data_t            = logic [DATA_BITS-1:0]   ,
            parameter   data_t  RESET_VALUE       = 'x                      ,
            parameter   data_t  BOOT_INIT         = 'x                      ,
            parameter   bit     IS_CLK_INVERTED   = 1'b0                    ,
            parameter   bit     IS_RESET_INVERTED = 1'b0                    ,
            parameter   bit     IS_DIN_INVERTED   = 1'b0                    ,
            parameter           DEVICE            = "RTL"                   ,
            parameter           SIMULATION        = "false"                 ,
            parameter           DEBUG             = "false"                 
        )
        (
            input   var logic   reset       ,
            input   var logic   clk         ,
            input   var logic   cke         ,
            
            input   var data_t  din         ,
            output  var data_t  dout        
        );
    
    if ( BYPASS ) begin : bypass
        assign dout = din;
    end
    else begin : flipflops
        // Xilinx
        if ( string'(DEVICE) == "SPARTAN6"
                || string'(DEVICE) == "VIRTEX6"
                || string'(DEVICE) == "7SERIES"
                || string'(DEVICE) == "ULTRASCALE"
                || string'(DEVICE) == "ULTRASCALE_PLUS"
                || string'(DEVICE) == "ULTRASCALE_PLUS_ES1"
                || string'(DEVICE) == "ULTRASCALE_PLUS_ES2") begin : xilinx

            for ( genvar i = 0; i < DATA_BITS; i++ ) begin : loop
                if ( ASYNC_RESET ) begin : async_reset
                    if ( RESET_VALUE[i] == 1'b1 ) begin : fdpe
                        FDPE
                                #(
                                    .INIT               (BOOT_INIT[i]       ),
                                    .IS_C_INVERTED      (IS_CLK_INVERTED    ),
                                    .IS_D_INVERTED      (IS_DIN_INVERTED    ),
                                    .IS_PRE_INVERTED    (IS_RESET_INVERTED  )
                                )
                            u_FDPE
                                (
                                    .Q                  (dout[i]            ), 
                                    .C                  (clk                ), 
                                    .CE                 (cke                ),
                                    .D                  (din[i]             ), 
                                    .PRE                (reset              )
                                );
                    end
                    else begin : fdce
                        FDCE
                                #(
                                    .IS_CLR_INVERTED    (IS_RESET_INVERTED  ),
                                    .IS_C_INVERTED      (IS_CLK_INVERTED    ),
                                    .IS_D_INVERTED      (IS_DIN_INVERTED    )
                                )
                            u_FDRE
                                (
                                    .Q                  (dout[i]            ), 
                                    .C                  (clk                ), 
                                    .CE                 (cke                ),
                                    .D                  (din[i]             ), 
                                    .CLR                (reset              )
                                );
                    end
                end
                else begin : sync_reset
                    if ( RESET_VALUE[i] == 1'b1 ) begin : fdse
                        FDSE
                                #(
                                    .INIT               (BOOT_INIT[i]       ),
                                    .IS_C_INVERTED      (IS_CLK_INVERTED    ),
                                    .IS_D_INVERTED      (IS_DIN_INVERTED    ),
                                    .IS_S_INVERTED      (IS_RESET_INVERTED  )
                                )
                            u_FDPE
                                (
                                    .Q                  (dout[i]            ), 
                                    .C                  (clk                ), 
                                    .CE                 (cke                ),
                                    .D                  (din[i]             ), 
                                    .S                  (reset              )
                                );
                    end
                    else begin : fdre
                        FDRE
                                #(
                                    .IS_C_INVERTED      (IS_CLK_INVERTED    ),
                                    .IS_D_INVERTED      (IS_DIN_INVERTED    ),
                                    .IS_R_INVERTED      (IS_RESET_INVERTED  )
                                )
                            u_FDRE
                                (
                                    .Q                  (dout[i]            ), 
                                    .C                  (clk                ), 
                                    .CE                 (cke                ),
                                    .D                  (din[i]             ), 
                                    .R                  (reset              )
                                );
                    end
                end
            end
        end
        else begin : rtl
            // RTL
            logic   rtl_reset   ;
            logic   rtl_clk     ;
            data_t  rtl_din     ;
            assign rtl_reset = IS_RESET_INVERTED ? ~reset : reset;
            assign rtl_clk   = IS_CLK_INVERTED   ? ~clk   : clk  ;
            assign rtl_din   = IS_DIN_INVERTED   ? ~din   : din  ;

            data_t  rtl_dout = BOOT_INIT;

            if ( ASYNC_RESET ) begin : async_reset
                always_ff @( posedge rtl_clk or posedge rtl_reset ) begin
                    if ( rtl_reset ) begin
                        rtl_dout <= RESET_VALUE;
                    end
                    else if ( cke ) begin
                        rtl_dout <= rtl_din;
                    end
                end
            end
            else begin : sync_reset
                always_ff @( posedge rtl_clk ) begin
                    if ( rtl_reset ) begin
                        rtl_dout <= RESET_VALUE;
                    end
                    else if ( cke ) begin
                        rtl_dout <= rtl_din;
                    end
                end
            end
            assign dout = rtl_dout;
        end

        // debug
        if ( string'(DEBUG) == "true" ) begin : debug
            (* MARK_DEBUG = "true" *)   data_t   dbg_dout;
            assign dbg_dout = dout;
        end
    end

endmodule


`default_nettype wire


// end of file
