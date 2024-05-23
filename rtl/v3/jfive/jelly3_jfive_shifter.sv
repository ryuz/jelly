// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_shifter
        #(
            parameter   bit     BYPASS_FF   = 1'b0                      ,
            parameter   int     XLEN        = 32                        ,
            parameter   int     SHAMT_BITS  = $clog2(XLEN)              ,
            parameter   type    shamt_t     = logic [SHAMT_BITS-1:0]    ,
            parameter   type    rval_t      = logic [XLEN-1:0]          ,
            parameter   int     ID_BITS     = 4                         ,
            parameter   type    id_t        = logic [ID_BITS-1:0]       ,
            parameter   type    ridx_t      = logic [5:0]               ,
            parameter           DEVICE      = "RTL"                     ,
            parameter           SIMULATION  = "false"                   ,
            parameter           DEBUG       = "false"                   
        )
        (
            input   var logic       reset           ,
            input   var logic       clk             ,
            input   var logic       cke             ,

            // input
            input   var logic       s_arithmetic    ,
            input   var logic       s_left          ,
            input   var logic       s_imm_en        ,
            input   var rval_t      s_rs1_val       ,
            input   var shamt_t     s_rs2_val       ,
            input   var shamt_t     s_shamt         ,
            input   var ridx_t      s_rd_idx        ,

            // output
            output  var ridx_t      m_rd_idx        ,
            output  var rval_t      m_rd_val        
        );


    // ------------------------------------
    //  Input
    // ------------------------------------

    localparam  int  EXT_SHAMT_BITS = $bits(shamt_t) + 1;
    localparam  int  SHAMT1_BITS    = 3;
    localparam  int  SHAMT0_BITS    = EXT_SHAMT_BITS - SHAMT1_BITS;
    localparam  type ext_shamt_t = logic [EXT_SHAMT_BITS-1:0];
    localparam  type shamt0_t    = logic [SHAMT0_BITS-1:0];
    localparam  type shamt1_t    = logic [SHAMT1_BITS-1:0];

    localparam  int  EXT_DATA_BITS  = $bits(rval_t) * 3;
    localparam  type ext_data_t  = logic [EXT_DATA_BITS-1:0];

    ext_shamt_t      s_ext_shamt      ;
    ext_data_t       s_ext_data       ;

    always_comb begin
        case ( {s_left, s_imm_en} )
        2'b00: s_ext_shamt = ext_shamt_t'($bits(rval_t)) + s_rs2_val;
        2'b01: s_ext_shamt = ext_shamt_t'($bits(rval_t)) + s_shamt;
        2'b10: s_ext_shamt = ext_shamt_t'($bits(rval_t)) - s_rs2_val;
        2'b11: s_ext_shamt = ext_shamt_t'($bits(rval_t)) - s_shamt;
        endcase
    end

    always_comb begin
        if ( s_arithmetic ) begin
            s_ext_data = { {XLEN{s_rs1_val[XLEN-1]}}, s_rs1_val, {XLEN{1'b0}} };
        end
        else begin
            s_ext_data = { {XLEN{1'b0}}, s_rs1_val, {XLEN{1'b0}} };
        end
    end

    shamt0_t    s_shamt0    ;
    shamt1_t    s_shamt1    ;
    assign {s_shamt1, s_shamt0} = s_ext_shamt;


    // ------------------------------------
    //   stage 0
    // ------------------------------------

    shamt0_t    st0_shamt0  ;
    ext_data_t  st0_rd_val  ;

    always_ff @(posedge clk) begin
        if ( cke ) begin
           st0_shamt0 <= s_shamt0;
           st0_rd_val <= s_ext_data >> {s_shamt1, shamt0_t'(0)};
        end
    end


    // ------------------------------------
    //  stage 1
    // ------------------------------------

    rval_t      st1_rd_val;
    always_ff @(posedge clk) begin
        if ( cke ) begin
           st1_rd_val <= rval_t'(st0_rd_val >> st0_shamt0);
        end
    end

    // ------------------------------------
    //  output
    // ------------------------------------
    
    assign m_rd_val = st1_rd_val;

endmodule


`default_nettype wire


// End of file
