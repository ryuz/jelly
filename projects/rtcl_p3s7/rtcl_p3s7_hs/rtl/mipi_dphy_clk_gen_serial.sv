
`timescale 1ps/1ps
`default_nettype none

module mipi_dphy_clk_gen_serial
        (
            input   var logic   reset       ,
            input   var logic   clk_in1     ,

            jelly3_axi4l_if.s   s_axi4l     ,

            input   var logic   mmcm_rst    ,
            input   var logic   mmcm_pwrdwn ,

            output  var logic   clk_out1    ,
            output  var logic   clk_out2    ,
            output  var logic   clkfb_out   ,
            input   var logic   clkfb_in    ,
            output  var logic   locked      
        );


    (* MARK_DEBUG="true" *) logic   [6:0]   mmcm_daddr  ;
                            logic           mmcm_dclk   ;
    (* MARK_DEBUG="true" *) logic           mmcm_den    ;
    (* MARK_DEBUG="true" *) logic   [15:0]  mmcm_di     ;
    (* MARK_DEBUG="true" *) logic   [15:0]  mmcm_do     ;
    (* MARK_DEBUG="true" *) logic           mmcm_drdy   ;
    (* MARK_DEBUG="true" *) logic           mmcm_dwe    ;

    MMCME2_ADV
            #(
                .BANDWIDTH            ("OPTIMIZED"      ),
                .CLKOUT4_CASCADE      ("FALSE"          ),
                .COMPENSATION         ("ZHOLD"          ),
                .STARTUP_WAIT         ("FALSE"          ),
                .DIVCLK_DIVIDE        (1                ),
//              .CLKFBOUT_MULT_F      (19.000           ),  // 475MHz
                .CLKFBOUT_MULT_F      (25.000           ),  // 625MHz
                .CLKFBOUT_PHASE       (0.000            ),
                .CLKFBOUT_USE_FINE_PS ("FALSE"          ),
                .CLKOUT0_DIVIDE_F     (2.000            ),
                .CLKOUT0_PHASE        (0.000            ),
                .CLKOUT0_DUTY_CYCLE   (0.500            ),
                .CLKOUT0_USE_FINE_PS  ("FALSE"          ),
                .CLKOUT1_DIVIDE       (2                ),
                .CLKOUT1_PHASE        (90.000           ),
                .CLKOUT1_DUTY_CYCLE   (0.500            ),
                .CLKOUT1_USE_FINE_PS  ("FALSE"          ),
                .CLKIN1_PERIOD        (20.000           )
            )
        u_mmcm_adv
            (
                .CLKFBOUT            (clkfb_out         ),
                .CLKFBOUTB           (                  ),
                .CLKOUT0             (clk_out1          ),
                .CLKOUT0B            (                  ),
                .CLKOUT1             (clk_out2          ),
                .CLKOUT1B            (                  ),
                .CLKOUT2             (                  ),
                .CLKOUT2B            (                  ),
                .CLKOUT3             (                  ),
                .CLKOUT3B            (                  ),
                .CLKOUT4             (                  ),
                .CLKOUT5             (                  ),
                .CLKOUT6             (                  ),
                .CLKFBIN             (clkfb_in          ),
                .CLKIN1              (clk_in1           ),
                .CLKIN2              (1'b0              ),
                .CLKINSEL            (1'b1              ),
                
                .DADDR               (mmcm_daddr        ),
                .DCLK                (mmcm_dclk         ),
                .DEN                 (mmcm_den          ),
                .DI                  (mmcm_di           ),
                .DO                  (mmcm_do           ),
                .DRDY                (mmcm_drdy         ),
                .DWE                 (mmcm_dwe          ),
                
                .PSCLK               (1'b0              ),
                .PSEN                (1'b0              ),
                .PSINCDEC            (1'b0              ),
                .PSDONE              (                  ),

                .LOCKED              (locked            ),
                .CLKINSTOPPED        (                  ),
                .CLKFBSTOPPED        (                  ),
                .PWRDWN              (mmcm_pwrdwn       ),
                .RST                 (mmcm_rst | reset  )
            );

    // AXI4-Lite
    assign mmcm_dclk = s_axi4l.aclk;

    logic   drp_busy    ;
    logic   drp_write   ;
    always_ff @(posedge s_axi4l.aclk) begin
        if ( ~s_axi4l.aresetn ) begin
            s_axi4l.bvalid <= 1'b0;
            s_axi4l.rvalid <= 1'b0;
            drp_busy   <= 1'b0;
            drp_write  <= 1'b0;
            mmcm_den   <= 1'b0;
            mmcm_dwe   <= 1'b0;
            mmcm_daddr <= 'x;
            mmcm_di    <= 'x;
        end
        else if ( s_axi4l.aclken ) begin
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 1'b0;
            end
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end

            mmcm_den   <= 1'b0;
            mmcm_dwe   <= 1'b0;
            if ( s_axi4l.awvalid && s_axi4l.awready && s_axi4l.wvalid && s_axi4l.wready ) begin
                drp_busy   <= 1'b1;
                drp_write  <= 1'b1;
                mmcm_den   <= 1'b1;
                mmcm_dwe   <= 1'b1;
                mmcm_daddr <= s_axi4l.awaddr[7:1];
                mmcm_di    <= s_axi4l.wdata[15:0];
            end
            else if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                drp_busy   <= 1'b1;
                mmcm_den   <= 1'b1;
                mmcm_dwe   <= 1'b0;
                mmcm_daddr <= s_axi4l.araddr[7:1];
            end

            if ( mmcm_drdy ) begin
                drp_busy   <= 1'b0;
                drp_write  <= 1'b0;
                if ( drp_write ) begin
                    s_axi4l.bvalid <= 1'b1;
                end
                else begin
                    s_axi4l.rdata  <= mmcm_do   ;
                    s_axi4l.rvalid <= 1'b1      ;
                end
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid  && ~s_axi4l.arvalid && ~drp_busy;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid && ~s_axi4l.arvalid && ~drp_busy;
    assign s_axi4l.bresp   = '0;
    assign s_axi4l.arready = (~s_axi4l.rvalid || s_axi4l.rready) && ~drp_busy;
    assign s_axi4l.rresp   = '0;

endmodule

`default_nettype wire

// end of file
