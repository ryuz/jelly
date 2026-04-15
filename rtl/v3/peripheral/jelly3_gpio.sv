// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// GPIO
module jelly3_gpio
        #(
            parameter   int             N            = 2                        ,
            parameter   int             DATA_BITS    = 8                        ,
            parameter   type            data_t       = logic [DATA_BITS-1:0]    ,
            parameter   int             REGADR_BITS  = 8                        ,
            parameter   type            regadr_t     = logic [REGADR_BITS-1:0]  ,
            parameter   data_t  [N-1:0] INIT_OUTPUT  = '0                       ,
            parameter   data_t  [N-1:0] INIT_DIR     = '0                       
        )
        (
            input   var data_t  [N-1:0]     gpio_i  ,
            output  var data_t  [N-1:0]     gpio_o  ,
            output  var data_t  [N-1:0]     gpio_t  ,

            jelly3_axi4l_if.s               s_axi4l  
        );

    // register address
    localparam  regadr_t    REGADR_OUTPUT  = 0;
    localparam  regadr_t    REGADR_INPUT   = 1;
    localparam  regadr_t    REGADR_DIR     = 2;

    localparam type axi4l_addr_t = logic [s_axi4l.ADDR_BITS-1:0];
    localparam type axi4l_data_t = logic [s_axi4l.DATA_BITS-1:0];
    localparam type axi4l_strb_t = logic [s_axi4l.STRB_BITS-1:0];


    // -------------------------
    //  register
    // -------------------------

    // registers
    data_t  [N-1:0]     reg_output;
    data_t  [N-1:0]     reg_dir   ;
    
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
            reg_output <= INIT_OUTPUT ;
            reg_dir    <= INIT_DIR    ;

            s_axi4l.bvalid <= 1'b0  ;
            s_axi4l.rdata  <= 'x    ;
            s_axi4l.rvalid <= 1'b0  ;
        end
        else if ( s_axi4l.aclken ) begin
            // write
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                for ( int i = 0; i < N; i++ ) begin
                    if ( regadr_write == regadr_t'(i*4) + REGADR_OUTPUT ) begin
                        reg_output[i] <= data_t'(write_mask(axi4l_data_t'(reg_output[i]), s_axi4l.wdata, s_axi4l.wstrb));
                    end
                    if ( regadr_write == regadr_t'(i*4) + REGADR_DIR ) begin
                        reg_dir   [i] <= data_t'(write_mask(axi4l_data_t'(reg_dir   [i]), s_axi4l.wdata, s_axi4l.wstrb));
                    end
                end
                s_axi4l.bvalid <= 1'b1;
            end

            // read
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                s_axi4l.rdata <= '0;
                for ( int i = 0; i < N; i++ ) begin
                    if ( regadr_read == regadr_t'(i*4) + REGADR_INPUT) begin
                        s_axi4l.rdata <= axi4l_data_t'(gpio_i[i]);
                    end
                    if ( regadr_read == regadr_t'(i*4) + REGADR_OUTPUT) begin
                        s_axi4l.rdata <= axi4l_data_t'(reg_output[i]);
                    end
                    if ( regadr_read == regadr_t'(i*4) + REGADR_DIR) begin
                        s_axi4l.rdata <= axi4l_data_t'(reg_dir[i]);
                    end
                end
                s_axi4l.rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;
    assign s_axi4l.arready = ~s_axi4l.rvalid || s_axi4l.rready;
    assign s_axi4l.rresp   = '0;

    assign gpio_o = reg_output;
    assign gpio_t = ~reg_dir   ;


endmodule

`default_nettype wire

// end of file