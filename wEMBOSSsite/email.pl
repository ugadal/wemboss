use Mail::Mailer;

use strict;

my ($email, $name, $starttime, $results) = @ARGV;

my $mailer = new Mail::Mailer;
$mailer->open({
	From => 'wEMBOSS server',
	To => "wEMBOSS user <$email>",
	Subject => "wEMBOSS: $name has finished",
	'Content-type' => "text/html\n\n"
}) or die "couldn't send email: $!";
print $mailer <<EOF;
<html>
<body>
<table width="500" border="0" align="center"  cellpadding="3" cellspacing="0" >
  <tr><td>
    <img src="http://www.be.embnet.org/wEMBOSS/images/header_logo.jpg" alt="EMBOSS home" name="wEMBOSS" width="160" height="60" border=0>
     </<td> 
     <td height="24" >The job you submitted to $name on @{[ scalar localtime($starttime) ]} has finished.
     </td>
  </tr>
  <tr> 
     <td></td><td>You can view the output <a href="$results">here</a></td>
  </tr>
  <tr>
    <td> Thank you for using wEMBOSS...</td>
  </tr>
</table>
</body>
</html>
EOF
$mailer->close();
