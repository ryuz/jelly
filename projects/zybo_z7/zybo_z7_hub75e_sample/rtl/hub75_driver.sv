// ---------------------------------------------------------------------------
//  Real-time Computing Lab   PYTHON300 + Spartan-7 MIPI Camera
//
//  Copyright (C) 2025 Ryuji Fuchikami. All Rights Reserved.
//  https://rtc-lab.com/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module hub75_driver
        #(
            parameter   int             CLK_DIV          = 4                        ,
            parameter   int             N                = 2                        ,
            parameter   int             WIDTH            = 64                       ,
            parameter   int             HEIGHT           = 32                       ,
            parameter   int             DATA_BITS        = 10                       ,
            parameter   type            data_t           = logic [DATA_BITS-1:0]    ,
            parameter   int             DISP_BITS        = 16                       ,
            parameter   type            disp_t           = logic [DISP_BITS-1:0]    ,
            parameter   int             INTERVAL_BITS    = 8                        ,
            parameter   type            interval_t       = logic [INTERVAL_BITS-1:0],
            parameter   int             SEL_BITS         = $clog2(HEIGHT)           ,
            parameter   type            sel_t            = logic [SEL_BITS-1:0]     ,
            parameter   int             ADDR_BITS        = $clog2(N*HEIGHT*WIDTH)   ,
            parameter   type            addr_t           = logic [ADDR_BITS-1:0]    ,
            parameter   int             REGADR_BITS      = 8                        ,
            parameter   type            regadr_t         = logic [REGADR_BITS-1:0]  ,
            parameter                   RAM_TYPE         = "block"                  ,
            parameter   bit             READMEMB         = 0                        ,
            parameter   bit             READMEMH         = 0                        ,
            parameter                   READMEM_FILE     = ""                       ,
            parameter                   CORE_ID          = 32'h5254_2421            ,
            parameter                   CORE_VERSION     = 32'h0001_0000            ,
            parameter   bit     [0:0]   INIT_CTL_CONTROL = 1'b1                     ,
            parameter   bit     [1:0]   INIT_PARAM_FLIP  = 2'b00                    ,
            parameter   disp_t          INIT_DISP        = disp_t'(256)             ,
            parameter   disp_t          INIT_MIN_DISP    = 32                       
        )
        (
            input   var logic               reset       ,
            input   var logic               clk         ,
            output  var logic               hub75_cke   ,
            output  var logic               hub75_oe_n  ,
            output  var logic               hub75_lat   ,
            output  var sel_t               hub75_sel   ,
            output  var logic   [N-1:0]     hub75_r     ,
            output  var logic   [N-1:0]     hub75_g     ,
            output  var logic   [N-1:0]     hub75_b     ,

            input   var logic               mem_clk     ,
            input   var logic               mem_we      ,
            input   var addr_t              mem_addr    ,
            input   var data_t              mem_r       ,
            input   var data_t              mem_g       ,
            input   var data_t              mem_b       ,

            jelly3_axi4l_if.s               s_axi4l     
        );
    
    // -------------------------------------
    //  localparam
    // -------------------------------------

    localparam  int     SLOTS        = $bits(data_t)            ;
    localparam  int     DEPTH        = N * HEIGHT * WIDTH       ;

    localparam  type    axi4l_data_t = logic [s_axi4l.DATA_BITS-1:0];

    function automatic disp_t init_disp(input int slot);
        disp_t disp = INIT_DISP;
        for ( int i = SLOTS-1; i >= 0; i-- ) begin
            if ( i == slot ) begin
                if ( disp < INIT_MIN_DISP ) begin
                    return INIT_MIN_DISP;
                end
                return disp;
            end
            disp = disp / 2;
            if ( disp < INIT_MIN_DISP ) begin
                disp     = disp * 2;
            end
        end
        return disp;
    endfunction

    function automatic interval_t init_interval(input int slot);
        disp_t     disp     = INIT_DISP;
        interval_t interval = 1;
        for ( int i = SLOTS-1; i >= 0; i-- ) begin
            if ( i == slot ) begin
                return interval - 1;
            end
            disp = disp / 2;
            if ( disp < INIT_MIN_DISP ) begin
                disp     = disp * 2;
                interval = interval * 2;
            end
        end
        return interval;
    endfunction


    // -------------------------------------
    //  registers
    // -------------------------------------
    
    // register address offset
    localparam  regadr_t REGADR_CORE_ID            = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION       = regadr_t'('h01);
    localparam  regadr_t REGADR_CTL_CONTROL        = regadr_t'('h04);
    localparam  regadr_t REGADR_PARAM_FLIP         = regadr_t'('h10);
    localparam  regadr_t REGADR_PARAM_DISP         = regadr_t'('h20);
    localparam  regadr_t REGADR_PARAM_INTERVAL     = regadr_t'('h40);
    
    // registers
    logic       [0:0]           reg_ctl_control     ;
    logic       [1:0]           reg_param_flip      ;
    disp_t      [SLOTS-1:0]     reg_param_disp      ;
    interval_t  [SLOTS-1:0]     reg_param_interval  ;

    function [s_axi4l.DATA_BITS-1:0] write_mask(
                                        input [s_axi4l.DATA_BITS-1:0] org,
                                        input [s_axi4l.DATA_BITS-1:0] data,
                                        input [s_axi4l.STRB_BITS-1:0] strb
                                    );
        for ( int i = 0; i < s_axi4l.DATA_BITS; i++ ) begin
            write_mask[i] = strb[i/8] ? data[i] : org[i];
        end
    endfunction

    regadr_t  regadr_write;
    regadr_t  regadr_read;
    assign regadr_write = regadr_t'(s_axi4l.awaddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));
    assign regadr_read  = regadr_t'(s_axi4l.araddr / s_axi4l.ADDR_BITS'(s_axi4l.STRB_BITS));

    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            reg_ctl_control <= INIT_CTL_CONTROL       ;
            reg_param_flip  <= INIT_PARAM_FLIP        ;
            for ( int i = 0; i < SLOTS; i++ ) begin
