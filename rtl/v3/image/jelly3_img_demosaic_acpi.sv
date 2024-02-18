// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2018 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// demosaic with ACPI
module jelly3_img_demosaic_acpi
        #(
            parameter   int             DATA_BITS        = 10                       ,
            parameter   type            data_t           = logic [DATA_BITS-1:0]    ,

            parameter   int             MAX_COLS         = 4096                     ,
            parameter                   RAM_TYPE         = "block"                  ,

            parameter   int             INDEX_BITS       = 1                        ,
            parameter   type            index_t          = logic [INDEX_BITS-1:0]   ,
            parameter   int             REGADR_BITS      = 8                        ,
            parameter   type            regadr_t         = logic [REGADR_BITS-1:0]  ,

            parameter                   CORE_ID          = 32'h527a_2110,
            parameter                   CORE_VERSION     = 32'h0001_0000,
        
            parameter   bit     [1:0]   INIT_CTL_CONTROL = 2'b01,
            parameter   bit     [1:0]   INIT_PARAM_PHASE = 2'b00
        )
        (
            
            input   wire        in_update_req,
            jelly3_img_if.s     s_img,
            jelly3_img_if.m     m_img,
            
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
    localparam  regadr_t REGADR_CURRENT_PHASE = regadr_t'('h18);
    
    // registers
    logic   [1:0]   reg_ctl_control;    // bit[0]:enable, bit[1]:update
    logic   [1:0]   reg_param_phase;
    
    // shadow registers(core domain)
    logic   [0:0]   core_ctl_control;
    logic   [1:0]   core_param_phase;
    
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
            reg_ctl_control <= INIT_CTL_CONTROL;
            reg_param_phase <= INIT_PARAM_PHASE;

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
                REGADR_CTL_CONTROL:   reg_ctl_control <= 2'(write_mask(axi4l_data_t'(reg_ctl_control), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_PHASE:   reg_param_phase <= 2'(write_mask(axi4l_data_t'(reg_param_phase), s_axi4l.wdata, s_axi4l.wstrb));
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
                REGADR_CURRENT_PHASE:  s_axi4l.rdata <= axi4l_data_t'(core_param_phase   );   // debug use only
                default: ;
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
                .INDEX_WIDTH    ($bits(index_t))
            )
        u_param_update_slave
            (
                .reset          (s_img.reset),
                .clk            (s_img.clk  ),
                .cke            (s_img.cke  ),
                
                .in_trigger     (update_trig        ),
                .in_update      (reg_ctl_control[1] ),
                
                .out_update     (update_en      ),
                .out_index      (update_index   )
            );
    
    // wait for frame start to update parameters
    logic       reg_update_req;
    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset ) begin
            reg_update_req   <= 1'b0;
            
            core_ctl_control <= 1'b0;
            core_param_phase <= INIT_PARAM_PHASE;
        end
        else begin
            if ( in_update_req ) begin
                reg_update_req <= 1'b1;
            end
            
            if ( s_img.cke ) begin
                if ( reg_update_req & update_trig & update_en ) begin
                    reg_update_req     <= 1'b0;
                    
                    core_ctl_control <= reg_ctl_control[0];
                    core_param_phase <= reg_param_phase;
                end
            end
        end
    end
    
    
    // core
    jelly3_img_demosaic_acpi_core
            #(
                .DATA_BITS      (DATA_BITS  ),
                .data_t         (data_t     ),
                .MAX_COLS       (MAX_COLS   ),
                .RAM_TYPE       (RAM_TYPE   )
            )
        u_img_demosaic_acpi_core
            (
                .param_phase    (core_param_phase   ),
                .s_img          (s_img              ),
                .m_img          (m_img              )
            );

    // assertion
    initial begin
        sva_data_bits   : assert ( DATA_BITS == s_img.DATA_BITS ) else $warning("DATA_BITS != s_img.DATA_BITS");
        sva_m_data_bits : assert ( m_img.DATA_BITS == s_img.DATA_BITS * 4) else $warning("m_img.DATA_BITS != s_img.DATA_BITS * 4");
    end
    always_comb begin
        sva_connect_reset : assert (m_img.reset === s_img.reset);
        sva_connect_clk   : assert (m_img.clk   === s_img.clk);
        sva_connect_cke   : assert (m_img.cke   === s_img.cke);
    end

endmodule


`default_nettype wire


// end of file
