use strict;
use warnings;
use File::Basename;
use File::Copy;
use Cwd;
use Storable;
use Data::Dumper;
use lib '../wEMBOSSsite/lib';
use wEMBOSS::ACD;



# prompt function...
#
sub prompt {
	my ($message, $default) = (shift, shift);
	my $rv;
	print "$message\n\t[ default is $default ]\n> ";
	chomp($rv = <STDIN>);
	$rv =~ s/\/$//;
	return $rv || $default;
}

# location of perl should be passed as the first argument...
#
my $perl;
chop( $perl = `which perl` )
	or die "can't locate perl : $!";

# collect information needed for install...
#

print <<EOF;

Please answer the following questions to set up wEMBOSS:

EOF
open ANSWERS, ">./yourAnswers"
        or die "couldn't write to ../yourAnswers  $!";
my $emboss_home = prompt(
	"Where was the share/EMBOSS data directory installed?",
	"/usr/local/emboss/share/EMBOSS"
);
print ANSWERS "$emboss_home\n";
my $emboss_bin = prompt(
	"Where were the EMBOSS binaries installed?",
	"/usr/local/bin"
);
print ANSWERS "$emboss_bin\n";
my $nobody  = prompt(
	"Who is the owner of the httpd processes of the web server ? (ask system manager if needed)",
	"nobody"
);
print ANSWERS "$nobody\n";
my $web_root = prompt(
	"Where is the root of the web server document tree?",
	"/home/httpd"
);
print ANSWERS "$web_root\n";
my $hostname = prompt(
	"What is the hostname of the web server wEMBOSS will be installed on?",
	"localhost"
);
print ANSWERS "$hostname\n";
my $port = prompt(
   "On what port is the web server listening for connections?",
   "80"
);
print ANSWERS "$port\n";
my $wemboss_home = prompt(
      "Where should wEMBOSS be installed?",
      "/home/wEMBOSS"
);
print ANSWERS "$wemboss_home\n";
my $wemboss_mail = prompt(
	"What is the local e-mail adress the users may contact?",
	'wemboss@this.site'
);
print ANSWERS "$wemboss_mail\n";

close ANSWERS;

# verify EMBOSS version 
my $EMBOSSversion="?";
if (open EMBOSSVERSION, "$emboss_bin/embossversion -nofull -auto | ") {$EMBOSSversion = <EMBOSSVERSION>}
else 								      { die " Can't locate EMBOSS programs in $emboss_bin\n" }

# create the symbolic link to the html doc pages of EMBOSS installation
if ($EMBOSSversion =~ /^3/) {
	-d "$web_root/embosshelp" or symlink "$emboss_home/doc/programs/html", "$web_root/embosshelp"
	or die "can't create $web_root/embosshelp symbolic link for $emboss_home/doc/programs/html : $!";
} elsif ($EMBOSSversion =~ /^[45]/) {
	-d "$web_root/emboss" or symlink "$emboss_home/doc/html/emboss", "$web_root/emboss"
	or die "can't create $web_root/emboss symbolic link for $emboss_home/doc/html/emboss : $!";
	if (-d "$emboss_home/doc/html/embassy") {
		-d "$web_root/embassy" or symlink "$emboss_home/doc/html/embassy", "$web_root/embassy"
		or die "can't create $web_root/embassy symbolic link for $emboss_home/doc/html/embassy : $!";
	}
} elsif ($EMBOSSversion =~ /^6/) {
        -d "$web_root/embosshelp" or symlink "$emboss_home/doc/programs/html", "$web_root/embosshelp"
        or die "can't create $web_root/embosshelp symbolic link for $emboss_home/doc/programs/html : $!";
        if (-d "$emboss_home/doc/html/embassy") {
                -d "$web_root/embassy" or symlink "$emboss_home/doc/html/embassy", "$web_root/embassy"
                or die "can't create $web_root/embassy symbolic link for $emboss_home/doc/html/embassy : $!";
        }

} else {die "can't create emboss html doc  symbolic link for any version of emboss : $!"}

