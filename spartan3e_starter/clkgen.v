// ----------------------------------------------------------------------------
//  Jelly -- The computing system for Spartan-3e Starter Kit
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami 
// ----------------------------------------------------------------------------



`timescale 1ns / 1ps


// Clock generator
module clkgen
		(
			in_reset, 
			in_clk, 
			
			out_clk,
			out_clk_x2,
			out_clk_uart,
			locked
		);

	input		in_reset;
	input		in_clk;
	
	output		out_clk;
	output		out_clk_x2;
	output		out_clk_uart;

	output		locked;
	
	
	// -------------------------
	//  Input Clock
	// -------------------------
	
	// clk_in
	wire		in_clk_ibufg;
	IBUFG
		i_ibufg_clkin
			(
				.I		(in_clk), 
				.O		(in_clk_ibufg)
			);
	
	
	
	// -------------------------
	//  System Clock
	// -------------------------
	
	// clk0
	wire		clk0;
	wire		clk0_bufg;
	BUFG
		i_bufg_clk0
			(
				.I		(clk0), 
				.O		(clk0_bufg)
			);
	
	// clkdv
	wire		clkdv;
	wire		clkdv_bufg;
	BUFG
		i_bufg_clkdv
			(
				.I		(clkdv), 
				.O		(clkdv_bufg)
			);

	// clk2x
	wire		clk2x;
	wire		clk2x_bufg;
	BUFG
		i_bufg_clk2x
			(
				.I		(clk2x), 
				.O		(clk2x_bufg)
			);
	
	// DCM
	wire		dcm_locked;
	DCM
			#(
				.CLK_FEEDBACK			("1X"),
				.CLKDV_DIVIDE			(2.0),
				.CLKFX_DIVIDE			(1),
				.CLKFX_MULTIPLY			(4),
				.CLKIN_DIVIDE_BY_2		("FALSE"),
				.CLKIN_PERIOD			(20.000),
				.CLKOUT_PHASE_SHIFT		("NONE"),
				.DESKEW_ADJUST			("SYSTEM_SYNCHRONOUS"),
				.DFS_FREQUENCY_MODE		("LOW"),
				.DLL_FREQUENCY_MODE		("LOW"),
				.DUTY_CYCLE_CORRECTION	("TRUE"),
				.FACTORY_JF				(16'h8080),
				.PHASE_SHIFT			(0),
				.STARTUP_WAIT			("FALSE")
			)
		i_dcm
			(
				.CLKFB					(clk0_bufg), 
				.CLKIN					(in_clk_ibufg), 
				.DSSEN					(1'b0),
				.PSCLK					(1'b0), 
				.PSEN					(1'b0), 
				.PSINCDEC				(1'b0), 
				.RST					(in_reset),
				.CLKDV					(clkdv),
				.CLKFX					(), 
				.CLKFX180				(), 
				.CLK0					(clk0), 
				.CLK2X					(clk2x), 
				.CLK2X180				(), 
				.CLK90					(), 
				.CLK180					(), 
				.CLK270					(), 
				.LOCKED					(dcm_locked), 
				.PSDONE					(), 
				.STATUS					()
			);

	
//	assign out_clk    = clkdv_bufg;
//	assign out_clk_x2 = clk0_bufg;

	assign out_clk      = clk0_bufg;
	assign out_clk_x2   = clk2x_bufg;
	
	assign out_clk_uart = clk0_bufg;
	
	
	
	
	// -------------------------
	//  DDR-SDRAM Clock
	// -------------------------

	// clk2x_0
	wire		clk2x_0;
	wire		clk2x_0_bufg;
	BUFG
		i_bufg_clk2x_0
			(
				.I		(clk2x_0), 
				.O		(clk2x_0_bufg)
			);

	// clk2x_90
	wire		clk2x_90;
	wire		clk2x_90_bufg;
	BUFG
		i_bufg_clk2x_90
			(
				.I		(clk2x_90), 
				.O		(clk2x_90_bufg)
			);
	
	// DCM_x2
	wire		dcm_x2_locked;
	DCM
			#(
				.CLK_FEEDBACK			("1X"),
				.CLKDV_DIVIDE			(2.0),
				.CLKFX_DIVIDE			(1),
				.CLKFX_MULTIPLY			(4),
				.CLKIN_DIVIDE_BY_2		("FALSE"),
				.CLKIN_PERIOD			(10.000),
				.CLKOUT_PHASE_SHIFT		("NONE"),
				.DESKEW_ADJUST			("SYSTEM_SYNCHRONOUS"),
				.DFS_FREQUENCY_MODE		("LOW"),
				.DLL_FREQUENCY_MODE		("LOW"),
				.DUTY_CYCLE_CORRECTION	("TRUE"),
				.FACTORY_JF				(16'h8080),
				.PHASE_SHIFT			(0),
				.STARTUP_WAIT			("FALSE")
			)
		i_dcm_x2
			(
				.CLKFB					(clk2x_0_bufg), 
				.CLKIN					(clk2x_bufg), 
				.DSSEN					(1'b0),
				.PSCLK					(1'b0), 
				.PSEN					(1'b0), 
				.PSINCDEC				(1'b0), 
				.RST					(in_reset),
				.CLKDV					(),
				.CLKFX					(), 
				.CLKFX180				(), 
				.CLK0					(clk2x_0), 
				.CLK2X					(), 
				.CLK2X180				(), 
				.CLK90					(clk2x_90), 
				.CLK180					(), 
				.CLK270					(), 
				.LOCKED					(dcm_x2_locked), 
				.PSDONE					(), 
				.STATUS					()
			);
	
	assign locked = dcm_x2_locked & dcm_locked;

	
endmodule

