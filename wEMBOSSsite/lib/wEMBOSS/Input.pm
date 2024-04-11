# # # # # # # # # # # # # # # # input action # # # # # # # # # # # # # # # #

=item input($cgi)

Parse the SACD structure for the requested EMBOSS program and prepare dynamically 
a form to gather input choice of the user. 

=cut

package wEMBOSS::Input;

use CGI qw( :standard);

use Storable;

use Text::Abbrev;

use Cwd;

use Cwd qw( chdir );

use File::Basename;

use strict;

our $SEQUENCE1 = "";
our $SEQUENCE2 = "";
our $SECTIONWIDTH = 640;  # width of section tables
our %EXTENSION =  ( 'abi trace' => '\.abi$',
			'blast_databank' => '\.(phr|pin|psq|pal|nhr|nin|nsq|nal)$',
			'nucleotide blast databank' => '\.(nhr|nin|nsq|nal)$',
			'protein blast databank' =>'\.(phr|pin|psq|pal)$',
			'dna fasta' => '\.(fasta|nuc)$',
			'protein fasta' => '\.(fasta|aa|prot)$', 
			'dendrogram' => '\.dnd$'
		  );
our $EMBOSSversion;		  
	
sub programPage {
	my $cgi  = shift;
#	my $name = $cgi->param('_app') || "blank";
	my $name = $cgi->param('_app') || "antigenic";
	my $projectDir   = $cgi->param('_pwd');
	my $required;
	chdir $projectDir or return errorPage ("couldn't chdir to  $projectDir : $!");
	if (open EMBOSSVERSION, "$main::EMBOSS_BIN/embossversion -nofull -auto | ") {$EMBOSSversion = <EMBOSSVERSION>}
	else                                                                  { errorPage (" Can't locate EMBOSS programs in $main::EMBOSS_BIN\n") }
	close EMBOSSVERSION;
	my $hide = $cgi->cookie('hide') || "no";
	my $acd = eval {retrieve ("$main::wEMBOSS_HOME/sacd/$name".".sacd") } or return (errorPage("Can't find $main::wEMBOSS_HOME/sacd/$name".".sacd"." : $!"));
	my $canonical = abbrev( keys %$acd ); # make sure 'doc' key works...
	my $docPath = "/embosshelp";
	if ($EMBOSSversion =~ /^6/) {
		if ( exists $acd->{'embassy'} ) { $docPath =  "/embassy/" . $acd->{'embassy'}}
	} elsif ($EMBOSSversion =~ /^[45]/) {
		$docPath = "/emboss/apps";
		if ( exists $acd->{'embassy'} ) { $docPath =  "/embassy/" . $acd->{'embassy'}}
	} 
	# enforce the exclude list here...
	#
	open EXCLUDE, "$main::wEMBOSS_HOME/embossData/exclude"
	  or warn "couldn't read $main::wEMBOSS_HOME/embossData/exclude: $!";
	return errorPage("$name has been excluded") if grep /^$name/, <EXCLUDE>;
	close EXCLUDE;
	
	# do application specific stuff in here to pretty it all up a bit...
	#
	if ($name =~ /^lindna/ or $name =~ /^cirdna/) {
		$acd->{'param'}->{'intercolor'}->{'datatype'} = 'selection';
		$acd->{'param'}->{'intercolor'}->{'values'} = join ';', ('Black',
		'Red', 'Yellow', 'Green', 'Aquamarine', 'Pink', 'Wheat', 'Grey',
		'Brown', 'Blue', 'Blueviolet', 'Cyan', 'Turquoise', 'Magenta',
		'Salmon', 'White');
	}
	# deal with anything that hasn't been dealt with above using the generic
	# subroutines...
	#
	my $paramsHtml = "";
	foreach my $param (@{$acd->{'-sorted'}}) {
		my $attribs = $acd->{'param'}->{$param};
		my $canonical = abbrev( keys %$attribs );
		my $datatype = $attribs->{'datatype'};
		$required = (($datatype =~ /section/) or $attribs->{$canonical->{'standard'}} or $attribs->{$canonical->{'param'}}
			or $attribs->{$canonical->{'required'}} or  $attribs->{$canonical->{'prompted'}});

		if ($required =~ /wEMBOSS/) {	
			$required = eval $required;
			next unless $required;
		}
		my $optional =  ($attribs->{$canonical->{'optional'}} or $attribs->{$canonical->{'add'}} or $attribs->{$canonical->{'adv'}}
			or $attribs->{$canonical->{'needed'}} or (not defined  $attribs->{$canonical->{'optional'}} and not defined  $attribs->{$canonical->{'add'}}
                        and not defined $attribs->{$canonical->{'needed'}})) ;
		if ( $optional  =~ /wEMBOSS/) {
			$optional = eval $optional;
			next unless $optional;
		}
		my $class = $required ? 'inner' : 'optional';

		# make sure that the default graphics format is set to PNG even if
		# optional fields are turned off, or EMBOSS will default to X11...
		#
		if (!$required and (($cgi->cookie('hide') eq 'yes') or !$optional )) {
			if ($datatype =~ /graph/) {
#				print "<input type='hidden' name='$param' value='PNG'>\n"
				$paramsHtml = $paramsHtml . "<input type='hidden' name='$param' value='PNG'>\n";
			}
			next;
		}	
		local(*datatypeSub) = $datatype; # 'datatypeSub' becomes an alias of the sub named $datatype (e.g. boolean, sequence...)!
		$paramsHtml = $paramsHtml . &datatypeSub($cgi, $param, $attribs, $canonical, $class) or error("unable to run'$datatype' function"); 
	}
	

	print <<EOF;
<html>
<head>
<title>wE $name</title>
<!--
<script language="JavaScript" src="/wEMBOSS/wEMBOSS.js"> </script>
--> 
<link href="/wEMBOSS/wEMBOSS.css" rel="stylesheet" type="text/css">
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"></head>
<body onLoad="parent.init()">
<DIV  id="docu" style = \"position:absolute;visibility:hidden;z-index:50;left:2\"></DIV>
<script language="JavaScript"> parent.wEMBOSSmain.focus();</script>
<form name="input" target="EMBOSSfile" action="/wEMBOSS_cgi/catch" method="post" enctype="multipart/form-data">
<table width="660" border="0" cellspacing="0" cellpadding="1">
 <tr>
  <td>
   <table width="100%" border="0" cellpadding="0" cellspacing="1">
    <tr>
	<td valign="top" colspan="3" ><span class="wtitle">w</span><span class="title">$name&nbsp;</span>($acd->{$canonical->{'doc'}})</td>
	<td valign="center" align="left" width="21%">
	 <table border="0" cellspacing="0" cellpadding="0">
	  <tr>
	<td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	<td nowrap background="/wEMBOSS/images/but_pink_back.gif"><a href="#" 
			onClick="parent.popup('$docPath/$name.html', 'helpWindow'); return false;" class="but">Manual</a></td>
	<td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>
    </tr>
    <tr>
	<td width="33%">&nbsp;</td>
	<td align="center" width="33%"> <input type="hidden" name="_action" value="run"> 
	    <input type="hidden" name="_app" value="$name"> <input type="hidden" name="_pwd" value="$projectDir"> 
	    <table border="0" cellspacing="0" cellpadding="0">
		 <tr>
		<td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
		<td nowrap background="/wEMBOSS/images/but_pink_back.gif"><a href="#" onClick="parent.submission(document); return false" 
										name=" _program" class="but">Run $name</a></td>
		<td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
		 </tr>
	    </table>
	</td>
	<td>&nbsp;</td>
	<td>
	    <table border="0" cellspacing="0" cellpadding="0">
		 <tr>
		<td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
		<td nowrap background="/wEMBOSS/images/but_pink_back.gif"><a href='#' onClick="parent.mycookie('$hide', 'hide'); return false;" class="but">
			 @{[ $hide eq 'yes' ? "Show" : "&nbsp;Hide&nbsp;" ]} optional</a></td>
		<td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
		 </tr>
	    </table>
	</td>
    </tr>
   </table>
  </td>
 </tr>
 <tr>
  <td>
   <table width="100%" border="0" align="center" cellpadding="3" cellspacing="0" bgcolor="#D7909B">
    <tr> 
	<td>
	 <table width="100%" border="0" cellpadding="1" cellspacing="0" >
	  <tr> 
	<td align="center" height="24" bgcolor="bb4553" class="titlewhite">&nbsp; 
			 Set the parameters for the run (or accept the defaults...) 
	</td>
	  </tr>
		$paramsHtml
	 </table>
	</td>
    </tr>
   </table>
  </td>
 </tr>
 <tr>
  <td>
   <table width="100%" border="0" align="center" cellpadding="0" cellspacing="1">
    <tr> 
	<td colspan="2" align="center">
	 <table border="0" cellspacing="0" cellpadding="0">
	  <tr> 
	<td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	<td nowrap background="/wEMBOSS/images/but_pink_back.gif">
			<a href="#" onClick="parent.submission(document); return false" 
				  name="_program" class="but">Run $name</a></td>
	<td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>
    </tr>
   </table> 
  </td>
 </tr>
 <tr>
  <td>
   <table width="100%" border="0" align="center" cellpadding="3" cellspacing="0" bgcolor="#D7909B">
    <tr> 
	<td>
	 <table width="100%" border="0" cellpadding="5" cellspacing="0">
	  <tr> 
	<td bgcolor="#FFFFF">
			<div align="center">If you are submitting a long job and 
		  		would like to be informed by email when it finishes,<br> please 
				enter your email address in the space below:<br>
			   		<input name="_email" type="text" size="50" maxlength="100" width="30">
			    </div>
	</td>
	  </tr>
	 </table>
	</td>
    </tr>
   </table>
  </td>
 </tr>
</table>
</form>
</body>
</html>
EOF

}

