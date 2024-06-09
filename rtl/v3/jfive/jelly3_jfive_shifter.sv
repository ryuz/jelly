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
            parameter   int     XLEN        = 32                        ,
            parameter   int     SHAMT_BITS  = $clog2(XLEN)              ,
            parameter   type    shamt_t     = logic [SHAMT_BITS-1:0]    ,
            parameter   type    rval_t      = logic [XLEN-1:0]          ,
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

            // output
            output  var rval_t      m_rd_val        ,
            input   var logic       m_acceptable    
        );


    // ------------------------------------
    //   stage 0
    // ------------------------------------

    localparam  int  EXT_SHAMT_BITS = $bits(shamt_t) + 1;
    localparam  type ext_shamt_t = logic [EXT_SHAMT_BITS-1:0];

    localparam  int  EXT_DATA_BITS  = $bits(rval_t) * 3;
    localparam  type ext_data_t  = logic [EXT_DATA_BITS-1:0];

    ext_shamt_t      st0_shamt      ;
    ext_data_t       st0_rs1_val    ;

    always_ff @(posedge clk) begin
        if ( reset ) begin
           st0_shamt   <= 'x;
           st0_rs1_val <= 'x;
        end
        else if ( cke && m_acceptable ) begin
            case ( {s_left, s_imm_en} )
            2'b00: st0_shamt <= ext_shamt_t'($bits(rval_t)) + ext_shamt_t'(s_rs2_val);
            2'b01: st0_shamt <= ext_shamt_t'($bits(rval_t)) + ext_shamt_t'(s_shamt  );
            2'b10: st0_shamt <= ext_shamt_t'($bits(rval_t)) - ext_shamt_t'(s_rs2_val);
            2'b11: st0_shamt <= ext_shamt_t'($bits(rval_t)) - ext_shamt_t'(s_shamt  );
            endcase
            if ( s_arithmetic ) begin
                st0_rs1_val <= { {XLEN{s_rs1_val[XLEN-1]}}, s_rs1_val, {XLEN{1'b0}} };
            end
            else begin
                st0_rs1_val <= { {XLEN{1'b0}}, s_rs1_val, {XLEN{1'b0}} };
            end
        end
    end

    // ------------------------------------
    //  stage 1
    // ------------------------------------

    rval_t      st1_rd_val;
    always_ff @(posedge clk) begin
        if ( cke && m_acceptable ) begin
           st1_rd_val <= rval_t'(st0_rs1_val >> st0_shamt);
        end
    end


    // ------------------------------------
    //  output
    // ------------------------------------
    
    assign m_rd_val = st1_rd_val;

endmodule


`default_nettype wire


// End of file
