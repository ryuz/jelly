

`timescale 1ns / 1ps
//`default_nettype none

module mipi_dphy_0
        #(
            parameter C_DPHY_MODE = "MASTER", 
            parameter C_DPHY_LANES = 2, 
            parameter C_HS_LINE_RATE = 1250,
            parameter C_XMIT_FIRST_DESKEW_SEQ  =  "false",  
            parameter C_XMIT_PERIODIC_DESKEW_SEQ  =  "false",  
            parameter C_SKEWCAL_FIRST_TIME  =  4096,  
            parameter C_SKEWCAL_PERIODIC_TIME  =  128,
            parameter C_RCVE_DESKEW_SEQ  =  "false",  
            parameter C_LPX_PERIOD = 50,
            parameter C_STABLE_CLK_PERIOD = 5.000,
            parameter C_ESC_CLK_PERIOD = 50.000,
            parameter C_WAKEUP = 1100,
            parameter C_HS_TIMEOUT = 65541,
            parameter C_ESC_TIMEOUT = 25600,
            parameter MTBF_SYNC_STAGES = 3,
            parameter C_EN_TIMEOUT_REGS = 0,
            parameter DPHY_PRESET = "None",
            parameter SUPPORT_LEVEL = 0,
            parameter C_EN_REG_IF = 0,
            parameter C_EN_DEBUG_REGS = 0,
            parameter C_EXAMPLE_SIMULATION = "true",
            parameter C_TXPLL_CLKIN_PERIOD = 8.0,
            parameter C_DIV4_CLK_PERIOD = 6.400,     
            parameter C_CAL_MODE = "FIXED",
            parameter C_EN_EXT_TAP = "0",
            parameter C_EN_SSC = "0",
            parameter C_EN_DEBUG_TX_CALIB = "0",
            parameter C_IDLY_TAP = 0
        )
        (
       input                            core_clk,
       input                            core_rst,
       input                            txclkesc_in,
       input                            txbyteclkhs_in,
       input                            oserdes_clkdiv_in,
       input                            oserdes_clk_in,
       input                            oserdes_clk90_in,
       input                            system_rst_in,
       output                           init_done,
       output                           cl_txclkactivehs,
       input                            cl_txrequesths,
       output                           cl_stopstate,
       input                            cl_enable,
       input                            cl_txulpsclk,
       input                            cl_txulpsexit,
       output                           cl_ulpsactivenot,
       input    [7:0]                   dl0_txdatahs,
       input                            dl0_txrequesths,
       output                      reg  dl0_txreadyhs,
       input                            dl0_forcetxstopmode,
       output                           dl0_stopstate,
       input                            dl0_enable,
       input                            dl0_txrequestesc,
       input                            dl0_txlpdtesc,
       input                            dl0_txulpsexit,
       output                           dl0_ulpsactivenot,
       input                            dl0_txulpsesc,
       input    [3:0]                   dl0_txtriggeresc,
       input    [7:0]                   dl0_txdataesc,
       input                            dl0_txvalidesc,
       output                           dl0_txreadyesc,
       input    [7:0]                   dl1_txdatahs,
       input                            dl1_txrequesths,
       output                      reg  dl1_txreadyhs,
       input                            dl1_forcetxstopmode,
       output                           dl1_stopstate,
       input                            dl1_enable,
       input                            dl1_txrequestesc,
       input                            dl1_txlpdtesc,
       input                            dl1_txulpsexit,
       output                           dl1_ulpsactivenot,
       input                            dl1_txulpsesc,
       input    [3:0]                   dl1_txtriggeresc,
       input    [7:0]                   dl1_txdataesc,
       input                            dl1_txvalidesc,
       output                           dl1_txreadyesc,
       output                           clk_hs_txp,
       output                           clk_hs_txn,
       output    [C_DPHY_LANES -1:0]    data_hs_txp,
       output    [C_DPHY_LANES -1:0]    data_hs_txn,
       output                           clk_lp_txp,
       output                           clk_lp_txn,
       output    [C_DPHY_LANES -1:0]    data_lp_txp,
       output    [C_DPHY_LANES -1:0]    data_lp_txn
   );

    localparam RDY_DELAY = 5;
    logic   [RDY_DELAY-1:0] dl0_rdydly = '0;
    logic   [RDY_DELAY-1:0] dl1_rdydly = '0;
    always_ff @(posedge txbyteclkhs_in) begin
        dl0_rdydly    <= RDY_DELAY'({dl0_rdydly, dl0_txrequesths});
        dl0_txreadyhs <= dl0_rdydly[RDY_DELAY-1];
        dl1_rdydly    <= RDY_DELAY'({dl1_rdydly, dl1_txrequesths});
        dl1_txreadyhs <= dl1_rdydly[RDY_DELAY-1];
    end

    int     counter;
    always_ff @(posedge txbyteclkhs_in) begin
        if ( core_rst || system_rst_in ) begin
            counter <= '0;
        end
        else begin
            counter <= counter + 1;
        end
    end

    assign init_done = (counter > 100);

endmodule

//`default_nettype wire

// end of file
