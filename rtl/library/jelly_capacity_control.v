// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// コマンド等の発行量管理
module jelly_capacity_control
        #(
            parameter   CAPACITY_WIDTH = 16,
            parameter   REQUEST_WIDTH  = CAPACITY_WIDTH,
            parameter   CHARGE_WIDTH   = CAPACITY_WIDTH,
            parameter   ISSUE_WIDTH    = CAPACITY_WIDTH,
            
            parameter   INIT_CAPACITY  = {CAPACITY_WIDTH{1'b0}},
            parameter   INIT_REQUEST   = {CAPACITY_WIDTH{1'b0}},
            
            parameter   S_REQUEST_REGS = 1,
            parameter   S_CHARGE_REGS  = 1,
            parameter   M_ISSUE_REGS   = 1,
            
            parameter   M_REQUEST_REGS = 1,
            parameter   M_CHARGE_REGS  = 1,
            parameter   S_ISSUE_REGS   = 1
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,
            
            output  wire    [CAPACITY_WIDTH-1:0]    current_capacity,
            output  wire    [CAPACITY_WIDTH-1:0]    queued_request,
            
            input   wire    [CHARGE_WIDTH-1:0]      s_charge_size,
            input   wire                            s_charge_valid,
            output  wire                            s_charge_ready,
            
            input   wire    [REQUEST_WIDTH-1:0]     s_request_size,
            input   wire                            s_request_valid,
            output  wire                            s_request_ready,
            
            output  wire    [ISSUE_WIDTH-1:0]       m_issue_size,
            output  wire                            m_issue_valid,
            input   wire                            m_issue_ready
        );
    
    
    // ---------------------------------
    //  Insert FF
    // ---------------------------------
    
    wire    [REQUEST_WIDTH-1:0]     ff_request_size;
    wire                            ff_request_valid;
    wire                            ff_request_ready;
    
    wire    [CHARGE_WIDTH-1:0]      ff_charge_size;
    wire                            ff_charge_valid;
    wire                            ff_charge_ready;
    
    wire    [ISSUE_WIDTH-1:0]       ff_issue_size;
    wire                            ff_issue_valid;
    wire                            ff_issue_ready;
    
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH         (REQUEST_WIDTH),
                .SLAVE_REGS         (S_REQUEST_REGS),
                .MASTER_REGS        (M_REQUEST_REGS)
            )
        i_pipeline_insert_ff_request
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data             (s_request_size),
                .s_valid            (s_request_valid),
                .s_ready            (s_request_ready),
                
                .m_data             (ff_request_size),
                .m_valid            (ff_request_valid),
                .m_ready            (ff_request_ready),
                
                .buffered           (),
                .s_ready_next       ()
            );
    
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH         (CHARGE_WIDTH),
                .SLAVE_REGS         (S_CHARGE_REGS),
                .MASTER_REGS        (M_CHARGE_REGS)
            )
        i_pipeline_insert_ff_charge
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data             (s_charge_size),
                .s_valid            (s_charge_valid),
                .s_ready            (s_charge_ready),
                
                .m_data             (ff_charge_size),
                .m_valid            (ff_charge_valid),
                .m_ready            (ff_charge_ready),
                
                .buffered           (),
                .s_ready_next       ()
            );
    
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH         (ISSUE_WIDTH),
                .SLAVE_REGS         (S_ISSUE_REGS),
                .MASTER_REGS        (M_ISSUE_REGS)
            )
        i_pipeline_insert_ff_issue
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data             (ff_issue_size),
                .s_valid            (ff_issue_valid),
                .s_ready            (ff_issue_ready),
                
                .m_data             (m_issue_size),
                .m_valid            (m_issue_valid),
                .m_ready            (m_issue_ready),
                
                .buffered           (),
                .s_ready_next       ()
            );
    
    
    
    // ---------------------------------
    //  Core
    // ---------------------------------
    
    reg     [CAPACITY_WIDTH-1:0]    reg_capacity, next_capacity;
    reg     [CAPACITY_WIDTH-1:0]    reg_request,  next_request;
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_capacity <= INIT_CAPACITY;
            reg_request  <= INIT_REQUEST;
        end
        else if ( cke && (!ff_issue_valid || ff_issue_ready) ) begin
            reg_capacity <= next_capacity;
            reg_request  <= next_request;
        end
    end
    
    always @* begin
        next_capacity = reg_capacity;
        if ( ff_charge_valid && ff_charge_ready ) begin
            next_capacity = next_capacity + ff_charge_size;
        end
        if ( ff_issue_valid && ff_issue_ready ) begin
            next_capacity = next_capacity - ff_issue_size;
        end
        
        next_request = reg_request;
        if ( ff_request_valid && ff_request_ready ) begin
            next_request = next_request + ff_request_size;
        end
        if ( ff_issue_valid && ff_issue_ready ) begin
            next_request = next_request - ff_issue_size;
        end
    end
    
    assign current_capacity = reg_capacity;
    assign queued_request   = reg_request;
    
    wire    [CAPACITY_WIDTH-1:0]    max_issue_size = {ISSUE_WIDTH{1'b1}};
    reg     [CAPACITY_WIDTH-1:0]    tmp_issue_size;
    reg     [ISSUE_WIDTH-1:0]       next_issue_size;
    reg                             next_issue_valid;
    always @* begin
        next_issue_size  = {ISSUE_WIDTH{1'bx}};
        next_issue_valid = 1'b0;
        
        tmp_issue_size   = (reg_request <= reg_capacity) ? reg_request : reg_capacity;
        next_issue_size  = (tmp_issue_size <= max_issue_size) ? tmp_issue_size : max_issue_size;
        next_issue_valid = (reg_request > 0 && reg_request > 0);
    end
    
    assign ff_issue_size    = next_issue_size;
    assign ff_issue_valid   = next_issue_valid;
    
    assign ff_charge_ready  = (!ff_issue_valid || ff_issue_ready);
    assign ff_request_ready = (!ff_issue_valid || ff_issue_ready);
    
endmodule


`default_nettype wire


// end of file