# # # # # # # # # # # # # # # # # DATATYPES # # # # # # # # # # # # # # # # #

#######################################################################################################################
# simple datatypes
#######################################################################################################################

sub variable {
	 my $cgi = shift;
	 my ($name, $attribs, $canonical, $class) = @_;
	 my $value = $attribs->{$canonical->{'value'}};
	 $value = eval $value;
	 do { no strict 'refs'; $$name= $value; use strict };
	return
"
			 <tr>
			<td class=$class>
			  <input type=hidden name=$name size=25
			  value=$value>
			</td>
			 </tr>
"
}

sub array {&float}

sub boolean {
	 my $cgi = shift;
	 my ($name, $attribs, $canonical, $class) = @_;
	 my $info = ($attribs->{$canonical->{'prompt'}} or
			 $attribs->{$canonical->{'info'}} or
		  $attribs->{$canonical->{'help'}});
	    $info .= "?" unless ($info =~ /\?$/);

	 my ($cgiValue, $default, $onClick) = ("", "", "", "", "");
	 my @checked = ("", "");
	 $default = $attribs->{$canonical->{'def'}};
	 $cgiValue = $cgi->param("$name");
	 if ($default =~ /EMBOSS::/) {
		  undef $cgiValue unless ($attribs->{'_controlParam'}) ;
		  $default = eval $default;
	 }
	 if ($cgiValue){
		  if ($cgiValue =~ /^y|1/i) { $checked[1] = "checked"}
		  else { $checked[0] = "checked"}
	 } else {
		  if ($default =~ /^y|1/i) {$checked[1] = "checked"}
		  else { $checked[0] = "checked"}
	 }
	 do { no strict 'refs'; if ($checked[1]) {$$name= 1} else {$$name = 0}; use strict };
	 if ($attribs->{'_controlParam'}) {$onClick=
		  "onClick= \"this.form._action.value='input'; this.form.target='_self'; this.form.submit()\""}
	return
"
			 <tr>
			<td>
			  <table width=100% border=0 cellpadding=0 cellspacing=0>
				    <tr><td colspan=3 bgcolor=#ECCAD0><img src=/wEMBOSS/images/pix.gif width=1 height=1></td></tr>
				    <tr> 
				      <td height=23 bgcolor=#FFFFFF width=7%>&nbsp;<img src=/wEMBOSS/images/arrow_red_pink.jpg width=8 height=9></td>
				      <td height=23 bgcolor=#FFFFFF width=63%>$info</td>
				      <td height=23 align=right nowrap bgcolor=#FFFFFF width=30%>&nbsp;n 
				        <input type=radio name=$name value=no  $checked[0] $onClick>

				        y 
				        <input type=radio name=$name value=yes $checked[1] $onClick> 
				      </td>
				    </tr>
				 <tr><td colspan=3 bgcolor=#ECCAD0><img src=/wEMBOSS/images/pix.gif width=1 height=1></td></tr>
			  </table>   
			</td>
			 </tr>
"
}

sub integer {
	my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;
	my ($min, $max, $onChange) = ("", "", "");
	my $info = ($attribs->{$canonical->{'info'}} or 
			$attribs->{$canonical->{'prompt'}} or
		  $attribs->{$canonical->{'help'}});
	$min = $attribs->{$canonical->{'min'}} if defined $attribs->{$canonical->{'min'}} ;
	$min = int eval $min if $min =~ "wEMBOSS";
	if ($min or $min eq "0") { $min = "min: $min"}
	$max = $attribs->{$canonical->{'max'}} if defined $attribs->{$canonical->{'max'}};
	$max = int eval $max if $max =~ "wEMBOSS";
	if ($max or $max eq "0") { $max = " max: $max"}
	my ($default, $expect) = &fixdef($attribs->{$canonical->{'def'}},
				                $attribs->{$canonical->{'expect'}});
	my $cgiValue = $cgi->param("$name");
	if ($default =~ /EMBOSS::/) {
		undef $cgiValue unless $attribs->{'_controlParam'} ;
		$default = eval $default;
		$default = "" if not $default;
	}
	if ($cgiValue){ $default = $cgiValue}
	do { no strict 'refs'; $$name= $default; use strict };
	if ($attribs->{'_controlParam'}) {$onChange=
		"onChange= \"this.form._action.value='input'; this.form.target='_self'; this.form.submit()\""}
	return
"
			 <tr>
			<td class=$class> 
			 <table width=100% border=0 cellpadding=0 cellspacing=0>
			  <tr>
			   <td width=15%> <input type=text name=$name size=10
					value=\"$default\" $onChange >
			   </td>
			   <td width=30% > $min$max </td>
			   <td> $info &nbsp; <em>$expect</em></td>
			  </tr>
			 </table>
			</td>
			 </tr>
"
}

