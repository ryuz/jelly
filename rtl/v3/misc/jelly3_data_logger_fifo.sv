// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_data_logger_fifo
        #(
            parameter   int         NUM              = 4                            ,
            parameter   int         DATA_BITS        = 32                           ,
            parameter   type        data_t           = logic [DATA_BITS-1:0]        ,
            parameter   int         TIMER_BITS       = 64                           ,
            parameter   type        timer_t          = logic [TIMER_BITS-1:0]       ,
            parameter   bit         FIFO_ASYNC       = 1                            ,
            parameter   int         FIFO_PTR_BITS    = 10                           ,
//          parameter   type        fifo_ptr_t       = logic [FIFO_PTR_BITS-1:0]    ,
            parameter   type        fifo_size_t      = logic [FIFO_PTR_BITS:0]      ,
            parameter               FIFO_RAM_TYPE    = "block"                      ,
            parameter   int         REGADR_BITS      = 8                            ,
            parameter   type        regadr_t         = logic [REGADR_BITS-1:0]      ,
            parameter   int         CORE_ID          = 32'h527a_f002                ,
            parameter   int         CORE_VERSION     = 32'h0001_0000                ,
            parameter   bit [1:0]   INIT_CTL_CONTROL = 2'b00                        ,
            parameter   fifo_size_t INIT_LIMIT_SIZE  = 0                            
        )
        (
            input   var logic               reset   ,
            input   var logic               clk     ,
            input   var logic               cke     ,
            
            input   var data_t  [NUM-1:0]   s_data  ,
            input   var logic               s_valid ,
            output  var logic               s_ready ,

            jelly3_axi4l_if.s               s_axi4l  
        );
    
    
    
    // -------------------------------------
    //  FIFO
    // -------------------------------------
    
    timer_t             fifo_s_timer        ;
    
    timer_t             fifo_m_timer        ;
    data_t  [NUM-1:0]   fifo_m_data         ;
    logic               fifo_m_valid        ;
    logic               fifo_m_ready        ;
    fifo_size_t         fifo_m_data_count   ;

    typedef struct packed {
        timer_t             timer   ;
        data_t  [NUM-1:0]   data    ;
    } logging_t;


    logging_t   fifo_s_pack;
    logging_t   fifo_m_pack;
    
    assign fifo_s_pack.timer = fifo_s_timer ;
    assign fifo_s_pack.data  = s_data       ;
    assign fifo_m_timer = fifo_m_pack.timer;
    assign fifo_m_data  = fifo_m_pack.data ;
    
    jelly2_fifo_generic_fwtf
            #(
                .ASYNC          (FIFO_ASYNC         ),
                .DATA_WIDTH     ($bits(logging_t)   ),
                .PTR_WIDTH      (FIFO_PTR_BITS      ),
                .DOUT_REGS      (1                  ),
                .RAM_TYPE       (FIFO_RAM_TYPE      ),
                .LOW_DEALY      (0                  ),
                .S_REGS         (1                  ),
                .M_REGS         (1                  )
            )
        u_fifo_generic_fwtf
            (
                .s_reset        (reset              ),
                .s_clk          (clk                ),
                .s_cke          (cke                ),
                .s_data         (fifo_s_pack        ),
                .s_valid        (s_valid            ),
                .s_ready        (s_ready            ),
                .s_free_count   (                   ),
                
                .m_reset        (~s_axi4l.aresetn   ),
                .m_clk          (s_axi4l.aclk       ),
                .m_cke          (s_axi4l.aclken     ),
                .m_data         (fifo_m_pack        ),
                .m_valid        (fifo_m_valid       ),
                .m_ready        (fifo_m_ready       ),
                .m_data_count   (fifo_m_data_count  )
            );
    

    
    // -------------------------------------
    //  Timer
    // -------------------------------------
    
    timer_t     reg_timer;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_timer <= 0;
        end
        else begin
            reg_timer <= reg_timer + 1'b1;
        end
    end
    
    assign fifo_s_timer = reg_timer;
    
    
    
    // -------------------------------------
    //  Register
    // -------------------------------------
    
    // type
    localparam int  AXI4L_ADDR_BITS = s_axi4l.ADDR_BITS;
    localparam int  AXI4L_DATA_BITS = s_axi4l.DATA_BITS;
    localparam int  AXI4L_STRB_BITS = s_axi4l.STRB_BITS;
    localparam type axi4l_addr_t = logic [AXI4L_ADDR_BITS-1:0];
    localparam type axi4l_data_t = logic [AXI4L_DATA_BITS-1:0] ;
    localparam type axi4l_strb_t = logic [AXI4L_STRB_BITS-1:0] ;

    // register address offset
    localparam  regadr_t REGADR_CORE_ID       = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION  = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_CONTROL   = regadr_t'('h04);
    localparam  regadr_t REGADR_CTL_STATUS    = regadr_t'('h05);
    localparam  regadr_t REGADR_CTL_COUNT     = regadr_t'('h07);
    localparam  regadr_t REGADR_LIMIT_SIZE    = regadr_t'('h08);
    localparam  regadr_t REGADR_READ_DATA     = regadr_t'('h10);
    localparam  regadr_t REGADR_POL_TIMER0    = regadr_t'('h18);
    localparam  regadr_t REGADR_POL_TIMER1    = regadr_t'('h19);
    localparam  regadr_t REGADR_POL_DATA_BASE = regadr_t'('h20);

    // registers
    logic   [1:0]   reg_ctl_control;
    fifo_size_t     reg_limit_size;
    
    // write mask
    function [s_axi4l.DATA_BITS-1:0] write_mask(
                                        input axi4l_data_t org,
                                        input axi4l_data_t data,
                                        input axi4l_strb_t strb
                                    );
        for ( int i = 0; i < s_axi4l.DATA_BITS; i++ ) begin
            write_mask[i] = strb[i/8] ? data[i] : org[i];
        end
    endfunction
    
    // registers control
    regadr_t  regadr_write;
    regadr_t  regadr_read;
    assign regadr_write = regadr_t'(s_axi4l.awaddr / axi4l_addr_t'($bits(axi4l_strb_t)));
    assign regadr_read  = regadr_t'(s_axi4l.araddr / axi4l_addr_t'($bits(axi4l_strb_t)));

    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            reg_ctl_control <= INIT_CTL_CONTROL ;
            reg_limit_size  <= INIT_LIMIT_SIZE  ;
            
            s_axi4l.bvalid <= 1'b0  ;
            s_axi4l.rdata  <= 'x    ;
            s_axi4l.rvalid <= 1'b0  ;
        end
        else begin
            // write
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 0;
            end

            reg_ctl_control[0] <= 1'b0; // auto clear
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_CTL_CONTROL  :   reg_ctl_control <=           2'(write_mask(axi4l_data_t'(reg_ctl_control), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_LIMIT_SIZE   :   reg_limit_size  <= fifo_size_t'(write_mask(axi4l_data_t'(reg_limit_size ), s_axi4l.wdata, s_axi4l.wstrb));
                default: ;
                endcase
                s_axi4l.bvalid <= 1'b1;
            end

            // read
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                case ( regadr_read )
                REGADR_CORE_ID      :   s_axi4l.rdata <= axi4l_data_t'(CORE_ID                          );
                REGADR_CORE_VERSION :   s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION                     );
                REGADR_CTL_CONTROL  :   s_axi4l.rdata <= axi4l_data_t'(reg_ctl_control                  );
                REGADR_CTL_STATUS   :   s_axi4l.rdata <= axi4l_data_t'(fifo_m_valid                     );
                REGADR_CTL_COUNT    :   s_axi4l.rdata <= axi4l_data_t'(fifo_m_data_count                );
                REGADR_LIMIT_SIZE   :   s_axi4l.rdata <= axi4l_data_t'(reg_limit_size                   );
                REGADR_READ_DATA    :   s_axi4l.rdata <= axi4l_data_t'(fifo_m_data                      );
                REGADR_POL_TIMER0   :   s_axi4l.rdata <= axi4l_data_t'(fifo_m_timer                     );
                REGADR_POL_TIMER1   :   s_axi4l.rdata <= axi4l_data_t'(fifo_m_timer >> AXI4L_DATA_BITS  );
                default             :   s_axi4l.rdata <= '0;
                endcase
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( regadr_read == REGADR_POL_DATA_BASE + regadr_t'(i) ) begin
                        s_axi4l.rdata <= axi4l_data_t'(fifo_m_data[i]);
                    end
                end
                s_axi4l.rvalid <= 1'b1  ;
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;
    assign s_axi4l.arready = ~s_axi4l.rvalid || s_axi4l.rready;
    assign s_axi4l.rresp   = '0;
    
    // CTL_CONTROL[0] への 1 書き込み or READ_DATA で読み進む
    assign fifo_m_ready = reg_ctl_control[0]
                        || (s_axi4l.arvalid && s_axi4l.arready && (regadr_read == REGADR_READ_DATA))
                        || (reg_limit_size != 0 && fifo_m_data_count > reg_limit_size)
                        || reg_ctl_control[1];
    
endmodule


`default_nettype wire


// end of file
