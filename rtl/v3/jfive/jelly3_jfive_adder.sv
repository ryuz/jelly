// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_adder
        #(
            localparam  int                     XLEN        = 32                                ,
            localparam  int                     SHAMT_BITS  = $clog2(XLEN)                      ,
            localparam  type                    shamt_t     = logic [SHAMT_BITS-1:0]            ,
            parameter   type                    rval_t      = logic [XLEN-1:0]                  ,
            parameter   int                     ID_BITS     = 4                                 ,
            parameter   type                    id_t        = logic [ID_BITS-1:0]               ,
            parameter   type                    ridx_t      = logic [5:0]                       ,
            parameter   type                    imm_i_t     = logic signed [11:0]               ,
            parameter                           DEVICE      = "RTL"                             ,
            parameter                           SIMULATION  = "false"                           ,
            parameter                           DEBUG       = "false"                           
        )
        (
            input   var logic               reset           ,
            input   var logic               clk             ,
            input   var logic               cke             ,

            // input
            input   var logic               s_sub_en        ,
            input   var logic               s_imm_en        ,
            input   var rval_t              s_imm_val       ,
            input   var rval_t              s_rs1_val       ,
            input   var rval_t              s_rs2_val       ,

            // output
            output  var logic               m_msb_c         ,
            output  var logic               m_carry         ,
            output  var rval_t              m_rd_val        
        );


    // ------------------------------------
    //  Input
    // ------------------------------------

    // selector (Xilinx LUT6)
    logic   s_cin;
    rval_t  s_din0;
    rval_t  s_din1;
    assign s_cin  = s_sub_en ? 1'b1 : 1'b0;
    assign s_din0 = s_rs1_val;
    always_comb begin
        case ( {s_sub_en, s_imm_en})
        2'b00:      s_din1 =  s_rs2_val;
        2'b01:      s_din1 =  s_imm_val;
        2'b10:      s_din1 = ~s_rs2_val;
        default:    s_din1 = 'x;
        endcase
    end
    
    // carry chain (Xilinx CARRY8)
    logic   s_msbc;
    logic   s_cout;
    rval_t  s_dout;
    if (       string'(DEVICE) == "ULTRASCALE"
            || string'(DEVICE) == "ULTRASCALE_PLUS"
            || string'(DEVICE) == "ULTRASCALE_PLUS_ES1"
            || string'(DEVICE) == "ULTRASCALE_PLUS_ES2" ) begin : xilinx
        // carry chain
        logic   cc_cin;
        rval_t  cc_sin;
        rval_t  cc_din;
        rval_t  cc_dout;
        rval_t  cc_cout;
        jelly3_carry_chain
                #(
                    .DATA_BITS  (DATA_BITS  ),
                    .data_t     (rval_t     ),
                    .DEVICE     (DEVICE     ),
                    .SIMULATION (SIMULATION ),
                    .DEBUG      (DEBUG      )
                )
            u_carry_chain
                (
                    .cin         (cc_cin ),
                    .sin         (cc_sin ),
                    .din         (cc_din ),
                    .dout        (cc_dout),
                    .cout        (cc_cout)
                );
        assign cc_cin = s_cin;
        assign cc_sin = s_din0 ^ s_din1;
        assign cc_din = s_din0;
        assign s_msbc = cc_cout[XLEN-2];
        assign s_cout = cc_cout[XLEN-1];
        assign s_dout = cc_dout;
    end
    else begin : rtl
        // rtl
        assign {s_msbc, s_dout[XLEN-2:0]} = {1'b0, s_din0[XLEN-2:0]} + {1'b0, s_din1[XLEN-2:0]} + rval_t'(s_cin);
        assign {s_cout, s_dout[XLEN-1]}   = s_din0[XLEN-1] + s_din1[XLEN-1] + s_msbc;
    end


    // ------------------------------------
    //  Stage 0
    // ------------------------------------

    logic   st0_carry     ;
    logic   st0_msb_c     ;
    rval_t  st0_rd_val    ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_msb_c  <= 'x;
            st0_carry  <= 'x;
            st0_rd_val <= 'x;
        end
        else if ( cke ) begin
            st0_msb_c  <= s_msbc;
            st0_carry  <= s_cout;
            st0_rd_val <= s_dout;
        end
    end


    // ------------------------------------
    //  Output
    // ------------------------------------

    assign m_msb_c  = st0_msb_c;
    assign m_carry  = st0_carry;
    assign m_rd_val = st0_rd_val;

endmodule


`default_nettype wire


// End of file
