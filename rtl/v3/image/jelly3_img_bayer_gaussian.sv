// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_bayer_gaussian
        #(
            parameter   int             MAX_COLS         = 4096                     ,
            parameter                   RAM_TYPE         = "block"                  ,
            parameter                   BORDER_MODE      = "REPLICATE"              ,
            parameter   bit             BYPASS_SIZE      = 1'b1                     ,
            parameter   bit             ROUND            = 1'b1                     ,
            parameter   int             REGADR_BITS      = 8                        ,
            parameter   type            regadr_t         = logic [REGADR_BITS-1:0]  ,
            parameter                   CORE_ID          = 32'h527a_437f            ,
            parameter                   CORE_VERSION     = 32'h0001_0000            ,
            parameter   bit     [0:0]   INIT_CTL_CONTROL = 1'b1                     
        )
        (
            input   var logic   in_update_req   ,

            jelly3_mat_if.s     s_img           ,
            jelly3_mat_if.m     m_img           ,
            
            jelly3_axi4l_if.s   s_axi4l
        );
    
    
    
    // -------------------------------------
    //  registers domain
    // -------------------------------------

    // type
    localparam type axi4l_addr_t = logic [$bits(s_axi4l.awaddr)-1:0];
    localparam type axi4l_data_t = logic [$bits(s_axi4l.wdata)-1:0];
    localparam type axi4l_strb_t = logic [$bits(s_axi4l.wstrb)-1:0];

    // register address offset
    localparam  regadr_t REGADR_CORE_ID       = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION  = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_CONTROL   = regadr_t'('h04);
    localparam  regadr_t REGADR_CTL_STATUS    = regadr_t'('h05);
    localparam  regadr_t REGADR_CTL_INDEX     = regadr_t'('h07);
    localparam  regadr_t REGADR_PARAM_PHASE   = regadr_t'('h08);
    localparam  regadr_t REGADR_PARAM_OFFSET0 = regadr_t'('h10);
    localparam  regadr_t REGADR_PARAM_OFFSET1 = regadr_t'('h11);
    localparam  regadr_t REGADR_PARAM_OFFSET2 = regadr_t'('h12);
    localparam  regadr_t REGADR_PARAM_OFFSET3 = regadr_t'('h13);
    
    // registers
    logic       [0:0]   reg_ctl_control     ;    // bit[0]:enable, bit[1]:update
        
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
            reg_ctl_control     <= INIT_CTL_CONTROL;

            s_axi4l.bvalid <= 1'b0;
            s_axi4l.rdata  <= 'x;
            s_axi4l.rvalid <= 1'b0;
        end
        else begin
            // write
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_CTL_CONTROL:   reg_ctl_control <= 1'(write_mask(axi4l_data_t'(reg_ctl_control), s_axi4l.wdata, s_axi4l.wstrb));
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
                REGADR_CORE_ID:        s_axi4l.rdata <= axi4l_data_t'(CORE_ID            );
                REGADR_CORE_VERSION:   s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION       );
                REGADR_CTL_CONTROL:    s_axi4l.rdata <= axi4l_data_t'(reg_ctl_control    );
                default:               s_axi4l.rdata <= '0;
                endcase
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;
    assign s_axi4l.arready = ~s_axi4l.rvalid || s_axi4l.rready;
    assign s_axi4l.rresp   = '0;
    
    

    // -------------------------------------
    //  core domain
    // -------------------------------------
    
    (* ASYNC_REG = "true" *)    logic   [0:0]   ff0_ctl_control, ff1_ctl_control;
    always_ff @(posedge s_img.clk) begin
        ff0_ctl_control <= reg_ctl_control;
        ff1_ctl_control <= ff0_ctl_control;
    end

    logic   [0:0]   core_ctl_control;
    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset ) begin
            core_ctl_control <= INIT_CTL_CONTROL;
        end
        else begin
            if ( in_update_req && s_img.valid && s_img.col_first && s_img.row_first ) begin
                core_ctl_control <= ff1_ctl_control;
            end
        end
    end
    
    
    // core
    jelly3_img_bayer_gaussian_core
            #(
                .MAX_COLS       (MAX_COLS           ),
                .RAM_TYPE       (RAM_TYPE           ),
                .BORDER_MODE    (BORDER_MODE        ),
                .BYPASS_SIZE    (BYPASS_SIZE        ),
                .ROUND          (ROUND              )
            )
        u_img_bayer_black_level_core
            (
                .enable         (core_ctl_control[0]),
                .s_img          (s_img              ),
                .m_img          (m_img              )
            );

endmodule


`default_nettype wire


// end of file