# create wEMBOSS installation HOME
-d $wemboss_home or mkdir $wemboss_home, 0711 and chmod 0755, $wemboss_home
        or die "couldn't create $wemboss_home: $!";

# copy all needed directories from wEMBOSS distribution to wEMBOSS installation site
#foreach my $directory ("embossData", "lib", "sacd", "wEMBOSS_cgi") {
#	system "cp -r ./$directory $wemboss_home/$directory"	
#		and die "unable to copy $directory to $wemboss_home/$directory : $!";
#	chmod 0755, "$wemboss_home/$directory"
#		or die "unable to chmod $wemboss_home/$directory : $!"	
#}

	system " cp -r ../wEMBOSSsite/* $wemboss_home"
		and die "unable to copy wEMBOSSsite content to $wemboss_home : $!";

# install the HTML files...
######################################################################################
print "\nInstalling wEMBOSS HTML files...\n";
#eval {
#	mkdir "$web_root/wEMBOSS", 0711;
#	mkdir "$web_root/wEMBOSS/tmp", 0711;
#	chmod 0711, "$web_root/wEMBOSS";	# umask might make it wrong...
	system "cp -r ../wEMBOSS $web_root"
#	chmod 0644, glob "$web_root/wEMBOSS/*";
#	chmod 0711, glob "$web_root/wEMBOSS/*/";
#	chmod 0644, glob "$web_root/wEMBOSS/*/*";
#} 
and die "couldn't install HTML files to $web_root/wEMBOSS: $!";

# parse the distribution template.txt file and extract some installation files of it
####################################################################################

open TEMPLATE, "<../wEMBOSSsite/template.txt" or die ("$_");
my $template = join "", <TEMPLATE>;
close TEMPLATE;
$template =~ s/nobody/$nobody/;
$template =~ s/\$perl/$perl/g;
$template =~ s/\$emboss_home/$emboss_home/;
$template =~ s/\$emboss_bin/$emboss_bin/;
$template =~ s/\$wemboss_home/$wemboss_home/;
$template =~ s/\$web_root/$web_root/g;
$template =~ s/\$wemboss_mail/$wemboss_mail/g;
my ($catch, $script, $jal, $index) = split (/%===%/, $template);

#  the setuid c program to authenticate the users (catch.c)
open  CATCH, ">$wemboss_home/wEMBOSS_cgi/catch.c"or die "$!";		
print CATCH $catch 
		or die "couldn't write to $wemboss_home/wEMBOSS_cgi/catch.c: $!";
close CATCH;
chown ((getpwnam("root"))[2,3], "$wemboss_home/wEMBOSS_cgi/catch.c") == 1
	or die "couldn't chown $wemboss_home/wEMBOSS_cgi/catch.c: $!";
chmod 0700, "$wemboss_home/wEMBOSS_cgi/catch.c"
        or die "couldn't chmod $wemboss_home/wEMBOSS_cgi/catch.c: $!";
my $pwd = cwd();
chdir "$wemboss_home/wEMBOSS_cgi" or die "couldn't chdir to $wemboss_home/wEMBOSS_cgi: $!";
system "make catch";
chdir $pwd;

# the CGI wrapper script (catch.pl) 
open  SCRIPT, ">$wemboss_home/wEMBOSS_cgi/catch.pl"or die "$!";		
print SCRIPT $script 
		or die "couldn't write to $wemboss_home/wEMBOSS_cgi/catch.pl: $!";
close SCRIPT;
chmod 0755, "$wemboss_home/wEMBOSS_cgi/catch.pl"
	or die "couldn't chmod $wemboss_home/wEMBOSS_cgi/catch.pl: $!";
# the script needed to print PDF files from Jalview 
# look for ps2pdf, warn if not found
my $ps2pdf = "";
chop( $ps2pdf = `which ps2pdf` );
if( !( -e $ps2pdf ) ) {
   warn "ps2pdf not found in your system. You will not be able to print from Jalview.\n";
}
open  JAL, ">$wemboss_home/wEMBOSS_cgi/_jalview_ps2pdf" or die "$!";		
print JAL $script 
		or die "couldn't write to $wemboss_home/wEMBOSS_cgi/_jalview_ps2pdf: $!";
