


`timescale 1ns / 1ps
`default_nettype none


module edid_rom
		(
			input	wire			clk,
			input	wire			en,
			input	wire	[6:0]	addr,
			output	wire	[7:0]	dout
		);
	
	reg		[7:0]	reg_dout;
	
	always @(posedge clk) begin
		if ( en ) begin
			case ( addr )
			7'h00:	reg_dout <= 8'h00;
			7'h01:	reg_dout <= 8'hff;
			7'h02:	reg_dout <= 8'hff;
			7'h03:	reg_dout <= 8'hff;
			7'h04:	reg_dout <= 8'hff;
			7'h05:	reg_dout <= 8'hff;
			7'h06:	reg_dout <= 8'hff;
			7'h07:	reg_dout <= 8'h00;
			7'h08:	reg_dout <= 8'h04;
			7'h09:	reg_dout <= 8'h21;
			7'h0a:	reg_dout <= 8'h00;
			7'h0b:	reg_dout <= 8'h00;
			7'h0c:	reg_dout <= 8'h39;
			7'h0d:	reg_dout <= 8'h30;
			7'h0e:	reg_dout <= 8'h00;
			7'h0f:	reg_dout <= 8'h00;
			7'h10:	reg_dout <= 8'h21;
			7'h11:	reg_dout <= 8'h19;
			7'h12:	reg_dout <= 8'h01;
			7'h13:	reg_dout <= 8'h03;
			7'h14:	reg_dout <= 8'h80;
			7'h15:	reg_dout <= 8'h00;
			7'h16:	reg_dout <= 8'h00;
			7'h17:	reg_dout <= 8'h78;
			7'h18:	reg_dout <= 8'h00;
			7'h19:	reg_dout <= 8'h00;
			7'h1a:	reg_dout <= 8'h00;
			7'h1b:	reg_dout <= 8'h00;
			7'h1c:	reg_dout <= 8'h00;
			7'h1d:	reg_dout <= 8'h00;
			7'h1e:	reg_dout <= 8'h00;
			7'h1f:	reg_dout <= 8'h00;
			7'h20:	reg_dout <= 8'h00;
			7'h21:	reg_dout <= 8'h00;
			7'h22:	reg_dout <= 8'h00;
			7'h23:	reg_dout <= 8'h21;
			7'h24:	reg_dout <= 8'h08;
			7'h25:	reg_dout <= 8'h00;
			7'h26:	reg_dout <= 8'h01;
			7'h27:	reg_dout <= 8'h00;
			7'h28:	reg_dout <= 8'h01;
			7'h29:	reg_dout <= 8'h00;
			7'h2a:	reg_dout <= 8'h01;
			7'h2b:	reg_dout <= 8'h00;
			7'h2c:	reg_dout <= 8'h01;
			7'h2d:	reg_dout <= 8'h00;
			7'h2e:	reg_dout <= 8'h01;
			7'h2f:	reg_dout <= 8'h00;
			7'h30:	reg_dout <= 8'h01;
			7'h31:	reg_dout <= 8'h00;
			7'h32:	reg_dout <= 8'h01;
			7'h33:	reg_dout <= 8'h00;
			7'h34:	reg_dout <= 8'h01;
			7'h35:	reg_dout <= 8'h00;
			7'h36:	reg_dout <= 8'hd2;
			7'h37:	reg_dout <= 8'h0a;
			7'h38:	reg_dout <= 8'hd0;
			7'h39:	reg_dout <= 8'h8a;
			7'h3a:	reg_dout <= 8'h20;
			7'h3b:	reg_dout <= 8'he0;
			7'h3c:	reg_dout <= 8'h2d;
			7'h3d:	reg_dout <= 8'h10;
			7'h3e:	reg_dout <= 8'h18;
			7'h3f:	reg_dout <= 8'h28;
			7'h40:	reg_dout <= 8'ha3;
			7'h41:	reg_dout <= 8'h00;
			7'h42:	reg_dout <= 8'hd0;
			7'h43:	reg_dout <= 8'he0;
			7'h44:	reg_dout <= 8'h21;
			7'h45:	reg_dout <= 8'h00;
			7'h46:	reg_dout <= 8'h00;
			7'h47:	reg_dout <= 8'h18;
			7'h48:	reg_dout <= 8'h00;
			7'h49:	reg_dout <= 8'h00;
			7'h4a:	reg_dout <= 8'h00;
			7'h4b:	reg_dout <= 8'h10;
			7'h4c:	reg_dout <= 8'h00;
			7'h4d:	reg_dout <= 8'h00;
			7'h4e:	reg_dout <= 8'h00;
			7'h4f:	reg_dout <= 8'h00;
			7'h50:	reg_dout <= 8'h00;
			7'h51:	reg_dout <= 8'h00;
			7'h52:	reg_dout <= 8'h00;
			7'h53:	reg_dout <= 8'h00;
			7'h54:	reg_dout <= 8'h00;
			7'h55:	reg_dout <= 8'h00;
			7'h56:	reg_dout <= 8'h00;
			7'h57:	reg_dout <= 8'h00;
			7'h58:	reg_dout <= 8'h00;
			7'h59:	reg_dout <= 8'h00;
			7'h5a:	reg_dout <= 8'h00;
			7'h5b:	reg_dout <= 8'h00;
			7'h5c:	reg_dout <= 8'h00;
			7'h5d:	reg_dout <= 8'h10;
			7'h5e:	reg_dout <= 8'h00;
			7'h5f:	reg_dout <= 8'h00;
			7'h60:	reg_dout <= 8'h00;
			7'h61:	reg_dout <= 8'h00;
			7'h62:	reg_dout <= 8'h00;
			7'h63:	reg_dout <= 8'h00;
			7'h64:	reg_dout <= 8'h00;
			7'h65:	reg_dout <= 8'h00;
			7'h66:	reg_dout <= 8'h00;
			7'h67:	reg_dout <= 8'h00;
			7'h68:	reg_dout <= 8'h00;
			7'h69:	reg_dout <= 8'h00;
			7'h6a:	reg_dout <= 8'h00;
			7'h6b:	reg_dout <= 8'h00;
			7'h6c:	reg_dout <= 8'h00;
			7'h6d:	reg_dout <= 8'h00;
			7'h6e:	reg_dout <= 8'h00;
			7'h6f:	reg_dout <= 8'h00;
			7'h70:	reg_dout <= 8'h00;
			7'h71:	reg_dout <= 8'h00;
			7'h72:	reg_dout <= 8'h00;
			7'h73:	reg_dout <= 8'h00;
			7'h74:	reg_dout <= 8'h00;
			7'h75:	reg_dout <= 8'h00;
			7'h76:	reg_dout <= 8'h00;
			7'h77:	reg_dout <= 8'h00;
			7'h78:	reg_dout <= 8'h00;
			7'h79:	reg_dout <= 8'h00;
			7'h7a:	reg_dout <= 8'h00;
			7'h7b:	reg_dout <= 8'h00;
			7'h7c:	reg_dout <= 8'h00;
			7'h7d:	reg_dout <= 8'h00;
			7'h7e:	reg_dout <= 8'h00;
			7'h7f:	reg_dout <= 8'hb2;
			endcase
		end
	end
	
	assign dout = reg_dout;
	
endmodule

`default_nettype wire


// end of file
