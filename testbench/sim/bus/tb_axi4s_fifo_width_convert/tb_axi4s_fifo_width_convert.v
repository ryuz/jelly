
`timescale 1ns / 1ps
`default_nettype none


module tb_axi4s_fifo_width_convert();
    localparam RATE0  = 1000.0/200.0;
    localparam RATE1  = 1000.0/130.0;
    localparam RATE2  = 1000.0/180.0;
    
    
    initial begin
        $dumpfile("tb_axi4s_fifo_width_convert.vcd");
        $dumpvars(0, tb_axi4s_fifo_width_convert);
    
    #100000
        $finish;
    end
    
    // バス幅を広げて戻すテスト
    
    reg     aresetn0 = 1'b0;
    initial #(RATE0*100)    aresetn0 = 1'b1;
    
    reg     aclk0 = 1'b1;
    always #(RATE0/2.0)     aclk0 = ~aclk0;
    
    reg     aresetn1 = 1'b0;
    initial #(RATE1*100)     aresetn1 = 1'b1;
    
    reg     aclk1 = 1'b1;
    always #(RATE1/2.0)      aclk1 = ~aclk1;
    
    reg     aresetn2 = 1'b0;
    initial #(RATE2*100)     aresetn1 = 1'b1;
    
    reg     aclk2 = 1'b1;
    always #(RATE2/2.0)      aclk2 = ~aclk2;
    
    
    
    parameter   TDATA_WIDTH0     = 24;
    parameter   TDATA_WIDTH1     = 64;
    parameter   TUSER_WIDTH0     = 4;
    
    parameter   TSTRB_WIDTH0     = TDATA_WIDTH0 / 8;
    parameter   TSTRB_WIDTH1     = TDATA_WIDTH1 / 8;
    parameter   TUSER_WIDTH1     = TUSER_WIDTH0 * TDATA_WIDTH1 / TDATA_WIDTH0;
    
    
    
    reg                         endian = 1;
    
    reg     [TDATA_WIDTH0-1:0]  axi4s_src_tdata;
    reg     [TSTRB_WIDTH0-1:0]  axi4s_src_tstrb;
    wire                        axi4s_src_tlast  = (axi4s_src_tuser[2:0] == 3'b111);
    reg     [TUSER_WIDTH0-1:0]  axi4s_src_tuser  = 0;
    reg                         axi4s_src_tvalid;
    wire                        axi4s_src_tready;
    
    wire    [TDATA_WIDTH1-1:0]  axi4s_cnv_tdata;
    wire    [TSTRB_WIDTH1-1:0]  axi4s_cnv_tstrb;
    wire                        axi4s_cnv_tfirst;
    wire                        axi4s_cnv_tlast;
    wire    [TUSER_WIDTH1-1:0]  axi4s_cnv_tuser;
    wire                        axi4s_cnv_tvalid;
    wire                        axi4s_cnv_tready;
    
    wire    [TDATA_WIDTH0-1:0]  axi4s_dst_tdata;
    wire    [TSTRB_WIDTH0-1:0]  axi4s_dst_tstrb;
    wire                        axi4s_dst_tfirst;
    wire                        axi4s_dst_tlast;
    wire    [TUSER_WIDTH0-1:0]  axi4s_dst_tuser;
    wire                        axi4s_dst_tvalid;
    reg                         axi4s_dst_tready;
    
    
    jelly_axi4s_fifo_width_convert
            #(
                .ASYNC              (1),
                .HAS_STRB           (1),
                .HAS_KEEP           (0),
                .HAS_FIRST          (0),
                .HAS_LAST           (1),
                .S_TDATA_WIDTH      (TDATA_WIDTH0),
                .M_TDATA_WIDTH      (TDATA_WIDTH1),
                .M_TUSER_WIDTH      (TUSER_WIDTH0),
  //            .FIRST_FORCE_LAST   (1),
  //            .FIRST_OVERWRITE    (0)
                .HAS_FIRST_SALIGN    = 1;
                .HAS_FIRST_MALIGN    = 0;
            )
        i_axi4s_fifo_width_convert
            (
                .endian             (endian),
                
                .s_aresetn          (aresetn0),
                .s_aclk             (aclk0),
                
                .s_axi4s_tdata      (axi4s_src_tdata),
                .s_axi4s_tstrb      (axi4s_src_tstrb),
                .s_axi4s_tkeep      (1'b1),
                .s_axi4s_tfirst     (axi4s_src_tfirst),
                .s_axi4s_tlast      (axi4s_src_tlast),
                .s_axi4s_tuser      (axi4s_src_tuser),
                .s_axi4s_tvalid     (axi4s_src_tvalid),
                .s_axi4s_tready     (axi4s_src_tready),
                .s_first_salign     (),
                .s_first_malign     (),
                .s_fifo_free_count  (),
                .s_fifo_wr_signal   (),
                
                .m_aresetn          (aresetn1),
                .m_aclk             (aclk1),
                .m_axi4s_tdata      (axi4s_cnv_tdata),
                .m_axi4s_tstrb      (axi4s_cnv_tstrb),
                .m_axi4s_tkeep      (),
                .m_axi4s_tfirst     (axi4s_cnv_tfirst),
                .m_axi4s_tlast      (axi4s_cnv_tlast),
                .m_axi4s_tuser      (axi4s_cnv_tuser),
                .m_axi4s_tvalid     (axi4s_cnv_tvalid),
                .m_axi4s_tready     (axi4s_cnv_tready),
                .m_fifo_data_count  (),
                .m_fifo_rd_signal   ()
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