//              reg_param_disp[i]     = disp_t'((2**i) * INIT_DISP);
                reg_param_disp[i]     = init_disp(i);
                reg_param_interval[i] = init_interval(i);
            end
       end
        else begin
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_CTL_CONTROL: reg_ctl_control <= 1'(write_mask(axi4l_data_t'(reg_ctl_control), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_FLIP : reg_param_flip  <= 2'(write_mask(axi4l_data_t'(reg_ctl_control), s_axi4l.wdata, s_axi4l.wstrb));
                default: ;
                endcase

                for ( int i = 0; i < SLOTS; i++ ) begin
                    if ( regadr_write == REGADR_PARAM_DISP + regadr_t'(i) ) begin
                        reg_param_disp[i] = disp_t'(write_mask(axi4l_data_t'(reg_param_disp[i]), s_axi4l.wdata, s_axi4l.wstrb));
                    end
                end
            end
        end
    end

    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            s_axi4l.bvalid <= 0;
        end
        else begin
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready ) begin
                s_axi4l.bvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;


    // read
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( s_axi4l.arvalid && s_axi4l.arready ) begin
            case ( regadr_read )
            REGADR_CORE_ID:            s_axi4l.rdata <= axi4l_data_t'(CORE_ID               );
            REGADR_CORE_VERSION:       s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION          );
            REGADR_CTL_CONTROL:        s_axi4l.rdata <= axi4l_data_t'(reg_ctl_control       );
            REGADR_PARAM_FLIP :        s_axi4l.rdata <= axi4l_data_t'(reg_param_flip        );
            default:                   s_axi4l.rdata <= '0;
            endcase
            for ( int i = 0; i < SLOTS; i++ ) begin
                if ( regadr_read == REGADR_PARAM_DISP + regadr_t'(i) ) begin
                    s_axi4l.rdata <= axi4l_data_t'(reg_param_disp[i]);
                end
            end
        end
    end

    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            s_axi4l.rvalid <= 1'b0;
        end
        else begin
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                s_axi4l.rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.arready = ~s_axi4l.rvalid || s_axi4l.rready;
    assign s_axi4l.rresp   = '0;
    

    // core
    hub75_driver_core
            #(
                .CLK_DIV        (CLK_DIV            ),
                .DISP_BITS      ($bits(disp_t)      ),
                .disp_t         (disp_t             ),
                .N              (N                  ),
                .WIDTH          (WIDTH              ),
                .HEIGHT         (HEIGHT             ),
                .SEL_BITS       ($bits(sel_t)       ),
                .sel_t          (sel_t              ),
                .DATA_BITS      ($bits(data_t)      ),
                .data_t         (data_t             ),
                .SLOTS          (SLOTS              ),
                .DEPTH          (DEPTH              ),
                .ADDR_BITS      ($bits(addr_t)      ),
                .addr_t         (addr_t             ),
                .RAM_TYPE       (RAM_TYPE           ),
                .READMEMB       (READMEMB           ),
                .READMEMH       (READMEMH           ),
                .READMEM_FILE   (READMEM_FILE       )
            )
        u_hub75_driver_core
            (
                .reset          ,
                .clk            ,
                
                .enable         (reg_ctl_control[0] ),
                .flip_h         (reg_param_flip[0]  ),
                .flip_v         (reg_param_flip[1]  ),
                .disp           (reg_param_disp     ),
                .interval       (reg_param_interval ),

                .hub75_cke      ,
                .hub75_oe_n     ,
                .hub75_lat      ,
                .hub75_sel      ,
                .hub75_r        ,
                .hub75_g        ,
                .hub75_b        ,

                .mem_clk        ,
                .mem_we         ,
                .mem_addr       ,
                .mem_r          ,
                .mem_g          ,
                .mem_b          
            );
    
    
endmodule


`default_nettype wire


// end of file
