`timescale 1ns / 1ps
`default_nettype none

`include "../../../../rtl/v3/model/jelly3_model_axi4_m.sv"
`include "../../../../rtl/v3/model/jelly3_model_axi4_mem_check.sv"


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );

    localparam  int     ID_BITS         = 4;
    localparam  int     ADDR_BITS       = 32;
    localparam  int     DATA_BITS       = 32;
    localparam  int     STRB_BITS       = DATA_BITS / 8;
    localparam  int     LEN_BITS        = 8;
    localparam  int     SIZE_BITS       = 3;
    localparam  int     DATA_BYTES      = STRB_BITS;
    localparam  int     DATA_SIZE       = $clog2(DATA_BYTES);
    localparam  int     WRITE_ADDR_LOW  = 'h0000_0100;
    localparam  int     WRITE_ADDR_HIGH = 'h0000_01ff;
    localparam  int     READ_ADDR_LOW   = 'h0000_0100;
    localparam  int     READ_ADDR_HIGH  = 'h0000_01ff;
    localparam  int     TEST_CYCLES     = 5000;
    localparam  int     WRITE_ID        = 3;
    localparam  int     READ_ID         = 5;

    localparam  type    id_t            = logic [ID_BITS-1:0]    ;
    localparam  type    addr_t          = logic [ADDR_BITS-1:0]  ;
    localparam  type    data_t          = logic [DATA_BITS-1:0]  ;
    localparam  type    len_t           = logic [LEN_BITS-1:0]   ;
    localparam  type    size_t          = logic [SIZE_BITS-1:0]  ;

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
        axi4
            (
                .aresetn    (aresetn    ),
                .aclk       (aclk       ),
                .aclken     (aclken     )
            );

    logic   enable;
    logic   busy;
    logic   write_busy;
    logic   read_busy;

    jelly3_model_axi4_m
            #(
                .WRITE_ADDR_LOW      (WRITE_ADDR_LOW      ),
                .WRITE_ADDR_HIGH     (WRITE_ADDR_HIGH     ),
                .READ_ADDR_LOW       (READ_ADDR_LOW       ),
                .READ_ADDR_HIGH      (READ_ADDR_HIGH      ),
                .WRITE_LEN_MIN       (0                   ),
                .WRITE_LEN_MAX       (7                   ),
                .READ_LEN_MIN        (1                   ),
                .READ_LEN_MAX        (7                   ),
                .WRITE_ISSUE_RATE    (55                  ),
                .READ_ISSUE_RATE     (55                  ),
                .AW_BUSY_RATE        (25                  ),
                .W_BUSY_RATE         (35                  ),
                .B_BUSY_RATE         (20                  ),
                .AR_BUSY_RATE        (25                  ),
                .R_BUSY_RATE         (20                  ),
                .WRITE_ID            (WRITE_ID            ),
                .READ_ID             (READ_ID             ),
                .WRITE_LOG_FILE      ("axi4_write_log.txt"),
                .READ_LOG_FILE       ("axi4_read_log.txt" ),
                .WRITE_RAND_SEED     (100                 ),
                .READ_RAND_SEED      (200                 ),
                .AW_RAND_SEED        (300                 ),
                .W_RAND_SEED         (301                 ),
                .B_RAND_SEED         (302                 ),
                .AR_RAND_SEED        (303                 ),
                .R_RAND_SEED         (304                 )
            )
        u_model_axi4_m
            (
                .enable              (enable              ),
                .busy                (busy                ),
                .write_busy          (write_busy          ),
                .read_busy           (read_busy           ),
                .m_axi4              (axi4.m              )
            );

    jelly3_model_axi4_s
            #(
                .MEM_ADDR_BITS       (12                  ),
                .READ_DATA_ADDR      (0                   ),
                .WRITE_LOG_FILE      ("slave_write_log.txt"),
                .READ_LOG_FILE       ("slave_read_log.txt" ),
                .AW_DELAY            (0                   ),
                .AR_DELAY            (0                   ),
                .AW_FIFO_PTR_BITS    (0                   ),
                .W_FIFO_PTR_BITS     (0                   ),
                .B_FIFO_PTR_BITS     (0                   ),
                .AR_FIFO_PTR_BITS    (0                   ),
                .R_FIFO_PTR_BITS     (0                   ),
                .AW_BUSY_RATE        (15                  ),
                .W_BUSY_RATE         (15                  ),
                .B_BUSY_RATE         (15                  ),
                .AR_BUSY_RATE        (15                  ),
                .R_BUSY_RATE         (15                  ),
                .AW_RAND_SEED        (400                 ),
                .W_RAND_SEED         (401                 ),
                .B_RAND_SEED         (402                 ),
                .AR_RAND_SEED        (403                 ),
                .R_RAND_SEED         (404                 )
            )
        u_model_axi4_s
            (
                .s_axi4              (axi4.s              )
            );

    jelly3_model_axi4_mem_check
            #(
                .SHOW_MATCH          (1                   ),
                .SHOW_SKIP           (0                   ),
                .CHECK_BID           (1                   ),
                .CHECK_BRESP         (1                   ),
                .CHECK_RID           (1                   ),
                .CHECK_RRESP         (1                   ),
                .CHECK_WLAST         (1                   ),
                .CHECK_RLAST         (1                   )
            )
        u_memory_checker
            (
                .mon_axi4            (axi4.mon            )
            );


    int             cycle_count;
    int             write_burst_count;
    int             write_resp_count;
    int             read_burst_count;
    int             read_data_count;
    logic [255:0]   awlen_seen;
    logic [255:0]   arlen_seen;

    logic           mon_write_active;
    addr_t          mon_write_addr;
    len_t           mon_write_len;

    logic           mon_read_active;
    addr_t          mon_read_addr;
    len_t           mon_read_len;

    always_ff @(posedge aclk) begin
        if ( !aresetn ) begin
            cycle_count        <= 0;
            write_burst_count  <= 0;
            write_resp_count   <= 0;
            read_burst_count   <= 0;
            read_data_count    <= 0;
            awlen_seen         <= '0;
            arlen_seen         <= '0;
            mon_write_active   <= 1'b0;
            mon_write_addr     <= '0;
            mon_write_len      <= '0;
            mon_read_active    <= 1'b0;
            mon_read_addr      <= '0;
            mon_read_len       <= '0;
        end
        else if ( aclken ) begin
            logic   issue_aw;
            logic   issue_w;
            logic   issue_b;
            logic   issue_ar;
            logic   issue_r;
            addr_t  curr_write_addr;
            len_t   curr_write_len;

            cycle_count <= cycle_count + 1;

            issue_aw = axi4.awvalid && axi4.awready;
            issue_w  = axi4.wvalid  && axi4.wready ;
            issue_b  = axi4.bvalid  && axi4.bready ;
            issue_ar = axi4.arvalid && axi4.arready;
            issue_r  = axi4.rvalid  && axi4.rready ;

            if ( issue_aw ) begin
                assert (axi4.awid == id_t'(WRITE_ID))
                    else $error("write id mismatch expected=%0d actual=%0d", WRITE_ID, axi4.awid);
                assert (int'(axi4.awaddr) >= WRITE_ADDR_LOW && int'(axi4.awaddr) <= WRITE_ADDR_HIGH)
                    else $error("write address out of range addr=%08x", axi4.awaddr);
                assert ((axi4.awaddr % DATA_BYTES) == 0)
                    else $error("write address is not aligned addr=%08x", axi4.awaddr);
                assert (axi4.awsize == size_t'(DATA_SIZE))
                    else $error("write size mismatch size=%0d expected=%0d", axi4.awsize, DATA_SIZE);
                assert (axi4.awburst == 2'b01)
                    else $error("write burst type mismatch burst=%0d", axi4.awburst);

                awlen_seen[axi4.awlen] <= 1'b1;
                write_burst_count      <= write_burst_count + 1;
            end

            curr_write_addr = mon_write_active ? mon_write_addr : axi4.awaddr;
            curr_write_len  = mon_write_active ? mon_write_len  : axi4.awlen;
            if ( issue_w ) begin
                assert (mon_write_active || issue_aw)
                    else $error("write data accepted without active write address");
                assert (int'(curr_write_addr) >= WRITE_ADDR_LOW && int'(curr_write_addr) <= WRITE_ADDR_HIGH)
                    else $error("write beat address out of range addr=%08x", curr_write_addr);
                assert (axi4.wlast == (curr_write_len == 0))
                    else $error("wlast mismatch addr=%08x len=%0d wlast=%0d", curr_write_addr, curr_write_len, axi4.wlast);

                if ( curr_write_len == 0 ) begin
                    mon_write_active <= 1'b0;
                    mon_write_addr   <= '0;
                    mon_write_len    <= '0;
                end
                else begin
                    mon_write_active <= 1'b1;
                    mon_write_addr   <= curr_write_addr + addr_t'(DATA_BYTES);
                    mon_write_len    <= curr_write_len - len_t'(1);
                end
            end
            else if ( issue_aw ) begin
                mon_write_active <= 1'b1;
                mon_write_addr   <= axi4.awaddr;
                mon_write_len    <= axi4.awlen;
            end

            if ( issue_b ) begin
                assert (axi4.bid == id_t'(WRITE_ID))
                    else $error("write response id mismatch expected=%0d actual=%0d", WRITE_ID, axi4.bid);
                assert (axi4.bresp == 2'b00)
                    else $error("write response error resp=%0d", axi4.bresp);
                write_resp_count <= write_resp_count + 1;
            end

            if ( issue_ar ) begin
                assert (axi4.arid == id_t'(READ_ID))
                    else $error("read id mismatch expected=%0d actual=%0d", READ_ID, axi4.arid);
                assert (int'(axi4.araddr) >= READ_ADDR_LOW && int'(axi4.araddr) <= READ_ADDR_HIGH)
                    else $error("read address out of range addr=%08x", axi4.araddr);
                assert ((axi4.araddr % DATA_BYTES) == 0)
                    else $error("read address is not aligned addr=%08x", axi4.araddr);
                assert (axi4.arsize == size_t'(DATA_SIZE))
                    else $error("read size mismatch size=%0d expected=%0d", axi4.arsize, DATA_SIZE);
                assert (axi4.arburst == 2'b01)
                    else $error("read burst type mismatch burst=%0d", axi4.arburst);

                arlen_seen[axi4.arlen] <= 1'b1;
                read_burst_count       <= read_burst_count + 1;
                mon_read_active        <= 1'b1;
                mon_read_addr          <= axi4.araddr;
                mon_read_len           <= axi4.arlen;
            end

            if ( issue_r ) begin
                assert (mon_read_active)
                    else $error("read data accepted without active read address");
                assert (axi4.rid == id_t'(READ_ID))
                    else $error("read response id mismatch expected=%0d actual=%0d", READ_ID, axi4.rid);
                assert (axi4.rresp == 2'b00)
                    else $error("read response error resp=%0d", axi4.rresp);
                assert (axi4.rlast == (mon_read_len == 0))
                    else $error("rlast mismatch addr=%08x len=%0d rlast=%0d", mon_read_addr, mon_read_len, axi4.rlast);

                read_data_count <= read_data_count + 1;
                if ( mon_read_len == 0 ) begin
                    mon_read_active <= 1'b0;
                    mon_read_addr   <= '0;
                    mon_read_len    <= '0;
                end
                else begin
                    mon_read_addr   <= mon_read_addr + addr_t'(DATA_BYTES);
                    mon_read_len    <= mon_read_len - len_t'(1);
                end
            end
        end
    end


    function automatic int count_seen(input logic [255:0] value);
        int count;
    begin
        count = 0;
        for ( int i = 0; i < 256; ++i ) begin
            if ( value[i] ) begin
                count++;
            end
        end
        return count;
    end
    endfunction


    initial begin
        enable = 1'b0;

        wait (aresetn == 1'b1);
        repeat (20) @(posedge aclk);

        enable = 1'b1;
        repeat (TEST_CYCLES) @(posedge aclk);
        enable = 1'b0;

        wait (!busy && !write_busy && !read_busy);
        repeat (20) @(posedge aclk);

        $display("---- tb_model_axi4 summary ----");
        $display("cycles            : %0d", cycle_count);
        $display("write bursts      : %0d", write_burst_count);
        $display("write responses   : %0d", write_resp_count);
        $display("read bursts       : %0d", read_burst_count);
        $display("read data beats   : %0d", read_data_count);
        $display("unique awlen      : %0d", count_seen(awlen_seen));
        $display("unique arlen      : %0d", count_seen(arlen_seen));

        assert (write_burst_count >= 8)
            else $fatal(1, "insufficient write bursts count=%0d", write_burst_count);
        assert (read_burst_count >= 8)
            else $fatal(1, "insufficient read bursts count=%0d", read_burst_count);
        assert (write_resp_count == write_burst_count)
            else $fatal(1, "write response count mismatch burst=%0d resp=%0d", write_burst_count, write_resp_count);
        assert (count_seen(awlen_seen) >= 2)
            else $fatal(1, "awlen variation is too small unique=%0d", count_seen(awlen_seen));
        assert (count_seen(arlen_seen) >= 3)
            else $fatal(1, "arlen variation is too small unique=%0d", count_seen(arlen_seen));

        u_model_axi4_s.write_memh("axi4_mem_dump.txt");

        $display("tb_model_axi4 passed");
        $finish;
    end

endmodule


`default_nettype wire


// end of file