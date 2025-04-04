// ---------------------------------------------------------------------------
//
//                                  Copyright (C) 2015-2020 by Ryuji Fuchikami
//                                  https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_sim();
    localparam RATE = 1000.0/200.0;
    
    initial begin
        $dumpfile("tb_sim.vcd");
        $dumpvars(0, tb_sim);
        
    #1000000
        $finish;
    end
    
    logic     reset = 1'b1;
    initial #(RATE*10) reset <= 1'b0;

    logic     clk = 1'b1;
    always  #(RATE/2.0) clk  = ~clk;
    


    // ----------------------------------
    //  main
    // ----------------------------------
    
    parameter int   WB_ADR_WIDTH = 16;
    parameter int   WB_DAT_WIDTH = 32;
    parameter int   WB_SEL_WIDTH = WB_DAT_WIDTH/8;

    logic   [WB_ADR_WIDTH-1:0]  s_wb_adr_i;
    logic   [WB_DAT_WIDTH-1:0]  s_wb_dat_i;
    logic   [WB_DAT_WIDTH-1:0]  s_wb_dat_o;
    logic                       s_wb_we_i;
    logic   [WB_SEL_WIDTH-1:0]  s_wb_sel_i;
    logic                       s_wb_stb_i;
    logic                       s_wb_ack_o;

    tb_sim_main
        i_sim_main
            (
                .*
            );
    
    


    // ----------------------------------
    //  WISHBONE master
    // ----------------------------------
    
    // force connect to top-net
    logic                       wb_rst_i;
    logic                       wb_clk_i;
    logic   [WB_ADR_WIDTH-1:0]  wb_adr_o;
    logic   [WB_DAT_WIDTH-1:0]  wb_dat_i;
    logic   [WB_DAT_WIDTH-1:0]  wb_dat_o;
    logic                       wb_we_o;
    logic   [WB_SEL_WIDTH-1:0]  wb_sel_o;
    logic                       wb_stb_o = 0;
    logic                       wb_ack_i;
    
    assign wb_rst_i = reset;
    assign wb_clk_i = clk;
    assign wb_dat_i = s_wb_dat_o;
    assign wb_ack_i = s_wb_ack_o;

    assign s_wb_adr_i = wb_adr_o;
    assign s_wb_dat_i = wb_dat_o;
    assign s_wb_we_i  = wb_we_o;
    assign s_wb_sel_i = wb_sel_o;
    assign s_wb_stb_i = wb_stb_o;
    
    
    reg     [WB_DAT_WIDTH-1:0]      reg_wb_dat;
    reg                             reg_wb_ack;
    always_ff @(posedge wb_clk_i) begin
        if ( ~wb_we_o & wb_stb_o & wb_ack_i ) begin
            reg_wb_dat <= wb_dat_i;
        end
        reg_wb_ack <= wb_ack_i;
    end
    
    
    task wb_write(
                input [WB_ADR_WIDTH-1:0]    adr,
                input [WB_DAT_WIDTH-1:0]    dat,
                input [WB_SEL_WIDTH-1:0]    sel
            );
    begin
        $display("WISHBONE_WRITE(adr:%h dat:%h sel:%b)", adr, dat, sel);
        @(negedge wb_clk_i);
            wb_adr_o = adr;
            wb_dat_o = dat;
            wb_sel_o = sel;
            wb_we_o  = 1'b1;
            wb_stb_o = 1'b1;
        @(negedge wb_clk_i);
            while ( reg_wb_ack == 1'b0 ) begin
                @(negedge wb_clk_i);
            end
            wb_adr_o = {WB_ADR_WIDTH{1'bx}};
            wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            wb_sel_o = {WB_SEL_WIDTH{1'bx}};
            wb_we_o  = 1'bx;
            wb_stb_o = 1'b0;
    end
    endtask
    
    task wb_read(
                input [WB_ADR_WIDTH-1:0]    adr
            );
    begin
        @(negedge wb_clk_i);
            wb_adr_o = adr;
            wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            wb_sel_o = {WB_SEL_WIDTH{1'b1}};
            wb_we_o  = 1'b0;
            wb_stb_o = 1'b1;
        @(negedge wb_clk_i);
            while ( reg_wb_ack == 1'b0 ) begin
                @(negedge wb_clk_i);
            end
            wb_adr_o = {WB_ADR_WIDTH{1'bx}};
            wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            wb_sel_o = {WB_SEL_WIDTH{1'bx}};
            wb_we_o  = 1'bx;
            wb_stb_o = 1'b0;
            $display("WISHBONE_READ(adr:%h dat:%h)", adr, reg_wb_dat);
    end
    endtask
    

    // ----------------------------------
    //  Simulation
    // ----------------------------------

    localparam  int                         ID_WIDTH          = 8;
    localparam  int                         OPCODE_WIDTH      = 8;
    localparam  int                         DECODE_ID_POS     = 0;
    localparam  int                         DECODE_OPCODE_POS = DECODE_ID_POS + ID_WIDTH;

    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SYS_CFG     = OPCODE_WIDTH'(8'h00);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CPU_CTL     = OPCODE_WIDTH'(8'h01);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WUP_TSK     = OPCODE_WIDTH'(8'h10);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SLP_TSK     = OPCODE_WIDTH'(8'h11);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_DLY_TSK     = OPCODE_WIDTH'(8'h18);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SIG_SEM     = OPCODE_WIDTH'(8'h21);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_SEM     = OPCODE_WIDTH'(8'h22);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_POL_SEM     = OPCODE_WIDTH'(8'h23);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_FLG     = OPCODE_WIDTH'(8'h31);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CLR_FLG     = OPCODE_WIDTH'(8'h32);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_AND = OPCODE_WIDTH'(8'h33);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_OR  = OPCODE_WIDTH'(8'h34);

    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_CORE_ID      = 'h00;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_VERSION      = 'h01;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_DATE         = 'h04;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_TASKS        = 'h20;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_SEMAPHORES   = 'h21;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_TSKPRI_WIDTH = 'h30;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_SEMCNT_WIDTH = 'h31;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_FLGPTN_WIDTH = 'h32;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_SYSTIM_WIDTH = 'h34;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_RELTIM_WIDTH = 'h35;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_SOFT_RESET   = 'hff;

    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_TOP_TSKID  = 'h00;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_TOP_VALID  = 'h01;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_RUN_TSKID  = 'h04;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_RUN_VALID  = 'h05;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IDLE_TSKID = 'h07;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_COPY_TSKID = 'h08;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_EN     = 'h10;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_STS    = 'h11;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_FORCE  = 'h1f;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH0   = 'he0;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH1   = 'he1;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH2   = 'he2;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH3   = 'he3;


    function [WB_ADR_WIDTH-1:0] make_addr(bit [OPCODE_WIDTH-1:0] opcode, int id);
    begin
        make_addr = '0;
        make_addr[DECODE_OPCODE_POS +: OPCODE_WIDTH] = OPCODE_WIDTH'(opcode);
        make_addr[DECODE_ID_POS     +: ID_WIDTH]     = ID_WIDTH'(id);
    end
    endfunction

    localparam REG_CORE_ID = 'h0000;
    localparam REG_WUP_TSK = 'h0100;

    task read_status();
    begin
        $display("=========================");
        $display("[status]");
        wb_read (make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_TOP_TSKID)));
        wb_read (make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_TOP_VALID)));
        wb_read (make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_RUN_TSKID)));
        wb_read (make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_RUN_VALID)));
        wb_read (make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_IRQ_EN)));
        wb_read (make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_IRQ_STS)));
        $display("=========================");
    end
    endtask

    task swtich_task();
    begin
