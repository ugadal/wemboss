# # # # # # # # # # # # # # # # # mngt action # # # # # # # # # # # # # # # # #

=item projectManagementPage

Create the wEMBOSS Management page. You can : 

	-create projects : a project  is a location where you store datafiles 
		and run EMBOSS programs, projects help you to keep clean
		you bioinformatic work. Identify one to one your own bioinformatic
		projects to wEMBOSS projects. 

	-make the housekeeping of current project data and results

=cut



package wEMBOSS::PMAction;

use strict;

use Cwd;

use Cwd qw ( chdir );

use File::Find;

use File::Basename;

use File::Copy;

use Mail::Mailer;

our @directories = ();




sub projectManagementPage {
	# first we perform all the management operations
	#
	my $cgi = shift;
	my $sort = $cgi->cookie('sort') || 'no';
	my ($currentProject, $projectDir, $type) = ('', '', '');
	my (@resultsDirs, @projectFiles, @projectDirectories) = ( (), (), () );
	$projectDir  = $cgi->param('_pwd') or $projectDir = $ENV{HOME};

	
	if		($cgi->param('_newProject'))	{ $projectDir = newProject($cgi->param('_newProject'))}
	elsif   ($cgi->param('_renameProject')) { $projectDir = renameProject($projectDir, $cgi->param('_newProjectName'))}
	elsif   ($cgi->param('_moveProject'))   { $projectDir = moveProject($projectDir, $cgi->param('_newParentProject'))}
	elsif   ($cgi->param('_deleteProject')) { $projectDir = deleteProject($projectDir)}

	
	&find({wanted => \&projectDirectories, follow=>1, follow_skip=>2}, "$ENV{HOME}");
	@projectDirectories = sort @directories;

	
	if (scalar @projectDirectories) { # there are projects, at least one
		if 		($cgi->param('_resultSetToDelete'))	{deleteResultSet($projectDir, $cgi->param('_resultSetToDelete')) 
		} elsif ($cgi->param('_writeComment'))		{writeComment($cgi->param('_result'), $cgi->param('_writeComment'))
		} elsif ($cgi->param('_listConv'))			{listConversion($cgi->param('_file'))
		} elsif ($cgi->param('_rmTrue'))			{deleteFiles($cgi)
		} elsif ($cgi->param('_saveFile'))			{saveFile($cgi)
		} elsif ($cgi->param('_upload'))			{ # uploading a file into the current project
														(my $fileName = $cgi->param('_upload'))=~ s/.*[\\\/]//;
			   											uploadfile($cgi->param('_upload'), "$projectDir/$fileName")
		} elsif ($cgi->param('_paste'))				{$projectDir = pasteFiles($cgi)}

		
		if ($projectDir eq $ENV{HOME}) {$projectDir = $projectDirectories[0]}
		($currentProject = $projectDir) =~ s#$ENV{HOME}\/##;
		$type = $cgi->param('_type') or $type = '.*';
		if (opendir PROJECT, "$currentProject") {
			   @projectFiles = sort grep {-f && /$type/i && !/\/[.]command/} map {"$projectDir/$_"} readdir PROJECT;
			   rewinddir PROJECT;
			if ($sort eq 'yes') { @resultsDirs = sort byName grep {/^\.\w.*[0-9]$/} readdir PROJECT }
			else		    { @resultsDirs = sort byDate grep {/^\.\w.*[0-9]$/} readdir PROJECT }
			   close PROJECT;
		} else { error ("Can't open current project $currentProject : $! ")}
	}
	my $enable = 0; my $disabled= "";
	if ($projectDir ne $ENV{HOME}) { 
		$enable = 1; # we manage a project
	} else {
		$disabled  = "disabled"; # not yet any project
	}
	my $existsResults = 0;
	if( scalar @resultsDirs != 0 ) {
		$existsResults = 1;
	}
	my $baseNameOfProject = basename $currentProject;
	my $projectTitle = "$currentProject project";
	my $projectSuggestion = "";
	if ($disabled) {
		$projectSuggestion = "myFirstProject";
		$currentProject = "wProjects";
		$projectTitle = "<h1>Create a first project</h1><h3 style=\"font-size: 10px; background-color: white; color: red;\">".
				      "Replace \"myFirstProject\" by the name you prefer and click on the \"New Project\" button </h3>"
		;
	}
	print <<EOF;
<html lang="en">

<head>
 <title>Project Management</title>
 <base target= 'wEMBOSSmain'>
 <link href="/wEMBOSS/wEMBOSS.css" rel="stylesheet" type="text/css">
 <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body bgcolor="#FFFFFF" onLoad="parent.init()">
<DIV  id="docu" style = \"position:absolute;visibility:hidden;z-index:50;left:2\"></DIV>
<table border="0" cellspacing="2" cellpadding="0">				            <!-- the big table -->
 <tr>
  <td><span class="title">$projectTitle</span> </td>
 </tr>
 <tr>
  <td align="center">
   <table align="center" cellpadding="0" cellspacing="0" style="border-style:solid; border-width:3px; border-color:#d38a94;"> 
    <tr>
	<td valign="top" bgcolor="#FFFFF">
	 <table  height="100%" border="0" align="center" cellpadding="0" cellspacing="3">
	  <tr>
	<td colspan="2">
		<form name="PMform">		   <!-- start of new project function -->
		<input type="hidden" name="_pwd"    value="$projectDir" >
		<span class="title"><a href="/wEMBOSS/PM-1.8.html" target="EMBOSShelp" onClick="parent.popup('/wEMBOSS/PM-1.8.html','helpWindow'); return false;">		
			<img src="/wEMBOSS/images/t_p_manag.gif" width="145" height="25" border="0"></a>
		</span>
	</td>
	  </tr>
	  <tr>
	<td>
	 <table border="0" cellspacing="0" cellpadding="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td background="/wEMBOSS/images/but_pink_back.gif" height="100%" width="65"> 
	   		<a href="#" onClick="newProject=parent.NewProject('$currentProject', document.PMform._subproject.checked, document.PFform._file.options);
				if ( newProject ) { parent.NewTitle('$ENV{HOME}/' + newProject, 0) } " class="but">New project</a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" height="100%"></td>
	  </tr>
	 </table>
	</td>
	   <td valign=top ><img src="/wEMBOSS/images/arrow_red.gif" width="16" height="10">
		   <input $disabled type="checkbox" name="_subproject">subproject&nbsp;?
	   </td>
	  </tr>
		   </form>
	  <tr>
	<td colspan="2">		     <!-- start of rename project function -->
	 <table border="0" cellpadding="0" cellspacing="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65"> 
	   	<a href="#" onClick="if( $enable ) { parent.renameProject('$projectDir', '$baseNameOfProject') }  
	   						 else { alert( 'Please create a project first' ) }" class="but">Rename proj.</a></td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>
	  </tr>
				<!-- start of move project function -->
	  <tr>
	<td>
			  <form  name="PMformMove">
	 <table border="0" cellspacing="0" cellpadding="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65">
				    <a href="#" onClick="if( $enable ) { parent.moveProject( '$projectDir', document.PMformMove._newParentProject.value, '$currentProject' ) } 
				    					 else { alert( 'Please create a project first' ) }" class="but">Move proj. to 
				    </a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>
	<td valign = top nowrap><img src="/wEMBOSS/images/arrow_red.gif" width="16" height="10">
				 <select name="_newParentProject" style="width: 130px;">
EOF

	my $parentProj = dirname( $currentProject );
	my $curProjName = basename( $currentProject );
	print "<option value=\"$ENV{HOME}\">(Top project)\n" if $currentProject =~ /\//;
	my $aProject;
	foreach my $aProjectDirectory ( @projectDirectories ) {
		( $aProject = $aProjectDirectory ) =~ s#$ENV{HOME}\/##  or next;
		if ($aProject !~ m#^$currentProject($|/)# && $aProject ne $parentProj) {
			print "	    <OPTION VALUE=\"$ENV{HOME}/$aProject\"> $aProject\n";
		}
	}
print <<EOF;
		 		      </select>
	</td>
	  </tr>
			 </form>
EOF

print <<EOF;
				 <!-- start of delete project function -->
	  <tr>
	<td colspan="2">
	 <table border="0" cellpadding="0" cellspacing="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65">
				    <a href="#" onClick="if( $enable ) { 
			 				if( window.confirm( 'Delete $currentProject and all of its contain?'))
								{parent.DeleteProject('$projectDir') 
							};
							return false
				   		   } else { alert( 'Please create a project first' ) ; return false}" 
				class="but">Delete proj.&nbsp;&nbsp;</a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>
	  </tr>
	  <tr><td colspan="2"><img src="/wEMBOSS/images/pix.gif" height="5"></td></tr>
	  <tr><td colspan="2" height="2" bgcolor="#d38a94"></td></tr>
	  <tr>
	<td colspan= "2"><span class="title"><a href="/wEMBOSS/PM-1.8.html" target="EMBOSShelp" onClick="parent.popup('/wEMBOSS/PM-1.8.html','helpWindow'); return false;"><img
			src="/wEMBOSS/images/t_p_files.gif" width="92" height="25" border="0"></a></span></td>
	  </tr>
	  <tr>
	<td>
					<!-- start of Project Files functions -->

		   <form method="POST" name="PFform" action="catch?" enctype="MULTIPART/FORM-DATA">

		   <input type="hidden" name="_action" value="mngt">
		   <input type="hidden" name="_pwd" value="$projectDir">
			   <!-- input's for knowing which function to perform -->
		   <input type="hidden" name="_edit" value="">
		   <input type="hidden" name="_cp" value="">
		   <input type="hidden" name="_listConv" value="">
		   <input type="hidden" id="_rmTrue" name="_rmTrue" id="_rmTrue" value="">
					<!-- start of new file function -->	

	 <table border="0" cellpadding="0" cellspacing="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65">
				  <a href="#" onClick="if( $enable ) {
				              parent.PMoperation('$projectDir', '&_edit=true&_file=newFiLe')
				                     } else { alert( 'Please create a project first' ); return false }"
				            class="but">New file&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>
	  </tr>
	  <tr><td colspan="2"><img src="/wEMBOSS/images/pix.gif" height="4"></td></tr>
					<!-- start of view file function -->
	  <tr height="24">
	<td>
	 <table border="0" cellpadding="0" cellspacing="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65">
				    <a href="#" onClick="if( $enable ) { parent.popup('/wEMBOSS_cgi/catch?_action=view&_file='
				    						+document.PFform._file.options[document.PFform._file.selectedIndex].value
				    						+'&_pwd=$projectDir', 'EMBOSSfile' ); } 
					  		  	else { alert( 'Please create a project first' ); return false }"					  		  					  		   
				 class="but">View&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>
	<td valign="center" rowspan="5" nowrap><img src="/wEMBOSS/images/arrow_red.gif" width="16" height="10">
			  <select multiple size="8" name="_file" id="_file" style="width: 130px;">
