
`timescale 1ns / 1ps
`default_nettype none


module tb_fifo_width_converter();
    localparam S_RATE  = 1000.0/100.0;
    localparam M_RATE  = 1000.0/100.0;
    
    
    initial begin
        $dumpfile("tb_fifo_width_converter.vcd");
        $dumpvars(0, tb_fifo_width_converter);
    
    #10000000
        $finish;
    end
    
    
    reg     s_clk = 1'b1;
    always #(S_RATE/2.0)    s_clk = ~s_clk;
    
    reg     m_clk = 1'b1;
    always #(S_RATE/2.0)    m_clk = ~m_clk;
    
    reg     reset = 1'b1;
    initial #(S_RATE*100)   reset <= 1'b0;
    
    
    parameter   ASYNC            = 1;
    parameter   UNIT_WIDTH       = 8;
    parameter   S_DATA_SIZE      = 2;   // log2 (0:1byte, 1:2byte, 2:4byte, 3:81byte...)
    parameter   M_DATA_SIZE      = 1;   // log2 (0:1byte, 1:2byte, 2:4byte, 3:81byte...)
    
    parameter   FIFO_PTR_WIDTH   = 10;
    parameter   FIFO_RAM_TYPE    = "block";
    parameter   FIFO_LOW_DEALY   = 0;
    parameter   FIFO_DOUT_REGS   = 1;
    parameter   FIFO_SLAVE_REGS  = 1;
    parameter   FIFO_MASTER_REGS = 1;
    
    parameter   S_DATA_WIDTH = (UNIT_WIDTH << S_DATA_SIZE);
    parameter   M_DATA_WIDTH = (UNIT_WIDTH << M_DATA_SIZE);
    
        
    genvar                          i;
    
    reg     [S_DATA_WIDTH-1:0]      src_data;
    reg                             src_valid;
    wire                            src_ready;
    
    wire    [M_DATA_WIDTH-1:0]      dst_data;
    wire                            dst_valid;
    reg                             dst_ready;
    
    always @(posedge s_clk) begin
        if ( reset ) begin
            src_data  <= 0;
            src_valid <= 0;
        end
        else begin
            if ( src_valid & src_ready ) begin
                src_data <= src_data + 1;
            end
            src_valid <= {$random()};
        end
    end
    
    always @(posedge m_clk) begin
        dst_ready <= {$random()};
    end
    
    
    
    // target
    jelly_fifo_width_converter
            #(
                .ASYNC              (ASYNC),
                .UNIT_WIDTH         (UNIT_WIDTH),
                .S_DATA_SIZE        (S_DATA_SIZE),
                .M_DATA_SIZE        (M_DATA_SIZE),
                .FIFO_PTR_WIDTH     (FIFO_PTR_WIDTH),
                .FIFO_RAM_TYPE      (FIFO_RAM_TYPE),
                .FIFO_LOW_DEALY     (FIFO_LOW_DEALY),
                .FIFO_DOUT_REGS     (FIFO_DOUT_REGS),
                .FIFO_SLAVE_REGS    (FIFO_SLAVE_REGS)
            )
        i_axi4s_video_fifo_width_converter
            (
                .endian             (1'b0),
                
                .s_reset            (reset),
                .s_clk              (s_clk),
                .s_data             (src_data),
                .s_valid            (src_valid),
                .s_ready            (src_ready),
                .s_free_count       (),
                .s_wr_signal        (),
                
                .m_reset            (reset),
                .m_clk              (m_clk),
                .m_data             (dst_data),
                .m_valid            (dst_valid),
                .m_ready            (dst_ready),
                .m_data_count       (),
                .s_rd_signal        ()
            );
    
    
endmodule


`default_nettype wire


// end of file
