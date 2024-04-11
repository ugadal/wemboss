# # # # # # # # # # # # # # # run action # # # # # # # # # # # # # # #

=item programRun($cgi)

Prepare the command line for the requested EMBOSS program using EMBOSS qualifiers 
specified in the given CGI object. Start the run and present an output page to the user.

=cut


package wEMBOSS::runAction;

use IPC::Open3;

#use POSIX qw( tmpnam );

use POSIX qw (sys_wait_h );

use Storable;

use Cwd qw ( chdir );

use Cwd;

use strict;

$|=1;

sub programRun {
	print STDERR "[ ", scalar localtime(), " ] in run method...\n"
	  if $main::VERBOSE;
	my $cgi = shift;
	my $programName = $cgi->param('_app');
	my $projectDir  = $cgi->param('_pwd');
	chdir $projectDir or return errorPage ("couldn't chdir to  $projectDir : $!");
	
	# enforce exclude list here...
	#
	open EXCLUDE, "$main::wEMBOSS_HOME/embossData/exclude"
	  or warn "couldn't read $main::wEMBOSS_HOME/embossData/exclude: $!";
	return errorPage("$programName has been excluded") if grep /^$programName/, <EXCLUDE>;
	close EXCLUDE;

	# spawn a child process to execute the command.  First define locally
	# scoped signal handlers that can kill the process if the user presses
	# the stop button or accidentally breaks the connection.  Then start
	# executing the command in a child process.  Lastly, enter into a loop to
	# periodically update the screen, exiting only when the child terminates
	# and we pick up SIG_CHILD...
	#
	my $email = $cgi->param('_email');
	if ($email) {
		open EMAIL, ">$projectDir/.email"
		  or die "couldn't create $projectDir/.email: $!";
		print EMAIL "$email\n";
		close EMAIL;
	}
	my $startTime = time();
	utime $startTime, $startTime, $projectDir or return errorPage (" Unable to modify acces time of $projectDir : $!");

	# $applDir : directory where all outputfiles fron the current application are allocated
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($startTime);
	$year = $year -100; $mon += 1;
	$year = "0" . $year if $year =~/^[1-9]$/;
	$mon  = "0" . $mon  if $mon  =~/^[1-9]$/;
	$mday = "0" . $mday if $mday =~/^[1-9]$/;
	$hour = "0" . $hour if $hour =~/^[1-9]$/;
	$min  = "0" . $min  if $min  =~/^[1-9]$/;
	$sec  = "0" . $sec  if $sec  =~/^[1-9]$/;
#	my $applDir = "$projectDir/$programName.$year.$mon.$mday:$hour.$min.$sec";
#	my $applDir = "$projectDir/.".$programName.".".$year.".".$mon.".".$mday.":".$hour.".".$min.".".$sec;
	my $applDir = ".".$programName.".".$year.".".$mon.".".$mday.":".$hour.".".$min.".".$sec;
	mkdir $applDir or return errorPage ("couldn't mkdir directory $applDir");
	$ENV{EMBOSS_OUTDIRECTORY} = "$applDir";
	print STDERR "[ ", scalar localtime(), " ] creating session directory...\n"
		if $main::VERBOSE;
	my @command = commandLine ($cgi, $programName, $projectDir, $applDir);
	# projectUrl is the URL of the project directory.
	my $projectUrl = "/wEMBOSS_cgi/catch?_action=view&_pwd=$projectDir";
#	chdir $applDir or return errorPage ("couldn't chdir to  $applDir : $!");
	print STDERR "[ ", scalar localtime(), " ] spawning child process...\n"
	  if $main::VERBOSE;
	SPAWN: {
		no strict;
		
		local $child = 0;
		open ERRORS, ">$projectDir/error"
		  or die "couldn't create $projectDir/error: $!";
		local $SIG{'PIPE'} = sub {
			warn "received SIG_PIPE, killing pid $child" if $main::VERBOSE;
			if ($child) {
				kill 'KILL', $child;
			}
			exit 1;
		};
		local $SIG{'TERM'} = sub {
			warn "received SIG_TERM, killing pid $child" if $main::VERBOSE;
			if ($child) {
				kill 'KILL', $child;
			}
			exit 1;
		};
## openMosix
#		@command = ( "mosrun", "-F", "-j2,3,4", "-l", @command );
##
		$child = open3(\*DUMMY, ">&ERRORS", ">&ERRORS", @command);

		# if the user has entered their email address, generate a temporary
		# placeholder where their output will be and tell them where to find
		# it...
		#
		if ($email) {
			return if indexHtmlEmail ($programName, $applDir, $startTime); 
			htmlWaitChoice ($email, $programName, $projectUrl, $applDir);
                        until (waitpid $child, WNOHANG) {
				sleep 1;
                        }
			resultIndexFile($programName, $projectDir, $applDir, $projectUrl, ($? >> 8), join " ", @command);
			# thanks to Perl/Unix dichotomy, system returns false when nothing
			# went wrong (note that we have to send mail from a separate program
			# because Mail::Mailer dies with taint checking enabled even with the
			# parameters laundered and I know of no way to control taint checking
			# save the command line switch -T...)
			system $^X, "$main::wEMBOSS_HOME/email.pl", $email, $programName, $startTime, "http://$ENV{HTTP_HOST}$projectUrl&_file=$applDir/index.html"
				and	die "couldn't send email for $applDir: $!";
			print "</body> \n </html>";
		} else {
			# while the child is working, print some pretty distractors so the
			# user knows we're still alive (also, we need to be able to detect
			# SIG_PIPE, so we have to keep trying to print...)
			#
			htmlWaitEndOfExecution ($programName);
                        until (waitpid $child, WNOHANG) {
                                print ".\n";
                                sleep 1;
                        }
			resultIndexFile($programName, $projectDir, $applDir, $projectUrl, ($? >> 8), join " ", @command);
			print <<EOF;
			<script language="javascript"> location.replace("$projectUrl/&_file=$applDir/index.html");
			</script> <noscript> <p>Done... Please
			<a href="$projectUrl&_file=$applDir/index.html">click here</a> to view your output...
			<i>(note also that this wouldn't be necessary if you had a
			JavaScript-aware browser)</i></p>  </body> \n </html>
EOF
		}
		close ERRORS;
	}
}