EOF
	 foreach my $projectFile (@projectFiles) {
	    my $fileName = basename $projectFile;
	    print "		                                    <option value =\"$projectFile\"> $fileName\n";
	 }

	 print<<EOF;
			  </select>
	</td>
	  </tr>

					<!-- start of edit file function -->
	  <tr height="24">
	<td>
	 <table border="0" cellpadding="0" cellspacing="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65">
				   <a href="#" onClick="if( $enable ) { parent.PMoperation('$projectDir', '&_edit=true&_file='+document.PFform._file.value)}
							else { alert( 'Please create a project first' ); return false }" 
					 class="but">Edit&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>
	  </tr>

					<!-- start of copy file(s) function -->
	  <tr height="24">
	<td>
	 <table border="0" cellpadding="0" cellspacing="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65">
				 <a href="#" onClick="if( $enable ) { document.PFform._cp.value='true'; document.PFform.submit();}
					    	   else { alert( 'Please create a project first' ); return false }" 
					 class="but">Copy&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>
	  </tr>

			    		<!-- start of delete file(s) function -->
	  <tr height="24">
	<td>
	 <table border="0" cellpadding="0" cellspacing="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65">
				   <a href="#" onClick="if( $enable ) { parent.deleteFiles('$projectDir', document.PFform._file.value)   } 
						  				else 		  { alert( 'Please create a project first' ); return false }" 
					 class="but">Delete&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>
	  </tr>

					<!-- start of convert list function -->
	  <tr height="24">
	<td>
	 <table border="0" cellpadding="0" cellspacing="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65">
				   <a href="#" onClick="if( $enable ) { document.PFform._listConv.value='true'; document.PFform.submit(); } 
			 				else { alert( 'Please create a project first' ); return false }" 
					 class="but">List G-E&amp;G&nbsp;&nbsp;&nbsp;</a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>
	  </tr>
	  <tr><td colspan="2"><img src="/wEMBOSS/images/pix.gif" height="4"></td></tr>

			               <!-- start of view with function -->
	  <tr>
	   <td valign="top" nowrap >
	    <table border="0" cellpadding="0" cellspacing="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
		 <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65">
			    <a href="#" onClick="parent.openWin(document.PFform._applet.value, '$projectDir', document.PFform._file.value)" 
			       class="but">View with&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			    </a>
		 </td>
		 <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
		</tr>
	    </table>
	   </td>
	   <td valign="top" nowrap><img src="/wEMBOSS/images/arrow_red.gif" width="16" height="10">
			<select size=1 name="_applet" style="width: 130px;">
			 <option selected value=1>Jalview (any format)
			 <option value=2>ATV
			 </select>
	   </td>
	  </tr>

				              <!-- start of file upload function -->
	  <tr>
	<td valign="top" nowrap >
	 <table border="0" cellpadding="0" cellspacing="0">  
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65"><a href="#" onClick="
	   if( $enable ) {
	   		if( document.PFform._upload.value != '' ) {
	   			document.PFform.submit(); 
	   		} else {
	   			alert( 'Please select a file to upload' ) 	   			
	   		} 
	   } else { 
	   	alert( 'Please create a project first' ); return false 
	   }" class="but">Upload&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table> 
	</td>
	<td valign="top" nowrap><img src="/wEMBOSS/images/arrow_red.gif" width="16" height="10">
		<input $disabled type="file" name="_upload" id="_upload" size=8 >
	</td>
	  </tr>
					<!-- start of file type function -->
	  <tr>
	<td nowrap  valign=top>
		<a  href="#" onClick="if( $enable ) { document.PFform.submit(); } 
							  else { alert( 'Please create a project first' ); return false }" 
			class="but"><img src="/wEMBOSS/images/t_f_type.gif" width="60" height="25" border="0">
		</a>
	</td>
	<td valign="top"><img src="/wEMBOSS/images/arrow_red.gif" width="16" height="10">
		 <input $disabled type="text" name="_type" value="$type" size = "10">
	</td>
	  </tr>
	  <tr><td colspan="2"><img src="/wEMBOSS/images/pix.gif" height="5"></td></tr>


				  <!-- a partir de aca hay que sacar de esta sub y ponerlo en la general del proy -->
		 </form>
	 </table>
	</td>
	<td colspan="2" width="2" bgcolor="#d38a94">
	<td valign= "top" bgcolor="#FFFFF">
	 <table width="100%"  height="100%" border="0" align="center" cellpadding="0" cellspacing="3">
	  <tr>
	<td valign="top" width="50%"><a href="/wEMBOSS/PM-1.8.html" target="EMBOSShelp" 
									onClick="parent.popup('/wEMBOSS/PM-1.8.html','helpWindow'); return false;">
									<img src="/wEMBOSS/images/t_p_results.gif" width="108" height="25" border="0">
								</a>
	</td>
	<td valign="bottom" align ="right">
	 <table border="0" cellspacing="0" cellpadding="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65" height="16">
	   	<a href='#' onClick="if( $existsResults )	{ parent.mycookie('$sort', 'sort')	   		
	   												} else { alert( 'Nothing to sort yet. Run a program first') };return false;" class="but">
			Sort @{[$sort  eq 'yes' ? "by date" : "by name" ]}
		</a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10"  height="16"></td>
	  </tr>
	 </table>
	</td>
	<td valign="bottom" align ="right">
	 <table border="0" cellspacing="0" cellpadding="0">
	  <tr>
	   <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" ></td>
	   <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65" height="16">
		 <a href='#' onClick="if( $existsResults ) { parent.deleteResultSet( document, 'resultS', '$projectDir' ) } 
		 					  else { alert( 'There are no results to delete yet.') }; return false;" class="but">Del selection</a>
	   </td>
	   <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	  </tr>
	 </table>
	</td>	
	  </tr>
	  <tr>
	<td colspan=3 valign=top>
	 <table  border="0" cellpadding="0" cellspacing="0">
		<tr>
	   	 <td><img onMouseOver="this.style.cursor='pointer'" src="/wEMBOSS/images/notebook_16x16_grey.gif" 
	   	 		title="To comment a result : click on the icon in front of its line!">
	   	 </td>
		 <td width="114" class="resultsName" >Program Output</td>
		 <td width="76" align=left class="resultsDate" style="color: #76AB45">yy.mm.dd</td>
		 <td width="76" align=left class="resultsDate" style="color: #76AB45">hh.mm.ss</td>
		 <td width="60" align=center class="resultsDate" style="color: #76AB45">Copy</td>
		 <td align=left>
