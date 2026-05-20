// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// 発行コマンドサイズ管理
module jelly3_capacity_size
        #(
            parameter   int     CAPACITY_BITS = 32                          ,
            parameter   type    capacity_t    = logic [CAPACITY_BITS-1:0]   ,
            parameter   int     USER_BITS     = 1                           ,
            parameter   type    user_t        = logic [USER_BITS-1:0]       ,
            parameter   int     SIZE_BITS     = 8                           ,
            parameter   type    size_t        = logic [SIZE_BITS-1:0]       ,
            parameter   bit     SIZE_OFFSET   = 1'b0                        ,
            parameter   int     CHARGE_BITS   = CAPACITY_BITS               ,
            parameter   type    charge_t      = logic [CHARGE_BITS-1:0]     ,
            parameter   bit     CHARGE_OFFSET = 1'b0                        ,
            parameter   bit     S_REG         = 1                           ,
            parameter   bit     M_REG         = 1              
        )
        (
            input   var logic       reset           ,
            input   var logic       clk             ,
            input   var logic       cke             ,
            
            input   var capacity_t  initial_capacity,
            output  var capacity_t  current_capacity,
            
            input   var charge_t    s_charge_size   ,
            input   var logic       s_charge_valid  ,
            
            input   var user_t      s_cmd_user      ,
            input   var size_t      s_cmd_size      ,
            input   var logic       s_cmd_valid     ,
            output  var logic       s_cmd_ready     ,
            
            output  var user_t      m_cmd_user      ,
            output  var size_t      m_cmd_size      ,
            output  var logic       m_cmd_valid     ,
            input   var logic       m_cmd_ready
        );
    
    // insert FF
    typedef struct packed {
        user_t  user;
        size_t  size;
    } cmd_t;


    user_t      ff_s_user ;
    size_t      ff_s_size ;
    logic       ff_s_valid;
    logic       ff_s_ready;

    jelly3_stream_ff
            #(
                .data_t     (cmd_t),
                .S_REG      (S_REG),
                .M_REG      (S_REG)
            )
        u_stream_ff_s
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data             ('{
                                        s_cmd_user,
                                        s_cmd_size
                                    }),
                .s_valid            (s_cmd_valid),
                .s_ready            (s_cmd_ready),
                
                .m_data             ('{
                                        ff_s_user    ,
                                        ff_s_size
                                    }),
                .m_valid            (ff_s_valid),
                .m_ready            (ff_s_ready)
            );


    // recieve request
    user_t      rx_user;
    size_t      rx_size;
    capacity_t  rx_issue;
    logic       rx_valid;
    logic       rx_ready;
    generate
    if ( S_REG ) begin : rx_reg
        user_t      reg_rx_user;
        size_t      reg_rx_size;
        capacity_t  reg_rx_issue;
        logic       reg_rx_valid;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_rx_user  <= {USER_BITS{1'bx}};
                reg_rx_size  <= {SIZE_BITS{1'bx}};
                reg_rx_issue <= {CAPACITY_BITS{1'b0}};
                reg_rx_valid <= 1'b0;
            end
            else if ( cke && ff_s_ready ) begin
                reg_rx_user  <= ff_s_user;
                reg_rx_size  <= ff_s_size;
                reg_rx_issue <= ff_s_valid ? (CAPACITY_BITS'({1'b0, ff_s_size}) + CAPACITY_BITS'(SIZE_OFFSET)) : 0;
                reg_rx_valid <= ff_s_valid;
            end
        end
        assign ff_s_ready = (!rx_valid || rx_ready);
        assign rx_user    = reg_rx_user;
        assign rx_size    = reg_rx_size;
        assign rx_issue   = reg_rx_issue;
        assign rx_valid   = reg_rx_valid;
    end
    else begin : rx_bypass
        assign ff_s_ready = rx_ready;
        assign rx_user    = ff_s_user;
        assign rx_size    = ff_s_size;
        assign rx_issue   = ff_s_valid ? ({1'b0, ff_s_size} + SIZE_OFFSET) : 0;
        assign rx_valid   = ff_s_valid;
    end
    endgenerate
    
    
    // capacity control
    charge_t    reg_charge;
    
    capacity_t  reg_capacity;
    capacity_t  reg_capacity_sub;
    logic       reg_select_sub;
    
    logic                         issue_enable;
    assign issue_enable = (current_capacity >= rx_issue);
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_charge       <= initial_capacity;
            
            reg_capacity     <= {CAPACITY_BITS{1'b0}};
            reg_capacity_sub <= {CAPACITY_BITS{1'bx}};
            reg_select_sub   <= 1'b0;
        end
        else if ( cke ) begin
            reg_charge       <= s_charge_valid ? (CAPACITY_BITS'({1'b0, s_charge_size}) + CAPACITY_BITS'(CHARGE_OFFSET)) : 0;
            
            reg_capacity     <= current_capacity + reg_charge;
            reg_capacity_sub <= current_capacity + reg_charge - rx_issue;
            reg_select_sub   <= issue_enable && rx_ready;
        end
    end
    
    assign current_capacity = reg_select_sub ? reg_capacity_sub : reg_capacity;
    
    
    
    // transmit command
    user_t      tx_user;
    size_t      tx_size;
    logic       tx_valid;
    logic       tx_ready;
    
    
    assign rx_ready     = tx_ready && issue_enable;
    
    assign tx_user      = rx_user;
    assign tx_size      = rx_size;
    assign tx_valid     = rx_valid && issue_enable;
    
    jelly3_stream_ff
            #(
                .data_t     (cmd_t),
                .S_REG      (M_REG),
                .M_REG      (M_REG)
            )
        u_stream_ff_m
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data            ('{tx_user,
                                    tx_size}),
                .s_valid            (tx_valid),
                .s_ready            (tx_ready),
                
                .m_data            ('{m_cmd_user,
                                        m_cmd_size
                                 }),
                .m_valid            (m_cmd_valid),
                .m_ready            (m_cmd_ready)
            );
    
    
endmodule


`default_nettype wire


// end of file
