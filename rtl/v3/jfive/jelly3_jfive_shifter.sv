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
            input   var shamt_t             s_shamt         ,
            input   var rval_t              s_rs1_val       ,
            input   var ridx_t              s_rd_idx        ,
            input   var rval_t              s_valid         ,
            output  var logic               s_wait          ,    

            output  var ridx_t              m_rd_idx        ,
            output  var rval_t              m_rd_val        ,
            output  var logic               m_valid         ,
            input   var logic               m_wait          
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

    assign carry_din  = '0;
    assign carry_cin  = s_left;
    assign sig0_shamt = carry_dout;


    logic            st0_alithmatic ;
    logic            st0_left       ;
    shamt_t          st0_shamt      ;
    rval_t           st0_rs1_val    ;

    always_ff @(posedge clk) begin
        if ( cke && !m_wait ) begin
            st0_alithmatic <= s_alithmatic;
            st0_left       <= s_left;
            st0_shamt      <= sig0_shamt;
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