EOF
   if( $existsResults ) { 
	 print <<EOF;
		<input onClick="parent.switchSelect( 'resultS', this.checked )" type="checkbox" name="checkAllResults">
		<!--s/u all-->
EOF
   }
   print <<EOF;
	   </td>
		</tr>
	 </table>
	</td>
	  </tr>	
	  <tr>
	<td colspan="3" valign="top"> <div style="height: 360px; width: 395px; overflow: auto;"> 	
	 <table border="0" cellpadding="0" cellspacing="0">
			<form name="result" method="POST" action="catch?">
			<input type="hidden" name="_action" value="mngt">
			<input type="hidden" id="_pwd" name="_pwd" value="$projectDir">
			<input type="hidden" name="_resultSetToDelete">
			<input type="hidden" name="_file">
			<input type="hidden" name="_cp">
			<input type="hidden" name="_copyResults">
EOF
    my $color = "ffffcc"; # start with color alternation of results
	 foreach my $directory ( @resultsDirs ) {
		  $directory = basename( $directory );
		  resultsHtml( $projectDir, $directory, \@projectDirectories, $color );
	   if( $color eq "ffffcc" ) {
		  $color = "fffff0";
	   } else {
		  $color = "ffffcc";
	   }
	 }
	print <<EOF;
			</form>
	 </table>
				</div>
	</td>
	  </tr>
	 </table>
	</td>
    </tr>
