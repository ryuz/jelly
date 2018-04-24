


`timescale 1ns / 1ps
`default_nettype none


module top
		(
			input	wire			in_clk125,
			
			input	wire	[3:0]	push_sw,
			input	wire	[3:0]	dip_sw,
			output	wire	[3:0]	led,
			output	wire	[7:0]	pmod_a,
			
			input	wire			cam_clk_hs_p,
			input	wire			cam_clk_hs_n,
			input	wire			cam_clk_lp_p,
			input	wire			cam_clk_lp_n,
			input	wire	[1:0]	cam_data_hs_p,
			input	wire	[1:0]	cam_data_hs_n,
			input	wire	[1:0]	cam_data_lp_p,
			input	wire	[1:0]	cam_data_lp_n,
			input	wire			cam_clk,
			output	wire			cam_gpio,
			inout	wire			cam_scl,
			inout	wire			cam_sda,
			
			inout	wire	[14:0]	DDR_addr,
			inout	wire	[2:0]	DDR_ba,
			inout	wire			DDR_cas_n,
			inout	wire			DDR_ck_n,
			inout	wire			DDR_ck_p,
			inout	wire			DDR_cke,
			inout	wire			DDR_cs_n,
			inout	wire	[3:0]	DDR_dm,
			inout	wire	[31:0]	DDR_dq,
			inout	wire	[3:0]	DDR_dqs_n,
			inout	wire	[3:0]	DDR_dqs_p,
			inout	wire			DDR_odt,
			inout	wire			DDR_ras_n,
			inout	wire			DDR_reset_n,
			inout	wire			DDR_we_n,
			inout	wire			FIXED_IO_ddr_vrn,
			inout	wire			FIXED_IO_ddr_vrp,
			inout	wire	[53:0]	FIXED_IO_mio,
			inout	wire			FIXED_IO_ps_clk,
			inout	wire			FIXED_IO_ps_porb,
			inout	wire			FIXED_IO_ps_srstb
		);
	
	
						wire			sys_reset;
	(* KEEP = "true" *)	wire			sys_clk100;
	(* KEEP = "true" *)	wire			sys_clk200;
	
	wire			IIC_0_0_scl_i;
	wire			IIC_0_0_scl_o;
	wire			IIC_0_0_scl_t;
	wire			IIC_0_0_sda_i;
	wire			IIC_0_0_sda_o;
	wire			IIC_0_0_sda_t;
	
	design_1
		i_design_1
			(
				.sys_reset				(1'b0),
				.sys_clock				(in_clk125),
				
				.out_reset				(sys_reset),
				.out_clk100				(sys_clk100),
				.out_clk200				(sys_clk200),
				
				.DDR_addr				(DDR_addr),
				.DDR_ba					(DDR_ba),
				.DDR_cas_n				(DDR_cas_n),
				.DDR_ck_n				(DDR_ck_n),
				.DDR_ck_p				(DDR_ck_p),
				.DDR_cke				(DDR_cke),
				.DDR_cs_n				(DDR_cs_n),
				.DDR_dm					(DDR_dm),
				.DDR_dq					(DDR_dq),
				.DDR_dqs_n				(DDR_dqs_n),
				.DDR_dqs_p				(DDR_dqs_p),
				.DDR_odt				(DDR_odt),
				.DDR_ras_n				(DDR_ras_n),
				.DDR_reset_n			(DDR_reset_n),
				.DDR_we_n				(DDR_we_n),
				.FIXED_IO_ddr_vrn		(FIXED_IO_ddr_vrn),
				.FIXED_IO_ddr_vrp		(FIXED_IO_ddr_vrp),
				.FIXED_IO_mio			(FIXED_IO_mio),
				.FIXED_IO_ps_clk		(FIXED_IO_ps_clk),
				.FIXED_IO_ps_porb		(FIXED_IO_ps_porb),
				.FIXED_IO_ps_srstb		(FIXED_IO_ps_srstb),
				
				.IIC_0_0_scl_i			(IIC_0_0_scl_i),
				.IIC_0_0_scl_o			(IIC_0_0_scl_o),
				.IIC_0_0_scl_t			(IIC_0_0_scl_t),
				.IIC_0_0_sda_i			(IIC_0_0_sda_i),
				.IIC_0_0_sda_o			(IIC_0_0_sda_o),
				.IIC_0_0_sda_t			(IIC_0_0_sda_t)
			);
	
	assign cam_gpio = dip_sw[0];
	
	IOBUF
		i_IOBUF_cam_scl
			(
				.IO		(cam_scl),
				.I		(IIC_0_0_scl_o),
				.O		(IIC_0_0_scl_i),
				.T		(IIC_0_0_scl_t)
			);

	IOBUF
		i_iobuf_cam_sda
			(
				.IO		(cam_sda),
				.I		(IIC_0_0_sda_o),
				.O		(IIC_0_0_sda_i),
				.T		(IIC_0_0_sda_t)
			);
	
	
								wire				rxbyteclkhs;
	(* MARK_DEBUG = "true" *)	wire				system_rst_out;
	(* MARK_DEBUG = "true" *)	wire				init_done;
	
	(* MARK_DEBUG = "true" *)	wire				cl_rxclkactivehs;
	(* MARK_DEBUG = "true" *)	wire				cl_stopstate;
	(* MARK_DEBUG = "true" *)	wire				cl_enable         = 1;
	(* MARK_DEBUG = "true" *)	wire				cl_rxulpsclknot;
	(* MARK_DEBUG = "true" *)	wire				cl_ulpsactivenot;
	
	(* MARK_DEBUG = "true" *)	wire	[7:0]		dl0_rxdatahs;
	(* MARK_DEBUG = "true" *)	wire				dl0_rxvalidhs;
	(* MARK_DEBUG = "true" *)	wire				dl0_rxactivehs;
	(* MARK_DEBUG = "true" *)	wire				dl0_rxsynchs;
	
	(* MARK_DEBUG = "true" *)	wire				dl0_forcerxmode   = 0;
	(* MARK_DEBUG = "true" *)	wire				dl0_stopstate;
	(* MARK_DEBUG = "true" *)	wire				dl0_enable        = 1;
	(* MARK_DEBUG = "true" *)	wire				dl0_ulpsactivenot;
	
	(* MARK_DEBUG = "true" *)	wire				dl0_rxclkesc;
	(* MARK_DEBUG = "true" *)	wire				dl0_rxlpdtesc;
	(* MARK_DEBUG = "true" *)	wire				dl0_rxulpsesc;
	(* MARK_DEBUG = "true" *)	wire	[3:0]		dl0_rxtriggeresc;
	(* MARK_DEBUG = "true" *)	wire	[7:0]		dl0_rxdataesc;
	(* MARK_DEBUG = "true" *)	wire				dl0_rxvalidesc;
	
	(* MARK_DEBUG = "true" *)	wire				dl0_errsoths;
	(* MARK_DEBUG = "true" *)	wire				dl0_errsotsynchs;
	(* MARK_DEBUG = "true" *)	wire				dl0_erresc;
	(* MARK_DEBUG = "true" *)	wire				dl0_errsyncesc;
	(* MARK_DEBUG = "true" *)	wire				dl0_errcontrol;
	
	(* MARK_DEBUG = "true" *)	wire	[7:0]		dl1_rxdatahs;
	(* MARK_DEBUG = "true" *)	wire				dl1_rxvalidhs;
	(* MARK_DEBUG = "true" *)	wire				dl1_rxactivehs;
	(* MARK_DEBUG = "true" *)	wire				dl1_rxsynchs;
	
	(* MARK_DEBUG = "true" *)	wire				dl1_forcerxmode   = 0;
	(* MARK_DEBUG = "true" *)	wire				dl1_stopstate;
	(* MARK_DEBUG = "true" *)	wire				dl1_enable        = 1;
	(* MARK_DEBUG = "true" *)	wire				dl1_ulpsactivenot;
	
	(* MARK_DEBUG = "true" *)	wire				dl1_rxclkesc;
	(* MARK_DEBUG = "true" *)	wire				dl1_rxlpdtesc;
	(* MARK_DEBUG = "true" *)	wire				dl1_rxulpsesc;
	(* MARK_DEBUG = "true" *)	wire	[3:0]		dl1_rxtriggeresc;
	(* MARK_DEBUG = "true" *)	wire	[7:0]		dl1_rxdataesc;
	(* MARK_DEBUG = "true" *)	wire				dl1_rxvalidesc;
	
	(* MARK_DEBUG = "true" *)	wire				dl1_errsoths;
	(* MARK_DEBUG = "true" *)	wire				dl1_errsotsynchs;
	(* MARK_DEBUG = "true" *)	wire				dl1_erresc;
	(* MARK_DEBUG = "true" *)	wire				dl1_errsyncesc;
	(* MARK_DEBUG = "true" *)	wire				dl1_errcontrol;
	
	/*
	(* MARK_DEBUG = "true" *)	reg		[7:0]		dbg_dl0_rxdatahs;
	(* MARK_DEBUG = "true" *)	reg		[7:0]		dbg_dl0_rxdataesc;
	(* MARK_DEBUG = "true" *)	reg		[7:0]		dbg_dl1_rxdatahs;
	(* MARK_DEBUG = "true" *)	reg		[7:0]		dbg_dl1_rxdataesc;
	
	always @(posedge clk100) begin
		dbg_dl0_rxdatahs  <= dl0_rxdatahs ;
		dbg_dl0_rxdataesc <= dl0_rxdataesc;
		dbg_dl1_rxdatahs  <= dl1_rxdatahs ;
		dbg_dl1_rxdataesc <= dl1_rxdataesc;
	end
	*/
	
	
	mipi_dphy_cam
		i_mipi_dphy_cam
			(
				.core_clk			(sys_clk200),
				.core_rst			(sys_reset),
				.rxbyteclkhs		(rxbyteclkhs),
				.system_rst_out		(system_rst_out),
				.init_done			(init_done),
				
				.cl_rxclkactivehs	(cl_rxclkactivehs),
				.cl_stopstate		(cl_stopstate),
				.cl_enable			(cl_enable),
				.cl_rxulpsclknot	(cl_rxulpsclknot),
				.cl_ulpsactivenot	(cl_ulpsactivenot),
				
				.dl0_rxdatahs		(dl0_rxdatahs),
				.dl0_rxvalidhs		(dl0_rxvalidhs),
				.dl0_rxactivehs		(dl0_rxactivehs),
				.dl0_rxsynchs		(dl0_rxsynchs),
				
				.dl0_forcerxmode	(dl0_forcerxmode),
				.dl0_stopstate		(dl0_stopstate),
				.dl0_enable			(dl0_enable),
				.dl0_ulpsactivenot	(dl0_ulpsactivenot),
				
				.dl0_rxclkesc		(dl0_rxclkesc),
				.dl0_rxlpdtesc		(dl0_rxlpdtesc),
				.dl0_rxulpsesc		(dl0_rxulpsesc),
				.dl0_rxtriggeresc	(dl0_rxtriggeresc),
				.dl0_rxdataesc		(dl0_rxdataesc),
				.dl0_rxvalidesc		(dl0_rxvalidesc),
				
				.dl0_errsoths		(dl0_errsoths),
				.dl0_errsotsynchs	(dl0_errsotsynchs),
				.dl0_erresc			(dl0_erresc),
				.dl0_errsyncesc		(dl0_errsyncesc),
				.dl0_errcontrol		(dl0_errcontrol),
				
				.dl1_rxdatahs		(dl1_rxdatahs),
				.dl1_rxvalidhs		(dl1_rxvalidhs),
				.dl1_rxactivehs		(dl1_rxactivehs),
				.dl1_rxsynchs		(dl1_rxsynchs),
				
				.dl1_forcerxmode	(dl1_forcerxmode),
				.dl1_stopstate		(dl1_stopstate),
				.dl1_enable			(dl1_enable),
				.dl1_ulpsactivenot	(dl1_ulpsactivenot),
				
				.dl1_rxclkesc		(dl1_rxclkesc),
				.dl1_rxlpdtesc		(dl1_rxlpdtesc),
				.dl1_rxulpsesc		(dl1_rxulpsesc),
				.dl1_rxtriggeresc	(dl1_rxtriggeresc),
				.dl1_rxdataesc		(dl1_rxdataesc),
				.dl1_rxvalidesc		(dl1_rxvalidesc),
				
				.dl1_errsoths		(dl1_errsoths),
				.dl1_errsotsynchs	(dl1_errsotsynchs),
				.dl1_erresc			(dl1_erresc),
				.dl1_errsyncesc		(dl1_errsyncesc),
				.dl1_errcontrol		(dl1_errcontrol),
				
				.clk_hs_rxp			(cam_clk_hs_p),
				.clk_hs_rxn			(cam_clk_hs_n),
				.clk_lp_rxp			(cam_clk_lp_p),
				.clk_lp_rxn			(cam_clk_lp_n),
				.data_hs_rxp		(cam_data_hs_p),
				.data_hs_rxn		(cam_data_hs_n),
				.data_lp_rxp		(cam_data_lp_p),
				.data_lp_rxn		(cam_data_lp_n)
		   );
	
	reg		[31:0]		reg_counter_rxbyteclkhs;
	always @(posedge rxbyteclkhs)	reg_counter_rxbyteclkhs <= reg_counter_rxbyteclkhs + 1;
	
	reg		[31:0]		reg_counter_clk200;
	always @(posedge sys_clk200)	reg_counter_clk200 <= reg_counter_clk200 + 1;
	
	reg		[31:0]		reg_counter_clk100;
	always @(posedge sys_clk100)	reg_counter_clk100 <= reg_counter_clk100 + 1;
	
	assign led[0] = reg_counter_rxbyteclkhs[24];
	assign led[1] = reg_counter_clk200[24];
	assign led[2] = reg_counter_clk100[24];
	assign led[3] = cam_gpio;
	
	assign pmod_a[0]   = cam_clk;
	assign pmod_a[1]   = reg_counter_rxbyteclkhs[2];
	assign pmod_a[7:2] = 0;
	
	
	
endmodule


`default_nettype wire

