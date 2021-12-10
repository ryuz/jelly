// ---------------------------------------------------------------------------
//
//                                  Copyright (C) 2015-2020 by Ryuz
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
    
    tb_sim_main
        i_sim_main
            (
            );
    
    initial begin
        force i_sim_main.i_top.i_design_1.reset = reset;
        force i_sim_main.i_top.i_design_1.clk   = clk;
    end
    


    // ----------------------------------
    //  WISHBONE master
    // ----------------------------------

    parameter int   WB_ADR_WIDTH = 37;
    parameter int   WB_DAT_WIDTH = 64;
    parameter int   WB_SEL_WIDTH = WB_DAT_WIDTH/8;
    
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
    assign wb_dat_i = i_sim_main.i_top.i_design_1.wb_dat_o;
    assign wb_ack_i = i_sim_main.i_top.i_design_1.wb_ack_o;

    initial begin
        force i_sim_main.i_top.i_design_1.wb_adr_i = wb_adr_o;
        force i_sim_main.i_top.i_design_1.wb_dat_i = wb_dat_o;
        force i_sim_main.i_top.i_design_1.wb_we_i  = wb_we_o;
        force i_sim_main.i_top.i_design_1.wb_sel_i = wb_sel_o;
        force i_sim_main.i_top.i_design_1.wb_stb_i = wb_stb_o;
    end
    
    reg     [WB_DAT_WIDTH-1:0]      reg_wb_dat;
    reg                             reg_wb_ack;
    always @(posedge wb_clk_i) begin
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
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_RSM_TSK     = OPCODE_WIDTH'(8'h14);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SUS_TSK     = OPCODE_WIDTH'(8'h15);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_DLY_TSK     = OPCODE_WIDTH'(8'h18);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CHG_PRI     = OPCODE_WIDTH'(8'h1c);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_TMO     = OPCODE_WIDTH'(8'h1f);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_TSKSTAT = OPCODE_WIDTH'(8'h90);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_TSKWAIT = OPCODE_WIDTH'(8'h91);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_WUPCNT  = OPCODE_WIDTH'(8'h92);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_SUSCNT  = OPCODE_WIDTH'(8'h93);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_TIMCNT  = OPCODE_WIDTH'(8'h94);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_ERCD    = OPCODE_WIDTH'(8'h98);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_GET_PRI     = OPCODE_WIDTH'(8'h9c);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SIG_SEM     = OPCODE_WIDTH'(8'h21);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_SEM     = OPCODE_WIDTH'(8'h22);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_POL_SEM     = OPCODE_WIDTH'(8'h23);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_SEMCNT  = OPCODE_WIDTH'(8'ha0);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_SEMQUE  = OPCODE_WIDTH'(8'ha1);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_FLG     = OPCODE_WIDTH'(8'h31);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CLR_FLG     = OPCODE_WIDTH'(8'h32);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_AND = OPCODE_WIDTH'(8'h33);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_OR  = OPCODE_WIDTH'(8'h34);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_ENA_FLG_EXT = OPCODE_WIDTH'(8'h3a);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_FLGPTN  = OPCODE_WIDTH'(8'hb0);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_TIM     = OPCODE_WIDTH'(8'h70);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_PSCL    = OPCODE_WIDTH'(8'h72);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_GET_TIM     = OPCODE_WIDTH'(8'hf0);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SYSTIM_LO   = OPCODE_WIDTH'(8'hf2);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SYSTIM_HI   = OPCODE_WIDTH'(8'hf3);

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

    localparam E_OK    = 0;
    localparam E_OBJ   = -41;
    localparam E_QOVR  = -43;
    localparam E_RLWAI = -49;
    localparam E_TMOUT = -50;

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
        wb_read (make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_COPY_TSKID)));
    end
    endtask

    task swtich_and_check(int exp_tskid);
    begin
        wb_read (make_addr(OPCODE_CPU_CTL, int'(CPU_CTL_COPY_TSKID)));
        if ( i_sim_main.i_top.i_rtos.run_tskid == exp_tskid ) begin
            $display("[OK] run_tskid = %d", exp_tskid);
        end
        else begin
            $error("[!!!ERROR!!!] run_tskid = %d (exp:%d)", i_sim_main.i_top.i_rtos.rdq_top_tskid, exp_tskid);
            $stop();
        end
    end
    endtask

    task check_er_code(int taskid, int exp_er);
    begin
        wb_read(make_addr(OPCODE_REF_ERCD, taskid));
        if ( int'($signed(reg_wb_dat)) == exp_er ) begin
            $display("[OK] tskid:%d er_code:%d (exp:%d)", taskid, int'($signed(reg_wb_dat)), exp_er);
        end
        else begin
            $error("[!!!ERROR!!!] tskid:%d er_code:%d (exp:%d)", taskid, int'($signed(reg_wb_dat)), exp_er);
            $stop();
        end
    end
    endtask


    localparam ADR_RTOS = 32'h0000_0000;
    localparam ADR_COM  = 32'h0001_0000;
    localparam ADR_I2C  = 32'h0010_0000;
    localparam ADR_LED  = 32'h0011_0000;


    localparam  int  REG_COM_CORE_ID        = 'h00;
    localparam  int  REG_COM_CORE_VERSION   = 'h01;
    localparam  int  REG_COM_CORE_DATE      = 'h02;
    localparam  int  REG_COM_CORE_SERIAL    = 'h03;
    localparam  int  REG_COM_TX_DATA        = 'h10;
    localparam  int  REG_COM_TX_STATUS      = 'h11;
    localparam  int  REG_COM_TX_FREE_COUNT  = 'h12;
    localparam  int  REG_COM_TX_IRQ_STATUS  = 'h14;
    localparam  int  REG_COM_TX_IRQ_ENABLE  = 'h15;
    localparam  int  REG_COM_RX_DATA        = 'h18;
    localparam  int  REG_COM_RX_STATUS      = 'h19;
    localparam  int  REG_COM_RX_FREE_COUNT  = 'h1a;
    localparam  int  REG_COM_RX_IRQ_STATUS  = 'h1c;
    localparam  int  REG_COM_RX_IRQ_ENABLE  = 'h1d;

    initial begin
    @(negedge wb_rst_i);
        wb_write(ADR_LED, 0, 8'hff);
        wb_write(ADR_LED, 1, 8'hff);
        wb_write(ADR_LED, 0, 8'hff);
        wb_write(ADR_LED, 1, 8'hff);

        wb_read (ADR_COM + REG_COM_CORE_ID);
        wb_write(ADR_COM + REG_COM_TX_DATA, 8'h21, 8'hff);
        wb_write(ADR_COM + REG_COM_TX_DATA, 8'h22, 8'hff);
        wb_write(ADR_COM + REG_COM_TX_DATA, 8'h23, 8'hff);
        wb_read (ADR_COM + REG_COM_RX_STATUS);
        wb_read (ADR_COM + REG_COM_RX_DATA);
        wb_read (ADR_COM + REG_COM_RX_STATUS);
        wb_read (ADR_COM + REG_COM_RX_DATA);
        wb_read (ADR_COM + REG_COM_RX_STATUS);
        wb_read (ADR_COM + REG_COM_RX_DATA);
        wb_read (ADR_COM + REG_COM_RX_STATUS);

        $finish();
    end
    
endmodule


`default_nettype wire


// end of file
