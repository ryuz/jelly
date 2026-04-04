// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_moment
        #(
            parameter   bit             AXI4L_ASYNC       = 1                           ,
            parameter   int             CH_DEPTH          = 1                           ,
            parameter   int             CX_BITS           = 32                          ,
            parameter   type            cx_t              = logic signed  [CX_BITS-1:0] ,
            parameter   int             CY_BITS           = 32                          ,
            parameter   type            cy_t              = logic signed  [CY_BITS-1:0] ,
            parameter   int             M00_BITS          = 32                          ,
            parameter   type            m00_t             = logic [M00_BITS-1:0]        ,
            parameter   int             M10_BITS          = 32                          ,
            parameter   type            m10_t             = logic [M10_BITS-1:0]        ,
            parameter   int             M01_BITS          = 32                          ,
            parameter   type            m01_t             = logic [M01_BITS-1:0]        ,
            parameter   int             REGADR_BITS       = 8                           ,
            parameter   type            regadr_t          = logic [REGADR_BITS-1:0]     ,
            parameter                   CORE_ID           = 32'h527a_5a34               ,
            parameter                   CORE_VERSION      = 32'h0003_0000               ,
            parameter   bit     [0:0]   INIT_IRQ_ENABLE   = 1'b0                        
        )
        (
            jelly3_mat_if.s                     s_mat          ,
            jelly3_axi4l_if.s                   s_axi4l        ,
            output  var logic                   out_irq        ,

            output  var m00_t   [CH_DEPTH-1:0]  m_moment_m00   ,
            output  var m10_t   [CH_DEPTH-1:0]  m_moment_m10   ,
            output  var m01_t   [CH_DEPTH-1:0]  m_moment_m01   ,
            output  var logic                   m_moment_valid ,

            output  var cx_t                    m_out_x        ,
            output  var cy_t                    m_out_y        ,
            output  var logic                   m_out_valid    
        );


    // -------------------------------------
    //  Core
    // -------------------------------------

    m00_t   [CH_DEPTH-1:0]  core_m00    ;
    m10_t   [CH_DEPTH-1:0]  core_m10    ;
    m01_t   [CH_DEPTH-1:0]  core_m01    ;
    logic                   core_valid  ;

    jelly3_img_moment_core
            #(
                .M00_BITS       (M00_BITS       ),
                .m00_t          (m00_t          ),
                .M10_BITS       (M10_BITS       ),
                .m10_t          (m10_t          ),
                .M01_BITS       (M01_BITS       ),
                .m01_t          (m01_t          )
            )
        u_img_moment_core
            (
                .s_mat          (s_mat          ),
                .m_m00          (core_m00       ),
                .m_m10          (core_m10       ),
                .m_m01          (core_m01       ),
                .m_valid        (core_valid     )
            );

    // direct output
    assign m_moment_m00   = core_m00   ;
    assign m_moment_m10   = core_m10   ;
    assign m_moment_m01   = core_m01   ;
    assign m_moment_valid = core_valid ;


    // -------------------------------------
    //  Registers domain
    // -------------------------------------

    // AXI4L types
    localparam int  AXI4L_ADDR_BITS = s_axi4l.ADDR_BITS;
    localparam int  AXI4L_DATA_BITS = s_axi4l.DATA_BITS;
    localparam int  AXI4L_STRB_BITS = s_axi4l.STRB_BITS;
    localparam type axi4l_addr_t = logic [AXI4L_ADDR_BITS-1:0];
    localparam type axi4l_data_t = logic [AXI4L_DATA_BITS-1:0];
    localparam type axi4l_strb_t = logic [AXI4L_STRB_BITS-1:0];

    // moment data struct for async transfer
    typedef struct packed {
        m01_t [CH_DEPTH-1:0] m01;
        m10_t [CH_DEPTH-1:0] m10;
        m00_t [CH_DEPTH-1:0] m00;
    } moment_data_t;

    // register address offset
    localparam  regadr_t REGADR_CORE_ID          = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION     = regadr_t'('h01);
    localparam  regadr_t REGADR_IRQ_ENABLE       = regadr_t'('h08);
    localparam  regadr_t REGADR_IRQ_STATUS       = regadr_t'('h09);
    localparam  regadr_t REGADR_IRQ_CLR          = regadr_t'('h0a);
    localparam  regadr_t REGADR_IRQ_SET          = regadr_t'('h0b);
    localparam  regadr_t REGADR_OUT_VALID        = regadr_t'('h20);
    localparam  regadr_t REGADR_OUT_READY        = regadr_t'('h21);
    localparam  regadr_t REGADR_OUT_X_LO         = regadr_t'('h30);
    localparam  regadr_t REGADR_OUT_X_HI         = regadr_t'('h31);
    localparam  regadr_t REGADR_OUT_Y_LO         = regadr_t'('h32);
    localparam  regadr_t REGADR_OUT_Y_HI         = regadr_t'('h33);
    localparam  regadr_t REGADR_MOMENT_VALID     = regadr_t'('h40);
    localparam  regadr_t REGADR_MOMENT_READY     = regadr_t'('h41);
    localparam  regadr_t REGADR_MOMENT_DATA      = regadr_t'('h50);

    // registers
    logic   [0:0]       reg_irq_enable      ;
    logic   [0:0]       reg_irq_status      ;
    moment_data_t       reg_moment          ;
    logic               reg_moment_valid    ;
    logic               reg_moment_ready    ;
    cx_t                reg_out_x           ;
    cy_t                reg_out_y           ;
    logic               reg_out_valid       ;
    logic               reg_out_ready       ;

    // pack core output into struct
    moment_data_t       core_moment     ;
    assign core_moment.m00 = core_m00   ;
    assign core_moment.m10 = core_m10   ;
    assign core_moment.m01 = core_m01   ;

    // async transfer: core domain -> register domain (moment results)
    jelly_data_async
            #(
                .ASYNC          (AXI4L_ASYNC            ),
                .DATA_WIDTH     ($bits(moment_data_t)   )
            )
        u_data_async_moment
            (
                .s_reset        (s_mat.reset            ),
                .s_clk          (s_mat.clk              ),
                .s_data         (core_moment            ),
                .s_valid        (core_valid             ),
                .s_ready        (                       ),

                .m_reset        (~s_axi4l.aresetn       ),
                .m_clk          (s_axi4l.aclk           ),
                .m_data         (reg_moment             ),
                .m_valid        (reg_moment_valid       ),
                .m_ready        (reg_moment_ready       )
            );

    // centroid data struct for async transfer
    typedef struct packed {
        cy_t y;
        cx_t x;
    } centroid_data_t;

    // async transfer: register domain -> core domain (centroid from CPU)
    centroid_data_t     reg_out_data;
    assign reg_out_data.x = reg_out_x   ;
    assign reg_out_data.y = reg_out_y   ;

    centroid_data_t     out_data    ;
    logic               out_valid   ;

    jelly_data_async
            #(
                .ASYNC          (AXI4L_ASYNC            ),
                .DATA_WIDTH     ($bits(centroid_data_t) )
            )
        u_data_async_centroid
            (
                .s_reset        (~s_axi4l.aresetn       ),
                .s_clk          (s_axi4l.aclk           ),
                .s_data         (reg_out_data           ),
                .s_valid        (reg_out_valid          ),
                .s_ready        (reg_out_ready          ),

                .m_reset        (s_mat.reset            ),
                .m_clk          (s_mat.clk              ),
                .m_data         (out_data               ),
                .m_valid        (out_valid              ),
                .m_ready        (1'b1                   )
            );

    assign m_out_x     = out_data.x   ;
    assign m_out_y     = out_data.y   ;
    assign m_out_valid = out_valid    ;


    // write mask
    function [AXI4L_DATA_BITS-1:0] write_mask(
                                        input axi4l_data_t org,
                                        input axi4l_data_t data,
                                        input axi4l_strb_t strb
                                    );
        for ( int i = 0; i < AXI4L_DATA_BITS; i++ ) begin
            write_mask[i] = strb[i/8] ? data[i] : org[i];
        end
    endfunction

    function [AXI4L_DATA_BITS-1:0] lo(logic [127:0] v);
        return AXI4L_DATA_BITS'(v);
    endfunction

    function [AXI4L_DATA_BITS-1:0] hi(logic [127:0] v);
        return AXI4L_DATA_BITS'(v >> AXI4L_DATA_BITS);
    endfunction


    // registers control
    regadr_t  regadr_write;
    regadr_t  regadr_read;
    assign regadr_write = regadr_t'(s_axi4l.awaddr / axi4l_addr_t'($bits(axi4l_strb_t)));
    assign regadr_read  = regadr_t'(s_axi4l.araddr / axi4l_addr_t'($bits(axi4l_strb_t)));

    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            reg_irq_enable     <= INIT_IRQ_ENABLE   ;
            reg_irq_status     <= '0                ;
            reg_moment_ready   <= 1'b0              ;
            reg_out_x          <= 'x                ;
            reg_out_y          <= 'x                ;
            reg_out_valid      <= 1'b0              ;

            s_axi4l.bvalid     <= 1'b0              ;
            s_axi4l.rdata      <= 'x                ;
            s_axi4l.rvalid     <= 1'b0              ;
        end
        else begin
            // IRQ on new moment result
            if ( reg_moment_valid ) begin
                reg_irq_status[0] <= 1'b1;
            end

            // auto clear
            reg_moment_ready <= 1'b0;
            if ( reg_out_ready ) begin
                reg_out_valid <= 1'b0;
            end


            // write
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_IRQ_ENABLE   : reg_irq_enable     <=    1'( write_mask(axi4l_data_t'(reg_irq_enable              ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_IRQ_CLR      : reg_irq_status     <=   ~1'( write_mask(axi4l_data_t'(0                           ), s_axi4l.wdata, s_axi4l.wstrb)) & reg_irq_status;
                REGADR_IRQ_SET      : reg_irq_status     <=    1'( write_mask(axi4l_data_t'(0                           ), s_axi4l.wdata, s_axi4l.wstrb)) | reg_irq_status;
                REGADR_MOMENT_READY : reg_moment_ready   <=    1'( write_mask(axi4l_data_t'(reg_moment_ready            ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_OUT_X_LO     : reg_out_x          <= cx_t'( write_mask(axi4l_data_t'(reg_out_x                   ), s_axi4l.wdata, s_axi4l.wstrb));
