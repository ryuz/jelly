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
            parameter   int     XLEN        = 32                                ,
            parameter   int     THREADS     = 4                                 ,
            parameter   int     ID_BITS     = THREADS > 1 ? $clog2(THREADS) : 1 ,
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
            input   var logic               reset           ,
            input   var logic               clk             ,
            input   var logic               cke             ,

            // data bus
            output  var addr_t              dbus_cmd_addr   ,
            output  var logic               dbus_cmd_wr     ,
            output  var strb_t              dbus_cmd_strb   ,
            output  var data_t              dbus_cmd_wdata  ,
            output  var logic               dbus_cmd_valid  ,
            input   var logic               dbus_cmd_wait   ,

            input   var data_t              dbus_ack_rdata  ,
            input   var logic               dbus_ack_valid  ,
            output  var logic               dbus_ack_wait   ,

            // input
            input   var id_t                s_id            ,
            input   var logic               s_rd_en         ,
            input   var ridx_t              s_rd_idx        ,
            input   var rval_t              s_addr          ,
            input   var logic               s_rd            ,
            input   var logic               s_wr            ,
            input   var strb_t              s_strb          ,
            input   var rval_t              s_wdata         ,
            input   var logic               s_valid         ,
            output  var logic               s_wait          ,

            // output
            output  var id_t                m_id            ,
            output  var logic               m_rd_en         ,
            output  var ridx_t              m_rd_idx        ,
            output  var rval_t              m_rd_val        ,
            output  var logic               m_valid         ,
            input   var logic               m_wait          
        );


    // ------------------------------------
    //  command
    // ------------------------------------

    assign dbus_cmd_addr  = s_addr;
    assign dbus_cmd_wr    = s_wr;
    assign dbus_cmd_strb  = s_strb;
    assign dbus_cmd_wdata = s_wdata;
    assign dbus_cmd_valid = s_valid;

    assign s_wait = dbus_cmd_wait; //  || (st0_valid && !(dbus_ack_valid && !dbus_ack_wait));


    // ------------------------------------
    //  Stage 0
    // ------------------------------------

    id_t                st0_id            ;
    logic               st0_rd_en         ;
    ridx_t              st0_rd_idx        ;
    align_t             st0_align         ;
    size_t              st0_size          ;
    logic               st0_unsigned      ;
    logic               st0_rd            ;
    logic               st0_wr            ;
    strb_t              st0_strb          ;
    rval_t              st0_wdata         ;
    logic               st0_valid         ;

    always_ff @( posedge clk ) begin
        if ( reset ) begin
            st0_id      <= 'x;
            st0_rd_en   <= 'x;
            st0_rd_idx  <= 'x;
            st0_align   <= 'x;
            st0_size    <= 'x;
            st0_rd      <= 'x;
            st0_wr      <= 'x;
            st0_strb    <= 'x;
            st0_wdata   <= 'x;
            st0_valid   <= 'x;
        end
        else if ( cke && !s_wait ) begin
            st0_id      <= s_id             ;
            st0_rd_en   <= s_rd_en          ;
            st0_rd_idx  <= s_rd_idx         ;
            st0_align   <= align_t'(s_addr) ;
            st0_rd      <= s_rd             ;
            st0_wr      <= s_wr             ;
            st0_strb    <= s_strb           ;
            st0_wdata   <= s_wdata          ;
            st0_valid   <= s_valid          ;
        end
    end

    rval_t      st0_rdata;
    assign st0_rdata = (dbus_ack_rdata >> (st0_align * 8));


    // ------------------------------------
    //  Stage 1
    // ------------------------------------

    id_t                st1_id            ;
    logic               st1_rd_en         ;
    ridx_t              st1_rd_idx        ;
    rval_t              st1_rd_val        ;
    rval_t              st1_addr          ;
    logic               st1_rd            ;
    logic               st1_wr            ;
    strb_t              st1_strb          ;
    rval_t              st1_wdata         ;
    logic               st1_valid         ;

    always_ff @(posedge clk ) begin
        if ( cke ) begin
            if ( !m_wait ) begin
                st1_valid <= 1'b0;
            end

            if ( dbus_ack_valid && !dbus_ack_wait ) begin
                st1_id     <= st0_id    ;
                st1_rd_en  <= st0_rd_en ;
                st1_rd_idx <= st0_rd_idx;

                if ( st0_unsigned ) begin
                    case ( st0_size )
                    2'b00:      st1_rd_val <= rval_t'($unsigned(st0_rdata[ 7:0]));
                    2'b01:      st1_rd_val <= rval_t'($unsigned(st0_rdata[15:0]));
                    2'b10:      st1_rd_val <= rval_t'($unsigned(st0_rdata[31:0]));
                    default:    st1_rd_val <= rval_t'($unsigned(st0_rdata));
                    endcase
                end
                else begin
                    case ( st0_size )
                    2'b00:      st1_rd_val <= rval_t'($signed(st0_rdata[ 7:0]));
                    2'b01:      st1_rd_val <= rval_t'($signed(st0_rdata[15:0]));
                    2'b10:      st1_rd_val <= rval_t'($signed(st0_rdata[31:0]));
                    default:    st1_rd_val <= rval_t'($signed(st0_rdata));
                    endcase
                end

                st1_valid <= 1'b1;
            end
        end
    end

    assign dbus_ack_wait = m_wait;


    // ------------------------------------
    //  Output
    // ------------------------------------

    assign m_id     = st1_id     ;
    assign m_rd_val = st1_rd_val;


endmodule


`default_nettype wire


// End of file
