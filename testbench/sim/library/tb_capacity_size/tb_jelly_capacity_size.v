
`timescale 1ns / 1ps
`default_nettype none


module tb_jelly_capacity_size();
    localparam RATE = 1000.0/20.0;
    
    initial begin
        $dumpfile("tb_jelly_capacity_size.vcd");
        $dumpvars(0, tb_jelly_capacity_size);
        
        #1000000;
//          $finish;
    end
    
    parameter   BUSY = 0;
    
    
    reg     clk = 1'b1;
    always #(RATE/2.0)      clk = ~clk;
    
    reg     reset = 1'b1;
    initial #(RATE*100)     reset = 1'b0;
    
    reg     cke = 1'b1;
    always @(posedge clk)   cke <= BUSY ? {$random} : 1'b1;
    
    
    
    parameter   CAPACITY_WIDTH     = 32;
    parameter   CMD_USER_WIDTH     = 0;
    parameter   CMD_SIZE_WIDTH     = 8;
    parameter   CMD_SIZE_OFFSET    = 1'b0;
    parameter   CHARGE_WIDTH       = CAPACITY_WIDTH;
    parameter   CHARGE_SIZE_OFFSET = 1'b0;
    parameter   S_REGS             = 1;
    
    parameter   CMD_USER_BITS      = CMD_USER_WIDTH > 0 ? CMD_USER_WIDTH : 1;
    
    
    reg     [CAPACITY_WIDTH-1:0]    initial_capacity = 0;
    
    wire    [CAPACITY_WIDTH-1:0]    current_capacity;
    
    reg     [CHARGE_WIDTH-1:0]      s_charge_size;
    reg                             s_charge_valid;
    
    reg     [CMD_USER_BITS-1:0]     s_cmd_user;
    reg     [CMD_SIZE_WIDTH-1:0]    s_cmd_size;
    reg                             s_cmd_valid;
    wire                            s_cmd_ready;
    
    wire    [CMD_USER_BITS-1:0]     m_cmd_user;
    wire    [CMD_SIZE_WIDTH-1:0]    m_cmd_size;
    wire                            m_cmd_valid;
    reg                             m_cmd_ready;
    
    jelly_capacity_size
            #(
                .CAPACITY_WIDTH         (CAPACITY_WIDTH),
                .CMD_USER_WIDTH         (CMD_USER_WIDTH),
                .CMD_SIZE_WIDTH         (CMD_SIZE_WIDTH),
                .CMD_SIZE_OFFSET        (CMD_SIZE_OFFSET),
                .CHARGE_WIDTH           (CHARGE_WIDTH),
                .CHARGE_SIZE_OFFSET     (CHARGE_SIZE_OFFSET),
                .S_REGS                 (S_REGS)
            )
        i_capacity_size
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .initial_capacity       (initial_capacity),
                
                .current_capacity       (current_capacity),
                
                .s_charge_size          (s_charge_size),
                .s_charge_valid         (s_charge_valid),
                
                .s_cmd_user             (s_cmd_user),
                .s_cmd_size             (s_cmd_size),
                .s_cmd_valid            (s_cmd_valid),
                .s_cmd_ready            (s_cmd_ready),
                
                .m_cmd_user             (m_cmd_user),
                .m_cmd_size             (m_cmd_size),
                .m_cmd_valid            (m_cmd_valid),
                .m_cmd_ready            (m_cmd_ready)
            );
    
    
    integer     i = 0;
    
    integer     req_rate = 2;
    integer     chg_rate = 2;
    
    integer     counter_request = 0;
    integer     counter_charge  = 0;
    integer     counter_issue   = 0;
    
    always @(posedge clk) begin
        if ( reset ) begin
            s_cmd_size      <= 0;
            s_cmd_valid     <= 0;
            s_charge_size   <= 0;
            s_charge_valid  <= 0;
            m_cmd_ready     <= 0;
        end
        else if ( cke ) begin
            i = i + 1;
            if ( (i % 1000) < 800 ) begin
                s_cmd_size      <= {$random()} & 32'hff;
                s_cmd_valid     <= ({$random()} % req_rate == 0);
                s_charge_size   <= {$random()} & 32'hff;
                s_charge_valid  <= ({$random()} % chg_rate == 0);
                m_cmd_ready     <= {$random()};
            end
            else begin
                s_cmd_valid     <= 1'b0;
                s_charge_valid  <= 1'b0;
                m_cmd_ready     <= 1'b1;
            end
            
            if ( (i % 1000) == 990 ) begin
                /*
                $display("current_capacity = %d", current_capacity);
                if ( counter_issue + current_capacity == counter_charge
                  && counter_issue + queued_request   == counter_request ) begin
                    $display("OK");
                end
                else begin
                    $display("!!!!NG!!!!");
                    $stop();
                end
                */
                
                if ( (i / 1000) < 3 ) begin
                    req_rate = 2;
                    chg_rate = 3;
                end
                else begin
                    req_rate = 3;
                    chg_rate = 2;
                end
            end
            
            /*
            if ( s_request_valid ) begin
                counter_request = counter_request + s_request_size + REQUEST_SIZE_OFFSET;
            end
            
            if ( s_charge_valid ) begin
                counter_charge = counter_charge + s_charge_size + CHARGE_SIZE_OFFSET;
            end
            
            if ( m_issue_valid && m_issue_ready ) begin
                counter_issue = counter_issue + m_issue_size + ISSUE_SIZE_OFFSET;
            end
            */
            
            if ( i / 1000 >= 10 ) begin
                $finish();
            end
        end
    end
    
    
endmodule


`default_nettype wire


// end of file
