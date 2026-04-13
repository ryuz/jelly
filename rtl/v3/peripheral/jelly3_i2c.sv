// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// I2C
module jelly3_i2c
        #(
            parameter   int         DIVIDER_BITS = 16                       ,
            parameter   type        divider_t    = logic [DIVIDER_BITS-1:0] ,
            parameter   divider_t   INIT_DIVIDER = 2000                     
        )
        (
            // I2C
            output  var logic                       i2c_scl_t,
            input   var logic                       i2c_scl_i,
            output  var logic                       i2c_sda_t,
            input   var logic                       i2c_sda_i,

            jelly3_axi4l_if.s                       s_axi4l  ,
            output  var logic                       irq      
        );

    // register address
    parameter   type        regadr_t = logic [2:0];

    localparam  regadr_t    REGADR_STATUS  = 3'b000;
    localparam  regadr_t    REGADR_CONTROL = 3'b001;
    localparam  regadr_t    REGADR_SEND    = 3'b010;
    localparam  regadr_t    REGADR_RECV    = 3'b011;
    localparam  regadr_t    REGADR_DIVIDER = 3'b100;

    localparam  int         CONTROL_START  = 0;
    localparam  int         CONTROL_STOP   = 1;
    localparam  int         CONTROL_ACK    = 2;
    localparam  int         CONTROL_NAK    = 3;
    localparam  int         CONTROL_RECV   = 4;

    localparam type axi4l_data_t = logic [s_axi4l.DATA_BITS-1:0];


    // -------------------------
    //   Core
    // -------------------------

    divider_t       divider;

    logic           cmd_start;
    logic           cmd_stop;
    logic           cmd_ack;
    logic           cmd_nak;
    logic           cmd_recv;
    logic           cmd_send;
    logic   [7:0]   recv_data;
    logic   [7:0]   send_data;
    logic           ack_status;
    logic           busy;

    jelly_i2c_core
            #(
                .DIVIDER_WIDTH      ($bits(divider_t))
            )
        u_i2c_core
            (
                .reset              (~s_axi4l.aresetn),
                .clk                (s_axi4l.aclk),

                .clk_dvider         (divider),

                .i2c_scl_t          (i2c_scl_t),
                .i2c_scl_i          (i2c_scl_i),
                .i2c_sda_t          (i2c_sda_t),
                .i2c_sda_i          (i2c_sda_i),

                .cmd_start          (cmd_start),
                .cmd_stop           (cmd_stop),
                .cmd_ack            (cmd_ack),
                .cmd_nak            (cmd_nak),
                .cmd_recv           (cmd_recv),
                .cmd_send           (cmd_send),
                .recv_data          (recv_data),
                .send_data          (send_data),
                .ack_status         (ack_status),

                .busy               (busy)
            );


    // -------------------------
    //  register
    // -------------------------

    function [s_axi4l.DATA_BITS-1:0] write_mask(
                                        input [s_axi4l.DATA_BITS-1:0] org   ,
                                        input [s_axi4l.DATA_BITS-1:0] data  ,
                                        input [s_axi4l.STRB_BITS-1:0] strb  
                                    );
        for ( int i = 0; i < s_axi4l.DATA_BITS; i++ ) begin
            write_mask[i] = strb[i/8] ? data[i] : org[i];
        end
    endfunction

    regadr_t  regadr_write;
    regadr_t  regadr_read;
    logic     write_fire;
    logic     write_control;

    assign regadr_write  = regadr_t'(s_axi4l.awaddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));
    assign regadr_read   = regadr_t'(s_axi4l.araddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));
    assign write_fire    = s_axi4l.aclken && s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready;
    assign write_control = write_fire && (regadr_write == REGADR_CONTROL) && s_axi4l.wstrb[0];

    // command
    assign cmd_start = write_control && s_axi4l.wdata[CONTROL_START];
    assign cmd_stop  = write_control && s_axi4l.wdata[CONTROL_STOP];
    assign cmd_ack   = write_control && s_axi4l.wdata[CONTROL_ACK];
    assign cmd_nak   = write_control && s_axi4l.wdata[CONTROL_NAK];
    assign cmd_recv  = write_control && s_axi4l.wdata[CONTROL_RECV];
    assign cmd_send  = write_fire && (regadr_write == REGADR_SEND) && s_axi4l.wstrb[0];
    assign send_data = s_axi4l.wdata[7:0];

    // write
    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            divider <= INIT_DIVIDER;
        end
        else if ( s_axi4l.aclken ) begin
            if ( write_fire ) begin
                case ( regadr_write )
                REGADR_DIVIDER : divider <= divider_t'(write_mask(axi4l_data_t'(divider), s_axi4l.wdata, s_axi4l.wstrb));
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

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid ;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;

    // read
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( s_axi4l.arvalid && s_axi4l.arready ) begin
            case ( regadr_read )
            REGADR_STATUS  : s_axi4l.rdata <= axi4l_data_t'({i2c_scl_i, i2c_sda_i, i2c_scl_t, i2c_sda_t, ack_status, 2'b00, busy});
            REGADR_RECV    : s_axi4l.rdata <= axi4l_data_t'(recv_data);
            REGADR_DIVIDER : s_axi4l.rdata <= axi4l_data_t'(divider);
            default:         s_axi4l.rdata <= '0;
            endcase
        end
    end

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

    // interrupt
    assign irq = ~busy;

endmodule

`default_nettype wire

// end of file