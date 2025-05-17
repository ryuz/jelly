
`timescale 1ns / 1ps
`default_nettype none


module python_align_10bit
        (
            input   var logic               reset       ,
            input   var logic               clk         ,

            input   var logic               sw_reset    ,
            input   var logic   [9:0]       pattern     ,
            output  var logic               calib_done  ,
            output  var logic               calib_error ,

            input   var logic   [3:0][1:0]  s_data      ,
            input   var logic        [1:0]  s_sync      ,
            input   var logic               s_valid     ,

            output  var logic   [3:0][9:0]  m_data      ,
            output  var logic        [9:0]  m_sync      ,
            output  var logic               m_valid     
        );

    // double latch
    (* ASYNC_REG="true" *)  logic   ff0_sw_reset, ff1_sw_reset;
    always_ff @(posedge clk) begin
        ff0_sw_reset <= sw_reset;
        ff1_sw_reset <= ff0_sw_reset;
    end

    logic   [9:0]   ff0_pattern;
    always_ff @(posedge clk) begin
        ff0_pattern <= pattern;
    end

    // pattern detect
    logic               detect     ;
    logic   [3:0]       phase      ;
    always_ff @(posedge clk) begin
        if ( reset || ff1_sw_reset ) begin
            phase       <= 'x   ;
            calib_done  <= 1'b0 ;
            calib_error <= 1'b0;
            m_data      <= 'x   ;
            m_sync      <= 'x   ;
            m_valid     <= 1'b0 ;
        end
        else begin
            m_valid     <= 1'b0 ;
            if ( s_valid ) begin
                m_data[0]  <= {m_data[0][7:0], s_data[0]};
                m_data[1]  <= {m_data[1][7:0], s_data[1]};
                m_data[2]  <= {m_data[2][7:0], s_data[2]};
                m_data[3]  <= {m_data[3][7:0], s_data[3]};
                m_sync     <= {m_sync   [7:0], s_sync   };

                detect <= ({m_data[0][7:0], s_data[0]} == ff0_pattern);

                phase <= phase + 1;
                if ( phase >= 4 ) begin
                    phase   <= '0           ;
                    m_valid <= calib_done   ;
                end

                if ( !calib_done ) begin
                    if ( s_data[0] != s_data[1] || s_data[0] != s_data[2] || s_data[0] != s_data[2] ) begin
                        calib_error <= 1'b1;
                    end
                    if ( detect && !calib_error ) begin
                        phase      <= 4'd1;
                        calib_done <= 1'b1;
                    end
                end
            end
        end
    end

endmodule

`default_nettype wire

// end of file
