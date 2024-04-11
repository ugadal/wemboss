=item programsByKeywords()


=cut



package wEMBOSS::searchAction;
	our $EMBOSSversion="?";


use strict;

sub programsByKeywords {
	if (open EMBOSSVERSION, "$main::EMBOSS_BIN/embossversion -nofull -auto | ") {$EMBOSSversion = <EMBOSSVERSION>}
	print <<EOF;
<html>

<head>
<title>wE by keywords </title>
<link rel="stylesheet" type="text/css" href="/wEMBOSS/wEMBOSS.css">
<!--
<script language="JavaScript" src="/wEMBOSS/wEMBOSS.js"> </script>
-->
</head>
<body topmargin="0" marginheight="0" bgcolor="#BDD99F" >
<form name="search" action="" onSubmit='if (parent.wEMBOSStitle.document.project._pwd.value != "") {parent.popup("/wEMBOSS_cgi/catch?_action=search&_pwd="
							+parent.wEMBOSStitle.document.project._pwd.value
							+"&_keywords="+document.search._keywords.value
							+"&_logic="+document.search._logic[0].checked, "EMBOSSfile")
					} else {alert("Please create a first project!")}
					; return false' >
<table  width="100%" border="0" cellpadding="0" cellspacing="0">
 <tr>
  <td class="credits">
            <div align="center" ><br>EMBOSS Version $EMBOSSversion<br></div>
  </td>
 </tr>
</table>

<table width="100%" border="0" cellpadding="0" cellspacing="5" bgcolor="#FFFFF">
 <tr>
  <td align=center>
   <table border="0" cellspacing="0" cellpadding="0">
    <tr>
	<td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	<td nowrap background="/wEMBOSS/images/but_pink_back.gif"><a href="#"
			onClick='if (parent.wEMBOSStitle.document.project._pwd.value != "") {parent.popup("/wEMBOSS_cgi/catch?_action=search&_pwd="
					+parent.wEMBOSStitle.document.project._pwd.value+"&_keywords="
					+document.search._keywords.value+"&_logic="
					+document.search._logic[0].checked, "EMBOSSfile")
					} else {alert("Please create a first project!")}
					; return false'
			  class="but">Search for programs</a></td>
	<td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
    </tr>
   </table>
  </td>
 </tr>
 <tr>
  <td align=center>
   <table border="0" cellspacing="0" cellpadding="1">
    <tr><td>by keywords :</td></tr>
    <tr><td><input type="text" name="_keywords" size="18" ></td></tr> 
    <tr><td align=center>and&nbsp;<input type="radio" name="_logic" value="and" checked>&nbsp;&nbsp;&nbsp;or&nbsp;<input type="radio" name="_logic" value="or"></td></tr>
   </table>
  </td>
 </tr>
</table>
<table width="100%" border="0" cellpadding="0" cellspacing="0">
 <tr>
  <td height="8" nowrap valign="top">
	    <div align="center" class="credits">Marc Colet &amp; Martin Sarachu<br>Version 2.2<br></div>
  </td>
 </tr>
 <tr>
  <td> <div align=center><img src="/wEMBOSS/images/logo_zb.gif" border=0></div></td>
 </tr>
</table>
</form>
</body>
</html>
EOF
}


=item search($cgi)

Generate an html page that contains the results of the user's keyword search.
Both the one line application descriptions and the user manuals are searched,
with applications that matched in the description appearing at the top of the
list because presumably they are the ones that most likely do what the user
wants.


=cut

