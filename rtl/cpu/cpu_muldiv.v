// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



module cpu_muldiv
		(
			reset, clk,
			op_mul, op_div, op_mthi, op_mtlo, op_signed,
			in_data0, in_data1,
			out_hi, out_lo,
			busy
		);
	
	parameter	DATA_WIDTH = 32;
	
	input							clk;
	input							reset;
	
	input							op_mul;
	input							op_div;
	input							op_mthi;
	input							op_mtlo;
	input							op_signed;
	
	input	[DATA_WIDTH-1:0]		in_data0;
	input	[DATA_WIDTH-1:0]		in_data1;
	
	output	[DATA_WIDTH-1:0]		out_hi;
	output	[DATA_WIDTH-1:0]		out_lo;
	
	output							busy;
	
	
		
	// MUL
	reg	signed	[DATA_WIDTH:0]			mul_in_data0;
	reg signed	[DATA_WIDTH:0]			mul_in_data1;
	wire signed	[(DATA_WIDTH*2)-1:0]	mul_out_data;
	
	always @ ( posedge clk ) begin
		if ( op_mul ) begin
			mul_in_data0[DATA_WIDTH]     <= op_signed ? in_data0[DATA_WIDTH-1] : 1'b0;
			mul_in_data1[DATA_WIDTH]     <= op_signed ? in_data1[DATA_WIDTH-1] : 1'b0;
			mul_in_data0[DATA_WIDTH-1:0] <= in_data0;
			mul_in_data1[DATA_WIDTH-1:0] <= in_data1;
		end
	end
	assign mul_out_data = mul_in_data0 * mul_in_data1;
	
	
	
	// DIV
	wire							div_out_en;
	wire	[DATA_WIDTH-1:0]		div_out_remainder;
	wire	[DATA_WIDTH-1:0]		div_out_quotient;
	cpu_divider
		i_cpu_divider
			(
				.reset				(reset),
				.clk				(clk),
				
				.op_div				(op_div),
				.op_signed			(op_signed),
				.op_set_remainder	(op_mthi),
				.op_set_quotient	(op_mtlo),
				
				.in_data0			(in_data0),
				.in_data1			(in_data1),
				
				.out_en				(div_out_en),
				.out_remainder		(div_out_remainder),
				.out_quotient		(div_out_quotient),
				
				.busy				(busy)
			);
	
	
	// switch
	reg								reg_mul_hi;
	reg								reg_mul_lo;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_mul_hi <= 1'b0;
			reg_mul_lo <= 1'b0;
		end
		else begin
			if ( op_mul ) begin
				reg_mul_hi <= 1'b1;
				reg_mul_lo <= 1'b1;
			end
			else begin
				if ( op_div | op_mthi ) begin
					reg_mul_hi <= 1'b0;
				end
				if ( op_div | op_mtlo ) begin
					reg_mul_lo <= 1'b0;
				end				
			end
		end
	end
	
	assign out_hi = reg_mul_hi ? mul_out_data[63:32] : div_out_remainder;
	assign out_lo = reg_mul_lo ? mul_out_data[31:0]  : div_out_quotient;
	
endmodule
