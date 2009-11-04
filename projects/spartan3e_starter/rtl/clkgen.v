// ---------------------------------------------------------------------------
//  Jelly -- The computing system for Spartan-3e Starter Kit
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


// Clock generator
module clkgen
		(
			input	wire		in_reset,
			input	wire		in_clk,
			
			output	wire		out_sys_clk,
			output	wire		out_sys_clk_x2,
			output	wire		out_sys_reset,
			
			output	wire		out_sdram_clk,
			output	wire		out_sdram_clk_90,
			output	wire		out_sdram_reset,
			
			output	wire		out_uart_clk,
			output	wire		out_uart_reset,
			
			output	wire		locked
		);
	
	
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
	wire		sys_clk_0;
	wire		sys_clk_0_bufg;
	BUFG
		i_bufg_sys_clk_0
			(
				.I		(sys_clk_0), 
				.O		(sys_clk_0_bufg)
			);
	
	// clkdv
	wire		sys_clk_dv;
	wire		sys_clk_dv_bufg;
	BUFG
		i_bufg_sys_clk_dv
			(
				.I		(sys_clk_dv), 
				.O		(sys_clk_dv_bufg)
			);

	// clk2x
	wire		sys_clk_2x;
	wire		sys_clk_2x_bufg;
	BUFG
		i_bufg_sys_clk_2x
			(
				.I		(sys_clk_2x), 
				.O		(sys_clk_2x_bufg)
			);
	
	// DCM
	wire		sys_dcm_locked;
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
				.CLKFB					(sys_clk_0_bufg), 
				.CLKIN					(in_clk_ibufg), 
				.DSSEN					(1'b0),
				.PSCLK					(1'b0), 
				.PSEN					(1'b0), 
				.PSINCDEC				(1'b0), 
				.RST					(in_reset),
				.CLKDV					(sys_clk_dv),
				.CLKFX					(), 
				.CLKFX180				(), 
				.CLK0					(sys_clk_0), 
				.CLK2X					(sys_clk_2x), 
				.CLK2X180				(), 
				.CLK90					(), 
				.CLK180					(), 
				.CLK270					(), 
				.LOCKED					(sys_dcm_locked), 
				.PSDONE					(), 
				.STATUS					()
			);
	
	// system reset
	reg		[1:0]	reg_sys_reset;
	always @( posedge sys_clk_dv_bufg or posedge in_reset ) begin
		if ( in_reset ) begin
			reg_sys_reset <= 2'b11;
		end
		else begin
			if ( !locked ) begin
				reg_sys_reset <= 2'b11;
			end
			else begin
				reg_sys_reset <= {1'b0, reg_sys_reset[1]};
			end
		end
	end
	
	
	// system clock & reset
	assign out_sys_clk    = sys_clk_0_bufg;
	assign out_sys_clk_x2 = sys_clk_2x_bufg;
	assign out_sys_reset  = reg_sys_reset[0];
	
	
	
	// -------------------------
	//  uart clock divider
	// -------------------------
	
	reg							uart_clk_dv;
	reg		[7:0]				dv_counter;
	always @ ( posedge out_sys_clk_x2 ) begin
		if ( out_sys_reset ) begin
			dv_counter  <= 0;
			uart_clk_dv <= 1'b0;
		end
		else begin
			if ( dv_counter == (54 - 1) ) begin		// 115200 bps
				dv_counter  <= 0;
				uart_clk_dv <= ~uart_clk_dv;
			end
			else begin
				dv_counter  <= dv_counter + 1;
			end
		end
	end

	assign out_uart_clk   = uart_clk_dv;
	assign out_uart_reset = out_sys_reset;
	
	
	
	// -------------------------
	//  DDR-SDRAM Clock
	// -------------------------

	// clk2x_0
	wire		sdram_clk_0;
	wire		sdram_clk_0_bufg;
	BUFG
		i_bufg_sdram_clk_0
			(
				.I		(sdram_clk_0), 
				.O		(sdram_clk_0_bufg)
			);

	// clk2x_90
	wire		sdram_clk_90;
	wire		sdram_clk_90_bufg;
	BUFG
		i_bufg_sdram_clk_90
			(
				.I		(sdram_clk_90), 
				.O		(sdram_clk_90_bufg)
			);
	
	// DCM_x2
	wire		sdram_dcm_locked;
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
		i_dcm_sdram
			(
				.CLKFB					(sdram_clk_0_bufg), 
				.CLKIN					(sys_clk_2x_bufg), 
				.DSSEN					(1'b0),
				.PSCLK					(1'b0), 
				.PSEN					(1'b0), 
				.PSINCDEC				(1'b0), 
				.RST					(in_reset | !sys_dcm_locked),
				.CLKDV					(),
				.CLKFX					(), 
				.CLKFX180				(), 
				.CLK0					(sdram_clk_0), 
				.CLK2X					(), 
				.CLK2X180				(), 
				.CLK90					(sdram_clk_90), 
				.CLK180					(), 
				.CLK270					(), 
				.LOCKED					(sdram_dcm_locked), 
				.PSDONE					(), 
				.STATUS					()
			);
	
	// sdram reset
	reg		[1:0]	reg_sdram_reset;
	always @( posedge sdram_clk_0_bufg or posedge in_reset ) begin
		if ( in_reset ) begin
			reg_sdram_reset <= 2'b11;
		end
		else begin
			if ( !locked ) begin
				reg_sdram_reset <= 2'b11;
			end
			else begin
				reg_sdram_reset <= {1'b0, reg_sdram_reset[1]};
			end
		end
	end
	
	assign out_sdram_clk    = sdram_clk_0_bufg;
	assign out_sdram_clk_90 = sdram_clk_90_bufg;
	assign out_sdram_reset  = reg_sdram_reset[0];
	
	
	assign locked = sys_dcm_locked & sdram_dcm_locked;
	
endmodule

