

`timescale 1ns / 1ps
//`default_nettype none


module tb_sim_main
        (
            input   logic                       reset,
            input   logic                       clk
        );
    

    parameter int   QUE_SIZE    = 16;
    parameter int   ID_WIDTH    = 32;
    parameter int   PRI_WIDTH   = 4;
    parameter int   COUNT_WIDTH = $clog2(QUE_SIZE+1);

    logic                           cke = 1'b1;

    logic   [ID_WIDTH-1:0]          add_id;
    logic   [PRI_WIDTH-1:0]         add_pri;
    logic                           add_valid;

    logic   [ID_WIDTH-1:0]          remove_id;
    logic                           remove_valid;

    logic   [ID_WIDTH-1:0]          top_id;
    logic   [PRI_WIDTH-1:0]         top_pri;
    logic                           top_valid;

    logic   [COUNT_WIDTH-1:0]       count;

    jelly_rtos_queue_fifo
            #(
                .QUE_SIZE       (QUE_SIZE),
                .ID_WIDTH       (ID_WIDTH),
                .COUNT_WIDTH    (COUNT_WIDTH)
            )
        i_rtos_queue_fifo
            (
                .*
            );


    typedef struct packed {
        logic                       op;
        logic   [ID_WIDTH-1:0]      id;
        logic                       valid;

        logic   [COUNT_WIDTH-1:0]   exp_count;
        logic   [ID_WIDTH-1:0]      exp_top_id;
    } object_t;

    localparam  TEST_NUM = 256;
    object_t    [TEST_NUM-1:0]  test_table;
    int                         idx;
    initial begin
        idx = 0;
        test_table[idx] = '{op: 1'b0, id: 32'h101, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h999, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;

        test_table[idx] = '{op: 1'b0, id: 32'h101, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h102, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h999, valid: 1'b1, exp_count:1,  exp_top_id: 32'h102};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, valid: 1'b1, exp_count:1,  exp_top_id: 32'h102};    idx++;

        test_table[idx] = '{op: 1'b0, id: 32'h101, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h102, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;


        test_table[idx] = '{op: 1'b0, id: 32'h101, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h102, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h103, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, valid: 1'b1, exp_count:3,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, valid: 1'b1, exp_count:2,  exp_top_id: 32'h102};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h103, valid: 1'b1, exp_count:1,  exp_top_id: 32'h103};    idx++;
        test_table[idx] = '{op: 1'bx, id:'x,       valid: 1'b0, exp_count:0,  exp_top_id: 'x     };    idx++;

        test_table[idx] = '{op: 1'b0, id: 32'h101, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h102, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h103, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, valid: 1'b1, exp_count:3,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h103, valid: 1'b1, exp_count:2,  exp_top_id: 32'h102};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, valid: 1'b1, exp_count:1,  exp_top_id: 32'h102};    idx++;

        test_table[idx] = '{op: 1'b0, id: 32'h101, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h102, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h103, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, valid: 1'b1, exp_count:3,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h103, valid: 1'b1, exp_count:1,  exp_top_id: 32'h103};    idx++;

        test_table[idx] = '{op: 1'b0, id: 32'h101, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h102, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h103, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, valid: 1'b1, exp_count:3,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h103, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;

        test_table[idx] = '{op: 1'b0, id: 32'h101, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h102, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h103, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h103, valid: 1'b1, exp_count:3,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, valid: 1'b1, exp_count:1,  exp_top_id: 32'h102};    idx++;

        test_table[idx] = '{op: 1'b0, id: 32'h101, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h102, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h103, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h103, valid: 1'b1, exp_count:3,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, valid: 1'b1, exp_count:2,  exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, valid: 1'b1, exp_count:1,  exp_top_id: 32'h101};    idx++;

        // 16個昇順
        test_table[idx] = '{op: 1'b0, id: 32'h100, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h101, valid: 1'b1, exp_count:1,  exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h102, valid: 1'b1, exp_count:2,  exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h103, valid: 1'b1, exp_count:3,  exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h104, valid: 1'b1, exp_count:4,  exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h105, valid: 1'b1, exp_count:5,  exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h106, valid: 1'b1, exp_count:6,  exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h107, valid: 1'b1, exp_count:7,  exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h108, valid: 1'b1, exp_count:8,  exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h109, valid: 1'b1, exp_count:9,  exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10a, valid: 1'b1, exp_count:10, exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10b, valid: 1'b1, exp_count:11, exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10c, valid: 1'b1, exp_count:12, exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10d, valid: 1'b1, exp_count:13, exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10e, valid: 1'b1, exp_count:14, exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10f, valid: 1'b1, exp_count:15, exp_top_id: 32'h100};    idx++;
