`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
        #100000;
            $finish;
    end
    
    localparam RATE = 1000.0/200.0;

    logic   clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    
    logic   reset = 1'b1;
    initial #(RATE*100) reset = 1'b0;

    tb_main
        u_tb_main
            (
                .reset  (reset),
                .clk    (clk)  
            );

    tb_auto_first
        u_tb_auto_first
            (
                .clk    (clk)
            );
    
endmodule


module tb_auto_first
        (
            input   var logic   clk
        );

    logic                   test_reset;
    initial begin
        test_reset = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        test_reset = 1'b0;
    end

    logic                   cke = 1'b1;
    logic                   s_last;
    logic   [0:0]           s_strb;
    logic   [0:0]           s_keep;
    logic   [0:0][7:0]      s_data;
    logic                   s_valid;
    logic                   s_ready;
    logic                   m_first;
    logic                   m_last;
    logic   [0:0][7:0]      m_data;
    logic   [0:0]           m_strb;
    logic   [0:0]           m_keep;
    logic                   m_user_f;
    logic                   m_user_l;
    logic                   m_valid;
    logic                   expected_input_first;
    logic   [2:0]           expected_first;
    logic   [2:0]           expected_last;
    logic   [2:0]           expected_strb;
    logic   [2:0]           expected_keep;
    logic   [2:0][7:0]      expected_data;
    int                     input_count;
    int                     output_count;

    jelly3_stream_width_convert
            #(
                .UNIT_BITS  (8          ),
                .S_NUM      (1          ),
                .M_NUM      (1          ),
                .USE_LAST   (1          ),
                .USE_STRB   (1          ),
                .USE_KEEP   (1          ),
                .AUTO_FIRST (1          ),
                .S_REG      (0          ),
                .M_REG      (0          )
            )
        u_stream_width_convert
            (
                .reset      (test_reset ),
                .clk        (clk        ),
                .cke        (cke        ),
                .endian     (1'b0       ),
                .padding    (8'b0       ),
                .s_align_s  ('0         ),
                .s_align_m  ('0         ),
                .s_first    (1'b0       ),
                .s_last     (s_last     ),
                .s_data     (s_data     ),
                .s_strb     (s_strb     ),
                .s_keep     (s_keep     ),
                .s_user_f   (1'b0       ),
                .s_user_l   (1'b0       ),
                .s_valid    (s_valid    ),
                .s_ready    (s_ready    ),
                .m_first    (m_first    ),
                .m_last     (m_last     ),
                .m_data     (m_data     ),
                .m_strb     (m_strb     ),
                .m_keep     (m_keep     ),
                .m_user_f   (m_user_f   ),
                .m_user_l   (m_user_l   ),
                .m_valid    (m_valid    ),
                .m_ready    (1'b1       )
            );

    always_ff @(posedge clk) begin
        if ( test_reset ) begin
            expected_first <= '0;
            expected_last  <= '0;
            expected_strb  <= '0;
            expected_keep  <= '0;
            expected_data  <= '0;
            input_count    <= 0;
        end
        else if ( cke ) begin
            if ( s_valid && s_ready ) begin
                if ( input_count >= 3 ) begin
                    $fatal(1, "auto-first test accepted too many inputs");
                end
                expected_first[input_count] <= expected_input_first;
                expected_last[input_count]  <= s_last;
                expected_strb[input_count]  <= s_strb;
                expected_keep[input_count]  <= s_keep;
                expected_data[input_count]  <= s_strb[0] ? s_data[0] : 8'b0;
                input_count <= input_count + 1;
            end
        end
    end

    always @(negedge clk) begin
        #1;
        if ( test_reset ) begin
            output_count = 0;
        end
        else if ( cke && m_valid ) begin
            if ( output_count >= input_count) begin
                $fatal(1, "auto-first test produced an unexpected output");
            end
            if ( m_first !== expected_first[output_count] ) begin
                $fatal(1, "auto-first mismatch at beat %0d: expected %0b, got %0b",
                        output_count, expected_first[output_count], m_first);
            end
            if ( m_last !== expected_last[output_count] ) begin
                $fatal(1, "last mismatch at beat %0d: expected %0b, got %0b",
                        output_count, expected_last[output_count], m_last);
            end
            if ( m_data[0] !== expected_data[output_count] ) begin
                $fatal(1, "data mismatch at beat %0d: expected %0h, got %0h",
                        output_count, expected_data[output_count], m_data[0]);
            end
            if ( m_strb !== expected_strb[output_count] ) begin
                $fatal(1, "strb mismatch at beat %0d: expected %0b, got %0b",
                        output_count, expected_strb[output_count], m_strb);
            end
            if ( m_keep !== expected_keep[output_count] ) begin
                $fatal(1, "keep mismatch at beat %0d: expected %0b, got %0b",
                        output_count, expected_keep[output_count], m_keep);
            end
            output_count = output_count + 1;
        end
    end

    task automatic send(input logic last, input logic first_expected, input logic strb, input logic keep);
        @(negedge clk);
        s_last               = last;
        expected_input_first = first_expected;
        s_strb               = strb;
        s_keep               = keep;
        s_data               = s_data + 1'b1;
        s_valid              = 1'b1;
        do begin
            @(posedge clk);
        end while ( !s_ready );
        @(negedge clk);
        s_valid = 1'b0;
    endtask

    initial begin
        s_last  = 1'b0;
        s_strb  = '0;
        s_keep  = '0;
        s_data  = '0;
        s_valid = 1'b0;
        expected_input_first = 1'b0;
        output_count = 0;
        wait ( !test_reset );
        send(1'b0, 1'b1, 1'b1, 1'b0);
        send(1'b1, 1'b0, 1'b0, 1'b1);
        send(1'b0, 1'b1, 1'b1, 1'b1);
        wait ( output_count == 3 );
        $display("PASS: width-converter AUTO_FIRST sequence");
    end

    initial begin
        #10000;
        if ( output_count != 3 ) begin
            $fatal(1, "auto-first test timed out after %0d outputs", output_count);
        end
    end

endmodule


`default_nettype wire


// end of file
