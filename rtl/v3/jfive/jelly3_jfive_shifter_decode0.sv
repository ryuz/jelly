// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_shifter_decode0
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
            input   var logic               s_alithmatic    ,
            input   var logic               s_left          ,
            input   var logic   [1:0]       s_select        ,
            input   var shamt_t             s_shamt0        ,
            input   var shamt_t             s_shamt1        ,
            input   var shamt_t             s_shamt2        ,

            // output
            output  var shamt_t             m_shamt         ,
            output  var rval_t              m_mask          
        );


    // CARRY chain
    logic            carry_cin;
    shamt_t          carry_sin;
    shamt_t          carry_din;
    shamt_t          carry_dout;
    shamt_t          carry_cout;

    jelly3_carry_chain
            #(
                .DATA_BITS      (SHAMT_BITS         ),
                .data_t         (shamt_t            ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_carry_chain
            (
                .cin            (carry_cin          ),
                .sin            (carry_sin          ),
                .din            (carry_din          ),
                .dout           (carry_dout         ),
                .cout           (carry_cout         )
            );

    // operation
    shamt_t     p;
    always_comb begin
        case ( {s_left, s_select} )
        3'b000: carry_sin = s_shamt0;
        3'b001: carry_sin = s_shamt1;
        3'b010: carry_sin = s_shamt2;
        3'b100: carry_sin = ~s_shamt0;
        3'b101: carry_sin = ~s_shamt1;  
        3'b110: carry_sin = ~s_shamt2;  
        default: carry_sin = 'x;
        endcase
    end

    assign carry_din = '0;
    assign carry_cin = s_left;
    assign m_shamt = carry_dout;

    always_comb begin
        m_mask = '0;
        if ( s_left ) begin
            for ( int i = 0; i < XLEN; i++ ) begin
                m_mask[i] = int'(m_shamt) > i;
            end
        end
        else begin
            for ( int i = 0; i < XLEN; i++ ) begin
                m_mask[i] = int'(m_shamt) > (XLEN - 1 - i);
            end
        end
    end
    




endmodule


`default_nettype wire


// End of file
