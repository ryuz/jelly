`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   clk,
            input   var logic   reset
        );

    jelly3_axi4_if
            #(
                .ID_BITS    (4),
                .ADDR_BITS  (32),
                .DATA_BITS  (32),
                .SIMULATION ("true")
            )
        axi4 (
                .aresetn    (~reset),
                .aclk       (clk),
                .aclken     (1'b1)
            );

    logic error;
    logic [10:0] error_flags;
    logic [3:0] error_code;
    logic [3:0] error_id;
    logic [31:0] error_addr;
    logic [7:0] error_len;

    jelly3_axi4_protocol_checker u_checker (
        .mon_axi4    (axi4.mon),
        .error       (error),
        .error_flags (error_flags),
        .error_code  (error_code),
        .error_id    (error_id),
        .error_addr  (error_addr),
        .error_len   (error_len)
    );

    task automatic init_bus();
        axi4.addr_base = '0;
        axi4.addr_high = '1;
        axi4.awid = '0;
        axi4.awaddr = '0;
        axi4.awlen = '0;
        axi4.awsize = '0;
        axi4.awburst = '0;
        axi4.awlock = '0;
        axi4.awcache = '0;
        axi4.awprot = '0;
        axi4.awqos = '0;
        axi4.awregion = '0;
        axi4.awuser = '0;
        axi4.awvalid = 1'b0;
        axi4.awready = 1'b1;
        axi4.wdata = '0;
        axi4.wstrb = '0;
        axi4.wlast = 1'b0;
        axi4.wuser = '0;
        axi4.wvalid = 1'b0;
        axi4.wready = 1'b1;
        axi4.bid = '0;
        axi4.bresp = '0;
        axi4.buser = '0;
        axi4.bvalid = 1'b0;
        axi4.bready = 1'b1;
        axi4.arid = '0;
        axi4.araddr = '0;
        axi4.arlen = '0;
        axi4.arsize = '0;
        axi4.arburst = '0;
        axi4.arlock = '0;
        axi4.arcache = '0;
        axi4.arprot = '0;
        axi4.arqos = '0;
        axi4.arregion = '0;
        axi4.aruser = '0;
        axi4.arvalid = 1'b0;
        axi4.arready = 1'b1;
        axi4.rid = '0;
        axi4.rdata = '0;
        axi4.rresp = '0;
        axi4.rlast = 1'b0;
        axi4.ruser = '0;
        axi4.rvalid = 1'b0;
        axi4.rready = 1'b1;
    endtask

    task automatic send_aw(input logic [31:0] addr, input logic [7:0] len);
        @(negedge clk);
        axi4.awid = 4'h3;
        axi4.awaddr = addr;
        axi4.awlen = len;
        axi4.awsize = 3'h2;
        axi4.awburst = 2'b01;
        axi4.awvalid = 1'b1;
        @(posedge clk);
        @(negedge clk);
        axi4.awvalid = 1'b0;
    endtask

    task automatic send_ar(input logic [31:0] addr, input logic [7:0] len);
        @(negedge clk);
        axi4.arid = 4'h5;
        axi4.araddr = addr;
        axi4.arlen = len;
        axi4.arsize = 3'h2;
        axi4.arburst = 2'b01;
        axi4.arvalid = 1'b1;
        @(posedge clk);
        @(negedge clk);
        axi4.arvalid = 1'b0;
    endtask

    task automatic send_w(input int beats, input int last_beat);
        for ( int i = 0; i < beats; i++ ) begin
            @(negedge clk);
            axi4.wdata = 32'(i);
            axi4.wstrb = '1;
            axi4.wlast = (i == last_beat);
            axi4.wvalid = 1'b1;
            @(posedge clk);
        end
        @(negedge clk);
        axi4.wvalid = 1'b0;
        axi4.wlast = 1'b0;
    endtask

    initial begin
        init_bus();
        wait (!reset);
        repeat (2) @(posedge clk);

        send_w(2, 1);
        send_aw(32'h0000_0ff8, 8'd1);
        repeat (2) @(posedge clk);
        assert (!error)
            else $fatal(1, "legal AW ending at 4KB boundary flagged: flags=%h", error_flags);

        send_aw(32'h0000_0ff8, 8'd2);
        send_w(3, 2);
        repeat (2) @(posedge clk);
        assert (error && error_flags[0] && error_code == 4'd0)
            else $fatal(1, "AW 4KB crossing was not reported: flags=%h code=%0d", error_flags, error_code);
        assert (error_id == 4'h3 && error_addr == 32'h0000_0ff8 && error_len == 8'd2)
            else $fatal(1, "first-error capture mismatch");

        send_ar(32'h0000_0ffc, 8'd1);
        repeat (2) @(posedge clk);
        assert (error_flags[1])
            else $fatal(1, "AR 4KB crossing was not reported: flags=%h", error_flags);

        send_aw(32'h0000_0200, 8'd1);
        send_w(1, 0);
        repeat (2) @(posedge clk);
        assert (error_flags[9])
            else $fatal(1, "WLAST/AWLEN mismatch was not reported: flags=%h", error_flags);

        $display("tb_axi4_protocol_checker : PASS flags=%h first_code=%0d", error_flags, error_code);
        $finish;
    end

endmodule


`default_nettype wire


// end of file