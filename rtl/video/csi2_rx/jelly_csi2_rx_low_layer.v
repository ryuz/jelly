// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// パケットの受信
module jelly_csi2_rx_low_layer
		#(
			parameter M_AXI4S_REGS = 0
		)
		(
			input	wire			aresetn,
			input	wire			aclk,
			
			input	wire	[7:0]	param_data_type,
			
			output	wire			out_request_sync,
			output	wire			out_frame_start,
			output	wire			out_frame_end,
			output	wire			out_crc_error,
			
			input	wire	[0:0]	s_axi4s_tuser,
			input	wire	[7:0]	s_axi4s_tdata,
			input	wire			s_axi4s_tvalid,
			output	wire			s_axi4s_tready,
			
			output	wire			m_axi4s_tlast,
			output	wire	[7:0]	m_axi4s_tdata,
			output	wire			m_axi4s_tvalid,
			input	wire			m_axi4s_tready
		);
	
	// CRC
	function [15:0]		calc_crc(input [15:0] crc, input [7:0] data);
	integer	i;
	begin
		calc_crc = crc;
		for ( i = 0; i < 8; i = i+1 ) begin
			calc_crc = ((calc_crc >> 1) ^ ((calc_crc[0] ^ st0_data[i]) ? 16'h8408 : 16'h0000));
		end
	end
	endfunction
	
	
	
	wire				cke;
	
	
	// stage 0 (header parser)
	localparam	[2:0]	ST0_IDLE = 0, ST0_ID = 1, ST0_WC0 = 2, ST0_WC1 = 3, ST0_ECC = 4;
	
	reg		[2:0]		st0_state;
	reg		[7:0]		st0_id;
	reg		[15:0]		st0_wc;
	reg		[7:0]		st0_ecc;
	reg					st0_ph;
	reg		[7:0]		st0_data;
	reg					st0_valid;
	
	always @(posedge aclk) begin
		if ( ~aresetn || out_request_sync ) begin
			st0_state <= ST0_IDLE;
			st0_id    <= 8'hxx;
			st0_wc    <= 16'hxxxx;
			st0_ecc   <= 8'hxx;
			st0_ph    <= 1'bx;
			st0_data  <= 8'hxx;
			st0_valid <= 1'b0;
		end
		else if ( cke ) begin
			st0_ph    <= 1'b0;
			st0_data  <= s_axi4s_tdata;
			st0_valid <= s_axi4s_tvalid;
			
			if ( s_axi4s_tuser && s_axi4s_tvalid ) begin
				// start
				st0_state <= ST0_ID;
				st0_id    <= 8'hxx;
				st0_wc    <= 16'hxxxx;
				st0_ecc   <= 8'hxx;
			end
			else begin
				case ( st0_state )
				ST0_ID:
					begin
						st0_id  <= 8'hxx;
						st0_wc  <= 16'hxxxx;
						st0_ecc <= 8'hxx;
						if ( s_axi4s_tvalid ) begin
							st0_state <= ST0_WC0;
							st0_id    <= s_axi4s_tdata;
						end
					end
				
				ST0_WC0:
					begin
						st0_wc       <= 16'hxxxx;
						st0_ecc      <= 8'hxx;
						if ( s_axi4s_tvalid ) begin
							st0_state    <= ST0_WC1;
							st0_wc[7:0]  <= s_axi4s_tdata;
						end
					end
				
				ST0_WC1:
					begin
						st0_wc[15:8] <= 8'hxx;
						st0_ecc      <= 8'hxx;
						if ( s_axi4s_tvalid ) begin
							st0_state    <= ST0_ECC;
							st0_wc[15:8] <= s_axi4s_tdata;
						end
					end
					
				ST0_ECC:
					begin
						st0_ecc <= 8'hxx;
						if ( s_axi4s_tvalid ) begin
							st0_state <= ST0_IDLE;
							st0_ecc   <= s_axi4s_tdata;
							st0_ph    <= 1'b1;
						end
					end
				
				default:
					begin
						st0_state <= ST0_IDLE;
						st0_id    <= 8'hxx;
						st0_wc    <= 16'hxxxx;
						st0_ecc   <= 8'hxx;
					end
				endcase
			end
		end
	end
	
	
	
	// stage1
	localparam	[1:0]	ST1_IDLE = 0, ST1_DATA = 1, ST1_CRC0 = 2, ST1_CRC1 = 3;
	
	reg		[1:0]	st1_state;
	reg		[15:0]	st1_wc;
	reg		[15:0]	st1_counter;
	reg		[15:0]	st1_crc;
	reg		[15:0]	st1_crc_sum;
	reg				st1_last;
	reg		[7:0]	st1_data;
	reg				st1_valid;
	reg				st1_req_sync;
	reg				st1_frame_start;
	reg				st1_frame_end;
	reg				st1_crc_error;
	
	always @(posedge aclk) begin
		if ( ~aresetn ) begin
			st1_state       <= ST0_IDLE;
			st1_wc          <= 16'hxxxx;
			st1_counter     <= 16'hxxxx;
			st1_crc         <= 16'hxxxx;
			st1_crc_sum     <= 16'hxxxx;
			st1_data        <= 8'hxx;
			st1_last        <= 1'bx;
			st1_valid       <= 1'b0;
			st1_req_sync    <= 1'b0;
			st1_frame_start <= 1'b0;
			st1_frame_end   <= 1'b0;
			st1_crc_error   <= 1'b0;
		end
		else if ( cke ) begin
			st1_req_sync    <= 1'b0;
			st1_frame_start <= 1'b0;
			st1_frame_end   <= 1'b0;
			st1_crc_error   <= 1'b0;
			st1_data        <= st0_data;
			st1_last        <= 1'b0;
			st1_valid       <= 1'b0;
			
			if ( st0_valid ) begin
				if ( st0_ph ) begin
					if ( st0_id[5:4] == 2'b00 ) begin
						// short packet
						st1_state       <= ST1_IDLE;
						st1_wc          <= 16'hxxxx;
						st1_counter     <= 16'hxxxx;
						st1_crc         <= 16'hxxxx;
						st1_crc_sum     <= 16'hxxxx;
						st1_req_sync    <= 1'b1;
						st1_frame_start <= (st0_id[3:0] == 4'h0);
						st1_frame_end   <= (st0_id[3:0] == 4'h1);
					end
					else begin
						// long packet
						st1_state    <= ST1_DATA;
						st1_wc       <= st0_wc;
						st1_counter  <= 16'h0001;
						st1_crc      <= 16'hxxxx;
						st1_crc_sum  <= 16'hffff;
					end
				end
				else begin
					case ( st1_state )
					ST1_DATA:
						begin
							st1_valid   <= 1'b1;
							st1_counter <= st1_counter + 1'b1;
							st1_crc     <= 16'hxxxx;
							st1_crc_sum <= calc_crc(st1_crc_sum, st0_data);
							
							if ( st1_counter == st1_wc ) begin
								st1_state <= ST1_CRC0;
							end
						end
					
					ST1_CRC0:
						begin
							st1_state     <= ST1_CRC1;
							st1_crc       <= 16'hxxxx;
							st1_crc[7:0]  <= st0_data;
						end
					
					ST1_CRC1:
						begin
							st1_state     <= ST1_IDLE;
							st1_crc[15:8] <= st0_data;
							st1_last      <= 1'b1;
							st1_req_sync  <= 1'b1;
						end
					
					default:
						begin
							st1_state    <= ST1_IDLE;
							st1_wc       <= 16'hxxxx;
							st1_counter  <= 16'hxxxx;
							st1_crc      <= 16'hxxxx;
						end
					endcase
				end
			end
			
			st1_crc_error <= st1_last && (st1_crc_sum != st1_crc);
		end
	end
	
	
	assign out_request_sync = st1_req_sync;
	assign out_frame_start  = st1_frame_start;
	assign out_frame_end    = st1_frame_end;
	assign out_crc_error    = st1_crc_error;
	
	assign s_axi4s_tready   = cke;
	
	assign m_axi4s_tlast    = st1_last;
	assign m_axi4s_tdata    = st1_data;
	assign m_axi4s_tvalid   = st1_valid;
	
	assign cke              = !m_axi4s_tvalid | m_axi4s_tready;
	
	
endmodule


`default_nettype wire


// end of file