sub searchWindow {
	if (open EMBOSSVERSION, "$main::EMBOSS_BIN/embossversion -nofull -auto | ") {$EMBOSSversion = <EMBOSSVERSION>}
		
	use Storable;
	
	my $cgi = shift;
	my $projectDirectory = $cgi->param('_pwd');

	print <<EOF;
<html>

<head>
<title>wE search results</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<script language="JavaScript" src="/wEMBOSS/wEMBOSS.js"></script>
<link rel="stylesheet" type="text/css" href="/wEMBOSS/wEMBOSS.css">
</head>
<body>
<script language="javascript"> parent.focus() </script>
<table width="635" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td><span class="wtitle">w</span><span class="title">Programs </span><span class="titlepopup">by keywords</span></td>
  </tr>
  <tr>
    <td><img src="/wEMBOSS/images/pix.gif" width="8" height="8"></td>
  </tr>
   <tr>
    <td>

EOF

	# generate the regular expression, using the formula from the cookbook...
	#
	my @keywords = split (/\s+/, $cgi->param('_keywords'));
	my $regexp;
	if ($cgi->param('_logic') eq 'true') {
		$regexp = '^';
		foreach my $keyword (@keywords) {
			$regexp .= "(?=.*$keyword)";
		}
	} else {
		$regexp = join '|', @keywords;
	}
	# read a list of programs and groups to be excluded from the menu into a
	# hash so we can easily test for membership... the exclude file contains
	# the entire output line from wossname for each application/group we want
	# excluded -- this actually speeds up the pattern match because the
	# initial test is on the lengths of the two strings...
	#

	my %exclude;

	open EXCLUDE, "$main::wEMBOSS_HOME/embossData/exclude" or warn "couldn't read $main::wEMBOSS_HOME/exclude: $!";

	my @excluded = <EXCLUDE>;

	close EXCLUDE;

	foreach (@excluded) {

		chomp;

		s/\s+.*//g;

		$exclude{$_}++;

	}

	# search the short description and manual for each application...
	#
	if (open WOSSNAME, "$main::EMBOSS_BIN/wossname -alpha -auto |") {
		my @results;
		foreach (<WOSSNAME>) {
			chomp;
			my ($name, $doc) = split (/\s+/, $_, 2);		
			next if $exclude{$name} or $name =~ m/^(wossname|tfm)$/;   # skip anything in the exclude list
			if (grep /$regexp/si, $doc) {
				unshift @results, ($name, $doc);			
			} elsif (open MANUAL, "<$main::EMBOSS_HOME/doc/programs/text/$name.txt") {
				my $manual = join "", <MANUAL>;
				$manual =~ s/\nSee also.*(\n\w)/$1\n/s;
				$manual =~ s/\nSee also.*/\n/s;
				if (grep /$regexp/si, $manual) {
					push @results, ($name, $doc);
				}
				close MANUAL;					
			}
		} # so we just ignore any line that isn't an EMBOSS app...
		close WOSSNAME;
		print <<EOF;
	 <table width="650" border="0" align="center" cellpadding="3" cellspacing="0" bgcolor="#D7909B">
	  <tr>
	    <td>
		 <table width="100%" border="0" cellpadding="1" cellspacing="0" bgcolor="#FFFFFF">
	   <tr>
		<td height="40" bgcolor="bb4553"><span class="txtwhite">&nbsp; @{[ @results/2 ]} matches found: best matches first!</span></td>
	   </tr>

EOF

		while (@results) {
			my $name = shift @results;
			my $doc = shift @results;
			my $docPath = "/embosshelp";
			my $acd = retrieve "$main::wEMBOSS_HOME/sacd/$name.sacd" or warn $@;
        	if ($EMBOSSversion =~ /^6/) {
                	if ( exists $acd->{'embassy'} ) { $docPath =  "/embassy/" . $acd->{'embassy'}}
        	} elsif ($EMBOSSversion =~ /^[45]/) {
                	$docPath = "/emboss/apps";
                	if ( exists $acd->{'embassy'} ) { $docPath =  "/embassy/" . $acd->{'embassy'}}
        	} 
			print <<EOF;
			<tr>
				<td align="left">
					<a href="#" class= "menu" onClick='if ("$projectDirectory" == "") {alert("Please create a first project!"); return false} else
				    	{parent.popup("/wEMBOSS_cgi/catch?_action=input&_app=$name&_pwd=$projectDirectory","wEMBOSSmain")}'> $name 
					</a>
				</td>
			</tr>
			<tr>
				<td align="left"><blockquote> $doc. 
				<a  href= '#' onClick="parent.popup('$docPath/$name.html','helpWindow'); return false" class = "menu" >
					<font size="1" color="blue">manual</font></a></blockquote> 
				</td>
			</tr>
EOF
		}
	} else {
		error("couldn't run wossname: $!");
	}
	
	print <<EOF;
		</table>
		 </td>
	    </tr>
	  </table>
	</td>
	 </tr>
</table>
</body>

</html>

EOF
}



1
