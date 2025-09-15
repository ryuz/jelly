
`timescale 1ns / 1ps
`default_nettype none

module rtcl_p3s7_dphy
        (
            input   var logic           in_clk50                ,
            input   var logic           in_clk72                ,
            output  var logic   [1:0]   led                     ,
            output  var logic   [7:0]   pmod                    ,

            output  var logic           sensor_pwr_en_vdd18     ,
            output  var logic           sensor_pwr_en_vdd33     ,
            output  var logic           sensor_pwr_en_pix       ,
            input   var logic           sensor_pgood            ,

            /*
            output  var logic           python_reset_n          ,
            output  var logic           python_clk_pll          ,
            output  var logic           python_ss_n             ,
            output  var logic           python_mosi             ,
            input   var logic           python_miso             ,
            output  var logic           python_sck              ,
            input   var logic   [2:0]   python_trigger          ,
            input   var logic   [1:0]   python_monitor          ,
            input   var logic           python_clk_p            ,
            input   var logic           python_clk_n            ,
            input   var logic   [3:0]   python_data_p           ,
            input   var logic   [3:0]   python_data_n           ,
            input   var logic           python_sync_p           ,
            input   var logic           python_sync_n           ,
            */

            input   var logic           mipi_reset_n            ,
            input   var logic           mipi_clk                ,
            inout   tri logic           mipi_scl                ,
            inout   tri logic           mipi_sda                ,
            output  var logic           mipi_clk_lp_p           ,
            output  var logic           mipi_clk_lp_n           ,
            output  var logic           mipi_clk_hs_p           ,
            output  var logic           mipi_clk_hs_n           ,
            output  var logic   [1:0]   mipi_data_lp_p          ,
            output  var logic   [1:0]   mipi_data_lp_n          ,
            output  var logic   [1:0]   mipi_data_hs_p          ,
            output  var logic   [1:0]   mipi_data_hs_n          
        );

    // ---------------------------------
    //  Clock and Reset
    // ---------------------------------

    logic clk50;
    BUFG
        u_bufg_clk50
            (
                .I  (in_clk50   ),
                .O  (clk50      )
            );

    logic clk72;
    BUFG
        u_bufg_clk72
            (
                .I  (in_clk72   ),
                .O  (clk72      )
            );


    // 初期リセット生成
    logic   [7:0]   reset_counter = '0;
    logic           reset = 1'b1;
    always_ff @(posedge clk72) begin
        if ( reset_counter == '1 ) begin
            reset <= 1'b0;
        end
        else begin
            reset_counter <= reset_counter + 1;
        end
    end


    // -------------------------------------
    //  MIPI GPIO
    // -------------------------------------

    // sensor power
    assign sensor_pwr_en_vdd18 = 1'b0;
    assign sensor_pwr_en_vdd33 = 1'b0;
    assign sensor_pwr_en_pix   = 1'b0;


    // -------------------------------------
    //  MIPI DPHY
    // -------------------------------------

    logic   dphy_core_reset          ;
    logic   dphy_core_clk            ;
    logic   dphy_system_reset        ;
    logic   dphy_txbyteclkhs_reset   ;
    logic   dphy_txbyteclkhs         ;
    logic   dphy_txclkesc            ;
    logic   dphy_oserdes_clkdiv      ;
    logic   dphy_oserdes_clk         ;
    logic   dphy_oserdes_clk90       ;

    mipi_dphy_clk_gen
        u_mipi_dphy_clk_gen
            (
                .reset              (reset                  ),
                .clk50              (clk50                  ),

                .core_reset         (dphy_core_reset        ),
                .core_clk           (dphy_core_clk          ),
                .system_reset       (dphy_system_reset      ),
                .txbyteclkhs_reset  (dphy_txbyteclkhs_reset ),
                .txbyteclkhs        (dphy_txbyteclkhs       ),
                .txclkesc           (dphy_txclkesc          ),
                .oserdes_clkdiv     (dphy_oserdes_clkdiv    ),
                .oserdes_clk        (dphy_oserdes_clk       ),
                .oserdes_clk90      (dphy_oserdes_clk90     )
            );

    // MIPI DPHY
    (* mark_debug="true" *)     logic           dphy_init_done              ;
    (* mark_debug="true" *)     logic           dphy_cl_txclkactivehs       ;
    (* mark_debug="true" *)     logic           dphy_cl_txrequesths         ;
    (* mark_debug="true" *)     logic           dphy_cl_stopstate           ;
    (* mark_debug="true" *)     logic           dphy_cl_enable              ;
 (* mark_debug="true" *)        logic           dphy_cl_txulpsclk           ;
 (* mark_debug="true" *)        logic           dphy_cl_txulpsexit          ;
 (* mark_debug="true" *)        logic           dphy_cl_ulpsactivenot       ;
    (* mark_debug="true" *)     logic   [7:0]   dphy_dl0_txdatahs           ;
    (* mark_debug="true" *)     logic           dphy_dl0_txrequesths        ;
    (* mark_debug="true" *)     logic           dphy_dl0_txreadyhs          ;
 (* mark_debug="true" *)        logic           dphy_dl0_forcetxstopmode    ;
 (* mark_debug="true" *)        logic           dphy_dl0_stopstate          ;
 (* mark_debug="true" *)        logic           dphy_dl0_enable             ;
 (* mark_debug="true" *)        logic           dphy_dl0_txrequestesc       ;
 (* mark_debug="true" *)        logic           dphy_dl0_txlpdtesc          ;
 (* mark_debug="true" *)        logic           dphy_dl0_txulpsexit         ;
 (* mark_debug="true" *)        logic           dphy_dl0_ulpsactivenot      ;
 (* mark_debug="true" *)        logic           dphy_dl0_txulpsesc          ;
 (* mark_debug="true" *)        logic   [3:0]   dphy_dl0_txtriggeresc       ;
 (* mark_debug="true" *)        logic   [7:0]   dphy_dl0_txdataesc          ;
 (* mark_debug="true" *)        logic           dphy_dl0_txvalidesc         ;
 (* mark_debug="true" *)        logic           dphy_dl0_txreadyesc         ;
    (* mark_debug="true" *)     logic   [7:0]   dphy_dl1_txdatahs           ;
    (* mark_debug="true" *)     logic           dphy_dl1_txrequesths        ;
    (* mark_debug="true" *)     logic           dphy_dl1_txreadyhs          ;
(* mark_debug="true" *)         logic           dphy_dl1_forcetxstopmode    ;
(* mark_debug="true" *)         logic           dphy_dl1_stopstate          ;
(* mark_debug="true" *)         logic           dphy_dl1_enable             ;
(* mark_debug="true" *)         logic           dphy_dl1_txrequestesc       ;
(* mark_debug="true" *)         logic           dphy_dl1_txlpdtesc          ;
(* mark_debug="true" *)         logic           dphy_dl1_txulpsexit         ;
(* mark_debug="true" *)         logic           dphy_dl1_ulpsactivenot      ;
(* mark_debug="true" *)         logic           dphy_dl1_txulpsesc          ;
(* mark_debug="true" *)         logic   [3:0]   dphy_dl1_txtriggeresc       ;
(* mark_debug="true" *)         logic   [7:0]   dphy_dl1_txdataesc          ;
(* mark_debug="true" *)         logic           dphy_dl1_txvalidesc         ;
(* mark_debug="true" *)         logic           dphy_dl1_txreadyesc         ;

    (* mark_debug="true" *)     logic           dbg_dphy_init_done          ;
    always_ff @(posedge dphy_txbyteclkhs) begin
        dbg_dphy_init_done      <= dphy_init_done     ;
    end

    mipi_dphy_0
        u_mipi_dphy_0
            (
                .core_clk               (dphy_core_clk              ),   //  input  
                .core_rst               (dphy_core_reset            ),   //  input  
                .txclkesc_in            (dphy_txclkesc              ),   //  input  
                .txbyteclkhs_in         (dphy_txbyteclkhs           ),   //  input  
                .oserdes_clkdiv_in      (dphy_oserdes_clkdiv        ),   //  input  
                .oserdes_clk_in         (dphy_oserdes_clk           ),   //  input  
                .oserdes_clk90_in       (dphy_oserdes_clk90         ),   //  input  
                .system_rst_in          (dphy_system_reset          ),   //  input  

                .init_done              (dphy_init_done             ),    // output                           
                .cl_txclkactivehs       (dphy_cl_txclkactivehs      ),    // output                           
                .cl_txrequesths         (dphy_cl_txrequesths        ),    // input                            
                .cl_stopstate           (dphy_cl_stopstate          ),    // output                           
                .cl_enable              (dphy_cl_enable             ),    // input                            
                .cl_txulpsclk           (dphy_cl_txulpsclk          ),    // input                            
                .cl_txulpsexit          (dphy_cl_txulpsexit         ),    // input                            
                .cl_ulpsactivenot       (dphy_cl_ulpsactivenot      ),    // output                           
                .dl0_txdatahs           (dphy_dl0_txdatahs          ),    // input    [7:0]                   
                .dl0_txrequesths        (dphy_dl0_txrequesths       ),    // input                            
                .dl0_txreadyhs          (dphy_dl0_txreadyhs         ),    // output                           
                .dl0_forcetxstopmode    (dphy_dl0_forcetxstopmode   ),    // input                            
                .dl0_stopstate          (dphy_dl0_stopstate         ),    // output                           
                .dl0_enable             (dphy_dl0_enable            ),    // input                            
                .dl0_txrequestesc       (dphy_dl0_txrequestesc      ),    // input                            
                .dl0_txlpdtesc          (dphy_dl0_txlpdtesc         ),    // input                            
                .dl0_txulpsexit         (dphy_dl0_txulpsexit        ),    // input                            
                .dl0_ulpsactivenot      (dphy_dl0_ulpsactivenot     ),    // output                           
                .dl0_txulpsesc          (dphy_dl0_txulpsesc         ),    // input                            
                .dl0_txtriggeresc       (dphy_dl0_txtriggeresc      ),    // input    [3:0]                   
                .dl0_txdataesc          (dphy_dl0_txdataesc         ),    // input    [7:0]                   
                .dl0_txvalidesc         (dphy_dl0_txvalidesc        ),    // input                            
                .dl0_txreadyesc         (dphy_dl0_txreadyesc        ),    // output                           
                .dl1_txdatahs           (dphy_dl1_txdatahs          ),    // input    [7:0]                   
                .dl1_txrequesths        (dphy_dl1_txrequesths       ),    // input                            
                .dl1_txreadyhs          (dphy_dl1_txreadyhs         ),    // output                           
                .dl1_forcetxstopmode    (dphy_dl1_forcetxstopmode   ),    // input                            
                .dl1_stopstate          (dphy_dl1_stopstate         ),    // output                           
                .dl1_enable             (dphy_dl1_enable            ),    // input                            
                .dl1_txrequestesc       (dphy_dl1_txrequestesc      ),    // input                            
                .dl1_txlpdtesc          (dphy_dl1_txlpdtesc         ),    // input                            
                .dl1_txulpsexit         (dphy_dl1_txulpsexit        ),    // input                            
                .dl1_ulpsactivenot      (dphy_dl1_ulpsactivenot     ),    // output                           
                .dl1_txulpsesc          (dphy_dl1_txulpsesc         ),    // input                            
                .dl1_txtriggeresc       (dphy_dl1_txtriggeresc      ),    // input    [3:0]                   
                .dl1_txdataesc          (dphy_dl1_txdataesc         ),    // input    [7:0]                   
                .dl1_txvalidesc         (dphy_dl1_txvalidesc        ),    // input                            
                .dl1_txreadyesc         (dphy_dl1_txreadyesc        ),    // output                           

                .clk_hs_txp             (mipi_clk_hs_p              ),    // output                           
                .clk_hs_txn             (mipi_clk_hs_n              ),    // output                           
                .data_hs_txp            (mipi_data_hs_p             ),    // output    [C_DPHY_LANES -1:0]    
                .data_hs_txn            (mipi_data_hs_n             ),    // output    [C_DPHY_LANES -1:0]    
                .clk_lp_txp             (mipi_clk_lp_p              ),    // output                           
                .clk_lp_txn             (mipi_clk_lp_n              ),    // output                           
                .data_lp_txp            (mipi_data_lp_p             ),    // output    [C_DPHY_LANES -1:0]    
                .data_lp_txn            (mipi_data_lp_n             )     // output    [C_DPHY_LANES -1:0]    
            );
    

//  assign dphy_cl_txrequesths      = '1    ;
    assign dphy_cl_enable           = '1    ;
    assign dphy_cl_txulpsclk        = '0    ;
    assign dphy_cl_txulpsexit       = '0    ;
//  assign dphy_dl0_txdatahs        = '0    ;
//  assign dphy_dl0_txrequesths     = '0    ;
    assign dphy_dl0_forcetxstopmode = '0    ;
    assign dphy_dl0_enable          = '1    ;
    assign dphy_dl0_txrequestesc    = '0    ;
    assign dphy_dl0_txlpdtesc       = '0    ;
    assign dphy_dl0_txulpsexit      = '0    ;
    assign dphy_dl0_txulpsesc       = '0    ;
    assign dphy_dl0_txtriggeresc    = '0    ;
    assign dphy_dl0_txdataesc       = '0    ;
    assign dphy_dl0_txvalidesc      = '0    ;
//  assign dphy_dl1_txdatahs        = '0    ;
//  assign dphy_dl1_txrequesths     = '0    ;
    assign dphy_dl1_forcetxstopmode = '0    ;
    assign dphy_dl1_enable          = '1    ;
    assign dphy_dl1_txrequestesc    = '0    ;
    assign dphy_dl1_txlpdtesc       = '0    ;
    assign dphy_dl1_txulpsexit      = '0    ;
    assign dphy_dl1_txulpsesc       = '0    ;
    assign dphy_dl1_txtriggeresc    = '0    ;
    assign dphy_dl1_txdataesc       = '0    ;
    assign dphy_dl1_txvalidesc      = '0    ;


    (* ASYNC_REG="true" *) logic  ff0_init_done, ff1_init_done;
    always_ff @(posedge dphy_txbyteclkhs) begin
        ff0_init_done <= dphy_init_done;
        ff1_init_done <= ff0_init_done;
    end

    logic [7:0]     mipi_test_count;
    always_ff @(posedge dphy_txbyteclkhs) begin
        if ( dphy_txbyteclkhs_reset || !ff1_init_done ) begin
            dphy_cl_txrequesths  <= 1'b0;
            dphy_dl0_txrequesths <= 1'b0;
            dphy_dl1_txrequesths <= 1'b0;

            dphy_dl0_txdatahs    <= '0;
            dphy_dl1_txdatahs    <= '0;

            mipi_test_count      <= '0;

        end
        else begin
            dphy_cl_txrequesths <= 1'b1;
            if ( dphy_cl_txclkactivehs ) begin
                mipi_test_count <= mipi_test_count + 1;
            end
            else begin
                mipi_test_count <= '0;
            end
//            dphy_dl0_txrequesths <= mipi_test_count[7];
//            dphy_dl1_txrequesths <= mipi_test_count[7];
            dphy_dl0_txrequesths <= 1'b1;
            dphy_dl1_txrequesths <= 1'b1;

            if ( dphy_dl0_txreadyhs ) begin
                dphy_dl0_txdatahs <= dphy_dl0_txdatahs + 1;
            end
            if ( dphy_dl1_txreadyhs ) begin
                dphy_dl1_txdatahs <= dphy_dl1_txdatahs - 1;
            end
        end
    end

    assign led  = '0;
    assign pmod = '0;

endmodule

`default_nettype wire

// end of file
