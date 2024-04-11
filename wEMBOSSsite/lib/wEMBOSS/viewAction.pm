# # # # # # # # # # # # # # # #  view action # # # # # # # # # # 

=item viewWindow($cgi)

Create a Web page or start a plugin on the client side to view a file located in a project.

It's also used to look to index.html files created by wEMBOSS to save program results. 

=cut

package wEMBOSS::viewAction;
use strict;
use Cwd;
use Cwd qw (chdir);

sub viewWindow {
	my $cgi = shift;
	my $projectDir  = $cgi->param('_pwd');
	my $outfile = $cgi->param('_file');
	chdir $projectDir or 
		(print "Content-type: text/html\n\n" 
			and error("can't chdir to $projectDir : $!") and exit(0));
	 open (OUTF, "<$outfile") or 
		(print "Content-type: text/html\n\n" and error ("can't open $outfile!"));
	 if ($outfile =~ /\.htm[l]?/) {
	   print "Content-type: text/html\n\n";
	   print <OUTF>;
	   exit(0);
	 }
	 if ($outfile =~ /\.jpg$/) {
	   print "Content-type: image/jpeg\n\n";
	    print <OUTF>;
	    exit(0);
	 }
	 if ($outfile =~ /\.png$/) {
	   print "Content-type: image/png\n\n";
	   print <OUTF>;
	   exit(0);
	 }
	 if ($outfile =~ /\.gif$/) {
	   print "Content-type: image/gif\n\n";
	   print <OUTF>;
	   exit(0);
	 }
	 if ($outfile =~ /\.ps$/) {
	   print "Content-type: application/postscript\n\n";
	   print <OUTF>;
	   exit(0);
	 }
	 if ($outfile =~ /\.pdf$/) {
	   print "Content-type: application/pdf\n\n";
	   print <OUTF>;
	   exit(0);
	 }
	 if ($outfile =~ /obj$/) {
	   system("cp $outfile /tmp/tmp.obj");
	   print "Content-type: application/x-obj\n\n";
	   print " ";
	   exit(0);
	 }
	 if ($outfile =~ /(\.xsim|_lav)$/) {
	   print "Content-type: chemical/x-aln2\n\n";
	   print <OUTF>;
	   exit(0);
	 }
	 if ($outfile =~ /\.treb?$/) {
	   print "Content-type: chemical/x-nexus\n\n";
	   print <OUTF>;
	   exit(0);
	 }
	 if ($outfile =~ /\.(dnd|ph|phb|treefile)$/) {
	   print "Content-type: chemical/x-newhampshire\n\n";
	   print <OUTF>;
	   exit(0);
	 }

	 if  ($outfile =~  /\.msf$/) {
	   print "Content-type: chemical/msf\n\n";
	   print <OUTF>;
	   exit(0);
	 }
	 print "Content-type: text\n\n";
	 print <OUTF>;
	 exit(0);
}
1
