// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_selector
        #(
            parameter   int     NUM             = 2                         ,
            parameter   int     SEL_BITS        = $clog2(NUM)               ,
            parameter   type    sel_t           = logic [SEL_BITS-1:0]      ,

            parameter   int     REGADR_BITS     = 8                         ,
            parameter   type    regadr_t        = logic [REGADR_BITS-1:0]   ,
            parameter   int     CORE_ID         = 32'h527a_2f10             ,
            parameter   int     CORE_VERSION    = 32'h0001_0000             ,
            parameter   sel_t   INIT_CTL_SELECT = 0
        )
        (
            jelly3_mat_if.s     s_img   [NUM]   ,
            jelly3_mat_if.m     m_img           ,

            jelly3_axi4l_if.s   s_axi4l         
        );
    

    // -------------------------------------
    //  registers domain
    // -------------------------------------

    // type
    localparam type axi4l_addr_t = logic [$bits(s_axi4l.awaddr)-1:0];
    localparam type axi4l_data_t = logic [$bits(s_axi4l.wdata)-1:0] ;
    localparam type axi4l_strb_t = logic [$bits(s_axi4l.wstrb)-1:0] ;

    // register address offset
    localparam  regadr_t REGADR_CORE_ID      = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_SELECT   = regadr_t'('h08);
    localparam  regadr_t REGADR_CONFIG_NUM   = regadr_t'('h10);
    
    // registers
    sel_t               reg_ctl_select  ;
    
    // write mask
    function [s_axi4l.DATA_BITS-1:0] write_mask(
                                        input axi4l_data_t org,
                                        input axi4l_data_t data,
                                        input axi4l_strb_t strb
                                    );
        for ( int i = 0; i < s_axi4l.DATA_BITS; i++ ) begin
            write_mask[i] = strb[i/8] ? data[i] : org[i];
        end
    endfunction
    
    // registers control
    regadr_t  regadr_write;
    regadr_t  regadr_read;
    assign regadr_write = regadr_t'(s_axi4l.awaddr / axi4l_addr_t'($bits(axi4l_strb_t)));
    assign regadr_read  = regadr_t'(s_axi4l.araddr / axi4l_addr_t'($bits(axi4l_strb_t)));

    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            reg_ctl_select <= INIT_CTL_SELECT   ;

            s_axi4l.bvalid <= 1'b0  ;
            s_axi4l.rdata  <= 'x    ;
            s_axi4l.rvalid <= 1'b0  ;
        end
        else begin
            // write
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_CTL_SELECT:  reg_ctl_select <= sel_t'(write_mask(axi4l_data_t'(reg_ctl_select), s_axi4l.wdata, s_axi4l.wstrb));
                default: ;
                endcase
                s_axi4l.bvalid <= 1'b1;
            end

            // read
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                case ( regadr_read )
                REGADR_CORE_ID:         s_axi4l.rdata <= axi4l_data_t'(CORE_ID          );
                REGADR_CORE_VERSION:    s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION     );
                REGADR_CTL_SELECT:      s_axi4l.rdata <= axi4l_data_t'(reg_ctl_select   );
                REGADR_CONFIG_NUM:      s_axi4l.rdata <= axi4l_data_t'(NUM              );
                default:                s_axi4l.rdata <= '0;
                endcase
                s_axi4l.rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;
    assign s_axi4l.arready = ~s_axi4l.rvalid || s_axi4l.rready;
    assign s_axi4l.rresp   = '0;
    
    
    
    // ---------------------------------
    //  Core
    // ---------------------------------
    
    jelly3_img_selector_core
            #(
                .NUM                (NUM            ),
                .SEL_BITS           (SEL_BITS       ),
                .sel_t              (sel_t          )
            )
        u_img_selector_core
            (
                .sel                (reg_ctl_select ),
                .s_img              (s_img          ),
                .m_img              (m_img          )
            );
    
endmodule


`default_nettype wire


// end of file