EOF
	 # now the extra HTML for some tasks
	 if ($cgi->param('_edit')) {
		  editFile($cgi);
	 }elsif ($cgi->param('_cp')) {
		  copyFiles($cgi,\@projectDirectories);
	 }
 print <<EOF;
   </table>
  </td>
 </tr>
</table>
</body>
</html>
EOF
}

sub tab {
	my $indent= shift;
	my $onClick= shift;
	my $value= shift;
print <<EOF;
$indent<table border="0" cellpadding="0" cellspacing="0">
$indent <tr>
$indent  <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
$indent  <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65">
$indent   <a href="#" onClick=$onClick class="but">$value</a>
$indent  </td>
$indent  <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
$indent </tr>
$indent</table>
EOF
} 


sub resultsHtml {
	 my $projectDir = shift;
	 my $result = shift;
	 my ($progName, $dateOf, $timeOf) = ($result  =~ m/\.(\w+)\.([0-9\.]+):([0-9\.]+)/);
	 my $projectDirectoriesRef = shift;
    my $color = shift;
    my $commentFile = "$projectDir/$result"."/.comment";
    my $comment;
    my $note;
    if( -s $commentFile ) { # if comment exists and contains something, show the yellow note and the comment itself
	  open( CF, "< $commentFile" );
	  while( <CF> ) {
		$comment = $_;
	  }
	  $note = "notebook_16x16.gif";
    } else { # no/empty comment, show grey note
	  $note = "notebook_16x16_grey.gif";
    }
	 print <<EOF;
		 <tr bgcolor="$color">
		  <td><img onMouseOver="this.style.cursor='pointer'" onClick="return parent.writeComment( '$projectDir', '$comment', '$projectDir/$result' )" 
		  		src="/wEMBOSS/images/$note" alt="$comment" title="$comment">
		  </td>
		  <td width="114"><a href="#" class="results" onClick="parent.popup('/wEMBOSS_cgi/catch?_action=view&_file=$result/index.html&_pwd=$projectDir',
		  																	'EMBOSSfile')">$progName
		  				  </a>
		  </td>		  		  
		  <td width="76" align="left" class="resultsDate" >$dateOf</td>
		  <td width="76" align="left" class="resultsDate" >$timeOf</td>
			  <td width="60" align="center"><input onClick="parent.PMoperation('$projectDir', '&_cp=true&_copyResults=$projectDir/$result')" 
		  	  class="smallbut" type="Button" onMouseOver='this.style.cursor="pointer"'  value="Files">
		  </td>
		  <td width="35" align="left"> <input type="checkbox" name="resultS" value="$result"> </td>
		 </tr>
