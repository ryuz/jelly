

`timescale 1ns / 1ps

module kv260_blinking_led_ps
    (
        output  var logic   [0:0]   led     // LED用に出力を 1bit 定義
    );

    // ---------------------------------
    //  ブロックデザインから信号を引き出す
    // ---------------------------------

    logic           aresetn ;
    logic           aclk    ;

    logic   [15:0]  awid    ;
    logic   [39:0]  awaddr  ;
    logic           awvalid ;
    logic           awready ;
    logic   [127:0] wdata   ;
    logic           wvalid  ;
    logic           wready  ;
    logic   [15:0]  bid     ;
    logic           bready  ;
    logic   [1:0]   bresp   ;
    logic           bvalid  ;
    logic   [15:0]  arid    ;
    logic   [39:0]  araddr  ;
    logic           arready ;
    logic           arvalid ;
    logic   [15:0]  rid     ;
    logic   [1:0]   rresp   ;
    logic           rlast   ;
    logic   [127:0] rdata   ;
    logic           rvalid  ;
    logic           rready  ;

    design_1
        u_design1
            (
                .pl_clk0_0                  (aclk       ),
                .pl_resetn0_0               (aresetn    ),

                .M_AXI_HPM0_FPD_0_awid      (awid       ),
                .M_AXI_HPM0_FPD_0_awaddr    (awaddr     ),
                .M_AXI_HPM0_FPD_0_awlen     (           ),
                .M_AXI_HPM0_FPD_0_awsize    (           ),
                .M_AXI_HPM0_FPD_0_awcache   (           ),
                .M_AXI_HPM0_FPD_0_awlock    (           ),
                .M_AXI_HPM0_FPD_0_awprot    (           ),
                .M_AXI_HPM0_FPD_0_awqos     (           ),
                .M_AXI_HPM0_FPD_0_awburst   (           ),
                .M_AXI_HPM0_FPD_0_awuser    (           ),
                .M_AXI_HPM0_FPD_0_awvalid   (awvalid    ),
                .M_AXI_HPM0_FPD_0_awready   (awready    ),
                .M_AXI_HPM0_FPD_0_wlast     (           ),
                .M_AXI_HPM0_FPD_0_wdata     (wdata      ),
                .M_AXI_HPM0_FPD_0_wstrb     (           ),
                .M_AXI_HPM0_FPD_0_wvalid    (wvalid     ),
                .M_AXI_HPM0_FPD_0_wready    (wready     ),
                .M_AXI_HPM0_FPD_0_bid       (bid        ),
                .M_AXI_HPM0_FPD_0_bready    (bready     ),
                .M_AXI_HPM0_FPD_0_bresp     (bresp      ),
                .M_AXI_HPM0_FPD_0_bvalid    (bvalid     ),
                .M_AXI_HPM0_FPD_0_arid      (arid       ),
                .M_AXI_HPM0_FPD_0_araddr    (araddr     ),
                .M_AXI_HPM0_FPD_0_arlen     (           ),
                .M_AXI_HPM0_FPD_0_arsize    (           ),
                .M_AXI_HPM0_FPD_0_arcache   (           ),
                .M_AXI_HPM0_FPD_0_arlock    (           ),
                .M_AXI_HPM0_FPD_0_arprot    (           ),
                .M_AXI_HPM0_FPD_0_arqos     (           ),
                .M_AXI_HPM0_FPD_0_arburst   (           ),
                .M_AXI_HPM0_FPD_0_aruser    (           ),
                .M_AXI_HPM0_FPD_0_arready   (arready    ),
                .M_AXI_HPM0_FPD_0_arvalid   (arvalid    ),
                .M_AXI_HPM0_FPD_0_rid       (rid        ),
                .M_AXI_HPM0_FPD_0_rresp     (rresp      ),
                .M_AXI_HPM0_FPD_0_rlast     (rlast      ),
                .M_AXI_HPM0_FPD_0_rdata     (rdata      ),
                .M_AXI_HPM0_FPD_0_rvalid    (rvalid     ),
                .M_AXI_HPM0_FPD_0_rready    (rready     )
            );
    

    // ---------------------------------
    //  AXI バスから LED を書き換え
    // ---------------------------------

    // 前の書き込みが終わっており、書き込みアドレスと書き込みデータを両方揃うまで待ち合わせ
    assign awready = (!bvalid || bready) && (awvalid && wvalid);
    assign wready  = (!bvalid || bready) && (awvalid && wvalid);

    // 前の読み出しが終わっていれば受付可能
    assign arready = (!rvalid || rready);

    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin   // AXIバスの論理は負論理
            // 初期化(リセット不要には X を入れている)
            bid     <= 'x   ;
            bresp   <= 'x   ;
            bvalid  <= 1'b0 ;
            rid     <= 'x   ;
            rresp   <= 'x   ;
            rlast   <= 'x   ;
            rdata   <= 'x   ;   // 初期化不要なものは不定値にしておく
            rvalid  <= 1'b0 ;
            led     <= 0    ;
        end
        else begin
            // valid を出しているときに ready であれば受け付けられたとして valid を倒す
            if ( bready ) begin bvalid <= 1'b0; end
            if ( rready ) begin rvalid <= 1'b0; end

            // 書き込みの受付
            if ( (awvalid && awready) && (wvalid && wready) ) begin
                led    <= wdata[0]  ;   // 書き込まれた値をLED値とする
                bid    <= awid      ;   // IDを返す
                bresp  <= '0        ;   // 正常完了
                bvalid <= 1'b1      ;
            end

            // 読み込みの受付
            if ( arvalid && rready ) begin
                rid    <= arid      ;   // IDを返す
                rresp  <= '0        ;   // 正常完了
                rlast  <= 1'b1      ;   // 最後のデータであることを示す(シングルアクセスなら常に1)
                rdata  <= 128'(led) ;   // LEDの状態を返す
                rvalid <= 1'b1      ;
            end
        end
    end

endmodule

