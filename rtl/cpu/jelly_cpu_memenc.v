// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    MIPS like CPU core
//
//                                  Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// memory access encoder
module jelly_cpu_memenc
		#(
			parameter	USE_INST_LSWLR      = 1'b1,
		)
		(
			input	wire	[31:0]		in_addr,
			input	wire	[31:0]		in_wdata,
			input	wire	[1:0]		in_size,
			input	wire				in_unsigned,
			
			output	wire	[3:0]		out_sel,
			output	wire	[31:0]		out_wdata,
			output	wire	[3:0]		out_lr_mask,
			output	wire	[1:0]		out_lr_shift
		);


	reg		[3:0]		tmp_sel,
	reg		[31:0]		tmp_wdata,
	reg		[3:0]		tmp_lr_mask;
	reg		[1:0]		tmp_lr_shift;

	always @* begin
		if ( in_size == 2'b00 ) begin
			if ( endian ) begin
				// byte big-endian
				tmp_sel      <= (4'b1000 >> in_addr[1:0]);
				tmp_wdata    <= {4{in_wdata[7:0]}};
				tmp_lr_mask  <= 4'b1111;
				tmp_lr_shift <= ~in_addr[1:0];
			end 
			else begin
				// byte little-endian
				tmp_sel      <= (4'b0001 << in_addr[1:0]);
				tmp_wdata    <= {4{ex_fwd_rt_data[7:0]}};
				tmp_lr_mask  <= 4'b1111;
				tmp_lr_shift <= in_addr[1:0];
			end 
		end
		else if ( in_size == 2'b01 ) begin
			if ( endian ) begin
				// half-word big-endian
				tmp_sel      <= (4'b1100 >> {in_addr[1], 1'b0});
				tmp_wdata    <= {2{in_wdata[15:0]}};
				tmp_lr_mask  <= 4'b1111;
				tmp_lr_shift <= {~in_addr[1], 1'b0};
			end
			else begin
				// half-word little-endian
				tmp_sel      <= (4'b0011 << {in_addr[1], 1'b0});
				tmp_wdata    <= {2{in_wdata[15:0]}};
				tmp_lr_mask  <= 4'b1111;
				tmp_lr_shift <= {in_addr[1], 1'b0};
			end
		end
		else if ( (in_size == 2'b10) && USE_INST_LSWLR ) begin
			if ( in_unsigned == 1'b0 ) begin
				if ( endian ) begin
					// word left big-endian
					tmp_sel      <= (4'b1111 >> in_addr[1:0]);
					tmp_wdata    <= (in_wdata[31:0] >> {in_addr[1:0], 3'b000});
					tmp_lr_mask  <= (4'b1111 << in_addr[1:0]);
					tmp_lr_shift <= ~in_addr[1:0];
				end 
				else begin
					// word left little-endian
					tmp_sel      <= (4'b1111 >> ~in_addr[1:0]);
					tmp_wdata    <= (in_wdata[31:0] >> {~in_addr[1:0], 3'b000});
					tmp_lr_mask  <= (4'b1111 << ~in_addr[1:0]);
					tmp_lr_shift <= in_addr[1:0];
				end 
			end
			else begin
				if ( endian ) begin
					// word right big-endian
					tmp_sel      <= (4'b1111 << ~in_addr[1:0]);
					tmp_wdata    <= (in_wdata[31:0] << {~in_addr[1:0], 3'b000});
					tmp_lr_mask  <= (4'b1111 >> ~in_addr[1:0]);
					tmp_lr_shift <= ~in_addr[1:0];
				end 
				else begin
					// word right little-endian
					tmp_sel      <= (4'b1111 << in_addr[1:0]);
					tmp_wdata    <= (in_wdata[31:0] << {in_addr[1:0], 3'b000});
					tmp_lr_mask  <= (4'b1111 >> in_addr[1:0]);
					tmp_lr_shift <= in_addr[1:0];
				end 
			end
		end
		else begin
			// word
			tmp_sel      <= 4'b1111;
			tmp_wdata    <= in_wdata;
			tmp_lr_mask  <= 1'b1111;
			tmp_lr_shift <= 0;
		end
		
		if ( !tmp_sel[0] ) begin tmp_wdata[7:0]   = 8'hxx; end
		if ( !tmp_sel[1] ) begin tmp_wdata[15:8]  = 8'hxx; end
		if ( !tmp_sel[2] ) begin tmp_wdata[23:16] = 8'hxx; end
		if ( !tmp_sel[3] ) begin tmp_wdata[31:24] = 8'hxx; end		
	end
	
endmodule
