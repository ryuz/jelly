
`timescale 1ns / 1ps
`default_nettype none


module tb_main
    import jelly3_jfive32_pkg::*;
        (
            input   var logic   reset,
            input   var logic   clk
        );
    

    localparam  int                         XLEN             = 32                                   ;
    localparam  int                         THREADS          = 4                                    ;
    localparam  int                         ID_BITS          = THREADS > 1 ? $clog2(THREADS) : 1    ;
    localparam  type                        id_t             = logic         [ID_BITS-1:0]          ;
    localparam  int                         PC_BITS          = 32                                   ;
    localparam  type                        pc_t             = logic         [PC_BITS-1:0]          ;
    localparam  pc_t                        PC_MASK          = '0                                   ;
    localparam  type                        rval_t           = logic signed  [XLEN-1:0]             ;
    localparam  int                         LOAD_QUES        = 2                                    ;
    localparam   int                        TCM_MEM_SIZE     = 512 * 1024                           ;
    localparam   rval_t                     TCM_ADDR_LO      = 32'h0000_0000                        ;
    localparam   rval_t                     TCM_ADDR_HI      = 32'h7fff_ffff                        ;
    localparam                              TCM_RAM_TYPE     = "block"                              ;
    localparam   bit                        TCM_READMEMB     = 1'b0                                 ;
    localparam   bit                        TCM_READMEMH     = 1'b1                                 ;
    localparam                              TCM_READMEM_FIlE = "../mem.hex"                         ;
    localparam  int                         M_AXI4L_PORTS     = 1                                   ;
    localparam  int                         M_AXI4L_ADDR_BITS = 32                                  ;
    localparam  type                        m_axi4l_data_t    = logic   [M_AXI4L_ADDR_BITS-1:0]     ;
    localparam  rval_t  [M_AXI4L_PORTS-1:0] M_AXI4L_ADDRS_LO  = '{32'h8000_0000}                    ;
    localparam  rval_t  [M_AXI4L_PORTS-1:0] M_AXI4L_ADDRS_HI  = '{32'hffff_ffff}                    ;
    localparam  bit     [THREADS-1:0]       INIT_RUN          = 1                                   ;
    localparam  id_t                        INIT_ID           = '0                                  ;
    localparam  pc_t    [THREADS-1:0]       INIT_PC           = '0                                  ;
    localparam   bit     [0:0]              INIT_CTL_CONTROL  = 1'b1                                ;

`ifdef __VERILATOR__
    localparam                              DEVICE            = "RTL"                               ;
`else
    localparam                              DEVICE            = "ULTRASCALE_PLUS";                  ;
