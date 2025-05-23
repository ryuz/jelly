// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_load_store
        #(
            parameter   int     LOAD_QUES   = 4                                 ,
            parameter   int     XLEN        = 32                                ,
            parameter   int     ID_BITS     = 4                                 ,
            parameter   type    id_t        = logic         [ID_BITS-1:0]       ,
            parameter   int     PHASE_BITS  = 1                                 ,
            parameter   type    phase_t     = logic         [PHASE_BITS-1:0]    ,
            parameter   int     PC_BITS     = 32                                ,
            parameter   type    pc_t        = logic         [PC_BITS-1:0]       ,
            parameter   int     INSTR_BITS  = 32                                ,
            parameter   type    instr_t     = logic         [INSTR_BITS-1:0]    ,
            parameter   type    ridx_t      = logic         [4:0]               ,
            parameter   type    rval_t      = logic signed  [XLEN-1:0]          ,
            parameter   int     ADDR_BITS   = $bits(rval_t)                     ,
            parameter   type    addr_t      = logic         [ADDR_BITS-1:0]     ,
            parameter   int     DATA_BITS   = $bits(rval_t)                     ,
            parameter   type    data_t      = logic         [DATA_BITS-1:0]     ,
            parameter   int     STRB_BITS   = $bits(data_t) / 8                 ,
            parameter   type    strb_t      = logic         [STRB_BITS-1:0]     ,
            parameter   int     ALIGN_BITS  = $clog2($bits(strb_t))             ,
            parameter   type    align_t     = logic         [ALIGN_BITS-1:0]    ,
            parameter   type    size_t      = logic         [1:0]               ,
            parameter   rval_t  ADDR_LO     = '0                                ,
            parameter   rval_t  ADDR_HI     = '1                                ,
            parameter           DEVICE      = "RTL"                             ,
            parameter           SIMULATION  = "false"                           ,
            parameter           DEBUG       = "false"                           
        )
        (
            input   var logic                   reset               ,
            input   var logic                   clk                 ,
            input   var logic                   cke                 ,

            // data bus 
            output  var addr_t                  dbus_aaddr          ,
            output  var logic                   dbus_awrite         ,
            output  var logic                   dbus_aread          ,
            output  var logic                   dbus_avalid         ,
            input   var logic                   dbus_aready         ,
            output  var strb_t                  dbus_wstrb          ,
            output  var data_t                  dbus_wdata          ,
            output  var logic                   dbus_wvalid         ,
            input   var logic                   dbus_wready         ,
            input   var data_t                  dbus_rdata          ,
            input   var logic                   dbus_rvalid         ,
            output  var logic                   dbus_rready         ,

            // execution
            output  var id_t    [LOAD_QUES-1:0] que_id              ,
            output  var logic   [LOAD_QUES-1:0] que_rd_en           ,
            output  var ridx_t  [LOAD_QUES-1:0] que_rd_idx          ,

            // input
            input   var id_t                    s_id                ,
            input   var phase_t                 s_phase             ,
            input   var pc_t                    s_pc                ,
            input   var instr_t                 s_instr             ,
            input   var logic                   s_rd_en             ,
            input   var ridx_t                  s_rd_idx            ,
            input   var rval_t                  s_addr              ,
            input   var size_t                  s_size              ,
            input   var logic                   s_unsigned          ,
            input   var logic                   s_rd                ,
            input   var logic                   s_wr                ,
            input   var strb_t                  s_wstrb             ,
            input   var rval_t                  s_wdata             ,
            input   var logic                   s_valid             ,
            output  var logic                   s_ready             ,

            // output   
            output  var id_t                    m_id                ,
            output  var pc_t                    m_pc                ,
            output  var instr_t                 m_instr             ,
            output  var logic                   m_rd_en             ,
            output  var ridx_t                  m_rd_idx            ,
            output  var rval_t                  m_rd_val            ,
            output  var logic                   m_valid             ,
            input   var logic                   m_ready        
        );

    // ------------------------------------
    //  parameter
    // ------------------------------------

    localparam   align_t  align_mask_b = ~align_t'('b000);
    localparam   align_t  align_mask_h = ~align_t'('b001);
    localparam   align_t  align_mask_w = ~align_t'('b011);

    rval_t  param_ADDR_LO = ADDR_LO;
    rval_t  param_ADDR_HI = ADDR_HI;


    // ------------------------------------
    //  input
    // ------------------------------------

    /* verilator lint_off UNSIGNED */
    /* verilator lint_off CMPCONST */
    logic       s_addr_valid;
    assign s_addr_valid = s_valid 
                    && $unsigned(s_addr) >= $unsigned(ADDR_LO)
                    && $unsigned(s_addr) <= $unsigned(ADDR_HI);
    /* verilator lint_on UNSIGNED */
    /* verilator lint_on CMPCONST */


    // ------------------------------------
    //  queue
    // ------------------------------------

    id_t        quein_id            ;
    pc_t        quein_pc            ;
    instr_t     quein_instr         ;
    ridx_t      quein_rd_idx        ;
    align_t     quein_align         ;
    size_t      quein_size          ;
    logic       quein_unsigned      ;
    logic       quein_valid         ;
    logic       quein_ready         ;

    id_t        queout_id           ;
    pc_t        queout_pc           ;
    instr_t     queout_instr        ;
    ridx_t      queout_rd_idx       ;
    align_t     queout_align        ;
    size_t      queout_size         ;
    logic       queout_unsigned     ;
    logic       queout_valid        ;
    logic       queout_ready        ;

    jelly3_jfive_load_queue
            #(
                .QUE_SIZE       (LOAD_QUES          ),
                .XLEN           (XLEN               ),
                .ID_BITS        (ID_BITS            ),
                .id_t           (id_t               ),
                .ridx_t         (ridx_t             ),
                .ALIGN_BITS     (ALIGN_BITS         ),
                .align_t        (align_t            ),
                .size_t         (size_t             ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_jfive_load_queue
            (
                .reset           ,
                .clk             ,
                .cke             ,

                .que_id         (que_id             ),
                .que_pc         (                   ),
                .que_instr      (                   ),
                .que_rd_en      (que_rd_en          ),
                .que_rd_idx     (que_rd_idx         ),
                .que_align      (                   ),
                .que_size       (                   ),
                .que_unsigned   (                   ),
                .que_valid      (                   ),

                .s_id           (quein_id           ),
                .s_pc           (quein_pc           ),
                .s_instr        (quein_instr        ),
                .s_rd_idx       (quein_rd_idx       ),
                .s_align        (quein_align        ),
                .s_size         (quein_size         ),
                .s_unsigned     (quein_unsigned     ),
                .s_valid        (quein_valid        ),
                .s_ready        (quein_ready        ),

                .m_id           (queout_id          ),
                .m_pc           (queout_pc          ),
                .m_instr        (queout_instr       ),
                .m_rd_idx       (queout_rd_idx      ),
                .m_align        (queout_align       ),
                .m_size         (queout_size        ),
                .m_unsigned     (queout_unsigned    ),
                .m_valid        (queout_valid       ),
                .m_ready        (queout_ready       )
        );

    assign quein_id        = s_id                           ;
    assign quein_pc        = s_pc                           ;
    assign quein_instr     = s_instr                        ;
    assign quein_rd_idx    = s_rd_idx                       ;
    assign quein_align     = align_t'(s_addr)               ;
    assign quein_size      = s_size                         ;
    assign quein_unsigned  = s_unsigned                     ;
    assign quein_valid     = s_rd_en && s_addr_valid && s_ready;


    
    // ------------------------------------
    //  send command
    // ------------------------------------

    id_t        cmd0_id     ;
    pc_t        cmd0_pc     ;
    instr_t     cmd0_instr  ;
    addr_t      cmd0_aaddr  ;
    logic       cmd0_awrite ;
    logic       cmd0_aread  ;
    logic       cmd0_avalid ;
    strb_t      cmd0_wstrb  ;
    data_t      cmd0_wdata  ;
    logic       cmd0_wvalid ;

    always_ff @(posedge clk ) begin
        if ( reset ) begin
            cmd0_id     <= 'x;
            cmd0_pc     <= 'x;
            cmd0_instr  <= 'x;
            cmd0_aaddr  <= 'x;
            cmd0_awrite <= 1'b0;
            cmd0_aread  <= 1'b0;
            cmd0_avalid <= 1'b0;
            cmd0_wstrb  <= '0;
            cmd0_wdata  <= 'x;
            cmd0_wvalid <= 1'b0;
        end
        else if ( cke ) begin
            if ( dbus_aready ) begin
                 cmd0_awrite <= 1'b0;
                 cmd0_aread  <= 1'b0;
                 cmd0_avalid <= 1'b0;
            end
            if ( dbus_aready ) begin
                 cmd0_wstrb  <= '0  ;
                 cmd0_wvalid <= 1'b0;
            end
            if ( s_ready ) begin
                cmd0_id     <= s_id     ;
                cmd0_pc     <= s_pc     ;
                cmd0_instr  <= s_instr  ;
                cmd0_aaddr  <= addr_t'(s_addr >> $clog2($bits(strb_t))) ;
                cmd0_awrite <= s_addr_valid &&  s_wr        ;
                cmd0_aread  <= s_addr_valid && !s_wr        ;
                cmd0_avalid <= s_addr_valid                 ;
                cmd0_wstrb  <= s_addr_valid ? s_wstrb : '0  ;
                cmd0_wdata  <= s_wdata                      ;
                cmd0_wvalid <= s_addr_valid &&  s_wr        ;
            end
        end
    end

    assign dbus_aaddr  = cmd0_aaddr     ;
    assign dbus_awrite = cmd0_awrite    ;
    assign dbus_aread  = cmd0_aread     ;
    assign dbus_avalid = cmd0_avalid    ;
    assign dbus_wstrb  = cmd0_wstrb     ;
    assign dbus_wdata  = cmd0_wdata     ;
    assign dbus_wvalid = cmd0_wvalid    ;

    assign s_ready = (!dbus_avalid || dbus_aready) && (!dbus_wvalid || dbus_wready) && quein_ready;


    // ------------------------------------
    //  recv response
    // ------------------------------------

    id_t                res0_id            ;
    pc_t                res0_pc            ;
    instr_t             res0_instr         ;
    logic               res0_rd_en         ;
    ridx_t              res0_rd_idx        ;
    rval_t              res0_rd_val        ;

    align_t             queout_align_b     ;
    align_t             queout_align_h     ;
    align_t             queout_align_w     ;
    assign queout_align_b = queout_align & ~align_t'('b000);
    assign queout_align_h = queout_align & ~align_t'('b001);
    assign queout_align_w = queout_align & ~align_t'('b011);

    rval_t              dbus_rdata_alignd_b;
    rval_t              dbus_rdata_alignd_h;
    rval_t              dbus_rdata_alignd_w;
    assign dbus_rdata_alignd_b = (dbus_rdata >> (8 * int'(queout_align_b)));
    assign dbus_rdata_alignd_h = (dbus_rdata >> (8 * int'(queout_align_h)));
    assign dbus_rdata_alignd_w = (dbus_rdata >> (8 * int'(queout_align_w)));

    always_ff @(posedge clk ) begin
        if ( reset ) begin
            res0_id      <= 'x   ;
            res0_pc      <= 'x   ;
            res0_instr   <= 'x   ;
            res0_rd_en   <= 1'b0 ;
            res0_rd_idx  <= 'x   ;
            res0_rd_val  <= 'x   ;
        end
        else if ( cke ) begin
            if ( !m_valid || m_ready ) begin
                res0_rd_en  <= 1'b0          ;  
                if ( dbus_rvalid && dbus_rready ) begin
                    res0_id     <= queout_id     ;
                    res0_pc     <= queout_pc     ;
                    res0_instr  <= queout_instr  ;
                    res0_rd_en  <= 1'b1          ;  
                    res0_rd_idx <= queout_rd_idx;

                    if ( queout_unsigned ) begin
                        case ( queout_size )
                        2'b00:      res0_rd_val <= rval_t'($unsigned(dbus_rdata_alignd_b[ 7:0]));
                        2'b01:      res0_rd_val <= rval_t'($unsigned(dbus_rdata_alignd_h[15:0]));
                        2'b10:      res0_rd_val <= rval_t'($unsigned(dbus_rdata_alignd_w[31:0]));
                        default:    res0_rd_val <= rval_t'($unsigned(dbus_rdata));
                        endcase
                    end
                    else begin
                        case ( queout_size )
                        2'b00:      res0_rd_val <= rval_t'($signed(dbus_rdata_alignd_b[ 7:0]));
                        2'b01:      res0_rd_val <= rval_t'($signed(dbus_rdata_alignd_h[15:0]));
                        2'b10:      res0_rd_val <= rval_t'($signed(dbus_rdata_alignd_w[31:0]));
                        default:    res0_rd_val <= rval_t'($signed(dbus_rdata));
                        endcase
                    end
                end
            end
        end
    end

    assign dbus_rready = m_ready;

    assign queout_ready  = (dbus_rvalid && dbus_rready); // || !queout_valid;


    // ------------------------------------
    //  Output
    // ------------------------------------

    assign m_id     = res0_id           ;
    assign m_pc     = res0_pc           ;
    assign m_instr  = res0_instr        ;
    assign m_rd_en  = res0_rd_en        ;
    assign m_rd_idx = res0_rd_idx       ;
    assign m_rd_val = res0_rd_val       ;
    assign m_valid  = res0_rd_en        ;

endmodule


`default_nettype wire


// End of file
