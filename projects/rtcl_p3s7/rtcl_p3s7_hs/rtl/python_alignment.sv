
`timescale 1ns / 1ps
`default_nettype none


module python_alignment
        #(
            parameter   int     CHANNELS      = 4                        ,
            parameter   int     DATA_BITS     = 10                       ,
            parameter   type    data_t        = logic [DATA_BITS-1:0]    ,
            parameter   int     SLIP_INTERVAL = 15                       
        )
        (
            input   var logic                   reset       ,
            input   var logic                   clk         ,

            input   var logic                   sw_reset    ,
            input   var data_t                  pattern     ,
            output  var logic                   align_done  ,
            output  var logic                   align_error ,

            output  var logic                   bitslip     ,
            input   var data_t  [CHANNELS-1:0]  s_data      ,
            input   var data_t                  s_sync      ,
            input   var logic                   s_valid     ,

            output  var data_t  [CHANNELS-1:0]  m_data      ,
            output  var data_t                  m_sync      ,
            output  var logic                   m_valid     
        );

    // counter bits
    localparam  int     COUNTER_BITS = $clog2(SLIP_INTERVAL+1);
    localparam  type    counter_t    = logic [COUNTER_BITS-1:0];

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
    logic   pattern_ok;
    logic   pattern_ng;
    always_comb begin
        pattern_ng = 1'b0;
        for (int i = 0; i < CHANNELS; i++) begin
            if ( s_data[i] != s_sync) begin
                pattern_ng = 1'b1;
            end
        end
        pattern_ok = !pattern_ng && (s_sync == ff0_pattern);
    end

    // alignment control
    counter_t   counter;
    always_ff @(posedge clk) begin
        if ( reset || ff1_sw_reset || !s_valid ) begin
            bitslip     <= 1'b0 ;
            counter     <= '0   ;
            align_done  <= 1'b0 ;
            align_error <= 1'b0 ;
        end
        else begin
            bitslip <= 1'b0 ;
            if ( !align_error && !align_done ) begin
                if ( pattern_ng ) begin
                    align_error <= 1'b1;
                end
                else if ( pattern_ok ) begin
                    align_done  <= 1'b1;
                end
                else begin
                    counter <= counter + 1;
                    if ( counter >= counter_t'(SLIP_INTERVAL) ) begin
                        bitslip <= 1'b1;
                        counter <= '0;
                    end
                end
            end
        end
    end

    // output
    assign m_data  = s_data     ;
    assign m_sync  = s_sync     ;
    assign m_valid = align_done ;

endmodule

`default_nettype wire

// end of file
