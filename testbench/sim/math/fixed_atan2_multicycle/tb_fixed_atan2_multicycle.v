
`timescale 1ns / 1ps
`default_nettype none


module tb_fixed_atan2_multicycle();
    localparam RATE    = 1000.0/200.0;
    
    initial begin
        $dumpfile("tb_fixed_atan2_multicycle.vcd");
        $dumpvars(0, tb_fixed_atan2_multicycle);
        
        #100000;
            $finish;
    end
    
    reg     clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    
    reg     reset = 1'b1;
    initial #(RATE*100.5)   reset = 1'b0;
    
    parameter   DATA_WIDTH = 32;
    
    wire                        cke = 1'b1;
    
    parameter   SCALED_RADIAN = 1;
    parameter   X_WIDTH       = 32;
    parameter   Y_WIDTH       = 32;
    parameter   ANGLE_WIDTH   = 32;
    parameter   Q_WIDTH       = SCALED_RADIAN ? ANGLE_WIDTH : ANGLE_WIDTH - 2;
    
    
    reg     signed  [X_WIDTH-1:0]       s_x = -100;
    reg     signed  [Y_WIDTH-1:0]       s_y = -10;
    reg                                 s_valid = 1;
    wire                                s_ready;
    
    wire    signed  [ANGLE_WIDTH-1:0]   m_angle;
    wire                                m_valid;
    wire                                m_ready = 1'b1;
    
    integer x, y;
    always @(posedge clk) begin
        if ( s_valid & s_ready ) begin
            x = $random();
            y = $random();
            $display("%d %d", x, y);
            s_x <= x;
            s_y <= y;
        end
        
        if ( m_valid & m_ready ) begin
            $display("%d", (m_angle * 64'sd360) >>> 32 );
        end
    end
    
    jelly_fixed_atan2_multicycle
            #(
                .X_WIDTH        (X_WIDTH),
                .Y_WIDTH        (Y_WIDTH),
                .ANGLE_WIDTH    (ANGLE_WIDTH)
            )
        i_fixed_atan2_multicycle
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_x            (s_x),
                .s_y            (s_y),
                .s_valid        (s_valid),
                .s_ready        (s_ready),
                
                .m_angle        (m_angle),
                .m_valid        (m_valid),
                .m_ready        (m_ready)
            );
    
    
endmodule


`default_nettype wire


// end of file
