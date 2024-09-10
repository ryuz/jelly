// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


interface jelly3_mat_if
        #(
            parameter   bit     USE_DE       = 1                        ,
            parameter   bit     USE_USER     = 0                        ,
            parameter   bit     USE_VALID    = 1                        ,
            parameter   int     TAPS         = 1                        ,
            parameter   int     DE_BITS      = TAPS                     ,
            parameter   int     CH_DEPTH     = 1                        ,
            parameter   int     CH_BITS      = 8                        ,
            parameter   int     USER_BITS    = 1                        
        )
        (
            input   var logic   reset   ,
            input   var logic   clk     ,
            input   var logic   cke
        );

    localparam  type    ch_t      = logic [CH_BITS-1:0]     ;
    localparam  type    data_t    = ch_t  [CH_DEPTH-1:0]    ;
    localparam  type    de_t      = logic [DE_BITS-1:0]     ;
    localparam  type    user_t    = logic [USER_BITS-1:0]   ;

    logic               row_first   ;
    logic               row_last    ;
    logic               col_first   ;
    logic               col_last    ;
    de_t                de          ;
    data_t  [TAPS-1:0]  data        ;
    user_t              user        ;
    logic               valid       ;
    
    modport m
        (
            input   reset       ,
            input   clk         ,
            input   cke         ,
    
            output  row_first   ,
            output  row_last    ,
            output  col_first   ,
            output  col_last    ,
            output  de          ,
            output  data        ,
            output  user        ,
            output  valid       
        );

    modport s
        (
            input   reset       ,
            input   clk         ,
            input   cke         ,
    
            input   row_first   ,
            input   row_last    ,
            input   col_first   ,
            input   col_last    ,
            input   de          ,
            input   data        ,
            input   user        ,
            input   valid       
        );


// valid 時に信号が有効であること
property prop_valid_row_first; @(posedge clk) disable iff ( reset || !cke ) valid |-> !$isunknown(row_first); endproperty
property prop_valid_row_last ; @(posedge clk) disable iff ( reset || !cke ) valid |-> !$isunknown(row_last ); endproperty
property prop_valid_col_first; @(posedge clk) disable iff ( reset || !cke ) valid |-> !$isunknown(col_first); endproperty
property prop_valid_col_last ; @(posedge clk) disable iff ( reset || !cke ) valid |-> !$isunknown(col_last ); endproperty
ASSERT_VALID_ROW_FIRST  : assert property(prop_valid_row_first);
ASSERT_VALID_ROW_LAST   : assert property(prop_valid_row_last );
ASSERT_VALID_COL_FIRST  : assert property(prop_valid_col_first);
ASSERT_VALID_COL_LAST   : assert property(prop_valid_col_last );

if ( USE_DE ) begin
    property prop_valid_de; @(posedge clk) disable iff ( reset || !cke ) valid |-> !$isunknown(de ); endproperty
    ASSERT_VALID_DE : assert property(prop_valid_de);
end


endinterface


`default_nettype wire


// end of file
