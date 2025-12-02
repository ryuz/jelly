
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset0  ,
            input   var logic   clk0    ,
            input   var logic   reset1  ,
            input   var logic   clk1    
        );
    

    parameter   bit     ASYNC       = 1                     ;
    parameter   int     DATA_BITS   = 8                     ;
    parameter   type    data_t      = logic [DATA_BITS-1:0] ;
    parameter   int     M_SYNC_FF   = 2                     ;
    parameter   int     S_SYNC_FF   = 2                     ;
    parameter           DEVICE      = "RTL"                 ;
    parameter           SIMULATION  = "false"               ;
    parameter           DEBUG       = "false"               ;

    logic       s_reset ;
    logic       s_clk   ;
    logic       s_cke   ;
    data_t      s_data  ;
    logic       s_valid ;
    logic       s_ready ;
    
    logic       m_reset ;
    logic       m_clk   ;
    logic       m_cke   ;
    data_t      m_data  ;
    logic       m_valid ;
    logic       m_ready ;

    assign s_reset = reset0    ;
    assign s_clk   = clk0      ;
//  assign s_cke   = 1'b1      ;
    always_ff @(posedge s_clk) s_cke <= 1'($random);

    assign m_reset = reset1    ;
    assign m_clk   = clk1      ;
//  assign m_cke   = 1'b1      ;
    always_ff @(posedge m_clk) m_cke <= 1'($random);

    jelly3_data_async
            #(
                .ASYNC          (ASYNC      ),
                .DATA_BITS      (DATA_BITS  ),
                .data_t         (data_t     ),
                .M_SYNC_FF      (M_SYNC_FF  ),
                .S_SYNC_FF      (S_SYNC_FF  ),
                .DEVICE         (DEVICE     ),
                .SIMULATION     (SIMULATION ),
                .DEBUG          (DEBUG      )
            )
        u_data_async
            (
                .s_reset        ,
                .s_clk          ,
                .s_cke          ,
                .s_data         ,
                .s_valid        ,
                .s_ready        ,

                .m_reset        ,
                .m_clk          ,
                .m_cke          ,
                .m_data         ,
                .m_valid        ,
                .m_ready        
            );

    
    // write
    data_t      reg_data;
    logic       reg_valid;
    always_ff @(posedge s_clk) begin
        if ( s_reset ) begin
            reg_data  <= 0;
            reg_valid <= 1'b0;
        end
        else if ( s_cke ) begin
            if ( !(s_valid && !s_ready) ) begin
                reg_valid <= 1'($random);
            end
            
            if ( s_valid && s_ready ) begin
                reg_data <= reg_data + 1'b1;
            end
        end
    end
    assign s_data  = reg_data;
    assign s_valid = reg_valid;
    

    // read
    int     fp;
    initial begin
        fp = $fopen("log.txt", "w");
    end
    
    data_t      reg_expectation_value;
    logic       reg_ready;
    always_ff @(posedge m_clk) begin
        if ( m_reset ) begin
            reg_expectation_value  <= 0;
            reg_ready              <= 1'b0;
        end
        else if ( m_cke ) begin
            reg_ready <= 1'($random);
            
            if ( m_valid && m_ready ) begin
                $fdisplay(fp, "%h %h", m_data, reg_expectation_value);
                if ( m_data != reg_expectation_value ) begin
                    $display("error! %h expect:%h", m_data, reg_expectation_value);
                end
                
                reg_expectation_value <= reg_expectation_value + 1'b1;
            end
        end
    end
    assign m_ready = reg_ready;
    
    /*
    covergroup cg_port (input logic clk, input logic valid, input logic ready, input logic [7:0] data) @(posedge clk);
        cp1: coverpoint valid { bins non_valid = {0}; bins valid = {1}; }
        cp2: coverpoint ready { bins non_ready = {0}; bins ready = {1}; }
        cp3: coverpoint data  { bins min_val = {0}; bins middle_val = {[1:254]}; bins max_val = {255}; }
        cross cp1, cp2, cp3 {
            ignore_bins invalid_data = binsof(cp1.non_valid);
        }
    endgroup
    cg_port cg_slave  = new(.clk(s_clk), .valid(s_valid), .ready(s_ready), .data(s_data));
    cg_port cg_master = new(.clk(m_clk), .valid(m_valid), .ready(m_ready), .data(m_data));
    */

    /*
    covergroup cg_port (input logic valid, input logic ready, input logic [7:0] data);
        cp1: coverpoint valid { bins non_valid = {0}; bins valid = {1}; }
        cp2: coverpoint ready { bins non_ready = {0}; bins ready = {1}; }
        cp3: coverpoint data  { bins min_val = {0}; bins middle_val = {[1:254]}; bins max_val = {255}; }
        cross cp1, cp2, cp3 {
            ignore_bins invalid_data = binsof(cp1.non_valid);
        }
    endgroup
    cg_port cg_slave  = new(.valid(s_valid), .ready(s_ready), .data(s_data));
    cg_port cg_master = new(.valid(m_valid), .ready(m_ready), .data(m_data));
    always @(posedge s_clk) cg_slave.sample();
    always @(posedge m_clk) cg_master.sample();
    */

    covergroup cg_slave_port @(posedge s_clk);
        cp1: coverpoint s_valid { bins non_valid = {0}; bins valid = {1}; }
        cp2: coverpoint s_ready { bins non_ready = {0}; bins ready = {1}; }
        cp3: coverpoint s_data  { bins min_val = {0}; bins middle_val = {[1:254]}; bins max_val = {255}; }
        cross cp1, cp2, cp3 {
            ignore_bins invalid_data = binsof(cp1.non_valid);
        }
    endgroup
    cg_slave_port cg_slave  = new();

    covergroup cg_master_port @(posedge m_clk);
        cp1: coverpoint m_valid { bins non_valid = {0}; bins valid = {1}; }
        cp2: coverpoint m_ready { bins non_ready = {0}; bins ready = {1}; }
        cp3: coverpoint m_data  { bins min_val = {0}; bins middle_val = {[1:254]}; bins max_val = {255}; }
        cross cp1, cp2, cp3 {
            ignore_bins invalid_data = binsof(cp1.non_valid);
        }
    endgroup
    cg_master_port cg_master  = new();
    
endmodule


`default_nettype wire

// end of file
