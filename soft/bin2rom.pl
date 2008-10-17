#!/usr/bin/perl


open(IN, $ARGV[0]) || die "ƒtƒ@ƒCƒ‹‚ªŒ©‚Â‚©‚è‚Ü‚¹‚ñ" ;
binmode(IN);


$addr_width = 12;

print <<END_OF_DATA;
`timescale 1ns / 1ps

module boot_rom
		(
			clk ,
			addr,
			data
		);
	
	input				clk;
END_OF_DATA

	printf "\tinput	[%d:0]		addr;\n", $addr_width - 1;

print <<END_OF_DATA;
	output	[31:0]		data;
	
	reg		[31:0]		data;
	
	always @ ( posedge clk ) begin
		case ( addr )
END_OF_DATA

for ( $addr = 0; $addr < (1 << $addr_width); $addr++ ) {
	sysread(IN, $buf, 4);
	$x = unpack("L", $buf);
    printf "\t\t%d'h%x:\t\tdata <= 32'h%08x;\n", $addr_width, $addr, $x;
}

print <<END_OF_DATA;
		default:	data <= 32'hf0000000;
		endcase
	end
	
endmodule
END_OF_DATA


close(IN);
