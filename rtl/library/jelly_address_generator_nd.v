// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_address_generator_nd
        #(
            parameter N          = 3,
            parameter ADDR_WIDTH = 32,
            parameter STEP_WIDTH = 32,
            parameter LEN_WIDTH  = 32,
            parameter LEN_OFFSET = 1'b1,
            parameter USER_WIDTH = 0,
            parameter S_REGS     = 0,
            
            // loacal
            parameter USER_BITS  = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire    [ADDR_WIDTH-1:0]    s_addr,
            input   wire    [N*STEP_WIDTH-1:0]  s_step,
            input   wire    [N*LEN_WIDTH-1:0]   s_len,
            input   wire    [USER_BITS-1:0]     s_user,
            input   wire                        s_valid,
            output  wire                        s_ready,
            
            output  wire    [ADDR_WIDTH-1:0]    m_addr,
            output  wire    [N-1:0]             m_first,
            output  wire    [N-1:0]             m_last,
            output  wire    [USER_BITS-1:0]     m_user,
            output  wire                        m_valid,
            input   wire                        m_ready
        );
    
    
    // insert FF
    wire    [ADDR_WIDTH-1:0]    ff_s_addr;
    wire    [N*STEP_WIDTH-1:0]  ff_s_step;
    wire    [N*LEN_WIDTH-1:0]   ff_s_len;
    wire    [USER_BITS-1:0]     ff_s_user;
    wire                        ff_s_valid;
    wire                        ff_s_ready;
    
    jelly_data_ff_pack
        #(
            .DATA0_WIDTH    (ADDR_WIDTH),
            .DATA1_WIDTH    (N*STEP_WIDTH),
            .DATA2_WIDTH    (N*LEN_WIDTH),
            .DATA3_WIDTH    (USER_WIDTH),
            .S_REGS         (S_REGS),
            .M_REGS         (S_REGS)
        )
    jelly_data_ff_pack
        (
            .reset          (reset),
            .clk            (clk),
            .cke            (cke),
            
            .s_data0        (s_addr),
            .s_data1        (s_step),
            .s_data2        (s_len),
            .s_data3        (s_user),
            .s_valid        (s_valid),
            .s_ready        (s_ready),
            
            .m_data0        (ff_s_addr),
            .m_data1        (ff_s_step),
            .m_data2        (ff_s_len),
            .m_data3        (ff_s_user),
            .m_valid        (ff_s_valid),
            .m_ready        (ff_s_ready)
        );
    
    
    // core
    integer                         i;
    reg                             tmp_last;
    
    reg     [N*ADDR_WIDTH-1:0]      reg_addr;
    reg     [N*LEN_WIDTH-1:0]       reg_len;
    reg     [N-1:0]                 reg_first;
    reg     [N-1:0]                 reg_last;
    reg     [USER_BITS-1:0]         reg_user;
    reg                             reg_valid;
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_addr  <= {(N*ADDR_WIDTH){1'bx}};
            reg_len   <= {(N*LEN_WIDTH){1'bx}};
            reg_first <= {N{1'bx}};
            reg_last  <= {N{1'bx}};
            reg_user  <= {USER_BITS{1'bx}};
            reg_valid <= 1'b0;
        end
        else if ( cke ) begin
            if ( !reg_valid && ff_s_valid ) begin
                // start
                tmp_last = 1'b1;
                for ( i = 0; i < N; i = i+1 ) begin
                    reg_addr [i*ADDR_WIDTH +: ADDR_WIDTH] <= ff_s_addr;
                    reg_len  [i*LEN_WIDTH  +: LEN_WIDTH ] <= ff_s_len [i*LEN_WIDTH  +: LEN_WIDTH] - (1'b1 - LEN_OFFSET);
                    reg_first[i] <= 1'b1;
                    tmp_last      = tmp_last && ((ff_s_len [i*LEN_WIDTH  +: LEN_WIDTH] - (1'b1 - LEN_OFFSET)) == 0);
                    reg_last [i] <= tmp_last;
                end
                reg_user  <= ff_s_user;
                reg_valid <= 1'b1;
            end
            else if ( m_valid && m_ready ) begin
                // next
                tmp_last = 1'b1;
                for ( i = 0; i < N; i = i+1 ) begin
                    reg_first[i] <= 1'b0;
                    if ( tmp_last ) begin
                        tmp_last = reg_last[i];
                        reg_addr[i*LEN_WIDTH +: LEN_WIDTH] <= reg_addr[i*LEN_WIDTH +: LEN_WIDTH] + ff_s_step[i*STEP_WIDTH +: STEP_WIDTH];
                        reg_len[i*LEN_WIDTH +: LEN_WIDTH]  <= reg_len[i*LEN_WIDTH +: LEN_WIDTH] - 1'b1;
                        reg_last[i]                        <= (reg_len[i*LEN_WIDTH +: LEN_WIDTH] - 1'b1) == 0;
                        if ( reg_last[i] ) begin
                            if ( i == N-1 ) begin
                                // end
                                reg_addr  <= {(N*ADDR_WIDTH){1'bx}};
                                reg_len   <= {(N*LEN_WIDTH){1'bx}};
                                reg_first <= {N{1'bx}};
                                reg_last  <= {N{1'bx}};
                                reg_user  <= {USER_BITS{1'bx}};
                                reg_valid <= 1'b0;
                            end
                            else begin
                                reg_addr [i*LEN_WIDTH +: LEN_WIDTH] <= reg_addr[(i+1)*LEN_WIDTH +: LEN_WIDTH] + ff_s_step[(i+1)*STEP_WIDTH +: STEP_WIDTH];
                                reg_len  [i*LEN_WIDTH +: LEN_WIDTH] <= ff_s_len [i*LEN_WIDTH  +: LEN_WIDTH] - (1'b1 - LEN_OFFSET);
                                reg_first[i]                        <= 1'b1;
                                reg_last [i]                        <= (ff_s_len [i*LEN_WIDTH  +: LEN_WIDTH] - (1'b1 - LEN_OFFSET)) == 0;
                            end
                        end
                    end
                end
            end
        end
    end
    
    
    reg     [N-1:0] reg_last_out;
    always @* begin
        reg_last_out[0] = reg_last[0];
        for ( i = 1; i < N; i = i+1 ) begin
            reg_last_out[i] = reg_last[i] & reg_last_out[i-1];
        end
    end
    
    
    assign ff_s_ready  = m_valid && m_ready && &m_last;
    
    assign m_addr      = reg_addr;
    assign m_first     = reg_first;
    assign m_last      = reg_last_out;
    assign m_user      = reg_user;
    assign m_valid     = reg_valid;
    
endmodule


`default_nettype wire


// end of file
