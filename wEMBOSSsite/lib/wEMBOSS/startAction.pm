# # # # # # # # # # # # # # # # # title action # # # # # # # # # # # # # # # # # # #

=item startwEMBOSS($cgi)

Generate the whole wEMBOSS window. 

$cgi is a reference to the CGI object created by the wrapper script

=cut


package wEMBOSS::startAction;


use strict;

sub startwEMBOSS {

	print <<EOF;
	
   <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
            "http://www.w3.org/TR/html4/frameset.dtd">

<html>

<head>
<title>wEMBOSS</title>
<script language=JavaScript src='/wEMBOSS/wEMBOSS.js'> </script>
</head>

<frameset rows='75,*' frameborder=no>
        <frame src='/wEMBOSS_cgi/catch?_action=title' name=wEMBOSStitle scrolling=no>
        <frameset cols='170,*'>
		 <frameset rows='*,160'>
			<frame src='/wEMBOSS_cgi/catch?_action=mmenu'
			name=wEMBOSSmenu scrolling=auto marginwidth=10 marginheight=5>
			<frame src='/wEMBOSS_cgi/catch?_action=key' 
			name=wEMBOSSauthors scrolling=no>
		 </frameset>
	                <frame src='/wEMBOSS_cgi/catch?_action=mngt'
         	        name=wEMBOSSmain scrolling=auto marginwidth=15 marginheight=5>
        </frameset>
</frameset>

</html>
EOF
}

1