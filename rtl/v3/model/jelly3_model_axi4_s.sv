// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4_s
        #(
            parameter   int     MEM_ADDR_BITS    = 16                   ,
            parameter   int     MEM_SIZE         = (1 << MEM_ADDR_BITS) ,
            parameter   bit     READ_DATA_ADDR   = 0                    ,      // リード結果をアドレスとする
            parameter   string  WRITE_LOG_FILE   = ""                   ,
            parameter   string  READ_LOG_FILE    = ""                   ,
            parameter   int     AW_DELAY         = 0                    ,
            parameter   int     AR_DELAY         = 0                    ,
            parameter   int     AW_FIFO_PTR_BITS = 0                    ,
            parameter   int     W_FIFO_PTR_BITS  = 0                    ,
            parameter   int     B_FIFO_PTR_BITS  = 0                    ,
            parameter   int     AR_FIFO_PTR_BITS = 0                    ,
            parameter   int     R_FIFO_PTR_BITS  = 0                    ,
            parameter   int     AW_BUSY_RATE     = 0                    ,
            parameter   int     W_BUSY_RATE      = 0                    ,
            parameter   int     B_BUSY_RATE      = 0                    ,
            parameter   int     AR_BUSY_RATE     = 0                    ,
            parameter   int     R_BUSY_RATE      = 0                    ,
            parameter   int     AW_RAND_SEED     = 0                    ,
            parameter   int     W_RAND_SEED      = 1                    ,
            parameter   int     B_RAND_SEED      = 2                    ,
            parameter   int     AR_RAND_SEED     = 3                    ,
            parameter   int     R_RAND_SEED      = 4                    
        )
        (
            jelly3_axi4_if.s    s_axi4         
        );
    
    localparam  int     AXI_ID_BITS   = s_axi4.ID_BITS          ;
    localparam  int     AXI_ADDR_BITS = s_axi4.ADDR_BITS        ;
    localparam  int     AXI_QOS_BITS  = s_axi4.QOS_BITS         ;
    localparam  int     AXI_LEN_BITS  = s_axi4.LEN_BITS         ;
    localparam  int     AXI_DATA_BITS = s_axi4.DATA_BITS        ;
    localparam  int     AXI_STRB_BITS = s_axi4.STRB_BITS        ;
    localparam  int     AXI_DATA_SIZE = $clog2(AXI_STRB_BITS)   ;
    
    
    // -------------------------------------
    //  generate busy
    // -------------------------------------
    
    logic   reg_busy_aw = 1'b0;
    logic   reg_busy_w  = 1'b0;
    logic   reg_busy_b  = 1'b0;
    logic   reg_busy_ar = 1'b0;
    logic   reg_busy_r  = 1'b0;
    int     reg_rand_aw = AW_RAND_SEED  ;
    int     reg_rand_w  = W_RAND_SEED   ;
    int     reg_rand_b  = B_RAND_SEED   ;
    int     reg_rand_ar = AR_RAND_SEED  ;
    int     reg_rand_r  = R_RAND_SEED   ;
    always_ff @(posedge s_axi4.aclk) begin
        if ( s_axi4.aclken ) begin
            if ( reg_busy_aw || !s_axi4.awvalid || s_axi4.awready ) begin
                reg_busy_aw <= $signed({$random(reg_rand_aw)} % 100) < AW_BUSY_RATE;
            end
            
            if ( reg_busy_w || !s_axi4.wvalid || s_axi4.wready ) begin
                reg_busy_w  <= $signed({$random(reg_rand_w)} % 100)  < W_BUSY_RATE;
            end
            
            reg_busy_b <= 1'b0;
            if ( !s_axi4.bvalid || s_axi4.bready ) begin
                reg_busy_b  <= $signed({$random(reg_rand_b)} % 100)  < B_BUSY_RATE;
            end
            
            reg_busy_ar <= 1'b0;
            if ( !s_axi4.arvalid || s_axi4.arready ) begin
                reg_busy_ar <= $signed({$random(reg_rand_ar)} % 100) < AR_BUSY_RATE;
            end
            
            reg_busy_r <= 1'b0;
            if ( !s_axi4.rvalid || s_axi4.rready ) begin
                reg_busy_r  <= $signed({$random(reg_rand_r)} % 100)  < R_BUSY_RATE;
            end
        end
    end 
    

    // -------------------------------------
    //  insert fifo
    // -------------------------------------
    
    logic   [AXI_ID_BITS-1:0]       axi4_fifo_awid      ;
    logic   [AXI_ADDR_BITS-1:0]     axi4_fifo_awaddr    ;
    logic   [AXI_LEN_BITS-1:0]      axi4_fifo_awlen     ;
    logic   [2:0]                   axi4_fifo_awsize    ;
    logic                           axi4_fifo_awvalid   ;
    logic                           axi4_fifo_awready   ;
    
    logic   [AXI_DATA_BITS-1:0]     axi4_wdata          ;
    logic   [AXI_STRB_BITS-1:0]     axi4_wstrb          ;
    logic                           axi4_wlast          ;
    logic                           axi4_wvalid         ;
    logic                           axi4_wready         ;
    
    logic    [AXI_ID_BITS-1:0]      axi4_bid            ;
    logic                           axi4_bvalid         ;
    logic                           axi4_bready         ;
    
    logic   [AXI_ID_BITS-1:0]       axi4_fifo_arid      ;
    logic   [AXI_ADDR_BITS-1:0]     axi4_fifo_araddr    ;
    logic   [AXI_LEN_BITS-1:0]      axi4_fifo_arlen     ;
    logic   [2:0]                   axi4_fifo_arsize    ;
    logic                           axi4_fifo_arvalid   ;
    logic                           axi4_fifo_arready   ;
    
    logic   [AXI_ID_BITS-1:0]       axi4_rid            ;
    logic   [AXI_DATA_BITS-1:0]     axi4_rdata          ;
    logic                           axi4_rlast          ;
    logic                           axi4_rvalid         ;
    logic                           axi4_rready         ;
    
    // aw
    logic                           s_axi4_awready_tmp   ;
    jelly3_stream_fifo_sync
            #(
                .PTR_BITS           (AW_FIFO_PTR_BITS                                                       ),
                .DATA_BITS          ($bits({axi4_fifo_awid, axi4_fifo_awaddr, axi4_fifo_awlen, axi4_fifo_awsize}))
            )
        u_stream_fifo_sync_aw
            (
                .reset              (~s_axi4.aresetn                                                        ),
                .clk                (s_axi4.aclk                                                            ),
                .cke                (s_axi4.aclken                                                          ),
                
                .s_data             ({s_axi4.awid, s_axi4.awaddr, s_axi4.awlen, s_axi4.awsize}              ),
                .s_valid            (s_axi4.awvalid & !reg_busy_aw                                          ),
                .s_ready            (s_axi4_awready_tmp                                                     ),
                .s_free_size        (                                                                       ),
                
                .m_data             ({axi4_fifo_awid, axi4_fifo_awaddr, axi4_fifo_awlen, axi4_fifo_awsize}  ),
                .m_valid            (axi4_fifo_awvalid                                                      ),
                .m_ready            (axi4_fifo_awready                                                      ),
                .m_data_size        (                                                                       )
            );
    assign s_axi4.awready = (s_axi4_awready_tmp & !reg_busy_aw);
    
    
    // w
    logic                           s_axi4_wready_tmp;
    jelly3_stream_fifo_sync
            #(
                .PTR_BITS          (W_FIFO_PTR_BITS                                     ),
                .DATA_BITS         ($bits({axi4_wdata, axi4_wstrb, axi4_wlast})         )
            )
        u_stream_fifo_sync_w
            (
                .reset              (~s_axi4.aresetn                                    ),
                .clk                (s_axi4.aclk                                        ),
                .cke                (s_axi4.aclken                                      ),
                
                .s_data             ({s_axi4.wdata, s_axi4.wstrb, s_axi4.wlast}         ),
                .s_valid            (s_axi4.wvalid & !reg_busy_w                        ),
                .s_ready            (s_axi4_wready_tmp                                  ),
                .s_free_size        (                                                   ),
                
                .m_data             ({axi4_wdata, axi4_wstrb, axi4_wlast}               ),
                .m_valid            (axi4_wvalid                                        ),
                .m_ready            (axi4_wready                                        ),
                .m_data_size        (                                                   )
            );
    assign s_axi4.wready = (s_axi4_wready_tmp & !reg_busy_w);
    
    
    // b
    logic                           s_axi4_bvalid_tmp;
    jelly3_stream_fifo_sync
            #(
                .PTR_BITS          (B_FIFO_PTR_BITS             ),
                .DATA_BITS         ($bits(axi4_bid)             )
            )
        u_stream_fifo_sync_b
            (
                .reset              (~s_axi4.aresetn            ),
                .clk                (s_axi4.aclk                ),
                .cke                (s_axi4.aclken              ),
                
                .s_data             (axi4_bid                   ),
                .s_valid            (axi4_bvalid                ),
                .s_ready            (axi4_bready                ),
                .s_free_size        (                           ),
                
                .m_data             (s_axi4.bid                 ),
                .m_valid            (s_axi4_bvalid_tmp          ),
                .m_ready            (s_axi4.bready & !reg_busy_b),
                .m_data_size        (                           )
            );
    assign s_axi4.bresp  = s_axi4.bvalid ? 2'b00 : 2'bxx;
    assign s_axi4.bvalid = s_axi4_bvalid_tmp & !reg_busy_b;
    
    
    // ar
    logic                          s_axi4_arready_tmp;
    jelly3_stream_fifo_sync
            #(
                .PTR_BITS          (AR_FIFO_PTR_BITS                                                            ),
                .DATA_BITS         ($bits({axi4_fifo_arid, axi4_fifo_araddr, axi4_fifo_arlen, axi4_fifo_arsize}))
            )
        u_stream_fifo_sync_ar
            (
                .reset              (~s_axi4.aresetn                                                            ),
                .clk                (s_axi4.aclk                                                                ),
                .cke                (s_axi4.aclken                                                              ),
                
                .s_data             ({s_axi4.arid, s_axi4.araddr, s_axi4.arlen, s_axi4.arsize}                  ),
                .s_valid            (s_axi4.arvalid & !reg_busy_ar                                              ),
                .s_ready            (s_axi4_arready_tmp                                                         ),
                .s_free_size        (                                                                           ),
                
                .m_data             ({axi4_fifo_arid, axi4_fifo_araddr, axi4_fifo_arlen, axi4_fifo_arsize}      ),
                .m_valid            (axi4_fifo_arvalid                                                          ),
                .m_ready            (axi4_fifo_arready                                                          ),
                .m_data_size        (                                                                           )
            );
    assign s_axi4.arready = (s_axi4_arready_tmp & !reg_busy_ar);
    
    
    // r
    logic                           s_axi4_rvalid_tmp;
    jelly3_stream_fifo_sync
            #(
                .PTR_BITS          (R_FIFO_PTR_BITS                             ),
                .DATA_BITS         ($bits({axi4_rid, axi4_rdata, axi4_rlast})   )
            )
        u_stream_fifo_sync_r
            (
                .reset              (~s_axi4.aresetn                            ),
                .clk                (s_axi4.aclk                                ),
                .cke                (s_axi4.aclken                              ),
                
                .s_data             ({axi4_rid, axi4_rdata, axi4_rlast}         ),
                .s_valid            (axi4_rvalid                                ),
                .s_ready            (axi4_rready                                ),
                .s_free_size        (                                           ),
                
                .m_data             ({s_axi4.rid, s_axi4.rdata, s_axi4.rlast}   ),
                .m_valid            (s_axi4_rvalid_tmp                          ),
                .m_ready            (s_axi4.rready & !reg_busy_r                ),
                .m_data_size        (                                           )
            );
    assign s_axi4.rresp  = s_axi4.rvalid ? 2'b00 : 2'bxx;
    assign s_axi4.rvalid = s_axi4_rvalid_tmp & !reg_busy_r;
    
    
    // -------------------------------------
    //  insert deleay
    // -------------------------------------
    
    logic   [AXI_ID_BITS-1:0]       axi4_awid       ;
    logic   [AXI_ADDR_BITS-1:0]     axi4_awaddr     ;
    logic   [AXI_LEN_BITS-1:0]      axi4_awlen      ;
    logic   [2:0]                   axi4_awsize     ;
    logic                           axi4_awvalid    ;
    logic                           axi4_awready    ;
    
    logic   [AXI_ID_BITS-1:0]       axi4_arid       ;
    logic   [AXI_ADDR_BITS-1:0]     axi4_araddr     ;
    logic   [AXI_LEN_BITS-1:0]      axi4_arlen      ;
    logic   [2:0]                   axi4_arsize     ;
    logic                           axi4_arvalid    ;
    logic                           axi4_arready    ;
    
    // aw
    jelly3_data_delay
            #(
                .LATENCY    (AW_DELAY                                                                                   ),
                .DATA_BITS  ($bits({axi4_awid, axi4_awaddr, axi4_awlen, axi4_awsize, axi4_awvalid})                     ),
                .DATA_INIT  ('0                                                                                         )
            )
        u_data_delay_aw
            (
                .reset      (~s_axi4.aresetn                                                                            ),
                .clk        (s_axi4.aclk                                                                                ),
                .cke        (s_axi4.aclken & axi4_awready                                                               ),
                
                .s_data     ({axi4_fifo_awid, axi4_fifo_awaddr, axi4_fifo_awlen, axi4_fifo_awsize, axi4_fifo_awvalid}   ),
                
                .m_data     ({axi4_awid, axi4_awaddr, axi4_awlen, axi4_awsize, axi4_awvalid}                            )
            );
    assign axi4_fifo_awready = axi4_awready;
    
    
    // ar
    jelly3_data_delay
            #(
                .LATENCY            (AR_DELAY                                                                                   ),
                .DATA_BITS          ($bits({axi4_arid, axi4_araddr, axi4_arlen, axi4_arsize, axi4_arvalid})                     ),
                .DATA_INIT          ('0                                                                                         )
            )
        u_data_delay_ar
            (
                .reset              (~s_axi4.aresetn                                                                            ),
                .clk                (s_axi4.aclk                                                                                ),
                .cke                (s_axi4.aclken & axi4_arready                                                               ),
                
                .s_data             ({axi4_fifo_arid, axi4_fifo_araddr, axi4_fifo_arlen, axi4_fifo_arsize, axi4_fifo_arvalid}   ),
                
                .m_data             ({axi4_arid, axi4_araddr, axi4_arlen, axi4_arsize, axi4_arvalid}                            )
            );
    assign axi4_fifo_arready = axi4_arready;
    
    
    
    // -------------------------------------
    //  AXI access
    // -------------------------------------
    
    int     w_fp = 0;
    int     r_fp = 0;
    
    initial begin
        if ( WRITE_LOG_FILE != "" ) begin
            w_fp = $fopen(WRITE_LOG_FILE, "w");
        end
        
        if ( READ_LOG_FILE != "" ) begin
            r_fp = $fopen(READ_LOG_FILE, "w");
        end
    end
    
    
    // memory
    localparam  MEM_BITS       = $clog2(MEM_SIZE);
    localparam  MEM_ADDR_MASK  = ((1 << MEM_BITS) - 1);
    logic   [AXI_DATA_BITS-1:0]    mem     [MEM_SIZE-1:0];

    // write
    logic                           reg_awbusy  ;
    logic   [AXI_ID_BITS-1:0]       reg_awid    ;
    logic   [AXI_ADDR_BITS-1:0]     reg_awaddr  ;
    logic   [AXI_LEN_BITS-1:0]      reg_awlen   ;
    logic   [2:0]                   reg_awsize  ;
    logic                           reg_bvalid  ;
    
    always_ff @( posedge s_axi4.aclk ) begin
        if ( !s_axi4.aresetn ) begin
            reg_awbusy <= 1'b0  ;
            reg_awid   <= '0    ;
            reg_awaddr <= '0    ;
            reg_awlen  <= '0    ;
            reg_awsize <= '0    ;
            reg_bvalid <= 1'b0  ;
        end
        else if ( s_axi4.aclken ) begin
            if ( axi4_bready ) begin
                reg_bvalid <= 1'b0;
            end
            
            if ( axi4_awready && axi4_wready ) begin
                reg_awbusy <= 1'b1          ;
                reg_awid   <= axi4_awid     ;
                reg_awaddr <= axi4_awaddr   ;
                reg_awlen  <= axi4_awlen    ;
                reg_awsize <= axi4_awsize   ;
                if ( axi4_wvalid && axi4_wready ) begin
                    if ( axi4_awlen == 0 ) begin
                        reg_bvalid <= 1'b1  ;
                        reg_awbusy <= 1'b0  ;
                    end
                    else begin
                        reg_awlen  <= axi4_awlen - 1                    ;
                        reg_awaddr <= axi4_awaddr + (1 << axi4_awsize)  ;
                    end
                end
            end
            else if ( axi4_wvalid && axi4_wready ) begin
                if ( reg_awlen == 0 ) begin
                    reg_bvalid <= 1'b1;
                    reg_awbusy <= 1'b0;
                end
                else begin
                    reg_awlen  <= reg_awlen - 1;
                    reg_awaddr <= reg_awaddr + (1 << reg_awsize);
                end
            end
            
            // wlast check
            if ( axi4_wvalid && axi4_wready ) begin
                if ( ((axi4_awvalid && axi4_awready) && (axi4_wlast != (axi4_awlen == 0)))
                    || (!(axi4_awvalid && axi4_awready) && (axi4_wlast != (reg_awlen == 0))) ) begin
                    $display("[%m(%t)] wlast error!", $time);
                end
            end
        end
    end
    
    
    // memory write
    logic   [AXI_ADDR_BITS-1:0]    sig_awaddr;
    assign sig_awaddr = reg_awbusy ? reg_awaddr : axi4_awaddr;
    always_ff @( posedge s_axi4.aclk ) begin
        if ( s_axi4.aclken ) begin
            if ( s_axi4.aresetn && axi4_wvalid && axi4_wready ) begin
                if ( int'(sig_awaddr >> AXI_DATA_SIZE) < MEM_SIZE ) begin
                    for ( int i = 0; i < AXI_STRB_BITS; i++ ) begin
                        if ( axi4_wstrb[i] ) begin
                            mem[MEM_ADDR_BITS'(sig_awaddr >> AXI_DATA_SIZE)][i*8 +: 8] <= axi4_wdata[i*8 +: 8];
                        end
                    end
                end
                
                if ( w_fp != 0 ) begin
                    $fdisplay(w_fp, "%h %h %h", sig_awaddr, axi4_wdata, axi4_wstrb);
                end
            end
        end
    end
    
    
    // write assign
    assign axi4_awready = !reg_awbusy && !(axi4_bvalid && !axi4_bready);
    assign axi4_wready  = (reg_awbusy || axi4_awvalid) && !(axi4_bvalid && !axi4_bready);
    
    assign axi4_bid     = axi4_bvalid ? reg_awid : 'x;
    assign axi4_bvalid  = reg_bvalid;
    
    
    // read
    logic                           reg_arbusy  ;
    logic   [AXI_ID_BITS-1:0]       reg_arid    ;
    logic   [AXI_ADDR_BITS-1:0]     reg_araddr  ;
    logic   [AXI_LEN_BITS-1:0]      reg_arlen   ;
    logic   [2:0]                   reg_arsize  ;
    logic                           reg_rlast   ;
    logic   [AXI_DATA_BITS-1:0]     reg_rdata   ;
    logic                           reg_rvalid  ;
    
    always_ff @( posedge s_axi4.aclk ) begin
        if ( !s_axi4.aresetn ) begin
            reg_arbusy <= 0;
            reg_arid   <= 0; 
            reg_araddr <= 0;
            reg_arlen  <= 0;
            reg_arsize <= 0;
            reg_rlast  <= 0;
            reg_rdata  <= 0;
            reg_rvalid <= 0;
        end
        else if ( s_axi4.aclken ) begin
            if ( axi4_rvalid & axi4_rready ) begin
                reg_araddr <= reg_araddr + (1 << reg_arsize);
                reg_arlen  <= reg_arlen - 1'b1              ;
                reg_rlast  <= ((reg_arlen - 1'b1) == 0)     ;
                if ( reg_rlast ) begin
                    reg_arbusy <= 1'b0;
                    reg_rvalid <= 1'b0;
                end
            end
            
            if ( axi4_arvalid & axi4_arready ) begin
                reg_arbusy <= (axi4_arlen != 0) ;
                reg_arid   <= axi4_arid         ;
                reg_araddr <= axi4_araddr       ;
                reg_arlen  <= axi4_arlen        ;
                reg_arsize <= axi4_arsize       ;
                
                reg_rlast  <= (axi4_arlen == 0) ;
                reg_rvalid <= 1'b1              ;
            end
            
            if ( axi4_rvalid && axi4_rready ) begin
                if ( r_fp != 0 ) begin
                    $fdisplay(r_fp, "%h %h", reg_araddr, axi4_rdata);
                end
            end
        end
    end
    
    
    assign axi4_arready = (!reg_arbusy && !(axi4_rvalid & !axi4_rready)) || (reg_rlast && axi4_rvalid && axi4_rready);
    
    assign axi4_rid     = axi4_rvalid ? reg_arid : {AXI_ID_BITS{1'bx}};
    assign axi4_rdata   = READ_DATA_ADDR                                                  ? AXI_DATA_BITS'(reg_araddr)                       :
                          (axi4_rvalid && (int'(reg_araddr >> AXI_DATA_SIZE) < MEM_SIZE)) ? mem[MEM_ADDR_BITS'(reg_araddr >> AXI_DATA_SIZE)] :
                          {AXI_DATA_BITS{1'bx}};
    
    assign axi4_rlast   = axi4_rvalid ? reg_rlast : 1'bx;
    assign axi4_rvalid  = reg_rvalid;
    
    
    
    // debug
    task write_memh
            (
                input   string  filename
            );
        int fp;
        fp = $fopen(filename, "w");
        if ( fp != 0 ) begin
            for ( int i = 0; i < MEM_SIZE; i++ ) begin
                $fdisplay(fp, "%h", mem[i]);
            end
            $fclose(fp);
        end
        else begin
            $display("file oppen error : %s", filename);
        end
    endtask
    
    task read_memh
            (
                input   string  filename
            );
    begin
        $readmemh(filename, mem);
    end
    endtask
    
endmodule

`default_nettype wire

// end of file
