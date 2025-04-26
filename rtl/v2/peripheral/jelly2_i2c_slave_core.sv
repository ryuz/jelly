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

            output  var logic   [7:0]                   m_addr      ,
            output  var logic                           m_we        ,
            output  var logic   [7:0]                   m_wdata     ,
            input   var logic                           m_rdata     ,
            output  var logic                           m_valid     
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

        ff2_scl <= ff1_scl;
        ff2_sda <= ff1_sda;
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
        ACK   ,
        ADDR  ,
        WRITE ,
        READ  
    } state_t;

    logic  [3:0]   count;
    logic  [7:0]   data ;
    always_ff @ ( posedge clk ) begin
        if ( reset ) begin
            state       <= IDLE;
            m_addr      <= '0  ;
            m_we        <= 1'b0;
            m_wdata     <= '0  ;
            m_valid     <= 1'b0;
        end
        else begin
            if ( div_pulse ) begin
                if ( {ff2_scl, ff1_scl} == 2'b11 && {ff2_sda, ff1_sda} == 2'b10 ) begin
                    // START condition
                    state <= DEV    ;
                    count <= 4'd8   ;
                end
                if ( {ff2_scl, ff1_scl} == 2'b11 && {ff2_sda, ff1_sda} == 2'b01 ) begin
                    // STOP condition
                    state <= IDLE   ;
                end
                if ( {ff2_scl, ff1_scl} == 2'b01 ) begin
                    data <= {data[6:0], ff2_sda};
                    count <= count - 1;
                end
                if ( {ff2_scl, ff1_scl} == 2'b10 && count == 4'd0 ) begin
                end

            endcase
        end

    
endmodule


`default_nettype wire


// end of file
