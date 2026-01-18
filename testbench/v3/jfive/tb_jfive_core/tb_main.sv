
`timescale 1ns / 1ps
`default_nettype none


module tb_main
    import jelly3_jfive32_pkg::*;
        (
            input   var logic   reset   ,
            input   var logic   clk
        );
    

    localparam  int                     XLEN           = 32                                 ;
    localparam  int                     THREADS        = 4                                  ;
    localparam  int                     ID_BITS        = THREADS > 1 ? $clog2(THREADS) : 1  ;
    localparam  type                    id_t           = logic         [ID_BITS-1:0]        ;
    localparam  int                     PHASE_BITS     = 1                                  ;
    localparam  type                    phase_t        = logic         [PHASE_BITS-1:0]     ;
    localparam  int                     PC_BITS        = 32                                 ;
    localparam  type                    pc_t           = logic         [PC_BITS-1:0]        ;
    localparam  pc_t                    PC_MASK        = '0                                 ;
    localparam  int                     INSTR_BITS     = 32                                 ;
    localparam  type                    instr_t        = logic         [INSTR_BITS-1:0]     ;
    localparam  type                    ridx_t         = logic         [4:0]                ;
    localparam  type                    rval_t         = logic signed  [XLEN-1:0]           ;
    localparam  int                     LS_UNITS       = 2                                  ;
    localparam  rval_t  [LS_UNITS-1:0]  LS_ADDRS_LO    = '{32'h8000_0000, 32'h0000_0000}    ;
    localparam  rval_t  [LS_UNITS-1:0]  LS_ADDRS_HI    = '{32'hffff_ffff, 32'h7fff_ffff}    ;
    localparam  int                     LOAD_QUES      = 2                                  ;
    localparam  int                     DBUS_ADDR_BITS = 10                                 ;
    localparam  type                    dbus_addr_t    = logic         [DBUS_ADDR_BITS-1:0] ;
    localparam  int                     DBUS_DATA_BITS = XLEN                               ;
    localparam  type                    dbus_data_t    = logic         [DBUS_DATA_BITS-1:0] ;
    localparam  int                     DBUS_STRB_BITS = $bits(dbus_data_t) / 8             ;
    localparam  type                    dbus_strb_t    = logic         [DBUS_STRB_BITS-1:0] ;

    localparam  bit     [THREADS-1:0]   INIT_RUN    = 1                                     ;
    localparam  id_t                    INIT_ID     = '0                                    ;
    localparam  pc_t    [THREADS-1:0]   INIT_PC     = '0                                    ;

    localparam                          DEVICE      = "RTL"                                 ;
    localparam                          SIMULATION  = "false"                               ;
    localparam                          DEBUG       = "false"                               ;

    logic                       cke = 1     ;

    id_t                        ibus_aid    ;
    phase_t                     ibus_aphase ;
    pc_t                        ibus_apc    ;
    logic                       ibus_avalid ;
    logic                       ibus_aready ;
    id_t                        ibus_rid    ;
    phase_t                     ibus_rphase ;
    pc_t                        ibus_rpc    ;
    instr_t                     ibus_rinstr ;
    logic                       ibus_rvalid ;
    logic                       ibus_rready ;

    dbus_addr_t [LS_UNITS-1:0]  dbus_aaddr  ;
    logic       [LS_UNITS-1:0]  dbus_awrite ;
    logic       [LS_UNITS-1:0]  dbus_aread  ;
    logic       [LS_UNITS-1:0]  dbus_avalid ;
    logic       [LS_UNITS-1:0]  dbus_aready ;
    dbus_strb_t [LS_UNITS-1:0]  dbus_wstrb  ;
    dbus_data_t [LS_UNITS-1:0]  dbus_wdata  ;
    logic       [LS_UNITS-1:0]  dbus_wvalid ;
    logic       [LS_UNITS-1:0]  dbus_wready ;
    dbus_data_t [LS_UNITS-1:0]  dbus_rdata  ;
    logic       [LS_UNITS-1:0]  dbus_rvalid ;
    logic       [LS_UNITS-1:0]  dbus_rready ;

    jelly3_jfive_core
            #(
                .XLEN               (XLEN           ),
                .THREADS            (THREADS        ),
                .ID_BITS            (ID_BITS        ),
                .id_t               (id_t           ),
                .PHASE_BITS         (PHASE_BITS     ),
                .phase_t            (phase_t        ),
                .PC_BITS            (PC_BITS        ),
                .pc_t               (pc_t           ),
                .PC_MASK            (PC_MASK        ),
                .INSTR_BITS         (INSTR_BITS     ),
                .instr_t            (instr_t        ),
                .ridx_t             (ridx_t         ),
                .rval_t             (rval_t         ),
                .LS_UNITS           (LS_UNITS       ),
                .LS_ADDRS_LO        (LS_ADDRS_LO    ),
                .LS_ADDRS_HI        (LS_ADDRS_HI    ),
                .LOAD_QUES          (LOAD_QUES      ),
                .DBUS_ADDR_BITS     (DBUS_ADDR_BITS ),
                .dbus_addr_t        (dbus_addr_t    ),
                .DBUS_DATA_BITS     (DBUS_DATA_BITS ),
                .dbus_data_t        (dbus_data_t    ),
                .DBUS_STRB_BITS     (DBUS_STRB_BITS ),
                .dbus_strb_t        (dbus_strb_t    ),
                .INIT_RUN           (INIT_RUN       ),
                .INIT_ID            (INIT_ID        ),
                .INIT_PC            (INIT_PC        ),
                .DEVICE             (DEVICE         ),
                .SIMULATION         (SIMULATION     ),
                .DEBUG              (DEBUG          )
            )
        u_jfive_core
            (
                .reset              ,
                .clk                ,
                .cke                ,

                .ibus_aid           ,
                .ibus_aphase        ,
                .ibus_apc           ,
                .ibus_avalid        ,
                .ibus_aready        ,
                .ibus_rid           ,
                .ibus_rphase        ,
                .ibus_rpc           ,
                .ibus_rinstr        ,
                .ibus_rvalid        ,
                .ibus_rready        ,

                .dbus_aaddr         ,
                .dbus_awrite        ,
                .dbus_aread         ,
                .dbus_avalid        ,
                .dbus_aready        ,
                .dbus_wstrb         ,
                .dbus_wdata         ,
                .dbus_wvalid        ,
                .dbus_wready        ,
                .dbus_rdata         ,
                .dbus_rvalid        ,
                .dbus_rready        
            );


    localparam int  MEM_ADDR_BITS  = 14;
    localparam type mem_addr_t     = logic  [MEM_ADDR_BITS-1:0] ;
    localparam int  MEM_DATA_BITS  = 32;
    localparam type mem_data_t     = logic  [MEM_DATA_BITS-1:0] ;
    localparam int  MEM_WE_BITS    = $bits(mem_data_t) / 8;
    localparam type mem_we_t       = logic  [MEM_WE_BITS-1:0]   ;

    logic           port0_cke   ;
    mem_we_t        port0_we    ;
    mem_addr_t      port0_addr  ;
    mem_data_t      port0_din   ;
    mem_data_t      port0_dout  ;

    logic           port1_cke   ;
    mem_we_t        port1_we    ;
    mem_addr_t      port1_addr  ;
    mem_data_t      port1_din   ;
    mem_data_t      port1_dout  ;

    jelly2_ram_dualport
            #(
                .ADDR_WIDTH     ($bits(mem_addr_t)  ),
                .DATA_WIDTH     (32                 ),
                .WE_WIDTH       (4                  ),
                .WORD_WIDTH     (8                  ),
                .RAM_TYPE       ("block"            ),
                .DOUT_REGS0     (1                  ),
                .DOUT_REGS1     (1                  ),
                .MODE0          ("WRITE_FIRST"      ),
                .MODE1          ("WRITE_FIRST"      ),
                .FILLMEM        (0                  ),
                .FILLMEM_DATA   (0                  ),
                .READMEMB       (0                  ),
                .READMEMH       (1                  ),
                .READMEM_FIlE   ("../mem.hex"       )
            )
        u_ram_dualport
            (
                .port0_clk      (clk                ),
                .port0_en       (port0_cke          ),
                .port0_regcke   (port0_cke          ),
                .port0_we       (port0_we           ),
                .port0_addr     (port0_addr         ),
                .port0_din      (port0_din          ),
                .port0_dout     (port0_dout         ),

                .port1_clk      (clk                ),
                .port1_en       (port1_cke          ),
                .port1_regcke   (port1_cke          ),
                .port1_we       (port1_we           ),
                .port1_addr     (port1_addr         ),
                .port1_din      (port1_din          ),
                .port1_dout     (port1_dout         )
            );
    
    assign port0_cke   = cke && ibus_rready;
    assign port0_we    = '0;
    assign port0_addr  = mem_addr_t'(ibus_apc >> 2);
    assign port0_din   = '0;
    
    id_t    ibus_st0_id     ;
    phase_t ibus_st0_phase  ;
    pc_t    ibus_st0_pc     ;
    logic   ibus_st0_valid  ;
    id_t    ibus_st1_id     ;
    phase_t ibus_st1_phase  ;
    pc_t    ibus_st1_pc     ;
    logic   ibus_st1_valid  ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            ibus_st0_id     <= 'x   ;
            ibus_st0_phase  <= 'x   ;
            ibus_st0_pc     <= 'x   ;
            ibus_st0_valid  <= 1'b0 ;
            ibus_st1_id     <= 'x   ;
            ibus_st1_phase  <= 'x   ;
            ibus_st1_pc     <= 'x   ;
            ibus_st1_valid  <= 1'b0;
        end
        else if ( cke && ibus_rready ) begin
            ibus_st0_id     <= ibus_aid         ;
            ibus_st0_phase  <= ibus_aphase      ;
            ibus_st0_pc     <= ibus_apc         ;
            ibus_st0_valid  <= ibus_avalid      ;
            ibus_st1_id     <= ibus_st0_id      ;
            ibus_st1_phase  <= ibus_st0_phase   ;
            ibus_st1_pc     <= ibus_st0_pc      ;
            ibus_st1_valid  <= ibus_st0_valid   ;
        end
    end

    assign ibus_aready = ibus_rready    ;

    assign ibus_rid    = ibus_st1_id    ;
    assign ibus_rphase = ibus_st1_phase ;
    assign ibus_rpc    = ibus_st1_pc    ;
    assign ibus_rinstr = port0_dout     ;
    assign ibus_rvalid = ibus_st1_valid ;


    // dbus
    assign port1_cke   = cke && dbus_rready[0]      ;
    assign port1_addr = mem_addr_t'(dbus_aaddr[0])  ;
    assign port1_we   = dbus_wstrb[0]               ;
    assign port1_din  = dbus_wdata[0]               ;

    dbus_addr_t         dbus_st0_addr       ;
    logic               dbus_st0_wr         ;
    dbus_strb_t         dbus_st0_strb       ;
    dbus_data_t         dbus_st0_wdata      ;
    logic               dbus_st0_valid      ;
    dbus_addr_t         dbus_st1_addr       ;
    logic               dbus_st1_wr         ;
    dbus_strb_t         dbus_st1_strb       ;
    dbus_data_t         dbus_st1_wdata      ;
    logic               dbus_st1_valid      ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            dbus_st0_addr   <= 'x   ;
            dbus_st0_wr     <= 'x   ;
            dbus_st0_strb   <= 'x   ;
            dbus_st0_wdata  <= 'x   ;
            dbus_st0_valid  <= 1'b0 ;
            dbus_st1_addr   <= 'x   ;
            dbus_st1_wr     <= 'x   ;
            dbus_st1_strb   <= 'x   ;
            dbus_st1_wdata  <= 'x   ;
            dbus_st1_valid  <= 1'b0 ;
        end
        else if ( cke && dbus_rready[0] ) begin
            dbus_st0_addr   <= dbus_aaddr [0]   ;
            dbus_st0_wr     <= dbus_awrite[0]   ;
            dbus_st0_strb   <= dbus_wstrb [0]   ;
            dbus_st0_wdata  <= dbus_wdata [0]   ;
            dbus_st0_valid  <= dbus_avalid[0] && !dbus_awrite[0];
            dbus_st1_addr   <= dbus_st0_addr    ;
            dbus_st1_wr     <= dbus_st0_wr      ;
            dbus_st1_strb   <= dbus_st0_strb    ;
            dbus_st1_wdata  <= dbus_st0_wdata   ;
            dbus_st1_valid  <= dbus_st0_valid   ;
        end
    end

    assign dbus_aready[0] = dbus_rready[0]                  ;
    assign dbus_wready[0] = dbus_rready[0] & dbus_avalid[0] ;
    assign dbus_rdata [0] = port1_dout    ;
    assign dbus_rvalid[0] = dbus_st1_valid;


    // ------------------------------------------------
    //  Debug
    // ------------------------------------------------

    localparam  type    mnemonic_t = logic [64*8-1:0];
    
    wire    mnemonic_t   ibus_res_mnemonic = mnemonic_t'(instr2mnemonic(ibus_rinstr));

    wire    mnemonic_t   ids_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_instruction_decode.s_instr));
    wire    mnemonic_t   id0_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_instruction_decode.st0_instr));
    wire    mnemonic_t   id1_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_instruction_decode.st1_instr));
    wire    mnemonic_t   id2_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_instruction_decode.st2_instr));
    wire    mnemonic_t   idm_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_instruction_decode.m_instr));

    wire    mnemonic_t   exs_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_execution.s_instr));
    wire    mnemonic_t   ex0_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_execution.st0_instr));
    wire    mnemonic_t   ex1_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_execution.st1_instr));
    wire    mnemonic_t   ex2_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_execution.st2_instr));

    wire    mnemonic_t   bs_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_execution.u_jfive_branch.s_instr));
    wire    mnemonic_t   b0_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_execution.u_jfive_branch.st0_instr));

    wire    mnemonic_t   mems_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_execution.load_store[0].u_jfive_load_store.s_instr));

    wire    mnemonic_t   branch_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.branch_instr));
    wire    mnemonic_t   wb_mnemonic     = mnemonic_t'(instr2mnemonic(u_jfive_core.wb_instr));

    
    wire    ridx_t  busy_rd_idx0 = u_jfive_core.u_jfive_execution.busy_rd_idx[0];
    wire    ridx_t  busy_rd_idx1 = u_jfive_core.u_jfive_execution.busy_rd_idx[1];
    wire    ridx_t  busy_rd_idx2 = u_jfive_core.u_jfive_execution.busy_rd_idx[2];
    wire    ridx_t  busy_rd_idx3 = u_jfive_core.u_jfive_execution.busy_rd_idx[3];
    wire    ridx_t  busy_rd_idx4 = u_jfive_core.u_jfive_execution.busy_rd_idx[4];
