// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module video_mnist_color_core
		#(
			parameter	RAW_WIDTH         = 10,
			parameter	DATA_WIDTH        = 8,
			parameter	TUSER_WIDTH       = 1,
			parameter	TNUMBER_WIDTH     = 4,
			parameter	TCOUNT_WIDTH      = 8,
			parameter	TVALIDATION_WIDTH = 8
		)
		(
			input	wire							aresetn,
			input	wire							aclk,
			
			input	wire	[1:0]					param_mode,
			input	wire	[TCOUNT_WIDTH-1:0]		param_th_count,
			input	wire	[3:0]					param_sel,
			input	wire	[TVALIDATION_WIDTH-1:0]	param_th_validation,
			
			input	wire	[TUSER_WIDTH-1:0]		s_axi4s_tuser,
			input	wire							s_axi4s_tlast,
			input	wire	[TNUMBER_WIDTH-1:0]		s_axi4s_tnumber,
			input	wire	[TCOUNT_WIDTH-1:0]		s_axi4s_tcount,
			input	wire	[RAW_WIDTH-1:0]			s_axi4s_traw,
			input	wire	[1*DATA_WIDTH-1:0]		s_axi4s_tgray,
			input	wire	[3*DATA_WIDTH-1:0]		s_axi4s_trgb,
			input	wire	[0:0]					s_axi4s_tbinary,
			input	wire	[TVALIDATION_WIDTH-1:0]	s_axi4s_tvalidation,
			input	wire							s_axi4s_tvalid,
			output	wire							s_axi4s_tready,
			
			output	wire	[TUSER_WIDTH-1:0]		m_axi4s_tuser,
			output	wire							m_axi4s_tlast,
			output	wire	[3*DATA_WIDTH-1:0]		m_axi4s_tdata,
			output	wire							m_axi4s_tvalid,
			input	wire							m_axi4s_tready
		);
	
	localparam TDATA_WIDTH = 3*DATA_WIDTH;
	
	
	reg		[TUSER_WIDTH-1:0]		st0_user;
	reg								st0_last;
	reg		[TDATA_WIDTH-1:0]		st0_data;
	reg								st0_en;
	reg		[23:0]					st0_color;
	reg								st0_valid;
	
	reg		[TUSER_WIDTH-1:0]		st1_user;
	reg								st1_last;
	reg		[TDATA_WIDTH-1:0]		st1_data;
	reg								st1_valid;
	
	always @(posedge aclk) begin
		if ( ~aresetn ) begin
			st0_user   <= {TUSER_WIDTH{1'bx}};
			st0_last   <= 1'bx;
			st0_data   <= {TDATA_WIDTH{1'bx}};
			st0_en     <= 1'bx;
			st0_color  <= 24'hxx_xx_xx;
			st0_valid  <= 1'b0;
			
			st1_user   <= {TUSER_WIDTH{1'bx}};
			st1_last   <= 1'bx;
			st1_data   <= {TDATA_WIDTH{1'bx}};
			st1_valid  <= 1'b0;
		end
		else if ( s_axi4s_tready ) begin
			// stage0
			st0_user   <= s_axi4s_tuser;
			st0_last   <= s_axi4s_tlast;
			
			case ( param_sel )
			4'd0: 		st0_data <= s_axi4s_trgb;
			4'd1: 		st0_data <= {TDATA_WIDTH{s_axi4s_tvalidation}};
			4'd2: 		st0_data <= {TDATA_WIDTH{s_axi4s_tbinary}};
			4'd3: 		st0_data <= {3{s_axi4s_tgray}};
			4'd4: 		st0_data <= {3{s_axi4s_traw[9:2]}};
			4'd5: 		st0_data <= s_axi4s_traw;
			4'd6: 		st0_data <= {TDATA_WIDTH{1'b0}};
			4'd7: 		st0_data <= {TDATA_WIDTH{1'b1}};
			4'd8: 		st0_data <= 24'h00_40_00;
			4'd9: 		st0_data <= 24'h00_00_40;
			4'd10: 		st0_data <= 24'h40_00_00;
			4'd11: 		st0_data <= 24'h40_40_40;
			default:	st0_data <= s_axi4s_trgb;
			endcase
			
			st0_en <= ((s_axi4s_tnumber < 10) && (s_axi4s_tcount >= param_th_count) && ((s_axi4s_tvalidation >= param_th_validation) || ~param_mode[1]));
			case ( s_axi4s_tnumber )
			4'd0:		st0_color <= 24'h00_00_00;	// •
			4'd1:		st0_color <= 24'h00_00_80;	// ’ƒ
			4'd2:		st0_color <= 24'h00_00_ff;	// Ô
			4'd3:		st0_color <= 24'h4c_b7_ff;	// žò
			4'd4:		st0_color <= 24'h00_ff_ff;	// ‰©
			4'd5:		st0_color <= 24'h00_80_00;	// —Î
			4'd6:		st0_color <= 24'hff_00_00;	// Â
			4'd7:		st0_color <= 24'h80_00_80;	// Ž‡
			4'd8:		st0_color <= 24'h80_80_80;	// ŠD
			4'd9:		st0_color <= 24'hff_ff_ff;	// ”’
			default:	st0_color <= 24'hxx_xx_xx;
			endcase
			st0_valid  <= s_axi4s_tvalid;
			
			// stage2
			st1_user   <= st0_user;
			st1_last   <= st0_last;
			st1_data   <= st0_data;
			if ( param_mode[0] && st0_en ) begin
				st1_data <= {st0_color[7:0], st0_color[15:8], st0_color[23:16]};
			end
			st1_valid  <= st0_valid;
		end
	end
	
	assign s_axi4s_tready = (m_axi4s_tready || !m_axi4s_tvalid);
	
	assign m_axi4s_tuser  = st1_user;
	assign m_axi4s_tlast  = st1_last;
	assign m_axi4s_tdata  = st1_data;
	assign m_axi4s_tvalid = st1_valid;
	
endmodule



`default_nettype wire



// end of file
