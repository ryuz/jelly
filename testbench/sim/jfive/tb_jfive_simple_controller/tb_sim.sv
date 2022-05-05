
`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    localparam RATE = 10.0;
    
    initial begin
        $dumpfile("tb_sim.vcd");
        $dumpvars(0, tb_sim);
        
    #1000000
        $finish();
    end

    reg     reset = 1'b1;
    always #(RATE*100)  reset = 1'b0;

    reg     clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    

    // -----------------------------
    //  main
    // -----------------------------

    tb_main
        i_main
            (
                .reset,
                .clk
            );


    /*
    logic [1:0] a;
    logic [1:0] b;
    logic [1:0] c;

    logic [1:0] d0;
    logic [1:0] d1;
    logic       msb_carry;
    logic       carry;
    logic       overflow;
    logic       zero;
    logic       negative;

    logic       my_eq ;
    logic       my_ne ;
    logic       my_lt ;
    logic       my_ge ;
    logic       my_ltu;
    logic       my_geu;

    logic       exp_eq ;
    logic       exp_ne ;
    logic       exp_lt ;
    logic       exp_ge ;
    logic       exp_ltu;
    logic       exp_geu;

    initial begin
        for (int i = 0; i < 4; ++i ) begin
            for (int j = 0; j < 4; ++j ) begin
                a = i[1:0];
                b = j[1:0];

                d0 = a;
                d1 = ~b;
                {msb_carry, c[0:0]} = {1'b0, d0[0:0]} + {1'b0, d1[0:0]} + 1'b1;
                {carry, c[1]}       = {1'b0, d0[1]} + {1'b0, d1[1]} + msb_carry;

                overflow = (msb_carry != carry);
                zero     = (c == '0);
                negative = c[1];

                my_eq = zero;
                my_ne = !zero; 
                my_lt =  (overflow != negative);
                my_ge  = (overflow == negative);
                my_ltu = !carry;
                my_geu = carry;

                exp_eq  = (  $signed(a)   == $signed(b));
                exp_ne  = (  $signed(a)   != $signed(b));
                exp_lt  = (  $signed(a)    < $signed(b));
                exp_ge  = (  $signed(a)   >= $signed(b));
                exp_ltu = ($unsigned(a)  < $unsigned(b));
                exp_geu = ($unsigned(a) >= $unsigned(b));


                $display("%b-%b=%b  carry=%b overflow=%b zero=%b, negative=%b", i[1:0], j[1:0], c, carry, overflow, zero, negative);
                $display(" eq  = %b  %b", exp_eq , my_eq  );
                $display(" ne  = %b  %b", exp_ne , my_ne  );
                $display(" lt  = %b  %b", exp_lt , my_lt  );
                $display(" ge  = %b  %b", exp_ge , my_ge  );
                $display(" ltu = %b  %b", exp_ltu, my_ltu );
                $display(" geu = %b  %b", exp_geu, my_geu );
            end
        end
        $finish;
    end
    */
    
endmodule


`default_nettype wire


// end of file
