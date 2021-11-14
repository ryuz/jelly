

`timescale 1ns / 1ps
//`default_nettype none


module tb_sim_main
        (
            input   logic                       reset,
            input   logic                       clk
        );
    

    parameter int   N          = 16;
    parameter int   ID_WIDTH   = 32;
    parameter int   PRI_WIDTH  = 4;
    parameter int   N_WIDTH    = $clog2(N+1);

    logic                           cke = 1'b1;

    logic   [0:0]                   in_op;  // 0: add, 1: del
    logic   [ID_WIDTH-1:0]          in_id;
    logic   [PRI_WIDTH-1:0]         in_pri;
    logic                           in_valid;

    logic   [ID_WIDTH-1:0]          top_id;
    logic   [PRI_WIDTH-1:0]         top_pri;
    logic                           top_valid;

    logic   [N_WIDTH-1:0]           size;

    jelly_priority_queue
            #(
                    .N              (N        ),
                    .ID_WIDTH       (ID_WIDTH ),
                    .PRI_WIDTH      (PRI_WIDTH),
                    .N_WIDTH        (N_WIDTH  )
            )
        i_priority_queue
            (
                .*
            );


    typedef struct packed {
        logic                       op;
        logic   [ID_WIDTH-1:0]      id;
        logic   [PRI_WIDTH-1:0]     pri;
        logic                       valid;

        logic   [N_WIDTH-1:0]       exp_size;
        logic   [ID_WIDTH-1:0]      exp_top_id;
        logic   [PRI_WIDTH-1:0]     exp_top_pri;
    } object_t;

    localparam  TEST_NUM = 256;
    object_t    [TEST_NUM-1:0]  test_table;
    int                         idx;
    initial begin
        idx = 0;
        test_table[idx] = '{op: 1'b0, id: 32'h102, pri: 4'h2, valid: 1'b1, exp_size:0,  exp_top_id: 'x,      exp_top_pri: 'x  };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h103, pri: 4'h3, valid: 1'b1, exp_size:1,  exp_top_id: 32'h102, exp_top_pri: 4'h2};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h101, pri: 4'h1, valid: 1'b1, exp_size:2,  exp_top_id: 32'h102, exp_top_pri: 4'h2};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, pri: 'x,   valid: 1'b1, exp_size:3,  exp_top_id: 32'h101, exp_top_pri: 4'h1};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h103, pri: 'x,   valid: 1'b1, exp_size:2,  exp_top_id: 32'h101, exp_top_pri: 4'h1};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, pri: 'x,   valid: 1'b1, exp_size:1,  exp_top_id: 32'h101, exp_top_pri: 4'h1};    idx++;
        test_table[idx] = '{op: 1'bx, id:'x,       pri: 'x,   valid: 1'b0, exp_size:0,  exp_top_id: 'x,      exp_top_pri: 'x  };    idx++;
        test_table[idx] = '{op: 1'bx, id:'x,       pri: 'x,   valid: 1'b0, exp_size:0,  exp_top_id: 'x,      exp_top_pri: 'x  };    idx++;
        test_table[idx] = '{op: 1'bx, id:'x,       pri: 'x,   valid: 1'b0, exp_size:0,  exp_top_id: 'x,      exp_top_pri: 'x  };    idx++;

        test_table[idx] = '{op: 1'b0, id: 32'h100, pri: 4'h0, valid: 1'b1, exp_size:0,  exp_top_id:'x,       exp_top_pri: 'x  };    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h101, pri: 4'h1, valid: 1'b1, exp_size:1,  exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h102, pri: 4'h2, valid: 1'b1, exp_size:2,  exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h103, pri: 4'h3, valid: 1'b1, exp_size:3,  exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h104, pri: 4'h4, valid: 1'b1, exp_size:4,  exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h105, pri: 4'h5, valid: 1'b1, exp_size:5,  exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h106, pri: 4'h6, valid: 1'b1, exp_size:6,  exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h107, pri: 4'h7, valid: 1'b1, exp_size:7,  exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h108, pri: 4'h8, valid: 1'b1, exp_size:8,  exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h109, pri: 4'h9, valid: 1'b1, exp_size:9,  exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10a, pri: 4'ha, valid: 1'b1, exp_size:10, exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10b, pri: 4'hb, valid: 1'b1, exp_size:11, exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10c, pri: 4'hc, valid: 1'b1, exp_size:12, exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10d, pri: 4'hd, valid: 1'b1, exp_size:13, exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10e, pri: 4'he, valid: 1'b1, exp_size:14, exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b0, id: 32'h10f, pri: 4'hf, valid: 1'b1, exp_size:15, exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
