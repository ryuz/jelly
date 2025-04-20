
`timescale 1ns / 1ps
`default_nettype none

module spi_cmd
        (
            input   var logic           reset       ,
            input   var logic           clk         ,

            input   var logic           enable      ,

            output  var logic   [8:0]   m_spi_addr  ,
            output  var logic           m_spi_we    ,
            output  var logic   [15:0]  m_spi_wdata ,
            output  var logic           m_spi_valid ,
            input   var logic           m_spi_ready 
        );
    

    logic   [7:0]   tbl_addr  ;
    logic   [1:0]   tbl_type  ;
    logic   [25:0]  tbl_data  ;
    
    spi_tbl
        u_spi_tbl
            (
                .addr   (tbl_addr               ),
                .dout   ({tbl_type, tbl_data}   )
            );

    typedef enum {
        IDLE    ,
        CMD     ,
        WAIT    
    } state_t;

    state_t         state       ;
    logic   [25:0]  cmd_data    ;
    always_ff @(posedge clk) begin
        if (reset) begin
            state       <= IDLE;
            tbl_addr    <= '0  ;
            cmd_data    <= 'x  ;
            m_spi_valid <= 1'b0;
        end
        else begin
            if ( m_spi_ready ) begin
                m_spi_valid <= 1'b0;
            end

            case (state)
                IDLE: begin
                    if (enable) begin
                        state <= CMD;
                        case ( tbl_type )
                            2'b00: begin
                                state       <= CMD;
                                tbl_addr    <= tbl_addr + 1;
                                cmd_data    <= tbl_data;
                                m_spi_valid <= 1'b1;
                            end
                            
                            2'b01: begin
                                state       <= WAIT;
                                tbl_addr    <= tbl_addr + 1;
                                cmd_data    <= tbl_data;
                                m_spi_valid <= 1'b0;
                            end

                            default: begin
                            end
                        endcase
                    end
                end

                CMD: begin
                    if ( m_spi_valid && m_spi_ready ) begin
                        state <= IDLE;
                    end
                end

                WAIT: begin
                    cmd_data <= cmd_data - 1;
                    if ( cmd_data == 0 ) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    assign {m_spi_addr, m_spi_we, m_spi_wdata} = cmd_data;

endmodule

`default_nettype wire

// end of file
