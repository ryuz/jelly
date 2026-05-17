// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_system_control
        #(
            parameter   int             DATA_BITS         = 32                      ,
            parameter   type            data_t            = logic [DATA_BITS-1:0]   ,
            parameter                   CORE_ID           = 32'h527a_0001           ,
            parameter                   CORE_VERSION      = 32'h0003_0001           ,
            parameter   data_t          CONFIG0           = '0                      ,
            parameter   data_t          CONFIG1           = '0                      ,
            parameter   data_t          CONFIG2           = '0                      ,
            parameter   data_t          CONFIG3           = '0                      ,
            parameter   data_t          CONFIG4           = '0                      ,
            parameter   data_t          CONFIG5           = '0                      ,
            parameter   data_t          CONFIG6           = '0                      ,
            parameter   data_t          CONFIG7           = '0                      ,
            parameter   data_t          INIT_CONTROL0     = '0                      ,
            parameter   data_t          INIT_CONTROL1     = '0                      ,
            parameter   data_t          INIT_CONTROL2     = '0                      ,
            parameter   data_t          INIT_CONTROL3     = '0                      ,
            parameter   data_t          INIT_CONTROL4     = '0                      ,
            parameter   data_t          INIT_CONTROL5     = '0                      ,
            parameter   data_t          INIT_CONTROL6     = '0                      ,
            parameter   data_t          INIT_CONTROL7     = '0                      
        )
        (
            jelly3_axi4l_if.s                   s_axi4l        ,

            output  var data_t  control0    ,
            output  var data_t  control1    ,
            output  var data_t  control2    ,
            output  var data_t  control3    ,
            output  var data_t  control4    ,
            output  var data_t  control5    ,
            output  var data_t  control6    ,
            output  var data_t  control7    ,

            input   var data_t  monitor0    ,
            input   var data_t  monitor1    ,
            input   var data_t  monitor2    ,
            input   var data_t  monitor3    ,
            input   var data_t  monitor4    ,
            input   var data_t  monitor5    ,
            input   var data_t  monitor6    ,
            input   var data_t  monitor7    
        );


    localparam  int             REGADR_BITS       = 8                           ;
    localparam  type            regadr_t          = logic [REGADR_BITS-1:0]     ;


    // -------------------------------------
    //  Registers
    // -------------------------------------

    // AXI4L types
    localparam int  AXI4L_ADDR_BITS = s_axi4l.ADDR_BITS;
    localparam int  AXI4L_DATA_BITS = s_axi4l.DATA_BITS;
    localparam int  AXI4L_STRB_BITS = s_axi4l.STRB_BITS;
    localparam type axi4l_addr_t = logic [AXI4L_ADDR_BITS-1:0];
    localparam type axi4l_data_t = logic [AXI4L_DATA_BITS-1:0];
    localparam type axi4l_strb_t = logic [AXI4L_STRB_BITS-1:0];

    // register address offset
    localparam  regadr_t REGADR_CORE_ID          = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION     = regadr_t'('h01);
    localparam  regadr_t REGADR_CONFIG0          = regadr_t'('h08);
    localparam  regadr_t REGADR_CONFIG1          = regadr_t'('h09);
    localparam  regadr_t REGADR_CONFIG2          = regadr_t'('h0a);
    localparam  regadr_t REGADR_CONFIG3          = regadr_t'('h0b);
    localparam  regadr_t REGADR_CONFIG4          = regadr_t'('h0c);
    localparam  regadr_t REGADR_CONFIG5          = regadr_t'('h0d);
    localparam  regadr_t REGADR_CONFIG6          = regadr_t'('h0e);
    localparam  regadr_t REGADR_CONFIG7          = regadr_t'('h0f);
    localparam  regadr_t REGADR_CONTROL0         = regadr_t'('h10);
    localparam  regadr_t REGADR_CONTROL1         = regadr_t'('h11);
    localparam  regadr_t REGADR_CONTROL2         = regadr_t'('h12);
    localparam  regadr_t REGADR_CONTROL3         = regadr_t'('h13);
    localparam  regadr_t REGADR_CONTROL4         = regadr_t'('h14);
    localparam  regadr_t REGADR_CONTROL5         = regadr_t'('h15);
    localparam  regadr_t REGADR_CONTROL6         = regadr_t'('h16);
    localparam  regadr_t REGADR_CONTROL7         = regadr_t'('h17);
    localparam  regadr_t REGADR_MONITOR0         = regadr_t'('h18);
    localparam  regadr_t REGADR_MONITOR1         = regadr_t'('h19);
    localparam  regadr_t REGADR_MONITOR2         = regadr_t'('h1a);
    localparam  regadr_t REGADR_MONITOR3         = regadr_t'('h1b);
    localparam  regadr_t REGADR_MONITOR4         = regadr_t'('h1c);
    localparam  regadr_t REGADR_MONITOR5         = regadr_t'('h1d);
    localparam  regadr_t REGADR_MONITOR6         = regadr_t'('h1e);
    localparam  regadr_t REGADR_MONITOR7         = regadr_t'('h1f);

    // registers

    // write mask
    function [AXI4L_DATA_BITS-1:0] write_mask(
                                        input axi4l_data_t org,
                                        input axi4l_data_t data,
                                        input axi4l_strb_t strb
                                    );
        for ( int i = 0; i < AXI4L_DATA_BITS; i++ ) begin
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
            control0 <= INIT_CONTROL0   ;
            control1 <= INIT_CONTROL1   ;
            control2 <= INIT_CONTROL2   ;
            control3 <= INIT_CONTROL3   ;
            control4 <= INIT_CONTROL4   ;
            control5 <= INIT_CONTROL5   ;
            control6 <= INIT_CONTROL6   ;
            control7 <= INIT_CONTROL7   ;

            s_axi4l.bvalid <= 1'b0      ;
            s_axi4l.rdata  <= 'x        ;
            s_axi4l.rvalid <= 1'b0      ;
        end
        else if ( s_axi4l.aclken ) begin
            // write
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 1'b0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_CONTROL0 : control0 <= data_t'( write_mask(axi4l_data_t'(control0), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_CONTROL1 : control1 <= data_t'( write_mask(axi4l_data_t'(control1), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_CONTROL2 : control2 <= data_t'( write_mask(axi4l_data_t'(control2), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_CONTROL3 : control3 <= data_t'( write_mask(axi4l_data_t'(control3), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_CONTROL4 : control4 <= data_t'( write_mask(axi4l_data_t'(control4), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_CONTROL5 : control5 <= data_t'( write_mask(axi4l_data_t'(control5), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_CONTROL6 : control6 <= data_t'( write_mask(axi4l_data_t'(control6), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_CONTROL7 : control7 <= data_t'( write_mask(axi4l_data_t'(control7), s_axi4l.wdata, s_axi4l.wstrb));
                default: ;
                endcase
                s_axi4l.bvalid <= 1'b1;
            end

            // read
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                s_axi4l.rdata <= '0;
                case ( regadr_read )
                REGADR_CORE_ID       :  s_axi4l.rdata <= axi4l_data_t'(CORE_ID      );
                REGADR_CORE_VERSION  :  s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION );
                REGADR_CONFIG0       :  s_axi4l.rdata <= axi4l_data_t'(CONFIG0      );
                REGADR_CONFIG1       :  s_axi4l.rdata <= axi4l_data_t'(CONFIG1      );
                REGADR_CONFIG2       :  s_axi4l.rdata <= axi4l_data_t'(CONFIG2      );
                REGADR_CONFIG3       :  s_axi4l.rdata <= axi4l_data_t'(CONFIG3      );
                REGADR_CONFIG4       :  s_axi4l.rdata <= axi4l_data_t'(CONFIG4      );
                REGADR_CONFIG5       :  s_axi4l.rdata <= axi4l_data_t'(CONFIG5      );
                REGADR_CONFIG6       :  s_axi4l.rdata <= axi4l_data_t'(CONFIG6      );
                REGADR_CONFIG7       :  s_axi4l.rdata <= axi4l_data_t'(CONFIG7      );
                REGADR_CONTROL0      :  s_axi4l.rdata <= axi4l_data_t'(control0     );
                REGADR_CONTROL1      :  s_axi4l.rdata <= axi4l_data_t'(control1     );
                REGADR_CONTROL2      :  s_axi4l.rdata <= axi4l_data_t'(control2     );
                REGADR_CONTROL3      :  s_axi4l.rdata <= axi4l_data_t'(control3     );
                REGADR_CONTROL4      :  s_axi4l.rdata <= axi4l_data_t'(control4     );
                REGADR_CONTROL5      :  s_axi4l.rdata <= axi4l_data_t'(control5     );
                REGADR_CONTROL6      :  s_axi4l.rdata <= axi4l_data_t'(control6     );
                REGADR_CONTROL7      :  s_axi4l.rdata <= axi4l_data_t'(control7     );
                REGADR_MONITOR0      :  s_axi4l.rdata <= axi4l_data_t'(monitor0     );
                REGADR_MONITOR1      :  s_axi4l.rdata <= axi4l_data_t'(monitor1     );
                REGADR_MONITOR2      :  s_axi4l.rdata <= axi4l_data_t'(monitor2     );
                REGADR_MONITOR3      :  s_axi4l.rdata <= axi4l_data_t'(monitor3     );
                REGADR_MONITOR4      :  s_axi4l.rdata <= axi4l_data_t'(monitor4     );
                REGADR_MONITOR5      :  s_axi4l.rdata <= axi4l_data_t'(monitor5     );
                REGADR_MONITOR6      :  s_axi4l.rdata <= axi4l_data_t'(monitor6     );
                REGADR_MONITOR7      :  s_axi4l.rdata <= axi4l_data_t'(monitor7     );
                default              :  s_axi4l.rdata <= '0;
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

endmodule

`default_nettype wire


// end of file
