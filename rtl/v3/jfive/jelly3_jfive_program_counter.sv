// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// instruction_fetch
module jelly3_jfive_program_counter
        #(
            parameter   int                     THREADS     = 4                                 ,
            parameter   int                     ID_BITS     = THREADS > 1 ? $clog2(THREADS) : 1 ,
            parameter   type                    id_t        = logic [ID_BITS-1:0]               ,
            parameter   int                     PHASE_BITS  = 1                                 ,
            parameter   type                    phase_t     = logic         [PHASE_BITS-1:0]    ,
            parameter   int                     PC_BITS     = 32                                ,
            parameter   type                    pc_t        = logic [PC_BITS-1:0]               ,
            parameter   pc_t                    PC_MASK     = '0                                ,
            parameter   bit     [THREADS-1:0]   INIT_RUN    = 1                                 ,
            parameter   id_t                    INIT_ID     = '0                                ,
            parameter   pc_t    [THREADS-1:0]   INIT_PC     = '0                                ,
            parameter                           DEVICE      = "RTL"                             ,
            parameter                           SIMULATION  = "false"                           ,
            parameter                           DEBUG       = "false"                           
        )
        (
            input   var logic   reset           ,
            input   var logic   clk             ,
            input   var logic   cke             ,

            // wakeup
            input   var id_t    wakeup_id       ,
            input   var logic   wakeup_valid    ,

            // shutdown
            input   var id_t    shutdown_id     ,
            input   var logic   shutdown_valid  ,

            // branch
            input   var id_t    branch_id       ,
            input   var pc_t    branch_pc       ,
            input   var logic   branch_valid    ,

            // instruction fetch output
            output  var id_t    m_id            ,
            output  var phase_t m_phase         ,
            output  var pc_t    m_pc            ,
            output  var logic   m_valid         ,
            input   var logic   m_wait         
        );

    // -----------------------------
    //  Run control
    // -----------------------------

    logic   [THREADS-1:0]   run;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            run   <= INIT_RUN;
        end
        else if ( cke ) begin
            // run control
            for ( int i = 0; i < THREADS; i++ ) begin
                // shutdown
                if ( shutdown_valid && shutdown_id == id_t'(i) ) begin
                    run[i] <= 1'b0;
                end
                // wakeup
                if ( wakeup_valid && wakeup_id == id_t'(i) ) begin
                    run[i] <= 1'b1;
                end
            end
        end
    end


    // -----------------------------
    //  Stage 0
    // -----------------------------

    id_t                    st0_id;
    logic   [THREADS-1:0]   st0_phase;
    pc_t    [THREADS-1:0]   st0_pc;

    function automatic id_t next_id
            (
                input id_t                  id,
                input logic [THREADS-1:0]   run
            );
        for ( int i = 0; i < THREADS; i++ ) begin
            id++;
            if ( int'(id) >= THREADS ) begin
                id = '0;
            end
            if ( run[id] ) begin
                return id;
            end
        end
        return id;
    endfunction

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_id    <= '0;
            st0_phase <= '0;
            st0_pc    <= INIT_PC;
        end
        else if ( cke ) begin
            if ( !m_wait ) begin
                // run id
                st0_id  <= next_id(st0_id, run);

                // program counter
                for ( int i = 0; i < THREADS; i++ ) begin
                    if ( branch_valid && branch_id == id_t'(i) ) begin
                        st0_pc[i]    <= branch_pc;
                        st0_phase[i] <= ~st0_phase[i];
                    end
                    else if ( run[i] && st0_id == id_t'(i) ) begin
                        st0_pc[i] <= (PC_MASK & st0_pc[i]) | (~PC_MASK & (st0_pc[i] + pc_t'(4)));
                    end
                end
            end
        end
    end


    // -----------------------------
    //  Stage 1 (Memory Access) 
    // -----------------------------

    id_t    st1_id      ;
    logic   st1_phase   ;
    pc_t    st1_pc      ;
    logic   st1_valid   ;
    logic   st1_ready   ;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st1_id    <= 'x;
            st1_phase <= 'x;
            st1_pc    <= 'x;
            st1_valid <= 1'b0;
        end
        else if ( cke ) begin
            if ( !m_wait ) begin
                st1_id    <= st0_id;
                st1_phase <= st0_phase[st0_id];
                st1_pc    <= st0_pc[st0_id];
                st1_valid <= run[st0_id];
            end
        end
    end


    assign m_id    = st1_id;
    assign m_phase = st1_phase;
    assign m_pc    = st1_pc;
    assign m_valid = st1_valid;
    
endmodule


`default_nettype wire


// End of file
