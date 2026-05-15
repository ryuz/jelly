`timescale 1ns / 1ps
`default_nettype none

`include "../../../../rtl/v3/bus/jelly3_axi4_arbiter_inorder.sv"


module tb_main
        (
            input   var logic   reset   ,
            input   var logic   clk
        );

    // -------------------------
    //  DUT
    // -------------------------

    localparam  int     NUM       = 3;
    localparam  int     ID_BITS   = 4;
    localparam  int     ADDR_BITS = 32;
    localparam  int     DATA_BITS = 32;
    localparam  int     STRB_BITS = DATA_BITS / 8;
    localparam  int     LEN_BITS  = 8;

    localparam  type    id_t      = logic [ID_BITS-1:0];
    localparam  type    addr_t    = logic [ADDR_BITS-1:0];
    localparam  type    data_t    = logic [DATA_BITS-1:0];
    localparam  type    strb_t    = logic [STRB_BITS-1:0];
    localparam  type    len_t     = logic [LEN_BITS-1:0];

    logic   aresetn;
    logic   aclk;
    logic   aclken;
    assign aresetn = ~reset;
    assign aclk    = clk;
    assign aclken  = 1'b1;

    jelly3_axi4_if
            #(
                .ID_BITS    (ID_BITS    ),
                .ADDR_BITS  (ADDR_BITS  ),
                .DATA_BITS  (DATA_BITS  ),
                .SIMULATION ("true"     )
            )
        s_axi4[NUM]
            (
                .aresetn    (aresetn    ),
                .aclk       (aclk       ),
                .aclken     (aclken     )
            );

    jelly3_axi4_if
            #(
                .ID_BITS    (ID_BITS    ),
                .ADDR_BITS  (ADDR_BITS  ),
                .DATA_BITS  (DATA_BITS  ),
                .SIMULATION ("true"     )
            )
        m_axi4
            (
                .aresetn    (aresetn    ),
                .aclk       (aclk       ),
                .aclken     (aclken     )
            );

    jelly3_axi4_arbiter_inorder
            #(
                .NUM            (NUM            ),
                .M_AWID         (2              ),
                .M_ARID         (3              ),
                .FIFO_PTR_BITS  (4              ),
                .FIFO_RAM_TYPE  ("distributed"  ),
                .FIFO_DOUT_REG  (0              )
            )
        u_axi4_arbiter_inorder
            (
                .s_axi4     (s_axi4     ),
                .m_axi4     (m_axi4     )
            );


    // -------------------------
    //  Model (slave-side memory model)
    // -------------------------

    jelly3_model_axi4_s
            #(
                .MEM_ADDR_BITS      (14             ),
                .READ_DATA_ADDR     (1              ),
                .WRITE_LOG_FILE     ("w_log.txt"    ),
                .READ_LOG_FILE      ("r_log.txt"    ),
                .AW_DELAY           (0              ),
                .AR_DELAY           (0              ),
                .AW_FIFO_PTR_BITS   (0              ),
                .W_FIFO_PTR_BITS    (0              ),
                .B_FIFO_PTR_BITS    (0              ),
                .AR_FIFO_PTR_BITS   (0              ),
                .R_FIFO_PTR_BITS    (0              ),
                .AW_BUSY_RATE       (40             ),
                .W_BUSY_RATE        (40             ),
                .B_BUSY_RATE        (40             ),
                .AR_BUSY_RATE       (40             ),
                .R_BUSY_RATE        (40             ),
                .AW_RAND_SEED       (101            ),
                .W_RAND_SEED        (102            ),
                .B_RAND_SEED        (103            ),
                .AR_RAND_SEED       (104            ),
                .R_RAND_SEED        (105            )
            )
        u_model_axi4_s
            (
                .s_axi4             (m_axi4.s       )
            );


    // -------------------------
    //  Interface mapping
    // -------------------------

    id_t      s_awid    [NUM-1:0];
    addr_t    s_awaddr  [NUM-1:0];
    len_t     s_awlen   [NUM-1:0];
    logic     [NUM-1:0][2:0] s_awsize;
    logic     [NUM-1:0][1:0] s_awburst;
    logic     [NUM-1:0] s_awvalid;
    logic     [NUM-1:0] s_awready;

    data_t    s_wdata   [NUM-1:0];
    strb_t    s_wstrb   [NUM-1:0];
    logic     [NUM-1:0] s_wlast;
    logic     [NUM-1:0] s_wvalid;
    logic     [NUM-1:0] s_wready;

    id_t      s_bid     [NUM-1:0];
    logic     [NUM-1:0] s_bvalid;
    logic     [NUM-1:0] s_bready;

    id_t      s_arid    [NUM-1:0];
    addr_t    s_araddr  [NUM-1:0];
    len_t     s_arlen   [NUM-1:0];
    logic     [NUM-1:0][2:0] s_arsize;
    logic     [NUM-1:0][1:0] s_arburst;
    logic     [NUM-1:0] s_arvalid;
    logic     [NUM-1:0] s_arready;

    id_t      s_rid     [NUM-1:0];
    logic     [NUM-1:0] s_rvalid;
    logic     [NUM-1:0] s_rready;

    for ( genvar i = 0; i < NUM; i++ ) begin : g_if_map
        assign s_axi4[i].awid     = s_awid   [i];
        assign s_axi4[i].awaddr   = s_awaddr [i];
        assign s_axi4[i].awlen    = s_awlen  [i];
        assign s_axi4[i].awsize   = s_awsize [i];
        assign s_axi4[i].awburst  = s_awburst[i];
        assign s_axi4[i].awlock   = '0;
        assign s_axi4[i].awcache  = '0;
        assign s_axi4[i].awprot   = '0;
        assign s_axi4[i].awqos    = '0;
        assign s_axi4[i].awregion = '0;
        assign s_axi4[i].awuser   = '0;
        assign s_axi4[i].awvalid  = s_awvalid[i];
        assign s_awready[i]       = s_axi4[i].awready;

        assign s_axi4[i].wdata    = s_wdata [i];
        assign s_axi4[i].wstrb    = s_wstrb [i];
        assign s_axi4[i].wlast    = s_wlast [i];
        assign s_axi4[i].wuser    = '0;
        assign s_axi4[i].wvalid   = s_wvalid[i];
        assign s_wready[i]        = s_axi4[i].wready;

        assign s_bid[i]           = s_axi4[i].bid;
        assign s_bvalid[i]        = s_axi4[i].bvalid;
        assign s_axi4[i].bready   = s_bready[i];

        assign s_axi4[i].arid     = s_arid   [i];
        assign s_axi4[i].araddr   = s_araddr [i];
        assign s_axi4[i].arlen    = s_arlen  [i];
        assign s_axi4[i].arsize   = s_arsize [i];
        assign s_axi4[i].arburst  = s_arburst[i];
        assign s_axi4[i].arlock   = '0;
        assign s_axi4[i].arcache  = '0;
        assign s_axi4[i].arprot   = '0;
        assign s_axi4[i].arqos    = '0;
        assign s_axi4[i].arregion = '0;
        assign s_axi4[i].aruser   = '0;
        assign s_axi4[i].arvalid  = s_arvalid[i];
        assign s_arready[i]       = s_axi4[i].arready;

        assign s_rid[i]           = s_axi4[i].rid;
        assign s_rvalid[i]        = s_axi4[i].rvalid;
        assign s_axi4[i].rready   = s_rready[i];
    end


    // -------------------------
    //  Assertions: Master port ID must be fixed
    // -------------------------

    property prop_m_awid_fixed;
        @(posedge aclk) disable iff (reset)
            (m_axi4.awvalid) |-> (m_axi4.awid == 2);
    endproperty
    assert property (prop_m_awid_fixed) else $error("ERROR: Master AWID is not fixed!");

    property prop_m_arid_fixed;
        @(posedge aclk) disable iff (reset)
            (m_axi4.arvalid) |-> (m_axi4.arid == 3);
    endproperty
    assert property (prop_m_arid_fixed) else $error("ERROR: Master ARID is not fixed!");


    // -------------------------
    //  Traffic generation
    // -------------------------

    int     cycle;
    int     write_accept_count [NUM];
    int     read_accept_count  [NUM];
    localparam int CYCLE_LIMIT = 5000;

    initial begin
        for ( int i = 0; i < NUM; i++ ) begin
            s_awid[i]     = id_t'(i);
            s_arid[i]     = id_t'(i);
            s_awaddr[i]   = 32'h0000_0000;
            s_araddr[i]   = 32'h0000_0100 + i * 32'h0000_0010;
            s_awlen[i]    = 0;
            s_arlen[i]    = 0;
            s_awsize[i]   = 2;
            s_arsize[i]   = 2;
            s_awburst[i]  = 1;
            s_arburst[i]  = 1;
            s_awvalid[i]  = 1'b0;
            s_arvalid[i]  = 1'b0;
            s_wdata[i]    = 0;
            s_wstrb[i]    = '1;
            s_wvalid[i]   = 1'b0;
            s_wlast[i]    = 1'b1;
            s_bready[i]   = 1'b1;
            s_rready[i]   = 1'b1;

            write_accept_count[i] = 0;
            read_accept_count[i]  = 0;
        end

        for ( cycle = 0; cycle < CYCLE_LIMIT; cycle++ ) begin
            for ( int i = 0; i < NUM; i++ ) begin
                // Write transactions: Issue every few cycles
                if ( (cycle % (10 * (i+1)) == 0) && !s_awvalid[i] && !s_wvalid[i] ) begin
                    s_awaddr[i] = addr_t'({$urandom_range(0, 15), 4'h0});
                    s_awlen[i]  = len_t'(0);
                    s_awvalid[i] = 1'b1;
                    s_wvalid[i]  = 1'b1;
                    s_wdata[i]  = $urandom();
                    s_wlast[i]  = 1'b1;
                end

                if ( s_awready[i] && s_awvalid[i] ) begin
                    s_awvalid[i] = 1'b0;
                end

                if ( s_wready[i] && s_wvalid[i] && s_wlast[i] ) begin
                    s_wvalid[i] = 1'b0;
                end

                // Read transactions: Issue every few cycles
                if ( (cycle % (12 * (i+1)) == 1) && !s_arvalid[i] ) begin
                    s_araddr[i] = addr_t'({$urandom_range(0, 15), 4'h0});
                    s_arlen[i]  = len_t'(0);
                    s_arvalid[i] = 1'b1;
                end

                if ( s_arready[i] && s_arvalid[i] ) begin
                    s_arvalid[i] = 1'b0;
                end

                // Track write responses with ID
                if ( s_bvalid[i] && s_bready[i] ) begin
                    if ( s_bid[i] != id_t'(i) ) begin
                        $error("ERROR: Slave %d received response with wrong ID %d (expected %d) at cycle %d", i, s_bid[i], i, cycle);
                    end else begin
                        $display("SUCCESS: Slave %d write response with correct ID %d at cycle %d", i, s_bid[i], cycle);
                    end
                    write_accept_count[i]++;
                end

                // Track read responses with ID
                if ( s_rvalid[i] && s_rready[i] ) begin
                    if ( s_rid[i] != id_t'(i) ) begin
                        $error("ERROR: Slave %d received read response with wrong ID %d (expected %d) at cycle %d", i, s_rid[i], i, cycle);
                    end else begin
                        $display("SUCCESS: Slave %d read response with correct ID %d at cycle %d", i, s_rid[i], cycle);
                    end
                    read_accept_count[i]++;
                end
            end

            @(posedge aclk);
        end

        // Summary
        $display("\n=== Test Summary ===");
        for ( int i = 0; i < NUM; i++ ) begin
            $display("Slave %d: %d write responses, %d read responses", i, write_accept_count[i], read_accept_count[i]);
        end

        $display("\nTest completed successfully!");
        $finish;
    end

endmodule


`default_nettype wire


// end of file
