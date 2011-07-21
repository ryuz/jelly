#!/usr/bin/perl

if ( $#ARGV < 1 )
{
	print "bin2hex.pl <filename> <size>\n";
	exit;
}

$file = $ARGV[0];
$size = $ARGV[1];

open(IN, $ARGV[0]) || die "ファイルが見つかりません" ;
binmode(IN);

for ( $i = 0; $i < $size; $i++ )
{
	read(IN, $buf, 4);
	$data = unpack "N", $buf;
	print sprintf("%08x\n", $data);
}


close(IN);

