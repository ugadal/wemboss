var helpFeatures, viewFeatures;
var toggle = new Array(2);
        toggle['yes'] = 'no';
        toggle['no'] = 'yes';

function changePWD (projectIndex) {
        parent.wEMBOSStitle.document.project._pwd.selectedIndex = projectIndex;
}

function unacceptedStr(acceptedChars, str ) { // returns true if a string is empty or contains unaccepted chars otherwise returns false
    if (str && str.match(acceptedChars)) {
        return false 
    } 
    return true   // it's true : the string is unacceptable!
}

function defPWD(progName) {
        if( parent.wEMBOSStitle.document.project._pwd.value == "" ) {
                alert( "You must create a first project before execution of a program!" );
                return false
        }
        parent.wEMBOSSmain.location.replace("/wEMBOSS_cgi/catch?_action=input&_app=" + progName + "&_pwd=" + parent.wEMBOSStitle.document.project._pwd.value);
        return true
}


function deleteFiles(projectDir, theFiles) {
    if( theFiles == null ) {
       alert( "Please select some file(s) to delete" );
       return false
    }
    alert (" file(s) : "+theFiles);
        if( window.confirm( "Delete the selected files?" ) ) {
        PMoperation(projectDir, "&_rmTrue=true&_file="+theFiles);
        return true
    } 
    return false
}

function DeleteProject (project) {
        var cDate = new Date();
        var antiCache = cDate.getTime();
	if (project.indexOf('/') >= 0) {
               parentProject = project.substring(0, project.lastIndexOf('/'));
        } else {
               parentProject = 'wProjects';
        }
        PMoperation (project, "&_deleteProject=1&_antiCache=" + antiCache)
        
	return parentProject;
}

function deleteResultSet( doc, elements, projectDir ) {
   // delete a set of results, elements param is the name of the results "array"
   // concat all the results separated by # and pass this as value of _deleteResultSet
   results = ""
   j = 0
   while( doc.getElementsByName( elements )[j] ) {
      if( doc.getElementsByName( elements )[j].checked ) {
         // add the project+result string to results String
         results += projectDir
         results += "/"
         results += doc.getElementsByName( elements )[j].value
         results += '%23'
      }
      j++
   }
   results = results.substr( 0, results.length - 3 ) // remove the last # character
   if( results != "" ) { // there are results to delete
      if( window.confirm( "Do you really want to delete the selected results?" ) ) {
            PMoperation(projectDir, "&_resultSetToDelete="+results);          
        return true
      } else {
         return false
      }
   } else {
      alert( "No results selected. Please select at least one result." )
      return false
   }
}

function init() {
         helpFeatures = "height=350,width=550,scrollbars,resizable";
        //viewFeatures = "height=800,width=600,scrollbars,resizable,toolbar";
        viewFeatures = "height=800,width=650,scrollbars,resizable";
        if (navigator.appName=="Netscape") {
                helpFeatures = helpFeatures + ",screenX=40,screenY=40";
                viewFeatures = viewFeatures + ",screenX=40,screenY=40";
        }else {
                helpFeatures = helpFeatures + ",top=40,left=40";
                viewFeatures = viewFeatures + ",top=0,left=0";
        }
        if (parent.wEMBOSSmain.location.search.match(/_delete/)) {
                 NewTitle (parent.wEMBOSSmain.document.PMform._pwd.value, 1)
        }
}

function loadMenu(){
	parent.wEMBOSSmenu.groupShowed=""; 
	parent.wEMBOSSmenu.subGroupShowed="";
}
function moveProject( projectToMove, newParent, text ) { // projectToMove becomes a child of newParent
        //alert( projectToMove + " : " + newParent )
        var cDate = new Date();
        var antiCache = cDate.getTime();
        var projectName = projectToMove.substring(projectToMove.lastIndexOf('/'))
        var newProjName = newParent + projectName
        PMoperation(projectToMove, "&_newParentProject=" + newParent + "&_moveProject=1&_antiCache="  + antiCache);
        NewTitle( newProjName );
        return newProjName
}

