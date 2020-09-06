// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// 発行コマンドサイズ管理
module jelly_capacity_size
        #(
            parameter   CAPACITY_WIDTH     = 32,
            parameter   CMD_USER_WIDTH     = 0,
            parameter   CMD_SIZE_WIDTH     = 8,
            parameter   CMD_SIZE_OFFSET    = 1'b0,
            parameter   CHARGE_WIDTH       = CAPACITY_WIDTH,
            parameter   CHARGE_SIZE_OFFSET = 1'b0,
            parameter   S_REGS             = 1,
            
            // local
            parameter   CMD_USER_BITS      = CMD_USER_WIDTH > 0 ? CMD_USER_WIDTH : 1
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,
            
            input   wire    [CAPACITY_WIDTH-1:0]    initial_capacity,
            
            output  wire    [CAPACITY_WIDTH-1:0]    current_capacity,
            
            input   wire    [CHARGE_WIDTH-1:0]      s_charge_size,
            input   wire                            s_charge_valid,
            
            input   wire    [CMD_USER_BITS-1:0]     s_cmd_user,
            input   wire    [CMD_SIZE_WIDTH-1:0]    s_cmd_size,
            input   wire                            s_cmd_valid,
            output  wire                            s_cmd_ready,
            
            output  wire    [CMD_USER_BITS-1:0]     m_cmd_user,
            output  wire    [CMD_SIZE_WIDTH-1:0]    m_cmd_size,
            output  wire                            m_cmd_valid,
            input   wire                            m_cmd_ready
        );
    
    // insert FF
    wire    [CMD_USER_BITS-1:0]     ff_s_cmd_user;
    wire    [CMD_SIZE_WIDTH-1:0]    ff_s_cmd_size;
    wire                            ff_s_cmd_valid;
    wire                            ff_s_cmd_ready;
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH         (CMD_USER_BITS + CMD_SIZE_WIDTH ),
                .SLAVE_REGS         (S_REGS),
                .MASTER_REGS        (0)
            )
        i_pipeline_insert_ff_s
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data             ({s_cmd_user, s_cmd_size}),
                .s_valid            (s_cmd_valid),
                .s_ready            (s_cmd_ready),
                
                .m_data             ({ff_s_cmd_user, ff_s_cmd_size}),
                .m_valid            (ff_s_cmd_valid),
                .m_ready            (ff_s_cmd_ready),
                
                .buffered           (),
                .s_ready_next       ()
            );
    
    
    // capacity control
    reg     [CAPACITY_WIDTH-1:0]    reg_capacity,  next_capacity;
    reg     [CMD_USER_BITS-1:0]     reg_cmd_user,  next_cmd_user;
    reg     [CMD_SIZE_WIDTH-1:0]    reg_cmd_size,  next_cmd_size;
    reg                             reg_cmd_valid, next_cmd_valid;
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_capacity  <= initial_capacity;
            reg_cmd_user  <= {CMD_USER_BITS{1'bx}};
            reg_cmd_size  <= {CMD_SIZE_WIDTH{1'bx}};
            reg_cmd_valid <= 1'b0;
        end
        else if ( cke ) begin
            reg_capacity  <= next_capacity;
            reg_cmd_user  <= next_cmd_user;
            reg_cmd_size  <= next_cmd_size;
            reg_cmd_valid <= next_cmd_valid;
        end
    end
    
    always @* begin
        next_capacity  = reg_capacity;
        next_cmd_user  = reg_cmd_user;
        next_cmd_size  = reg_cmd_size;
        next_cmd_valid = reg_cmd_valid;
        
        if ( m_cmd_ready ) begin
            next_cmd_user  = {CMD_USER_BITS{1'bx}};
            next_cmd_size  = {CMD_SIZE_WIDTH{1'bx}};
            next_cmd_valid = 1'b0;
        end
        
        if ( ff_s_cmd_valid && ff_s_cmd_ready ) begin
            next_cmd_user  = ff_s_cmd_user;
            next_cmd_size  = ff_s_cmd_size;
            next_cmd_valid = 1'b1;
            
            next_capacity  = next_capacity - next_cmd_size - CMD_SIZE_OFFSET;
        end
        
        if ( s_charge_valid ) begin
            next_capacity  = next_capacity + s_charge_size + CHARGE_SIZE_OFFSET;
        end
    end
    
    assign ff_s_cmd_ready = (!m_cmd_valid || m_cmd_ready) && (ff_s_cmd_valid && (reg_capacity >= {1'b0, ff_s_cmd_size} + CMD_SIZE_OFFSET));
    
    assign m_cmd_user  = reg_cmd_user;
    assign m_cmd_size  = reg_cmd_size;
    assign m_cmd_valid = reg_cmd_valid;
    
    assign current_capacity = next_capacity;
    
    
    
    // debug (simulation only)
    integer     total_s_size;
    integer     total_m_size;
    integer     total_charge;
    always @(posedge clk) begin
        if ( reset ) begin
            total_s_size <= 0;
            total_m_size <= 0;
            total_charge <= 0;
        end
        else if ( cke ) begin
            if ( s_cmd_valid && s_cmd_valid ) begin
                total_s_size <= total_s_size + s_cmd_size + CMD_SIZE_OFFSET;
            end
            
            if ( m_cmd_valid && m_cmd_valid ) begin
                total_m_size <= total_m_size + m_cmd_size + CMD_SIZE_OFFSET;
            end
            
            if ( s_charge_valid ) begin
                total_charge <= total_charge + s_charge_size + CHARGE_SIZE_OFFSET;
            end
        end
    end
    
    
endmodule


`default_nettype wire


// end of file
