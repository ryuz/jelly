// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//  Random test for jelly3_axi4_arbiter_inorder
//  - NUM=4 masters, each accessing its own non-overlapping 256-byte region
//  - Master-side and slave-side mem checkers verify read/write consistency
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

`include "../../../../rtl/v3/bus/jelly3_axi4_arbiter_inorder.sv"


module tb_main
        (
            input   var logic   reset   ,
            input   var logic   clk
        );

    // -----------------------------------------------------------------------
    //  Parameters
    // -----------------------------------------------------------------------

    localparam  int     NUM         = 4         ;   // number of masters
    localparam  int     S_ID_BITS   = 8         ;   // source-side ID bits
    localparam  int     M_ID_BITS   = 2         ;   // fixed downstream ID bits
    localparam  int     ADDR_BITS   = 32        ;
    localparam  int     DATA_BITS   = 32        ;

    // Each master accesses an independent 256-byte address region:
    //   master 0 : 0x0000_0100 .. 0x0000_01ff
    //   master 1 : 0x0000_0200 .. 0x0000_02ff
    //   master 2 : 0x0000_0300 .. 0x0000_03ff
    //   master 3 : 0x0000_0400 .. 0x0000_04ff
    localparam  longint unsigned    REGION_BASE  = 64'h100   ;   // start of master-0 region
    localparam  longint unsigned    REGION_STEP  = 64'h100   ;   // step between regions
    localparam  longint unsigned    REGION_SIZE  = 64'h100   ;   // size of each region (bytes)

    localparam  int     PHASE_CYCLES       = 10000  ;   // cycles per per-master phase
    localparam  int     CONCURRENT_CYCLES  = 30000  ;   // cycles for all-master concurrent phase


    // -----------------------------------------------------------------------
    //  Clocks / reset
    // -----------------------------------------------------------------------

    logic   aresetn ;
    logic   aclk    ;
    logic   aclken  ;

    assign aresetn = ~reset ;
    assign aclk    = clk    ;
    assign aclken  = 1'b1   ;


    // -----------------------------------------------------------------------
    //  Interfaces
    // -----------------------------------------------------------------------

    // slave ports (NUM masters connect here)
    jelly3_axi4_if
            #(
                .ID_BITS        (S_ID_BITS  ),
                .ADDR_BITS      (ADDR_BITS  ),
                .DATA_BITS      (DATA_BITS  ),
                .ALLOW_RDATA_X  (1          ),
                .SIMULATION     ("true"     )
            )
        s_axi4 [NUM]
            (
                .aresetn        (aresetn    ),
                .aclk           (aclk       ),
                .aclken         (aclken     )
            );

    jelly3_axi4_if
            #(
                .ID_BITS        (M_ID_BITS  ),
                .ADDR_BITS      (ADDR_BITS  ),
                .DATA_BITS      (DATA_BITS  ),
                .ALLOW_RDATA_X  (1          ),
                .SIMULATION     ("true"     )
            )
        m_axi4
            (
                .aresetn        (aresetn    ),
                .aclk           (aclk       ),
                .aclken         (aclken     )
            );


    // -----------------------------------------------------------------------
    //  DUT : jelly3_axi4_arbiter
    // -----------------------------------------------------------------------

    jelly3_axi4_arbiter_inorder
            #(
                .NUM        (NUM        )
            )
        u_arbiter
            (
                .s_axi4     (s_axi4     ),
                .m_axi4     (m_axi4.m   )
            );


    // -----------------------------------------------------------------------
    //  Slave memory model
    //  READ_DATA_ADDR=0 : returns actual stored data (not the address value)
    // -----------------------------------------------------------------------

    jelly3_model_axi4_s
            #(
                .MEM_ADDR_BITS      (12                     ),
                .READ_DATA_ADDR     (0                      ),
                .WRITE_LOG_FILE     ("axi4_write_log.txt"   ),
                .READ_LOG_FILE      ("axi4_read_log.txt"    ),
                .AW_DELAY           (0                      ),
                .AR_DELAY           (0                      ),
                .AW_FIFO_PTR_BITS   (0                      ),
                .W_FIFO_PTR_BITS    (0                      ),
                .B_FIFO_PTR_BITS    (0                      ),
                .AR_FIFO_PTR_BITS   (0                      ),
                .R_FIFO_PTR_BITS    (0                      ),
                .AW_BUSY_RATE       (15                     ),
                .W_BUSY_RATE        (15                     ),
                .B_BUSY_RATE        (15                     ),
                .AR_BUSY_RATE       (15                     ),
                .R_BUSY_RATE        (15                     ),
                .AW_RAND_SEED       (600                    ),
                .W_RAND_SEED        (601                    ),
                .B_RAND_SEED        (602                    ),
                .AR_RAND_SEED       (603                    ),
                .R_RAND_SEED        (604                    )
            )
        u_slave
            (
                .s_axi4             (m_axi4.s       )
            );


    // -----------------------------------------------------------------------
    //  Slave-side memory checker
    //  Monitors merged traffic on m_axi4 and checks data and response protocol
    // -----------------------------------------------------------------------

    jelly3_model_axi4_mem_check
            #(
                .SHOW_MATCH         (0              ),
                .SHOW_SKIP          (0              ),
                .CHECK_BRESP        (1              ),
                .CHECK_RRESP        (1              ),
                .CHECK_WLAST        (1              ),
                .CHECK_RLAST        (1              )
            )
        u_slave_check
            (
                .mon_axi4           (m_axi4.mon     )
            );


    // -----------------------------------------------------------------------
    //  Per-master : traffic model + master-side checker
    //
    //  The arbiter replaces downstream IDs with fixed values and queues each
    //  source ID for restoration when the response returns.
    // -----------------------------------------------------------------------

    logic [NUM-1:0]     enable      ;
    logic [NUM-1:0]     busy        ;

    for (genvar i = 0; i < NUM; i++) begin : g_master

        // address range for master i
        localparam longint unsigned ADDR_LOW  = REGION_BASE + REGION_STEP * i;
        localparam longint unsigned ADDR_HIGH = REGION_BASE + REGION_STEP * i + REGION_SIZE - 1;

        jelly3_model_axi4_m
                #(
                    .WADDR_LOW          (ADDR_LOW           ),
                    .WADDR_HIGH         (ADDR_HIGH          ),
                    .RADDR_LOW          (ADDR_LOW           ),
                    .RADDR_HIGH         (ADDR_HIGH          ),
                    .AW_BUSY_RATE       (95 - i * 5         ),
                    .W_BUSY_RATE        (95 - i * 5         ),
                    .B_BUSY_RATE        (95 - i * 5         ),
                    .AR_BUSY_RATE       (95 - i * 5         ),
                    .R_BUSY_RATE        (95 - i * 5         )
                )
            u_master
                (
                    .enable             (enable[i]          ),
                    .m_axi4             (s_axi4[i].m        )
                );

        // Master-side memory checker verifies data and LAST/RESP protocol.
        // The source-ID scoreboard below separately checks BID/RID restoration.
        jelly3_model_axi4_mem_check
                #(
                    .SHOW_MATCH         (0                  ),
                    .SHOW_SKIP          (0                  ),
                    .CHECK_BRESP        (1                  ),
                    .CHECK_RRESP        (1                  ),
                    .CHECK_WLAST        (1                  ),
                    .CHECK_RLAST        (1                  )
                )
            u_master_check
                (
                    .mon_axi4           (s_axi4[i].mon      )
                );
    end : g_master


    // -----------------------------------------------------------------------
    //  Transaction counters (for summary)
    // -----------------------------------------------------------------------

    // Helper wires: mirror interface signals into plain logic arrays so that
    // the always_ff loop can index them with a non-genvar variable.
    // (Verilator rejects s_axi4[i].signal when 'i' is not a genvar.)
    logic   [NUM-1:0]   mon_awvalid ;
    logic   [NUM-1:0]   mon_awready ;
    logic   [NUM-1:0]   mon_bvalid  ;
    logic   [NUM-1:0]   mon_bready  ;
    logic   [NUM-1:0]   mon_arvalid ;
    logic   [NUM-1:0]   mon_arready ;
    logic   [NUM-1:0]   mon_rvalid  ;
    logic   [NUM-1:0]   mon_rready  ;
    logic   [NUM-1:0]   mon_rlast   ;
    logic   [S_ID_BITS-1:0] mon_awid [NUM];
    logic   [S_ID_BITS-1:0] mon_bid  [NUM];
    logic   [S_ID_BITS-1:0] mon_arid [NUM];
    logic   [S_ID_BITS-1:0] mon_rid  [NUM];

    for (genvar i = 0; i < NUM; i++) begin : g_mon_wires
        assign mon_awvalid[i] = s_axi4[i].awvalid;
        assign mon_awready[i] = s_axi4[i].awready;
        assign mon_bvalid [i] = s_axi4[i].bvalid ;
        assign mon_bready [i] = s_axi4[i].bready ;
        assign mon_arvalid[i] = s_axi4[i].arvalid;
        assign mon_arready[i] = s_axi4[i].arready;
        assign mon_rvalid [i] = s_axi4[i].rvalid ;
        assign mon_rready [i] = s_axi4[i].rready ;
        assign mon_rlast  [i] = s_axi4[i].rlast  ;
        assign mon_awid   [i] = s_axi4[i].awid   ;
        assign mon_bid    [i] = s_axi4[i].bid    ;
        assign mon_arid   [i] = s_axi4[i].arid   ;
        assign mon_rid    [i] = s_axi4[i].rid    ;
    end : g_mon_wires

    typedef logic [S_ID_BITS-1:0] s_id_t;
    s_id_t expected_bid [NUM][$];
    s_id_t expected_rid [NUM][$];

    int     cycle_count                 ;
    int     write_burst_count   [NUM]   ;
    int     write_resp_count    [NUM]   ;
    int     read_burst_count    [NUM]   ;
    int     read_resp_count     [NUM]   ;

    always_ff @(posedge aclk) begin
        if ( !aresetn ) begin
            cycle_count <= 0;
            for ( int i = 0; i < NUM; i++ ) begin
                write_burst_count[i] <= 0;
                write_resp_count [i] <= 0;
                read_burst_count [i] <= 0;
                read_resp_count  [i] <= 0;
            end
        end
        else if ( aclken ) begin
            cycle_count <= cycle_count + 1;
            for ( int i = 0; i < NUM; i++ ) begin
                if ( mon_awvalid[i] && mon_awready[i] ) begin
                    write_burst_count[i] <= write_burst_count[i] + 1;
                end
                if ( mon_bvalid[i] && mon_bready[i] ) begin
                    write_resp_count[i] <= write_resp_count[i] + 1;
                end
                if ( mon_arvalid[i] && mon_arready[i] ) begin
                    read_burst_count[i] <= read_burst_count[i] + 1;
                end
                if ( mon_rvalid[i] && mon_rready[i] && mon_rlast[i] ) begin
                    read_resp_count[i] <= read_resp_count[i] + 1;
                end
            end
        end
    end

    always @(posedge aclk) begin
        if ( !aresetn ) begin
            for ( int i = 0; i < NUM; i++ ) begin
                expected_bid[i].delete();
                expected_rid[i].delete();
            end
        end
        else if ( aclken ) begin
            for ( int i = 0; i < NUM; i++ ) begin
                if ( mon_awvalid[i] && mon_awready[i] ) begin
                    expected_bid[i].push_back(mon_awid[i]);
                end
                if ( mon_bvalid[i] && mon_bready[i] ) begin
                    if ( expected_bid[i].size() == 0 || mon_bid[i] !== expected_bid[i][0] ) begin
                        $fatal(1, "BID mismatch on master %0d: got %h expected %h", i, mon_bid[i], expected_bid[i].size() ? expected_bid[i][0] : 'x);
                    end
                    expected_bid[i].pop_front();
                end
                if ( mon_arvalid[i] && mon_arready[i] ) begin
                    expected_rid[i].push_back(mon_arid[i]);
                end
                if ( mon_rvalid[i] && mon_rready[i] ) begin
                    if ( expected_rid[i].size() == 0 || mon_rid[i] !== expected_rid[i][0] ) begin
                        $fatal(1, "RID mismatch on master %0d: got %h expected %h", i, mon_rid[i], expected_rid[i].size() ? expected_rid[i][0] : 'x);
                    end
                    if ( mon_rlast[i] ) begin
                        expected_rid[i].pop_front();
                    end
                end
            end
        end
    end


    // -----------------------------------------------------------------------
    //  Test sequence
    // -----------------------------------------------------------------------

    initial begin
        enable = '0;
        #1000;
        enable = '1;
        #1000000;
        enable = '0;
        #1000;

        for ( int i = 0; i < NUM; i++ ) begin
            if ( write_burst_count[i] == 0 || read_burst_count[i] == 0 ) begin
                $fatal(1, "No traffic observed on master %0d", i);
            end
            if ( write_burst_count[i] != write_resp_count[i] || read_burst_count[i] != read_resp_count[i] ) begin
                $fatal(1, "Outstanding transactions on master %0d: AW/B=%0d/%0d AR/RLAST=%0d/%0d", i, write_burst_count[i], write_resp_count[i], read_burst_count[i], read_resp_count[i]);
            end
        end

        $finish;
    end

endmodule

`default_nettype wire

// end of file
