
`timescale 1ns / 1ps
`default_nettype none

module pttern_align_10bit
        (
            input   var logic           reset       ,
            input   var logic           clk         ,

            input   var logic           force_align ,
            input   var logic   [9:0]   pattern     ,
            output  var logic           detected    ,
            output  var logic           bitslip     ,

            input   var logic   [3:0]   s_data      ,
            input   var logic           s_valid     ,

            output  var logic   [9:0]   m_data      ,
            output  var logic           m_valid     
        );


    logic   [5:0]   det_buf;
    logic   [9:0]   det_pattern;
    always_ff @(posedge clk) begin
        if ( s_valid ) begin
            det_buf <= {det_buf[1:0], s_data};
        end
    end
    assign det_pattern = {det_buf[5:0], s_data};
    logic det;
    assign det = s_valid && (det_pattern == pattern);


    logic           running , next_running  ;
    logic   [3:0]   num     , next_num      ;
    logic   [11:0]  buffer  , next_buffer   ;
    always_comb begin
        next_running = running;
        next_num     = num   ;
        next_buffer  = buffer;
        
        if ( m_valid ) begin
            next_buffer  = {next_buffer[1:0], 10'hxxx};
            next_num    -= 4'd10;
        end
        if ( s_valid ) begin
            next_buffer[8-next_num +: 4] = s_data;
            next_num += 4;
        end
    end

    always_ff @(posedge clk) begin
        if ( reset || force_align ) begin
            running <= 1'b0 ;
            num     <= '0   ;
            buffer  <= '0   ;
            m_valid <= 1'b0 ;
        end
        else begin
            num     <= next_num     ;
            buffer  <= next_buffer  ;
            m_valid <= running && (next_num >= 4'd10);
            if ( !running && det ) begin
                running <= 1'b1;
                num     <= '0;
            end
        end
    end

    logic   [5:0]  bit_slip_count;
    always_ff @(posedge clk) begin
        if ( reset || force_align ) begin
            bit_slip_count <= '0    ;
            bitslip        <= 1'b0  ;
        end
        else begin
            if ( !running ) begin
                bitslip <= 1'b0;

                bit_slip_count <= bit_slip_count + 1;
                if ( bit_slip_count == '1 ) begin
                    bitslip <= 1'b1;
                end
            end
        end
    end

    assign detected = running;
    assign m_data   = buffer[11:2];

endmodule

`default_nettype wire

// end of file