//      wb_read (make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_TOP_TSKID)));
//      wb_write(make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_RUN_TSKID)), reg_wb_dat, 4'hf);
        wb_read (make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_COPY_TSKID)));
    end
    endtask

    task check_top_taskid(int exp_tskid);
    begin
        if ( i_sim_main.i_rtos.cur_top_tskid == exp_tskid ) begin
            $display("[OK] top_tskid = %d", exp_tskid);
        end
        else begin
            $display("[!!!ERROR!!!] top_tskid = %d (exp:%d)", i_sim_main.i_rtos.cur_top_tskid, exp_tskid);
            $error();
        end
    end
    endtask

    task check_run_taskid(int exp_tskid);
    begin
        if ( i_sim_main.i_rtos.cur_run_tskid == exp_tskid ) begin
            $display("[OK] run_tskid = %d", exp_tskid);
        end
        else begin
            $display("[!!!ERROR!!!] run_tskid = %d (exp:%d)", i_sim_main.i_rtos.cur_run_tskid, exp_tskid);
            $error();
        end
    end
    endtask

    task check_irq(bit exp_irq);
    begin
        if ( i_sim_main.i_rtos.irq == exp_irq ) begin
            $display("[OK] irq = %d", exp_irq);
        end
        else begin
            $display("[!!!ERROR!!!] irq = %d (exp:%d)", i_sim_main.i_rtos.irq, exp_irq);
            $error();
        end
    end
    endtask

    int test_no = 0;

    initial begin
    @(negedge wb_rst_i);
    
    #100;
        test_no = 1;
        read_status();
        $display(" --- initialize --- ");
        wb_read (0);
        wb_write(make_addr(OPCODE_SYS_CFG, SYS_CFG_SOFT_RESET), 1, 4'hf);
        
        wb_write(make_addr(OPCODE_CPU_CTL, CPU_CTL_IDLE_TSKID), 15, 4'hf);
        wb_write(make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_RUN_TSKID)), 15, 4'hf);
        $display("irq en");
        wb_write(make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_IRQ_EN)), 1, 4'hf);
        read_status();
        check_top_taskid(15);

    #100;
        test_no = 2;
        $display(" --- wake up task --- ");
        $display("wup_tsk 1");
        check_irq(1'b0);
        wb_write(make_addr(OPCODE_WUP_TSK, 1), 0, 4'hf);
    #10
        check_irq(1'b1);
        swtich_task();
        check_irq(1'b0);
        read_status();
        check_top_taskid(1);

        $display("wup_tsk 0");
        wb_write(make_addr(OPCODE_WUP_TSK, 0), 0, 4'hf);
        swtich_task();
        check_top_taskid(0);

        $display("slp_tsk 0");
        wb_write(make_addr(OPCODE_SLP_TSK, 0), 0, 4'hf);
        swtich_task();
        check_top_taskid(1);

        $display("slp_tsk 1");
        wb_write(make_addr(OPCODE_SLP_TSK, 1), 0, 4'hf);
        swtich_task();
        check_top_taskid(15);

    #100;
        test_no = 22;
        $display(" --- busy test --- ");
        wb_write(make_addr(OPCODE_WUP_TSK, 1), 0, 4'hf);
        wb_write(make_addr(OPCODE_WUP_TSK, 0), 0, 4'hf);
        wb_write(make_addr(OPCODE_SLP_TSK, 0), 0, 4'hf);
        wb_write(make_addr(OPCODE_SLP_TSK, 1), 0, 4'hf);

    #100;
        test_no = 3;
        $display(" --- delay task --- ");

        $display("wup_tsk 1");
        wb_write(make_addr(OPCODE_WUP_TSK, 1), 0, 4'hf);
        swtich_task();
        check_top_taskid(1);

        $display("dly_tsk 10");
        wb_write(make_addr(OPCODE_DLY_TSK, 1), 30, 4'hf);
    #5
        check_irq(1'b1);
        swtich_task();
        check_irq(1'b0);
        check_top_taskid(15);
    #300;
        check_irq(1'b1);
        swtich_task();
        check_irq(1'b0);
        check_top_taskid(1);
    #300;

        $display("slp_tsk 1");
        wb_write(make_addr(OPCODE_SLP_TSK, 1), 0, 4'hf);
        swtich_task();
        check_top_taskid(15);

    #200;
        test_no = 4;
        $display(" --- wai_flg --- ");
        $display("wup_tsk 1");
        wb_write(make_addr(OPCODE_WUP_TSK, 1), 0, 4'hf);
        swtich_task();
        check_top_taskid(1);
        $display("wup_tsk 0");
        wb_write(make_addr(OPCODE_WUP_TSK, 0), 0, 4'hf);
        swtich_task();
        check_top_taskid(0);
    #20;
        wb_write(make_addr(OPCODE_WAI_FLG_AND, 0), 5, 4'hf);
        swtich_task();
        check_top_taskid(1);
    #10;
        wb_write(make_addr(OPCODE_SET_FLG, 0), 1, 4'hf);
        swtich_task();
        check_top_taskid(1);
    #10;
        wb_write(make_addr(OPCODE_SET_FLG, 0), 4, 4'hf);
        swtich_task();
        check_top_taskid(0);
    #20;
        wb_write(make_addr(OPCODE_CLR_FLG, 0), ~1, 4'hf);
        wb_write(make_addr(OPCODE_CLR_FLG, 0), ~4, 4'hf);
        wb_write(make_addr(OPCODE_SLP_TSK, 0), 0, 4'hf);
        wb_write(make_addr(OPCODE_SLP_TSK, 1), 0, 4'hf);

    #100
        test_no = 5;
        $display(" --- wai_sem --- ");
        wb_write(make_addr(OPCODE_WUP_TSK, 1), 0, 4'hf);
        swtich_task();
        check_top_taskid(1);
        wb_write(make_addr(OPCODE_WAI_SEM, 2), 0, 4'hf);
        swtich_task();
        check_top_taskid(15);
    #20;
        wb_write(make_addr(OPCODE_SIG_SEM, 2), 0, 4'hf);
        swtich_task();
        check_top_taskid(1);

    #20;
        wb_write(make_addr(OPCODE_SIG_SEM, 2), 0, 4'hf);
        swtich_task();
        check_top_taskid(1);
    #20;
        wb_write(make_addr(OPCODE_WAI_SEM, 2), 0, 4'hf);
    #5;
        swtich_task();
        check_top_taskid(1);

    #20;
        wb_write(make_addr(OPCODE_SLP_TSK, 1), 0, 4'hf);
        swtich_task();
        check_top_taskid(15);

    #100
        test_no = 6;
        $display(" --- wai_sem2 --- ");
        wb_write(make_addr(OPCODE_WUP_TSK, 0), 0, 4'hf);
        wb_write(make_addr(OPCODE_WUP_TSK, 1), 0, 4'hf);
        wb_write(make_addr(OPCODE_WAI_SEM, 3), 0, 4'hf);
        wb_write(make_addr(OPCODE_WAI_SEM, 3), 0, 4'hf);
        swtich_task();
        check_top_taskid(15);

        wb_write(make_addr(OPCODE_SIG_SEM, 3), 0, 4'hf);
        wb_write(make_addr(OPCODE_SIG_SEM, 3), 0, 4'hf);
        swtich_task();
        check_top_taskid(0);
        wb_write(make_addr(OPCODE_SLP_TSK, 0), 0, 4'hf);
        swtich_task();
        check_top_taskid(1);
        wb_write(make_addr(OPCODE_SLP_TSK, 1), 0, 4'hf);
        swtich_task();
        check_top_taskid(15);

    #100
        test_no = 7;
        $display(" --- wai_sem3 --- ");
        wb_write(make_addr(OPCODE_SIG_SEM, 0), 0, 4'hf);
        wb_write(make_addr(OPCODE_WUP_TSK, 0), 0, 4'hf);
        swtich_task();
        check_top_taskid(0);
        wb_write(make_addr(OPCODE_WAI_SEM, 0), 0, 4'hf);
        swtich_task();
        check_top_taskid(0);
        wb_write(make_addr(OPCODE_SIG_SEM, 0), 0, 4'hf);
        wb_write(make_addr(OPCODE_WAI_SEM, 0), 0, 4'hf);
        swtich_task();
        check_top_taskid(0);
        wb_write(make_addr(OPCODE_SIG_SEM, 0), 0, 4'hf);
        wb_write(make_addr(OPCODE_SLP_TSK, 0), 0, 4'hf);
        swtich_task();
        check_top_taskid(15);


    #100
        test_no = 8;
        $display(" --- pol_sem --- ");
        wb_write(make_addr(OPCODE_SIG_SEM, 1), 0, 4'hf);
        wb_write(make_addr(OPCODE_SIG_SEM, 1), 0, 4'hf);
        wb_read (make_addr(OPCODE_POL_SEM, 1));
        wb_read (make_addr(OPCODE_POL_SEM, 0));
        wb_read (make_addr(OPCODE_POL_SEM, 1));
        wb_read (make_addr(OPCODE_POL_SEM, 1));

    #100;
        test_no = 999;
        $display(" --- soft reset --- ");
        wb_write(make_addr(OPCODE_SYS_CFG, SYS_CFG_SOFT_RESET), 1, 4'hf);
    #100;
        $finish();
        
    end
    
endmodule


`default_nettype wire


// end of file
