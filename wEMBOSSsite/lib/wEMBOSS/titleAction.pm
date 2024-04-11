# # # # # # # # # # # # # # # # # title action # # # # # # # # # # # # # # # # # # #

=item Header($cgi)

Generate the wEMBOSS title and the selector of projects. 

$cgi is a reference to the CGI object created by the wrapper script

=cut


package wEMBOSS::titleAction;

use Cwd;

use File::Find;

use strict;



our @directories = ();




sub header {
	my $cgi = shift;
	my $projectDir = $cgi->param('_pwd') || cwd();
	(my $currentProject = $projectDir ) =~ s#$ENV{HOME}\/?##;
	my $time = time();
#	if ($cgi->param('deletedProject') == 0) {

	if (0) {
		 do {wait} until -e $projectDir or $time +10 < time();
		 error ("$projectDir : $! \nstart wEMBOSS again!") unless -e $projectDir;
	}
	&find({wanted => \&projectNames, follow=>1, follow_skip=>2}, "$ENV{HOME}");
	my @projects = sort @directories;
	
	

	 print <<EOF;
<html>

<head>
<title>wE title frame</title>
<!--
<script language="JavaScript" src="/wEMBOSS/wEMBOSS.js"> </script> 
-->
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="/wEMBOSS/wEMBOSS.css" rel="stylesheet" type="text/css">
</head>
<body background="/wEMBOSS/images/header_back_right.jpg" 
	leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<form name="project" target="wEMBOSSmain" action="/wEMBOSS_cgi/catch" >
<input type=hidden name="_action" value ="mngt" >
<table width="100%" border="0" cellpadding="0" cellspacing="0">
    <tr>
	 <td height=74 width="160">
		<a href="http://emboss.sourceforge.net/apps/" target="_blank"><img
		 src="/wEMBOSS/images/header_logo.jpg" alt="EMBOSS home" name="wEMBOSS" width="160" height="100%" border=0></a>
	 </td>
	 <td height="74" background="/wEMBOSS/images/header_back.jpg">
	 <table width="100%" height="74" border="0" cellpadding="0" cellspacing="0">
	   <tr>
		<td width="74" rowspan="2"><img src="/wEMBOSS/images/pix.gif" width="74" height="74"></td>
		<td>&nbsp;</td>
		<td width="120" rowspan="2"><a href="http://www.be.embnet.org" target="_blank"><img src="/wEMBOSS/images/header_logo_ben.gif" 
				alt="BEN" name="BEN" width="59" height="74" border="0" id="BEN"></a><a href="http://www.ar.embnet.org" target="_blank"><img 
				src="/wEMBOSS/images/header_logo_ar.gif" 
				alt="IBBM" name="IBBM" width="61" height="74" border="0" id="IBBM"></a></td>
	   </tr>
	   <tr>
		<td>
		  <select name= "_pwd" onChange='parent.PMoperation(this.value, "")'>
EOF
	 foreach my $project (@projects) {
		  if ($currentProject eq $project) {
				print "         <OPTION VALUE=\"$ENV{HOME}/$project\" selected> $project\n";
		   } else {
				print "         <OPTION VALUE=\"$ENV{HOME}/$project\"> $project\n";
		  }
	 }
	my $loginUser = $ENV{USER};

#	my $loginUser = "tester";
	 print <<EOF;
		 </select>
		 <input name="button" type="button" onClick= "parent.PMoperation(document.project._pwd.value, '')" ; return true;" title="Project Management" value="PM" class="OKbut">
		 &nbsp;&nbsp;&nbsp;&nbsp;
		 <span class="OKbut" style="font-size: 12px">This session belongs to user <b>$loginUser</b></span>
		</td>
	   </tr>
	 </table>
	 </td>
    </tr>
</table>
</form>
</body>@
</html>
EOF
}


sub projectNames{
	-d && $File::Find::name !~ /\/\./ && $File::Find::name =~ s/$ENV{HOME}\/// && push (@directories, $File::Find::name);

}

1
