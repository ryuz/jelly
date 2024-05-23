
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );
    
    localparam  bit                     BYPASS_FF   = 1'b0                              ;
    localparam  int                     XLEN        = 32                                ;
    localparam  int                     SHAMT_BITS  = $clog2(XLEN)                      ;
    localparam  type                    shamt_t     = logic [SHAMT_BITS-1:0]            ;
    localparam  type                    rval_t      = logic [XLEN-1:0]                  ;
    localparam  int                     ID_BITS     = 4                                 ;
    localparam  type                    id_t        = logic [ID_BITS-1:0]               ;
    localparam  type                    ridx_t      = logic [5:0]                       ;
//  localparam  type                    imm_i_t     = logic signed [11:0]               ;
    localparam                          DEVICE      = "RTL"                             ;
    localparam                          SIMULATION  = "false"                           ;
    localparam                          DEBUG       = "false"                           ;

    logic               cke             = 1;

            
    logic               s_arithmetic    ;
    logic               s_left          ;
    logic               s_imm_en        ;
    rval_t              s_rs1_val       ;
    shamt_t             s_rs2_val       ;
    shamt_t             s_shamt         ;
    ridx_t              s_rd_idx        ;
    ridx_t              m_rd_idx        ;
    rval_t              m_rd_val        ;
    
    jelly3_jfive_shifter
            #(
                .BYPASS_FF      (BYPASS_FF  ),
                .XLEN           (XLEN       ),
                .SHAMT_BITS     (SHAMT_BITS ),
                .shamt_t        (shamt_t    ),
                .rval_t         (rval_t     ),
                .ID_BITS        (ID_BITS    ),
                .id_t           (id_t       ),
                .ridx_t         (ridx_t     ),
//                .imm_i_t        (imm_i_t    ),
                .DEVICE         (DEVICE     ),
                .SIMULATION     (SIMULATION ),
                .DEBUG          (DEBUG      )
            )
        u_jfive_shifter
            (
                .reset           ,
                .clk             ,
                .cke             ,
                .s_arithmetic    ,
                .s_left          ,
                .s_imm_en        ,
                .s_rs1_val       ,
                .s_rs2_val       ,
                .s_shamt         ,
                .s_rd_idx        ,
                .m_rd_idx        ,
                .m_rd_val        
            );

    always_ff @(posedge clk) begin
        
        s_arithmetic <= 1'($urandom_range(0, 1));
        s_left       <= 1'($urandom_range(0, 1));
        s_imm_en     <= 1'($urandom_range(0, 1));
        s_rs1_val    <= $urandom();
        s_rs2_val    <= 5'($urandom_range(0, 31));
        s_shamt      <= 5'($urandom_range(0, 31));
        s_rd_idx     <= 6'h00;
        /*
        s_arithmetic <= 1'b1;
        s_left       <= 1'b1;
        s_imm_en     <= 1'b0;
        s_rs1_val    <= 32'h12345678;
        s_rs2_val    <= 5'd20;
        s_shamt      <= 5'd20;
        s_rd_idx     <= 6'h00;
        */
    end


    // 期待値
    shamt_t  tmp_shamt;
    rval_t   expected_rd_val0;
    rval_t   expected_rd_val;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            tmp_shamt = s_imm_en ? s_shamt : s_rs2_val;
            case ( {s_arithmetic, s_left} )
            2'b00:  begin expected_rd_val0 <= (s_rs1_val >>  tmp_shamt); end
            2'b01:  begin expected_rd_val0 <= (s_rs1_val <<  tmp_shamt); end
            2'b10:  begin expected_rd_val0 <= ($signed(s_rs1_val) >>> tmp_shamt); end
            2'b11:  begin expected_rd_val0 <= ($signed(s_rs1_val) <<< tmp_shamt); end
            endcase
            
            expected_rd_val  <= expected_rd_val0;
        end
    end

    wire match = m_rd_val == expected_rd_val;

    
endmodule


`default_nettype wire


// end of file