//              REGADR_OUT_X_HI     : reg_out_x          <= cx_t'({write_mask(axi4l_data_t'(reg_out_x >> AXI4L_DATA_BITS), s_axi4l.wdata, s_axi4l.wstrb), reg_out_x[AXI4L_DATA_BITS-1:0]});
                REGADR_OUT_Y_LO     : reg_out_y          <= cy_t'( write_mask(axi4l_data_t'(reg_out_y                   ), s_axi4l.wdata, s_axi4l.wstrb));
//              REGADR_OUT_Y_HI     : reg_out_y          <= cy_t'({write_mask(axi4l_data_t'(reg_out_y >> AXI4L_DATA_BITS), s_axi4l.wdata, s_axi4l.wstrb), reg_out_y[AXI4L_DATA_BITS-1:0]});
                REGADR_OUT_VALID    : reg_out_valid      <=    1'( write_mask(axi4l_data_t'(0                           ), s_axi4l.wdata, s_axi4l.wstrb));
                default: ;
                endcase
                s_axi4l.bvalid <= 1'b1;
            end

            // read
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                s_axi4l.rdata <= '0;
                case ( regadr_read )
                REGADR_CORE_ID       :  s_axi4l.rdata <= axi4l_data_t'(CORE_ID          );
                REGADR_CORE_VERSION  :  s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION     );
                REGADR_IRQ_ENABLE    :  s_axi4l.rdata <= axi4l_data_t'(reg_irq_enable   );
                REGADR_IRQ_STATUS    :  s_axi4l.rdata <= axi4l_data_t'(reg_irq_status   );
                REGADR_MOMENT_VALID  :  s_axi4l.rdata <= axi4l_data_t'(reg_moment_valid );
                REGADR_MOMENT_READY  :  s_axi4l.rdata <= axi4l_data_t'(reg_moment_ready );
                REGADR_OUT_X_LO      :  s_axi4l.rdata <= lo(128'(reg_out_x));
                REGADR_OUT_X_HI      :  s_axi4l.rdata <= hi(128'(reg_out_x));
                REGADR_OUT_Y_LO      :  s_axi4l.rdata <= lo(128'(reg_out_y));
                REGADR_OUT_Y_HI      :  s_axi4l.rdata <= hi(128'(reg_out_y));
                default: begin
                    for ( int c = 0; c < CH_DEPTH; c++ ) begin
                        if (regadr_read == regadr_t'('h50 + c * 8 + 0)) s_axi4l.rdata <= lo(128'(reg_moment.m00[c]));
                        if (regadr_read == regadr_t'('h50 + c * 8 + 1)) s_axi4l.rdata <= hi(128'(reg_moment.m00[c]));
                        if (regadr_read == regadr_t'('h50 + c * 8 + 2)) s_axi4l.rdata <= lo(128'(reg_moment.m10[c]));
                        if (regadr_read == regadr_t'('h50 + c * 8 + 3)) s_axi4l.rdata <= hi(128'(reg_moment.m10[c]));
                        if (regadr_read == regadr_t'('h50 + c * 8 + 4)) s_axi4l.rdata <= lo(128'(reg_moment.m01[c]));
                        if (regadr_read == regadr_t'('h50 + c * 8 + 5)) s_axi4l.rdata <= hi(128'(reg_moment.m01[c]));
                    end
                end
                endcase
                s_axi4l.rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;
    assign s_axi4l.arready = ~s_axi4l.rvalid || s_axi4l.rready;
    assign s_axi4l.rresp   = '0;

    assign out_irq = |(reg_irq_status & reg_irq_enable);

endmodule


`default_nettype wire


// end of file
