// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module zybo_necolink_lan8720
        #(
            parameter bit DEBUG      = 1'b1,
            parameter bit SIMULATION = 1'b0
        )
        (
            input   wire            in_clk125,
            
            input   wire    [3:0]   push_sw,
            input   wire    [3:0]   dip_sw,
            output  wire    [3:0]   led,

            inout   wire    [7:0]   pmod_a,
            inout   wire    [7:0]   pmod_b,
            inout   wire    [7:0]   pmod_c,
            inout   wire    [7:0]   pmod_d,
            inout   wire    [7:0]   pmod_e,
            
            inout   wire    [14:0]  DDR_addr,
            inout   wire    [2:0]   DDR_ba,
            inout   wire            DDR_cas_n,
            inout   wire            DDR_ck_n,
            inout   wire            DDR_ck_p,
            inout   wire            DDR_cke,
            inout   wire            DDR_cs_n,
            inout   wire    [3:0]   DDR_dm,
            inout   wire    [31:0]  DDR_dq,
            inout   wire    [3:0]   DDR_dqs_n,
            inout   wire    [3:0]   DDR_dqs_p,
            inout   wire            DDR_odt,
            inout   wire            DDR_ras_n,
            inout   wire            DDR_reset_n,
            inout   wire            DDR_we_n,
            inout   wire            FIXED_IO_ddr_vrn,
            inout   wire            FIXED_IO_ddr_vrp,
            inout   wire    [53:0]  FIXED_IO_mio,
            inout   wire            FIXED_IO_ps_clk,
            inout   wire            FIXED_IO_ps_porb,
            inout   wire            FIXED_IO_ps_srstb
        );
    
    
    logic           sys_reset;
    logic           sys_clk100;
    logic           sys_clk125;
    logic           sys_clk200;
    logic           sys_clk250;

    logic           core_reset;
    logic           core_clk;
    
    design_1
        i_design_1
            (
                .in_reset               (1'b0),
                .in_clk125              (in_clk125),
                
                .out_reset              (sys_reset),
                .out_clk100             (sys_clk100),
                .out_clk125             (sys_clk125),
                .out_clk200             (sys_clk200),
                .out_clk250             (sys_clk250),

                .core_reset             (core_reset),
                .core_clk               (core_clk),

                .DDR_addr               (DDR_addr),
                .DDR_ba                 (DDR_ba),
                .DDR_cas_n              (DDR_cas_n),
                .DDR_ck_n               (DDR_ck_n),
                .DDR_ck_p               (DDR_ck_p),
                .DDR_cke                (DDR_cke),
                .DDR_cs_n               (DDR_cs_n),
                .DDR_dm                 (DDR_dm),
                .DDR_dq                 (DDR_dq),
                .DDR_dqs_n              (DDR_dqs_n),
                .DDR_dqs_p              (DDR_dqs_p),
                .DDR_odt                (DDR_odt),
                .DDR_ras_n              (DDR_ras_n),
                .DDR_reset_n            (DDR_reset_n),
                .DDR_we_n               (DDR_we_n),
                .FIXED_IO_ddr_vrn       (FIXED_IO_ddr_vrn),
                .FIXED_IO_ddr_vrp       (FIXED_IO_ddr_vrp),
                .FIXED_IO_mio           (FIXED_IO_mio),
                .FIXED_IO_ps_clk        (FIXED_IO_ps_clk),
                .FIXED_IO_ps_porb       (FIXED_IO_ps_porb),
                .FIXED_IO_ps_srstb      (FIXED_IO_ps_srstb)
            );
    
    

    // ---------------------------------
    // LAN
    // ---------------------------------

    logic   [3:0]       rmii_refclk;
    logic   [3:0]       rmii_txen;
    logic   [3:0][1:0]  rmii_tx;
    logic   [3:0][1:0]  rmii_rx;
    logic   [3:0]       rmii_crs;
    logic   [3:0]       rmii_mdc;
    logic   [3:0]       rmii_mdio_t;
    logic   [3:0]       rmii_mdio_i;
    logic   [3:0]       rmii_mdio_o;

    rmii_to_pmod
        i_rmii_to_pmod
            (
                .rmii_refclk,
                .rmii_txen,
                .rmii_tx,
                .rmii_rx,
                .rmii_crs,
                .rmii_mdc,
                .rmii_mdio_t,
                .rmii_mdio_i,
                .rmii_mdio_o,

                .pmod_a,
                .pmod_b,
                .pmod_c,
                .pmod_d,
                .pmod_e
            );

    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_rx_tfirst;
    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_rx_tlast;
    (* mark_debug="true" *) logic   [3:0][7:0]      axi4s_eth_rx_tdata;
    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_rx_tvalid;
                            logic   [3:0]           axi4s_eth_tx_tfirst;
    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_tx_tlast;
    (* mark_debug="true" *) logic   [3:0][7:0]      axi4s_eth_tx_tdata;
    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_tx_tvalid;
    (* mark_debug="true" *) logic   [3:0]           axi4s_eth_tx_tready;


    wire    aresetn = ~core_reset;
    wire    aclk    = core_clk;
    
    generate
    for ( genvar i = 0; i < 4; ++i ) begin : loop_rmii_phy
        rmii_phy
                #(
                    .DEBUG                  ("true")
                )   
            i_rmii_phy  
                (   
                    .aresetn                (aresetn),
                    .aclk                   (aclk),

                    .m_axi4s_rx_tfirst      (axi4s_eth_rx_tfirst[i]),
                    .m_axi4s_rx_tlast       (axi4s_eth_rx_tlast [i]),
                    .m_axi4s_rx_tdata       (axi4s_eth_rx_tdata [i]),
                    .m_axi4s_rx_tvalid      (axi4s_eth_rx_tvalid[i]),

                    .s_axi4s_tx_tlast       (axi4s_eth_tx_tlast [i]),
                    .s_axi4s_tx_tdata       (axi4s_eth_tx_tdata [i]),
                    .s_axi4s_tx_tvalid      (axi4s_eth_tx_tvalid[i]),
                    .s_axi4s_tx_tready      (axi4s_eth_tx_tready[i]),

                    .rmii_refclk            (rmii_refclk[i]), 
                    .rmii_txen              (rmii_txen  [i]),
                    .rmii_tx                (rmii_tx    [i]),
                    .rmii_rx                (rmii_rx    [i]),
                    .rmii_crs               (rmii_crs   [i]),
                    .rmii_mdc               (rmii_mdc   [i]),
                    .rmii_mdio_t            (rmii_mdio_t[i]),
                    .rmii_mdio_o            (rmii_mdio_o[i]),
                    .rmii_mdio_i            (rmii_mdio_i[i])
                );
    end
    endgenerate



    // core clock
