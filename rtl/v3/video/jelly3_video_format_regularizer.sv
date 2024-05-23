// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_video_format_regularizer
        #(
            parameter   int             WIDTH_BITS       = 16                           ,
            parameter   type            width_t          = logic [WIDTH_BITS-1:0]       ,
            parameter   int             HEIGHT_BITS      = 16                           ,
            parameter   type            height_t         = logic [HEIGHT_BITS-1:0]      ,
            parameter   int             INDEX_BITS       = 1                            ,
            parameter   type            index_t          = logic [INDEX_BITS-1:0]       ,
            parameter   int             FRAME_TIMER_BITS = 32                           ,
            parameter   type            frame_timer_t    = logic [FRAME_TIMER_BITS-1:0] ,
            parameter   int             TIMER_BITS       = 32                           ,
            parameter   type            timer_t          = logic [TIMER_BITS-1:0]       ,
            parameter   int             REGADR_BITS      = 8                            ,
            parameter   type            regadr_t         = logic [REGADR_BITS-1:0]      ,

            parameter   bit             S_REGS           = 1,
            parameter   bit             M_REGS           = 1,

            parameter                   CORE_ID          = 32'h527a_1220,
            parameter                   CORE_VERSION     = 32'h0001_0000,

            parameter   bit     [1:0]   INIT_CTL_CONTROL      = 2'b00,
            parameter   bit             INIT_CTL_SKIP         = 1,
            parameter   bit             INIT_CTL_FRM_TIMER_EN = 0,
            parameter   frame_timer_t   INIT_CTL_FRM_TIMEOUT  = 1000000,
            parameter   width_t         INIT_PARAM_WIDTH      = 640,
            parameter   height_t        INIT_PARAM_HEIGHT     = 480,
            parameter                   INIT_PARAM_FILL       = 0,
            parameter   timer_t         INIT_PARAM_TIMEOUT    = 0
        )
        (
            input   var logic                   aclken,

            jelly3_axi4s_if.s                   s_axi4s,
            jelly3_axi4s_if.m                   m_axi4s,

            jelly3_axi4l_if.s                   s_axi4l,

            output  var width_t                 out_param_width,
            output  var height_t                out_param_height
        );
    
    
    localparam type axi4s_data_t = logic [m_axi4s.DATA_BITS-1:0];
    localparam type axi4l_data_t = logic [s_axi4l.DATA_BITS-1:0];
    


    // -------------------------------------
    //  registers
    // -------------------------------------
    
    // register address offset
    localparam  regadr_t REGADR_CORE_ID            = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION       = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_CONTROL        = regadr_t'('h04);
    localparam  regadr_t REGADR_CTL_STATUS         = regadr_t'('h05);
    localparam  regadr_t REGADR_CTL_INDEX          = regadr_t'('h07);
    localparam  regadr_t REGADR_CTL_SKIP           = regadr_t'('h08);
    localparam  regadr_t REGADR_CTL_FRM_TIMER_EN   = regadr_t'('h0a);
    localparam  regadr_t REGADR_CTL_FRM_TIMEOUT    = regadr_t'('h0b);
    localparam  regadr_t REGADR_PARAM_WIDTH        = regadr_t'('h10);
    localparam  regadr_t REGADR_PARAM_HEIGHT       = regadr_t'('h11);
    localparam  regadr_t REGADR_PARAM_FILL         = regadr_t'('h12);
    localparam  regadr_t REGADR_PARAM_TIMEOUT      = regadr_t'('h13);

    
    // registers
    logic   [1:0]   reg_ctl_control;
    logic           reg_ctl_skip;
    logic           reg_ctl_frm_timer_en;
    frame_timer_t   reg_ctl_frm_timeout;

    width_t         reg_param_width;
    height_t        reg_param_height;
    axi4s_data_t    reg_param_fill;
    timer_t         reg_param_timeout;
    
    // status
    logic           busy;
    index_t         index;
    
    // latch core domain signals
    (* ASYNC_REG = "true" *)    logic     ff0_busy,  ff1_busy;
    (* ASYNC_REG = "true" *)    index_t   ff0_index, ff1_index, ff2_index;
    always_ff @(posedge s_axi4l.aclk) begin
        ff0_busy  <= busy       ;
        ff1_busy  <= ff0_busy   ;
        ff0_index <= index      ;
        ff1_index <= ff0_index  ;
        ff2_index <= ff1_index  ;
    end

    function [s_axi4l.DATA_BITS-1:0] write_mask(
                                        input [s_axi4l.DATA_BITS-1:0] org,
                                        input [s_axi4l.DATA_BITS-1:0] data,
                                        input [s_axi4l.STRB_BITS-1:0] strb
                                    );
        for ( int i = 0; i < s_axi4l.DATA_BITS; i++ ) begin
            write_mask[i] = strb[i/8] ? data[i] : org[i];
        end
    endfunction

    regadr_t  regadr_write;
    regadr_t  regadr_read;
    assign regadr_write = regadr_t'(s_axi4l.awaddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));
    assign regadr_read  = regadr_t'(s_axi4l.araddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));

    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            reg_ctl_control      <= INIT_CTL_CONTROL;
            reg_ctl_skip         <= INIT_CTL_SKIP;
            reg_ctl_frm_timer_en <= INIT_CTL_FRM_TIMER_EN;
            reg_ctl_frm_timeout  <= INIT_CTL_FRM_TIMEOUT;
            reg_param_width      <= INIT_PARAM_WIDTH;
            reg_param_height     <= INIT_PARAM_HEIGHT;
            reg_param_fill       <= INIT_PARAM_FILL;
            reg_param_timeout    <= INIT_PARAM_TIMEOUT;
        end
        else begin
            if ( ff1_index[0] != ff2_index[0] ) begin
                reg_ctl_control[1] <= 1'b0;     // auto clear
            end
            
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_CTL_CONTROL:        reg_ctl_control      <=             2'(write_mask(axi4l_data_t'(reg_ctl_control      ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_CTL_SKIP:           reg_ctl_skip         <=             1'(write_mask(axi4l_data_t'(reg_ctl_skip         ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_CTL_FRM_TIMER_EN:   reg_ctl_frm_timer_en <=             1'(write_mask(axi4l_data_t'(reg_ctl_frm_timer_en ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_CTL_FRM_TIMEOUT:    reg_ctl_frm_timeout  <= frame_timer_t'(write_mask(axi4l_data_t'(reg_ctl_frm_timeout  ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_WIDTH:        reg_param_width      <=       width_t'(write_mask(axi4l_data_t'(reg_param_width      ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_HEIGHT:       reg_param_height     <=      height_t'(write_mask(axi4l_data_t'(reg_param_height     ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_FILL:         reg_param_fill       <=  axi4s_data_t'(write_mask(axi4l_data_t'(reg_param_fill       ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_TIMEOUT:      reg_param_timeout    <=       timer_t'(write_mask(axi4l_data_t'(reg_param_timeout    ), s_axi4l.wdata, s_axi4l.wstrb));
                default: ;
                endcase
            end
        end
    end

    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            s_axi4l.bvalid <= 0;
        end
        else begin
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready ) begin
                s_axi4l.bvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;


    // read
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( s_axi4l.arvalid && s_axi4l.arready ) begin
            case ( regadr_read )
            REGADR_CORE_ID:            s_axi4l.rdata <= axi4l_data_t'(CORE_ID             );
            REGADR_CORE_VERSION:       s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION        );
            REGADR_CTL_CONTROL:        s_axi4l.rdata <= axi4l_data_t'(reg_ctl_control     );
            REGADR_CTL_STATUS:         s_axi4l.rdata <= axi4l_data_t'(ff1_busy            );
            REGADR_CTL_INDEX:          s_axi4l.rdata <= axi4l_data_t'(ff1_index           );
            REGADR_CTL_SKIP:           s_axi4l.rdata <= axi4l_data_t'(reg_ctl_skip        );
            REGADR_CTL_FRM_TIMER_EN:   s_axi4l.rdata <= axi4l_data_t'(reg_ctl_frm_timer_en);
            REGADR_CTL_FRM_TIMEOUT:    s_axi4l.rdata <= axi4l_data_t'(reg_ctl_frm_timeout );
            REGADR_PARAM_WIDTH:        s_axi4l.rdata <= axi4l_data_t'(reg_param_width     );
            REGADR_PARAM_HEIGHT:       s_axi4l.rdata <= axi4l_data_t'(reg_param_height    );
            REGADR_PARAM_FILL:         s_axi4l.rdata <= axi4l_data_t'(reg_param_fill      );
            REGADR_PARAM_TIMEOUT:      s_axi4l.rdata <= axi4l_data_t'(reg_param_timeout   );
            default: ;
            endcase
        end
    end

    logic           axi4l_rvalid;
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            s_axi4l.rvalid <= 1'b0;
        end
        else begin
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                s_axi4l.rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.arready = ~s_axi4l.rvalid || s_axi4l.rready;
    assign s_axi4l.rresp   = '0;
    
    
    
    // -------------------------------------
    //  core
    // -------------------------------------
    
    // core
    (* ASYNC_REG = "true" *)    logic     ff0_ctl_enable,        ff1_ctl_enable,    ff2_ctl_enable;
    (* ASYNC_REG = "true" *)    logic     ff0_ctl_update,        ff1_ctl_update;
    (* ASYNC_REG = "true" *)    logic     ff0_ctl_skip,          ff1_ctl_skip;
    (* ASYNC_REG = "true" *)    logic     ff0_ctl_frm_timer_en,  ff1_ctl_frm_timer_en;
    
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            ff0_ctl_enable       <= 1'b0;
            ff1_ctl_enable       <= 1'b0;
            ff2_ctl_enable       <= 1'b0;
            
            ff0_ctl_update       <= 1'b0;
            ff1_ctl_update       <= 1'b0;
            
            ff0_ctl_skip         <= 1'b0;
            ff1_ctl_skip         <= 1'b0;
            
            ff0_ctl_frm_timer_en <= 1'b0;
            ff1_ctl_frm_timer_en <= 1'b0;
        end
        else begin
            ff0_ctl_enable       <= reg_ctl_control[0];
            ff1_ctl_enable       <= ff0_ctl_enable;
            ff2_ctl_enable       <= ff1_ctl_enable;

            ff0_ctl_update       <= reg_ctl_control[1];
            ff1_ctl_update       <= ff0_ctl_update;

            ff0_ctl_skip         <= reg_ctl_skip;
            ff1_ctl_skip         <= ff0_ctl_skip;
            
            ff0_ctl_frm_timer_en <= reg_ctl_frm_timer_en;
            ff1_ctl_frm_timer_en <= ff0_ctl_frm_timer_en;
        end
    end
    
    // core
    jelly3_video_format_regularizer_core
            #(
                .width_t            (width_t                ),
                .height_t           (height_t               ),
                .index_t            (index_t                ),
                .frame_timer_t      (frame_timer_t          ),
                .timer_t            (timer_t                ),
                .S_REGS             (S_REGS                 ),
                .M_REGS             (M_REGS                 )
            )
        u_video_format_regularizer_core
            (
                .aclken,

                .s_axi4s,
                .m_axi4s,

                .ctl_enable         (ff2_ctl_enable         ),
                .ctl_busy           (busy                   ),
                .ctl_update         (ff1_ctl_enable         ),
                .ctl_index          (index                  ),
                .ctl_skip           (ff1_ctl_skip           ),
                .ctl_frm_timer_en   (ff1_ctl_frm_timer_en   ),
                .ctl_frm_timeout    (reg_ctl_frm_timeout    ),

                .param_width        (reg_param_width        ),
                .param_height       (reg_param_height       ),
                .param_fill         (reg_param_fill         ),
                .param_timeout      (reg_param_timeout      ),

                .current_width      (out_param_width        ),
                .current_height     (out_param_height       )
            );
    
endmodule


`default_nettype wire


// end of file
