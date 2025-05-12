
`timescale 1ns / 1ps
`default_nettype none

module py300_align_10bit
        (
            input   var logic               reset       ,
            input   var logic               clk         ,

            input   var logic               sw_reset    ,
            input   var logic   [9:0]       pattern     ,
            output  var logic   [4:0]       bitslip     ,
            output  var logic               calib_done  ,
            output  var logic               calib_error ,

            input   var logic   [3:0][3:0]  s_data      ,
            input   var logic        [3:0]  s_sync      ,
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

    // pattern detect
    logic   [5:0]   det_buf;
    logic   [9:0]   det_pattern;
    always_ff @(posedge clk) begin
        if ( s_valid ) begin
            det_buf <= {det_buf[1:0], s_data[0]};
        end
    end
    assign det_pattern = {det_buf[5:0], s_data[0]};
    logic det;
    assign det = s_valid && (det_pattern == pattern);

    (* MARK_DEBUG = "true" *)   logic                running , next_running     ;
    (* MARK_DEBUG = "true" *)   logic   [3:0]        num     , next_num         ;
    (* MARK_DEBUG = "true" *)   logic   [3:0][11:0]  data_buf, next_data_buf    ;
    (* MARK_DEBUG = "true" *)   logic        [11:0]  sync_buf, next_sync_buf    ;
    always_comb begin
        next_running   = running    ;
        next_num       = num        ;
        next_data_buf  = data_buf   ;
        next_sync_buf  = sync_buf   ;
        
        if ( m_valid ) begin
            next_data_buf[0]  = {next_data_buf[0][1:0], 10'hxxx};
            next_data_buf[1]  = {next_data_buf[1][1:0], 10'hxxx};
            next_data_buf[2]  = {next_data_buf[2][1:0], 10'hxxx};
            next_data_buf[3]  = {next_data_buf[3][1:0], 10'hxxx};
            next_sync_buf     = {next_sync_buf   [1:0], 10'hxxx};
            next_num      -= 4'd10;
        end
        if ( s_valid ) begin
            next_data_buf[0][8-next_num +: 4] = s_data[0]   ;
            next_data_buf[1][8-next_num +: 4] = s_data[1]   ;
            next_data_buf[2][8-next_num +: 4] = s_data[2]   ;
            next_data_buf[3][8-next_num +: 4] = s_data[3]   ;
            next_sync_buf   [8-next_num +: 4] = s_sync      ;
            next_num += 4;
        end
    end

    always_ff @(posedge clk) begin
        if ( reset || ff1_sw_reset ) begin
            running  <= 1'b0 ;
            num      <= '0   ;
            data_buf <= '0   ;
            sync_buf <= '0   ;
            m_valid  <= 1'b0 ;
        end
        else begin
            num      <= next_num        ;
            data_buf <= next_data_buf   ;
            sync_buf <= next_sync_buf   ;
            m_valid  <= running && (next_num >= 4'd10);
            if ( !running && det ) begin
                running <= 1'b1;
                num     <= '0;
            end
        end
    end

    logic   [5:0]  bit_slip_count;
    always_ff @(posedge clk) begin
        if ( reset || ff1_sw_reset ) begin
            bit_slip_count <= '0    ;
            bitslip        <= '0    ;
        end
        else begin
            if ( !running ) begin
                bitslip <= '0;
                bit_slip_count <= bit_slip_count + 1;
                if ( bit_slip_count == '1 ) begin
                    bitslip <= '1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if ( reset || ff1_sw_reset ) begin
            calib_error <= 1'b0;
        end
        else begin
            if ( !running ) begin
                if ( s_data[0] != s_data[1] || s_data[0] != s_data[2] || s_data[0] != s_data[2] ) begin
                    calib_error <= 1'b1;
                end
            end
        end
    end

    assign calib_done = running;
    assign m_data[0]  = data_buf[0][11:2];
    assign m_data[1]  = data_buf[1][11:2];
    assign m_data[2]  = data_buf[2][11:2];
    assign m_data[3]  = data_buf[3][11:2];
    assign m_sync     = sync_buf   [11:2];

endmodule

`default_nettype wire

// end of file
