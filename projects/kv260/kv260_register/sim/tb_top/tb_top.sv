// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuji Fuchikami 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_top();

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        #1000000;
        $finish;
    end


    // ---------------------------------
    //  clock & reset
    // ---------------------------------

    localparam RATE = 1000.0/100.00;

    logic           reset = 1;
    initial #100 reset = 0;

    logic           clk = 1'b1;
    always #(RATE/2.0) clk <= ~clk;

    

    // -----------------------------------------
    //  top
    // -----------------------------------------
    
    kv260_register
        i_top
            (
                .pmod           (),
                .fan_en         ()
            );


    // -----------------------------------------
    // AXI4-Lite
    // -----------------------------------------

    localparam  int      AXI4L_ADDR_BITS = 40;
    localparam  int      AXI4L_DATA_BITS = 32;

    jelly3_axi4l_if
            #(
                .ADDR_BITS  (AXI4L_ADDR_BITS),
                .DATA_BITS  (AXI4L_DATA_BITS)
            )
        i_axi4l_peri
            (
                .aresetn    (~reset),
                .aclk       (clk)
            );


    always_comb force i_top.i_design_1.m_axi4l_aresetn = i_axi4l_peri.aresetn;
    always_comb force i_top.i_design_1.m_axi4l_aclk    = i_axi4l_peri.aclk   ;
    always_comb force i_top.i_design_1.m_axi4l_awaddr  = i_axi4l_peri.awaddr ;
    always_comb force i_top.i_design_1.m_axi4l_awprot  = i_axi4l_peri.awprot ;
    always_comb force i_top.i_design_1.m_axi4l_awvalid = i_axi4l_peri.awvalid;
    always_comb force i_top.i_design_1.m_axi4l_wstrb   = i_axi4l_peri.wstrb  ;
    always_comb force i_top.i_design_1.m_axi4l_wdata   = i_axi4l_peri.wdata  ;
    always_comb force i_top.i_design_1.m_axi4l_wvalid  = i_axi4l_peri.wvalid ;
    always_comb force i_top.i_design_1.m_axi4l_bready  = i_axi4l_peri.bready ;
    always_comb force i_top.i_design_1.m_axi4l_araddr  = i_axi4l_peri.araddr ;
    always_comb force i_top.i_design_1.m_axi4l_arprot  = i_axi4l_peri.arprot ;
    always_comb force i_top.i_design_1.m_axi4l_arvalid = i_axi4l_peri.arvalid;
    always_comb force i_top.i_design_1.m_axi4l_rready  = i_axi4l_peri.rready ;

    assign i_axi4l_peri.awready = i_top.i_design_1.m_axi4l_awready ;
    assign i_axi4l_peri.wready  = i_top.i_design_1.m_axi4l_wready  ;
    assign i_axi4l_peri.bresp   = i_top.i_design_1.m_axi4l_bresp   ;
    assign i_axi4l_peri.bvalid  = i_top.i_design_1.m_axi4l_bvalid  ;
    assign i_axi4l_peri.arready = i_top.i_design_1.m_axi4l_arready ;
    assign i_axi4l_peri.rdata   = i_top.i_design_1.m_axi4l_rdata   ;
    assign i_axi4l_peri.rresp   = i_top.i_design_1.m_axi4l_rresp   ;
    assign i_axi4l_peri.rvalid  = i_top.i_design_1.m_axi4l_rvalid  ;

    jelly3_axi4l_accessor
            #(
                .RAND_RATE_AW   (50),
                .RAND_RATE_W    (50),
                .RAND_RATE_B    (50),
                .RAND_RATE_AR   (50),
                .RAND_RATE_R    (50)
            )
        u_axi4l_accessor
            (
                .m_axi4l        (i_axi4l_peri)
            );

    initial begin
        logic [AXI4L_DATA_BITS-1:0]  rdata;

        #1000;

        // REG0

        // read initial value
        u_axi4l_accessor.read(40'ha000_0000, rdata);
        assert( rdata == 32'h0000_0000 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha000_0004, rdata);
        assert( rdata == 32'h0000_0000 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha000_0008, rdata);
        assert( rdata == 32'h0000_0000 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha000_000c, rdata);
        assert( rdata == 32'h0000_0000 ) else begin $display("read data mismatch"); $fatal; end

        // write test
        u_axi4l_accessor.write(40'ha000_0000, 32'h1100_0011, 4'hf);
        u_axi4l_accessor.write(40'ha000_0004, 32'h0022_2200, 4'hf);
        u_axi4l_accessor.write(40'ha000_0008, 32'h3333_3333, 4'hf);
        u_axi4l_accessor.write(40'ha000_000c, 32'h4040_4040, 4'hf);

        u_axi4l_accessor.read(40'ha000_0000, rdata);
        assert( rdata == 32'h1100_0011 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha000_0004, rdata);
        assert( rdata == 32'h0022_2200 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha000_0008, rdata);
        assert( rdata == 32'h3333_3333 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha000_000c, rdata);
        assert( rdata == 32'h4040_4040 ) else begin $display("read data mismatch"); $fatal; end

        // strb test
        u_axi4l_accessor.write(40'ha000_0000, 32'h44aa_aaaa, 4'h8);
        u_axi4l_accessor.write(40'ha000_0004, 32'hbb55_bbbb, 4'h4);
        u_axi4l_accessor.write(40'ha000_0008, 32'hcccc_66cc, 4'h2);
        u_axi4l_accessor.write(40'ha000_000c, 32'hffff_ff77, 4'h1);

        u_axi4l_accessor.read(40'ha000_0000, rdata);
        assert( rdata == 32'h4400_0011 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha000_0004, rdata);
        assert( rdata == 32'h0055_2200 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha000_0008, rdata);
        assert( rdata == 32'h3333_6633 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha000_000c, rdata);
        assert( rdata == 32'h4040_4077 ) else begin $display("read data mismatch"); $fatal; end


        // REG0

        // read initial value
        u_axi4l_accessor.read(40'ha001_0000, rdata);
        assert( rdata == 32'h0000_0000 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha001_0004, rdata);
        assert( rdata == 32'h0000_0000 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha001_0008, rdata);
        assert( rdata == 32'h0000_0000 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha001_000c, rdata);
        assert( rdata == 32'h0000_0000 ) else begin $display("read data mismatch"); $fatal; end

        // write test
        u_axi4l_accessor.write(40'ha001_0000, 32'h1100_0011, 4'hf);
        u_axi4l_accessor.write(40'ha001_0004, 32'h0022_2200, 4'hf);
        u_axi4l_accessor.write(40'ha001_0008, 32'h3333_3333, 4'hf);
        u_axi4l_accessor.write(40'ha001_000c, 32'h4040_4040, 4'hf);

        u_axi4l_accessor.read(40'ha001_0000, rdata);
        assert( rdata == 32'h1100_0011 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha001_0004, rdata);
        assert( rdata == 32'h0022_2200 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha001_0008, rdata);
        assert( rdata == 32'h3333_3333 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha001_000c, rdata);
        assert( rdata == 32'h4040_4040 ) else begin $display("read data mismatch"); $fatal; end

        // strb test
        u_axi4l_accessor.write(40'ha001_0000, 32'h44aa_aaaa, 4'h8);
        u_axi4l_accessor.write(40'ha001_0004, 32'hbb55_bbbb, 4'h4);
        u_axi4l_accessor.write(40'ha001_0008, 32'hcccc_66cc, 4'h2);
        u_axi4l_accessor.write(40'ha001_000c, 32'hffff_ff77, 4'h1);

        u_axi4l_accessor.read(40'ha001_0000, rdata);
        assert( rdata == 32'h4400_0011 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha001_0004, rdata);
        assert( rdata == 32'h0055_2200 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha001_0008, rdata);
        assert( rdata == 32'h3333_6633 ) else begin $display("read data mismatch"); $fatal; end
        u_axi4l_accessor.read(40'ha001_000c, rdata);
        assert( rdata == 32'h4040_4077 ) else begin $display("read data mismatch"); $fatal; end
    
    end
    


endmodule



`default_nettype wire


// end of file
