// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_shifter
        #(
            localparam  bit                     BYPASS_FF   = 1'b0                              ,
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
            input   var logic               s_imm_en        ,
            input   var rval_t              s_rs1_val       ,
            input   var shamt_t             s_rs2_val       ,
            input   var shamt_t             s_shamt         ,
            input   var ridx_t              s_rd_idx        ,

            output  var ridx_t              m_rd_idx        ,
            output  var rval_t              m_rd_val        
        );


    // ------------------------------------
    //  Stage 0
    // ------------------------------------

    // signal
    shamt_t          sig0_shamt  ;

    // CARRY chain
    logic            carry_cin  ;
    shamt_t          carry_sin  ;
    shamt_t          carry_din  ;
    shamt_t          carry_dout ;
    shamt_t          carry_cout ;

    always_comb begin
    end

    assign carry_din  = '0;
    assign carry_cin  = s_left;
    assign sig0_shamt = carry_dout;


    logic            st0_alithmatic ;
    logic            st0_left       ;
    shamt_t          st0_shamt      ;
    rval_t           st0_rs1_val    ;

    always_ff @(posedge clk) begin
        if ( cke ) begin
            st0_alithmatic <= s_alithmatic;
            st0_left       <= s_left;

            case ( {s_left, s_imm_en} )
            2'b00: st0_shamt <= s_rs2_val;
            2'b01: st0_shamt <= s_shamt;
            2'b10: st0_shamt <= -s_rs2_val;
            2'b11: st0_shamt <= -s_shamt;
            default: st0_shamt = 'x;
            endcase
            
            st0_rs1_val    <= s_rs1_val;
        end
    end


    logic            sig1_alithmatic ;
    logic            sig1_left       ;
    shamt_t          sig1_shamt      ;
    rval_t           sig1_mask       ;
    rval_t           sig1_rs1_val    ;

    always_comb begin
        sig1_mask = '0;
        if ( st0_left ) begin
            for ( int i = 0; i < XLEN; i++ ) begin
                sig1_mask[i] = int'(st0_shamt) > i;
            end
        end
        else begin
            for ( int i = 0; i < XLEN; i++ ) begin
                sig1_mask[i] = int'(st0_shamt) > (XLEN - 1 - i);
            end
        end
    end


    // ------------------------------------
    //  Flip-Flops
    // ------------------------------------
    
    jelly3_flipflops
            #(
                .BYPASS         (1'b0                    ),
                .DATA_BITS      ($bits({m_shamt, m_mask})),
                .RESET_VALUE    ('x                      ),
                .BOOT_INIT      ('x                      ),
                .DEVICE         (DEVICE                  ),
                .SIMULATION     (SIMULATION              ),
                .DEBUG          ("false"                 )
            )
        u_flipflops
            (
                .reset          (1'b0                   ),
                .clk            ,
                .cke            ,
                
                .din            ({out_shamt, out_mask}  ),
                .dout           ({m_shamt, m_mask}      )
            );


endmodule


`default_nettype wire


// End of file
