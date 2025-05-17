// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

module py300_control
        #(
            parameter   int             REGADR_BITS          = 8                        ,
            parameter   type            regadr_t             = logic [REGADR_BITS-1:0]  ,
  
            parameter                   CORE_ID              = 16'h527a                 ,
            parameter                   CORE_VERSION         = 32'h0100                 ,
            parameter   bit             INIT_ALIGN_RESET     = 1'b0                     ,
            parameter   bit [9:0]       INIT_ALIGN_PATTERN   = 10'h3a6                  ,
            parameter   bit             INIT_ISERDES_RESET   = 1'b0                     
//          parameter   bit [4:0]       INIT_ISERDES_BITSLIP = 5'b00000                 
        )
        (
            jelly3_axi4l_if.s           s_axi4l             ,

            output  var logic           out_iserdes_reset   ,
//          output  var logic   [4:0]   out_iserdes_bitslip ,
            output  var logic           out_align_reset     ,
            output  var logic   [9:0]   out_align_pattern   ,
            input   var logic           in_calib_done       ,
            input   var logic           in_calib_error      
        );
    
    
    // -------------------------------------
    //  registers domain
    // -------------------------------------

    // type
    localparam type axi4l_addr_t = logic [$bits(s_axi4l.awaddr)-1:0];
    localparam type axi4l_data_t = logic [$bits(s_axi4l.wdata)-1:0];
    localparam type axi4l_strb_t = logic [$bits(s_axi4l.wstrb)-1:0];

    // register address offset
    localparam  regadr_t REGADR_CORE_ID             = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION        = regadr_t'('h01);
    localparam  regadr_t REGADR_ISERDES_RESET       = regadr_t'('h10);
//  localparam  regadr_t REGADR_ISERDES_BITSLIP     = regadr_t'('h12);
    localparam  regadr_t REGADR_ALIGN_RESET         = regadr_t'('h20);
    localparam  regadr_t REGADR_ALIGN_PATTERN       = regadr_t'('h22);
    localparam  regadr_t REGADR_CALIB_STATUS        = regadr_t'('h28);
    
    // registers
    logic           reg_iserdes_reset   ;
//  logic   [4:0]   reg_iserdes_bitslip ;
    logic           reg_align_reset     ;
    logic   [9:0]   reg_align_pattern   ;
    logic   [1:0]   reg_calib_status    ;

    always_ff @(posedge s_axi4l.aclk) begin
        reg_calib_status <= {in_calib_error, in_calib_done};
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
            reg_iserdes_reset   <= INIT_ISERDES_RESET   ;
//          reg_iserdes_bitslip <= INIT_ISERDES_BITSLIP ;
            reg_align_reset     <= INIT_ALIGN_RESET     ;
            reg_align_pattern   <= INIT_ALIGN_PATTERN   ;
        end
        else begin
            // auto clear
//          reg_iserdes_bitslip <= '0;

            // write
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_ISERDES_RESET      :   reg_iserdes_reset   <=  1'(write_mask(axi4l_data_t'(reg_iserdes_reset  ), s_axi4l.wdata, s_axi4l.wstrb));
//              REGADR_ISERDES_BITSLIP    :   reg_iserdes_bitslip <=  5'(write_mask(axi4l_data_t'(reg_iserdes_bitslip), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_ALIGN_RESET        :   reg_align_reset     <=  1'(write_mask(axi4l_data_t'(reg_align_reset    ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_ALIGN_PATTERN      :   reg_align_pattern   <= 10'(write_mask(axi4l_data_t'(reg_align_pattern  ), s_axi4l.wdata, s_axi4l.wstrb));
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
            REGADR_CORE_ID          :   s_axi4l.rdata <= axi4l_data_t'(CORE_ID             );
            REGADR_CORE_VERSION     :   s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION        );
            REGADR_ISERDES_RESET    :   s_axi4l.rdata <= axi4l_data_t'(reg_iserdes_reset   );
//          REGADR_ISERDES_BITSLIP  :   s_axi4l.rdata <= axi4l_data_t'(reg_iserdes_bitslip );
            REGADR_ALIGN_RESET      :   s_axi4l.rdata <= axi4l_data_t'(reg_align_reset     );
            REGADR_ALIGN_PATTERN    :   s_axi4l.rdata <= axi4l_data_t'(reg_align_pattern   );
            REGADR_CALIB_STATUS     :   s_axi4l.rdata <= axi4l_data_t'(reg_calib_status    );
            default                 :   s_axi4l.rdata <= '0;
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
    assign  out_iserdes_reset   = reg_iserdes_reset  ;
//  assign  out_iserdes_bitslip = reg_iserdes_bitslip;
    assign  out_align_reset     = reg_align_reset    ;
    assign  out_align_pattern   = reg_align_pattern  ;

endmodule


`default_nettype wire


// end of file
