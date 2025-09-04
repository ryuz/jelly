// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

module system_control
        #(
            parameter   int             REGADR_BITS          = 8                        ,
            parameter   type            regadr_t             = logic [REGADR_BITS-1:0]  ,
  
            parameter                   CORE_ID              = 16'h527a                 ,
            parameter                   CORE_VERSION         = 16'h0100                 ,
            parameter   bit             INIT_SENSOR_ENABLE   = 1'b0                     ,
            parameter   bit             INIT_RECV_RESET      = 1'b1                     ,
            parameter   bit             INIT_ALIGN_RESET     = 1'b1                     ,
            parameter   bit [9:0]       INIT_ALIGN_PATTERN   = 10'h3a6                  ,
//          parameter   bit [10:0]      INIT_TRIM_X_START    = 11'd0                    ,
//          parameter   bit [10:0]      INIT_TRIM_X_END      = 11'd255                  ,
            parameter   bit [7:0]       INIT_CSI_DATA_TYPE   = 8'h2b                    ,
            parameter   bit [15:0]      INIT_CSI_WC          = 16'(256*5/4)             ,
            parameter   bit             INIT_DPHY_CORE_RESET = 1'b1                     ,
            parameter   bit             INIT_DPHY_SYS_RESET  = 1'b1                     
        )
        (
            jelly3_axi4l_if.s           s_axi4l             ,

            output  var logic           out_sensor_enable   ,
            input   var logic           in_sensor_ready     ,
            output  var logic           out_recv_reset      ,
            output  var logic           out_align_reset     ,
            output  var logic   [9:0]   out_align_pattern   ,
            input   var logic           in_align_done       ,
            input   var logic           in_align_error      ,
//          output  var logic   [10:0]  out_trim_x_start    ,
//          output  var logic   [10:0]  out_trim_x_end      ,
//          output  var logic   [7:0]   out_csi_data_type   ,
//          output  var logic   [15:0]  out_csi_wc          ,
            output  var logic           out_dphy_core_reset ,
            output  var logic           out_dphy_sys_reset  ,
            input   var logic           in_dphy_init_done   
        );
    
    
    // -------------------------------------
    //  registers domain
    // -------------------------------------

    // type
    localparam type axi4l_addr_t = logic [$bits(s_axi4l.awaddr)-1:0];
    localparam type axi4l_data_t = logic [$bits(s_axi4l.wdata)-1:0];
    localparam type axi4l_strb_t = logic [$bits(s_axi4l.wstrb)-1:0];

    // register address offset
    localparam  regadr_t REGADR_CORE_ID             = regadr_t'('h00);
    localparam  regadr_t REGADR_CORE_VERSION        = regadr_t'('h01);
    localparam  regadr_t REGADR_SENSOR_ENABLE       = regadr_t'('h04);
    localparam  regadr_t REGADR_SENSOR_READY        = regadr_t'('h08);
    localparam  regadr_t REGADR_RECV_RESET          = regadr_t'('h10);
    localparam  regadr_t REGADR_ALIGN_RESET         = regadr_t'('h20);
    localparam  regadr_t REGADR_ALIGN_PATTERN       = regadr_t'('h22);
    localparam  regadr_t REGADR_ALIGN_STATUS        = regadr_t'('h28);
//  localparam  regadr_t REGADR_TRIM_X_START        = regadr_t'('h30);
//  localparam  regadr_t REGADR_TRIM_X_END          = regadr_t'('h31);
//  localparam  regadr_t REGADR_CSI_DATA_TYPE       = regadr_t'('h50);
//  localparam  regadr_t REGADR_CSI_WC              = regadr_t'('h51);
    localparam  regadr_t REGADR_DPHY_CORE_RESET     = regadr_t'('h80);
    localparam  regadr_t REGADR_DPHY_SYS_RESET      = regadr_t'('h81);
    localparam  regadr_t REGADR_DPHY_INIT_DONE      = regadr_t'('h88);

    // registers
    logic           reg_sensor_enable   ;
    logic           reg_sensor_ready    ;
    logic           reg_recv_reset      ;
    logic           reg_align_reset     ;
    logic   [9:0]   reg_align_pattern   ;
    logic   [1:0]   reg_align_status    ;
//  logic   [10:0]  reg_trim_x_start    ;
//  logic   [10:0]  reg_trim_x_end      ;
//  logic   [7:0]   reg_csi_data_type   ;
//  logic   [15:0]  reg_csi_wc          ;
    logic           reg_dphy_core_reset ;
    logic           reg_dphy_sys_reset  ;
    logic           reg_dphy_init_done  ;

    always_ff @(posedge s_axi4l.aclk) begin
        reg_sensor_ready   <= in_sensor_ready;
        reg_align_status   <= {in_align_error, in_align_done};
        reg_dphy_init_done <= in_dphy_init_done;
    end

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
            reg_sensor_enable   <= INIT_SENSOR_ENABLE   ;
            reg_recv_reset      <= INIT_RECV_RESET      ;
            reg_align_reset     <= INIT_ALIGN_RESET     ;
            reg_align_pattern   <= INIT_ALIGN_PATTERN   ;
