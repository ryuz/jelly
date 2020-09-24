
`timescale 1ns / 1ps
`default_nettype none


module tb_stream_gate();
    localparam RATE = 1000.0/20.0;
    
    initial begin
        $dumpfile("tb_stream_gate.vcd");
        $dumpvars(0, tb_stream_gate);
        
        #1000000;
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
    
    reg                         skip = 0;           // 非busy時に読み飛ばす
    reg                         detect_first = 0;
    reg                         detect_last  = 0;
    reg                         padding_en   = 0;
    reg     [DATA_WIDTH-1:0]    padding_data = 32'haa55aa55;
    reg                         padding_skip = 0;
    
    reg     [LEN_WIDTH-1:0]     s_permit_len;
    reg                         s_permit_valid;
    wire                        s_permit_ready;
    
    wire                        s_first = (s_data[2:0] == 3'b000);
    wire                        s_last  = (s_data[2:0] == 3'b111);
    reg     [DATA_WIDTH-1:0]    s_data;
    reg                         s_valid;
    wire                        s_ready;
    
    wire                        m_first;
    wire                        m_last;
    wire    [DATA_WIDTH-1:0]    m_data;
    wire                        m_valid;
    reg                         m_ready;
    
    
    
    jelly_stream_gate
            #(
                .DATA_WIDTH     (DATA_WIDTH),
                .LEN_WIDTH      (LEN_WIDTH),
                .LEN_OFFSET     (LEN_OFFSET),
                .S_PERMIT_REGS  (S_PERMIT_REGS),
                .S_REGS         (S_REGS),
                .M_REGS         (M_REGS)
            )
        i_stream_gate
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .skip           (skip),
                .detect_first   (detect_first),
                .detect_last    (detect_last),
                .padding_en     (padding_en),
                .padding_data   (padding_data),
                .padding_skip   (padding_skip),
                
                .s_permit_len   (s_permit_len),
                .s_permit_valid (s_permit_valid),
                .s_permit_ready (s_permit_ready),
                
                .s_first        (s_first),
                .s_last         (s_last),
                .s_data         (s_data),
                .s_valid        (s_valid),
                .s_ready        (s_ready),
                
                .m_first        (m_first),
                .m_last         (m_last),
                .m_data         (m_data),
                .m_valid        (m_valid),
                .m_ready        (m_ready)
            );
    
    initial begin
            s_permit_valid = 0;
    #10000;
        @(posedge clk)
            skip           <= 0;
            detect_first   <= 0;
            detect_last    <= 1;
            padding_en     <= 0;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 0;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        
        @(posedge clk)
            skip           <= 0;
            detect_first   <= 0;
            detect_last    <= 1;
            padding_en     <= 0;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 6;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        
        @(posedge clk)
            skip           <= 0;
            detect_first   <= 0;
            detect_last    <= 1;
            padding_en     <= 0;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 7;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        
        @(posedge clk)
            skip           <= 0;
            detect_first   <= 0;
            detect_last    <= 1;
            padding_en     <= 0;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 8;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        
        @(posedge clk)
            skip           <= 0;
            detect_first   <= 0;
            detect_last    <= 1;
            padding_en     <= 1;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 8;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        
        @(posedge clk)
            skip           <= 0;
            detect_first   <= 0;
            detect_last    <= 1;
            padding_en     <= 0;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 8;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        
        // first
        @(posedge clk)
            skip           <= 0;
            detect_first   <= 1;
            detect_last    <= 0;
            padding_en     <= 0;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 8;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        @(posedge clk)
            skip           <= 0;
            detect_first   <= 1;
            detect_last    <= 0;
            padding_en     <= 0;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 3;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        
        // none
        @(posedge clk)
            skip           <= 0;
            detect_first   <= 0;
            detect_last    <= 0;
            padding_en     <= 0;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 8;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        @(posedge clk)
            skip           <= 0;
            detect_first   <= 0;
            detect_last    <= 0;
            padding_en     <= 0;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 3;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        // skip
        @(posedge clk)
            skip           <= 1;
            detect_first   <= 1;
            detect_last    <= 1;
            padding_en     <= 1;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 11;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        // skip
        @(posedge clk)
            skip           <= 0;
            detect_first   <= 1;
            detect_last    <= 1;
            padding_en     <= 1;
            padding_data   <= 32'haa55aa55;
            s_permit_len   <= 4;
            s_permit_valid <= 1;
        while ( !(s_permit_valid && s_permit_ready) )
            @(posedge clk);
            s_permit_valid <= 0;
        #10000;
        
        $finish();
    end
    
    
    always @(posedge clk) begin
        if ( reset ) begin
            s_data   <= 0;
            s_valid  <= 0;
            m_ready  <= 0;
        end
        else if ( cke ) begin
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
