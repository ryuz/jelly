// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_hdmi_rx_decode
		#(
			parameter DVI_ONLYIN = 0
		)
		(
			input	wire			reset,
			input	wire			clk,
			
			input	wire	[9:0]	in_d,
			
			output	wire			out_de,
			output	wire	[7:0]	out_d,
			output	wire			out_c0,
			output	wire			out_c1
		);
	
	// stage 0
	wire	[9:0]		st0_d = in_d;
	
	// stage 1
	reg					st1_de;
	reg					st1_c0;
	reg					st1_c1;
	reg		[7:0]		st1_d;
	
	reg					st1_video_guard_band_c0;
	reg					st1_video_guard_band_c1;
	reg					st1_video_guard_band_c2;
	
	reg					st1_data_guard_band_c1;
	reg					st1_data_guard_band_c2;
	
	reg		[3:0]		st1_terc4;
	
	
	always @(posedge clk) begin
		if ( reset ) begin
			st1_de    <= 1'b0;
			st1_c0    <= 1'b0;
			st1_c1    <= 1'b0;
			st1_d     <= {8{1'bx}};
		end
		else begin
			// stage 1
			st1_de <= 1'b0;
			
			st1_video_guard_band_c0 <= 1'b0;
			st1_video_guard_band_c1 <= 1'b0;
			st1_video_guard_band_c2 <= 1'b0;
			
			st1_data_guard_band_c1  <= 1'b0;
			st1_data_guard_band_c2  <= 1'b0;
			
			case ( st0_d )
			10'b1101010100: {st1_c1, st1_c0} <= 2'b00;
			10'b0010101011: {st1_c1, st1_c0} <= 2'b01;
			10'b0101010100: {st1_c1, st1_c0} <= 2'b10;
			10'b1010101011: {st1_c1, st1_c0} <= 2'b11;
			
			10'b1011001100: st1_video_guard_band_c0 <= 1'b1;
			10'b0100110011: st1_video_guard_band_c1 <= 1'b1;
			10'b1011001100: st1_video_guard_band_c2 <= 1'b1;
			
			10'b0100110011: st1_data_guard_band_c1  <= 1'b1;
			10'b0100110011: st1_data_guard_band_c2  <= 1'b1;
			
			10'b1010011100: st1_terc4 <= 4'b0000;
			10'b1001100011: st1_terc4 <= 4'b0001;
			10'b1011100100: st1_terc4 <= 4'b0010;
			10'b1011100010: st1_terc4 <= 4'b0011;
			10'b0101110001: st1_terc4 <= 4'b0100;
			10'b0100011110: st1_terc4 <= 4'b0101;
			10'b0110001110: st1_terc4 <= 4'b0110;
			10'b0100111100: st1_terc4 <= 4'b0111;
			10'b1011001100: st1_terc4 <= 4'b1000;
			10'b0100111001: st1_terc4 <= 4'b1001;
			10'b0110011100: st1_terc4 <= 4'b1010;
			10'b1011000110: st1_terc4 <= 4'b1011;
			10'b1010001110: st1_terc4 <= 4'b1100;
			10'b1001110001: st1_terc4 <= 4'b1101;
			10'b0101100011: st1_terc4 <= 4'b1110;
			10'b1011000011: st1_terc4 <= 4'b1111;
			
			default:
				begin
				st1_de <= 1'b1;
				case ( st0_d[9:8] )
				2'b00 : st1_d <= ~( st0_d[7:0] ^ { st0_d[6:1], 1'b1});
				2'b01 : st1_d <=  ( st0_d[7:0] ^ { st0_d[6:1], 1'b0});
				2'b10 : st1_d <= ~(~st0_d[7:0] ^ {~st0_d[6:1], 1'b1});
				2'b11 : st1_d <=  (~st0_d[7:0] ^ {~st0_d[6:1], 1'b0});
				endcase
				end
			endcase
			
			if ( DVI_ONLYIN ) begin
				st1_video_guard_band_c0 <= 1'b0;
				st1_video_guard_band_c1 <= 1'b0;
				st1_video_guard_band_c2 <= 1'b0;
				st1_data_guard_band_c1  <= 1'b0;
				st1_data_guard_band_c2  <= 1'b0;
				st1_terc4               <= 4'b0000;
			end
		end
	end
	
	assign out_de = st1_de;
	assign out_d  = st1_d;
	assign out_c0 = st1_c0;
	assign out_c1 = st1_c1;
	
endmodule


`default_nettype wire


// end of file
