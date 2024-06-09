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
            parameter   bit     RAW_HAZARD  = 1'b1                              ,
            parameter   bit     WAW_HAZARD  = 1'b1                              ,
            parameter           DEVICE      = "RTL"                             ,
            parameter           SIMULATION  = "false"                           ,
            parameter           DEBUG       = "false"                           
        )
        (
            input   var logic                   reset               ,
            input   var logic                   clk                 ,
            input   var logic                   cke                 ,

            // data bus 
            output  var addr_t                  dbus_cmd_addr       ,
            output  var logic                   dbus_cmd_wr         ,
            output  var strb_t                  dbus_cmd_strb       ,
            output  var data_t                  dbus_cmd_wdata      ,
            output  var logic                   dbus_cmd_valid      ,
            input   var logic                   dbus_cmd_acceptable ,

            input   var data_t                  dbus_res_rdata      ,
            input   var logic                   dbus_res_valid      ,
            output  var logic                   dbus_res_acceptable ,

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
            input   var strb_t                  s_strb              ,
            input   var rval_t                  s_wdata             ,
            input   var logic                   s_valid             ,
            output  var logic                   s_acceptable        ,

            // output   
            output  var id_t                    m_id                ,
            output  var logic                   m_rd_en             ,
            output  var ridx_t                  m_rd_idx            ,
            output  var rval_t                  m_rd_val            ,
            output  var logic                   m_valid             ,
            input   var logic                   m_acceptable        
        );



    // ------------------------------------
    //  queue
    // ------------------------------------

    id_t        quein_id            ;
    ridx_t      quein_rd_idx        ;
    align_t     quein_align         ;
    size_t      quein_size          ;
    logic       quein_unsigned      ;
    logic       quein_valid         ;
    logic       quein_acceptable    ;

    id_t        queout_id           ;
    ridx_t      queout_rd_idx       ;
    align_t     queout_align        ;
    size_t      queout_size         ;
    logic       queout_unsigned     ;
    logic       queout_valid        ;
    logic       queout_acceptable   ;

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

                .que_id          (que_id            ),
                .que_rd_en       (que_rd_en         ),
                .que_rd_idx      (que_rd_idx        ),
                .que_align       (                  ),
                .que_size        (                  ),
                .que_unsigned    (                  ),
                .que_valid       (                  ),

                .s_id            (quein_id          ),
                .s_rd_idx        (quein_rd_idx      ),
                .s_align         (quein_align       ),
                .s_size          (quein_size        ),
                .s_unsigned      (quein_unsigned    ),
                .s_valid         (quein_valid       ),
                .s_acceptable    (quein_acceptable  ),

                .m_id            (queout_id         ),
                .m_rd_idx        (queout_rd_idx     ),
                .m_align         (queout_align      ),
                .m_size          (queout_size       ),
                .m_unsigned      (queout_unsigned   ),
                .m_valid         (queout_valid      ),
                .m_acceptable    (queout_acceptable )
        );

    assign quein_id        = s_id                       ;
    assign quein_rd_idx    = s_rd_idx                   ;
    assign quein_align     = align_t'(s_addr)           ;
    assign quein_size      = s_size                     ;
    assign quein_unsigned  = s_unsigned                 ;       
    assign quein_valid     = s_rd && dbus_cmd_acceptable;



    // ------------------------------------
    //  command
    // ------------------------------------

    assign dbus_cmd_addr  = s_addr                      ;
    assign dbus_cmd_wr    = s_wr                        ;
    assign dbus_cmd_strb  = s_strb                      ;
    assign dbus_cmd_wdata = s_wdata                     ;
    assign dbus_cmd_valid = s_valid & quein_acceptable  ;

    assign s_acceptable = !s_valid || (dbus_cmd_acceptable && quein_acceptable);


    // ------------------------------------
    //  Stage 0
    // ------------------------------------

    id_t                st0_id            ;
    logic               st0_rd_en         ;
    ridx_t              st0_rd_idx        ;
    rval_t              st0_rd_val        ;
    rval_t              st0_addr          ;
    logic               st0_rd            ;
    logic               st0_wr            ;
    strb_t              st0_strb          ;
    rval_t              st0_wdata         ;
//  logic               st0_valid         ;

    always_ff @(posedge clk ) begin
        if ( cke ) begin
            if ( !m_valid || m_acceptable ) begin
                st0_rd_en  <= 1'b0          ;  
                if ( dbus_res_valid && dbus_res_acceptable ) begin
                    st0_id     <= queout_id     ;
                    st0_rd_en  <= 1'b1          ;  
                    st0_rd_idx <= queout_rd_idx;

                    if ( queout_unsigned ) begin
                        case ( queout_size )
                        2'b00:      st0_rd_val <= rval_t'($unsigned(dbus_res_rdata[ 7:0]));
                        2'b01:      st0_rd_val <= rval_t'($unsigned(dbus_res_rdata[15:0]));
                        2'b10:      st0_rd_val <= rval_t'($unsigned(dbus_res_rdata[31:0]));
                        default:    st0_rd_val <= rval_t'($unsigned(dbus_res_rdata));
                        endcase
                    end
                    else begin
                        case ( queout_size )
                        2'b00:      st0_rd_val <= rval_t'($signed(dbus_res_rdata[ 7:0]));
                        2'b01:      st0_rd_val <= rval_t'($signed(dbus_res_rdata[15:0]));
                        2'b10:      st0_rd_val <= rval_t'($signed(dbus_res_rdata[31:0]));
                        default:    st0_rd_val <= rval_t'($signed(dbus_res_rdata));
                        endcase
                    end
                end
            end
        end
    end

    assign dbus_res_acceptable = m_acceptable;

    assign queout_acceptable  = !dbus_res_valid || dbus_res_acceptable;


    // ------------------------------------
    //  Output
    // ------------------------------------

    assign m_id     = st0_id           ;
    assign m_rd_en  = st0_rd_en        ;
    assign m_rd_idx = st0_rd_idx       ;
    assign m_rd_val = st0_rd_val       ;
    assign m_valid  = st0_rd_en        ;

endmodule


`default_nettype wire


// End of file
