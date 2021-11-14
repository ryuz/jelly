// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_priority_queue
        #(
            parameter int   N          = 16,
            parameter int   ID_WIDTH   = 4,
            parameter int   PRI_WIDTH  = 4,
            parameter int   N_WIDTH    = $clog2(N+1)
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,

            input   wire    [0:0]                   in_op,  // 0: add, 1: del
            input   wire    [ID_WIDTH-1:0]          in_id,
            input   wire    [PRI_WIDTH-1:0]         in_pri,
            input   wire                            in_valid,

            output  wire    [ID_WIDTH-1:0]          top_id,
            output  wire    [PRI_WIDTH-1:0]         top_pri,
            output  wire                            top_valid,

            output  wire    [N_WIDTH-1:0]           size
        );


    
    typedef struct packed {
        logic   [ID_WIDTH-1:0]   id;
        logic   [PRI_WIDTH-1:0]  pri;
        logic                    valid;
    } object_t;
    
    typedef enum {
        stay,
        forward,
        backward,
        insert
    } flag_t;

    object_t                    in_obj;
    assign in_obj.id    = in_id;
    assign in_obj.pri   = in_pri;
    assign in_obj.valid = in_valid;

    logic       [N_WIDTH-1:0]   reg_size;
    flag_t      [N-1:0]         reg_flag;
    object_t                    reg_obj;
    object_t    [N-1:0]         reg_array;

    object_t    [N-1:0]         array;
    logic       [N-1:0]         compare;

    always_comb begin : blk_array
        // array
        automatic object_t  [N:0] tmp_array;
        tmp_array[N-1:0] = reg_array;
        tmp_array[N]     = '0;
        for ( int i = 0; i < N; ++i ) begin
            case ( reg_flag[i] )
            stay:       array[i] = tmp_array[i];
            forward:    array[i] = tmp_array[i+1];
            backward:   array[i] = tmp_array[i-1];
            insert:     array[i] = reg_obj;
            endcase
        end

        // priority
        for ( int i = 0; i < N; ++i ) begin
            compare[i] = (in_pri < array[i].pri || !array[i].valid);
        end
    end

    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_size  <= '0;
            for ( int i = 0; i < N; ++i ) begin
                reg_flag[i]  <= stay;
                reg_array[i] <= '{id: 'x, pri: 'x, valid: 1'b0};
            end
        end
        else if ( cke ) begin
            for ( int i = 0; i < N; ++i ) begin
                reg_flag[i]  <= stay;
                reg_array[i] <= array[i];
            end

            reg_obj <= in_obj;
            if ( in_valid ) begin
                if (in_op == 1'b0) begin    // add
                    reg_size <= reg_size + 1'b1;

                    for ( int i = 0; i < N; ++i ) begin
                        if ( compare[i] ) begin
                            if ( i == 0 ) begin
                                reg_flag[i] <= insert;
                            end
                            else begin
                                reg_flag[i] <= compare[i-1] ? backward : insert;
                            end
                        end
                    end

                    /*
                    if ( compare[0] ) begin
                        reg_array[0] <= in_obj;
                        reg_obj      <= reg_array[0];
                        if ( N > 1 ) begin
                            reg_flag[1] <= insert;
                        end
                    end
                    */
                end

                if (in_op == 1'b1) begin    // delete
                    automatic bit   del_flag;

                    reg_size <= reg_size - 1'b1;
                    del_flag = 1'b0;
                    for ( int i = 0; i < N; ++i ) begin
                        if ( array[i].id == in_id ) begin
                            del_flag = 1'b1;
                        end

                        if ( del_flag ) begin
                            reg_flag[i] <= forward;
                        end
                    end

                    if ( array[0].id == in_id ) begin
                        reg_array[0] <= array[1];
                        reg_flag[0]  <= stay;
                    end
                end
            end
        end
    end
    
    assign top_id    = array[0].id;
    assign top_pri   = array[0].pri;
    assign top_valid = array[0].valid;
    assign size      = reg_size;

endmodule


`default_nettype wire


// End of file
