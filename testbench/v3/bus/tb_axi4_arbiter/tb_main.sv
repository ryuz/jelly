`timescale 1ns / 1ps
`default_nettype none

`include "../../../../rtl/v3/bus/jelly3_axi4_arbiter.sv"


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

    jelly3_axi4_arbiter
            #(
                .NUM            (NUM            ),
                .FIFO_PTR_BITS  (4              ),
                .FIFO_RAM_TYPE  ("distributed"  ),
                .FIFO_DOUT_REG  (0              )
            )
        u_axi4_arbiter
            (
                .s_axi4     (s_axi4     ),
                .m_axi4     (m_axi4     )
            );


    // -------------------------
    //  Model
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

    logic     [NUM-1:0] s_bvalid;
    logic     [NUM-1:0] s_bready;

    id_t      s_arid    [NUM-1:0];
    addr_t    s_araddr  [NUM-1:0];
    len_t     s_arlen   [NUM-1:0];
    logic     [NUM-1:0][2:0] s_arsize;
    logic     [NUM-1:0][1:0] s_arburst;
    logic     [NUM-1:0] s_arvalid;
    logic     [NUM-1:0] s_arready;

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

        assign s_rvalid[i]        = s_axi4[i].rvalid;
        assign s_axi4[i].rready   = s_rready[i];
    end


    // -------------------------
    //  Traffic generation
    // -------------------------

    int     cycle;
    int     write_accept_count [NUM];
    int     read_accept_count  [NUM];
    localparam int CYCLE_LIMIT = 2000;

    function automatic bit write_fire(input int i);
        case (i)
        0: write_fire = ($urandom_range(0, 5) == 0);
        1: write_fire = ($urandom_range(0, 3) == 0);
        default: write_fire = 1'($urandom_range(0, 1));
        endcase
    endfunction

    function automatic bit read_fire(input int i);
        case (i)
        0: read_fire = ($urandom_range(0, 5) == 0);
        1: read_fire = ($urandom_range(0, 3) == 0);
        default: read_fire = 1'($urandom_range(0, 1));
        endcase
    endfunction

    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            cycle <= 0;

            for ( int i = 0; i < NUM; i++ ) begin
                write_accept_count[i] <= 0;
                read_accept_count [i] <= 0;

                s_awid   [i] <= id_t'(i);
                s_awaddr [i] <= addr_t'((24'h10_0000 * (i+1)));
                s_awlen  [i] <= '0;
                s_awsize [i] <= 3'h2;
                s_awburst[i] <= 2'b01;
                s_awvalid[i] <= 1'b0;

                s_wdata  [i] <= data_t'((32'h1000_0000 * (i+1)));
                s_wstrb  [i] <= '1;
                s_wlast  [i] <= 1'b1;
                s_wvalid [i] <= 1'b0;
                s_bready [i] <= 1'b0;

                s_arid   [i] <= id_t'(i);
                s_araddr [i] <= addr_t'((24'h20_0000 * (i+1)));
                s_arlen  [i] <= '0;
                s_arsize [i] <= 3'h2;
                s_arburst[i] <= 2'b01;
                s_arvalid[i] <= 1'b0;
                s_rready [i] <= 1'b0;
            end
        end
        else begin
            cycle <= cycle + 1;

            for ( int i = 0; i < NUM; i++ ) begin
                if ( s_awvalid[i] && s_awready[i] && s_wvalid[i] && s_wready[i] ) begin
                    write_accept_count[i] <= write_accept_count[i] + 1;
                    s_awaddr[i] <= s_awaddr[i] + 4;
                    s_wdata [i] <= s_wdata [i] + 1;
                end

                if ( s_arvalid[i] && s_arready[i] ) begin
                    read_accept_count[i] <= read_accept_count[i] + 1;
                    s_araddr[i] <= s_araddr[i] + addr_t'(4);
                    s_arlen [i] <= len_t'($urandom_range(0, 3));
                end

                if ( (!s_awvalid[i] || s_awready[i]) && (!s_wvalid[i] || s_wready[i]) ) begin
                    if ( cycle < CYCLE_LIMIT && write_fire(i) ) begin
                        s_awvalid[i] <= 1'b1;
                        s_wvalid [i] <= 1'b1;
                    end
                    else begin
                        s_awvalid[i] <= 1'b0;
                        s_wvalid [i] <= 1'b0;
                    end
                end

                if ( !s_arvalid[i] || s_arready[i] ) begin
                    if ( cycle < CYCLE_LIMIT && read_fire(i) ) begin
                        s_arvalid[i] <= 1'b1;
                    end
                    else begin
                        s_arvalid[i] <= 1'b0;
                    end
                end

                s_bready[i] <= 1'($urandom_range(0, 1));
                s_rready[i] <= 1'($urandom_range(0, 1));
            end
        end
    end


    // -------------------------
    //  Arbitration checks
    // -------------------------

    always_ff @(posedge aclk) begin
        if ( aresetn && aclken ) begin
            if ( m_axi4.arvalid && m_axi4.arready ) begin
                int ar_count;
                ar_count = 0;
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( s_arvalid[i] && s_arready[i] ) begin
                        ar_count = ar_count + 1;
                    end
                end
                assert (ar_count == 1) else $error("AR accept source count error=%0d cycle=%0d", ar_count, cycle);
            end

            if ( m_axi4.awvalid && m_axi4.awready && m_axi4.wvalid && m_axi4.wready ) begin
                int aw_count;
                aw_count = 0;
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( s_awvalid[i] && s_awready[i] && s_wvalid[i] && s_wready[i] ) begin
                        aw_count = aw_count + 1;
                    end
                end
                assert (aw_count == 1) else $error("AW/W accept source count error=%0d cycle=%0d", aw_count, cycle);
            end

            if ( cycle == CYCLE_LIMIT ) begin
                $display("write_accept_count = %0d %0d %0d", write_accept_count[0], write_accept_count[1], write_accept_count[2]);
                $display("read_accept_count  = %0d %0d %0d", read_accept_count[0],  read_accept_count[1],  read_accept_count[2]);
            end
        end
    end

endmodule


`default_nettype wire


// end of file
