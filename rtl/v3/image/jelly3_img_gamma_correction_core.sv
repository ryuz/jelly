// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_gamma_correction_core
        #(
            parameter   int     S_DATA_BITS = 8                             ,
            parameter   type    s_data_t    = logic [S_DATA_BITS-1:0]       ,
            parameter   int     M_DATA_BITS = 8                             ,
            parameter   type    m_data_t    = logic [M_DATA_BITS-1:0]       ,
            parameter           RAM_TYPE    = "block"
        )
        (
            input   var logic       reset   ,
            input   var logic       clk     ,
            input   var logic       cke     ,

            input   var logic       enable  ,

            input   var logic       mem_clk ,
            input   var logic       mem_en  ,
            input   var s_data_t    mem_addr,
            input   var m_data_t    mem_din ,

            input   var s_data_t    s_data  ,

            output  var m_data_t    m_data  
        );

    // gamma table
    m_data_t mem_dout;
    jelly3_ram_simple_dualport
            #(
                .ADDR_BITS      (S_DATA_BITS),
                .addr_t         (s_data_t   ),
                .WE_BITS        (1          ),
                .we_t           (logic      ),
                .DATA_BITS      (M_DATA_BITS),
                .data_t         (m_data_t   ),
                .RAM_TYPE       (RAM_TYPE   ),
                .DOUT_REG       (1'b1       )
            )
        u_ram_simple_dualport
            (
                .wr_clk         (mem_clk     ),
                .wr_en          (mem_en      ),
                .wr_addr        (mem_addr    ),
                .wr_din         (mem_din     ),

                .rd_clk         (clk         ),
                .rd_en          (cke         ),
                .rd_regcke      (cke         ),
                .rd_addr        (s_data      ),
                .rd_dout        (mem_dout    )
            );

    s_data_t st0_data;
    s_data_t st1_data;
    m_data_t st2_data;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_data <= 'x;
            st1_data <= 'x;
            st2_data <= 'x;
        end
        else if ( cke ) begin
            st0_data <= s_data;
            st1_data <= st0_data;

            if ( enable ) begin
                st2_data <= mem_dout;
            end
            else begin
                if ( M_DATA_BITS > S_DATA_BITS ) begin
                    st2_data <= m_data_t'((st1_data << (M_DATA_BITS - S_DATA_BITS)) | (st1_data >> S_DATA_BITS));
                end
                else begin
                    st2_data <= m_data_t'(st1_data >> (S_DATA_BITS - M_DATA_BITS));
                end
            end
        end
    end

    assign m_data = st2_data;

endmodule


`default_nettype wire


// end of file