//      test_table[idx] = '{op: 1'bx, id: 'x,      pri: 'x,   valid: 1'b0, exp_size:16, exp_top_id:'32'h100, exp_top_pri: 4'h0};    idx++;

        test_table[idx] = '{op: 1'b1, id: 32'h100, pri: 4'h0, valid: 1'b1, exp_size:16, exp_top_id: 32'h100, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h101, pri: 4'h1, valid: 1'b1, exp_size:15, exp_top_id: 32'h101, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h102, pri: 4'h2, valid: 1'b1, exp_size:14, exp_top_id: 32'h102, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h103, pri: 4'h3, valid: 1'b1, exp_size:13, exp_top_id: 32'h103, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h104, pri: 4'h4, valid: 1'b1, exp_size:12, exp_top_id: 32'h104, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h105, pri: 4'h5, valid: 1'b1, exp_size:11, exp_top_id: 32'h105, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h106, pri: 4'h6, valid: 1'b1, exp_size:10, exp_top_id: 32'h106, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h107, pri: 4'h7, valid: 1'b1, exp_size:9,  exp_top_id: 32'h107, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h108, pri: 4'h8, valid: 1'b1, exp_size:8,  exp_top_id: 32'h108, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h109, pri: 4'h9, valid: 1'b1, exp_size:7,  exp_top_id: 32'h109, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10a, pri: 4'ha, valid: 1'b1, exp_size:6,  exp_top_id: 32'h10a, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10b, pri: 4'hb, valid: 1'b1, exp_size:5,  exp_top_id: 32'h10b, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10c, pri: 4'hc, valid: 1'b1, exp_size:4,  exp_top_id: 32'h10c, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10d, pri: 4'hd, valid: 1'b1, exp_size:3,  exp_top_id: 32'h10d, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10e, pri: 4'he, valid: 1'b1, exp_size:2,  exp_top_id: 32'h10e, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'b1, id: 32'h10f, pri: 4'hf, valid: 1'b1, exp_size:1,  exp_top_id: 32'h10f, exp_top_pri: 4'h0};    idx++;
        test_table[idx] = '{op: 1'bx, id: 'x,      pri: 'x,   valid: 1'b0, exp_size:0,  exp_top_id:'x,       exp_top_pri: 4'x};     idx++;

    end

    int     step = 0;

    assign in_op    = test_table[step].op;
    assign in_id    = test_table[step].id;
    assign in_pri   = test_table[step].pri;
    assign in_valid = test_table[step].valid;


    logic   [N_WIDTH-1:0]   exp_size;
    logic   [ID_WIDTH-1:0]  exp_top_id;
    logic   [PRI_WIDTH-1:0] exp_top_pri;
    logic                   exp_top_valid;
    assign exp_size      = test_table[step].exp_size;
    assign exp_top_id    = test_table[step].exp_top_id;
    assign exp_top_pri   = test_table[step].exp_top_pri;
    assign exp_top_valid = exp_size > 0;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            step <= 0;
        end
        else if ( cke ) begin
            if ( step < idx ) begin
                step <= step + 1;

                if ( !(size == exp_size) )                          $display("error[%d]: size", step);
                if ( exp_top_valid && !(top_id  == exp_top_id) )    $display("error[%d]: top_id", step);
                if ( exp_top_valid && !(top_pri == exp_top_pri) )   $display("error[%d]: top_pri", step);
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
