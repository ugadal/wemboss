=head1 NAME

wEMBOSS::ACD - EMBOSS Ajax Command Definition file parser

Copyright (C) 2003, 2004, 2005 Marc Colet, Martin Sarachu

This file is part of wEMBOSS.

wEMBOSS is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

wEMBOSS is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with wEMBOSS; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 SYNOPSIS
	
	use wEMBOSS::ACD;
	
	my $href = parseACD($filename);
	
=head1 DESCRIPTION

This module will parse EMBOSS Ajax Command Definition files to a nested hash
structure.  Conveniently, this hash is appropriate for output by XML::Simple...

The top level hash contains all of the information in the I<appl> block of
the ACD file (program name, documentation, group membership) plus a reference
to a hash of the application parameters, keyed to the string C<param>.

Each key in the parameter hash is the name of a parameter, and each value is a
reference to a hash of the attributes of that parameter.

The parser uses the Text:Abbrev module to ensure that it catches any
abbreviation of datatypes that the author of the ACD file may have used.  The
canonical name for each datatype, as defined by the ACD specification, is what
is actually stored in the hash.

=cut

package wEMBOSS::ACD;
use 5.6.1;
use strict;
use warnings;
use Text::Abbrev;
# global hash of abbreviations for canonical datatypes...
#
our $CANONICAL = abbrev qw(array boolean toggle integer float range regexp string infile
			   dirlist directory discretestates distances filelist frequencies
	                   matrix matrixf codon outcodon sequence seqset seqall features
                           list selection outfile seqout seqoutset seqoutall outdir variable
                           graph xygraph datafile section endsection align featout report
			   pattern properties seqsetall tree );
our $ACDPROTEIN = "";
# parseACD ( $filename )
#
# parse the named ACD file, returning a hash structure as described above...
#
sub parseACD {
        $ACDPROTEIN = "";
	our %CANONICAL;
	my @blocks = getBlocks(shift);
	my (%appl, %params, @controlParams);

	# parse the application description block...
	#
	my ($name, $type, $attribs) = parseBlock(shift @blocks);
	($name && $type && $attribs) or die "Bad appl block\n";
	$appl{'name'} = $name;

	# make sure that documentation and groups are stored by those canonical
	# names (instead of doc, group, or some other abbreviation). anything else
	# that happens to be there keeps the key it has...
	#
	while (my ($key, $value) = each %$attribs) {
		$appl{$key} = $value;
	}

	# parse the variables...
	#
	my @sorted;
	while ( ($name, $type, $attribs, @controlParams) = parseBlock(shift @blocks) ) {
		last unless ($name && $type && $attribs);
		if (my $canonical = $CANONICAL->{lc $type}) {
			$attribs->{'datatype'} = $canonical;
		} else {
			$attribs->{'datatype'} = $type;
			print STDERR "Datatype '$type' in $name.acd does not exist...\n";
		}
		if (!$ACDPROTEIN and $type =~ /sequence|seqall|seqset/) {$ACDPROTEIN = $name}
		push @sorted, $name;
		$params{$name} = $attribs;
		if (scalar @controlParams) {	# here we add the '_controlParam' attribute to parameters
			no strict 'refs' ;      # that control attribute values of other parameters
			foreach (@controlParams){ $params{$_}->{'_controlParam'} = 1} 
			use strict;						      
		}
	}
	$appl{'param'} = \%params;
	$appl{'-sorted'} = \@sorted;
	
	return \%appl;
}

