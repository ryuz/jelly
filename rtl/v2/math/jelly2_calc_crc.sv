
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// CRC
module jelly2_calc_crc
        #(
            parameter   int                     DATA_WIDTH = 8,
            parameter   int                     CRC_WIDTH  = 32,
            parameter   bit     [CRC_WIDTH-1:0] POLY_REPS  = 32'h04C11DB7,  // Polynomial representations
            parameter   bit                     REVERSED   = 0
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            input   wire                        in_update,
            input   wire    [DATA_WIDTH-1:0]    in_data,
            input   wire                        in_valid,
            
            output  wire    [CRC_WIDTH-1:0]     out_crc
        );

    
    localparam TABLE_SIZE = (1 << DATA_WIDTH);

    bit     [CRC_WIDTH-1:0]     reps;
    bit     [CRC_WIDTH-1:0]     crc_table[0:TABLE_SIZE-1];

    always_comb begin
        if ( !REVERSED ) begin
            for ( int i = 0; i < CRC_WIDTH; ++i ) begin
                reps[i] = POLY_REPS[CRC_WIDTH-1 - i];
            end
        end
        else begin
            reps = POLY_REPS;
        end

        for ( int i = 0; i < TABLE_SIZE; ++i ) begin
            automatic bit   [CRC_WIDTH-1:0]   c;
            c = CRC_WIDTH'(i);
            for ( int j = 0; j < DATA_WIDTH; ++j ) begin
                c = c[0] ? (reps ^ (c >> 1)) : (c >> 1);
            end
            crc_table[i] = c;
        end
    end

    reg     [CRC_WIDTH-1:0]     reg_crc;
    reg     [CRC_WIDTH-1:0]     tmp_crc;
    reg     [DATA_WIDTH-1:0]    tmp_index;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_crc <= {CRC_WIDTH{1'b1}};
        end
        else if ( cke ) begin
            if ( in_valid ) begin
                tmp_crc    = in_update ? reg_crc : {CRC_WIDTH{1'b1}};
                tmp_index  = DATA_WIDTH'(tmp_crc) ^ in_data;
                reg_crc   <= crc_table[tmp_index] ^ (tmp_crc >> DATA_WIDTH);
            end
        end
    end
    
    assign out_crc = ~reg_crc;
    
endmodule


`default_nettype wire


// end of file