//  wire    ridx_t  busy_rd_idx5 = u_jfive_core.u_jfive_execution.busy_rd_idx[5];
    

    wire    pc_t        exe_pc        = u_jfive_core.u_jfive_execution.st0_pc       ;
    wire    instr_t     exe_instr     = u_jfive_core.u_jfive_execution.st0_instr    ;
    wire    logic       exe_rs1_en    = u_jfive_core.u_jfive_execution.st0_rs1_en   ;
    wire    ridx_t      exe_rs1_idx   = u_jfive_core.u_jfive_execution.st0_rs1_idx  ;
    wire    rval_t      exe_rs1_val   = u_jfive_core.u_jfive_execution.st0_rs1_val  ;
    wire    logic       exe_rs2_en    = u_jfive_core.u_jfive_execution.st0_rs2_en   ;
    wire    ridx_t      exe_rs2_idx   = u_jfive_core.u_jfive_execution.st0_rs2_idx  ;
    wire    rval_t      exe_rs2_val   = u_jfive_core.u_jfive_execution.st0_rs2_val  ;
    wire    logic       exe_valid     = u_jfive_core.u_jfive_execution.st0_valid    ;
    wire    logic       exe_ready     = u_jfive_core.u_jfive_execution.st0_ready    ;
    wire    mnemonic_t  exe_mnemonic  = mnemonic_t'(instr2mnemonic(exe_instr));

    int exe_counter = 0;
    int fp_exe_log;
    initial fp_exe_log = $fopen("exe_log.txt", "w");
    always_ff @(posedge clk) begin
        if ( !reset && cke ) begin
            if ( exe_valid && exe_ready ) begin
                automatic   logic   rs1_en ;
                automatic   ridx_t  rs1_idx;
                automatic   rval_t  rs1_val;
                automatic   logic   rs2_en ;
                automatic   ridx_t  rs2_idx;
                automatic   rval_t  rs2_val;
                rs1_en  = exe_rs1_en ;
                rs1_idx = exe_rs1_idx;
                rs1_val = exe_rs1_val;
                rs2_en  = exe_rs2_en ;
                rs2_idx = exe_rs2_idx;
                rs2_val = exe_rs2_val;
                if ( !rs1_en ) rs1_idx = 0;
                if ( !rs2_en ) rs2_idx = 0;
                if ( rs1_idx == 0 ) rs1_val = '0;
                if ( rs2_idx == 0 ) rs2_val = '0;

                $fwrite(fp_exe_log, "pc:%08x instr:%08x rs1(%2d):%08x rs2(%2d):%08x %s\n",
                    exe_pc,
                    exe_instr,
                    rs1_idx,
                    rs1_val,
                    rs2_idx,
                    rs2_val,
                    string'(exe_mnemonic)
                    );
                exe_counter <= exe_counter + 1;
            end

            /*
            if ( u_jfive_core.u_jfive_execution.st1_valid && u_jfive_core.u_jfive_execution.alu_ready ) begin
                automatic   logic   rs1_en ;
                automatic   ridx_t  rs1_idx;
                automatic   rval_t  rs1_val;
                automatic   logic   rs2_en ;
                automatic   ridx_t  rs2_idx;
                automatic   rval_t  rs2_val;
                rs1_en  = u_jfive_core.u_jfive_execution.st1_rs1_en ;
                rs1_idx = u_jfive_core.u_jfive_execution.st1_rs1_idx;
                rs1_val = u_jfive_core.u_jfive_execution.st1_rs1_val;
                rs2_en  = u_jfive_core.u_jfive_execution.st1_rs2_en ;
                rs2_idx = u_jfive_core.u_jfive_execution.st1_rs2_idx;
                rs2_val = u_jfive_core.u_jfive_execution.st1_rs2_val;
                if ( !rs1_en ) rs1_idx = 0;
                if ( !rs2_en ) rs2_idx = 0;
                if ( rs1_idx == 0 ) rs1_val = '0;
                if ( rs2_idx == 0 ) rs2_val = '0;

                $fwrite(fp_exe_log, "pc:%08x instr:%08x rs1(%2d):%08x rs2(%2d):%08x %s\n",
                    u_jfive_core.u_jfive_execution.st1_pc,
                    u_jfive_core.u_jfive_execution.st1_instr,
                    rs1_idx,
                    rs1_val,
                    rs2_idx,
                    rs2_val,
                    string'(ex1_mnemonic)
                    );
                exe_counter <= exe_counter + 1;
            end
                */
        end
    end

    int fp_dbus_log;
    initial fp_dbus_log = $fopen("dbus_log.txt", "w");
    always_ff @(posedge clk) begin
        if ( !reset && cke ) begin
            if ( dbus_avalid[0] && dbus_awrite[0] ) begin
                $fwrite(fp_dbus_log, "%d w addr:%08x %08x wdata:%08x strb:%b\n", exe_counter, dbus_aaddr[0], int'(dbus_aaddr[0]) << 2, dbus_wdata[0], dbus_wstrb[0]);
            end
            if ( dbus_st1_valid && !dbus_st1_wr ) begin
                $fwrite(fp_dbus_log, "%d r addr:%08x %08x rdata:%08x\n", exe_counter, dbus_st1_addr, int'(dbus_st1_addr) << 2, dbus_rdata[0]);
            end
        end
    end


    int fp_port1_log;
    initial fp_port1_log = $fopen("port1_log.txt", "w");
    always_ff @(posedge clk) begin
        if ( !reset && cke ) begin
            if ( port1_cke ) begin
                if ( port1_we != 0 ) begin
                    $fwrite(fp_port1_log, "%t w addr:%08x %08x wdata:%08x %b\n", $time, port1_addr, port1_addr*4, port1_din, port1_we);
                end
            end
        end
    end




    int fp_wb_rd_log;
    initial begin
        fp_wb_rd_log = $fopen("wb_rd_log.txt", "w");
    end
    always_ff @(posedge clk) begin
        if ( !reset && cke ) begin
            if ( u_jfive_core.wb_rd_en ) begin
                $fwrite(fp_wb_rd_log, "%2d %08x %s\n", u_jfive_core.wb_rd_idx, u_jfive_core.wb_rd_val, string'(wb_mnemonic));
            end
        end
    end

    always_ff @(posedge clk) begin
        if ( !reset && cke ) begin
            if ( dbus_avalid[0] && dbus_awrite[0] && dbus_aaddr[0] == 0 ) begin
                $display("%08x %08x %s\n", dbus_aaddr[0], dbus_wdata[0], string'(ids_mnemonic));
            end
        end
    end

    always_ff @(posedge clk) begin
        if ( !reset && cke ) begin
            if ( dbus_avalid[0] ) begin
                $display("%08x %b %08x", dbus_aaddr[0], dbus_awrite[0], dbus_wdata[0]);
            end
        end
    end

endmodule


`default_nettype wire


// end of file
