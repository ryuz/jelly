// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// I2C
module jelly2_i2c_slave_core
        #(
            parameter  int  DIVIDER_WIDTH     = 8,
            parameter  bit  SIMULATION        = 0,
            parameter  bit  DEBUG             = 1
        )
        (
            input   var logic                           reset       ,
            input   var logic                           clk         ,
            
            input   var logic                           i2c_scl     ,
            input   var logic                           i2c_sda     ,
            output  var logic                           i2c_sda_t   ,

            input   var logic   [DIVIDER_WIDTH-1:0]     divider     ,
            input   var logic   [7:1]                   dev         ,

            output  var logic                           wr_start    ,
            output  var logic                           wr_en       ,
            output  var logic   [7:0]                   wr_data     ,
            output  var logic                           rd_start    ,
            output  var logic                           rd_req      ,
            input   var logic                           rd_en       ,
            input   var logic   [7:0]                   rd_data     
        );
    
    // -------------------------
    //  Clock divider
    // -------------------------
    
    logic                       div_pulse;
    logic   [DIVIDER_WIDTH-1:0] div_counter;
    always_ff @ ( posedge clk ) begin
        if ( reset ) begin
            div_pulse   <= 1'b0;
            div_counter <= 0;
        end
        else begin
            if ( div_counter == divider ) begin
                div_pulse   <= 1'b1;
                div_counter <= 0;
            end
            else begin
                div_pulse   <= 1'b0;
                div_counter <= div_counter + 1'b1;
            end
        end
    end
    
    
    // -------------------------
    //  I2C
    // -------------------------
    
    (* ASYNC_REG = "true" *)    logic   ff0_scl, ff1_scl;
    (* ASYNC_REG = "true" *)    logic   ff0_sda, ff1_sda;

    always_ff @ ( posedge clk ) begin
        ff0_scl <= i2c_scl;
        ff1_scl <= ff0_scl;
        ff0_sda <= i2c_sda;
        ff1_sda <= ff0_sda;
    end

    logic   ff2_scl;
    logic   ff2_sda;
    always_ff @ ( posedge clk ) begin
        if ( reset ) begin
            ff2_scl <= 1'b1;
            ff2_sda <= 1'b1;
        end
        else if ( div_pulse ) begin
            ff2_scl <= ff1_scl;
            ff2_sda <= ff1_sda;
        end
    end

    typedef enum {
        IDLE  ,
        DEV   ,
        WRITE ,
        READ  
    } state_t;

    state_t         state   ;
    logic   [3:0]   count   ;
    logic   [7:0]   rx_data ;
    logic   [8:0]   tx_data ;
    logic           ack     ;
    always_ff @ ( posedge clk ) begin
        if ( reset ) begin
            state    <= IDLE;
            count    <= 'x   ;
            rx_data  <= 'x   ;
            tx_data  <= '1   ;
            ack      <= 1'b0 ;
            wr_start <= 1'b0 ;
            wr_en    <= 1'b0 ;
            rd_start <= 1'b0 ;
            rd_req   <= 1'b0 ;
        end
        else begin
            wr_start <= 1'b0;
            wr_en    <= 1'b0;
            rd_start <= 1'b0;
            rd_req   <= 1'b0;
            if ( rd_en ) begin
                tx_data <= {1'b1, rd_data};
            end

            if ( div_pulse ) begin
                if ( {ff2_scl, ff1_scl} == 2'b11 && {ff2_sda, ff1_sda} == 2'b10 ) begin
                    // START condition
                    state <= DEV    ;
                    count <= 4'd0   ;
                end
                if ( {ff2_scl, ff1_scl} == 2'b11 && {ff2_sda, ff1_sda} == 2'b01 ) begin
                    // STOP condition
                    state <= IDLE   ;
                end
                if ( {ff2_scl, ff1_scl} == 2'b01 ) begin
                    rx_data <= {rx_data[6:0], ff2_sda};
                    count   <= count + 1;
                    if ( count >= 4'd8 ) begin
                        count <= '0;
                    end
                end

                if ( ack && {ff2_scl, ff1_scl} == 2'b10 ) begin
                    ack   <= 1'b0;
                end

                case ( state )
                DEV:
                    begin
                        if ( {ff2_scl, ff1_scl} == 2'b10 && count == 4'd8 ) begin
                            if ( rx_data[7:1] == dev ) begin
                                ack   <= 1'b1;
                                if ( rx_data[0] == 1'b0 ) begin
                                    state    <= WRITE;
                                    wr_start <= 1'b1;
                                end
                                else begin
                                    state    <= READ;
                                    rd_start <= 1'b1;
                                end
                            end
                            else begin
                                state <= IDLE;
                            end
                        end
                    end

                WRITE:
                    begin
                        if ( {ff2_scl, ff1_scl} == 2'b10 && count == 4'd8 ) begin
                            wr_en <= 1'b1;
                            ack   <= 1'b1;
                        end
                    end

                READ:
                    begin
                        if ( {ff2_scl, ff1_scl} == 2'b10 ) begin
                            tx_data <= {tx_data[7:0], 1'b1};
                        end
                        if ( {ff2_scl, ff1_scl} == 2'b01 && count == 4'd8 ) begin
                            if ( ff1_sda == 1'b0 ) begin
                                rd_req <= 1'b1; // ACK
                            end
                            else begin
                                state <= IDLE; // NAK
                            end
                        end
                    end
                default: ;
                endcase
            end
        end
    end

    always_ff @ ( posedge clk ) begin
        if ( reset ) begin
            i2c_sda_t <= 1'b1;
        end
        else begin
            i2c_sda_t <= 1'b1;
            if ( ack ) begin
                i2c_sda_t <= 1'b0;
            end
            else if ( state == READ ) begin
                i2c_sda_t <= tx_data[8];
            end
        end
    end

    assign wr_data = rx_data;

endmodule

`default_nettype wire

// end of file
