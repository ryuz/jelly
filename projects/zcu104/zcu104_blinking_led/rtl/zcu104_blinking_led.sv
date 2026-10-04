// ZCU104 sample design


`timescale 1ns / 1ps
`default_nettype none


module zcu104_blinking_led
        #(
            parameter  int COUNT_LIMIT = 125000000
        )
        (
            input   var logic           clk125_p,
            input   var logic           clk125_n,

            output  var logic   [3:0]   led     ,
            input   var logic   [3:0]   push_sw ,
            input   var logic   [3:0]   dip_sw  
        );
    
    logic           reset   ;    // sync reset
    assign  reset   =   push_sw[0];

    logic   clk;
    IBUFDS
        u_ibufds
            (
                .O  (clk        ),
                .I  (clk125_p   ),
                .IB (clk125_n   )
            );


    // PS
    /*
    logic           reset   ;    // sync reset
    design_1
        u_design_1
            (
                .fan_en     (fan_en ),
                .reset      (reset  ),
                .clk        (clk    )
            );
    */

    // counter
    (* MARK_DEBUG = "true" *)   logic   [26:0]     counter;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            counter <= '0;
            led     <= '0;
        end
        else begin
            counter <= counter + 1'b1;
            if ( counter >= 27'(COUNT_LIMIT - 1) ) begin // 1秒をカウントする
                counter <= '0;
                led     <= led + 1'b1;
            end
        end
    end

endmodule

`default_nettype wire

// end of file