sub float {
	 my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;
	my ($min, $max, $onChange) = ("", "", "");
	my $info = ($attribs->{$canonical->{'info'}} or 
			$attribs->{$canonical->{'prompt'}} or
		  $attribs->{$canonical->{'help'}});
	$min = $attribs->{$canonical->{'min'}} if defined $attribs->{$canonical->{'min'}} ;
	$min = eval $min if $min =~ "wEMBOSS"; 
	if ($min or $min eq "0") { $min = "min: $min"}
	$max = $attribs->{$canonical->{'max'}} or $max="" if defined $attribs->{$canonical->{'max'}};
	$max = eval $max if $max =~ "wEMBOSS";
	if ($max or $max eq "0") { $max = " max: $max"}
	my ($default, $expect) = &fixdef($attribs->{$canonical->{'def'}},
				                $attribs->{$canonical->{'exp'}});
	 my $cgiValue = $cgi->param("$name");
	 if ($default =~ /EMBOSS::/) {
		  undef $cgiValue unless $attribs->{'_controlParam'};
		  $default = eval $default;
		  $default = "" if not $default;
	 }
	 if ($cgiValue){ $default = $cgiValue}
	do { no strict 'refs'; $$name= $default; use strict };
	if ($attribs->{'_controlParam'}) {$onChange=
		"onChange= \"this.form._action.value='input'; this.form.target='_self'; this.form.submit()\""}
	return 
"
			<tr>
			 <td class=$class>
			  <table width=100% border=0 cellpadding=0 cellspacing=0>
			<tr>
			 <td width=15%> <input type=text name=$name size=10
				value=$default $onChange >
			 <td>
			 <td width=30% >$min$max</td>
			 <td> $info &nbsp; <em>$expect</em></td>
			</tr>
			 </table>
			</td>
		    </tr>
"
}

sub range {
	 my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;
	my $info = ($attribs->{$canonical->{'info'}} or 
			$attribs->{$canonical->{'prompt'}} or
		  $attribs->{$canonical->{'help'}});
	my ($default, $expect) = &fixdef($attribs->{$canonical->{'def'}},
				                $attribs->{$canonical->{'exp'}});
	 my $cgiValue = $cgi->param("$name");
	 if ($default =~ /EMBOSS::/) {
		  undef $cgiValue unless $attribs->{'_controlParam'};
		  $default =~ s/\-/\.\"\-\"\./;
		  $default = eval $default;
		  $default = "" if not $default;
	 }
	 if ($cgiValue){ $default = $cgiValue}
	do { no strict 'refs'; $$name= $default; use strict };
	return
"
		 <tr>
		<td class=$class>
		 <table width=100% border=0 cellpadding=0 cellspacing=0>
		  <tr>
		   <td width=45%>
		  <input type=text name=$name size=10
		   value=$default>
		   </td>
		   <td>$info <em>$expect</em></td> 
		  </tr>
		 </table>
		</td>
		 </tr>
"
}
sub string {
	my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;
	my $info = ($attribs->{$canonical->{'info'}} or 
			$attribs->{$canonical->{'prompt'}} or
		  $attribs->{$canonical->{'help'}});
	my ($default, $expect) = &fixdef($attribs->{$canonical->{'def'}},
				                $attribs->{$canonical->{'exp'}});
	 my $cgiValue = $cgi->param("$name");
	 if ($default =~ /EMBOSS::/) {
		  undef $cgiValue;
		  $default =~ s/\-/\.\"\-\"\./;
		  $default = eval $default;
		  $default = "" if not $default;
	 }
	 if ($cgiValue){ $default = $cgiValue}
	do { no strict 'refs'; $$name= $default; use strict };
	return
"
			 <tr> 
				<td>
			   <table width=100% border=0 cellpadding=0 cellspacing=0>
			    <tr>
				<td width=45%> <input type=text name=$name size=25 value=$default> 
				</td>
				<td>$info <em>$expect</em></td>  
			    </tr>
			   </table>
			   </tr>
"
}

sub toggle { &boolean }

#######################################################################################################################
# input datatypes
#######################################################################################################################

sub codon  { &matrixf }

sub cpdb  { &matrixf }

sub datafile  { &matrixf }

sub directory {print "<!-- directory -->\n"}

sub dirlist {print "<!-- dirlist -->\n"}

sub discretestates  { &matrixf }

sub distances  { &matrixf }

sub features { &matrixf }

sub filelist  { &matrixf }

sub frequencies  { &matrixf }

sub infile { &matrixf }

sub matrix { &matrixf }

