// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// instruction_fetch
module jelly3_instruction_fetch
        #(
            parameter   int                     THREADS     = 4                                 ,
            parameter   int                     ID_BITS     = THREADS > 1 ? $clog2(THREADS) : 1 ,
            parameter   type                    id_t        = logic [ID_BITS-1:0]               ,
            parameter   int                     ADDR_BITS   = 10                                ,
            parameter   type                    addr_t      = logic [ADDR_BITS-1:0]             ,
            parameter   int                     DATA_BITS   = 32                                ,
            parameter   type                    data_t      = logic [DATA_BITS-1:0]             ,
            parameter   int                     PC_BITS     = ADDR_BITS                         ,
            parameter   type                    pc_t        = logic [PC_BITS-1:0]               ,
            parameter   int                     MEM_LATENCY = 2                                 ,
            parameter                           DEVICE      = "RTL"                             ,
            parameter   bit                     SIMULATION  = 1'b0                              ,
            parameter   bit     [THREADS-1:0]   INIT_RUN    = 1                                 ,
            parameter   id_t                    INIT_ID     = '0                                ,
            parameter   pc_t    [THREADS-1:0]   INIT_PC     = '0                                
        )
        (
            input   var logic   reset       ,
            input   var logic   clk         ,
            input   var logic   cke         ,

            // wakeup
            input   var logic   wakeup_en   ,
            input   var id_t    wakeup_id   ,

            // shutdown
            input   var logic   shutdown_en ,
            input   var id_t    shutdown_id ,

            // branch
            input   var logic   branch_en   ,
            input   var id_t    branch_id   ,
            input   var pc_t    branch_pc   ,

            // memory port
            output  var addr_t  ardddr      ,
            output  var logic   arvalid     ,
            input   var logic   arready     ,
            input   var data_t  rdata       ,
            input   var logic   rvalid      ,
            output  var logic   rready      ,

            // instruction output
            output  var pc_t    out_pc      ,
            output  var data_t  out_data    ,
            output  var logic   out_valid   
        );

    // interlock
    logic interlock;
    assign interlock = !arready;

    // -----------------------------
    //  Stage 0                     
    // -----------------------------

    logic   [THREADS-1:0]   st0_run;
    logic   [THREADS-1:0]   st0_slot;
    pc_t    [THREADS-1:0]   st0_pc;

    function automatic logic [THREADS-1:0] next_slot (logic [THREADS-1:0] slot, logic [THREADS-1:0] run);
        for ( int i = 0; i < THREADS-1; i++ ) begin
            slot = (slot << 1) | (slot >> (THREADS-1));
            if ( (slot & run) != '0 ) begin
                return slot;
            end
        end
        return slot;
    endfunction

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_run  <= INIT_RUN;
            st0_slot <= 1;
            st0_pc   <= INIT_PC;
        end
        else if ( cke ) begin
            if ( !interlock ) begin
                // run control
                for ( int i = 0; i < THREADS; i++ ) begin
                    // shutdown
                    if ( shutdown_en && shutdown_id == id_t'(i) ) begin
                        st0_run[i] <= 1'b0;
                    end
                    // wakeup
                    if ( wakeup_en && wakeup_id == id_t'(i) ) begin
                        st0_run[i] <= 1'b1;
                    end
                end

                // run slot
                st0_slot <= next_slot(st0_slot,st0_run);

                // program counter
                for ( int i = 0; i < THREADS; i++ ) begin
                    if ( branch_en && branch_id == id_t'(i) ) begin
                        st0_pc[i] <= branch_pc;
                    end
                    else if ( st0_run[i] && st0_slot[i] ) begin
                        st0_pc[i] <= st0_pc[i] + 1;
                    end
                end
            end
        end
    end

    // -----------------------------
    //  Stage 0                     
    // -----------------------------


endmodule


`default_nettype wire


// End of file
