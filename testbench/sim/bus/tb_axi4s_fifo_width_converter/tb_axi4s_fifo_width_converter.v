
`timescale 1ns / 1ps
`default_nettype none


module tb_axi4s_fifo_width_converter();
    localparam S_RATE  = 1000.0/100.0;
    localparam M_RATE  = 1000.0/100.0;
    
    
    initial begin
        $dumpfile("tb_axi4s_fifo_width_converter.vcd");
        $dumpvars(0, tb_axi4s_fifo_width_converter);
    
    #100000
        $finish;
    end
    
    reg     s_aresetn = 1'b0;
    initial #(S_RATE*100)   s_aresetn = 1'b1;
    
    reg     s_aclk = 1'b1;
    always #(S_RATE/2.0)    s_aclk = ~s_aclk;
    
    reg     m_aresetn = 1'b0;
    initial #(M_RATE*100)   m_aresetn = 1'b1;
    
    reg     m_aclk = 1'b1;
    always #(M_RATE/2.0)    m_aclk = ~m_aclk;
    
    
    parameter   ASYNC            = 1;
    parameter   FIFO_PTR_WIDTH   = 9;
    parameter   FIFO_RAM_TYPE    = "block";
    parameter   FIFO_LOW_DEALY   = 0;
    parameter   FIFO_DOUT_REGS   = 1;
    parameter   FIFO_S_REGS      = 1;
    parameter   FIFO_M_REGS      = 1;
    
    parameter   HAS_STRB         = 1;
    parameter   HAS_KEEP         = 1;
    parameter   HAS_FIRST        = 1;
    parameter   HAS_LAST         = 1;
    
    parameter   BYTE_WIDTH       = 8;
    parameter   S_TDATA_WIDTH    = 32;
    parameter   M_TDATA_WIDTH    = 32*3;
    parameter   DATA_WIDTH_GCD   = BYTE_WIDTH;
    
    parameter   S_TSTRB_WIDTH    = HAS_STRB ? (S_TDATA_WIDTH / BYTE_WIDTH) : 0;
    parameter   S_TKEEP_WIDTH    = HAS_KEEP ? (S_TDATA_WIDTH / BYTE_WIDTH) : 0;
    parameter   S_TUSER_WIDTH    = 0;
    
    parameter   M_TSTRB_WIDTH    = HAS_STRB ? (M_TDATA_WIDTH / BYTE_WIDTH) : 0;
    parameter   M_TKEEP_WIDTH    = HAS_KEEP ? (M_TDATA_WIDTH / BYTE_WIDTH) : 0;
    parameter   M_TUSER_WIDTH    = S_TUSER_WIDTH * M_TDATA_WIDTH / S_TDATA_WIDTH;
    
    parameter   FIRST_FORCE_LAST = 1;
    parameter   FIRST_OVERWRITE  = 0;
    
    parameter   S_REGS           = 1;
    
    // local
    parameter   S_TDATA_BITS     = S_TDATA_WIDTH > 0 ? S_TDATA_WIDTH : 1;
    parameter   S_TSTRB_BITS     = S_TSTRB_WIDTH > 0 ? S_TSTRB_WIDTH : 1;
    parameter   S_TKEEP_BITS     = S_TKEEP_WIDTH > 0 ? S_TKEEP_WIDTH : 1;
    parameter   S_TUSER_BITS     = S_TUSER_WIDTH > 0 ? S_TUSER_WIDTH : 1;
    parameter   M_TDATA_BITS     = M_TDATA_WIDTH > 0 ? M_TDATA_WIDTH : 1;
    parameter   M_TSTRB_BITS     = M_TSTRB_WIDTH > 0 ? M_TSTRB_WIDTH : 1;
    parameter   M_TKEEP_BITS     = M_TKEEP_WIDTH > 0 ? M_TKEEP_WIDTH : 1;
    parameter   M_TUSER_BITS     = M_TUSER_WIDTH > 0 ? M_TUSER_WIDTH : 1;
    
    
    localparam S_NUM = S_TDATA_WIDTH / BYTE_WIDTH;
    localparam M_NUM = M_TDATA_WIDTH / BYTE_WIDTH;
    
    
    integer     i;
    integer     count;
    
    reg                         endian = 1;
    
    reg     [S_TDATA_BITS-1:0]  s_axi4s_tdata;
    reg     [S_TSTRB_BITS-1:0]  s_axi4s_tstrb;
    reg     [S_TKEEP_BITS-1:0]  s_axi4s_tkeep;
    wire                        s_axi4s_tfirst = 0;//(count[1:0] == 1'b0);
    wire                        s_axi4s_tlast  = (count[1:0] == 1'b1);
    reg     [S_TUSER_BITS-1:0]  s_axi4s_tuser = 0;
    reg                         s_axi4s_tvalid;
    wire                        s_axi4s_tready;
    wire    [FIFO_PTR_WIDTH:0]  s_fifo_free_count;
    wire                        s_fifo_wr_signal;
    
    wire    [M_TDATA_BITS-1:0]  m_axi4s_tdata;
    wire    [M_TSTRB_BITS-1:0]  m_axi4s_tstrb;
    wire    [M_TKEEP_BITS-1:0]  m_axi4s_tkeep;
    wire                        m_axi4s_tfirst;
    wire                        m_axi4s_tlast;
    wire    [M_TUSER_BITS-1:0]  m_axi4s_tuser;
    wire                        m_axi4s_tvalid;
    reg                         m_axi4s_tready;
    wire    [FIFO_PTR_WIDTH:0]  m_fifo_data_count;
    wire                        m_fifo_rd_signal;
    
    jelly_axi4s_fifo_width_converter
            #(
                .ASYNC              (ASYNC),
                .FIFO_PTR_WIDTH     (FIFO_PTR_WIDTH),
                .FIFO_RAM_TYPE      (FIFO_RAM_TYPE),
                .FIFO_LOW_DEALY     (FIFO_LOW_DEALY),
                .FIFO_DOUT_REGS     (FIFO_DOUT_REGS),
                .FIFO_S_REGS        (FIFO_S_REGS),
                .FIFO_M_REGS        (FIFO_M_REGS),
                .HAS_STRB           (HAS_STRB),
                .HAS_KEEP           (HAS_KEEP),
                .HAS_FIRST          (HAS_FIRST),
                .HAS_LAST           (HAS_LAST),
                .BYTE_WIDTH         (BYTE_WIDTH),
                .S_TDATA_WIDTH      (S_TDATA_WIDTH),
                .M_TDATA_WIDTH      (M_TDATA_WIDTH),
                .DATA_WIDTH_GCD     (DATA_WIDTH_GCD),
                .S_TSTRB_WIDTH      (S_TSTRB_WIDTH),
                .S_TKEEP_WIDTH      (S_TKEEP_WIDTH),
                .S_TUSER_WIDTH      (S_TUSER_WIDTH),
                .M_TSTRB_WIDTH      (M_TSTRB_WIDTH),
                .M_TKEEP_WIDTH      (M_TKEEP_WIDTH),
                .M_TUSER_WIDTH      (M_TUSER_WIDTH),
                .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                .FIRST_OVERWRITE    (FIRST_OVERWRITE),
                .S_REGS             (S_REGS)
            )
        i_axi4s_fifo_width_converter
            (
                .endian             (endian),
                
                .s_aresetn          (s_aresetn),
                .s_aclk             (s_aclk),
                .s_axi4s_tdata      (s_axi4s_tdata),
                .s_axi4s_tstrb      (s_axi4s_tstrb),
                .s_axi4s_tkeep      (s_axi4s_tkeep),
                .s_axi4s_tfirst     (s_axi4s_tfirst),
                .s_axi4s_tlast      (s_axi4s_tlast),
                .s_axi4s_tuser      (s_axi4s_tuser),
                .s_axi4s_tvalid     (s_axi4s_tvalid),
                .s_axi4s_tready     (s_axi4s_tready),
                .s_fifo_free_count  (s_fifo_free_count),
                .s_fifo_wr_signal   (s_fifo_wr_signal),
                
                .m_aresetn          (m_aresetn),
                .m_aclk             (m_aclk),
                .m_axi4s_tdata      (m_axi4s_tdata),
                .m_axi4s_tstrb      (m_axi4s_tstrb),
                .m_axi4s_tkeep      (m_axi4s_tkeep),
                .m_axi4s_tfirst     (m_axi4s_tfirst),
                .m_axi4s_tlast      (m_axi4s_tlast),
                .m_axi4s_tuser      (m_axi4s_tuser),
                .m_axi4s_tvalid     (m_axi4s_tvalid),
                .m_axi4s_tready     (m_axi4s_tready),
                .m_fifo_data_count  (m_fifo_data_count),
                .m_fifo_rd_signal   (m_fifo_rd_signal)
            );
    
    
    always @(posedge s_aclk) begin
        if ( ~s_aresetn ) begin
            count   <= 0;
            for ( i = 0; i < S_TDATA_WIDTH/8; i = i+1 ) begin
                s_axi4s_tdata[i*8 +: 8] <= endian ? S_NUM - 1 - (i+0) : (i+0);
                s_axi4s_tstrb           <= 1;
                s_axi4s_tkeep           <= 2;
            end
            s_axi4s_tvalid <= 0;
        end
        else begin
            if ( s_axi4s_tvalid && s_axi4s_tready ) begin
                for ( i = 0; i < S_TDATA_WIDTH/8; i = i+1 ) begin
                    s_axi4s_tdata[i*8 +: 8] <= s_axi4s_tdata[i*8 +: 8] + S_NUM;
                    s_axi4s_tstrb           <= s_axi4s_tstrb + 1;
                    s_axi4s_tkeep           <= s_axi4s_tkeep + 1;
                end
                count <= count + 1;
            end
            if ( !s_axi4s_tvalid || s_axi4s_tready ) begin
                s_axi4s_tvalid <= 1;
            end
        end
    end
    
    
    always @(posedge m_aclk) begin
        m_axi4s_tready <= {$random()};
    end
    
    
    
    integer fp;
    initial begin
        fp = $fopen("out.txt", "w");
    end
    
    always @(posedge m_aclk) begin
        if ( ~m_aresetn ) begin
        end
        else begin
            if ( m_axi4s_tvalid && m_axi4s_tready ) begin
                $fdisplay(fp, "%h %h %h %b %b", m_axi4s_tdata, m_axi4s_tstrb, m_axi4s_tkeep, m_axi4s_tfirst, m_axi4s_tlast);
            end
        end
    end
    
    
    
endmodule


`default_nettype wire


// end of file
