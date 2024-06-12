// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_packet_position_step
        #(
            parameter   int unsigned    INDEX_WIDTH     = 8                 ,
            parameter   int unsigned    OFFSET_WIDTH    = 8                 ,
            parameter   int unsigned    STEP_WIDTH      = 8                 ,
            parameter   int unsigned    LENGTH_WIDTH    = STEP_WIDTH        ,
            parameter   int unsigned    FLAG_WIDTH      = 1                 ,
            parameter   bit             DEBUG           = 1'b0              ,
            parameter   bit             SIMULATION      = 1'b0             
        )
        ( 
            input   var logic                       reset                   ,
            input   var logic                       clk                     ,
            input   var logic                       cke                     ,

            input   var logic   [OFFSET_WIDTH-1:0]  offset                  ,
            input   var logic   [STEP_WIDTH-1:0]    step                    ,
            input   var logic   [LENGTH_WIDTH-1:0]  length                  ,   // size-1
            input   var logic   [INDEX_WIDTH-1:0]   index                   ,

            input   var logic                       setup                   ,
            input   var logic                       s_valid                 ,

            output  var logic   [FLAG_WIDTH-1:0]    m_flag                  ,
            output  var logic                       m_first                 ,
            output  var logic                       m_last                  ,
            output  var logic                       m_valid                 
        );


    localparam  type    t_offset = logic    [OFFSET_WIDTH-1:0];
    localparam  type    t_index  = logic    [INDEX_WIDTH-1:0];
    localparam  type    t_step   = logic    [STEP_WIDTH-1:0];
    localparam  type    t_length = logic    [LENGTH_WIDTH-1:0];
    localparam  type    t_flag   = logic    [FLAG_WIDTH-1:0];

    logic       offset_valid;

    generate
    if ( OFFSET_WIDTH > 0 ) begin : blk_count
        logic       offset_mask;
        t_offset    offset_count;
        always_ff @(posedge clk) begin
            if ( cke ) begin
                if ( setup ) begin
                    offset_mask  <= offset != t_offset'(0);
                    offset_count <= offset - t_offset'(1);
                end
                else begin
                    if ( s_valid && offset_mask ) begin
                        offset_count <= offset - t_offset'(1);
                        offset_mask  <= offset_count == t_offset'(0);
                    end
                end
            end
        end
        assign offset_valid = s_valid & ~offset_mask;
    end
    else begin : none_offset
        assign offset_valid = s_valid;
    end
    endgenerate


    t_flag      position_flag;
    logic       position_first;
    logic       position_last;
    logic       position_enable;
    t_index     index_count;
    logic       step_last;
    t_step      step_count;
    t_index     index_next;
    t_step      step_next;
    assign index_next = index_count + t_index'(1);
    assign step_next  = step_count  + t_step'(1);
    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( setup ) begin
                position_flag   <= index == t_index'(0) ? t_flag'(1) : t_flag'(0);
                position_first  <= index == t_index'(0);
                position_last   <= index == t_index'(0) && length == t_length'(0);
                position_enable <= index == t_index'(0);
                index_count     <= t_index'(0);
                step_last       <= step == t_step'(1);
                step_count      <= t_step'(0);
            end
            else begin
                if ( offset_valid ) begin
                    if ( step_next == t_step'(length) ) begin
                        position_enable <= 1'b0;
                    end

                    step_count    <= step_next;
                    step_last     <= step_next == step;
                    position_last <= step_next == t_step'(length);

                    position_flag <= position_flag << 1;
                    if ( position_last ) begin
                        position_flag <= t_flag'(0);
                    end

                    if ( step_last  ) begin
                        position_flag   <= index_next == index ? t_flag'(1) : t_flag'(0);
                        position_first  <= index_next == index;
                        position_last   <= index_next == index && length == t_length'(0);
                        position_enable <= index_next == index;
                        index_count     <= index_next;
                        step_last       <= step == t_step'(1);
                        step_count      <= t_step'(0);
                    end
                end
            end
        end
    end

    assign m_flag  = position_flag                  ;
    assign m_first = position_first                 ;
    assign m_last  = position_last                  ;
    assign m_valid = position_enable & offset_valid ;

endmodule


`default_nettype wire


// end of file
