

`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
    #1000000
        $finish;
    end
    
    // ---------------------------------
    //  reset & clock
    // ---------------------------------

    localparam RATE = 1000.0/100.00;

    logic       reset = 1'b1;
    initial #(RATE*100) reset = 1'b0;

    logic       clk = 1'b1;
    initial forever #(RATE/2.0) clk = ~clk;


    
    // ---------------------------------
    //  main
    // ---------------------------------

    typedef logic   [39:0]  addr_t;
    typedef logic   [127:0] data_t;
    typedef logic   [15:0]  strb_t;
    typedef logic   [2:0]   prot_t;
    typedef logic   [1:0]   resp_t;

    logic   aresetn ;
    logic   aclk    ;
    addr_t  awaddr  ;
    prot_t  awprot  ;
    logic   awvalid ;
    logic   awready ;
    data_t  wdata   ;
    strb_t  wstrb   ;
    logic   wvalid  ;
    logic   wready  ;
    resp_t  bresp   ;
    logic   bvalid  ;
    logic   bready  ;
    addr_t  araddr  ;
    prot_t  arprot  ;
    logic   arvalid ;
    logic   arready ;
    data_t  rdata   ;
    resp_t  rresp   ;
    logic   rvalid  ;
    logic   rready  ;

    assign aresetn = ~reset ;
    assign aclk    = clk    ;

    tb_main
        u_tb_main
            (
                .s_axi4l_aresetn    (aresetn    ),
                .s_axi4l_aclk       (aclk       ),
                .s_axi4l_awaddr     (awaddr     ),
                .s_axi4l_awprot     (awprot     ),
                .s_axi4l_awvalid    (awvalid    ),
                .s_axi4l_awready    (awready    ),
                .s_axi4l_wdata      (wdata      ),
                .s_axi4l_wstrb      (wstrb      ),
                .s_axi4l_wvalid     (wvalid     ),
                .s_axi4l_wready     (wready     ),
                .s_axi4l_bresp      (bresp      ),
                .s_axi4l_bvalid     (bvalid     ),
                .s_axi4l_bready     (bready     ),
                .s_axi4l_araddr     (araddr     ),
                .s_axi4l_arprot     (arprot     ),
                .s_axi4l_arvalid    (arvalid    ),
                .s_axi4l_arready    (arready    ),
                .s_axi4l_rdata      (rdata      ),
                .s_axi4l_rresp      (rresp      ),
                .s_axi4l_rvalid     (rvalid     ),
                .s_axi4l_rready     (rready     )
            );
    
    
    // ---------------------------------
    //  Test
    // ---------------------------------

    initial begin
        data_t rdata;
        // リセット解除待ち
        #10000;

        forever begin
            // LED を ON
            write(addr_t'(0), data_t'(1), strb_t'('hffff)); // 1を書く
            read(addr_t'(0), rdata);                        // 読み出す
            #10000;
    
            // LED を OFF
            write(addr_t'(0), data_t'(0), strb_t'('hffff)); // 0を書く
            read(addr_t'(0), rdata);                        // 読み出す
            #10000;
        end
    end


    // ---------------------------------
    //  Access Task
    // ---------------------------------

    localparam EPSILON = 0.01;

    initial begin
        awvalid = 1'b0  ;
        wvalid  = 1'b0  ;
        bready  = 1'b1  ;
        arvalid = 1'b0  ;
        rready  = 1'b1  ;
    end

    logic   issue_aw;
    logic   issue_w ;
    logic   issue_b ;
    logic   issue_ar;
    logic   issue_r ;
    always_ff @(posedge aclk) begin
        issue_aw <= awvalid & awready   ;
        issue_w  <= wvalid  & wready    ;
        issue_b  <= bvalid  & bready    ;
        issue_ar <= arvalid & arready   ;
        issue_r  <= rvalid  & rready    ;
    end

    task write(
                input   addr_t  addr,
                input   data_t  data,
                input   strb_t  strb
            );
        $display("[axi4l write] addr:%x <= data:%x strb:%x", addr, data, strb);
        @(posedge aclk); #EPSILON;
        awaddr  = addr;
        awprot  = '0;
        awvalid = 1'b1;
        wstrb   = strb;
        wdata   = data;
        wvalid  = 1'b1;

        @(posedge aclk); #EPSILON;
        while ( awvalid || wvalid ) begin
            if ( issue_aw ) begin
                awaddr  = 'x;
                awprot  = 'x;
                awvalid = 1'b0;
            end
            if ( issue_w ) begin
                wstrb   = 'x;
                wdata   = 'x;
                wvalid  = 1'b0;
            end
            @(posedge aclk); #EPSILON;
        end

        while ( !issue_b ) begin
            @(posedge aclk); #EPSILON;
        end
    endtask

    task read(
                input   addr_t  addr,
                output  data_t  data
            );
        @(posedge aclk); #EPSILON;
        araddr  = addr;
        arprot  = '0;
        arvalid = 1'b1;
        @(posedge aclk); #EPSILON;
        while ( !issue_ar ) begin
            @(posedge aclk); #EPSILON;
        end

        araddr  = 'x;
        arprot  = 'x;
        arvalid = 1'b0;
        @(posedge aclk); #EPSILON;
        while ( !issue_r ) begin
            @(posedge aclk); #EPSILON;
        end
        data = rdata;
        $display("[axi4l read] addr:%x => data:%x", addr, data);
    endtask


endmodule


`default_nettype wire