`endif
    localparam                              SIMULATION        = "false"                             ;
    localparam                              DEBUG             = "false"                             ;


    logic               cke              = 1'b1;
    always @(posedge clk) begin
        // ランダム
        cke <= 1'b1; // $urandom_range(0, 1);
    end


    jelly3_axi4l_if
            #(
                .ADDR_BITS     (32          ),
                .DATA_BITS     (32          )
            )
        s_axi4l_ctl
            (
                .aresetn        (~reset     ),
                .aclk           (clk        ),
                .aclken         (1'b1       )
            );

    jelly3_axi4_if
            #(
                .ADDR_BITS     (32          ),
                .DATA_BITS     (32          )
            )
        s_axi4_mem
            (
                .aresetn        (~reset     ),
                .aclk           (clk        ),
                .aclken         (1'b1       )
            );

    jelly3_axi4l_if
            #(
                .ADDR_BITS     (32          ),
                .DATA_BITS     (32          )
            )
        m_axi4l
            (
                .aresetn        (~reset     ),
                .aclk           (clk        ),
                .aclken         (1'b1       )
            );



    jelly3_jfive_controller
            #(
                .XLEN               (XLEN               ),
                .THREADS            (THREADS            ),
                .PC_MASK            (PC_MASK            ),
                .LOAD_QUES          (LOAD_QUES          ),
                .TCM_MEM_SIZE       (TCM_MEM_SIZE       ),
                .TCM_ADDR_LO        (TCM_ADDR_LO        ),
                .TCM_ADDR_HI        (TCM_ADDR_HI        ),
                .TCM_RAM_TYPE       (TCM_RAM_TYPE       ),
                .TCM_READMEMB       (TCM_READMEMB       ),
                .TCM_READMEMH       (TCM_READMEMH       ),
                .TCM_READMEM_FIlE   (TCM_READMEM_FIlE   ),
                .M_AXI4L_PORTS      (M_AXI4L_PORTS      ),
                .M_AXI4L_ADDR_BITS  (M_AXI4L_ADDR_BITS  ),
                .M_AXI4L_ADDRS_LO   (M_AXI4L_ADDRS_LO   ),
                .M_AXI4L_ADDRS_HI   (M_AXI4L_ADDRS_HI   ),
                .INIT_RUN           (INIT_RUN           ),
                .INIT_ID            (INIT_ID            ),
                .INIT_PC            (INIT_PC            ),
                .INIT_CTL_CONTROL   (INIT_CTL_CONTROL   ),
                .DEVICE             (DEVICE             ),
                .SIMULATION         (SIMULATION         ),
                .DEBUG              (DEBUG              )
            )
        u_jfive_controller
            (
                .reset              ,
                .clk                ,
                .cke                ,
                .s_axi4l_ctl        (s_axi4l_ctl        ),
                .s_axi4_mem         (s_axi4_mem         ),
                .m_axi4l_ext        ('{m_axi4l}         )
            );


    jelly3_axi4l_register
            #(
                .NUM        (8          ),
                .BITS       (1          ),
                .INIT       ('0         )
            )
        u_axi4l_register
            (
                .s_axi4l    (m_axi4l    ),
                .value      (           )
            );

    
    assign s_axi4l_ctl.awvalid = 1'b0;
    assign s_axi4l_ctl.wvalid  = 1'b0;
    assign s_axi4l_ctl.bready  = 1'b0;
    assign s_axi4l_ctl.arvalid = 1'b0;
    assign s_axi4l_ctl.rready  = 1'b0;

    assign s_axi4_mem.awvalid = 1'b0;
    assign s_axi4_mem.wvalid  = 1'b0;
    assign s_axi4_mem.bready  = 1'b0;
    assign s_axi4_mem.arvalid = 1'b0;
    assign s_axi4_mem.rready  = 1'b0;


    always_ff @(posedge m_axi4l.aclk) begin
        if (  m_axi4l.aresetn == 1'b1 ) begin
            if ( m_axi4l.wvalid && m_axi4l.wready ) begin
                $write("%c", m_axi4l.wdata[7:0]);
            end
        end
    end

    /*
    assign m_axi4l.awready = 1'b1;
    assign m_axi4l.wready  = 1'b1;
    assign m_axi4l.bresp   = '0;
    assign m_axi4l.bvalid  = m_axi4l.awvalid & m_axi4l.awready;
    assign m_axi4l.arready = m_axi4l.rready;
    assign m_axi4l.rdata   = '0;
    assign m_axi4l.rvalid  =  m_axi4l.arvalid; 
    */



    // ------------------------------------------------
    //  Debug
    // ------------------------------------------------

    localparam  int                     DBUS_ADDR_BITS = 16                                 ;
    localparam  type                    dbus_addr_t    = logic         [DBUS_ADDR_BITS-1:0] ;
    localparam  int                     DBUS_DATA_BITS = XLEN                               ;
    localparam  type                    dbus_data_t    = logic         [DBUS_DATA_BITS-1:0] ;
    localparam  int                     DBUS_STRB_BITS = $bits(dbus_data_t) / 8             ;
    localparam  type                    dbus_strb_t    = logic         [DBUS_STRB_BITS-1:0] ;
    localparam  type                    ridx_t         = logic         [4:0]                ;
    localparam  int                     INSTR_BITS     = 32                                 ;
    localparam  type                    instr_t        = logic         [INSTR_BITS-1:0]     ;
    localparam  int                     LS_UNITS       = 1 + M_AXI4L_PORTS                  ;
    localparam  rval_t  [LS_UNITS-1:0]  LS_ADDRS_LO    = {M_AXI4L_ADDRS_LO, TCM_ADDR_LO}     ;
    localparam  rval_t  [LS_UNITS-1:0]  LS_ADDRS_HI    = {M_AXI4L_ADDRS_HI, TCM_ADDR_HI}     ;

    localparam  type                    mnemonic_t     = logic [64*8-1:0];
    
    /*
    wire    mnemonic_t   ibus_res_mnemonic = mnemonic_t'(instr2mnemonic(ibus_res_instr));

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

    wire    mnemonic_t   mems_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.u_jfive_execution.u_jfive_load_store.s_instr));

    wire    mnemonic_t   branch_mnemonic = mnemonic_t'(instr2mnemonic(u_jfive_core.branch_instr));
    wire    mnemonic_t   wb_mnemonic     = mnemonic_t'(instr2mnemonic(u_jfive_core.wb_instr));

    
    wire    ridx_t  exe_rd_idx0 = u_jfive_core.u_jfive_execution.exe_rd_idx[0];
    wire    ridx_t  exe_rd_idx1 = u_jfive_core.u_jfive_execution.exe_rd_idx[1];
    wire    ridx_t  exe_rd_idx2 = u_jfive_core.u_jfive_execution.exe_rd_idx[2];
    wire    ridx_t  exe_rd_idx3 = u_jfive_core.u_jfive_execution.exe_rd_idx[3];
    wire    ridx_t  exe_rd_idx4 = u_jfive_core.u_jfive_execution.exe_rd_idx[4];
//  wire    ridx_t  exe_rd_idx5 = u_jfive_core.u_jfive_execution.exe_rd_idx[5];
        */


    wire    mnemonic_t  wb_mnemonic     = mnemonic_t'(instr2mnemonic(u_jfive_controller.u_jfive_core.wb_instr));

    wire    pc_t        exe_pc        = u_jfive_controller.u_jfive_core.u_jfive_execution.st0_pc       ;
    wire    instr_t     exe_instr     = u_jfive_controller.u_jfive_core.u_jfive_execution.st0_instr    ;
    wire    logic       exe_rs1_en    = u_jfive_controller.u_jfive_core.u_jfive_execution.st0_rs1_en   ;
    wire    ridx_t      exe_rs1_idx   = u_jfive_controller.u_jfive_core.u_jfive_execution.st0_rs1_idx  ;
    wire    rval_t      exe_rs1_val   = u_jfive_controller.u_jfive_core.u_jfive_execution.st0_rs1_val  ;
    wire    logic       exe_rs2_en    = u_jfive_controller.u_jfive_core.u_jfive_execution.st0_rs2_en   ;
    wire    ridx_t      exe_rs2_idx   = u_jfive_controller.u_jfive_core.u_jfive_execution.st0_rs2_idx  ;
    wire    rval_t      exe_rs2_val   = u_jfive_controller.u_jfive_core.u_jfive_execution.st0_rs2_val  ;
    wire    logic       exe_valid     = u_jfive_controller.u_jfive_core.u_jfive_execution.st0_valid    ;
    wire    logic       exe_ready     = u_jfive_controller.u_jfive_core.u_jfive_execution.st0_ready    ;
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
        end
    end

    // dbus
    dbus_addr_t [LS_UNITS-1:0]  dbus_aaddr      ;
    logic       [LS_UNITS-1:0]  dbus_awrite     ;
    logic       [LS_UNITS-1:0]  dbus_aread      ;
    logic       [LS_UNITS-1:0]  dbus_avalid     ;
    logic       [LS_UNITS-1:0]  dbus_aready     ;
    dbus_strb_t [LS_UNITS-1:0]  dbus_wstrb      ;
    dbus_data_t [LS_UNITS-1:0]  dbus_wdata      ;
    logic       [LS_UNITS-1:0]  dbus_wvalid     ;
    logic       [LS_UNITS-1:0]  dbus_wready     ;
    dbus_data_t [LS_UNITS-1:0]  dbus_rdata      ;
    logic       [LS_UNITS-1:0]  dbus_rvalid     ;
    logic       [LS_UNITS-1:0]  dbus_rready     ;

    assign dbus_aaddr   = u_jfive_controller.dbus_aaddr ;
    assign dbus_awrite  = u_jfive_controller.dbus_awrite;
    assign dbus_aread   = u_jfive_controller.dbus_aread ;
    assign dbus_avalid  = u_jfive_controller.dbus_avalid;
    assign dbus_aready  = u_jfive_controller.dbus_aready;
    assign dbus_wstrb   = u_jfive_controller.dbus_wstrb ;
    assign dbus_wdata   = u_jfive_controller.dbus_wdata ;
    assign dbus_wvalid  = u_jfive_controller.dbus_wvalid;
    assign dbus_wready  = u_jfive_controller.dbus_wready;
    assign dbus_rdata   = u_jfive_controller.dbus_rdata ;
    assign dbus_rvalid  = u_jfive_controller.dbus_rvalid;
    assign dbus_rready  = u_jfive_controller.dbus_rready;

    int fp_dbus0_log;
    initial fp_dbus0_log = $fopen("dbus0_log.txt", "w");
    always_ff @(posedge clk) begin
        if ( !reset && cke ) begin
            if ( dbus_avalid[0] && dbus_aready[0] ) begin
                if ( dbus_awrite ) begin
                    $fwrite(fp_dbus0_log, "%d w addr:%08x %08x wdata:%08x strb:%b\n", exe_counter, dbus_aaddr[0], int'(dbus_aaddr[0]) << 2, dbus_wdata[0], dbus_wstrb[0]);
                end
                else begin
                    $fwrite(fp_dbus0_log, "%d r addr:%08x %08x\n", exe_counter, dbus_aaddr[0], int'(dbus_aaddr[0]) << 2);
                end
            end
            if ( dbus_rvalid[0] && dbus_rready[0] ) begin
                $fwrite(fp_dbus0_log, "r rdata:%08x\n", dbus_rdata[0]);
            end
        end
    end

endmodule


`default_nettype wire


// end of file
