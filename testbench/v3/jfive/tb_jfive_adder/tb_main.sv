
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter           DEVICE      = "RTL"             ,
            parameter           SIMULATION  = "false"           ,
            parameter           DEBUG       = "false"           
        )
        (
            input   var logic   reset,
            input   var logic   clk
        );
    


    localparam  int     XLEN        = 32                       ;
    localparam  type    rval_t      = logic signed [XLEN-1:0]  ;


    logic               cke             ;
    logic               s_sub           ;
    logic               s_imm_en        ;
    rval_t              s_imm_val       ;
    rval_t              s_rs1_val       ;
    rval_t              s_rs2_val       ;
    logic               m_msb_c         ;
    logic               m_carry         ;
    logic               m_sign          ;
    rval_t              m_rd_val        ;

    jelly3_jfive_adder
            #(
                .XLEN           (XLEN       ),
                .rval_t         (rval_t     ),
                .DEVICE         (DEVICE     ),
                .SIMULATION     (SIMULATION ),
                .DEBUG          (DEBUG      )
            )
        u_jfive_adder
            (
                .reset          ,
                .clk            ,
                .cke            ,

                .s_sub          ,
                .s_imm_en       ,
                .s_imm_val      ,
                .s_rs1_val      ,
                .s_rs2_val      ,

                .m_msb_c        ,
                .m_carry        ,
                .m_sign         ,
                .m_rd_val       
            );

    int fp;
    initial begin
        cke = 1'b1;
        #1000;
        @(posedge clk); #1;

            s_sub     = 1'b0;
            s_imm_en  = 1'b0;
            s_imm_val = 'x;
            s_rs1_val = 123;
            s_rs2_val = 456;
        @(posedge clk); #1;
            assert (m_rd_val == 123 + 456) else $error("m_rd_val = %d", m_rd_val);
            assert (m_sign   == 1'b0     ) else $error("m_sign   = %d", m_sign );
            assert (m_carry  == 1'b0     ) else $error("m_carry  = %d", m_carry );
            assert (m_msb_c  == 1'b0     ) else $error("m_msb_c  = %d", m_msb_c );

            s_sub     = 1'b1;
            s_imm_en  = 1'b0;
            s_imm_val = 'x;
            s_rs1_val = 10;
            s_rs2_val =  7;
        @(posedge clk); #1;
            assert (m_rd_val ==    3     ) else $error("m_rd_val = %d", m_rd_val);
            assert (m_sign   == 1'b0     ) else $error("m_sign   = %d", m_sign );
            assert (m_carry  == 1'b1     ) else $error("m_carry  = %d", m_carry );
            assert (m_msb_c  == 1'b1     ) else $error("m_msb_c  = %d", m_msb_c );

            s_sub     = 1'b1;
            s_imm_en  = 1'b0;
            s_imm_val = 'x;
            s_rs1_val = 10;
            s_rs2_val = -7;
        @(posedge clk); #1;
            assert (m_rd_val ==   17     ) else $error("m_rd_val = %d", m_rd_val);
            assert (m_sign   == 1'b0     ) else $error("m_sign   = %d", m_sign );
            assert (m_carry  == 1'b0     ) else $error("m_carry  = %d", m_carry );
            assert (m_msb_c  == 1'b0     ) else $error("m_msb_c  = %d", m_msb_c );

            fp = $fopen("calc.csv", "w");
            $fdisplay(fp, "rs1,rs2,rd,sign,carry,msb_c");
            for ( int i = -3; i <= 3 ; i++ ) begin
                for ( int j = -3; j <= 3 ; j++ ) begin
                    s_sub     = 1'b1;
                    s_imm_en  = 1'b0;
                    s_imm_val = 'x;
                    s_rs1_val = i;
                    s_rs2_val = j;
                    @(posedge clk); #1;
                    $fdisplay(fp, "%3d,%3d,%3d,%d,%d,%d", i, j, m_rd_val, m_sign, m_carry, m_msb_c);
                end
            end
            $fclose(fp);

        @(posedge clk); #1;
        @(posedge clk); #1;

        $finish;
    end
    
endmodule


`default_nettype wire


// end of file
