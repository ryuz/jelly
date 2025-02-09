

`timescale 1ns / 1ps
`default_nettype none


module mipi_spartan7
        (
            input   var logic           in_clk72            ,
            input   var logic           in_clk50            ,
            
            inout   tri logic   [7:0]   pmod                ,

            input   var logic           python_clk_p        ,
            input   var logic           python_clk_n        ,
            input   var logic   [3:0]   python_data_p       ,
            input   var logic   [3:0]   python_data_n       ,
            input   var logic           python_sync_p       ,
            input   var logic           python_sync_n       ,
            output  var logic           python_reset_n      ,
            output  var logic           python_clk_pll      ,
            output  var logic           python_ss_n         ,
            output  var logic           python_mosi         ,
            input   var logic           python_miso         ,
            output  var logic           python_sck          ,
            output  var logic   [2:0]   python_trigger      ,
            input   var logic   [1:0]   python_monitor      ,

            output  var logic           python_pwr_en_vdd18 ,
            output  var logic           python_pwr_en_vdd33 ,
            output  var logic           python_pwr_en_pix   ,
            output  var logic           python_pgood        ,
            output  var logic           python_osc_en       ,

            input   var logic           mipi_reset_n        ,
            input   var logic           mipi_gpio           ,
            input   var logic           mipi_sck            ,
            inout   tri logic           mipi_sda            ,
            output  var logic           mipi_clk_hs_p       ,
            output  var logic           mipi_clk_hs_n       ,
            output  var logic           mipi_clk_lp_p       ,
            output  var logic           mipi_clk_lp_n       ,
            output  var logic   [1:0]   mipi_data_hs_p      ,
            output  var logic   [1:0]   mipi_data_hs_n      ,
            output  var logic   [1:0]   mipi_data_lp_p      ,
            output  var logic   [1:0]   mipi_data_lp_n      
        );

    logic      in_reset_n      ;
    assign    in_reset_n      = ~mipi_reset_n;


    // clock generate
    logic       ref_clk200;
    logic       mipi_clk;
    logic       mipi_clk_90;
    logic       mipi_clk_div;
    logic       locked;

    clk_wiz_0 
        u_clk_wiz_0 
            (
                .resetn     (in_reset_n     ),
                .clk_in1    (in_clk50       ),
                .locked     (locked         ),

                .clk_out1   (ref_clk200     ),
                .clk_out2   (mipi_clk       ),
                .clk_out3   (mipi_clk_90    ),
                .clk_out4   (mipi_clk_div   )
            );
    
    logic       idelayctrl_rdy;
    IDELAYCTRL
        u_idelayctrl
            (
                .REFCLK     (ref_clk200     ),
                .RST        (~in_reset_n    ),
                .RDY        (idelayctrl_rdy )
            );

    // PYTHON300
    assign python_clk_pll = in_clk72;

    assign python_pwr_en_vdd18 = 1'bz;
    assign python_pwr_en_vdd33 = 1'bz;
    assign python_pwr_en_pix   = 1'bz;
    assign python_pgood        = 1'bz;
    assign python_osc_en       = 1'bz;

    logic           python_rx_clk       ;
    logic [39:0]    python_rx_data      ;
    logic [9:0]     python_rx_sync      ;
    logic           python_system_clk   ;
    logic           python_inter_clk    ;

    serdes_1_to_10_idelay_ddr
            #(
                .D                      (5                  ),  // Parameter to set the number of data lines
                .REF_FREQ               (200                ),  // Parameter to set reference frequency used by idelay controller
                .HIGH_PERFORMANCE_MODE  ("FALSE"            ),  // Parameter to set HIGH_PERFORMANCE_MODE of input delays to reduce jitter
                .CLKIN_PERIOD           (6.000              ),  // clock period (ns) of input clock on clkin_p
                .DATA_FORMAT            ("PER_CLOCK"        )   // Parameter Used to determine method for mapping input parallel word to output serial words
            )
        u_serdes_1_to_10_idelay_ddr
            (
                .clkin_p                (python_clk_p       ),  // input  : Input from LVDS clock receiver pin
                .clkin_n                (python_clk_n       ),  // input  : Input from LVDS clock receiver pin
                .datain_p               ({python_sync_p, python_data_p} ),  // input  : Input from LVDS clock data pins
                .datain_n               ({python_sync_n, python_data_n} ),  // input  : Input from LVDS clock data pins
                .enable_phase_detector  (pmod[0]            ),  // input  : Enables the phase detector logic when high
                .enable_monitor         (pmod[1]            ),  // input  : Enables the eye monitoring logic when high
                .reset                  (~in_reset_n        ),  // input  : Reset line
                .bitslip                (pmod[2]            ),  // input  : Bitslip line
                .idelay_rdy             (idelayctrl_rdy     ),  // input  : input delays are ready
                .rxclk                  (python_rx_clk),  // output : Global/BUFIO rx clock network
                .system_clk             (python_system_clk),  // output : Regional clock output at parallel data rate
                .inter_clk              (python_inter_clk),  // output : Regional clock output at intermediate data rate, use for monitorin
                .rx_lckd                (                   ),  // output : MMCM locked, synchronous to system_clk
                .rx_data                ({python_rx_sync, python_rx_data}),  // output : Received Data
                .debug                  (                   ),  // output : debug info
                .bit_rate_value         (16'h0720           ),  // input  : Bit rate in Mbps, for example 16'h0585 16'h1050 ..
                .dcd_correct            (1'b0               ),  // input  : '0' = square, '1' = assume 10% DCD
                .bit_time_value         (                   ),  // output : Calculated bit time value for slave devices
                .eye_info               (                   ),  // output : eye info
                .m_delay_1hot           (                   ),  // output : Master delay control value as a one-hot vector
                .clock_sweep            (                   )   // output : clock eye info
            );

    assign pmod[4] = ^python_rx_data;

    /*
    logic           python_clk  ;
    logic   [3:0]   python_data ;
    logic   [3:0]   python_sync ;

    IBUFDS
        u_ibufds_clk
            (
                .I      (python_clk_p   ),
                .IB     (python_clk_n   ),
                .O      (python_clk     )
            );

    IBUFDS
        u_ibufds_data_0
            (
                .I      (python_data_p  [0]),
                .IB     (python_data_n  [0]),
                .O      (python_data    [0])
            );
    
    IBUFDS
        u_ibufds_data_1
            (
                .I      (python_data_p  [1]),
                .IB     (python_data_n  [1]),
                .O      (python_data    [1])
            );
        
    IBUFDS
        u_ibufds_data_2
            (
                .I      (python_data_p  [2]),
                .IB     (python_data_n  [2]),
                .O      (python_data    [2])
            );
    
    IBUFDS
        u_ibufds_data_3
            (
                .I      (python_data_p  [3]),
                .IB     (python_data_n  [3]),
                .O      (python_data    [3])
            );
    
    IBUFDS
        u_ibufds_sync
            (
                .I      (python_sync_p  ),
                .IB     (python_sync_n  ),
                .O      (python_sync    )
            );
    */


    // MIPI TX
    logic               core_clk                ;     // input    
    logic               core_rst                ;     // input 
    logic               txclkesc_in             ;     // input 
    logic               txbyteclkhs_in          ;     // input 
    logic               oserdes_clkdiv_in       ;     // input 
    logic               oserdes_clk_in          ;     // input 
    logic               oserdes_clk90_in        ;     // input 
    logic               system_rst_in           ;     // input 
    logic               init_done               ;     // output
    logic               cl_txclkactivehs        ;     // output
    logic               cl_txrequesths          ;     // input 
    logic               cl_stopstate            ;     // output
    logic               cl_enable               ;     // input 
    logic               cl_txulpsclk            ;     // input 
    logic               cl_txulpsexit           ;     // input 
    logic               cl_ulpsactivenot        ;     // output
    logic   [7:0]       dl0_txdatahs            ;     // input 
    logic               dl0_txrequesths         ;     // input 
    logic               dl0_txreadyhs           ;     // output
    logic               dl0_forcetxstopmode     ;     // input 
    logic               dl0_stopstate           ;     // output
    logic               dl0_enable              ;     // input 
    logic               dl0_txrequestesc        ;     // input 
    logic               dl0_txlpdtesc           ;     // input 
    logic               dl0_txulpsexit          ;     // input 
    logic               dl0_ulpsactivenot       ;     // output
    logic               dl0_txulpsesc           ;     // input 
    logic   [3:0]       dl0_txtriggeresc        ;     // input 
    logic   [7:0]       dl0_txdataesc           ;     // input 
    logic               dl0_txvalidesc          ;     // input 
    logic               dl0_txreadyesc          ;     // output
    logic   [7:0]       dl1_txdatahs            ;     // input 
    logic               dl1_txrequesths         ;     // input 
    logic               dl1_txreadyhs           ;     // output
    logic               dl1_forcetxstopmode     ;     // input 
    logic               dl1_stopstate           ;     // output
    logic               dl1_enable              ;     // input 
    logic               dl1_txrequestesc        ;     // input 
    logic               dl1_txlpdtesc           ;     // input 
    logic               dl1_txulpsexit          ;     // input 
    logic               dl1_ulpsactivenot       ;     // output
    logic               dl1_txulpsesc           ;     // input 
    logic   [3:0]       dl1_txtriggeresc        ;     // input 
    logic   [7:0]       dl1_txdataesc           ;     // input 
    logic               dl1_txvalidesc          ;     // input 
    logic               dl1_txreadyesc          ;     // output


    mipi_dphy_0
        u_mipi_dphy_0
            (
                .core_rst               ,
                .txclkesc_in            ,
                .txbyteclkhs_in         ,
                .oserdes_clkdiv_in      ,
                .oserdes_clk_in         ,
                .oserdes_clk90_in       ,
                .system_rst_in          ,
                .init_done              ,
                .cl_txclkactivehs       ,
                .cl_txrequesths         ,
                .cl_stopstate           ,
                .cl_enable              ,
                .cl_txulpsclk           ,
                .cl_txulpsexit          ,
                .cl_ulpsactivenot       ,
                .dl0_txdatahs           ,
                .dl0_txrequesths        ,
                .dl0_txreadyhs          ,
                .dl0_forcetxstopmode    ,
                .dl0_stopstate          ,
                .dl0_enable             ,
                .dl0_txrequestesc       ,
                .dl0_txlpdtesc          ,
                .dl0_txulpsexit         ,
                .dl0_ulpsactivenot      ,
                .dl0_txulpsesc          ,
                .dl0_txtriggeresc       ,
                .dl0_txdataesc          ,
                .dl0_txvalidesc         ,
                .dl0_txreadyesc         ,
                .dl1_txdatahs           ,
                .dl1_txrequesths        ,
                .dl1_txreadyhs          ,
                .dl1_forcetxstopmode    ,
                .dl1_stopstate          ,
                .dl1_enable             ,
                .dl1_txrequestesc       ,
                .dl1_txlpdtesc          ,
                .dl1_txulpsexit         ,
                .dl1_ulpsactivenot      ,
                .dl1_txulpsesc          ,
                .dl1_txtriggeresc       ,
                .dl1_txdataesc          ,
                .dl1_txvalidesc         ,
                .dl1_txreadyesc         ,

                .clk_hs_txp             (mipi_clk_hs_p  ),
                .clk_hs_txn             (mipi_clk_hs_n  ),
                .data_hs_txp            (mipi_data_hs_p ),
                .data_hs_txn            (mipi_data_hs_n ),
                .clk_lp_txp             (mipi_clk_lp_p  ),
                .clk_lp_txn             (mipi_clk_lp_n  ),
                .data_lp_txp            (mipi_data_lp_p ),
                .data_lp_txn            (mipi_data_lp_n )
            );

    assign core_clk          = mipi_clk_div     ;     // input    
    assign core_rst          = ~in_reset_n      ;     // input 
    assign txclkesc_in       = '0               ;     // input 
    assign txbyteclkhs_in    = mipi_clk_div     ;     // input 
    assign oserdes_clkdiv_in = mipi_clk_div     ;     // input 
    assign oserdes_clk_in    = mipi_clk         ;     // input 
    assign oserdes_clk90_in  = mipi_clk_90      ;     // input 
    assign system_rst_in     = ~in_reset_n      ;     // input 

    assign cl_txrequesths       = '0   ;     // input 
    assign cl_enable            = '1   ;     // input 
    assign cl_txulpsclk         = '0   ;     // input 
    assign cl_txulpsexit        = '0   ;     // input 
    assign dl0_txdatahs         = python_rx_data[7:0]   ;     // input 
    assign dl0_txrequesths      = '1   ;     // input 
    assign dl0_forcetxstopmode  = '0   ;     // input 
    assign dl0_enable           = '1   ;     // input 
    assign dl0_txrequestesc     = '0   ;     // input 
    assign dl0_txlpdtesc        = '0   ;     // input 
    assign dl0_txulpsexit       = '0   ;     // input 
    assign dl0_txulpsesc        = '0   ;     // input 
    assign dl0_txtriggeresc     = '0   ;     // input 
    assign dl0_txdataesc        = '0   ;     // input 
    assign dl0_txvalidesc       = '0   ;     // input 
    assign dl1_txdatahs         = python_rx_data[7:0]   ;     // input 
    assign dl1_txrequesths      = '1   ;     // input 
    assign dl1_forcetxstopmode  = '0   ;     // input 
    assign dl1_enable           = '1   ;     // input 
    assign dl1_txrequestesc     = '0   ;     // input 
    assign dl1_txlpdtesc        = '0   ;     // input 
    assign dl1_txulpsexit       = '0   ;     // input 
    assign dl1_txulpsesc        = '0   ;     // input 
    assign dl1_txtriggeresc     = '0   ;     // input 
    assign dl1_txdataesc        = '0   ;     // input 
    assign dl1_txvalidesc       = '0   ;     // input 



//       input                core_clk,
//       input                core_rst,
//       input                txclkesc_in,
//       input                txbyteclkhs_in,
//       
//       
//       
//       input                oserdes_clkdiv_in,
//       input                oserdes_clk_in,
//       input                oserdes_clk90_in,
//       
//       input                system_rst_in,
//       output               init_done,
//
//       output               cl_txclkactivehs,
//
//       //Clock lane PPI TX interface
//       input                cl_txrequesths,
//       
//       //Clock lane TX control siganls
//       output               cl_stopstate,
//       input                cl_enable,
//       input                cl_txulpsclk,
//
//       //Clock lane TX escape mode signals
//       input                cl_txulpsexit,
//       output               cl_ulpsactivenot,
//
//
//       //Data lane0 PPI TX high speed signals
//       input    [7:0]       dl0_txdatahs,
//       input                dl0_txrequesths,
//       output               dl0_txreadyhs,
//
//       //Data lane0 TX control siganls
//       input                dl0_forcetxstopmode,
//       output               dl0_stopstate,
//       input                dl0_enable,
//
//       //Data lane0 TX escape mode signals
//       input                dl0_txrequestesc,
//       input                dl0_txlpdtesc,
//       input                dl0_txulpsexit,
//       output               dl0_ulpsactivenot,
//       input                dl0_txulpsesc,
//       input    [3:0]       dl0_txtriggeresc,
//       input    [7:0]       dl0_txdataesc,
//       input                dl0_txvalidesc,
//       output               dl0_txreadyesc,
//
//       //Data lane1 PPI TX high speed signals
//       input    [7:0]       dl1_txdatahs,
//       input                dl1_txrequesths,
//       output               dl1_txreadyhs,
//
//       //Data lane1 TX control siganls
//       input                dl1_forcetxstopmode,
//       output               dl1_stopstate,
//       input                dl1_enable,
//
//       //Data lane1 TX escape mode signals
//       input                dl1_txrequestesc,
//       input                dl1_txlpdtesc,
//       input                dl1_txulpsexit,
//       output               dl1_ulpsactivenot,
//       input                dl1_txulpsesc,
//       input    [3:0]       dl1_txtriggeresc,
//       input    [7:0]       dl1_txdataesc,
//       input                dl1_txvalidesc,
//       output               dl1_txreadyesc,
//
//       //IO I/F signals for MASTER(TX)
//       output               clk_hs_txp,
//       output               clk_hs_txn,
//       output    [C_DPHY_LANES -1:0] data_hs_txp,
//       output    [C_DPHY_LANES -1:0] data_hs_txn,
//       output               clk_lp_txp,
//       output               clk_lp_txn,
//       output    [C_DPHY_LANES -1:0] data_lp_txp,
//       output    [C_DPHY_LANES -1:0] data_lp_txn


endmodule


`default_nettype wire
