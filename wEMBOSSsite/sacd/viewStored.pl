#!/usr/bin/perl
use strict;
use 5.6.1;
use strict;
use warnings;
use Storable;
use Data::Dumper;
my $program = shift;
my $restored_acd = retrieve "$program.sacd";
$Data::Dumper::Purity = 1;
print Dumper $restored_acd, "\n";

