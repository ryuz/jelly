
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
        #100000;
            $finish;
    end
    
    localparam S_RATE = 1000.0/133.0;
    localparam M_RATE = 1000.0/210.0;

    logic   s_clk = 1'b1;
    initial forever #(S_RATE/2.0) s_clk = ~s_clk;

    logic   s_reset = 1'b1;
    initial #(S_RATE*100) s_reset = 1'b0;

    logic   m_clk = 1'b1;
    initial forever #(M_RATE/2.0) m_clk = ~m_clk;

    logic   m_reset = 1'b1;
    initial #(M_RATE*100) m_reset = 1'b0;


    tb_main
        u_tb_main
            (
                .s_reset    (s_reset    ),
                .s_clk      (s_clk      ),
                .m_reset    (m_reset    ),
                .m_clk      (m_clk      )
            );
    
endmodule


`default_nettype wire


// end of file
