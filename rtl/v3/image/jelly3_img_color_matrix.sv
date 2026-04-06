// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_color_matrix
        #(
            parameter   int                                 CH_BITS              = 10                                   ,
            parameter   type                                ch_t                 = logic [CH_BITS-1:0]                  ,
            parameter   int                                 INTERNAL_BITS        = CH_BITS + 2                          ,
            parameter   int                                 COEFF_INT_BITS       = 17                                   ,
            parameter   int                                 COEFF_FRAC_BITS      = 8                                    ,
            parameter   int                                 COEFF3_INT_BITS      = COEFF_INT_BITS                       ,
            parameter   int                                 COEFF3_FRAC_BITS     = COEFF_FRAC_BITS                      ,
            parameter   bit                                 STATIC_COEFF         = 1                                    ,
            parameter                                       DEVICE               = "RTL"                                ,
            parameter   int                                 INDEX_BITS           = 1                                    ,
            parameter   type                                index_t              = logic [INDEX_BITS-1:0]               ,
            parameter   int                                 REGADR_BITS          = 8                                    ,
            parameter   type                                regadr_t             = logic [REGADR_BITS-1:0]              ,
            parameter                                       CORE_ID              = 32'h527a_2130                        ,
            parameter                                       CORE_VERSION         = 32'h0003_0001                        ,
            localparam  int                                 COEFF_BITS           = COEFF_INT_BITS + COEFF_FRAC_BITS     ,
            localparam  int                                 COEFF3_BITS          = COEFF3_INT_BITS + COEFF3_FRAC_BITS   ,
            parameter   bit             [2:0]               INIT_CTL_CONTROL     = 3'b001                               ,
            parameter   bit     signed  [COEFF_BITS-1:0]    INIT_PARAM_MATRIX00  = COEFF_BITS'(1 << COEFF_FRAC_BITS)    ,
            parameter   bit     signed  [COEFF_BITS-1:0]    INIT_PARAM_MATRIX01  = '0                                   ,
            parameter   bit     signed  [COEFF_BITS-1:0]    INIT_PARAM_MATRIX02  = '0                                   ,
            parameter   bit     signed  [COEFF3_BITS-1:0]   INIT_PARAM_MATRIX03  = '0                                   ,
            parameter   bit     signed  [COEFF_BITS-1:0]    INIT_PARAM_MATRIX10  = '0                                   ,
            parameter   bit     signed  [COEFF_BITS-1:0]    INIT_PARAM_MATRIX11  = COEFF_BITS'(1 << COEFF_FRAC_BITS)    ,
            parameter   bit     signed  [COEFF_BITS-1:0]    INIT_PARAM_MATRIX12  = '0                                   ,
            parameter   bit     signed  [COEFF3_BITS-1:0]   INIT_PARAM_MATRIX13  = '0                                   ,
            parameter   bit     signed  [COEFF_BITS-1:0]    INIT_PARAM_MATRIX20  = '0                                   ,
            parameter   bit     signed  [COEFF_BITS-1:0]    INIT_PARAM_MATRIX21  = '0                                   ,
            parameter   bit     signed  [COEFF_BITS-1:0]    INIT_PARAM_MATRIX22  = COEFF_BITS'(1 << COEFF_FRAC_BITS)    ,
            parameter   bit     signed  [COEFF3_BITS-1:0]   INIT_PARAM_MATRIX23  = '0                                   ,
            parameter   ch_t                                INIT_PARAM_CLIP_MIN0 = '0                                   ,
            parameter   ch_t                                INIT_PARAM_CLIP_MAX0 = '1                                   ,
            parameter   ch_t                                INIT_PARAM_CLIP_MIN1 = '0                                   ,
            parameter   ch_t                                INIT_PARAM_CLIP_MAX1 = '1                                   ,
            parameter   ch_t                                INIT_PARAM_CLIP_MIN2 = '0                                   ,
            parameter   ch_t                                INIT_PARAM_CLIP_MAX2 = '1
        )
        (
            input   var logic   in_update_req,

            jelly3_mat_if.s     s_img,
            jelly3_mat_if.m     m_img,

            jelly3_axi4l_if.s   s_axi4l
        );


    // -------------------------------------
    //  registers domain
    // -------------------------------------

    initial if ( REGADR_BITS < 8 ) $error();

    // type
    localparam type axi4l_addr_t = logic [$bits(s_axi4l.awaddr)-1:0];
    localparam type axi4l_data_t = logic [$bits(s_axi4l.wdata)-1:0];
    localparam type axi4l_strb_t = logic [$bits(s_axi4l.wstrb)-1:0];

    // register address offset
    localparam  regadr_t REGADR_CORE_ID               = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION          = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_CONTROL           = regadr_t'('h04);
    localparam  regadr_t REGADR_CTL_STATUS            = regadr_t'('h05);
    localparam  regadr_t REGADR_CTL_INDEX             = regadr_t'('h07);
    localparam  regadr_t REGADR_PARAM_MATRIX00        = regadr_t'('h10);
    localparam  regadr_t REGADR_PARAM_MATRIX01        = regadr_t'('h11);
    localparam  regadr_t REGADR_PARAM_MATRIX02        = regadr_t'('h12);
    localparam  regadr_t REGADR_PARAM_MATRIX03        = regadr_t'('h13);
    localparam  regadr_t REGADR_PARAM_MATRIX10        = regadr_t'('h14);
    localparam  regadr_t REGADR_PARAM_MATRIX11        = regadr_t'('h15);
    localparam  regadr_t REGADR_PARAM_MATRIX12        = regadr_t'('h16);
    localparam  regadr_t REGADR_PARAM_MATRIX13        = regadr_t'('h17);
    localparam  regadr_t REGADR_PARAM_MATRIX20        = regadr_t'('h18);
    localparam  regadr_t REGADR_PARAM_MATRIX21        = regadr_t'('h19);
    localparam  regadr_t REGADR_PARAM_MATRIX22        = regadr_t'('h1a);
    localparam  regadr_t REGADR_PARAM_MATRIX23        = regadr_t'('h1b);
    localparam  regadr_t REGADR_PARAM_CLIP_MIN0       = regadr_t'('h20);
    localparam  regadr_t REGADR_PARAM_CLIP_MAX0       = regadr_t'('h21);
    localparam  regadr_t REGADR_PARAM_CLIP_MIN1       = regadr_t'('h22);
    localparam  regadr_t REGADR_PARAM_CLIP_MAX1       = regadr_t'('h23);
    localparam  regadr_t REGADR_PARAM_CLIP_MIN2       = regadr_t'('h24);
    localparam  regadr_t REGADR_PARAM_CLIP_MAX2       = regadr_t'('h25);
    localparam  regadr_t REGADR_CFG_COEFF0_BITS       = regadr_t'('h40);
    localparam  regadr_t REGADR_CFG_COEFF1_BITS       = regadr_t'('h41);
    localparam  regadr_t REGADR_CFG_COEFF2_BITS       = regadr_t'('h42);
    localparam  regadr_t REGADR_CFG_COEFF3_BITS       = regadr_t'('h43);
    localparam  regadr_t REGADR_CFG_COEFF0_FRAC_BITS  = regadr_t'('h44);
    localparam  regadr_t REGADR_CFG_COEFF1_FRAC_BITS  = regadr_t'('h45);
    localparam  regadr_t REGADR_CFG_COEFF2_FRAC_BITS  = regadr_t'('h46);
    localparam  regadr_t REGADR_CFG_COEFF3_FRAC_BITS  = regadr_t'('h47);
    localparam  regadr_t REGADR_CURRENT_MATRIX00      = regadr_t'('h90);
    localparam  regadr_t REGADR_CURRENT_MATRIX01      = regadr_t'('h91);
    localparam  regadr_t REGADR_CURRENT_MATRIX02      = regadr_t'('h92);
    localparam  regadr_t REGADR_CURRENT_MATRIX03      = regadr_t'('h93);
    localparam  regadr_t REGADR_CURRENT_MATRIX10      = regadr_t'('h94);
    localparam  regadr_t REGADR_CURRENT_MATRIX11      = regadr_t'('h95);
    localparam  regadr_t REGADR_CURRENT_MATRIX12      = regadr_t'('h96);
    localparam  regadr_t REGADR_CURRENT_MATRIX13      = regadr_t'('h97);
    localparam  regadr_t REGADR_CURRENT_MATRIX20      = regadr_t'('h98);
    localparam  regadr_t REGADR_CURRENT_MATRIX21      = regadr_t'('h99);
    localparam  regadr_t REGADR_CURRENT_MATRIX22      = regadr_t'('h9a);
    localparam  regadr_t REGADR_CURRENT_MATRIX23      = regadr_t'('h9b);
    localparam  regadr_t REGADR_CURRENT_CLIP_MIN0     = regadr_t'('ha0);
    localparam  regadr_t REGADR_CURRENT_CLIP_MAX0     = regadr_t'('ha1);
    localparam  regadr_t REGADR_CURRENT_CLIP_MIN1     = regadr_t'('ha2);
    localparam  regadr_t REGADR_CURRENT_CLIP_MAX1     = regadr_t'('ha3);
    localparam  regadr_t REGADR_CURRENT_CLIP_MIN2     = regadr_t'('ha4);
    localparam  regadr_t REGADR_CURRENT_CLIP_MAX2     = regadr_t'('ha5);


    // registers
    logic           [2:0]               reg_ctl_control;
    logic   signed  [COEFF_BITS-1:0]    reg_param_matrix00;
    logic   signed  [COEFF_BITS-1:0]    reg_param_matrix01;
    logic   signed  [COEFF_BITS-1:0]    reg_param_matrix02;
    logic   signed  [COEFF3_BITS-1:0]   reg_param_matrix03;
    logic   signed  [COEFF_BITS-1:0]    reg_param_matrix10;
    logic   signed  [COEFF_BITS-1:0]    reg_param_matrix11;
    logic   signed  [COEFF_BITS-1:0]    reg_param_matrix12;
    logic   signed  [COEFF3_BITS-1:0]   reg_param_matrix13;
    logic   signed  [COEFF_BITS-1:0]    reg_param_matrix20;
    logic   signed  [COEFF_BITS-1:0]    reg_param_matrix21;
    logic   signed  [COEFF_BITS-1:0]    reg_param_matrix22;
    logic   signed  [COEFF3_BITS-1:0]   reg_param_matrix23;
    ch_t                                reg_param_clip_min0;
    ch_t                                reg_param_clip_max0;
    ch_t                                reg_param_clip_min1;
    ch_t                                reg_param_clip_max1;
    ch_t                                reg_param_clip_min2;
    ch_t                                reg_param_clip_max2;

    // shadow registers (core domain)
    logic   signed  [COEFF_BITS-1:0]    core_param_matrix00;
    logic   signed  [COEFF_BITS-1:0]    core_param_matrix01;
    logic   signed  [COEFF_BITS-1:0]    core_param_matrix02;
    logic   signed  [COEFF3_BITS-1:0]   core_param_matrix03;
    logic   signed  [COEFF_BITS-1:0]    core_param_matrix10;
    logic   signed  [COEFF_BITS-1:0]    core_param_matrix11;
    logic   signed  [COEFF_BITS-1:0]    core_param_matrix12;
    logic   signed  [COEFF3_BITS-1:0]   core_param_matrix13;
    logic   signed  [COEFF_BITS-1:0]    core_param_matrix20;
    logic   signed  [COEFF_BITS-1:0]    core_param_matrix21;
    logic   signed  [COEFF_BITS-1:0]    core_param_matrix22;
    logic   signed  [COEFF3_BITS-1:0]   core_param_matrix23;
    ch_t                                core_param_clip_min0;
    ch_t                                core_param_clip_max0;
    ch_t                                core_param_clip_min1;
    ch_t                                core_param_clip_max1;
    ch_t                                core_param_clip_min2;
    ch_t                                core_param_clip_max2;

    // handshake with core domain
    index_t         update_index;
    logic           update_ack;
    index_t         ctl_index;

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
            reg_ctl_control     <= INIT_CTL_CONTROL | 3'b001;
            reg_param_matrix00  <= INIT_PARAM_MATRIX00;
            reg_param_matrix01  <= INIT_PARAM_MATRIX01;
            reg_param_matrix02  <= INIT_PARAM_MATRIX02;
            reg_param_matrix03  <= INIT_PARAM_MATRIX03;
            reg_param_matrix10  <= INIT_PARAM_MATRIX10;
            reg_param_matrix11  <= INIT_PARAM_MATRIX11;
            reg_param_matrix12  <= INIT_PARAM_MATRIX12;
            reg_param_matrix13  <= INIT_PARAM_MATRIX13;
            reg_param_matrix20  <= INIT_PARAM_MATRIX20;
            reg_param_matrix21  <= INIT_PARAM_MATRIX21;
            reg_param_matrix22  <= INIT_PARAM_MATRIX22;
            reg_param_matrix23  <= INIT_PARAM_MATRIX23;
            reg_param_clip_min0 <= INIT_PARAM_CLIP_MIN0;
            reg_param_clip_max0 <= INIT_PARAM_CLIP_MAX0;
            reg_param_clip_min1 <= INIT_PARAM_CLIP_MIN1;
            reg_param_clip_max1 <= INIT_PARAM_CLIP_MAX1;
            reg_param_clip_min2 <= INIT_PARAM_CLIP_MIN2;
            reg_param_clip_max2 <= INIT_PARAM_CLIP_MAX2;

            s_axi4l.bvalid <= 1'b0;
            s_axi4l.rdata  <= 'x;
            s_axi4l.rvalid <= 1'b0;
        end
        else begin
            // auto clear
            if ( update_ack && !reg_ctl_control[2] ) begin
                reg_ctl_control[1] <= 1'b0;
            end

            // write
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 1'b0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_CTL_CONTROL:     reg_ctl_control     <=           3'(write_mask(axi4l_data_t'(reg_ctl_control    ), s_axi4l.wdata, s_axi4l.wstrb)) | 3'b001;
                REGADR_PARAM_MATRIX00:  reg_param_matrix00  <=  COEFF_BITS'(write_mask(axi4l_data_t'(reg_param_matrix00 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_MATRIX01:  reg_param_matrix01  <=  COEFF_BITS'(write_mask(axi4l_data_t'(reg_param_matrix01 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_MATRIX02:  reg_param_matrix02  <=  COEFF_BITS'(write_mask(axi4l_data_t'(reg_param_matrix02 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_MATRIX03:  reg_param_matrix03  <= COEFF3_BITS'(write_mask(axi4l_data_t'(reg_param_matrix03 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_MATRIX10:  reg_param_matrix10  <=  COEFF_BITS'(write_mask(axi4l_data_t'(reg_param_matrix10 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_MATRIX11:  reg_param_matrix11  <=  COEFF_BITS'(write_mask(axi4l_data_t'(reg_param_matrix11 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_MATRIX12:  reg_param_matrix12  <=  COEFF_BITS'(write_mask(axi4l_data_t'(reg_param_matrix12 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_MATRIX13:  reg_param_matrix13  <= COEFF3_BITS'(write_mask(axi4l_data_t'(reg_param_matrix13 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_MATRIX20:  reg_param_matrix20  <=  COEFF_BITS'(write_mask(axi4l_data_t'(reg_param_matrix20 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_MATRIX21:  reg_param_matrix21  <=  COEFF_BITS'(write_mask(axi4l_data_t'(reg_param_matrix21 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_MATRIX22:  reg_param_matrix22  <=  COEFF_BITS'(write_mask(axi4l_data_t'(reg_param_matrix22 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_MATRIX23:  reg_param_matrix23  <= COEFF3_BITS'(write_mask(axi4l_data_t'(reg_param_matrix23 ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_CLIP_MIN0: reg_param_clip_min0 <=        ch_t'(write_mask(axi4l_data_t'(reg_param_clip_min0), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_CLIP_MAX0: reg_param_clip_max0 <=        ch_t'(write_mask(axi4l_data_t'(reg_param_clip_max0), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_CLIP_MIN1: reg_param_clip_min1 <=        ch_t'(write_mask(axi4l_data_t'(reg_param_clip_min1), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_CLIP_MAX1: reg_param_clip_max1 <=        ch_t'(write_mask(axi4l_data_t'(reg_param_clip_max1), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_CLIP_MIN2: reg_param_clip_min2 <=        ch_t'(write_mask(axi4l_data_t'(reg_param_clip_min2), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_CLIP_MAX2: reg_param_clip_max2 <=        ch_t'(write_mask(axi4l_data_t'(reg_param_clip_max2), s_axi4l.wdata, s_axi4l.wstrb));
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
                REGADR_CORE_ID:             s_axi4l.rdata <= axi4l_data_t'(CORE_ID             );
                REGADR_CORE_VERSION:        s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION        );
                REGADR_CTL_CONTROL:         s_axi4l.rdata <= axi4l_data_t'(reg_ctl_control     );
                REGADR_CTL_STATUS:          s_axi4l.rdata <= axi4l_data_t'(1                   );
                REGADR_CTL_INDEX:           s_axi4l.rdata <= axi4l_data_t'(ctl_index           );
                REGADR_PARAM_MATRIX00:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix00  );
                REGADR_PARAM_MATRIX01:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix01  );
                REGADR_PARAM_MATRIX02:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix02  );
                REGADR_PARAM_MATRIX03:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix03  );
                REGADR_PARAM_MATRIX10:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix10  );
                REGADR_PARAM_MATRIX11:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix11  );
                REGADR_PARAM_MATRIX12:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix12  );
                REGADR_PARAM_MATRIX13:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix13  );
                REGADR_PARAM_MATRIX20:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix20  );
                REGADR_PARAM_MATRIX21:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix21  );
                REGADR_PARAM_MATRIX22:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix22  );
                REGADR_PARAM_MATRIX23:      s_axi4l.rdata <= axi4l_data_t'(reg_param_matrix23  );
                REGADR_PARAM_CLIP_MIN0:     s_axi4l.rdata <= axi4l_data_t'(reg_param_clip_min0 );
                REGADR_PARAM_CLIP_MAX0:     s_axi4l.rdata <= axi4l_data_t'(reg_param_clip_max0 );
                REGADR_PARAM_CLIP_MIN1:     s_axi4l.rdata <= axi4l_data_t'(reg_param_clip_min1 );
                REGADR_PARAM_CLIP_MAX1:     s_axi4l.rdata <= axi4l_data_t'(reg_param_clip_max1 );
                REGADR_PARAM_CLIP_MIN2:     s_axi4l.rdata <= axi4l_data_t'(reg_param_clip_min2 );
                REGADR_PARAM_CLIP_MAX2:     s_axi4l.rdata <= axi4l_data_t'(reg_param_clip_max2 );
                REGADR_CFG_COEFF0_BITS:     s_axi4l.rdata <= axi4l_data_t'(COEFF_BITS          );
                REGADR_CFG_COEFF1_BITS:     s_axi4l.rdata <= axi4l_data_t'(COEFF_BITS          );
                REGADR_CFG_COEFF2_BITS:     s_axi4l.rdata <= axi4l_data_t'(COEFF_BITS          );
                REGADR_CFG_COEFF3_BITS:     s_axi4l.rdata <= axi4l_data_t'(COEFF3_BITS         );
                REGADR_CFG_COEFF0_FRAC_BITS:s_axi4l.rdata <= axi4l_data_t'(COEFF_FRAC_BITS     );
                REGADR_CFG_COEFF1_FRAC_BITS:s_axi4l.rdata <= axi4l_data_t'(COEFF_FRAC_BITS     );
                REGADR_CFG_COEFF2_FRAC_BITS:s_axi4l.rdata <= axi4l_data_t'(COEFF_FRAC_BITS     );
                REGADR_CFG_COEFF3_FRAC_BITS:s_axi4l.rdata <= axi4l_data_t'(COEFF3_FRAC_BITS    );
                REGADR_CURRENT_MATRIX00:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix00 );   // for debug
                REGADR_CURRENT_MATRIX01:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix01 );   // for debug
                REGADR_CURRENT_MATRIX02:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix02 );   // for debug
                REGADR_CURRENT_MATRIX03:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix03 );   // for debug
                REGADR_CURRENT_MATRIX10:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix10 );   // for debug
                REGADR_CURRENT_MATRIX11:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix11 );   // for debug
                REGADR_CURRENT_MATRIX12:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix12 );   // for debug
                REGADR_CURRENT_MATRIX13:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix13 );   // for debug
                REGADR_CURRENT_MATRIX20:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix20 );   // for debug
                REGADR_CURRENT_MATRIX21:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix21 );   // for debug
                REGADR_CURRENT_MATRIX22:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix22 );   // for debug
                REGADR_CURRENT_MATRIX23:    s_axi4l.rdata <= axi4l_data_t'(core_param_matrix23 );   // for debug
                REGADR_CURRENT_CLIP_MIN0:   s_axi4l.rdata <= axi4l_data_t'(core_param_clip_min0);   // for debug
                REGADR_CURRENT_CLIP_MAX0:   s_axi4l.rdata <= axi4l_data_t'(core_param_clip_max0);   // for debug
                REGADR_CURRENT_CLIP_MIN1:   s_axi4l.rdata <= axi4l_data_t'(core_param_clip_min1);   // for debug
                REGADR_CURRENT_CLIP_MAX1:   s_axi4l.rdata <= axi4l_data_t'(core_param_clip_max1);   // for debug
                REGADR_CURRENT_CLIP_MIN2:   s_axi4l.rdata <= axi4l_data_t'(core_param_clip_min2);   // for debug
                REGADR_CURRENT_CLIP_MAX2:   s_axi4l.rdata <= axi4l_data_t'(core_param_clip_max2);   // for debug
                default:                    s_axi4l.rdata <= '0;
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
    logic   update_trig = (s_img.valid & s_img.row_first & s_img.col_first);
    logic   update_en;

    jelly_param_update_slave
            #(
                .INDEX_WIDTH    ($bits(index_t))
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
    logic   reg_update_req;
    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset ) begin
            reg_update_req       <= 1'b0;

            core_param_matrix00  <= INIT_PARAM_MATRIX00;
            core_param_matrix01  <= INIT_PARAM_MATRIX01;
            core_param_matrix02  <= INIT_PARAM_MATRIX02;
            core_param_matrix03  <= INIT_PARAM_MATRIX03;
            core_param_matrix10  <= INIT_PARAM_MATRIX10;
            core_param_matrix11  <= INIT_PARAM_MATRIX11;
            core_param_matrix12  <= INIT_PARAM_MATRIX12;
            core_param_matrix13  <= INIT_PARAM_MATRIX13;
            core_param_matrix20  <= INIT_PARAM_MATRIX20;
            core_param_matrix21  <= INIT_PARAM_MATRIX21;
            core_param_matrix22  <= INIT_PARAM_MATRIX22;
            core_param_matrix23  <= INIT_PARAM_MATRIX23;
            core_param_clip_min0 <= INIT_PARAM_CLIP_MIN0;
            core_param_clip_max0 <= INIT_PARAM_CLIP_MAX0;
            core_param_clip_min1 <= INIT_PARAM_CLIP_MIN1;
            core_param_clip_max1 <= INIT_PARAM_CLIP_MAX1;
            core_param_clip_min2 <= INIT_PARAM_CLIP_MIN2;
            core_param_clip_max2 <= INIT_PARAM_CLIP_MAX2;
        end
        else begin
            if ( in_update_req ) begin
                reg_update_req <= 1'b1;
            end

            if ( s_img.cke ) begin
                if ( reg_update_req & update_trig & update_en ) begin
                    reg_update_req       <= 1'b0;

                    core_param_matrix00  <= reg_param_matrix00;
                    core_param_matrix01  <= reg_param_matrix01;
                    core_param_matrix02  <= reg_param_matrix02;
                    core_param_matrix03  <= reg_param_matrix03;
                    core_param_matrix10  <= reg_param_matrix10;
                    core_param_matrix11  <= reg_param_matrix11;
                    core_param_matrix12  <= reg_param_matrix12;
                    core_param_matrix13  <= reg_param_matrix13;
                    core_param_matrix20  <= reg_param_matrix20;
                    core_param_matrix21  <= reg_param_matrix21;
                    core_param_matrix22  <= reg_param_matrix22;
                    core_param_matrix23  <= reg_param_matrix23;
                    core_param_clip_min0 <= reg_param_clip_min0;
                    core_param_clip_max0 <= reg_param_clip_max0;
                    core_param_clip_min1 <= reg_param_clip_min1;
                    core_param_clip_max1 <= reg_param_clip_max1;
                    core_param_clip_min2 <= reg_param_clip_min2;
                    core_param_clip_max2 <= reg_param_clip_max2;
                end
            end
        end
    end


    // core
    jelly3_img_color_matrix_core
            #(
                .CH_BITS                (CH_BITS                ),
                .ch_t                   (ch_t                   ),
                .INTERNAL_BITS          (INTERNAL_BITS          ),

                .COEFF_INT_BITS         (COEFF_INT_BITS         ),
                .COEFF_FRAC_BITS        (COEFF_FRAC_BITS        ),
                .COEFF3_INT_BITS        (COEFF3_INT_BITS        ),
                .COEFF3_FRAC_BITS       (COEFF3_FRAC_BITS       ),
                .STATIC_COEFF           (STATIC_COEFF           ),
                .DEVICE                 (DEVICE                 )
            )
        u_img_color_matrix_core
            (
                .param_matrix00         (core_param_matrix00    ),
                .param_matrix01         (core_param_matrix01    ),
                .param_matrix02         (core_param_matrix02    ),
                .param_matrix03         (core_param_matrix03    ),
                .param_matrix10         (core_param_matrix10    ),
                .param_matrix11         (core_param_matrix11    ),
                .param_matrix12         (core_param_matrix12    ),
                .param_matrix13         (core_param_matrix13    ),
                .param_matrix20         (core_param_matrix20    ),
                .param_matrix21         (core_param_matrix21    ),
                .param_matrix22         (core_param_matrix22    ),
                .param_matrix23         (core_param_matrix23    ),
                .param_clip_min0        (core_param_clip_min0   ),
                .param_clip_max0        (core_param_clip_max0   ),
                .param_clip_min1        (core_param_clip_min1   ),
                .param_clip_max1        (core_param_clip_max1   ),
                .param_clip_min2        (core_param_clip_min2   ),
                .param_clip_max2        (core_param_clip_max2   ),
                .s_img                  (s_img                  ),
                .m_img                  (m_img                  )
            );


endmodule


`default_nettype wire


// end of file
