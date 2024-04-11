#!$perl
###########################################################################
# Copyright (C) 2003, 2004, 2005 Marc Colet, Martin Sarachu
#
# This file is part of wEMBOSS.
#
# wEMBOSS is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# wEMBOSS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with wEMBOSS; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
###########################################################################
use CGI;
use Cwd qw ( chdir );
use Cwd;
use lib "../lib";
use wEMBOSS::viewAction; 
use wEMBOSS::titleAction;
use wEMBOSS::menuAction;
use wEMBOSS::searchAction;
use wEMBOSS::runAction;
use wEMBOSS::Input;
use wEMBOSS::PMAction;
use wEMBOSS::startAction;
use strict;

# initialize location variables...
#g

my $cgi = new CGI;

#our $EMBOSS_HOME	= '$emboss_home';
# When using Eclipse comment the above line and add an appropriate explicit assignment of $EMBOSS_HOME
our $EMBOSS_HOME	= '/usr/local/share/EMBOSS';

#our $EMBOSS_BIN	= '$emboss_bin';
# When using Eclipse comment the above line and add an appropriate explicit assignment of $EMBOSS_BIN
our $EMBOSS_BIN	= '/usr/local/bin';
 
#our $wEMBOSS_HOME	= '$wemboss_home';
# When using Eclipse comment the above line and add an appropriate explicit assignment of $wEMBOSS_HOME
our $wEMBOSS_HOME	= '/Users/marc/Documents/workspace/wEMBOSSDEV-2.2/wEMBOSSsite';
 
 our $VERBOSE		= 0;


#
$ENV{'USER'} = $ENV{'REMOTE_USER'};
my($user,$bs,$homedir) = ("","","");
#($user,$bs,$bs,$bs,$bs,$bs,$bs,$homedir) = getpwnam($ENV{'REMOTE_USER'});
($user,$bs,$bs,$bs,$bs,$bs,$bs,$homedir) = getpwnam('marc');
my $wprojectsdir = "$homedir/wProjects";
if (not chdir($wprojectsdir)) {
	# wProjects does not exits, new user, create dir
	if (not mkdir($wprojectsdir, 0000750)) {
		print "Content-type: text/html\n\n";
		wEMBOSS::Input::errorPage(" wEMBOSS : Unable to mkdir $wprojectsdir directory, ask system manager! : $!", );
		exit(1);
	}
	if (not chdir($wprojectsdir)) {
		print "Content-type: text/html\n\n";
		wEMBOSS::Input::errorPage(" wEMBOSS :  Unable to chdir to $wprojectsdir directory, ask system manager : $!");
		exit(1);
	}
}
# set other environment variables.  for some reason, wossname requires tt the
# EMBOSS binaries be in the path...

$ENV{'PATH'} = "$EMBOSS_BIN:/bin:/usr/local/bin";
$ENV{HOME} =$wprojectsdir;
$ENV{'PLPLOT_LIB'} = $EMBOSS_HOME;
my $pwd = $ENV{'PWD'};
for ($cgi->param("_action")) {
	/^view|^output/	and do { wEMBOSS::viewAction::viewWindow($cgi); last; };
	print "Content-type: text/html\n\n";
	/^title/        and do { wEMBOSS::titleAction::header($cgi); last; };
	/^mmenu/        and do { wEMBOSS::menuAction::programsMenu(); last; };
	/^key/          and do { wEMBOSS::searchAction::programsByKeywords(); last; };
	/^search/       and do { wEMBOSS::searchAction::searchWindow($cgi); last; };
	/^mngt/         and do { wEMBOSS::PMAction::projectManagementPage($cgi); last; };
	/^input/        and do { wEMBOSS::Input::programPage($cgi); last; };
	/^run/          and do { wEMBOSS::runAction::programRun($cgi); last; };
	/^start/		and do { wEMBOSS::startAction::startwEMBOSS($cgi); last; };
	print " action \$_ not found";
}

print "\n";