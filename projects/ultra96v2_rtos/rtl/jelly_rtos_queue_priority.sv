// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_rtos_queue_priority
        #(
            parameter int   QUE_SIZE    = 16,
            parameter int   ID_WIDTH    = 4,
            parameter int   PRI_WIDTH   = 4,
            parameter int   COUNT_WIDTH = $clog2(QUE_SIZE+1)
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            input   wire    [ID_WIDTH-1:0]      add_id,
            input   wire    [PRI_WIDTH-1:0]     add_pri,
            input   wire                        add_valid,

            input   wire    [ID_WIDTH-1:0]      remove_id,
            input   wire                        remove_valid,

            output  wire    [ID_WIDTH-1:0]      top_id,
            output  wire    [PRI_WIDTH-1:0]     top_pri,
            output  wire                        top_valid,

            output  reg     [COUNT_WIDTH-1:0]   count
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
    
    object_t                    add_obj;
    assign add_obj.id    = add_id;
    assign add_obj.pri   = add_pri;
    assign add_obj.valid = add_valid;
    
    flag_t                      reg_flag    [QUE_SIZE-1:0];
    object_t                    reg_obj;
    object_t    [QUE_SIZE-1:0]  reg_array;
    
    object_t    [QUE_SIZE-1:0]  array;
    logic       [QUE_SIZE-1:0]  compare;
    
    always_comb begin : blk_array
        // array
        automatic object_t  [QUE_SIZE:0] tmp_array;
        tmp_array[QUE_SIZE-1:0]   = reg_array;
        tmp_array[QUE_SIZE]       = 'x;
        tmp_array[QUE_SIZE].valid = '0;
        for ( int i = 0; i < QUE_SIZE; ++i ) begin
            case ( reg_flag[i] )
            stay:       array[i] = tmp_array[i];
            forward:    array[i] = tmp_array[i+1];
            backward:   array[i] = tmp_array[i-1];
            insert:     array[i] = reg_obj;
            endcase
        end
        
        // priority
        for ( int i = 0; i < QUE_SIZE; ++i ) begin
            compare[i] = (add_pri < array[i].pri || !array[i].valid);
        end
    end
    
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            count <= '0;
            for ( int i = 0; i < QUE_SIZE; ++i ) begin
                reg_flag[i]  <= stay;
                reg_array[i] <= '{id: 'x, pri: 'x, valid: 1'b0};
            end
        end
        else if ( cke ) begin
            for ( int i = 0; i < QUE_SIZE; ++i ) begin
                reg_flag[i]  <= stay;
                reg_array[i] <= array[i];
            end
            
            reg_obj <= add_obj;
            /* verilator lint_off CASEINCOMPLETE */
            unique case ({remove_valid, add_valid})
            2'b01:  // add
                begin
                    count <= count + 1'b1;
                    
                    for ( int i = 0; i < QUE_SIZE; ++i ) begin
                        if ( compare[i] ) begin
                            if ( i == 0 ) begin
                                reg_flag[i] <= insert;
                            end
                            else begin
                                reg_flag[i] <= compare[i-1] ? backward : insert;
                            end
                        end
                    end
                    
                    if ( compare[0] ) begin
                        reg_array[0] <= add_obj;
                        reg_flag[0]  <= stay;
                        reg_obj      <= reg_array[0];
                        if ( QUE_SIZE > 1 ) begin
                            reg_flag[1] <= insert;
                        end
                    end
                end

            2'b10:  // remove
                begin
                    automatic bit   remove_flag;

                    count <= count - 1'b1;
                    remove_flag = 1'b0;
                    for ( int i = 0; i < QUE_SIZE; ++i ) begin
                        if ( array[i].id == remove_id ) begin
                            remove_flag = 1'b1;
                        end

                        if ( remove_flag ) begin
                            reg_flag[i] <= forward;
                        end
                    end

                    if ( array[0].id == remove_id ) begin
                        reg_array[0] <= array[1];
                        reg_flag[0]  <= stay;
                    end
                end

            2'b00:  // nop
                ;

            endcase
            /* verilator lint_on CASEINCOMPLETE */
        end
    end
    
    assign top_id    = reg_array[0].id;
    assign top_pri   = reg_array[0].pri;
    assign top_valid = reg_array[0].valid;

endmodule


`default_nettype wire


// End of file