EOF
}

sub copyFiles {
	 my ($file, $fileName);
	 my $cgi = shift;
	 my $projectDirectoriesRef = shift;
	 my @cpFiles;
	 my $projectDir = $cgi->param('_pwd');
	 my $fromDirectory = basename  $projectDir ;
	 if  ($cgi->param('_copyResults')) {
		my $resultDirectory = $cgi->param('_copyResults');
		$fromDirectory = basename  $resultDirectory;
		if ( opendir RESDIR, $resultDirectory  ) {
			@cpFiles = sort  map {"$resultDirectory/$_"} grep{ !/html/ && !/^\.\.?$/ } readdir( RESDIR );
			close RESDIR;
		} else { error ("Can't open result directory $resultDirectory") }
	 } else {
	 	@cpFiles = $cgi->param('_file') 
	 }
	 print<<EOF;
    <tr><td colspan="4" height="2" bgcolor="#d38a94"></td></tr>
    <tr>	   
	<td colspan=4>
	 <table width="100%" border="0" cellpadding="4" cellspacing="0" bgcolor="#FFFFF">
		 <form method="POST" name="CFform" action="/wEMBOSS_cgi/catch">
		 <input type="hidden" name="_action" value="mngt">
		 <input type="hidden" name="_pwd" value="$projectDir">
		 <input type="hidden" name="_paste" value="true">
	  <tr>
	   <td>
	    <a href="/wEMBOSS/PM-1.8.html" target="EMBOSShelp" onClick="parent.popup('/wEMBOSS/PM-1.8.html', 'helpWindow'); return false;">
	   	<img src="/wEMBOSS/images/t_f_copy.gif" width="56" height="24" border="0">
	    </a> 
	   </td>
	   <td colspan="3" >Control-click to (un)select </td>
	  </tr>
	  <tr>
	<td align="right" style="width: 115px;">Copy </td>
	<td rowspan="2">
	    <select multiple size=5 name="_filesToCopy" style="width: 130px;">
EOF

	 foreach $file (@cpFiles) {
		  $fileName = basename($file);
		  print "<option selected value=\"$file\">$fileName\n";
	 }
	 print <<EOF;
	    </select>
	</td>
	<td>from </td>
	<td colspan="2" > $fromDirectory </td>
	  </tr>
	  <tr>
	<td></td>
	<td align="left" >to project: </td>
	<td> <select name="_to">
EOF
	 foreach my $projectDirectory (@$projectDirectoriesRef) {
	    my $project;
	    ($project = $projectDirectory) =~ s#$ENV{HOME}\/## or next;
		  if ($projectDirectory eq $projectDir) {
				print "<OPTION VALUE=\"$projectDirectory\" selected> $project\n";
		  } else {
				print "<OPTION VALUE=\"$projectDirectory\"> $project\n";
		  }
	 }

	 print <<EOF;
	    </select>
	</td>
	<td>
	    <input type="submit" onClick="parent.changePWD(document.CFform._to.selectedIndex);" value=" OK ?">
	</td>
	  </tr>
	  <tr>
	<td align="right" >renamed </td>
	<td> <input type="text" size="12" name="_rename" style="width: 130px;"></td>
	<td colspan="2" > (only the first selected file is renamed )</td>
	<td></td>
	  </tr>
	 </table>
	</td>
    </tr>
EOF
}