//          reg_trim_x_start    <= INIT_TRIM_X_START    ;
//          reg_trim_x_end      <= INIT_TRIM_X_END      ;
//          reg_csi_data_type   <= INIT_CSI_DATA_TYPE   ;
//          reg_csi_wc          <= INIT_CSI_WC          ;
            reg_dphy_core_reset <= INIT_DPHY_CORE_RESET ;
            reg_dphy_sys_reset  <= INIT_DPHY_SYS_RESET  ;
        end
        else begin
            // write
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                case ( regadr_write )
                REGADR_SENSOR_ENABLE        : reg_sensor_enable   <=  1'(write_mask(axi4l_data_t'(reg_sensor_enable  ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_RECV_RESET         :   reg_recv_reset      <=  1'(write_mask(axi4l_data_t'(reg_recv_reset     ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_ALIGN_RESET        :   reg_align_reset     <=  1'(write_mask(axi4l_data_t'(reg_align_reset    ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_ALIGN_PATTERN      :   reg_align_pattern   <= 10'(write_mask(axi4l_data_t'(reg_align_pattern  ), s_axi4l.wdata, s_axi4l.wstrb));
//              REGADR_TRIM_X_START       :   reg_trim_x_start    <= 11'(write_mask(axi4l_data_t'(reg_trim_x_start   ), s_axi4l.wdata, s_axi4l.wstrb));
//              REGADR_TRIM_X_END         :   reg_trim_x_end      <= 11'(write_mask(axi4l_data_t'(reg_trim_x_end     ), s_axi4l.wdata, s_axi4l.wstrb));
//              REGADR_CSI_DATA_TYPE      :   reg_csi_data_type   <=  8'(write_mask(axi4l_data_t'(reg_csi_data_type  ), s_axi4l.wdata, s_axi4l.wstrb));
//              REGADR_CSI_WC             :   reg_csi_wc          <= 16'(write_mask(axi4l_data_t'(reg_csi_wc         ), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_DPHY_CORE_RESET    :   reg_dphy_core_reset <=  1'(write_mask(axi4l_data_t'(reg_dphy_core_reset), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_DPHY_SYS_RESET     :   reg_dphy_sys_reset  <=  1'(write_mask(axi4l_data_t'(reg_dphy_sys_reset ), s_axi4l.wdata, s_axi4l.wstrb));
                default: ;
                endcase
            end
        end

        // 4の倍数に固定
//      reg_trim_x_start[1:0] <= '0;
//      reg_trim_x_end  [1:0] <= '1;
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
            REGADR_CORE_ID          :   s_axi4l.rdata <= axi4l_data_t'(CORE_ID             );
            REGADR_CORE_VERSION     :   s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION        );
            REGADR_SENSOR_ENABLE    :   s_axi4l.rdata <= axi4l_data_t'(reg_sensor_enable   );
            REGADR_SENSOR_READY     :   s_axi4l.rdata <= axi4l_data_t'(reg_sensor_ready    );
            REGADR_RECV_RESET       :   s_axi4l.rdata <= axi4l_data_t'(reg_recv_reset      );
            REGADR_ALIGN_RESET      :   s_axi4l.rdata <= axi4l_data_t'(reg_align_reset     );
            REGADR_ALIGN_PATTERN    :   s_axi4l.rdata <= axi4l_data_t'(reg_align_pattern   );
            REGADR_ALIGN_STATUS     :   s_axi4l.rdata <= axi4l_data_t'(reg_align_status    );
//          REGADR_TRIM_X_START     :   s_axi4l.rdata <= axi4l_data_t'(reg_trim_x_start    );
//          REGADR_TRIM_X_END       :   s_axi4l.rdata <= axi4l_data_t'(reg_trim_x_end      );
//          REGADR_CSI_DATA_TYPE    :   s_axi4l.rdata <= axi4l_data_t'(reg_csi_data_type   );
//          REGADR_CSI_WC           :   s_axi4l.rdata <= axi4l_data_t'(reg_csi_wc          );
            REGADR_DPHY_CORE_RESET  :   s_axi4l.rdata <= axi4l_data_t'(reg_dphy_core_reset );
            REGADR_DPHY_SYS_RESET   :   s_axi4l.rdata <= axi4l_data_t'(reg_dphy_sys_reset  );
            REGADR_DPHY_INIT_DONE   :   s_axi4l.rdata <= axi4l_data_t'(reg_dphy_init_done  );
            default                 :   s_axi4l.rdata <= '0;
            endcase
        end
    end

    logic           axi4l_rvalid;
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


    // output
    assign  out_sensor_enable   = reg_sensor_enable     ;
    assign  out_recv_reset      = reg_recv_reset        ;
    assign  out_align_reset     = reg_align_reset       ;
    assign  out_align_pattern   = reg_align_pattern     ;
//  assign  out_trim_x_start    = reg_trim_x_start      ;
//  assign  out_trim_x_end      = reg_trim_x_end        ;
//  assign  out_csi_data_type   = reg_csi_data_type     ;
//  assign  out_csi_wc          = reg_csi_wc            ;
    assign  out_dphy_core_reset = reg_dphy_core_reset   ;
    assign  out_dphy_sys_reset  = reg_dphy_sys_reset    ;

endmodule


`default_nettype wire


// end of file
