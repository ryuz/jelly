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
            parameter   int                     ADDR_BITS   = 32                                ,
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
            input   var logic   branch_en       ,
            input   var id_t    branch_id       ,
            input   var pc_t    branch_pc       ,

            // memory port
            output  var addr_t  mem_araddr      ,
            output  var logic   mem_arvalid     ,
            input   var logic   mem_arready     ,
            input   var data_t  mem_rdata       ,
            input   var logic   mem_rvalid      ,
            output  var logic   mem_rready      ,

            // instruction fetch output
            output  var id_t    if_id           ,
            output  var pc_t    if_pc           ,
            output  var data_t  if_inst         ,
            output  var logic   if_valid        ,
            input   var logic   if_ready        
        );



    // -----------------------------
    //  Stage 0                     
    // -----------------------------


    logic   [THREADS-1:0]   st0_run     ;
    logic   [THREADS-1:0]   st0_slot,   st0_slot_next   ;
    id_t                    st0_id,     st0_id_next     ;
    pc_t    [THREADS-1:0]   st0_pc      ;
    logic                   st0_valid   ;
    logic                   st0_ready   ;

    always_comb begin
        st0_slot_next = st0_slot;
        st0_id_next   = 'x;
        for ( int i = 0; i < THREADS-1; i++ ) begin
            st0_slot_next = (st0_slot_next << 1) | (st0_slot_next >> (THREADS-1));
            if ( (st0_slot_next & st0_run) != '0 ) begin
                break;
            end
        end

        for ( int i = 0; i < THREADS; i++ ) begin
            if ( st0_slot_next[i] ) begin
                st0_id_next = id_t'(i);
                break;
            end
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_run  <= INIT_RUN;
            st0_slot <= 1;
            st0_pc   <= INIT_PC;
        end
        else if ( cke ) begin
            if ( st0_ready ) begin
                // run control
                for ( int i = 0; i < THREADS; i++ ) begin
                    // shutdown
                    if ( shutdown_valid && shutdown_id == id_t'(i) ) begin
                        st0_run[i] <= 1'b0;
                    end
                    // wakeup
                    if ( wakeup_valid && wakeup_id == id_t'(i) ) begin
                        st0_run[i] <= 1'b1;
                    end
                end

                // run slot
                st0_slot <= st0_slot_next;

                // run id
                st0_id   <= st0_id_next;

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

    assign st0_valid = st0_run[st0_id];


    // -----------------------------
    //  Stage 1                     
    // -----------------------------

    id_t    st1_id      ;
    pc_t    st1_pc      ;
    logic   st1_valid   ;
    logic   st1_ready   ;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st1_id      <= 'x;
            st1_pc      <= 'x;
            st1_valid   <= 1'b0;
            mem_araddr  <= 'x;
            mem_arvalid <= 1'b0;
        end
        else if ( cke ) begin
            if ( st1_ready || !st1_valid ) begin
                st1_id    <= st0_id;
                st1_pc    <= st0_pc[st0_id];
                st1_valid <= st0_valid;

                // ブランチで無効化する
                if ( branch_en && branch_id == st0_id ) begin
                    st1_valid <= 1'b0;
                end

                // memory access
                if ( mem_arready ) begin
                    mem_arvalid <= 1'b0;
                end
                if ( st1_valid && st1_ready ) begin
                    mem_araddr  <= addr_t'(st1_pc);
                    mem_arvalid <= 1'b1;
                end
            end
        end
    end

//    assign mem_araddr  = addr_t'(st1_pc);
//    assign mem_arvalid = st1_valid && st1_ready;
    
    assign st0_ready = (st1_ready || !st1_valid) && (mem_arready || !mem_arvalid);


    // -----------------------------
    //  Stage 2
    // -----------------------------

    id_t         st2_delay_id    [MEM_LATENCY:0];
    pc_t         st2_delay_pc    [MEM_LATENCY:0];
    logic        st2_delay_mem   [MEM_LATENCY:0];
    logic        st2_delay_valid [MEM_LATENCY:0];
    logic        st2_delay_ready [MEM_LATENCY:0];
    
    assign st2_delay_id   [0] = st1_id;
    assign st2_delay_pc   [0] = st1_pc;
    assign st2_delay_mem  [0] = mem_arvalid && mem_arready;
    assign st2_delay_valid[0] = st1_valid;

    assign st1_ready          = st2_delay_ready[0];

    for ( genvar i = 1; i <= MEM_LATENCY; i++ ) begin : st2_delay
        jelly3_instruction_fetch_delay
                #(
                    .ID_BITS    (ID_BITS    ),
                    .id_t       (id_t       ),
                    .PC_BITS    (PC_BITS    ),
                    .pc_t       (pc_t       )
                )
            u_instruction_fetch_delay
                (
                    .reset      ,
                    .clk        ,
                    .cke        ,

                    .branch_en  ,
                    .branch_id  ,
                    .branch_pc  ,

                    .s_id       (st2_delay_id   [i]     ),
                    .s_pc       (st2_delay_pc   [i]     ),
                    .s_mem      (st2_delay_mem  [i]     ),
                    .s_valid    (st2_delay_valid[i]     ),
                    .s_ready    (st2_delay_ready[i]     ),

                    .m_id       (st2_delay_id   [i+1]   ),
                    .m_pc       (st2_delay_pc   [i+1]   ),
                    .m_mem      (st2_delay_mem  [i+1]   ),
                    .m_valid    (st2_delay_valid[i+1]   ),
                    .m_ready    (st2_delay_ready[i+1]   )
                );
    end

    id_t    st2_id      ;
    pc_t    st2_pc      ;
    logic   st2_mem     ;
    logic   st2_valid   ;
    logic   st2_ready   ;

    assign st2_id    = st2_delay_id   [MEM_LATENCY];
    assign st2_pc    = st2_delay_pc   [MEM_LATENCY];
    assign st2_mem   = st2_delay_mem  [MEM_LATENCY];
    assign st2_valid = st2_delay_valid[MEM_LATENCY];
    assign st2_delay_ready[MEM_LATENCY] = st2_ready;


    // -----------------------------
    //  Stage 3
    // -----------------------------

    assign mem_rready = st2_mem && if_ready;

    assign if_id     = st2_id;
    assign if_pc     = st2_pc;
    assign if_inst   = mem_rdata;
    assign if_valid  = mem_rvalid && st2_valid;

    assign st2_ready = (st2_mem != mem_rvalid) && (if_ready || !st2_valid);
    
endmodule


`default_nettype wire


// End of file
