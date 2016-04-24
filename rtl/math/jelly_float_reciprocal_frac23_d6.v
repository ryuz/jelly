


`timescale 1ns / 1ps
`default_nettype none



module jelly_float_reciprocal_frac23_d6
		(
			input	wire				reset,
			input	wire				clk,
			input	wire	[1:0]		cke,
			
			input	wire	[5:0]		in_d,
			
			output	wire	[22:0]		out_frac,
			output	wire	[22:0]		out_grad
		);
	
	(* rom_style = "distributed" *)		reg		[45:0]		mem_dout;
	
	always @(posedge clk) begin
		if ( cke[0] ) begin
			case ( in_d )
			6'h00:	mem_dout <= 46'h00000003f03f;
			6'h01:	mem_dout <= 46'h3e07e083d1b1;
			6'h02:	mem_dout <= 46'h3c1f0803b483;
			6'h03:	mem_dout <= 46'h3a44c683989c;
			6'h04:	mem_dout <= 46'h387878837ded;
			6'h05:	mem_dout <= 46'h36b982036463;
			6'h06:	mem_dout <= 46'h350750834bed;
			6'h07:	mem_dout <= 46'h33615a03347b;
			6'h08:	mem_dout <= 46'h31c71c831e01;
			6'h09:	mem_dout <= 46'h30381c03086f;
			6'h0a:	mem_dout <= 46'h2eb3e482f3bb;
			6'h0b:	mem_dout <= 46'h2d3a0702dfd8;
			6'h0c:	mem_dout <= 46'h2bca1b02ccbb;
			6'h0d:	mem_dout <= 46'h2a63bd82ba5a;
			6'h0e:	mem_dout <= 46'h29069082a8ac;
			6'h0f:	mem_dout <= 46'h27b23a8297a8;
			6'h10:	mem_dout <= 46'h266666828745;
			6'h11:	mem_dout <= 46'h2522c402777c;
			6'h12:	mem_dout <= 46'h23e706026844;
			6'h13:	mem_dout <= 46'h22b2e4025997;
			6'h14:	mem_dout <= 46'h218618824b70;
			6'h15:	mem_dout <= 46'h206060823dc7;
			6'h16:	mem_dout <= 46'h1f417d023096;
			6'h17:	mem_dout <= 46'h1e29320223d8;
			6'h18:	mem_dout <= 46'h1d1746021789;
			6'h19:	mem_dout <= 46'h1c0b81820ba2;
			6'h1a:	mem_dout <= 46'h1b05b0820020;
			6'h1b:	mem_dout <= 46'h1a05a081f4fe;
			6'h1c:	mem_dout <= 46'h190b2181ea38;
			6'h1d:	mem_dout <= 46'h18160581dfca;
			6'h1e:	mem_dout <= 46'h17262081d5af;
			6'h1f:	mem_dout <= 46'h163b4901cbe7;
			6'h20:	mem_dout <= 46'h15555581c26c;
			6'h21:	mem_dout <= 46'h14741f81b93a;
			6'h22:	mem_dout <= 46'h13978281b050;
			6'h23:	mem_dout <= 46'h12bf5a81a7ab;
			6'h24:	mem_dout <= 46'h11eb85019f47;
			6'h25:	mem_dout <= 46'h111be1819722;
			6'h26:	mem_dout <= 46'h105050818f3b;
			6'h27:	mem_dout <= 46'h0f88b301878d;
			6'h28:	mem_dout <= 46'h0ec4ec818018;
			6'h29:	mem_dout <= 46'h0e04e08178d9;
			6'h2a:	mem_dout <= 46'h0d48740171ce;
			6'h2b:	mem_dout <= 46'h0c8f8d016af4;
			6'h2c:	mem_dout <= 46'h0bda1301644c;
			6'h2d:	mem_dout <= 46'h0b27ed015dd1;
			6'h2e:	mem_dout <= 46'h0a7904815783;
			6'h2f:	mem_dout <= 46'h09cd43015161;
			6'h30:	mem_dout <= 46'h092492814b69;
			6'h31:	mem_dout <= 46'h087ede014598;
			6'h32:	mem_dout <= 46'h07dc12013fef;
			6'h33:	mem_dout <= 46'h073c1a813a6a;
			6'h34:	mem_dout <= 46'h069ee581350a;
			6'h35:	mem_dout <= 46'h060460812fce;
			6'h36:	mem_dout <= 46'h056c79812ab2;
			6'h37:	mem_dout <= 46'h04d7208125b8;
			6'h38:	mem_dout <= 46'h0444448120de;
			6'h39:	mem_dout <= 46'h03b3d5811c21;
			6'h3a:	mem_dout <= 46'h0325c5011782;
			6'h3b:	mem_dout <= 46'h029a04011300;
			6'h3c:	mem_dout <= 46'h021084010e99;
			6'h3d:	mem_dout <= 46'h018937810a4e;
			6'h3e:	mem_dout <= 46'h01041081061d;
			6'h3f:	mem_dout <= 46'h008102010204;
			endcase
		end
	end
	
	reg		[22:0]		reg_frac;
	reg		[22:0]		reg_grad;
	
	always @(posedge clk) begin
		if ( cke[1] ) begin
			{reg_frac, reg_grad} <= mem_dout;
		end
	end
	
	assign out_frac = reg_frac;
	assign out_grad = reg_grad;
	
	
endmodule


`default_nettype wire


// end of file