//  localparam  int unsigned    CLK_NUMERATOR   = 4;    //  4ns (250MHz)
    localparam  int unsigned    CLK_NUMERATOR   = 5;    //  5ns (200MHz)
//  localparam  int unsigned    CLK_NUMERATOR   = 8;    //  8ns (125MHz)
    localparam  int unsigned    CLK_DENOMINATOR = 1;

    localparam  int unsigned    MAX_NODES               = 4;
    localparam  int unsigned    MAX_SLAVES              = MAX_NODES - 1;

    localparam  int unsigned    TIMER_WIDTH             = 64;
    localparam  int unsigned    SYNCTIM_OFFSET_LPF_GAIN = 8;
    localparam  int unsigned    SYNCTIM_LPF_GAIN_CYCLE  = 8;
    localparam  int unsigned    SYNCTIM_LPF_GAIN_PERIOD = 8;
    localparam  int unsigned    SYNCTIM_LPF_GAIN_PHASE  = 8;

    localparam  int unsigned    GPIO_GLOBAL_BYTES       = 5                         ;
    localparam  int unsigned    GPIO_LOCAL_OFFSET       = GPIO_GLOBAL_BYTES         ;
    localparam  int unsigned    GPIO_LOCAL_BYTES        = 4                         ;
    localparam  int unsigned    GPIO_FULL_BYTES         = GPIO_GLOBAL_BYTES + GPIO_LOCAL_BYTES * MAX_SLAVES;

    
    // master
    logic   [TIMER_WIDTH-1:0]                           master_current_time;

    logic                   [GPIO_GLOBAL_BYTES*8-1:0]   master_gpio_tx_global;
    logic   [MAX_SLAVES-1:0][GPIO_LOCAL_BYTES *8-1:0]   master_gpio_tx_locals;
    logic                                               master_gpio_tx_accepted;

    logic                   [GPIO_GLOBAL_BYTES*8-1:0]   master_gpio_rx_global;
    logic   [MAX_SLAVES-1:0][GPIO_LOCAL_BYTES *8-1:0]   master_gpio_rx_locals;
    logic                                               master_gpio_rx_valid;

    jelly2_necolink_master
            #(
                .MAX_NODES                  (MAX_NODES                          ),
                .TIMER_WIDTH                (TIMER_WIDTH                        ),
                .NUMERATOR                  (CLK_NUMERATOR                      ),
                .DENOMINATOR                (CLK_DENOMINATOR                    ),
                .SYNCTIM_OFFSET_LPF_GAIN    (SYNCTIM_OFFSET_LPF_GAIN            ),
                .GPIO_GLOBAL_BYTES          (GPIO_GLOBAL_BYTES                  ),
                .GPIO_LOCAL_OFFSET          (GPIO_LOCAL_OFFSET                  ),
                .GPIO_LOCAL_BYTES           (GPIO_LOCAL_BYTES                   ),
                .GPIO_FULL_BYTES            (GPIO_FULL_BYTES                    ),

                .DEBUG                      (DEBUG                              ),
                .SIMULATION                 (SIMULATION                         )
            )       
        u_necolink_master       
            (       
                .reset                      (~aresetn                           ),
                .clk                        (aclk                               ),
                .cke                        (1'b1                               ),

                .node_self                  (                                   ),
                .node_last                  (                                   ),
                .network_looped             (                                   ),

//              .synctim_force_renew        (dip_sw[0]),        
                .external_time              ('0                                 ),
                .current_time               (master_current_time                ),

                .param_mac_enable           (1'b0                               ),
                .param_set_mac_addr_self    (1'b0                               ),
                .param_set_mac_addr_up      (1'b0                               ),
                .param_mac_addr_self        (48'h00_00_0c_00_53_00              ),
                .param_mac_addr_down        (48'hff_ff_ff_ff_ff_ff              ),
                .param_mac_addr_up          (48'hff_ff_ff_ff_ff_ff              ),
                .param_mac_type_down        (16'h0000                           ),
                .param_mac_type_up          (16'h0000                           ),

                .gpio_tx_full_data          ({master_gpio_tx_locals, master_gpio_tx_global} ),
                .gpio_tx_full_accepted      (master_gpio_tx_accepted                        ),
                .m_gpio_res_full_data       ({master_gpio_rx_locals, master_gpio_rx_global} ),
                .m_gpio_res_valid           (master_gpio_rx_valid                           ),

                .s_up_rx_first              (axi4s_eth_rx_tfirst[0]             ),
                .s_up_rx_last               (axi4s_eth_rx_tlast [0]             ),
                .s_up_rx_data               (axi4s_eth_rx_tdata [0]             ),
                .s_up_rx_valid              (axi4s_eth_rx_tvalid[0]             ),
                .m_up_tx_first              (axi4s_eth_tx_tfirst[0]             ),
                .m_up_tx_last               (axi4s_eth_tx_tlast [0]             ),
                .m_up_tx_data               (axi4s_eth_tx_tdata [0]             ),
                .m_up_tx_valid              (axi4s_eth_tx_tvalid[0]             ),
                .m_up_tx_ready              (axi4s_eth_tx_tready[0]             ),

                .s_down_rx_first            (axi4s_eth_rx_tfirst[1]             ),
                .s_down_rx_last             (axi4s_eth_rx_tlast [1]             ),
                .s_down_rx_data             (axi4s_eth_rx_tdata [1]             ),
                .s_down_rx_valid            (axi4s_eth_rx_tvalid[1]             ),
                .m_down_tx_first            (axi4s_eth_tx_tfirst[1]             ),
                .m_down_tx_last             (axi4s_eth_tx_tlast [1]             ),
                .m_down_tx_data             (axi4s_eth_tx_tdata [1]             ),
                .m_down_tx_valid            (axi4s_eth_tx_tvalid[1]             ),
                .m_down_tx_ready            (axi4s_eth_tx_tready[1]             )
            );


    // パルス幅を変化させる
    logic           master_pulse_duration_dir;
    logic   [5:0]   master_pulse_duration_sub;
    logic   [15:0]  master_pulse_duration;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            master_pulse_duration_dir <= 1'b0;
            master_pulse_duration_sub <= '0;
            master_pulse_duration     <= 100;
        end
        else begin
            if ( master_gpio_tx_accepted ) begin
                if ( master_pulse_duration_dir ) begin
                    {master_pulse_duration, master_pulse_duration_sub} <= {master_pulse_duration, master_pulse_duration_sub} - 1'b1;
                end
                else begin
                    {master_pulse_duration, master_pulse_duration_sub} <= {master_pulse_duration, master_pulse_duration_sub} + 1'b1;
                end

                if ( master_pulse_duration < 100 ) begin
                    master_pulse_duration_dir <= 1'b0;
                end
                if ( master_pulse_duration > 1000 ) begin
                    master_pulse_duration_dir <= 1'b1;
                end
            end
        end
    end

    // 周期トリガ
    logic   [23:0]          master_next_time;
    logic                   master_trigger;
    timer_trigger_interval_core
            #(
                .TIME_WIDTH             (24                         )
            )
        u_timer_trigger_interval_core
            (
                .reset                  (~aresetn                   ),
                .clk                    (aclk                       ),
                .cke                    (1'b1                       ),

                .current_time           (master_current_time[23:0]  ),

                .enable                 (1'b1                       ),
                .param_interval         (24'd20000                  ),
                .param_next_time_en     (1'b0                       ),
                .param_next_time        ('0                         ),

                .out_next_time          (master_next_time           ),
                .out_trigger            (master_trigger             )
            );

    assign master_gpio_tx_global = {master_pulse_duration, master_next_time};


    logic       master_pulse;
    timer_generate_pulse_core
            #(
                .TIME_WIDTH             (24                         ),
                .DURATION_WIDTH         (16                         )
            )
        u_timer_generate_pulse_core
            (
                .reset                  (~aresetn                   ),
                .clk                    (aclk                       ),
                .cke                    (1'b1                       ),

                .current_time           (master_current_time[23:0]  ),
                .trigger                (master_trigger             ),

                .enable                 (1'b1                       ),
                .param_duration         (master_pulse_duration      ),

                .out_pulse              (master_pulse               )
            );


    // slave
    logic   [TIMER_WIDTH-1:0]           slave_current_time;

    logic   [GPIO_GLOBAL_BYTES*8-1:0]   slave_gpio_rx_global;
    logic   [GPIO_LOCAL_BYTES *8-1:0]   slave_gpio_rx_local;
    logic                               slave_gpio_rx_valid;

    jelly2_necolink_slave
            #(
                .TIMER_WIDTH                (64                         ),
                .NUMERATOR                  (CLK_NUMERATOR              ),
                .DENOMINATOR                (CLK_DENOMINATOR            ),
                .SYNCTIM_LIMIT_WIDTH        (24                         ),
                .SYNCTIM_TIMER_WIDTH        (24                         ),
                .SYNCTIM_CYCLE_WIDTH        (24                         ),
                .SYNCTIM_ERROR_WIDTH        (24                         ),
                .SYNCTIM_ERROR_Q            (8                          ),
                .SYNCTIM_ADJUST_WIDTH       (24                         ),
                .SYNCTIM_ADJUST_Q           (8                          ),
                .SYNCTIM_LPF_GAIN_CYCLE     (SYNCTIM_LPF_GAIN_CYCLE     ),
                .SYNCTIM_LPF_GAIN_PERIOD    (SYNCTIM_LPF_GAIN_PERIOD    ),
                .SYNCTIM_LPF_GAIN_PHASE     (SYNCTIM_LPF_GAIN_PHASE     ),
                .GPIO_GLOBAL_BYTES          (GPIO_GLOBAL_BYTES          ),
                .GPIO_LOCAL_OFFSET          (GPIO_LOCAL_OFFSET          ),
                .GPIO_LOCAL_BYTES           (GPIO_LOCAL_BYTES           ),
                .GPIO_FULL_BYTES            (GPIO_FULL_BYTES            ),
                .DEBUG                      (DEBUG                      ),
                .SIMULATION                 (SIMULATION                 )
            )
        u_necolink_slave
            (
                .reset                      (~aresetn                   ),
                .clk                        (aclk                       ),
                .cke                        (1'b1                       ),
                
                .timsync_adj_enable         (dip_sw[1]                  ),
                .current_time               (slave_current_time         ),

                .node_self                  (                           ),
                .node_last                  (                           ),
                .network_looped             (                           ),

                .param_mac_enable           (1'b0                       ),
                .param_set_mac_addr_self    ('0                         ),
                .param_set_mac_addr_up      ('0                         ),
                .param_set_mac_addr_down    ('0                         ),
                .param_mac_addr_self        ('0                         ),
                .param_mac_addr_down        ('0                         ),
                .param_mac_addr_up          ('0                         ),
                .param_synctim_limit_min    (-24'd100000                ), // SYNCTIM_LIMIT_WIDTH
                .param_synctim_limit_max    (+24'd100000                ), // SYNCTIM_LIMIT_WIDTH
                .param_synctim_adjust_min   (-24'd10000                 ), // SYNCTIM_ERROR_WIDTH
                .param_synctim_adjust_max   (+24'd10000                 ), // SYNCTIM_ERROR_WIDTH

                .gpio_tx_global_mask        ('0                         ),
                .gpio_tx_global_data        ('0                         ),
                .gpio_tx_local_mask         ('1                         ),
                .gpio_tx_local_data         (32'hffeeddcc               ),
                .gpio_tx_accepted           (                           ),
                .m_gpio_rx_global_data      (slave_gpio_rx_global       ),
                .m_gpio_rx_local_data       (slave_gpio_rx_local        ),
                .m_gpio_rx_valid            (slave_gpio_rx_valid        ),
                .m_gpio_res_full_data       (                           ),
                .m_gpio_res_valid           (                           ),

                .s_up_rx_first              (axi4s_eth_rx_tfirst[2]     ),
                .s_up_rx_last               (axi4s_eth_rx_tlast [2]     ),
                .s_up_rx_data               (axi4s_eth_rx_tdata [2]     ),
                .s_up_rx_valid              (axi4s_eth_rx_tvalid[2]     ),
                .m_up_tx_first              (axi4s_eth_tx_tfirst[2]     ),
                .m_up_tx_last               (axi4s_eth_tx_tlast [2]     ),
                .m_up_tx_data               (axi4s_eth_tx_tdata [2]     ),
                .m_up_tx_valid              (axi4s_eth_tx_tvalid[2]     ),
                .m_up_tx_ready              (axi4s_eth_tx_tready[2]     ),

                .s_down_rx_first            (axi4s_eth_rx_tfirst[3]     ),
                .s_down_rx_last             (axi4s_eth_rx_tlast [3]     ),
                .s_down_rx_data             (axi4s_eth_rx_tdata [3]     ),
                .s_down_rx_valid            (axi4s_eth_rx_tvalid[3]     ),
                .m_down_tx_first            (axi4s_eth_tx_tfirst[3]     ),
                .m_down_tx_last             (axi4s_eth_tx_tlast [3]     ),
                .m_down_tx_data             (axi4s_eth_tx_tdata [3]     ),
                .m_down_tx_valid            (axi4s_eth_tx_tvalid[3]     ),
                .m_down_tx_ready            (axi4s_eth_tx_tready[3]     )
            );

    logic   [15:0]      slave_pulse_duration;
    logic   [23:0]      slave_next_time;
    logic               slave_trigger;

    always_ff @(posedge aclk) begin
        if ( slave_gpio_rx_valid ) begin
            {slave_pulse_duration, slave_next_time} <= slave_gpio_rx_global;
        end
    end
    
    timer_trigger_oneshot_core
            #(
                .TIME_WIDTH             (24)
            )
        u_trigger_oneshot
            (
                .reset                  (~aresetn                   ),
                .clk                    (aclk                       ),
                .cke                    (1'b1                       ),

                .enable                 (1'b1                       ),

                .current_time           (slave_current_time[23:0]   ),
                .next_time              (slave_next_time            ),

                .out_trigger            (slave_trigger              )
        );

    logic       slave_pulse;
    timer_generate_pulse_core
            #(
                .TIME_WIDTH             (24                         ),
                .DURATION_WIDTH         (16                         )
            )
        u_timer_generate_pulse_core_slave
            (
                .reset                  (~aresetn                   ),
                .clk                    (aclk                       ),
                .cke                    (1'b1                       ),

                .current_time           (slave_current_time[23:0]   ),
                .trigger                (slave_trigger              ),

                .enable                 (1'b1                       ),
                .param_duration         (slave_pulse_duration       ),

                .out_pulse              (slave_pulse                )
            );


    // ----------------------------------------
    //  Output
    // ----------------------------------------
    
    IOBUF   i_iobuf_pmod_c4 (.IO(pmod_c[4]), .I(master_pulse           ), .O(), .T(1'b0));
    IOBUF   i_iobuf_pmod_c5 (.IO(pmod_c[5]), .I(slave_pulse            ), .O(), .T(1'b0));
    IOBUF   i_iobuf_pmod_c6 (.IO(pmod_c[6]), .I(master_current_time[10]), .O(), .T(1'b0));
    IOBUF   i_iobuf_pmod_c7 (.IO(pmod_c[7]), .I(slave_current_time [10]), .O(), .T(1'b0));

    

    // ----------------------------------------
    //  Debug
    // ----------------------------------------
    
    logic   [31:0]      reg_counter_clk200;
    always_ff @(posedge sys_clk200)         reg_counter_clk200 <= reg_counter_clk200 + 1;
    
    logic   [31:0]      reg_counter_clk100;
    always_ff @(posedge sys_clk100)         reg_counter_clk100 <= reg_counter_clk100 + 1;
    
    logic   [31:0]      reg_counter_mii0_clk;
    always_ff @(posedge rmii_refclk[0])     reg_counter_mii0_clk <= reg_counter_mii0_clk + 1;
    
    logic   [31:0]      reg_counter_mii1_clk;
    always_ff @(posedge rmii_refclk[1])     reg_counter_mii1_clk <= reg_counter_mii1_clk + 1;
    
    assign led[0] = dip_sw[0];
    assign led[1] = dip_sw[1];
    assign led[2] = reg_counter_mii0_clk[23]; 
    assign led[3] = reg_counter_mii1_clk[23];

endmodule


`default_nettype wire

