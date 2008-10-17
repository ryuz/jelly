// ----------------------------------------------------------------------------
//  MIPS like CPU for FPGA                                                     
//                                                                             
//                                       Copyright (C) 2008 by Ryuji Fuchikami 
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


module cpu_cop0
		(
			reset, clk,
			interlock,
			rd_addr, sel,
			in_en, in_data,
			out_data,
			exception_en, exception_cause, exception_pc, exception_eret,
			status, cause, epc
		);
	
	input			clk;
	input			reset;

	input			interlock;

	input	[4:0]	rd_addr;
	input	[2:0]	sel;
	
	input			in_en;
	input	[31:0]	in_data;
	
	output	[31:0]	out_data;
	
	input			exception_en;
	input			exception_cause;
	input	[31:0]	exception_pc;
	input			exception_eret;
	
	output	[31:0]	status;		// 12
	output	[31:0]	cause;		// 13
	output	[31:0]	epc;		// 14
	
	
	// register
	reg		[31:0]	reg_status;
	reg		[31:0]	reg_cause;
	reg		[31:0]	reg_epc;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_status <= {32{1'b0}};
			reg_cause  <= {32{1'b0}};
			reg_epc    <= {32{1'b0}};
		end
		else begin
			if ( !interlock ) begin
				// status
				if ( in_en & (rd_addr == 5'd12) ) begin
					reg_status[0] <= in_data[0];
					reg_status[2] <= in_data[2]; 
					reg_status[4] <= in_data[4];
				end
				else if ( exception_en ) begin
					reg_status[0] <= 1'b0;
					reg_status[2] <= reg_status[0];
					reg_status[4] <= reg_status[2];
				end
				else if ( exception_eret ) begin
					reg_status[0] <= reg_status[2];
					reg_status[2] <= reg_status[4];
				end
				
				// epc
				if ( in_en & (rd_addr == 5'd14) ) begin
					reg_epc <= in_data;
				end
				else if ( exception_en ) begin
					reg_epc <= exception_pc;
				end
			end
		end
	end
	
	reg 	[31:0]	out_data;
	always @* begin
		case ( rd_addr )
		5'd12:		out_data <= reg_status;
		5'd13:		out_data <= reg_cause;
		5'd14:		out_data <= reg_epc;
		default:	out_data <= {32{1'bx}};
		endcase
	end
	
	assign status = reg_status;
	assign cause  = reg_cause;
	assign epc    = reg_epc;
	
endmodule
