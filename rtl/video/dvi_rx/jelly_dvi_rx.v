// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_dvi_rx
		#(
			parameter PHASE_ADJ_TH = 8 
		)
		(
			// input
			input	wire			in_reset,
			input	wire			in_clk_p,
			input	wire			in_clk_n,
			input	wire	[2:0]	in_data_p,
			input	wire	[2:0]	in_data_n,
			
			// output
			output	wire			out_clk,
			output	wire			out_reset,
			output	wire			out_vsync,
			output	wire			out_hsync,
			output	wire			out_de,
			output	wire	[23:0]	out_data,
			output	wire	[3:0]	out_ctl,
			output	wire			out_valid
		);
	
	
	// -----------------------------
	//  T.M.D.S. input
	// -----------------------------
	
	wire		serdes_clk;
	wire		serdes_data0;
	wire		serdes_data1;
	wire		serdes_data2;
	
	IBUFDS
			#(
				.IOSTANDARD	("TMDS_33")
			)
		i_ibufds_clk
			(
				.I			(in_clk_p),
				.IB			(in_clk_n),
				.O			(serdes_clk)
			);
	
	IBUFDS
			#(
				.IOSTANDARD	("TMDS_33")
			)
		i_ibufds_0
			(
				.I			(in_data_p[0]),
				.IB			(in_data_n[0]),
				.O			(serdes_data0)
			);
	
	IBUFDS
			#(
				.IOSTANDARD	("TMDS_33")
			)
		i_ibufds_1
			(
				.I			(in_data_p[1]),
				.IB			(in_data_n[1]),
				.O			(serdes_data1)
			);
	
	IBUFDS
			#(
				.IOSTANDARD	("TMDS_33")
			)
		i_ibufds_2
			(
				.I			(in_data_p[2]),
				.IB			(in_data_n[2]),
				.O			(serdes_data2)
			);
	
	
	// -----------------------------
	//  clock
	// -----------------------------
	
	wire		clkfb;
	wire		clk;
	wire		clk_x5;
	wire		clk_x5_180;
	
	wire		mmcm_clkfb;
	wire		mmcm_clk;
	wire		mmcm_clk_x5;
	wire		mmcm_clk_x5_180;

	wire		mmcm_locked;
	
	wire		mmcm_psen;
	wire		mmcm_psincdec;
	wire		mmcm_psdone;
	
	MMCME2_ADV
			#(
				.BANDWIDTH				("OPTIMIZED"),
				.CLKOUT4_CASCADE		("FALSE"),
				.COMPENSATION			("ZHOLD"),
				.STARTUP_WAIT			("FALSE"),
				.DIVCLK_DIVIDE			(1),
				.CLKFBOUT_MULT_F		(15.000),
				.CLKFBOUT_PHASE			(0.000),
				.CLKFBOUT_USE_FINE_PS	("FALSE"),
				.CLKOUT0_DIVIDE_F		(15.000),
				.CLKOUT0_PHASE			(0.000),
				.CLKOUT0_DUTY_CYCLE		(0.500),
				.CLKOUT0_USE_FINE_PS	("TRUE"),
				.CLKOUT1_DIVIDE			(3),
				.CLKOUT1_PHASE			(0.000),
				.CLKOUT1_DUTY_CYCLE		(0.500),
				.CLKOUT1_USE_FINE_PS	("TRUE"),
				.CLKOUT2_DIVIDE			(3),
				.CLKOUT2_PHASE			(180.000),
				.CLKOUT2_DUTY_CYCLE		(0.500),
				.CLKOUT2_USE_FINE_PS	("FALSE"),
				.CLKIN1_PERIOD			(13.333),
				.REF_JITTER1			(0.010)
			)
		i_mmcm_adv_inst
			(
				.CLKFBOUT				(mmcm_clkfb),
				.CLKFBOUTB				(),
				.CLKOUT0				(mmcm_clk),
				.CLKOUT0B				(),
				.CLKOUT1				(mmcm_clk_x5),
				.CLKOUT1B				(),
				.CLKOUT2				(mmcm_clk_x5_180),
				.CLKOUT2B				(),
				.CLKOUT3				(),
				.CLKOUT3B				(),
				.CLKOUT4				(),
				.CLKOUT5				(),
				.CLKOUT6				(),
				.CLKFBIN				(clkfb),
				.CLKIN1					(serdes_clk),
				.CLKIN2					(1'b0),
				.CLKINSEL				(1'b1),
				.DADDR					(7'h0),
				.DCLK					(1'b0),
				.DEN					(1'b0),
				.DI						(16'h0),
				.DO						(),
				.DRDY					(),				
				.DWE					(1'b0),
				
				.PSCLK					(clk),
				.PSEN					(mmcm_psen),
				.PSINCDEC				(mmcm_psincdec),
				.PSDONE					(mmcm_psdone),
				
				.LOCKED					(mmcm_locked),
				.CLKINSTOPPED			(),
				.CLKFBSTOPPED			(),
				.PWRDWN					(1'b0),
				.RST					(in_reset)
			);
	
	BUFG	i_bufg_clkfb		(.I(mmcm_clkfb),      .O(clkfb));
	BUFG	i_bufg_clk			(.I(mmcm_clk),        .O(clk));
	BUFG	i_bufg_clk_x5		(.I(mmcm_clk_x5),     .O(clk_x5));
	BUFG	i_bufg_clk_x5_180	(.I(mmcm_clk_x5_180), .O(clk_x5_180));
	
	reg		reg_reset;
	wire	reset_async = in_reset | !mmcm_locked;
	always @(posedge clk or posedge reset_async) begin
		if ( reset_async ) begin
			reg_reset <= 1'b1;
		end
		else begin
			reg_reset <= 1'b0;
		end
	end
	wire	reset = reg_reset;
	
	
	// -----------------------------
	//  serdes
	// -----------------------------
	
	wire	[9:0]	clk_data;
	wire	[9:0]	dec_data0;
	wire	[9:0]	dec_data1;
	wire	[9:0]	dec_data2;

	wire			sig_phase_ok   = ( (clk_data == 10'b00000_11111)
									|| (clk_data == 10'b00011_11100)
									|| (clk_data == 10'b01111_10000)
									|| (clk_data == 10'b11110_00001)
									|| (clk_data == 10'b11000_00111));

	wire			sig_bitslip_ok = (clk_data == 10'b00000_11111);

	wire			sig_psdone;
	
	reg		[3:0]	reg_psdone_dly;
	always @(posedge clk) begin
		reg_psdone_dly[0]   <= mmcm_psdone;
		reg_psdone_dly[3:1] <= reg_psdone_dly[2:0];
	end
	assign sig_psdone = reg_psdone_dly[3];
	
	
	// clock phase
	reg				reg_calib_start;
	reg				reg_setup_ok;
	reg				reg_search_ok;
	reg				reg_phase_ok;
	reg				reg_bitslip_ok;
		
	reg				reg_psen;
	reg				reg_psincdec;
	reg		[15:0]	reg_pscounter;

	reg				reg_bitslip;
	reg		[0:0]	reg_bitslip_counter;
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_calib_start     <= 1'b1;
			reg_setup_ok        <= 1'b0;
			reg_search_ok       <= 1'b0;
			reg_phase_ok        <= 1'b0;
			reg_bitslip_ok      <= 1'b0;
			
			reg_psen            <= 1'b0;
			reg_psincdec        <= 1'b0;
			reg_pscounter       <= 0;
			
			reg_bitslip         <= 1'b0;
			reg_bitslip_counter <= 1;
		end
		else begin
			reg_psen <= 1'b0;			
			if ( reg_bitslip_ok && !sig_phase_ok ) begin
				// エラー時の再スタート
				reg_calib_start <= 1'b1;
			end
			else if ( reg_calib_start ) begin
				// キャリブレーション開始
				reg_calib_start     <= 1'b0;
				reg_setup_ok        <= 1'b0;
				reg_search_ok       <= 1'b0;
				reg_phase_ok        <= 1'b0;
				reg_bitslip_ok      <= 1'b0;
				
				reg_psen            <= 1'b1;
				reg_psincdec        <= 1'b0;
				reg_pscounter       <= 0;

				reg_bitslip_ok      <= 1'b0;
				reg_bitslip         <= 1'b0;
				reg_bitslip_counter <= 1;
			end
			else if ( !reg_setup_ok ) begin
				// セットアップ(EYEの中にいたら一旦出る)
				if ( sig_psdone ) begin
					reg_psen <= 1'b1;
					if ( !sig_phase_ok ) begin
						reg_setup_ok <= 1'b1;
					end
				end
			end
			else if ( !reg_search_ok ) begin
				// EYEの範囲を探す(PHASE_ADJ_TH 以上の幅で取れる場所を探す)
				if ( sig_psdone ) begin
					reg_psen <= 1'b1;
					if ( sig_phase_ok ) begin
						reg_pscounter <= reg_pscounter + 1'b1;
					end
					else begin
						if ( reg_pscounter >= PHASE_ADJ_TH ) begin
							reg_search_ok <= 1'b1;
							reg_psincdec  <= 1'b1;
							reg_pscounter <= (reg_pscounter >> 1);
						end
						else begin
							reg_pscounter <= 0;
						end
					end
				end
			end
			else if ( !reg_phase_ok ) begin
				// EYE の中央に移動
				if ( sig_psdone ) begin
					reg_pscounter <= reg_pscounter - 1'b1;
					if ( reg_pscounter == 0 ) begin
						if ( sig_phase_ok ) begin
							reg_phase_ok <= 1'b1;
						end
						else begin
							reg_calib_start <= 1'b1;
						end
					end
					else begin
						reg_psen <= 1'b1;
					end
				end
			end
			else if ( !reg_bitslip_ok ) begin
				// 目的の配置に bitslip
				reg_bitslip <= 1'b0;
				if ( reg_bitslip_counter != 0 ) begin
					reg_bitslip_counter <= reg_bitslip_counter - 1'b1;
				end
				else begin
					if ( sig_bitslip_ok ) begin
						reg_bitslip_ok      <= 1'b0;
						reg_bitslip         <= 1'b1;
						reg_bitslip_counter <= 1;
					end
					else if ( !sig_phase_ok ) begin
						reg_calib_start <= 1'b1;
					end
				end
			end
		end
	end
	
	assign mmcm_psen     = reg_psen;
	assign mmcm_psincdec = reg_psincdec;
	
	
	
	jelly_serdes_1to10_7series
		i_serdes_1to10_clk
			(
				.reset		(reg_reset),
				.clk		(clk),
				.clk_x5		(clk_x5),
				
				.bitslip	(reg_bitslip),
				
				.in_data	(serdes_clk),
				
				.out_data	(clk_data)
			);

	
	jelly_serdes_1to10_7series
		i_serdes_1to10_0
			(
				.reset		(reg_reset),
				.clk		(clk),
				.clk_x5		(clk_x5),
				
				.bitslip	(reg_bitslip),
				
				.in_data	(serdes_data0),
				
				.out_data	(dec_data0)
			);
	
	jelly_serdes_1to10_7series
		i_serdes_1to10_1
			(
				.reset		(reg_reset),
				.clk		(clk),
				.clk_x5		(clk_x5),
				
				.bitslip	(reg_bitslip),
				
				.in_data	(serdes_data1),
				
				.out_data	(dec_data1)
			);
	
	jelly_serdes_1to10_7series
		i_serdes_1to10_2
			(
				.reset		(reg_reset),
				.clk		(clk),
				.clk_x5		(clk_x5),
				
				.bitslip	(reg_bitslip),
				
				.in_data	(serdes_data2),
				
				.out_data	(dec_data2)
			);
	
	
	/*
	// -----------------------------
	//  encode
	// -----------------------------
	
	wire	[9:0]	enc_data0;
	wire	[9:0]	enc_data1;
	wire	[9:0]	enc_data2;
	
	jelly_dvi_tx_encode
		i_dvi_tx_encode_0
			(
				.reset		(reset),
				.clk		(clk),
				
				.in_de		(in_de),
				.in_d		(in_data[7:0]),
				.in_c0		(in_hsync),
				.in_c1		(in_vsync),
				
				.out_d		(enc_data0)
			);
	
	jelly_dvi_tx_encode
		i_dvi_tx_encode_1
			(
				.reset		(reset),
				.clk		(clk),
				
				.in_de		(in_de),
				.in_d		(in_data[15:8]),
				.in_c0		(in_ctl[0]),
				.in_c1		(in_ctl[1]),
				
				.out_d		(enc_data1)
			);
	
	jelly_dvi_tx_encode
		i_dvi_tx_encode_2
			(
				.reset		(reset),
				.clk		(clk),
				
				.in_de		(in_de),
				.in_d		(in_data[23:16]),
				.in_c0		(in_ctl[2]),
				.in_c1		(in_ctl[3]),
				
				.out_d		(enc_data2)
			);
	
	*/
	
	
	
endmodule


`default_nettype wire


// end of file