//      test_table[idx] = '{op: 1'bx, id: 'x,      valid: 1'b0, exp_count:16, exp_top_id:'32'h100};    idx++;

        test_table[idx] = '{op: 1'b1, id: 32'h100, valid: 1'b1, exp_count:16, exp_top_id: 32'h100};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, valid: 1'b1, exp_count:15, exp_top_id: 32'h101};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, valid: 1'b1, exp_count:14, exp_top_id: 32'h102};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h103, valid: 1'b1, exp_count:13, exp_top_id: 32'h103};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h104, valid: 1'b1, exp_count:12, exp_top_id: 32'h104};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h105, valid: 1'b1, exp_count:11, exp_top_id: 32'h105};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h106, valid: 1'b1, exp_count:10, exp_top_id: 32'h106};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h107, valid: 1'b1, exp_count:9,  exp_top_id: 32'h107};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h108, valid: 1'b1, exp_count:8,  exp_top_id: 32'h108};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h109, valid: 1'b1, exp_count:7,  exp_top_id: 32'h109};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10a, valid: 1'b1, exp_count:6,  exp_top_id: 32'h10a};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10b, valid: 1'b1, exp_count:5,  exp_top_id: 32'h10b};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10c, valid: 1'b1, exp_count:4,  exp_top_id: 32'h10c};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10d, valid: 1'b1, exp_count:3,  exp_top_id: 32'h10d};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10e, valid: 1'b1, exp_count:2,  exp_top_id: 32'h10e};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10f, valid: 1'b1, exp_count:1,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'bx, id: 'x,      valid: 1'b0, exp_count:0,  exp_top_id: 'x     };    idx++;

        // 16個降順
        test_table[idx] = '{op: 1'b0, id: 32'h10f, valid: 1'b1, exp_count:0,  exp_top_id: 'x     };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10e, valid: 1'b1, exp_count:1,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10d, valid: 1'b1, exp_count:2,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10c, valid: 1'b1, exp_count:3,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10b, valid: 1'b1, exp_count:4,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10a, valid: 1'b1, exp_count:5,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h109, valid: 1'b1, exp_count:6,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h108, valid: 1'b1, exp_count:7,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h107, valid: 1'b1, exp_count:8,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h106, valid: 1'b1, exp_count:9,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h105, valid: 1'b1, exp_count:10, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h104, valid: 1'b1, exp_count:11, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h103, valid: 1'b1, exp_count:12, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h102, valid: 1'b1, exp_count:13, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h101, valid: 1'b1, exp_count:14, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h100, valid: 1'b1, exp_count:15, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'bx, id: 'x,      valid: 1'b0, exp_count:16, exp_top_id: 32'h10f};    idx++;

        test_table[idx] = '{op: 1'b1, id: 32'h100, valid: 1'b1, exp_count:16, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, valid: 1'b1, exp_count:15, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, valid: 1'b1, exp_count:14, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h103, valid: 1'b1, exp_count:13, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h104, valid: 1'b1, exp_count:12, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h105, valid: 1'b1, exp_count:11, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h106, valid: 1'b1, exp_count:10, exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h107, valid: 1'b1, exp_count:9,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h108, valid: 1'b1, exp_count:8,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h109, valid: 1'b1, exp_count:7,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10a, valid: 1'b1, exp_count:6,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10b, valid: 1'b1, exp_count:5,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10c, valid: 1'b1, exp_count:4,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10d, valid: 1'b1, exp_count:3,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10e, valid: 1'b1, exp_count:2,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10f, valid: 1'b1, exp_count:1,  exp_top_id: 32'h10f};    idx++;
        test_table[idx] = '{op: 1'bx, id: 'x,      valid: 1'b0, exp_count:0,  exp_top_id: 'x     };    idx++;
    end

    int     step = 0;

    always_comb begin : block_op
        add_id       = 'x;
        add_valid    = 1'b0;
        remove_id    = 'x;
        remove_valid = 1'b0;
        if ( test_table[step].valid ) begin
            if ( test_table[step].op == 1'b0 ) begin
                add_id    = test_table[step].id;
                add_valid = test_table[step].valid;
            end
            else if ( test_table[step].op == 1'b1 ) begin
                remove_id    = test_table[step].id;
                remove_valid = test_table[step].valid;
            end
        end
    end

    logic   [COUNT_WIDTH-1:0]   exp_count;
    logic   [ID_WIDTH-1:0]      exp_top_id;
    logic   [PRI_WIDTH-1:0]     exp_top_pri;
    logic                   exp_top_valid;
    assign exp_count     = test_table[step].exp_count;
    assign exp_top_id    = test_table[step].exp_top_id;
    assign exp_top_valid = exp_count > 0;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            step <= 0;
        end
        else if ( cke ) begin
            if ( step < idx ) begin
                step <= step + 1;

                if ( !(count == exp_count) )                        $display("error[%d]: count", step);
                if ( exp_top_valid && !(top_id  == exp_top_id) )    $display("error[%d]: top_id", step);
                if ( !(top_valid == exp_top_valid) )                $display("error[%d]: top_valid", step);
            end
            else begin
                $finish();
            end
        end
    end


endmodule


//`default_nettype wire


// end of file
