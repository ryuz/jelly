// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



//  DVI transmitter
module jelly_vout_axi4s
		#(
			parameter	WIDTH = 24
		)
		(
			input	wire				reset,
			input	wire				clk,
			
			// slave AXI4-Stream (input)
			input	wire	[0:0]		s_axi4s_tuser,
			input	wire				s_axi4s_tlast,
			input	wire	[WIDTH-1:0]	s_axi4s_tdata,
			input	wire				s_axi4s_tvalid,
			output	wire				s_axi4s_tready,
			
			// input timing
			input	wire				in_vsync,
			input	wire				in_hsync,
			input	wire				in_de,
			input	wire	[WIDTH-1:0]	in_data,
			input	wire	[3:0]		in_ctl,
			
			// output
			output	wire				out_vsync,
			output	wire				out_hsync,
			output	wire				out_de,
			output	wire	[WIDTH-1:0]	out_data,
			output	wire	[3:0]		out_ctl
		);
	
	localparam	[1:0]	ST_WAIT_AXI4S_FS = 0, ST_WAIT_VIDEO_FS = 1, ST_BUSY = 2;
	
	reg		[1:0]		reg_state;
	
	reg					reg_flag_fe;
	
	reg					reg_vsync;
	reg					reg_hsync;
	reg					reg_de;
	reg		[WIDTH-1:0]	reg_data;
	reg		[3:0]		reg_ctl;
	reg					reg_tuser;
	
	reg					reg_tready;
	
	wire				sig_frame_start = (reg_flag_fe & in_de);
	wire				sig_frame_end   = reg_flag_fe;
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_state   <= ST_WAIT_AXI4S_FS;
			reg_flag_fe <= 1'b0;
			
			reg_vsync   <= 1'b0;
			reg_hsync   <= 1'b0;
			reg_de      <= 1'b0;
			reg_data    <= {WIDTH{1'b0}};
			reg_ctl     <= 4'd0;
			
			reg_tready  <= 1'b1;
		end
		else begin
			// signal
			reg_vsync <= in_vsync;
			reg_hsync <= in_hsync;
			reg_ctl   <= in_ctl;
			reg_de    <= in_de;
			if ( s_axi4s_tvalid && s_axi4s_tready ) begin
				reg_data  <= s_axi4s_tdata;
				reg_tuser <= s_axi4s_tuser;
			end
			
			if ( !in_de ) begin
				reg_data  <= {WIDTH{1'b0}};
			end
			
			
			// fs
			if ( reg_vsync != in_vsync ) begin
				reg_flag_fe <= 1'b1;
			end
			else begin
				if ( sig_frame_start ) begin
					reg_flag_fe <= 1'b0;
				end
			end
			
			// state
			case ( reg_state )
			ST_WAIT_AXI4S_FS:
				begin
					reg_tready <= 1'b1;
					if ( s_axi4s_tuser && s_axi4s_tvalid && s_axi4s_tready ) begin
						reg_tready <= 1'b0;
						reg_state  <= ST_WAIT_VIDEO_FS;
					end
				end
			
			ST_WAIT_VIDEO_FS:
				begin
					if ( sig_frame_start ) begin
						reg_tready <= 1'b1;
						reg_state  <= ST_BUSY;
					end
				end
			
			ST_BUSY:
				begin
					reg_tready <= in_de;
					if ( sig_frame_end && !reg_tuser ) begin
						reg_state  <= ST_WAIT_VIDEO_FS;
						reg_tready <= 1'b1;
					end
				end
			
			default:
				begin
					reg_state  <= 2'bxx;
					reg_tready <= 1'bx;
				end
			endcase
		end
	end
	
	assign s_axi4s_tready = reg_tready;
	
	assign out_vsync      = reg_vsync;
	assign out_hsync      = reg_hsync;
	assign out_de         = reg_de;
	assign out_data       = reg_data;
	assign out_ctl        = reg_ctl;
	
endmodule


`default_nettype wire


// end of file
