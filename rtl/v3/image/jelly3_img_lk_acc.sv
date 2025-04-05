// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_lk_acc
        #(
            parameter   int             TAPS              = 1                               ,
            parameter   int             X_BITS            = 11                              ,
            parameter   type            x_t               = logic [X_BITS-1:0]              ,
            parameter   int             Y_BITS            = 10                              ,
            parameter   type            y_t               = logic [Y_BITS-1:0]              ,
            parameter   int             CALC_BITS         = 36                              ,
            parameter   type            calc_t            = logic signed  [CALC_BITS-1:0]   ,
            parameter   int             ACC_BITS          = $bits(calc_t) + 20              ,
            parameter   type            acc_t             = logic signed  [ACC_BITS-1:0]    ,
            parameter   int             INDEX_BITS        = 1                               ,
            parameter   type            index_t           = logic [INDEX_BITS-1:0]          ,
            parameter   int             REGADR_BITS       = 8                               ,
            parameter   type            regadr_t          = logic [REGADR_BITS-1:0]         ,
            parameter                   CORE_ID           = 32'h527a_2391                   ,
            parameter                   CORE_VERSION      = 32'h0003_0000                   ,
            parameter   bit     [1:0]   INIT_CTL_CONTROL  = 2'b01                           ,
            parameter   x_t             INIT_PARAM_X      = '0                              ,
            parameter   y_t             INIT_PARAM_Y      = '0                              ,
            parameter   x_t             INIT_PARAM_WIDTH  = '1                              ,
            parameter   y_t             INIT_PARAM_HEIGHT = '1                              
        )
        (
            input   var logic               reset           ,
            input   var logic               clk             ,
            input   var logic               cke             ,

            input   var logic               in_update_req   ,

            jelly3_axi4l_if.s               s_axi4l         ,

            input   var logic               s_img_row_first ,
            input   var logic               s_img_row_last  ,
            input   var logic               s_img_col_first ,
            input   var logic               s_img_col_last  ,
            input   var logic   [TAPS-1:0]  s_img_de        ,
            input   var calc_t  [TAPS-1:0]  s_img_gx2       ,
            input   var calc_t  [TAPS-1:0]  s_img_gy2       ,
            input   var calc_t  [TAPS-1:0]  s_img_gxy       ,
            input   var calc_t  [TAPS-1:0]  s_img_ex        ,
            input   var calc_t  [TAPS-1:0]  s_img_ey        ,
            input   var logic               s_img_valid     ,


            output  var acc_t               out_acc_gx2     ,
            output  var acc_t               out_acc_gy2     ,
            output  var acc_t               out_acc_gxy     ,
            output  var acc_t               out_acc_ex      ,
            output  var acc_t               out_acc_ey      ,
            output  var logic               out_acc_valid   
        );
    

    // -------------------------------------
    //  registers domain
    // -------------------------------------

    // type
    localparam type axi4l_addr_t = logic [$bits(s_axi4l.awaddr)-1:0];
    localparam type axi4l_data_t = logic [$bits(s_axi4l.wdata) -1:0];
    localparam type axi4l_strb_t = logic [$bits(s_axi4l.wstrb) -1:0];

    // register address offset
    localparam  regadr_t REGADR_CORE_ID       = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION  = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_CONTROL   = regadr_t'('h04);
    localparam  regadr_t REGADR_CTL_STATUS    = regadr_t'('h05);
    localparam  regadr_t REGADR_CTL_INDEX     = regadr_t'('h07);
    localparam  regadr_t REGADR_IRQ_ENABLE    = regadr_t'('h08);
    localparam  regadr_t REGADR_IRQ_STATUS    = regadr_t'('h09);
    localparam  regadr_t REGADR_IRQ_CLR       = regadr_t'('h0a);
    localparam  regadr_t REGADR_IRQ_SET       = regadr_t'('h0b);
    localparam  regadr_t REGADR_PARAM_X       = regadr_t'('h10);
    localparam  regadr_t REGADR_PARAM_Y       = regadr_t'('h11);
    localparam  regadr_t REGADR_PARAM_WIDTH   = regadr_t'('h12);
    localparam  regadr_t REGADR_PARAM_HEIGHT  = regadr_t'('h13);
    localparam  regadr_t REGADR_ACC_VALID     = regadr_t'('h40);
    localparam  regadr_t REGADR_ACC_GXX0      = regadr_t'('h42);
    localparam  regadr_t REGADR_ACC_GXX1      = regadr_t'('h43);
    localparam  regadr_t REGADR_ACC_GYY0      = regadr_t'('h44);
    localparam  regadr_t REGADR_ACC_GYY1      = regadr_t'('h45);
    localparam  regadr_t REGADR_ACC_GXY0      = regadr_t'('h46);
    localparam  regadr_t REGADR_ACC_GXY1      = regadr_t'('h47);
    localparam  regadr_t REGADR_ACC_EX0       = regadr_t'('h48);
    localparam  regadr_t REGADR_ACC_EX1       = regadr_t'('h49);
    localparam  regadr_t REGADR_ACC_EY0       = regadr_t'('h4a);
    localparam  regadr_t REGADR_ACC_EY1       = regadr_t'('h4b);
    localparam  regadr_t REGADR_OUT_VALID     = regadr_t'('h60);
    localparam  regadr_t REGADR_OUT_DX0       = regadr_t'('h64);
    localparam  regadr_t REGADR_OUT_DX1       = regadr_t'('h65);
    localparam  regadr_t REGADR_OUT_DY0       = regadr_t'('h66);
    localparam  regadr_t REGADR_OUT_DY1       = regadr_t'('h67);
    
    // registers
    logic   [1:0]   reg_ctl_control     ;    // bit[0]:enable, bit[1]:update
    x_t             reg_param_x         ;
    y_t             reg_param_y         ;
    x_t             reg_param_width     ;
    y_t             reg_param_height    ;
    
    // shadow registers(core domain)
    logic   [0:0]   core_ctl_control    ;
    x_t             core_param_x        ;
    y_t             core_param_y        ;
    x_t             core_param_width    ;
    y_t             core_param_height   ;
    
    // handshake with core domain
    index_t         update_index        ;
    logic           update_ack          ;
    index_t         ctl_index           ;
    
    jelly_param_update_master
            #(
                .INDEX_WIDTH    ($bits(index_t)     )
            )
        u_param_update_master
            (
                .reset          (~s_axi4l.aresetn   ),
                .clk            (s_axi4l.aclk       ),
                .cke            (1'b1               ),
                .in_index       (update_index       ),
                .out_ack        (update_ack         ),
                .out_index      (ctl_index          )
            );
    

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
            reg_ctl_control  <= INIT_CTL_CONTROL    ;
            reg_param_x      <= INIT_PARAM_X        ;
            reg_param_y      <= INIT_PARAM_Y        ;
            reg_param_width  <= INIT_PARAM_WIDTH    ;
            reg_param_height <= INIT_PARAM_HEIGHT   ;

            s_axi4l.bvalid   <= 1'b0    ;
            s_axi4l.rdata    <= 'x      ;
            s_axi4l.rvalid   <= 1'b0    ;
        end
        else begin
            // auto clear
            if ( update_ack ) begin
                reg_ctl_control[1] <= 1'b0;
            end

            // write
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_CTL_CONTROL  :   reg_ctl_control  <=   2'(write_mask(axi4l_data_t'(reg_ctl_control ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_X      :   reg_param_x      <= x_t'(write_mask(axi4l_data_t'(reg_param_x     ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_Y      :   reg_param_y      <= y_t'(write_mask(axi4l_data_t'(reg_param_y     ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_WIDTH  :   reg_param_width  <= x_t'(write_mask(axi4l_data_t'(reg_param_width ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_HEIGHT :   reg_param_height <= y_t'(write_mask(axi4l_data_t'(reg_param_height), s_axi4l.wdata, s_axi4l.wstrb));
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
                REGADR_CORE_ID      :   s_axi4l.rdata <= axi4l_data_t'(CORE_ID          );
                REGADR_CORE_VERSION :   s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION     );
                REGADR_CTL_CONTROL  :   s_axi4l.rdata <= axi4l_data_t'(reg_ctl_control  );
                REGADR_CTL_STATUS   :   s_axi4l.rdata <= axi4l_data_t'(core_ctl_control );   // debug use only
                REGADR_CTL_INDEX    :   s_axi4l.rdata <= axi4l_data_t'(ctl_index        );
                REGADR_PARAM_X      :   s_axi4l.rdata <= axi4l_data_t'(reg_param_x      );
                REGADR_PARAM_Y      :   s_axi4l.rdata <= axi4l_data_t'(reg_param_y      );
                REGADR_PARAM_WIDTH  :   s_axi4l.rdata <= axi4l_data_t'(reg_param_width  );
                REGADR_PARAM_HEIGHT :   s_axi4l.rdata <= axi4l_data_t'(reg_param_height );
                default:                s_axi4l.rdata <= '0;
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
    
    

    // -------------------------------------
    //  core domain
    // -------------------------------------
    
    // handshake with registers domain
    wire    update_trig = (s_img_valid & s_img_row_first & s_img_col_first);
    wire    update_en;
    
    jelly_param_update_slave
            #(
                .INDEX_WIDTH    ($bits(index_t)     )
            )
        u_param_update_slave
            (
                .reset          (reset              ),
                .clk            (clk                ),
                .cke            (cke                ),
                
                .in_trigger     (update_trig        ),
                .in_update      (reg_ctl_control[1] ),
                
                .out_update     (update_en          ),
                .out_index      (update_index       )
            );
    

    // wait for frame start to update parameters
    logic       reg_update_req;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_update_req   <= 1'b0;
            
            core_ctl_control  <= INIT_CTL_CONTROL[0]    ;
            core_param_x      <= INIT_PARAM_X           ;
            core_param_y      <= INIT_PARAM_Y           ;
            core_param_width  <= INIT_PARAM_WIDTH       ;
            core_param_height <= INIT_PARAM_HEIGHT      ;
        end
        else begin
            if ( in_update_req ) begin
                reg_update_req <= 1'b1;
            end
            
            if ( cke ) begin
                if ( reg_update_req & update_trig & update_en ) begin
                    reg_update_req     <= 1'b0;
                    
                    core_ctl_control  <= reg_ctl_control[0];
                    core_param_x       <= reg_param_x      ;
                    core_param_y       <= reg_param_y      ;
                    core_param_width   <= reg_param_width  ;
                    core_param_height  <= reg_param_height ;
                end
            end
        end
    end
    

    typedef struct packed {
        calc_t  [TAPS-1:0]  gx2 ;
        calc_t  [TAPS-1:0]  gy2 ;
        calc_t  [TAPS-1:0]  gxy ;
        calc_t  [TAPS-1:0]  ex  ;
        calc_t  [TAPS-1:0]  ey  ;
    } moment_t;
    
    // Rect
    moment_t            s_img_moment   ;
    assign s_img_moment.gx2 = s_img_gx2;
    assign s_img_moment.gy2 = s_img_gy2;
    assign s_img_moment.gxy = s_img_gxy;
    assign s_img_moment.ex  = s_img_ex ;
    assign s_img_moment.ey  = s_img_ey ;

    logic               rect_row_first ;
    logic               rect_row_last  ;
    logic               rect_col_first ;
    logic               rect_col_last  ;
    logic   [TAPS-1:0]  rect_de        ;
    moment_t            rect_moment    ;
    logic               rect_valid     ;

    jelly3_img_mask_rect_core
            #(
                .TAPS               (1                  ),
                .DE_BITS            (TAPS               ),
                .DATA_BITS          ($bits(moment_t)    ),
                .data_t             (moment_t           ),
                .X_BITS             ($bits(x_t)         ),
                .Y_BITS             ($bits(y_t)         )
            )
        u_img_mask_rect_core
            (
                .reset              (reset              ),
                .clk                (clk                ),
                .cke                (cke                ),

                .enable             (core_ctl_control[0]),
                .param_x            (core_param_x       ),
                .param_y            (core_param_y       ),
                .param_width        (core_param_width   ),
                .param_height       (core_param_height  ),

                .s_img_rows         ('0                 ),
                .s_img_cols         ('0                 ),
                .s_img_row_first    (s_img_row_first    ),
                .s_img_row_last     (s_img_row_last     ),
                .s_img_col_first    (s_img_col_first    ),
                .s_img_col_last     (s_img_col_last     ),
                .s_img_de           (s_img_de           ),
                .s_img_data         (s_img_moment       ),
                .s_img_user         ('0                 ),
                .s_img_valid        (s_img_valid        ),

                .m_rect_row_first   (rect_row_first     ),
                .m_rect_row_last    (rect_row_last      ),
                .m_rect_col_first   (rect_col_first     ),
                .m_rect_col_last    (rect_col_last      ),
                .m_rect_de          (rect_de            ),
                .m_img_rows         (                   ),
                .m_img_cols         (                   ),
                .m_img_row_first    (                   ),
                .m_img_row_last     (                   ),
                .m_img_col_first    (                   ),
                .m_img_col_last     (                   ),
                .m_img_de           (                   ),
                .m_img_data         (rect_moment        ),
                .m_img_user         (                   ),
                .m_img_valid        (rect_valid         )
        );

    jelly3_img_lk_acc_core
            #(
                .TAPS               (TAPS                           ),
                .calc_t             (calc_t                         ),
                .acc_t              (acc_t                          )
            )
        u_img_lk_acc_core
            (
                .reset              (reset                          ),
                .clk                (clk                            ),
                .cke                (cke                            ),

                .in_first           (rect_row_first & rect_col_first),
                .in_last            (rect_row_last  & rect_col_last ),
                .in_de              (rect_de                        ),
                .in_gx2             (rect_moment.gx2                ),
                .in_gy2             (rect_moment.gy2                ),
                .in_gxy             (rect_moment.gxy                ),
                .in_ex              (rect_moment.ex                 ),
                .in_ey              (rect_moment.ey                 ),
                .in_valid           (rect_valid                     ),

                .out_gx2            (out_acc_gx2                    ),
                .out_gy2            (out_acc_gy2                    ),
                .out_gxy            (out_acc_gxy                    ),
                .out_ex             (out_acc_ex                     ),
                .out_ey             (out_acc_ey                     ),
                .out_valid          (out_acc_valid                  )
            );


endmodule


`default_nettype wire


// end of file