close JAL;
chmod 0755, "$wemboss_home/wEMBOSS_cgi/_jalview_ps2pdf"
	or die "couldn't chmod $wemboss_home/wEMBOSS_cgi/_jalview_ps2pdf : $!";  
	
# the index.html file that will be installed at web document root
open  INDEX, ">$web_root/wEMBOSS/index.html" or die "$!";		
print INDEX $index 
		or die "couldn't write to $web_root/wEMBOSS/index.html: $!";
close INDEX;
chmod 0644, "$web_root/wEMBOSS/index.html"
	or die "couldn't chmod $web_root/index.html : $!";  

# install local emboss data descrition at wEMBOSS HOME
########################################################################################
print "\nGenerating default configuration files...\n";
open CODONS, ">$wemboss_home/embossData/codons"
        or die "couldn't open $wemboss_home/embossData   /codons: $!";
open DATAFILES, ">$wemboss_home/embossData/dataFiles"
	 or die "couldn't open $wemboss_home/embossdata/dataFiles: $!";
open DNAMATRICES, ">$wemboss_home/embossData/dnaMatrices"
        or die "couldn't open $wemboss_home/embossData/dnaMatrices: $!";
open PROTMATRICES, ">$wemboss_home/embossData/protMatrices"
        or die "couldn't open $wemboss_home/embossData/protMatrices: $!";

open EMBOSSDATA, "$emboss_bin/embossdata -showall -reject=AAINDEX,CVS,PRINTS,PROSITE,REBASE -auto |"
	or die "couldn't run $emboss_bin/embossdata: $!";
while (<EMBOSSDATA>) {
	chomp;
	s/^\s+//;
	s/\s+$//;
	next unless length;
	print CODONS $1, "\n"   if (/^(\w+.cut)$/);
	print DNAMATRICES $_, "\n" if (/^EDNA|^ENUC/);
	print PROTMATRICES $_, "\n" if (/^EBLOSUM|^EPAM|^EPROT/);
	print DATAFILES $_, "\n" if (/^([\w\-]+\.dat)$/);	
}
close EMBOSSDATA;
close DNAMATRICES;
close PROTMATRICES;
close CODONS;
close DATAFILES;
chmod 0644, "$wemboss_home/embossData/dnaMatrices";
chmod 0644, "$wemboss_home/embossData/protMatrices";
chmod 0644, "$wemboss_home/embossdata/codons";


# INSTALL the sacd files ( perl structure containing ACD file info  of all  emboss and embassy localy installed programs)
###############################################################################################################################
my $acd = "";
$Data::Dumper::Purity = 1;
open WOSSLIST, "wossname -alphabetic -auto |" or die "couldn't run wossname: $!";
my @alphaProgramList = <WOSSLIST>;
shift @alphaProgramList;
shift @alphaProgramList;
close WOSSLIST;
print "@alphaProgramList\n";
foreach (@alphaProgramList) { # read each line
        chomp;
        next unless /\w/;
        my ($name, $doc) = split( /\s+/, $_, 2 ); # get name
        my $acd = "";
        $acd =  wEMBOSS::ACD::parseACD("$emboss_home/acd/$name.acd")  or die "$!";
        store($acd, "$wemboss_home/sacd/$name.sacd") or die "Can't store sacd of $name acd file\n";
}

################################################

# make the temp dir writable by all
#
chmod( 0777, "$web_root/wEMBOSS/tmp" )
   or die "couldn't chmod $web_root/wEMBOSS/tmp: $!";

print <<EOF;

And that should just about do it.  Point your browser at  
the URL of your web site under wEMBOSS/index.html file to try it out...

Please report any errors or strange occurrences to
Marc Colet <MarcRColet\@gmail.com> 

EOF