# parseBlock($block)
#
# parse a top level block, extracting the data type, the parameter name, and
# a hash of attributes and their values.  note that to comply with XML, we
# should probably change every \S to a \w, but this is stricter than the 
# EMBOSS ACD specification seems to require...
#
sub parseBlock {
	my $block = shift or return ();
	my (%attribs, @controlParams, $controlParam, $var);

	# grab the data type and parameter name first...
	#
	$block =~ m/(\S+?)\s*[:=]\s*(\S+)\s*\[/g;
	my ($type, $name) = (lc $1, lc $2);

	# then grab the attributes...
	#
#	while ($block =~ m/(\S+?)\s*[:=]\s*(".*?"|\S+)/g) {
	while ($block =~ m/(\S+?)\s*[:=]\s*(".*?")/g) {
		my ($acdExp, $beginExp, $strippedExp, $endExp) = ("", "", "", "") ;
		$controlParam  = "";
		($var, $_) = (lc $1, $2);
		s/\"[Yy][eE]?[sS]?\"/"1"/g;
		s/\"(No|NO|no|N)\"/"0"/g;
		tr/"\\//d; # remove quotes and line continuation characters
		s/\n/ /g;
		if (/\$\(/) { # an ACD expression
			wEMBOSS::error ("\"$name\" parameter: syntax error (missing left parenthesis)".
					" in ACD expression (tell to EMBOSS Manager : this could produce".
					" wrong results from program execution!)") if /[\$\@][^(]/;
			s/acdprotein/$ACDPROTEIN.protein/g;			 # restore protein property of sequence object
			while (m/\$\((\w+?)[\.\)]/g) { push @controlParams, lc $1 } # make parameter aware of its control activity
										 # Perlisation of expression
			s/(\$\(\w+)\.(\w+?)\)/$1\{$2\})/g;			 # $(var.prop) -> $(var{prop})   
			s/(\$)\(([\w\{\}]+)\)/ $1$2 /g;			 	 # $(var)      -> $var  eventual also
			$acdExp=$_;
			while ($acdExp=~/\@/) {
										 # the most inner left expression is stripped from "@(" and ")"
				($acdExp=~s/(.*?)\@\(([^@]+?)\)(.*$)/$1$2$3/) 
				or wEMBOSS::error ("\"$name\" parameter: syntax error (missing right  parenthesis)".
						   " in ACD expression (tell to EMBOSS Manager : this could produce".
						   " wrong results from program execution!)");  
				$beginExp= $1; $strippedExp=$2; $endExp=$3;
				$_ = $strippedExp;
				if (s/(\$\w+)\s*=\s*(\w+?)\s*\:/ $2 :/) {	 # A typical ACD "param =value : : : :" expression
					($controlParam = $1) and (s/\s+?([\w\.]+)\s+?:/ : $controlParam  == "$1" ?/g
					) and (s/$/ : "0" /) and (s/ ://
					) and (s/\?\s*([\w ]+)\s+\:/? "$1" :/g);
				#	s/ (\w) / "$1" /; s/\s([\w\.]+)\s*/ "$1" /g;
				} else {
					s/\s([!=]{2})\s?/ $1 /;
					s/\s([\w\.]+)\s*/ "$1" /g;
				}		 # others expressions
				$acdExp = $beginExp . "(" . $_ . ")"  . $endExp;
			}
			$_ = $acdExp;
			if (m/\s\{/) {
				$acdExp= $_;
				($acdExp=~s/(.*?)==\s*\{([^\}]+?)\}(.*$)/$1$2$3/)
				or wEMBOSS::error ("\"$name\" parameter: syntax error in { | } ACD expression");
				$beginExp= $1; $strippedExp=$2; $endExp=$3;
				$strippedExp =~ s/[\s\"]//g;  
				$_ =  $beginExp . "=~ m/" . $strippedExp. "/"  . $endExp;
			} else { s/\|/ or /g }
            s/\&/ and /g; 
            s/(\S+)\s*\=\=\s*(\S+)/lc $1 eq lc $2/g;
            s/(\S+)\s*\!\=\s*(\S+)/lc $1 ne lc $2/g;
            s/"true"/"1"/ig;
            s/"false"/"0"/ig;
			s/\"(No|NO|no|N)\"/"0"/g;
            $_ = lc $_ ;
			s/\$([\w\{\}]+)\s*/\$wEMBOSS::Input::$1 /g;
			s/  / /g;s/  / /g;s/  / /g;
		} 
		$attribs{$var} = $_;
	}
	return ($name, $type, \%attribs, @controlParams);
}

# getBlocks ( $filename )
#
# break the named ACD file up into its component blocks, returning these in a
# list...
#
sub getBlocks {
	my $acd_path = shift;
	my ($block, @blocks);

	open FH, "<$acd_path" or die "$0: couldn't open $acd_path for read: $!";
	
	while (<FH>) {
		s/#.*//;			# no comments
		s/^\s+//;			# no leading white
		s/\s+$//;			# no trailing white
		next unless length;	# anything left?
		
		if ( my ($this) = m/(.*]\s*$)/ ) {
			push @blocks, $block . $this;
			$block = "";
		} elsif (my ($variable, $value) = m/variable\s*?[:=]\s+?(\w+)\s+(.*)/ ){
			push @blocks, "variable : $variable [value : $value]";
		} elsif (my ($section) = m/endsection\s*?:\s*?(\w+)\s*/ ){
			push @blocks, "endsection: $section"."end"."[value : 1]";
		} else {
			$block .= "$_ ";
		}
	}
	
	close FH;
#	foreach (@blocks) { print STDERR $_, "\n";}
	return @blocks;
}

1;

=head1 AUTHOR

Luke McCarthy <lukem@bioinfo.pbi.nrc.ca>
modified to interpret ACD expressions in perl by Marc Colet 

=head1 BUGS

I don't handle sections very well.  I should really add them as another level
in the hash hierarchy...

I should really return the data as an object.  It would make more sense.

=head1 SEE ALSO

The AJAX Command Definition Language Specification, at
http://www.uk.embnet.org/Software/EMBOSS/Acd/syntax.html

=head1 COPYRIGHT

Copyright (c) 2001 Luke McCarthy.  All rights reserved.  This program is free
software. You may copy or redistribute it under the same terms as Perl itself.

=cut
