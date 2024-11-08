// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// Black Level Correction
module jelly3_img_bayer_black_level
        #(
            parameter   int             S_DATA_BITS        = 10                            ,
            parameter   type            s_data_t           = logic [S_DATA_BITS-1:0]       ,
            parameter   int             M_DATA_BITS        = S_DATA_BITS + 1               ,
            parameter   type            m_data_t           = logic signed [M_DATA_BITS-1:0],
            parameter   int             OFFSET_BITS        = S_DATA_BITS                   ,
            localparam  type            offset_t           = logic [OFFSET_BITS-1:0]       ,
            localparam  type            phase_t            = logic [1:0]                   ,
  
            parameter   int             INDEX_BITS         = 1                        ,
            parameter   type            index_t            = logic [INDEX_BITS-1:0]   ,
            parameter   int             REGADR_BITS        = 8                        ,
            parameter   type            regadr_t           = logic [REGADR_BITS-1:0]  ,
  
            parameter                   CORE_ID            = 32'h527a_ffff,
            parameter                   CORE_VERSION       = 32'h0001_0000,
          
            parameter   bit     [1:0]   INIT_CTL_CONTROL   = 2'b01  ,
            parameter   phase_t         INIT_PARAM_PHASE   = 2'b00  ,
            parameter   offset_t        INIT_PARAM_OFFSET0 = 0      ,
            parameter   offset_t        INIT_PARAM_OFFSET1 = 0      ,
            parameter   offset_t        INIT_PARAM_OFFSET2 = 0      ,
            parameter   offset_t        INIT_PARAM_OFFSET3 = 0      
        )
        (
            
            input   wire        in_update_req,
            jelly3_mat_if.s     s_img,
            jelly3_mat_if.m     m_img,
            
            jelly3_axi4l_if.s   s_axi4l
        );
    
    
    
    // -------------------------------------
    //  registers domain
    // -------------------------------------

    // type
    localparam type axi4l_addr_t = logic [$bits(s_axi4l.awaddr)-1:0];
    localparam type axi4l_data_t = logic [$bits(s_axi4l.wdata)-1:0];
    localparam type axi4l_strb_t = logic [$bits(s_axi4l.wstrb)-1:0];

    // register address offset
    localparam  regadr_t REGADR_CORE_ID       = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION  = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_CONTROL   = regadr_t'('h04);
    localparam  regadr_t REGADR_CTL_STATUS    = regadr_t'('h05);
    localparam  regadr_t REGADR_CTL_INDEX     = regadr_t'('h07);
    localparam  regadr_t REGADR_PARAM_PHASE   = regadr_t'('h08);
    localparam  regadr_t REGADR_PARAM_OFFSET0 = regadr_t'('h10);
    localparam  regadr_t REGADR_PARAM_OFFSET1 = regadr_t'('h11);
    localparam  regadr_t REGADR_PARAM_OFFSET2 = regadr_t'('h12);
    localparam  regadr_t REGADR_PARAM_OFFSET3 = regadr_t'('h13);
    
    // registers
    logic       [1:0]   reg_ctl_control     ;    // bit[0]:enable, bit[1]:update
    phase_t             reg_param_phase     ;
    offset_t    [3:0]   reg_param_offset    ;
    
    // shadow registers(core domain)
    logic       [0:0]   core_ctl_control    ;
    phase_t             core_param_phase    ;
    offset_t    [3:0]   core_param_offset   ;
    
    // handshake with core domain
    index_t             update_index        ;
    logic               update_ack          ;
    index_t             ctl_index           ;
    
    jelly_param_update_master
            #(
                .INDEX_WIDTH    ($bits(index_t))
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
            reg_ctl_control     <= INIT_CTL_CONTROL;
            reg_param_phase     <= INIT_PARAM_PHASE;
            reg_param_offset[0] <= INIT_PARAM_OFFSET0;
            reg_param_offset[1] <= INIT_PARAM_OFFSET1;
            reg_param_offset[2] <= INIT_PARAM_OFFSET2;
            reg_param_offset[3] <= INIT_PARAM_OFFSET3;

            s_axi4l.bvalid <= 1'b0;
            s_axi4l.rdata  <= 'x;
            s_axi4l.rvalid <= 1'b0;
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
                REGADR_CTL_CONTROL:   reg_ctl_control     <=        2'(write_mask(axi4l_data_t'(reg_ctl_control    ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_PHASE:   reg_param_phase     <=  phase_t'(write_mask(axi4l_data_t'(reg_param_phase    ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_OFFSET0: reg_param_offset[0] <= offset_t'(write_mask(axi4l_data_t'(reg_param_offset[0]), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_OFFSET1: reg_param_offset[1] <= offset_t'(write_mask(axi4l_data_t'(reg_param_offset[1]), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_OFFSET2: reg_param_offset[2] <= offset_t'(write_mask(axi4l_data_t'(reg_param_offset[2]), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_OFFSET3: reg_param_offset[3] <= offset_t'(write_mask(axi4l_data_t'(reg_param_offset[3]), s_axi4l.wdata, s_axi4l.wstrb));
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
                REGADR_CORE_ID:        s_axi4l.rdata <= axi4l_data_t'(CORE_ID            );
                REGADR_CORE_VERSION:   s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION       );
                REGADR_CTL_CONTROL:    s_axi4l.rdata <= axi4l_data_t'(reg_ctl_control    );
                REGADR_CTL_STATUS:     s_axi4l.rdata <= axi4l_data_t'(core_ctl_control   );   // debug use only
                REGADR_CTL_INDEX:      s_axi4l.rdata <= axi4l_data_t'(ctl_index          );
                REGADR_PARAM_PHASE:    s_axi4l.rdata <= axi4l_data_t'(reg_param_phase    );
                REGADR_PARAM_OFFSET0:  s_axi4l.rdata <= axi4l_data_t'(reg_param_offset[0]);
                REGADR_PARAM_OFFSET1:  s_axi4l.rdata <= axi4l_data_t'(reg_param_offset[1]);
                REGADR_PARAM_OFFSET2:  s_axi4l.rdata <= axi4l_data_t'(reg_param_offset[2]);
                REGADR_PARAM_OFFSET3:  s_axi4l.rdata <= axi4l_data_t'(reg_param_offset[3]);
                default:               s_axi4l.rdata <= '0;
                endcase
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
    wire    update_trig = (s_img.valid & s_img.row_first & s_img.col_first);
    wire    update_en;
    
    jelly_param_update_slave
            #(
                .INDEX_WIDTH    ($bits(index_t)     )
            )
        u_param_update_slave
            (
                .reset          (s_img.reset        ),
                .clk            (s_img.clk          ),
                .cke            (s_img.cke          ),
                
                .in_trigger     (update_trig        ),
                .in_update      (reg_ctl_control[1] ),
                
                .out_update     (update_en          ),
                .out_index      (update_index       )
            );
    
    // wait for frame start to update parameters
    logic       reg_update_req;
    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset ) begin
            reg_update_req   <= 1'b0;
            
            core_ctl_control     <= INIT_CTL_CONTROL[0] ;
            core_param_phase     <= INIT_PARAM_PHASE    ;
            core_param_offset[0] <= INIT_PARAM_OFFSET0  ;
            core_param_offset[1] <= INIT_PARAM_OFFSET1  ;
            core_param_offset[2] <= INIT_PARAM_OFFSET2  ;
            core_param_offset[3] <= INIT_PARAM_OFFSET3  ;
        end
        else begin
            if ( in_update_req ) begin
                reg_update_req <= 1'b1;
            end
            
            if ( s_img.cke ) begin
                if ( reg_update_req & update_trig & update_en ) begin
                    reg_update_req    <= 1'b0;
                    
                    core_ctl_control  <= reg_ctl_control[0] ;
                    core_param_phase  <= reg_param_phase    ;
                    core_param_offset <= reg_param_offset   ;
                end
            end
        end
    end
    
    
    // core
    jelly3_img_bayer_black_level_core
            #(
                .S_DATA_BITS    (S_DATA_BITS),
                .s_data_t       (s_data_t   ),
                .M_DATA_BITS    (M_DATA_BITS),
                .m_data_t       (m_data_t   ),
                .OFFSET_BITS    (OFFSET_BITS)
            )
        u_img_bayer_black_level_core
            (
                .enable         (core_ctl_control[0]), 
                .param_phase    (core_param_phase   ),
                .param_offset   (core_param_offset  ),
                .s_img          (s_img              ),
                .m_img          (m_img              )
            );

    // assertion
    initial begin
        sva_s_data_bits : assert ( S_DATA_BITS == s_img.DATA_BITS ) else $warning("DATA_BITS != s_img.DATA_BITS");
        sva_m_data_bits : assert ( M_DATA_BITS == m_img.DATA_BITS ) else $warning("DATA_BITS != s_img.DATA_BITS");
    end
    always_comb begin
        sva_connect_reset : assert (m_img.reset === s_img.reset) else $error("m_img.reset != s_img.reset");
        sva_connect_clk   : assert (m_img.clk   === s_img.clk)   else $error("m_img.clk != s_img.clk");
        sva_connect_cke   : assert (m_img.cke   === s_img.cke)   else $error("m_img.cke != s_img.cke");
    end

endmodule


`default_nettype wire


// end of file
