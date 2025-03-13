// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// Black Level Correction
module jelly3_img_bayer_black_level_calc
        #(
            parameter   int     TAPS        = 1                             ,
            parameter   int     TAP_POS     = 0                             ,
            parameter   int     S_DATA_BITS = 10                            ,
            parameter   type    s_data_t    = logic [S_DATA_BITS-1:0]       ,
            parameter   int     M_DATA_BITS = S_DATA_BITS + 1               ,
            parameter   type    m_data_t    = logic signed [M_DATA_BITS-1:0],
            parameter   int     OFFSET_BITS = S_DATA_BITS                   ,
            parameter   type    offset_t    = logic [OFFSET_BITS-1:0]       ,
            localparam  type    phase_t     = logic [1:0]                   
        )
        (
            input   var logic               reset           ,
            input   var logic               clk             ,
            input   var logic               cke             ,
            input   var logic               enable          ,
            input   var phase_t             param_phase     ,
            input   var offset_t    [3:0]   param_offset    ,
            input   var logic               s_row_first     ,
            input   var logic               s_col_first     ,
            input   var s_data_t            s_data          ,
            output  var m_data_t            m_data          
        );

    localparam  int     CALC_BITS = ($bits(s_data_t) > $bits(m_data_t)) ? $bits(s_data_t)+1 : $bits(m_data_t)+1;
    localparam  type    calc_t    = logic  signed  [CALC_BITS-1:0];
    localparam  bit     SIGNED    = calc_t'(s_data_t'(calc_t'(-1))) == calc_t'(-1);

    localparam calc_t   MAX_VALUE = SIGNED ? calc_t'({1'b0, {($bits(m_data_t)-1){1'b1}}}) : calc_t'({1'b0, {$bits(m_data_t){1'b1}}});
    localparam calc_t   MIN_VALUE = SIGNED ? calc_t'({1'b1, {($bits(m_data_t)-1){1'b0}}}) : calc_t'({1'b0, {$bits(m_data_t){1'b0}}});

    
    phase_t     reg_param_phase ;

    phase_t     st0_phase       ;
    logic       st0_row_first   ;
    logic       st0_col_first   ;
    calc_t      st0_data        ;

    calc_t      st1_data        ;

    calc_t      st2_data        ;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_param_phase <= 'x;

            st0_phase     <= 'x;
            st0_row_first <= 'x;
            st0_col_first <= 'x;
            st0_data      <= 'x;

            st1_data      <= 'x;

            st2_data      <= 'x;
        end
        else if ( cke ) begin
            // stage0
            st0_phase[0] <= st0_phase[0] + TAPS[0];
            if ( s_col_first ) begin
                if ( s_row_first ) begin
                    reg_param_phase[0] <= param_phase[0] + TAP_POS[0];
                    reg_param_phase[1] <= param_phase[1];
                    st0_phase[0]       <= param_phase[0] + TAP_POS[0];
                    st0_phase[1]       <= param_phase[1];
                end
                else begin
                    st0_phase[0] <= reg_param_phase[0];
                    st0_phase[1] <= ~st0_phase[1];
                end
            end
            st0_data      <= calc_t'(s_data)    ;

            // stage1
            st1_data      <= st0_data       ;
            if ( enable ) begin
                st1_data      <= st0_data - calc_t'(param_offset[st0_phase]);
            end

            // stage2
            st2_data      <= st1_data       ;
            if ( st1_data < MIN_VALUE ) st2_data <= MIN_VALUE;
            if ( st1_data > MAX_VALUE ) st2_data <= MAX_VALUE;
        end
    end

    assign m_data      = m_data_t'(st2_data)    ;

endmodule


`default_nettype wire


// end of file