function mycookie(value, cgiPar) {
        parent.wEMBOSSmain.document.cookie=cgiPar + "=" + toggle[value] + ';';
    if (cgiPar == "sort")   {PMoperation(parent.wEMBOSSmain.document.PMform._pwd.value, "");
	} else                  {location.reload()} 
}

function NewProject (oldProject, subProject, projFiles) {
        var cDate = new Date();
        var antiCache = cDate.getTime();
	var newProject = prompt( "Please enter a name for the project", "" )  // get the new project name
    if (newProject == null) return false;
    if( unacceptedStr( /^[\w]+$/, newProject ) ) { // non-alpha is not valid
        alert( "Please enter a name with only alphanumerics characters." )
        return false
    }
    for( var i = 0; i < projFiles.length; i++ ) {
        if( newProject == projFiles[i].text ) {
        alert( "Please use another name. Your project already contains a file with the same name." )
        return false
        }
    }
	if (subProject) { newProject = oldProject + "/" + newProject }
    PMoperation(oldProject, "&_newProject=" + newProject + "&_antiCache="  + antiCache );
    return newProject;
}

function NewTitle(project, deletedProject) {
        var cDate = new Date();
        var antiCache = cDate.getTime();
//        alert("Projet : "+ project);
        parent.wEMBOSStitle.location.replace(
                "/wEMBOSS_cgi/catch?_action=title&_pwd=" + project
                                + "&_deletedProject=" + deletedProject
                                + "&_antiCache="  + antiCache
        );
}

