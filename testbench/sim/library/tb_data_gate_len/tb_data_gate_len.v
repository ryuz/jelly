
`timescale 1ns / 1ps
`default_nettype none


module tb_data_gate_len();
    localparam RATE = 1000.0/20.0;
    
    initial begin
        $dumpfile("tb_data_gate_len.vcd");
        $dumpvars(0, tb_data_gate_len);
        
        #100000;
            $finish;
    end
    
    
    parameter   RAND_BUSY = 1;
    
    
    reg     clk = 1'b1;
    always #(RATE/2.0)    clk   = ~clk;
    
    reg     reset = 1'b1;
    initial #(RATE*100)   reset = 1'b0;
    
    reg     cke = 1'b1;
    always @(posedge clk) cke <= 1; // RAND_BUSY ? {$random()} : 1'b1;
    
    
    parameter   DATA_WIDTH    = 32;
    parameter   LEN_WIDTH     = 32;
    parameter   LEN_OFFSET    = 1'b1;
    
    parameter   S_PERMIT_REGS = 1;
    parameter   S_REGS        = 1;
    parameter   M_REGS        = 1;
    
    
    reg     [LEN_WIDTH-1:0]     s_permit_len;
    wire                        s_permit_first = 1;//(s_permit_len == 3);
    wire                        s_permit_last  = 1;//(s_permit_len == 4);
    reg                         s_permit_valid;
    wire                        s_permit_ready;
    
    reg     [DATA_WIDTH-1:0]    s_data;
    reg                         s_valid;
    wire                        s_ready;
    
    wire                        m_first;
    wire                        m_last;
    wire    [DATA_WIDTH-1:0]    m_data;
    wire                        m_valid;
    reg                         m_ready;
    
    
    
    jelly_data_gate_len
            #(
                .DATA_WIDTH     (DATA_WIDTH),
                .LEN_WIDTH      (LEN_WIDTH),
                .LEN_OFFSET     (LEN_OFFSET),
                .S_PERMIT_REGS  (S_PERMIT_REGS),
                .S_REGS         (S_REGS),
                .M_REGS         (M_REGS)
            )
        i_data_gate_len
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_permit_len   (s_permit_len),
                .s_permit_first (s_permit_first),
                .s_permit_last  (s_permit_last),
                .s_permit_valid (s_permit_valid),
                .s_permit_ready (s_permit_ready),
                
                .s_data         (s_data),
                .s_valid        (s_valid),
                .s_ready        (s_ready),
                
                .m_first        (m_first),
                .m_last         (m_last),
                .m_data         (m_data),
                .m_valid        (m_valid),
                .m_ready        (m_ready)
            );
    
    reg     reg_en;
    always @(posedge clk) begin
        if ( reset ) begin
            reg_en   <= 1'b1;
            
            s_permit_len   <= 0;
            s_permit_valid <= 0;
            
            s_data   <= 0;
            s_valid  <= 0;
            m_ready  <= 0;
        end
        else if ( cke ) begin
            
            if ( s_permit_ready ) begin
                s_permit_valid <= (RAND_BUSY ? {$random()} : 1'b1) & reg_en;
            end
            
            if ( s_permit_ready & s_permit_valid ) begin
                if ( s_permit_len > 7 ) begin
                    reg_en <= 1'b0;
                end
                else begin
                    s_permit_len <= s_permit_len + 1;
                end
            end
            
            
            if ( s_ready ) begin
                s_valid <= (RAND_BUSY ? {$random()} : 1'b1);
            end
            
            if ( s_ready & s_valid ) begin
                s_data <= s_data + 1;
            end
            
            m_ready <= (RAND_BUSY ? {$random()} : 1'b1);
        end
    end
    
    integer fp;
    initial begin
        fp = $fopen("out.txt", "w");
    end
    
    always @(posedge clk) begin
        if ( reset ) begin
        end
        else if ( cke ) begin
            if ( m_valid && m_ready ) begin
                $fdisplay(fp, "%h %b %b", m_data, m_first, m_last);
            end
        end
    end
    
    
    
endmodule


`default_nettype wire


// end of file
