
`timescale 1ns / 1ps
`default_nettype none

module python_spi
        (
            input   var logic           reset       ,
            input   var logic           clk         ,

            input   var logic   [8:0]   s_addr      ,
            input   var logic           s_we        ,
            input   var logic   [15:0]  s_wdata     ,
            input   var logic           s_valid     ,
            output  var logic           s_ready     ,

            output  var logic   [15:0]  m_rdata     ,
            output  var logic           m_rvalid    ,

            output  var logic           spi_ss_n    ,
            output  var logic           spi_sck     ,
            output  var logic           spi_mosi    ,
            input   var logic           spi_miso    
        );
    
    // 分周
    logic   [2:0]   clk_div;
    logic           clk_puls;
    always_ff @(posedge clk ) begin
        if (reset) begin
            clk_div  <= '1;
            clk_puls <= 1'b0;
        end
        else begin
            clk_div  <= clk_div - 1'b1;
            clk_puls <= clk_div == '0;
        end
    end

    typedef enum {
        IDLE    ,
        START   ,
        SEND    ,
        STOP0   ,
        STOP1   ,
        END0    ,
        END1    
    } state_t;

    logic                   busy    ;
    state_t                 state   ;
    logic                   phase   ;
    logic    [5:0]          count   ;
    logic    [9+1+16-1:0]   data    ;
    always_ff @(posedge clk) begin
        if (reset) begin
            busy     <= 1'b0    ;
            state    <= IDLE    ;
            count    <= 'x      ;
            data     <= '0      ;
            m_rvalid <= '0      ;
            spi_ss_n <= 1'b1    ;
            spi_sck  <= 1'b0    ;
            spi_mosi <= 1'b0    ;
        end
        else begin
            m_rvalid <= 1'b0;

            if (s_valid && s_ready) begin
                busy     <= 1'b1    ;
                state    <= IDLE    ;
                count    <= '0      ;
                data     <= {s_addr, s_we, s_wdata};
                spi_ss_n <= 1'b1    ;
                spi_sck  <= 1'b0    ;
                spi_mosi <= 1'b0    ;
            end
            else if ( busy && clk_puls ) begin
                phase    <= ~phase  ;
                case ( state )
                IDLE:
                    begin
                        state    <= START   ;
                        spi_ss_n <= 1'b0    ;
                        spi_sck  <= 1'b0    ;
                    end

                START:
                    begin
                        state    <= SEND        ;
                        count    <= '0          ;
                        spi_ss_n <= 1'b0        ;
                        spi_sck  <= 1'b0        ;
                        {spi_mosi, data} <= {data, spi_miso};
                    end

                SEND:
                    begin
                        spi_sck <= ~spi_sck;
                        if ( spi_sck ) begin
                            count            <= count + 1'b1;   ;
                            {spi_mosi, data} <= {data, spi_miso};
                            if ( count == 6'd25 ) begin
                                state    <= STOP0;
                                spi_mosi <= 1'b0;
                                m_rvalid <= 1'b1;
                            end
                        end
                    end

                STOP0:
                    begin
                        state <= STOP1;
                    end

                STOP1:
                    begin
                        state    <= END0;
                        spi_ss_n <= 1'b1;
                    end

                END0:
                    begin
                        state    <= END1;
                    end

                END1:
                    begin
                        busy    <= 1'b0;
                        state   <= IDLE;
                    end
                endcase
            end
        end
    end

//  assign spi_mosi = send[$bits(send)-1];
    assign m_rdata = data[15:0];
    assign s_ready = !busy;

endmodule

`default_nettype wire

// end of file