function openWin( app, dir, file ) {
   var tlph = this.location.protocol + "//" + this.location.host;
   myFile = file.replace( /\/.+\//, '' ); // only the file that we are opening
   if ( app != 2 && navigator.appName.match( "icrosoft" ) ) { // Jalview
      applet_window = open("", "applet_window",
         "screenY=0,width=600,height=700,status=no,toolbar=no,menubar=no,resizable=yes");
      param = "<PARAM NAME='oneMoreURL2' value='/wEMBOSS/tmp/" + myFile + ".pdf'>"
   } else {
      applet_window = open("", "applet_window",
         "screenY=0,width=200,height=150,status=no,toolbar=no,menubar=no,resizable=no");
      param = "<PARAM NAME='oneMoreURL2' value='javascript:void window.open(\"/wEMBOSS/tmp/" + myFile + ".pdf\",\"pdfFile\",\"status=no,toolbar=no,menubar=no,resizable=yes\")'>"
   }
   
   // open document for further output
   applet_window.document.open();

   // create document
   applet_window.document.writeln( "<HTML><HEAD><TITLE>wEMBOSS - Applet viewer" );
   applet_window.document.writeln( "</TITLE></HEAD><BODY>" );
   applet_window.document.writeln( '<FONT FACE = "HELVETICA, ARIAL">' );
   applet_window.document.writeln( "<CENTER><B>" );
   applet_window.document.writeln( "Please do not close this window as long as you want to use the selected applet.<br>" );
   if ( app == 1 ) {
      applet_window.document.write( '<APPLET ARCHIVE = "/wEMBOSS/jars/jalviewApplet.jar"' );
//      applet_window.document.writeln( ' CODE = "jalview.ButtonAlignApplet.class"' );
      applet_window.document.write( ' CODE = "jalview.bin.JalviewLite"' );
      applet_window.document.writeln( ' windowWidth = 150 windowHeight = 50>' );
//      applet_window.document.write( '<PARAM NAME = "type"' );
//      applet_window.document.writeln( ' VALUE = "URL">' );
//      applet_window.document.write( "<PARAM NAME = input" );
//      applet_window.document.write( " VALUE=" + tlph + "/wEMBOSS_cgi/catch?_action=view&_pwd=" );
//    applet_window.document.write( " VALUE=/wEMBOSS_cgi/catch?_action=view&_pwd=" );
//      applet_window.document.writeln( dir + "&_file=" + file + " >" );
//      applet_window.document.writeln( '<param name=format value="MSF">');
//      applet_window.document.writeln( "<PARAM NAME='fileServer' value='localhost'>" );
//      applet_window.document.writeln( "<PARAM NAME='port' value='80'>" );
//    applet_window.document.writeln( "<PARAM NAME='fileLocation2' value='/wEMBOSS_cgi/_jalview_ps2pdf'>");
//      applet_window.document.writeln( "<PARAM NAME='fileLocation2' value='/wEMBOSS_cgi/_jalview_ps2pdf'>");
//      myFile = file.replace( /\/.+\//, '' );
//      applet_window.document.writeln( "<PARAM NAME='fileName2' value='" + myFile + "'>" );
//      applet_window.document.writeln( "<PARAM NAME='oneMoreURL2' value='javascript:void window.open(\"/wEMBOSS/tmp/" + myFile + ".pdf\",\"pdfFile\",\"status=no,toolbar=no,menubar=no,resizable=yes\")'>" );
//      applet_window.document.writeln( param );
      applet_window.document.writeln('<param name="defaultColour" value="% Identity">');
      applet_window.document.write( '<PARAM NAME ="file"' );
      applet_window.document.write(" VALUE=" + tlph + "/wEMBOSS_cgi/catch?_action=view&_pwd=" );
      applet_window.document.writeln( dir + "&_file=" + file + " >" );
      applet_window.document.writeln( "</APPLET>" );
    } else {
         applet_window.document.write( '<APPLET ARCHIVE ="/wEMBOSS/jars/forester.jar"' );
         applet_window.document.write( ' CODE = "org.forester.atv.ATVapplet"' );
         applet_window.document.writeln( ' WIDTH = 150 HEIGHT = 50>' );
         applet_window.document.write( '<PARAM NAME ="url_of_tree_to_load" ' );
         applet_window.document.write( " VALUE='" + tlph + "/wEMBOSS_cgi/catch?_action=view&_pwd=" );
         applet_window.document.writeln( dir + "&_file=" + file + "' >" );
         applet_window.document.writeln( "</APPLET>" );
    }
   applet_window.document.writeln( "</BODY></HTML>" );

   // close the document - (not the window!)
   applet_window.document.close();
}

function PMoperation (projectDirectory, parameters) {
    parent.wEMBOSSmain.location.replace(
        "/wEMBOSS_cgi/catch?_action=mngt&_pwd=" + projectDirectory + parameters
    );
}

function popup(url,name) {
 // opens a new window with url 'url'
 //  to open windows in top of each other give them a different name
 var pWidth = 900 ; var pHeight = window.screen.availHeight; var w; var h=0;
 if (!name) name = "newWin";
 if (name == "wEMBOSSwindow") {    
     w = (window.screen.availWidth-pWidth)/2;
 } else {
     pWidth = 650;

    if (name == "helpWindow") {
        w=0;
    } else {
        w =  window.screen.availWidth -pWidth ;    
    }
 }
 newWin = window.open(url,name,"status=yes,scrollbars=yes,resizable=yes,width="+pWidth+",height="+pHeight+",screenX="+w+",screenY="+h+",top="+h+",left="+w+"'");
 if (!newWin.opener) newWin.opener = self;
 setTimeout("newWin.focus()",250); // put focus on new window
}

function renameProject(projectDir, projectName) { // attempts to rename the current project, returns the new name if succesfull
       var newName = prompt( "Please enter a new name for the project", projectName ) // get the new name
       if( newName == null ) { // blank is not valid
               return false
       } else {
               if( unacceptedStr(/^[\w\/]+$/, newName ) ) { // non-alpha is not valid
                       alert( "Please enter a name with only alphanumerics characters. ( don't touch the '/'s please )" );
                       return false
               }
               // ok to rename the project
               var cDate = new Date();
               var antiCache = cDate.getTime();
               PMoperation(projectDir, "&_renameProject=1&_newProjectName=" + newName + "&_antiCache="  + antiCache);
               var parentProject = projectDir.substring(0, projectDir.lastIndexOf('/'))
               //alert( "proj nuevo: "+parentProject+"/"+newName )
               NewTitle( parentProject+"/"+newName )
               return newName 
       }
}

function ResultViewHref(thisObject, fileToView) {
        if (thisObject.src) {
                thisObject.src  = "/wEMBOSS_cgi/catch?_action=view&_pwd=" + opener.document.result._pwd.value + "&_file=" + fileToView;
        } else {
                thisObject.href = "/wEMBOSS_cgi/catch?_action=view&_pwd=" + opener.document.result._pwd.value + "&_file=" + fileToView;
        }
}       

function saveAs(projectDir, actualFileName) { //  save file in projectDir 
	var fileName = prompt( "Save as ", actualFileName) // get the new name
		if( unacceptedStr(/^[\w\.]+$/, fileName ) ) { // non-alpha is not valid
			alert( "Please enter a name with only alphanumerics ( _ and  . accepted ) characters." )
			return false
		}
		// ok to save the  file
		var cDate = new Date();
		parent.wEMBOSSmain.document.EFform._antiCache.value = cDate.getTime();
		parent.wEMBOSSmain.document.EFform._saveFile.value = fileName;
		parent.wEMBOSSmain.document.EFform.submit();
}

function submission (mainDoc) {
	var outFile = "";
	if(mainDoc.getElementById('outfile') != null) {
		outFile = mainDoc.getElementById('outfile').value;
	}
	if(outFile != "") {
		if (outFile.match(/^[\w\.]+$/) ) {
            popup("", "EMBOSSfile");
			mainDoc.input.submit();
			return false;
		} else {
			alert ('Filenames must only have alphanumeric characters');
		}
	} else {
        popup("","EMBOSSfile");
		mainDoc.input.submit();
		return false;
	}
}

function switchSelect( elements, switchValue ) {
// elements is the name of a group of checkboxes, the function checks/unchecks
// all the checkboxes according to the switchValue
   j=0
   while( parent.wEMBOSSmain.document.getElementsByName( elements )[j] ) {
      parent.wEMBOSSmain.document.getElementsByName( elements )[j].checked = switchValue
      j++
   }
}

		

function switchView( elemClicked, theGroupShowed, theSubGroupShowed ) {
	if (theSubGroupShowed != "") {
		var showedElem = parent.wEMBOSSmenu.document.getElementById(theSubGroupShowed );
		showedElem.style.display = "none";
		subGroupShowed = "";
	}
	if (theGroupShowed != "") {
		var showedElem = parent.wEMBOSSmenu.document.getElementById( theGroupShowed );
		showedElem.style.display = "none";
		groupShowed = "";
	}
	if (theGroupShowed == elemClicked | theSubGroupShowed == elemClicked) {
		return "";
	} else {
		var newlyShowedElem = parent.wEMBOSSmenu.document.getElementById( elemClicked )
//		newlyShowedElem.style.display = "inline";
		newlyShowedElem.style.display = "block";
		return elemClicked;
	}
}

function writeComment( curProj, oldComment, result ) { // writes a comment for result in curProj
   var cDate = new Date();
   var antiCache = cDate.getTime();
   var newComment = prompt( "Please enter a new comment for selected result", oldComment ) // new comment 
   if( newComment == "" ) { // blank comment 
      newComment = "e$" // hack to symbolize blank/empty comments
   } else {
      if ( newComment.length > 100 ) {
         alert( "Comment cannot exceed 100 characters in length, please try again." )
         return false
      }
      //if( unacceptedStr( /^[\w\s-_*/()]+$/, newComment ) ) { // only letter, digits, whitespace and some symbols
      //   alert( "An invalid symbol was entered, please try again." )
      //   return false
      //}
   }
   PMoperation(curProj, "&_result=" + result + "&_writeComment=" + newComment + "&_antiCache="  + antiCache); 
    return true
   //return newProject;
}