sub renameProject {
	my $projectDir = shift;
	( my $parentProjectDir = $projectDir ) =~ s#\/[^/]*?$##;
	my $newProjectName = shift;
	rename( $projectDir, "$parentProjectDir/$newProjectName" ) or ( error( "Can't rename the project to $newProjectName :$!" ) and return( $projectDir ) );
	return( "$parentProjectDir/$newProjectName" );
}

sub moveProject {
	my $projectToMove = shift;
	my $newParentProject = shift;
	my $actualProjectName = basename( $projectToMove );
	( system( "mv", $projectToMove, $newParentProject ) == 0 ) or ( error( "Can't move $actualProjectName to $newParentProject: $!" ) and return( $projectToMove ) );
	return( $newParentProject . "/" . $actualProjectName );
}

sub deleteFiles {
	my $cgi = shift;
	my @filesToDelete = $cgi->param('_file');
	if (unlink @filesToDelete) {
		wait until !(-e pop @filesToDelete)
	} else {
		error ("Unable to delete @filesToDelete : $!"); return();
	}
}

sub deleteProject {
	 my $projectDir = shift;
	(my $parentProjectDir = $projectDir) =~ s#\/[^/]*?$##; 
	 opendir PROJECT, "$projectDir"
		or ( error("Can't open project to delete $projectDir : $!") and return ($projectDir))
	;
	my @resultsDirs = sort grep {/^\.\w.+[0-9]$/} readdir PROJECT;
	foreach my $resultDir (@resultsDirs) {
		deleteResult($projectDir, "$projectDir/$resultDir") or return ($projectDir);
	}
	if (rewinddir PROJECT) {
		my @files = grep( !/^\.[\.]?$/, readdir PROJECT );
		close PROJECT;
		foreach my $file ( @files ) {
			unlink "$projectDir/$file" or (error("Can't  delete $file  : $!") and return ($projectDir))
		}
		rmdir $projectDir or (error ("can't delete project $projectDir : $!") and return ($projectDir));
	} else { return ($projectDir) and error( "Unable to rewind $projectDir : $!") }
	return $parentProjectDir;
}