sub matrixf {
	my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;
	my $grepExp = '-f';
	my $info = ($attribs->{$canonical->{'info'}} or 
			$attribs->{$canonical->{'prompt'}} or
		  $attribs->{$canonical->{'help'}});
	my ($default, $expect) = &fixdef($attribs->{$canonical->{'def'}},
				                $attribs->{$canonical->{'exp'}});
	my @values=$cgi->param("$name");
	$default = $values[2]?$values[2]:$values[1]?$values[1]:$values[0]?$values[0]:$default;
	do { no strict 'refs'; $$name= $default; use strict };
	my $typeMessage;
	if    ($attribs->{'datatype'} eq "matrixf") {$typeMessage = "(a floating point scoring matrix)"}
	elsif ($attribs->{'datatype'} eq "matrix")  {$typeMessage = "(an integer scoring matrix)"}
	elsif ($attribs->{'datatype'} eq "codon")   {$typeMessage = "( codon usage table )"}
	elsif ($attribs->{'datatype'} eq "features"){$typeMessage = "( feature table )"}
	my $EMBOSSdataHtml= "";
	if ( $attribs->{'datatype'} =~ m/^codon|^matrix|^datafile/) { # data from EMBOSS data
                my @EMBOSSData;
                my $EMBOSSData;
                if ( $attribs->{'datatype'} eq "codon") {
                        $main::EMBOSSData = "<$main::wEMBOSS_HOME/embossData/codons";
                        $default = "default" unless $default;
                } elsif (  $attribs->{'datatype'} =~ m/matrix/)         {
                        my $isProtein;
                        for ($attribs->{$canonical->{'protein'}}) { $isProtein = eval }
                        if ($isProtein) { $main::EMBOSSData = "<$main::wEMBOSS_HOME/embossData/protMatrices" }
                        else            { $main::EMBOSSData = "<$main::wEMBOSS_HOME/embossData/dnaMatrices"  }
                        $default = "default" unless $default;
                } elsif (  $attribs->{'datatype'} =~ m/datafile/)         {
                        $default = "" unless $default;
                        $main::EMBOSSData = "<$main::wEMBOSS_HOME/embossData/dataFiles";
                }
                eval {
                        open EMBOSSDATA, $main::EMBOSSData;
			$EMBOSSData = join "", <EMBOSSDATA>;
			@EMBOSSData = split /\n/, $EMBOSSData;
                        unshift @EMBOSSData, "default" ;
                        close EMBOSSDATA;
                } or return error("Couldn't read $main::EMBOSSData : $!");

	$EMBOSSdataHtml =
"
			    <tr><td width=45%>
"
	.	scrolling_list (-name=>$name,
						-size=>1,
						-class=>'data',
						-values=>\@EMBOSSData,
						-default=>[$default])
	.
"
				 </td><td>from EMBOSS data</td></tr>
"
	
	} # data from project or local computer
	my $err = "";
	if ($attribs->{'knowntype'}) {
		$attribs->{'knowntype'} = eval $attribs->{'knowntype'} if ($attribs->{'knowntype'} =~"EMBOSS::");
		$grepExp = '-f && /'.$EXTENSION{$attribs->{'knowntype'}} .'/'  if $EXTENSION{$attribs->{'knowntype'}};
		$err = error("$attribs->{'knowntype'}");
	}
        opendir PROJECT, "." or error ("can't open project: $! ");
	my @projectFiles = sort grep {eval $grepExp} readdir PROJECT;
        my @projectFileNames = @projectFiles;
        close PROJECT;
        my $topProject = "";
        ($topProject) = ( cwd() =~ m#/wProjects/(\w+)/# );

        if ($topProject =~ /\w+/ ) {
                opendir TOPPROJECT, "$ENV{HOME}/$topProject" or error ("can't open topProject: $! ");
                my @topProjectFiles = sort grep {eval $grepExp} map { "$ENV{HOME}/$topProject/$_" } readdir TOPPROJECT;
                close TOPPROJECT;
                push @projectFiles, @topProjectFiles;
                foreach my $topProjectFile (@topProjectFiles) {
                        push @projectFileNames, $topProject."/".basename($topProjectFile);
                }
        }

	my $projectFileName; my %labels;
	foreach my $projectFile (@projectFiles) {
		chomp $projectFile;
		$labels{$projectFile} = shift @projectFileNames;
	}
	unshift @projectFiles, "";
return

"
			<tr>
			  <td class=$class>
			   <table width=100% border=0 cellpadding=0 cellspacing=2>
				  <tr><td colspan=2 bgcolor=#ECCAD0><img src=/wEMBOSS/images/pix.gif width=1 height=1></td></tr>
			    <tr><td width=45%></td><td>$info <em>$typeMessage</em></td></tr>
				$EMBOSSdataHtml
			    <tr><td width=45%>
"
	.	scrolling_list (-name=>$name,
						-size=>1,
						-class=>'data',
						-values=>\@projectFiles,
						-default=>[$default],
						-labels=>\%labels)
	.
						
"
				</select>
				 </td><td>from project(s) data</td></tr>
			    <tr><td> <input type=file name=$name size=20></td><td>from local data </td></tr>
				  <tr><td colspan=2 bgcolor=#ECCAD0><img src=/wEMBOSS/images/pix.gif width=1 height=1></td></tr>
				</table>
			    </td>
			   </tr>
"
}

sub pattern {
	my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;
	my $info = $attribs->{$canonical->{'info'}};
	$info = $attribs->{$canonical->{'prompt'}} unless $info;
	$info = $attribs->{$canonical->{'help'}}   unless $info;
        my ($default, $expect) = &fixdef($attribs->{$canonical->{'def'}},
                                                $attribs->{$canonical->{'exp'}});
        my $cgiValue = $cgi->param("$name");
        $default = "" unless $default;
        if ($cgiValue){$default = $cgiValue}
        do { no strict 'refs'; $$name= $default; use strict };
	return
"
                         <tr> 
                                <td>
                           <table width=100% border=0 cellpadding=0 cellspacing=0>
                            <tr>
                                <td width=45%> <input type=text name=$name size=25 value=$default> 
                                </td>
                                <td>$info <em>$expect</em></td>  
                            </tr>
                           </table>
                           </tr>
                         <tr>
                        <td class=$class> 
                         <table width=100% border=0 cellpadding=0 cellspacing=0>
                          <tr>
                           <td width=45%> <input type=text name=pmismatch size=10
                                        value=0 >
                           </td>
                           <td>Accepted mismatchs</td>
                          </tr>
                         </table>
                        </td>
                         </tr>
"

}



sub properties  { &matrixf }

sub regexp {
	my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;
	my $info = ($attribs->{$canonical->{'info'}} or
			   $attribs->{$canonical->{'prompt'}} or
			   $attribs->{$canonical->{'help'}});
	return
"
			       <tr>
			         <td class=$class>
			          <table width=100% border=0 cellpadding=0 cellspacing=0>
			           <tr>
			            <td width=45%>
			             <input type=text name=$name size=25
			             value=$attribs->{$canonical->{'def'}}>
			            </td>
			            <td>$info</td>
			           </tr>
			          </table> 
			         </td>
			       </tr>
"

}

sub scop  { &matrixf }

sub sequence {
  my $idle;
  my $cgi =shift;
  my ($name, $attribs, $canonical, $class) = @_;
  my $info = ($attribs->{$canonical->{'info'}} or
    $attribs->{$canonical->{'prompt'}} or
    $attribs->{$canonical->{'help'}} or
    "Sequence(s)");
    
  my $rev = ""; my $sbegin = ""; my $send = "";
  my ($seqName, $type, $length, $begin, $end, $seqComment, $message)  =("", "any", "", "", "", "filename or USA<em> (dbname:entry)</em><br>", "");
  my @checked = ("", "", "checked");
  my @values = (); my %labels={};
  my $databases;
  my $radioHtmlChoice ="";
  if (open SHOWDB, "$main::EMBOSS_BIN/showdb -only -auto | ") {
    $databases = join "\t", <SHOWDB>;
    $databases =~ s/[\t\s]+/ /g;
  } else { error("Unable to run SHOWDB  : $!") }
  for ($attribs->{$canonical->{'type'}}) {
    /wEMBOSS/ and do { $_ = eval };
    $type = $_ if $_;
    if    (/^d$|dna|nuc/i) {
      $message = "(nucleic sequence(s) only)";
      last;
    }
    elsif (/^p$|protein/i) {
      $message = "(proteic sequence(s) only)";
      last;
    }
  }

  my $checked = "c"; # default value
  $checked = $cgi->param("_radio_$name")if defined $cgi->param("_radio_$name");
  @checked = ("checked", "", "") if ($checked eq "a");
  @checked = ("", "checked", "") if ($checked eq "b");
  $seqName = $cgi->param($name) ;
  chomp $seqName;
  my $infoType= "";
  if ($seqName) {
    my ($dB, $list, $oldSeqName) = ("", "", "");
    if (ref $seqName eq "Fh"){ # a file to upLoad
        my $fileName = $seqName;
      $fileName =~ s/.*\\//;
      $fileName = basename($fileName);
      error ("$seqName, $fileName");
      uploadfile($seqName, "$fileName");
      $seqName = $fileName;
      $seqComment = "the sequence is incorporated in your project<br>";
                }
                if ($seqName =~ /([\w\.]+)(\:\w*\*)/) { # identifier is DB:[accNum|ID]
                $dB =$1;
                $oldSeqName = $seqName;
      if (open SHOWDB, "$main::EMBOSS_BIN/showdb -only -type -database $dB -auto | ") {
        ($dB, $infoType )  = split /\s+/ ,<SHOWDB>;
      } else { error ("Unable to run SHOWDB with $dB : $!") }
    } else {
      if ($seqName =~ /^(\@|list\:\:)([\w\.]+)/) { # identifier is a list of sequences
            $list = $2;
            $oldSeqName = $seqName;
            if (open LISTDB, "<$list") {
              do {$seqName = <LISTDB>;} until ($seqName =~ m/^(\s*)([\w\.\:\-]+)/ or eof(LISTDB));
                  $seqName = $2;
                  close LISTDB;
            } else { error ( "Unable to open $list : $!")}
          }
          if ($databases !~ /$seqName/ || $seqName =~ /^\!(.+)/) {
          # ident. is a fileName (sequence, MSA, etc) in the current project
            if( $seqName =~ /^\!(.+)/ ) {
                  $seqName =~ s/!/./;
                  $seqName =~ s/-/./;
                  $seqName =~ s/:/\//;
                  $seqName =~ s/-/./;
                  my $pwd = $cgi->param('_pwd');
                  $seqName = $pwd."/".$seqName;
            }
            if (open INFOSEQ, "$main::EMBOSS_BIN/infoseq -only -type -length -auto $seqName | ") {
                  my $infoseq = join "", <INFOSEQ>;
                  if ($infoseq =~ /^Type/)  {($idle, $idle, $infoType, $length)  = split /[\s\n]+/ ,$infoseq}
                  elsif ($infoseq)         {($infoType, $length)                = split /\s+/     ,$infoseq}
                  $seqName = $oldSeqName if $list;
                  if ($length) {
                    close INFOSEQ;
                    no strict 'refs';
                    ($begin, $end) = (1, $length);
                    ($$name{"name"}, $$name{"begin"}, $$name{"end"}, $$name{"length"}) = ($seqName, 1, $length, $length);
                  use strict;
                  } else { error ("'$seqName' isn't recognised as a sequence by EMBOSS")}
            } else { error ("Unable to run INFOSEQ with $seqName : $!") }
          } else  { error ("Don't use a database name as is, use an EMBOSS USA instead!") }
          if ($SEQUENCE1) {$SEQUENCE2 = $seqName; $SEQUENCE2 =~ s/^.*?\://}
          else            {$SEQUENCE1 = $seqName; $SEQUENCE1 =~ s/^.*?\://}
    }
    no strict 'refs';
    if ($infoType =~ /p/i) {$$name{"protein"}= 1; $$name{"nucleic"} = 0}
    else                   {$$name{"protein"}= 0; $$name{"nucleic"} = 1}
    use strict;
    if ($infoType eq "N") {$rev = checkbox(-name=>'sreverse',-value=>'yes',-label=>'rev')};   
    if ( $attribs->{'datatype'} eq "sequence") {
          $sbegin = "begin" . textfield(-name=>'sbegin', -size=>8, -value=>$begin, -override=>'true');
          $send   = "end" .   textfield(-name=>'send',   -size=>8, -value=>$end, -override=>'true') . $infoType;
    } else {
    			$sbegin = "begin ($begin)" . textfield(-name=>'sbegin',  -size=>8, -override=>'true');
          $send   = "end ($end)" .     textfield(-name=>'send',    -size=>8, -override=>'true') . $infoType; 
    }
  }
  if ($checked eq "a") {
		$radioHtmlChoice = "$seqComment($type type)" . textfield(	-name=>$name,
                									-value=>$seqName,
                									-size=>20,
                									-onChange=>"this.form._action.value='input'; this.form.target='_self'; this.form.submit()");
  } elsif ($checked eq "b") {
    $radioHtmlChoice =" upload a sequence ($type type) file <br>" . 
        							filefield(-name=>$name,
                        				-size=>32,
                        				-onChange=>"this.form._action.value='input'; 
                        										this.form._radio_$name\[0].checked=true;
                        										this.form.target='_self';
                        										this.form.submit()");


  }
	elsif ($checked eq "c") {
		my (@seqList, @nucList, @protList, $seq );
                $seqComment ="select a USA/filename";
                if ($type =~ /dna|nuc|^n$|any/i ) {
                	if ( open LIST, "nucList") {
						@nucList = <LIST>;
                                close LIST;
                                unshift @nucList, "# Nucleics";
                                push @seqList,  @nucList;
					} else { error("nucList doesn't exist"); }
                }
                if ($type =~ /^p$|prot|any/i) {
					if ( open LIST, "protList") {
                                @protList = <LIST>;
                                close LIST;
                                unshift @protList, "# Proteins";
                                push @seqList,  @protList;
                } else { error("protList  doesn't exist"); }
                }
                if (@seqList) {
                        my ($optionValue, $optionComment) = ("", "");
#                        push @values, ""; $labels{""}= "$optionValue $type type";
						push @values, ""; $labels{""}= "";                        
                        my $i = -1;
                        foreach (@seqList) {
                                $i += 1;
                                chomp;
                                next if /^\s*#|^\s*$/;
                                $optionComment = "";
                                $_ =~ s/^\s+//;
                                ($optionValue, $optionComment) = split (/ /, $_, 2);
                                $optionValue =~s/\r//g;
                                $optionComment = "" unless defined $optionComment;
                                $optionComment = substr($optionComment,0,24)."...";
                                push @values, $optionValue; $labels{$optionValue}= "$optionValue $optionComment";
                        }
                        $radioHtmlChoice = "$seqComment (type : $type)<br>" . scrolling_list(-name=>$name,
                                                                              -size=>'1',
                                                                              -class=>'data',
                                                                              -values=>\@values,
                                                                              -default=>[$seqName],
                                                                              -labels=>\%labels,
                                                                              -onChange=>"this.form._action.value='input';this.form.target='_self';this.form.submit()");
        }
  }

	return
"
                           <tr>
                          <td>
                            <table width = 100% border=0 cellpadding=0 cellspacing=0>
                                 <tr><td bgcolor=#ECCAD0 colspan=2 ><img src=/wEMBOSS/images/pix.gif width=1 height=1></td></tr>
                                 <tr> 
                                        <td width=45% ></td>
                                      <td><input type=radio name=_radio_$name value=a $checked[0] 
                                        onClick=\"this.form._action.value='input'; this.form.target='_self'; this.form.submit()\">
                                         from the EMBOSS databases or a current project file
                                   </td>
                                  <tr>
                                   <td class=$class>\u$info </td>
                                   <td><input type=radio name=_radio_$name value=b $checked[1] 
                                        onClick=\"this.form._action.value='input'; this.form.target='_self'; this.form.submit()\">
                                        from the local computer/PC 
                                   </td>
                                  </tr>
                                  <tr><td></td>
                                   <td><input type=radio name=_radio_$name value=c $checked[2] 
                                        onClick=\"this.form._action.value='input'; this.form.target='_self'; this.form.submit()\">
                                        from the sequence selector (nucList or protList)
                                   </td>
                                  </tr>
                                  <tr><td colspan=2><em>$message</em></tr>
                                  <tr>
                                   <td> 
             $radioHtmlChoice   
                           </td>
                           <td>
                              $sbegin
                              $send 
                              $rev
                                </td>
                                </tr>
                                <tr><td colspan=2 bgcolor=#ECCAD0><img src=/wEMBOSS/images/pix.gif width=1 height=1></td></tr>
                         </table>
                        </td>
                         </tr>
"


}


sub seqset { &sequence }

sub seqall { &sequence }

sub seqsetall { &sequence }

sub tree  { &matrixf }

#######################################################################################################################
# lists datatypes
#######################################################################################################################

sub list {
	 my $cgi = shift;
	my $onChange = "";
	my ($name, $attribs, $canonical, $class) = @_;
	my $size = "1"; my $multiple = "";
	my $info = ($attribs->{$canonical->{'info'}} or 
			$attribs->{$canonical->{'prompt'}} or
				$attribs->{$canonical->{'head'}} or
		  $attribs->{$canonical->{'help'}});
	my $delim = ($attribs->{$canonical->{'delim'}} or ";");
	my @values = split (/$delim\s*/, $attribs->{$canonical->{'value'}});
	if ($attribs->{$canonical->{'max'}} > 1) {
		$size = "'".@values."'";  
		$multiple = 'true';
	}
	my $selected="";
 	if (defined  $cgi->param("$name")) {$selected  = $cgi->param("$name")}
	elsif (defined $attribs->{$canonical->{'def'}}) {$selected  = $attribs->{$canonical->{'def'}}}
	if ($attribs->{'_controlParam'}) {$onChange=
		"this.form._action.value='input'; this.form.target='_self'; this.form.submit()"}
	do { no strict 'refs'; $$name= $selected; use strict };  # $$name is usable in expressions
	my @numbers; my %labels;
	foreach my $choice (@values) {
		my ($number, $text) = split (/\s*:\s*/, $choice, 2);
		$labels{$number} = $text;
		push @numbers, $number;

	}

	return
"
			 <tr>
			  <td class=$class>
			   <table width = 100% border=0 cellpadding=0 cellspacing=0>
			    <tr>
				 <td width=45%>
"
	.	scrolling_list(-name=>$name,
						-size=>$size,
						-multiple=>$multiple,
						-class=>'data',
						-values=>\@numbers,
						-labels=>\%labels,
						-default=>[$selected],
						-onchange=>$onChange)
	.
"
				 </td>
				 <td> $info
				 </td>
			    </tr>
			   </table>
			  </td>
			 </tr>
"
}

sub selection {
	my $cgi = shift;
	my $onChange = "";
	my $size = "1"; my $multiple = "";
	my ($name, $attribs, $canonical, $class) = @_;
	my $info = ($attribs->{$canonical->{'info'}} or 
				$attribs->{$canonical->{'head'}} or
			$attribs->{$canonical->{'prompt'}} or
		  $attribs->{$canonical->{'help'}});
	my $delim = ($attribs->{$canonical->{'delim'}} or ";");
	my @values = split (/$delim\s*/, $attribs->{$canonical->{'value'}});
	if ($attribs->{$canonical->{'max'}} > 1) {
                $size = "'". @values . "'";
                $multiple = 'true';
        }
	 my $selected="";
	 if (defined  $cgi->param("$name")) {$selected  = $cgi->param("$name")}
	 elsif (defined $attribs->{$canonical->{'def'}}) {$selected  = $attribs->{$canonical->{'def'}}}
	 if ($attribs->{'_controlParam'}) {$onChange=
		 "this.form._action.value='input'; this.form.target='_self'; this.form.submit()"}
	my $i=1; my %labels ; my @i;  
	foreach my $choice (@values) {
		$labels{$i} = $choice ;
		push @i, $i;
		$i++;
	}
	return
"
			 <tr>
			  <td class=$class>
			   <table width = 100% border=0 cellpadding=0 cellspacing=0>
			    <tr>
				 <td width=45% >
"
	. scrolling_list(-name=>$name,
                     -size=>$size,
		     -multiple=>$multiple,
                     -class=>'data',
                     -values=>\@i,
                     -default=>[$selected],
                     -labels=>\%labels,	
                     -onChange=>$onChange)
	.
"
				 </td>
				 <td>$info
			    </tr>
			   </table>
			  </td>
			 </tr>
"
}

#######################################################################################################################
# output datatypes
#######################################################################################################################


my @aformats = qw(xxx simple fasta msf clustal mega meganon nexus nexusnon phylip phylipnon selex treecon srs
				  xxxx  tcoffee pair markx0 markx1 markx2 markx3 markx10 srspair score );

my %aformats = (
	    xxx => '--- Multiple sequence formats ---' ,
	    simple => 'old EMBOSS format' ,
	    fasta => 'fastA format with gaps' ,
	    msf => 'GCG MSF format' ,
	    clustal=>'CLUSTAL .aln',
	    mega=>'Mega interleaved',
	    meganon=>'Mega sequential',
	    nexus=>'NEXUS/PAUP interleaved',
	    nexusnon=>'NEXUS/PAUP sequential',
	    phylip=>'PHYLIP interleaved',
	    phylipnon=>'PHYLIP sequential',
	    selex=>'SELEX',
	    treecon=>'Treecon',
	    srs => 'SRS format' ,
	    xxxx => '--- Pair-wise sequence formats ---' ,
        tcoffee => 'TCOFFEE format' ,	    
	    pair => 'old EMBOSS format' ,
	    markx0 => 'fastA format' ,
	    markx1 => 'fastA format marking differences' ,
	    markx2 => 'fastA format showing differences only' ,
	    markx3 => 'simple fastA format' ,
	    markx10 => 'simple fastA format with comments' ,
	    srspair => 'SRS format' ,
	    score => 'show scores only' 
);


my @rformats = qw( embl genbank gff dasgff pir swiss listfile dbmotif diffseq excel feattable motif nametable
					regions seqtable simple srs table tagseq );

my %rformats = (
	    embl => 'EMBL feature table format',
	    genbank => 'GenBank feature table format',
	    gff => 'GFF feature table format',
	    dasgff =>'DASGFF XML',
	    pir => 'PIR feature table format',
	    swiss => 'SwissProt feature table format',
	    listfile => 'EMBOSS list file',
	    dbmotif => 'DbMotif format',
	    diffseq => 'EMBOSS diffseq format',
	    excel => 'tab-delimited table format',
	    feattable => 'EMBOSS feattable format',
	    motif => 'EMBOSS motif format',
	    nametable => 'simple table with sequence name',
	    regions => 'Regions format including feature type',
	    seqtable => 'Table format including feature sequence',
	    simple => 'SRS format without sequence',
	    srs => 'SRS format',
	    table => 'Table format',
	    tagseq => 'EMBOSS tagseq format without sequence'
);



sub align {
	my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;
	return
"
			       <tr>
			         <td class=$class>
			          <table width=100% border=0 cellpadding=0 cellspacing=2>
			           <tr>
			            <td width=45%>
"
	.	scrolling_list (-name=>'aformat',
						-size=>1,
						-class=>'data',
						-values=>\@aformats,
						-labels=>\%aformats,
						-default=>[$attribs->{'aformat'}])
	.
"
			            </td>
			            <td>Format of sequences alignement output file</td>
			           </tr>
			          </table>
			         </td>
			       </tr>
"
}

sub featout {
	my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;
	my $cgiValue = $cgi->param("$name");
	return 
"                               <tr>
                                 <td class='optional'>
                                   <table width=100% border=0 cellpadding=0 cellspacing=2>
                                       <tr><td colspan=3 bgcolor=#ECCAD0><img src=/wEMBOSS/images/pix.gif width=1 height=1></td></tr>
                                       <tr>
                                         <td colspan=2 nowrap width=45%>
"
 	.	 scrolling_list(-name=>'offormat',
						-size=>1,
						-class=>'data',
						-values=> ['gff2', 'gff3', 'embl', 'swissprot', 'genbank', 'pir', 'dasgff'],
						-labels=> { gff2=>'GFF2',
									gff3=>'GFF3',
									embl=>'EMBL',
									swissprot=>'SWISSPROT',
									genbank=>'GenBank',
									pir=>'PIR',
									dasgff=>'DASGFF XML'
								   },
						-default=> ['gff3']
						)
	.
"                                        
                                         </td>
                                         <td>Feature output format </td>
                                     </tr>
                                     <tr>
                                         <td height=23 bgcolor=#FFFFFF width=7%>&nbsp;<img src=/wEMBOSS/images/arrow_red_pink.jpg width=8 height=9></td>
                                         <td align=left height=23 bgcolor=#FFFFFF width=63%>Separate files for each entry?</td>
                                         <td width=75 height=23 align=right nowrap bgcolor=#FFFFFF>&nbsp;n
                                           <input type=radio name=ofsingle value=no  checked>
                                           
                                           y
                                           <input Type=radio name=ofsingle value=yes>
                                         </td>
                                     </tr>
                                     <tr><td colspan=3 bgcolor=#ECCAD0><img src=/wEMBOSS/images/pix.gif width=1 height=1></td></tr>
                                     </table>
                                   </td>
                               </tr>
"
}

sub outcodon {&outfile}

sub outcpdb {&outfile}

sub outdata {&outfile}

sub outdir {print "<!-- outdirdir -->\n"}

sub outdiscrete {&outfile}

sub outdistance {&outfile}

sub outfreq {&outfile}

sub outfile {
	my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;
	my $info= ($attribs->{$canonical->{'info'}} or
			 $attribs->{$canonical->{'prompt'}} or
			 $attribs->{$canonical->{'help'}}); 
	my $default = $attribs->{$canonical->{'def'}};
	$default = $name if $default eq 'stdout';
	do { no strict 'refs'; $$name= $default; use strict };
	if ( $attribs->{'datatype'} eq "outfile") {
		return ;
	} else {
		$info = 'Output codon usage file name' if !$info ;
		return
"
			       <tr>
			         <td class=$class>
			          <table width = 100% border=0 cellpadding=0 cellspacing=0>
			           <tr
			            <td width=45%>
"
	.	 scrolling_list(-name=>'oformat2',
						-size=>1,
						-class=>'data',
						-values=> ['emboss', 'gcg', 'cutg','cutgaa', 'spsum', 'cherry', 'transterm', 'codehop','staden'],
						-labels=> { emboss=>'EMBOSS',
									gcg=>'GCG',
									cutg=>'CUTG',
									cutgaa=>'CUTG with amino acids',
									spsum=>'CUTG species summary file',
									cherry=>'Mike Cherry\' codon usage db',
									transterm=>'TransTerm',
									staden=>'Staden with numbers'
								   }
						)
	.
"
			            </td>
			            <td>$info</td>
			           </tr>
			          </table>
			         </td>
			       </tr>
"			            

	}

}

sub outfileall {&outfile}

sub outmatrix {&outfile}

sub outmatrixf {&outfile}

sub outproperties {&outfile}

sub outscop {&outfile}

sub outtree {&outfile}

sub report {
	   my $cgi = shift;
	   my ($name, $attribs, $canonical, $class) = @_;
	   my $info = "Output report file name";
	return
"
			       <tr>
			         <td class=optional><!-- <input type=hidden name=$name value=$name> -->
			          <table width=100% border=0 cellpadding=0 cellspacing=2>
			           <tr>
			            <td width=45%>
"
	. scrolling_list (	-name=>'rformat',
						-size=>1,
						-class=>'data',
						-values=>\@rformats,
						-labels=>\%rformats,
						-default=>[$attribs->{'rformat'}])
	.
"
			           </td>
			           <td>Report format
			           </td>
			          </tr>
			         </table>
			        </td>
			       </tr>
"
}

sub seqout {
	my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;

	# will eventually have to deal with the 'features' attribute here, but not
	# right now...
	my $info = $attribs->{$canonical->{'info'}};
	$info = "File format for output sequence" unless $info;
	return
"
			 <tr>
			<td class=$class>
			 <table width = 100% border=0 cellpadding=0 cellspacing=2>
			  <tr>
			   <td width=45%>
"
	.	scrolling_list (-name=>'osformat',
						-size=>1,
						-class=>'data',
						-values=> [	'gcg', 'emblold', 'emblnew', 'swissold', 'swissnew', 'fasta', 'ncbi', 'gifasta', 'nbrf', 'genbank', 'genpept', 'gff2', 'gff3', 'ig', 'codata', 'strider',
								    'acedb', 'staden', 'experiment', 'text', 'fitch', 'msf', 'clustal', 'selex', 'phylip', 'phylipnon', 'asn1', 'hennig86', 'mega', 'meganon', 'nexus',
									'nexusnon', 'jackknifer', 'jackknifernon', 'treecom', 'mase', 'das', 'dasdna', 'fastq-sanger', 'fastq-illumina', 'fastq-solexa'],
						-labels=> {	gcg=>'GCG', 
			    					emblold=>'EMBL old',
			    					emblnew=>'EMBL new',
			    					swissold=>'SwissProt old',
			     					swissnew=>'SwissProt new',
			     					fasta=>'Pearson fastA',
			     					ncbi=>'NCBI fastA',
			     					gifasta=>'NCBI fastA with GI',
			     					nbrf=>'NBRF (PIR)',
			     					genbank=>'GenBank',
			     					genpept=>'GenPept',
			     					gff2=>'GFF2',
			     					gff3=>'GFF3',
			     					ig=>'Intelligenetics',
			     					codata=>'CODATA',
			     					strider=>'DNA Strider',
			     					acedb=>'ACeDB',
			     					staden=>'Staden',
			     					experiment=>'Staden experiment',
			     					text=>'plain text',
			     					fitch=>'Fitch',
			     					msf=>'GCG MSF',
			     					clustal=>'CLUSTAL .aln',
			     					selex=>'SELEX',
			     					phylip=>'PHYLIP interleaved',
			     					phylipnon=>'PHYLIP sequential',
			     					asn1=>'ASN.1',
			     					hennig86=>'Hennig86',
			     					mega=>'Mega interleaved',
			     					meganon=>'Mega sequential',
			     					nexus=>'NEXUS/PAUP interleaved',
			     					nexusnon=>'NEXUS/PAUP sequential',
			     					jackknifer=>'Jackknifer interleaved',
			     					jackknifernon=>'Jackknifer sequential',
			     					treecon=>'Treecon',
			     					mase=>'MASE',
			     					das=>'DASSEQUENCE XML',
			     					dasdna=>'DASDNA XML',
			     					'fastq-sanger'=>'fastQ Sanger',
			     					'fastq-illumina'=>'fastQ Illumina',
			     					'fastq-solexa'=>'fastQ Solexa'},
			     			-default=>['fasta'])
	.
"

			   </td>
			   <td>$info</td>
			  </tr>
			 </table>
			   </td>
			 </tr>
"
}

sub seqoutset {&seqout}

sub seqoutall { &seqout }

#######################################################################################################################
# graphics datatypes
#######################################################################################################################

sub graph {
	my $cgi = shift;
	my ($name, $attribs, $canonical, $class) = @_;
	my $info = ($attribs->{$canonical->{'info'}} or 
			$attribs->{$canonical->{'prompt'}} or
			"Output graphic format");
	my ($graphType, $selected) = ("", "selected");
	$graphType  = $cgi->param("$name") if defined  $cgi->param("$name");
	$selected = "" unless $graphType eq "cps"; 
	do { no strict 'refs'; $$name= $selected; use strict };
	return
"
			 <tr>
			<td class=$class>
			 <table width=100% border=0 cellpadding=0 cellspacing=0>
			  <tr>
			   <td width=45%>
			     <input type=hidden name=goutfile value=default>
"
	.	scrolling_list(-name=>$name,
						-size=>1,
						-class=>'data',
						-values=> ['png', 'cps','pdf'],
						-labels=> { png=>'PNG', cps=>'PostScript', pdf =>'PDF'},
						-default=> [ 'png' ],
					)
	.
"
				 </td>
			   <td>$info</td>
			  </tr>
			 </table>	
			</td>
			 </tr>
"
}

sub xygraph {
	&graph;
}

#######################################################################################################################
# wemboss section datatypes
#######################################################################################################################

sub section {
	   my $cgi = shift;
	   my ($name, $attribs, $canonical) = @_;
	   $name = uc $name;
	   $SECTIONWIDTH=  $SECTIONWIDTH - 15;
	return
"
			   <tr> 
			     <!-- td background=/wEMBOSS/images/back_program.jpg-->
			     <td bgcolor=#FFFFF>
			       <table width=$SECTIONWIDTH border=0 align=center cellpadding=0 cellspacing=4>
			         <tr><td align=left><span class=section>$name</span></td>
			         </tr>
"
}

sub endsection {
	   $SECTIONWIDTH=  $SECTIONWIDTH + 15;
	return
"
			       </table>
			     </td>
			   </tr>
			   <tr> 
			     <td bgcolor=#ECCAD0><img src=/wEMBOSS/images/pix.gif width=1 height=1></td>
			   </tr>
"
}


sub error {
	my $message = shift;

	if (open LOG, ">>$main::wEMBOSS_HOME/logs/error.log") {
		print LOG scalar localtime(), " -->\n$message";
		close LOG;
	} else {
		warn "couldn't write to $main::wEMBOSS_HOME/logs/error.log: $!";
	}
	$message = CGI::escapeHTML($message);
	
	return
"
		 <tr>
		  <td bgcolor=#ECCAD0>
		<table cellpadding=4 cellspacing=0 border=0 width=100%>
			<tr>
				<th class=error>Warning</th>
			</tr>
		</table>
		<table cellpadding=8 cellspacing=0 border=0 width=100%>
			<tr>
				<td class=inner><pre>$message</pre></td>
			</tr>
		</table>
		  </td>
		 </tr>
"
}

# fixerror($path)
#
# examine the specified error file and return an array containing only those
# lines that are actually errors...
#
# $path is the path to the error file
#
sub fixerror {
	my $path = shift;
	my @returns;

	open ERROR, "<$path" or die "couldn't read $path: $!";
	while (<ERROR>)  {
		chomp;
		s/^\s+//;
		s/\s+$//;
		next unless length;
		next if /^created/i;
		next if /^scanning/i;
		next if /^..clustalw/i;
		push @returns, $_;
	}
	close ERROR;

	return @returns;
}

# fixdef($default, $expect)
#
# according to the EMBOSS ACD definition, $default is the default value of a
# parameter, while $expect is a human-readable explanation of that value, in
# the event that $default is an expression.
#
# in wEMBOSS, $default is the default value of the input field.  so, if it's
# an expression, we need to blank it out and print the explanation.  otherwise,
# we're free to use it, so we simply return it unchanged...
#
sub fixdef {
	my ($default, $expect) = @_;
	
	if ($expect) {
		return ($default, $expect =~ /^if/i ? "(\u$expect)"
				                    : "(default is \l$expect)");
	} else {
		return ($default, "");
	}
}

sub errorPage {
	my $message = shift;
	my $warn = "";
	# log the error...
	if (open LOG, ">>$main::wEMBOSS_HOME/logs/error.log") {
		print LOG scalar localtime(), " --> $message\n";
		close LOG;
	} else {
		$warn = "couldn't write to $main::wEMBOSS_HOME/logs/error.log: $!";
	}
	$message = CGI::escapeHTML($message);
	print <<EOF;
<html>
<head>
<title>wE error</title>
<link rel="stylesheet" type="text/css" href="/wEMBOSS/wEMBOSS.css">
</head>
<body>
<h1>wEMBOSS: error...</h1>
<p>$message ( $ warn )</p>
</body>
</html>
EOF
	return ();

}

sub uploadfile {
	my ($fh, $outfile) = @_;
	open UPLOAD, ">$outfile"
	  or return errorPage("couldn't write to $outfile: $!");
	print UPLOAD <$fh>;
	close UPLOAD;
}

1
