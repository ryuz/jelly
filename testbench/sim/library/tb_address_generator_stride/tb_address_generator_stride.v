
`timescale 1ns / 1ps
`default_nettype none


module tb_address_generator_stride();
    localparam RATE = 1000.0/20.0;
    
    initial begin
        $dumpfile("tb_address_generator_stride.vcd");
        $dumpvars(0, tb_address_generator_stride);
        
        #10000;
            $finish;
    end
    
    
    parameter   RAND_BUSY = 0;
    
    
    reg     clk = 1'b1;
    always #(RATE/2.0)    clk   = ~clk;
    
    reg     reset = 1'b1;
    initial #(RATE*100)   reset = 1'b0;
    
    reg     cke = 1'b1;
    always @(posedge clk) cke <= RAND_BUSY ? {$random()} : 1'b1;
    
    
    parameter   ADDR_WIDTH   = 32;
    parameter   STRIDE_WIDTH = 32;
    parameter   LEN_WIDTH    = 32;
    parameter   COUNT_WIDTH  = 32;
    parameter   USER_WIDTH   = 0;
    parameter   COUNT_OFFSET = 1'b1;
    parameter   USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1;
    
    reg     [ADDR_WIDTH-1:0]    s_addr   = 32'h0001000;
    reg     [STRIDE_WIDTH-1:0]  s_stride = 32'h0000100;
    reg     [LEN_WIDTH-1:0]     s_len    = 3;
    reg     [COUNT_WIDTH-1:0]   s_count  = 3;
    reg     [USER_BITS-1:0]     s_user   = 0;
    reg                         s_valid  = 1;
    wire                        s_ready;
    
    wire    [ADDR_WIDTH-1:0]    m_addr;
    wire    [LEN_WIDTH-1:0]     m_len;
    wire                        m_first;
    wire                        m_last;
    wire    [USER_BITS-1:0]     m_user;
    wire                        m_valid;
    reg                         m_ready = 1;
    
    jelly_address_generator_stride
            #(
                .ADDR_WIDTH     (ADDR_WIDTH),
                .STRIDE_WIDTH   (STRIDE_WIDTH),
                .LEN_WIDTH      (LEN_WIDTH),
                .COUNT_WIDTH    (COUNT_WIDTH),
                .USER_WIDTH     (USER_WIDTH),
                .COUNT_OFFSET   (COUNT_OFFSET)
            )
        i_address_generator_stride
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_addr         (s_addr),
                .s_stride       (s_stride),
                .s_len          (s_len),
                .s_count        (s_count),
                .s_user         (s_user),
                .s_valid        (s_valid),
                .s_ready        (s_ready),
                
                .m_addr         (m_addr),
                .m_len          (m_len),
                .m_first        (m_first),
                .m_last         (m_last),
                .m_user         (m_user),
                .m_valid        (m_valid),
                .m_ready        (m_ready)
            );
    
    /*
    localparam  TEST_NUM = 257;
    integer     i = 0;
    integer     exp_i = 0;
    integer     count_s_size  = 0;
    integer     count_m_size  = 0;
    integer     count_m_exp   = 0;
    reg         err = 0;
    always @(posedge clk) begin
        if ( reset ) begin
            i        = 0;
            s_valid <= 0;
            m_ready <= 0;
        end
        else if ( cke ) begin
            if ( s_ready ) begin
                s_valid <= 1'b0;
                
                i = i + s_valid;
                if ( i < TEST_NUM ) begin
                    s_addr    <= i * 256;
                    s_size    <= i + 1 - SIZE_OFFSET;
                    s_max_len <= i;
                    s_valid   <= RAND_BUSY ? {$random()} : 1'b1;
                end
            end
            
            m_ready <= RAND_BUSY ? {$random()} : 1'b1;
            
            
            if ( s_valid && s_ready ) begin
                count_s_size <= count_s_size + s_size + SIZE_OFFSET;
            end
            
            if ( m_valid && m_ready ) begin
                count_m_size <= count_m_size + m_len + LEN_OFFSET;
                if ( m_last ) begin
                    exp_i       <= exp_i + 1;
                    count_m_exp <= count_m_exp + (exp_i + 1);
                    if ( (count_m_size + m_len + LEN_OFFSET) != (count_m_exp + (exp_i + 1)) ) begin
                        err <= 1;
                        $display("error");
                    end
                end
            end
        end
    end
    
    initial begin
        #1000;
        while ( i < TEST_NUM ) begin
            #1000;
        end
        
        #(RATE*2000);
        if ( count_m_size != count_s_size ) begin
            $display("error");
        end
        else begin
            $display("OK");
        end
        $finish();
    end
    */
    
endmodule


`default_nettype wire


// end of file