sub deleteResult {
	my $projectDir =shift;
	my $resultDir = shift; # result to delete
	if (opendir(RESULTDIR, $resultDir)) {
		chdir $resultDir or ( error("Can't chdir to $resultDir : $!") and return 0 );
		my @files = grep( !/^\.\.?$/, readdir RESULTDIR ); # get relevant files
		close RESULTDIR;
		my @cannot = grep {not unlink} @files;
		chdir $ENV{HOME};
		$#cannot <0 or ( error("Can't delete @cannot files : $!") and return 0);
		rmdir "$resultDir" or ( error( "Can't delete the $resultDir directory : $!" ) and return 0);
	} else { error("Cannot open the $resultDir result directory : $!") and return 0 }
	return 1;
}

sub deleteResultSet {
   my $projectDir =shift;
   my $results = shift; # we have to split this line into an array of results
   my @resultsDir = split( /#/, $results );
   my $retval = 0;
   foreach my $resultDir ( @resultsDir ) { # erase each result
	 $retval = deleteResult( $projectDir, $resultDir );
   }
   return $retval;
}

sub writeComment {
   my $result = shift;
   my $comment = shift;
   if( $comment eq 'e$' ) { # hack to simbolize empty/blank comments
	 $comment = "";
   }
   open( CF, "> $result/.comment" );
   print CF $comment;
   close CF;
}

sub editFile {
	 my $fileName;
	 my $cgi = shift;
	 my $projectDir = $cgi->param('_pwd');
	 my $file = $cgi->param('_file');
	 if ($file ne "newFiLe") {
		  if ($file) {
				open (FILE, "<$file") or error ("Can't open $file : $!") and return();
				$fileName = basename("$file");
		  }
	 }
	 print<<EOF;
    <tr><td colspan="4" height="2" bgcolor="#d38a94"></td></tr>
    <tr>
	<td colspan="4" bgcolor="#FFFFF">
	 <table border="0" cellpadding="4" cellspacing="0">
	  <form method="POST" name="EFform" action="catch">
	   <input type="hidden" NAME="_action" value="mngt" >
	   <input type="hidden" name="_pwd" value="$projectDir" >
	   <input type="hidden" NAME="_antiCache" value="" >
	   <input type="hidden" NAME="_saveFile" value="" >
	  <tr>
	   <td>
		  <a href="/wEMBOSS/PM-1.8.html" target="EMBOSShelp" onClick="parent.popup('/wEMBOSS/PM-1.8.html', 'helpWindow'); return false;">
		<img src="/wEMBOSS/images/t_f_edit.gif" width="56" height="24" border="0">
		  </a>
	   </td>
    <td align=center>add filename to nucList<input type="radio" name="_nucpep" value="nucList">&nbsp;&nbsp;&nbsp;&nbsp;to protList
    <input type="radio" name="_nucpep" value="protList">&nbsp;&nbsp;&nbsp;&nbsp;don't add<input type="radio" name="_nucpep" value="" checked></td>
	   <td align="right">
	    <table border="0" cellpadding="0" cellspacing="0">
	     <tr>
	      <td><img src="/wEMBOSS/images/but_pink_left.gif" width="20" height="16"></td>
	      <td nowrap background="/wEMBOSS/images/but_pink_back.gif" width="65">
			<a href="#" onClick="parent.saveAs('$projectDir', '$fileName')" class="but">
			Save as&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</a>
	      </td>
	      <td><img src="/wEMBOSS/images/but_pink_right.gif" width="10" height="16"></td>
	     </tr>
	    </table>
	   </td>
	   <td align="left"> $fileName </td>
	  </tr>
	  <tr>
	   <td colspan="3">
		<textarea name="_fileCnt" cols="80" rows="15">
EOF
	 if ($file ne "newFiLe") {
		  print <FILE>;
	 }
	 print <<EOF;
</textarea>
	   </td>
	  </tr>
	  </form>
	 </table>
	</td>
    </tr>
EOF
}


sub listConversion {
# transcription of Guy's GCGList2EMBOSS.pl
# transforms GCG List File into EMBOSS format
#  List should still be usable under GCG
# usage : GCGList2EMBOSS.pl  <name of List File>
# written by Guy Bottu on 09/10/2002
	my $list;
	my @gcgLists = shift;
	foreach my $listName ( @gcgLists ) {
		$list = "";
		open (LIST, "$listName") or error ("Cannot open $listName");
		my $parsinghead = 1;
		while (<LIST>) {
			if ($parsinghead) {
				if (/\.\./) { $parsinghead = 0 }
				s/^/# /;
			} else {
				s/(^ *)!/$1#/;
			}
			$list .= $_;
		}
		if ($parsinghead) { error ("Is this a GCG List File !? Cannot find the \"..\" line.");}
		close LIST;
		open (LIST, ">$listName") or error ("Can't open $listName for writing");
		print LIST $list;
		close LIST;
	}
}

sub newProject {
	my $newProject = shift;
	my $projectDir = "$ENV{HOME}/$newProject";
	if ( mkdir $projectDir ) {
		open LIST, ">$projectDir/nucList"  or (error (" unable to create nucList in $projectDir: $!") and return ($projectDir));
		print LIST "#nucleics of $newProject\n";
		close LIST;
		open  LIST, ">$projectDir/protList"  or (error (" unable to create protList  in $projectDir: $!") and return ($projectDir));
		print LIST "#proteins of $newProject\n";
		close LIST;
	} else { error ( "unable to mkdir $projectDir : $!") and return ($projectDir) }
	return ($projectDir);
}

sub pasteFiles {
	 my $cgi = shift;
	 my $projectDir = $cgi->param('_to');
	 my @filesToPaste = $cgi->param('_filesToCopy');
	 if (my $newName = $cgi->param('_rename')) {
		  my $file = shift @filesToPaste;
		  my $fileName = $projectDir."/".basename($newName);
		  copy ($file, $fileName);
	 }
	 foreach my $file (@filesToPaste) {
		  my $fileName = $projectDir."/".basename($file);
		  copy ($file, $fileName) or  error ("Unable to paste $fileName : $!");
	 }
	 return $projectDir
}	

sub projectDirectories{
	-d && $File::Find::name !~ /\/\.|wProjects$/ && push @directories, $File::Find::name ;
}

sub projectNames{
	-d && $File::Find::name !~ /\/\.|wProjects$/  && push (@directories, $_);
}

sub dataTreeFiles{
	-d &&  $File::Find::name !~ /\/\./ && push (@directories, " Content of " .  basename $File::Find::name . " directory :") || 
	-f &&  $File::Find::name !~ /\/\./ && push (@directories,   $_);
}

sub saveFile {
	my ( $file, $fileName, $nucpep);
	my $cgi = shift;
	my $currentprojectDir =  $cgi->param('_pwd');
	if ($fileName = $cgi->param('_saveFile')) {
		$file = "$currentprojectDir/$fileName";
		chomp $fileName
	} else {
		error("No filename");
		return;
	}
	if ( -f "$file" ) {
		if (!open (FILE,">$file")) {
			error ("$file: $!");
			return;
		} 
	} elsif (!open (FILE,"+>$file"))  {
		error ("$file: $!");
		return;
	}
	my $fileContent = $cgi->param('_fileCnt');
	if ($fileContent !~ /\n$/) {$fileContent = $fileContent . "\n"}
#	$fileContent =~s/\r//g;
	print FILE $fileContent;
	close (FILE);
	if ($nucpep = $cgi->param('_nucpep')){
		$file = "$currentprojectDir/$nucpep";
		if (!open (FILE,">>$file")) {
			error ("$file: $!");
			return;
		}
		print FILE "\n$fileName";
		close (FILE);
	}
}









sub byDate {
	(my $dateA = $a) =~ s/\.\w+\.//;
	(my $dateB = $b) =~ s/\.\w+\.//;
	if ($dateB lt $dateA) 		{ return -1 }
	elsif ($dateB gt $dateA) 	{ return  1 } 
	return 0;
}

sub byName {
	my ($nameA)  = ($a =~ m/^\.(\w+)\./);
	my ($nameB)  = ($b =~ m/^\.(\w+)\./);
	(my $dateA = $a) =~ s/\.\w+\.//;
	(my $dateB = $b) =~ s/\.\w+\.//;
	if ($nameA lt $nameB)		{ return -1}
	elsif ($nameA gt $nameB)	{ return  1}
	if ($dateB lt $dateA)		 { return -1 }
	elsif ($dateB gt $dateA)	   { return  1 } 
	return 0;
}

sub uploadfile {
	my ($fh, $outfile) = @_;
	open UPLOAD, ">$outfile"
	  or return errorPage("couldn't write to $outfile: $!");
	print UPLOAD <$fh>;
	close UPLOAD;
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


1
