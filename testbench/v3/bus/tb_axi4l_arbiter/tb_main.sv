
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset   ,
            input   var logic   clk     
        );

    // -------------------------
    //  DUT
    // -------------------------

    parameter   int     NUM       = 3   ;
    parameter   int     ADDR_BITS = 24  ;
    parameter   int     DATA_BITS = 32  ;

    logic   aresetn ;
    logic   aclk    ;
    logic   aclken  ;
    assign aresetn = ~reset ;
    assign aclk    = clk    ;
    assign aclken  = 1'b1   ;

    jelly3_axi4l_if
            #(
                .ADDR_BITS  (ADDR_BITS  ),
                .DATA_BITS  (DATA_BITS  ),
                .SIMULATION ("true"     )
            )
        s_axi4l[NUM]
            (
                .aresetn    (aresetn    ),
                .aclk       (aclk       ),
                .aclken     (aclken     )
            );
    
    jelly3_axi4l_if
            #(
                .ADDR_BITS  (ADDR_BITS  ),
                .DATA_BITS  (DATA_BITS  )
            )
        m_axi4l
            (
                .aresetn    (aresetn    ),
                .aclk       (aclk       ),
                .aclken     (aclken     )
            );

    jelly3_axi4l_arbiter
            #(
                .NUM        (NUM        )
            )
        u_axi4l_arbiter
            (
                .s_axi4l    (s_axi4l    ),
                .m_axi4l    (m_axi4l    )
            );


    // -------------------------
    //  Model
    // -------------------------

    jelly3_axi4l_terminator
            #(
                .READ_VALUE (32'h87654321)
            )
        u_axi4_accessor
            (
                .s_axi4l    (m_axi4l.s  )
            );

    int     cycle;
    localparam CYCLE_LIMIT = 1000;

    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            cycle <= '0;

            s_axi4l[0].awaddr  <= 24'h10_0000;
            s_axi4l[0].awprot  <= '0;
            s_axi4l[0].awvalid <= '0;
            s_axi4l[0].wstrb   <= 4'b1101;
            s_axi4l[0].wdata   <= 32'h1000_0000;
            s_axi4l[0].wvalid  <= '0;
            s_axi4l[0].araddr  <= 24'h11_0000;
            s_axi4l[0].arprot  <= '0;
            s_axi4l[0].arvalid <= '0;
            s_axi4l[0].bready  <= '0;
            s_axi4l[0].rready  <= '0;

            s_axi4l[1].awaddr  <= 24'h20_0000;
            s_axi4l[1].awprot  <= '0;
            s_axi4l[1].awvalid <= '0;
            s_axi4l[1].wstrb   <= 4'b1001;
            s_axi4l[1].wdata   <= 32'h2000_0000;
            s_axi4l[1].wvalid  <= '0;
            s_axi4l[1].araddr  <= 24'h22_0000;
            s_axi4l[1].arprot  <= '0;
            s_axi4l[1].arvalid <= '0;
            s_axi4l[1].bready  <= '0;
            s_axi4l[1].rready  <= '0;

            s_axi4l[2].awaddr  <= 24'h30_0000;
            s_axi4l[2].awprot  <= '0;
            s_axi4l[2].awvalid <= '0;
            s_axi4l[2].wstrb   <= 4'b0110;
            s_axi4l[2].wdata   <= 32'h3000_0000;
            s_axi4l[2].wvalid  <= '0;
            s_axi4l[2].araddr  <= 24'h33_0000;
            s_axi4l[2].arprot  <= '0;
            s_axi4l[2].arvalid <= '0;
            s_axi4l[2].bready  <= '0;
            s_axi4l[2].rready  <= '0;
        end
        else begin
            cycle <= cycle + 1;

            if ( !s_axi4l[0].awvalid || s_axi4l[0].awready) s_axi4l[0].awvalid <= $urandom_range(0, 5) == 0 && cycle < CYCLE_LIMIT;
            if ( !s_axi4l[0].wvalid  || s_axi4l[0].wready ) s_axi4l[0].wvalid  <= $urandom_range(0, 5) == 0 && cycle < CYCLE_LIMIT;
            if (  s_axi4l[0].awvalid && s_axi4l[0].awready) s_axi4l[0].awaddr  <= s_axi4l[0].awaddr + 1;
            if (  s_axi4l[0].wvalid  && s_axi4l[0].wready)  s_axi4l[0].wdata   <= s_axi4l[0].wdata  + 1;
            s_axi4l[0].bready <= 1'($urandom_range(0, 1));
            s_axi4l[0].rready <= 1'($urandom_range(0, 1));
            if ( !s_axi4l[0].arvalid || s_axi4l[0].arready) s_axi4l[0].arvalid <= $urandom_range(0, 5) == 0 && cycle < CYCLE_LIMIT;
            if (  s_axi4l[0].arvalid && s_axi4l[0].arready) s_axi4l[0].araddr  <= s_axi4l[0].araddr + 1;


            if ( !s_axi4l[1].awvalid || s_axi4l[1].awready) s_axi4l[1].awvalid <= $urandom_range(0, 3) == 0 && cycle < CYCLE_LIMIT;
            if ( !s_axi4l[1].wvalid  || s_axi4l[1].wready ) s_axi4l[1].wvalid  <= $urandom_range(0, 3) == 0 && cycle < CYCLE_LIMIT;
            if (  s_axi4l[1].awvalid && s_axi4l[1].awready) s_axi4l[1].awaddr  <= s_axi4l[1].awaddr + 1;
            if (  s_axi4l[1].wvalid  && s_axi4l[1].wready)  s_axi4l[1].wdata   <= s_axi4l[1].wdata  + 1;
            s_axi4l[1].bready <= 1'($urandom_range(0, 1));
            s_axi4l[1].rready <= 1'($urandom_range(0, 1));
            if ( !s_axi4l[1].arvalid || s_axi4l[1].arready) s_axi4l[1].arvalid <= $urandom_range(0, 3) == 0 && cycle < CYCLE_LIMIT;
            if (  s_axi4l[1].arvalid && s_axi4l[1].arready) s_axi4l[1].araddr  <= s_axi4l[1].araddr + 1;


            if ( !s_axi4l[2].awvalid || s_axi4l[2].awready) s_axi4l[2].awvalid <= 1'($urandom_range(0, 1)) && cycle < CYCLE_LIMIT;
            if ( !s_axi4l[2].wvalid  || s_axi4l[2].wready ) s_axi4l[2].wvalid  <= 1'($urandom_range(0, 1)) && cycle < CYCLE_LIMIT;
            if (  s_axi4l[2].awvalid && s_axi4l[2].awready) s_axi4l[2].awaddr  <= s_axi4l[2].awaddr + 1;
            if (  s_axi4l[2].wvalid  && s_axi4l[2].wready)  s_axi4l[2].wdata   <= s_axi4l[2].wdata  + 1;
            s_axi4l[2].bready <= 1'($urandom_range(0, 1));
            s_axi4l[2].rready <= 1'($urandom_range(0, 1));
            if ( !s_axi4l[2].arvalid || s_axi4l[2].arready) s_axi4l[2].arvalid <= 1'($urandom_range(0, 1)) && cycle < CYCLE_LIMIT;
            if (  s_axi4l[2].arvalid && s_axi4l[2].arready) s_axi4l[2].araddr  <= s_axi4l[2].araddr + 1;
        end
    end


endmodule


`default_nettype wire


// end of file
