// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



//	1 to 10 serdes for xilinx 7series
module jelly_serdes_1to10_dpa_7series
		#(
			parameter	HIGH_PERFORMANCE_MODE = "FALSE",
			parameter	PIN_SWAP              = 0,
			parameter	IDELAY_VALUE_MASTE    = 0,
			parameter	IDELAY_VALUE_SLAVE    = IDELAY_VALUE_MASTE+1,
			parameter	IOSTANDARD            = "TMDS_33"
		)
		(
			input	wire			reset,
			input	wire			clk,
			input	wire			clk_x2,
			input	wire			clk_x10,
			
			input	wire			idelay_master_ce,
			input	wire			idelay_master_inc,
			input	wire			idelay_slave_ce,
			input	wire			idelay_slave_inc,
			
			input	wire			bitslip,
			
			input	wire			in_d_p,
			input	wire			in_d_n,
			
			output	wire			out_d,
			output	wire	[9:0]	out_data,
			
			output	wire			phase_valid,
			output	wire			phase_match
		);
	
	// clk_2x phase
	reg			reg_clk_x2_phase = 1'b0;
	always @(posedge clk_x2) begin
		if ( reset ) begin
			reg_clk_x2_phase <= 1'b0;
		end
		else begin
			reg_clk_x2_phase <= reg_clk_x2_phase + 1'b1;
		end
	end
	
	
	reg		[5:0]	reg_bitslip_phase = 6'b00001;
	reg				reg_bitslip;
	always @(posedge clk_x2) begin
		if ( reset ) begin
			reg_bitslip_phase <= 6'b00001;
			reg_bitslip       <= 1'b0;
		end
		else begin
			if ( reg_clk_x2_phase & bitslip ) begin
				reg_bitslip_phase <= {reg_bitslip_phase[4:0], reg_bitslip_phase[5]};
			end
			reg_bitslip <= (bitslip & reg_clk_x2_phase & |reg_bitslip_phase[4:0]);
		end
	end
	
	// 5bit to 10bit 
	wire	[4:0]		serdes_data_master;
	wire	[4:0]		serdes_data_slave;
	reg		[4:0]		reg_data0;
	reg		[4:0]		reg_data1;
	always @(posedge clk_x2) begin
		reg_data0 <= serdes_data_master;
		reg_data1 <= reg_data0;
	end
	
	reg					reg_word_sel;
	reg		[9:0]		reg_out_data;
	reg		[9:0]		reg_phase_valid;
	reg		[9:0]		reg_phase_match;
	always @(posedge clk_x2) begin
		if ( reset ) begin
			reg_word_sel    <= 1'b0;
			reg_out_data    <= {10{1'bx}};
			reg_phase_valid <= 1'b0;
		    reg_phase_match <= 1'b0;
		end
		else if ( reg_clk_x2_phase ) begin
			if ( bitslip & reg_bitslip_phase[5] ) begin
				reg_word_sel <= reg_word_sel + 1'b1;
			end
			reg_out_data    <= reg_word_sel ? {reg_data0, serdes_data_master} : {reg_data1, reg_data0};
			reg_phase_valid <= (serdes_data_master[3:0] != serdes_data_master[4:1]);
			reg_phase_match <= (serdes_data_master == serdes_data_slave);
		end
	end
	
	assign out_data    = reg_out_data;
	
	assign phase_valid = reg_phase_valid;
	assign phase_match = reg_phase_match;
	
	
	jelly_serdes_1to5_dpa_7series
			#(
				.HIGH_PERFORMANCE_MODE		(HIGH_PERFORMANCE_MODE),
				.PIN_SWAP					(PIN_SWAP),
				.IDELAY_VALUE_MASTE			(IDELAY_VALUE_MASTE),
				.IDELAY_VALUE_SLAVE			(IDELAY_VALUE_SLAVE),
				.IOSTANDARD					(IOSTANDARD)
			)
		i_serdes_1to5_dpa_7series
			(
				.reset						(reset),
				.clk						(clk_x2),
				.clk_x5						(clk_x10),
				
				.idelay_master_ce			(idelay_master_ce & reg_clk_x2_phase),
				.idelay_master_inc			(idelay_master_inc),
				.idelay_slave_ce			(idelay_slave_ce & reg_clk_x2_phase),
				.idelay_slave_inc			(idelay_slave_inc),
				
				.bitslip					(reg_bitslip),
				
				.in_d_p						(in_d_p),
				.in_d_n						(in_d_n),
				
				.out_d						(out_d),
				.out_data_master			(serdes_data_master),
				.out_data_slave				(serdes_data_slave)
			);
	
endmodule


`default_nettype wire


// end of file
