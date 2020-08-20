// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
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
            parameter   INIT_REQUEST   = {CAPACITY_WIDTH{1'b0}}
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,
            
            input   wire    [ISSUE_WIDTH-1:0]       max_issue_size,
            
            output  wire    [CAPACITY_WIDTH-1:0]    current_capacity,
            output  wire    [CAPACITY_WIDTH-1:0]    queued_request,
            
            input   wire    [REQUEST_WIDTH-1:0]     s_request_size,
            input   wire                            s_request_valid,
            
            input   wire    [CHARGE_WIDTH-1:0]      s_charge_size,
            input   wire                            s_charge_valid,
            
            output  wire    [ISSUE_WIDTH-1:0]       m_issue_size,
            output  wire                            m_issue_valid,
            input   wire                            m_issue_ready
        );
    
    wire                            ready;
    
    reg     [CAPACITY_WIDTH-1:0]    reg_request_size;
    reg     [CAPACITY_WIDTH-1:0]    reg_charge_size;
    
    reg     [CAPACITY_WIDTH-1:0]    reg_queued_request;
    reg     [CAPACITY_WIDTH-1:0]    reg_current_capacity;
    
    reg     [CAPACITY_WIDTH-1:0]    tmp_issue_size;
    reg     [ISSUE_WIDTH-1:0]       reg_issue_size;
    reg                             reg_issue_valid;
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_request_size     <= {CAPACITY_WIDTH{1'b0}};
            reg_charge_size      <= {CAPACITY_WIDTH{1'b0}};
            
            reg_queued_request   <= INIT_REQUEST;
            reg_current_capacity <= INIT_CAPACITY;
            
            reg_issue_size       <= {ISSUE_WIDTH{1'bx}};
            reg_issue_valid      <= 1'b0;
        end
        else if ( cke ) begin
            // queue input
            reg_request_size <= (ready ? {CAPACITY_WIDTH{1'b0}} : reg_request_size) + (s_request_valid ? s_request_size : {CAPACITY_WIDTH{1'b0}});
            reg_charge_size  <= (ready ? {CAPACITY_WIDTH{1'b0}} : reg_charge_size ) + (s_charge_valid  ? s_charge_size  : {CAPACITY_WIDTH{1'b0}});
            
            // capacity control
            if ( ready ) begin
                reg_queued_request   <= reg_queued_request   + reg_charge_size  - reg_issue_size;
                reg_current_capacity <= reg_current_capacity + reg_request_size - reg_issue_size;
            end
            
            // issue
            tmp_issue_size = (reg_queued_request <= reg_current_capacity) ? reg_queued_request : reg_current_capacity;
            reg_issue_size  <= (tmp_issue_size <= max_issue_size) ? tmp_issue_size : max_issue_size;
            reg_issue_valid <= (reg_queued_request > 0 && reg_current_capacity > 0);
        end
    end
    
    assign ready = (!m_issue_valid || m_issue_ready);
    
    assign m_issue_size  = reg_issue_size;
    assign m_issue_valid = reg_issue_valid;
    
    assign current_capacity = reg_current_capacity;
    assign queued_request   = reg_queued_request;
    
endmodule


`default_nettype wire


// end of file
