#!/usr/bin/perl
use strict;
use 5.6.1;
use strict;
use warnings;
use Storable;
use Data::Dumper;
my $sacd = shift;
die ("displaySacd.pl needs one argument (e. g. water.sacd)" ) unless $sacd;
my $restored_acd = retrieve "$sacd";
my $teller;
$|=1;

print "\n";
foreach ( sort keys %$restored_acd ) {
	/^param|^-sorted/	and do {next};	
	printf "%-15s = %-80s\n", $_, "\"$$restored_acd{$_}\"";
}

printf "%-15s : \n", "parameters";
foreach my $param(  @{$$restored_acd{-sorted}} ) {
	if ($$restored_acd{param}{$param}{datatype} eq "endsection") {next};
	if ($$restored_acd{param}{$param}{datatype} eq "section") {printf "---%-25s\n", $$restored_acd{param}{$param}{information}; next}
	printf "      %-25s\n", $param;
	foreach my $attribute(  keys %{$$restored_acd{param}{$param}}) {
		if (length $$restored_acd{param}{$param}{$attribute} <= 60) {
			printf "         %-15s = %-80s\n", $attribute,$$restored_acd{param}{$param}{$attribute};
		} else {
			printf "         %-15s = ", $attribute;
			my @attribute = split //, $$restored_acd{param}{$param}{$attribute};
			while (  scalar @attribute ) {
				if (scalar @attribute > 60 ) {$teller = 60} else {$teller = scalar @attribute} 	
				while ( $teller) {
					print shift @attribute;
					$teller = $teller -1;
				}
				while ((scalar @attribute > 1) and ($attribute[0] !~ /\s/)) {print shift @attribute}
				shift @attribute if scalar @attribute;
				printf "\n%27s", "" if scalar @attribute ;
			}
			print "\n";

		}
			
	}	
}	