sub commandLine {
	# construct the command line...
	my $cgi = shift;
	my $programName = shift;
	my $projectDir = shift;
	my $applDir = shift;
#	my $acd = eval { parseACD("$EMBOSS_HOME/acd/$programName.acd") } or do {
	my $acd = retrieve "$main::wEMBOSS_HOME/sacd/$programName".".sacd" or do {
		warn "SECURITY: attempt to run non-EMBOSS program: $@";
		return errorPage("$programName is not a valid EMBOSS application");
	};
	print STDERR "[ ", scalar localtime(), " ] building command line...\n"
		if $main::VERBOSE;
	my @command = ($programName);
	my @secondS = ();
	foreach my $param ($cgi->param) {
		next if $param =~ /^_/; # ignore our control arguments
		my @values = ($cgi->param($param));
		my $datatype = $acd->{'param'}->{$param}->{'datatype'};
		next if $datatype eq 'variable';
		if (@values > 1) {
			my $fileName;
			if ($datatype =~ /^list|^select/) {
				push @command, ("-$param", join ',', @values);
			} else {
                                if ($param =~ /^sbegin$|^send$/) {
                                       	push @command, ("-$param", $values[0]) if $values[0];
                                       	push @secondS, ("-$param", $values[1]) if $values[1];
                                } elsif ($param =~ /^sreverse$/) { 
                                       	if ($values[0] eq "yes") {push @command, "-$param"}
                                       	if ($values[1] eq "yes") {push @secondS, "-$param"}
                                } else {

# 					/^codon|^cpdb|^datafile|^discretestates|^distances|^filelist|^frequencies|^infile|^matrix|^properties|^scop|^tree/ datatype
					foreach my $item (reverse @values) { # order of priority :  upload PC file then project file then EMBOSS data file
						next unless length $item;
						if (ref $item eq "Fh"){
							warn "$item\n" if $main::VERBOSE;
							($fileName = $item)=~ s/.*[\\\/]//;
							uploadfile($item,  "$projectDir/$fileName");
							$item = $fileName;
						}
						push @command, ("-$param", "$item") unless $item eq "default";
						last;
					}
				}
			}
		} else {
			if ($values[0] ne "default") {
				      if (ref $values[0] eq "Fh") {
				              uploadfile($values[0], "$projectDir/$param");
				              push @command, ("-$param", "$projectDir/$param");
				      } elsif ($values[0] eq "yes") {
				              push @command, "-$param";
				      } elsif ($values[0] eq "no") {
				              push @command, "-no$param";
				      } elsif (length $values[0]) {
						if (($datatype =~ /^align|^featout|^outfile|^report|^seqout/) or ($param eq "goutfile")) {
							push @command, ("-$param", "$values[0]");
						} else {
							push @command, ("-$param", $values[0]);
						}
				      }
			   }
			if ($#secondS > -1) {push @command, @secondS; @secondS=()};
		}
	 }
	push @command, "-auto";
	return @command;
}

sub indexHtmlEmail {
	my $name = shift;
	my $applDir = shift;
	my $startTime = shift;
	open INDEX, ">$applDir/index.html"
		or return errorPage("couldn't create $applDir/index.html: $!");
	 print INDEX <<EOF;
<html>

<head>
<title>wE $name run</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" type="text/css" href="/wEMBOSS/wEMBOSS.css">
</head>
<body>
<script language="javascript"> parent.focus() </script>
<table width="635" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td><span class="wtitle">w</span><span class="title">$name </span><span class="titlepopup">Output</span></td>
  </tr>
  <tr>
	 <tr>
		  <td align="left">Running $name...</td>
	 </tr>
	 <tr>
		  <td>$name has been running since @{[ scalar localtime($startTime) ]}<br>
		   check back later...</td>
	 </tr>
</table>
</body>

</html>
EOF
	 close INDEX;
	return 0;
}

sub htmlWaitChoice {
	my $email = shift;
	my $name = shift;
	my $projectUrl = shift;
	my $applDir = shift;
	print <<EOF;
<html>

<head>
<title>wE waiting for $name output</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" type="text/css" href="/wEMBOSS/wEMBOSS.css">
</head>
<body>
<script language="javascript"> parent.focus()</script>
<table width="635" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td><span class="wtitle">w</span><span class="title">$name </span><span class="titlepopup">Output</span></td>
  </tr>
  <tr>
    <td align="left">Running $name...</td>
  </tr>
  <tr>
    <td>You will be receive email at $email when $name has finished
	 running, or you can check <a href="$projectUrl/&_file=$applDir/index.html">here</a>
	 periodically...</td>
  </tr>
</table>
</body>
</html>
EOF
}

sub htmlWaitEndOfExecution {
	my $name = shift;
	print <<EOF;
<html>
 
<head>
<title>wE waiting for $name output</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" type="text/css" href="/wEMBOSS/wEMBOSS.css">
</head>
<body>
<script language="javascript"> parent.focus();</script>
<table width="635" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td><span class="wtitle">w</span><span class="title">$name </span><span class="titlepopup">Output</span></td>
  </tr>
  <tr>
	<td align="left">Running $name, please wait...</td>
  </tr>
  <tr>
    <td><img src="/wEMBOSS/images/pix.gif" width="8" height="8"></td>
  </tr>
</table>
EOF
}

sub resultIndexFile {
	my ($name, $projectDir, $applDir, $projectUrl, $exitstatus, $command) = @_;
	(my $currentProject = $projectDir) =~ s#$ENV{HOME}\/##;
	# now deal with every file in the directory that matters...
	opendir RESULTDIR, "$applDir" or errorPage ( "couldn't open $applDir : $!");
	my @resultFiles = grep{ !/^\.\.?$/ } readdir( RESULTDIR );
	close RESULTDIR;
	my $Name = uc $name;
	 # now create the index.html in the results directory, this will show all the files into that result
	open INDEX, ">$applDir/index.html"
	   or return errorPage("couldn't create $applDir/index.html: $!");
#	select INDEX ;
	print INDEX <<EOF;
<html>

<head>
<title>wE $name output </title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" type="text/css" href="/wEMBOSS/wEMBOSS.css">
<script language="JavaScript" src="/wEMBOSS/wEMBOSS.js"></script>
</head>
<body onLoad="parent.focus()">
<!--<script language="javascript">parent.focus() </script>-->
<table   width="630" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td><span class="wtitle">w</span><span class="title">$Name </span><span class="titlepopup">Output file(s)</span></td>
  </tr>
  <tr>
    <td><img src="/wEMBOSS/images/pix.gif" width="8" height="8"></td>
  </tr>
  <tr>
    <td>
      <table width="100%" border="0" align="center" cellpadding="3" cellspacing="0" bgcolor="#D7909B">
        <tr> 
 	  <td>
EOF
	# output the errors first, if there are any that matter...
	#
	my @error = fixerror("$projectDir/error");
	push @error, "$name exited with status $exitstatus..." if $exitstatus;
	error(join "\n", @error) if scalar @error;
	my $i = 0;
	chdir $applDir or error ( "couldn't chdir to $applDir : $!");


	foreach my $entry (@resultFiles) {
		  next if $entry =~ /^\.\.?$/;
		  next if $entry eq ".command";
		  next if $entry eq "input";
		  next if $entry eq "error";
		  next if $entry eq "index.html";
		  next unless -s $entry;
		  if ($entry =~ /\.png$|\.gif$|\.jpg$/) {
				print INDEX <<EOF;
	    <table width="100%" border="0" cellpadding="5" cellspacing="0" bgcolor="#FFFFFF">
	      <tr>
	        <td height="40" bgcolor="bb4553"><span class="titlewhite">&nbsp;Image file:</span>
		    <span class="txtwhite">&nbsp;<a id="saveAs$i" href="$projectUrl&_file=$applDir/$entry"
			onClick='if (opener.document.result) {return ResultViewHref(this, "$applDir/$entry")}' >$entry</a></span></td>
	      </tr>
	      <tr>
	        <td align="center"><br>
		    <img id="image$i" src="$projectUrl&_file=$applDir/$entry" 
			 onClick='if (opener.document.result) {return ResultViewHref(this,"$applDir/$entry")}' hspace="0" vspace="0"><br> </td>
	      </tr>
	    </table>

EOF
		  } elsif ($entry =~ /\.ps$|\.html$|\.pdf$/) {
				print INDEX <<EOF;
	    <table width="100%" border="0" cellpadding="5" cellspacing="0" bgcolor="#FFFFFF">
	      <tr>
	        <td height="40" bgcolor="bb4553"><span class="titlewhite" id="result$i" >&nbsp;$entry
		  [ <a id="saveAs$i" href="$projectUrl&_file=$applDir/$entry"
		    onClick='if (opener.document.result) {return ResultViewHref(this, "$applDir/$entry")}' >click to view</a> ]</span></td>
	      </tr>
	      <tr><td> </td></tr>
	    </table>

EOF
		  } else {
				if ( -T $entry ) {
					open DATA, "<$entry"
					or error("couldn't read $entry: $!");

				        print INDEX <<EOF;
	    <table width="100%" border="0" cellpadding="5" cellspacing="0" bgcolor="#FFFFFF">
	      <tr>
	        <td height="40" bgcolor="bb4553"><span class="titlewhite" id="result$i">&nbsp;$entry
		  [ <a id="saveAs$i" href="$projectUrl&_file=$applDir/$entry" 
		    onClick='if (opener.document.result) {return ResultViewHref(this, "$applDir/$entry")}' >right click to save locally</a> ]</span></td>
	      </tr>
	      <tr>
	        <td><pre>@{[ join("", <DATA>) ]}</pre></td>
	      </tr>
	    </table>
EOF
				        close DATA;
				}
		  }
	   $i++;
	 }

	 print INDEX <<EOF;
	  </td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><img src="/wEMBOSS/images/pix.gif" width="8" height="8"></td>
  </tr>
  <tr>
    <td>
      <table border="0" cellpadding="3" cellspacing="0" bgcolor="#BDD99F">
       <tr><td>Executed EMBOSS command line :</td></tr
       <tr><td>$command</td></tr>
       <tr><td>$ENV{'REMOTE_USER'} is working at $ENV{'REMOTE_ADDR'} IP address in wEMBOSS $currentProject project</td></tr>
      </table>
    </td>
  </tr>
</table>
</body>
</html>
EOF
	 close INDEX;
}



# error ($message)

#

# output an error message and log the error...

#

# $message is the error message to log and output

#

sub error {

	my $message = shift;
	if (open LOG, ">>$main::wEMBOSS_HOME/logs/error.log") {
		print LOG scalar localtime(), " -->\n$message";
		close LOG;
	} else {
		warn "couldn't write to $main::wEMBOSS_HOME/logs/error.log: $!";
	}
	$message = CGI::escapeHTML($message);
	print INDEX <<EOF;
		 <tr>
		  <td bgcolor="#ECCAD0">
			<table cellpadding="4" cellspacing="0" border="0" width="100%">
				<tr>
					<th class="error">Warning</th>
				</tr>
			</table>
			<table cellpadding="8" cellspacing="0" border="0" width="100%">
				<tr>
					<td class="inner"><pre>$message</pre></td>
				</tr>
			</table>
		  </td>
		 </tr>

EOF

}





# errorPage($message)
#
# output a general error page and log the error...
#
# $message is the error message to log and output
#
sub errorPage {
	my $message = shift;
	# log the error...
	#
	if (open LOG, ">>$main::wEMBOSS_HOME/logs/error.log") {
		print LOG scalar localtime(), " --> $message";
		close LOG;
	} else {
		warn "couldn't write to $main::wEMBOSS_HOME/logs/error.log: $!";
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
<p>$message</p>
</body>
</html>
EOF
	return ();
}

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

sub uploadfile {
	my ($fh, $outfile) = @_;
	open UPLOAD, ">$outfile"
	  or return errorPage("couldn't write to $outfile: $!");
	print UPLOAD <$fh>;
	close UPLOAD;
}


1
