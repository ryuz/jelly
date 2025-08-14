// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module timing_generator
        #(
            parameter                   CORE_ID          = 32'haaaa_1234                ,
            parameter                   CORE_VERSION     = 32'h0001_0000                ,
            parameter   int             TIMER_BITS       = 32                           ,
            parameter   type            timer_t          = logic [TIMER_BITS-1:0]       ,
            parameter   int             REGADR_BITS      = 8                            ,
            parameter   type            regadr_t         = logic [REGADR_BITS-1:0]      ,

            parameter   bit             INIT_CTL_CONTROL = 1'b0                         ,
            parameter   timer_t         INIT_PARAM_PERIOD      = 100000                 ,
            parameter   timer_t         INIT_PARAM_TRIG0_START =      1                 ,
            parameter   timer_t         INIT_PARAM_TRIG0_END   =  90000                 ,
            parameter   bit             INIT_PARAM_TRIG0_POL   =      0                 
        )
        (
            jelly3_axi4s_if.s                   s_axi4s,
            jelly3_axi4s_if.m                   m_axi4s,

            jelly3_axi4l_if.s                   s_axi4l,

            output  var logic                   out_trig0
        );
    
    // -------------------------------------
    //  localparam
    // -------------------------------------
    
    localparam type axi4l_data_t = logic [s_axi4l.DATA_BITS-1:0];


    // -------------------------------------
    //  registers
    // -------------------------------------
    
    // register address offset
    localparam  regadr_t REGADR_CORE_ID            = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION       = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_CONTROL        = regadr_t'('h04);
    localparam  regadr_t REGADR_CTL_STATUS         = regadr_t'('h05);
    localparam  regadr_t REGADR_CTL_TIMER          = regadr_t'('h08);
    localparam  regadr_t REGADR_PARAM_PERIOD       = regadr_t'('h10);
    localparam  regadr_t REGADR_PARAM_TRIG0_START  = regadr_t'('h20);
    localparam  regadr_t REGADR_PARAM_TRIG0_END    = regadr_t'('h21);
    localparam  regadr_t REGADR_PARAM_TRIG0_POL    = regadr_t'('h22);

    
    // registers
    logic           reg_busy                ;
    logic           reg_trig0               ;

    logic   [0:0]   reg_ctl_control         ;
    timer_t         reg_ctl_timer           ;
    timer_t         reg_param_period        ;
    timer_t         reg_param_trig0_start   ;
    timer_t         reg_param_trig0_end     ;
    logic           reg_param_trig0_pol     ;

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
            reg_busy              <= 1'b0                   ;
            reg_trig0             <= 1'b0                   ;
            reg_ctl_control       <= INIT_CTL_CONTROL       ;
            reg_ctl_timer         <= timer_t'(0)            ;
            reg_param_period      <= INIT_PARAM_PERIOD      ;
            reg_param_trig0_start <= INIT_PARAM_TRIG0_START ;
            reg_param_trig0_end   <= INIT_PARAM_TRIG0_END   ;
            reg_param_trig0_pol   <= INIT_PARAM_TRIG0_POL   ;
       end
        else begin
            // control
            if ( reg_busy ) begin
                reg_ctl_timer <= reg_ctl_timer + 1;
                if ( reg_ctl_timer + 1 == reg_param_period ) begin
                    reg_ctl_timer <= timer_t'(0);
                    reg_busy      <= reg_ctl_control[0];
                end
                if ( reg_ctl_timer == reg_param_trig0_start ) begin
                    reg_trig0 <= 1'b1;
                end
                if ( reg_ctl_timer == reg_param_trig0_end ) begin
                    reg_trig0 <= 1'b0;
                end
            end
            else begin
                reg_ctl_timer <= timer_t'(0);
                reg_busy      <= reg_ctl_control[0];
            end


            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_CTL_CONTROL      :   reg_ctl_control       <=       1'(write_mask(axi4l_data_t'(reg_ctl_control      ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_CTL_TIMER        :   reg_ctl_timer         <= timer_t'(write_mask(axi4l_data_t'(reg_ctl_timer        ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_PERIOD     :   reg_param_period      <= timer_t'(write_mask(axi4l_data_t'(reg_param_period     ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_TRIG0_START:   reg_param_trig0_start <= timer_t'(write_mask(axi4l_data_t'(reg_param_trig0_start), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_TRIG0_END  :   reg_param_trig0_end   <= timer_t'(write_mask(axi4l_data_t'(reg_param_trig0_end  ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_TRIG0_POL  :   reg_param_trig0_pol   <=       1'(write_mask(axi4l_data_t'(reg_param_trig0_pol  ), s_axi4l.wdata, s_axi4l.wstrb));
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
            REGADR_CTL_STATUS:         s_axi4l.rdata <= axi4l_data_t'(reg_busy            );
            REGADR_CTL_TIMER:          s_axi4l.rdata <= axi4l_data_t'(reg_ctl_timer       );
            REGADR_PARAM_PERIOD:       s_axi4l.rdata <= axi4l_data_t'(reg_param_period    );
            REGADR_PARAM_TRIG0_START:  s_axi4l.rdata <= axi4l_data_t'(reg_param_trig0_start);
            REGADR_PARAM_TRIG0_END:    s_axi4l.rdata <= axi4l_data_t'(reg_param_trig0_end  );
            REGADR_PARAM_TRIG0_POL:    s_axi4l.rdata <= axi4l_data_t'(reg_param_trig0_pol  );
            default:                   s_axi4l.rdata <= '0;
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
    

    // output
    assign out_trig0 = reg_trig0 ^ reg_param_trig0_pol;

    
endmodule


`default_nettype wire


// end of file
