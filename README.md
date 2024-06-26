# librairies nécessaires
```
emerge -qv MailTools
emerge -qv dev-perl/CGI
```
**wEMBOSS utilise apache pour fonctionner, il est nécessaire de l'installer et de l'activer avant l'installation de wEMBOSS :**

```emerge apache
  /etc/init.d/apache2 start
ou systemd :
  systemctl enable apache2
  systemctl start apache2
```
```
cd /opt
git clone https://github.com/ugadal/wemboss.git
cd wemboss
cd wEMBOSSinstall
```
lisez INSTALL
lancez: ```perl install.pl```

et répondez aux questions comme suit: (valeurs par défaut adaptées à Gentoo)
```
/usr/local/share/EMBOSS
/usr/local/bin
apache
/var/www/localhost/htdocs
localhost
80
/opt/wemboss_site
"moi"@localhost
```
Modifications à effectuer dans le fichier /etc/apache2/vhosts.d/default_vhost.include

première modif dans /etc/apache2/httpd.conf

Ajoutez Trois lignes un peu avant la fin
```
  LoadModule usertrack_module modules/mod_usertrack.so
  LoadModule vhost_alias_module modules/mod_vhost_alias.so
  <AuthnProviderAlias file shadfile>
       AuthUserFile "/etc/shadow"
  </AuthnProviderAlias>
  # If you wish httpd to run as a different user or group, you must run
  # httpd as root initially and it will switch.
  #
```

La modification dans le default_vhost.include se simplifie elle devient :

fichier: /etc/apache2/vhosts.d/default_vhost.include qqpart ou il y a déjà une ligne ScriptAlias
```
ScriptAlias /wEMBOSS_cgi/ "/opt/wemboss_site/wEMBOSS_cgi/"
qqpart là où il y a déjà des balises <Directory>

<Directory "/opt/wemboss_site/wEMBOSS_cgi">
      AuthBasicProvider shadfile
      AuthType basic
      Authname "EMBOSS user"
      Require valid-user
</Directory>
```
pour finir

```
/etc/init.d/apache2 reload
groupadd shadow
usermod -a -G shadow apache
chgrp shadow /etc/shadow
chmod 640 /etc/shadow
/etc/init.d/apache2 reload
```

#Créer un compte :
useradd -m 'Nom'
passwd 'Nom'


wEMBOSS, a web interface for EMBOSS
===================================

wEMBOSS is an interface to the EMBOSS bioinformatics tools
(http://emboss.sourceforge.net). wEMBOSS can be downloaded from
http://wemboss.sourceforge.net.

wEMBOSS reference
=================

wEMBOSS: a web interface for EMBOSS
Sarachu M. and Colet M.
Bioinformatics 2005 21(4):540-541

About the included applets
==========================

All applets are included with permission of the authors.

- Zmasek C.M. and Eddy S.R. (2001) ATV: display and manipulation of annotated
 phylogenetic trees. Bioinformatics, 17: 383-384.

 ATV web site http://www.phylosoft.org/archaeopteryx

- M. Clamp, J. Cuff, S.M. Searle and G.J. Barton (2004) The Jalview Java
 alignment editor. Bioinformatics, 20: 426-427.
- A.M. Waterhouse, J.B. Procter, D.M.A. Martin, M. Clamp and G.J. Barton (2009)
 Jalview version 2 - a multiple sequence alignment editor and analysis
 workbench. Bioinformatics 25: 1189-1191.

 Jalview web site  http://www.jalview.org


Warning
-------
The Jalview applet does not run under MacOS X with the Firefox browser.
It does however work properly with Safari and Opera.


wEMBOSS-2
=========

wEMBOSS-2 is completely reorganized from the developer and manager point-of-vue.
wEMBOSS-2 has the same functionality as wEMBOSS-1.8.1 for the users.
wEMBOSSDEV-2 for the developer is now a project in Eclipse using the Epic
plug-in.
wEMBOSSDIST-2.x is the corresponding distribution package. It is distributed as
successive releases with version numbers. We are starting the distribution at
version 2.1.

What is different, in a few words :
wEMBOSS does not install anymore its modules in the Perl system libraries.
This is completely justified because the wEMBOSS Perl code is used first at
installation time and later at wEMBOSS run time but never as reusable code for
other applications.
  
Thus after installation you can find wEMBOSS-2 files only at 3 places :
	- where you put the distribution package (of course)
	- where you did install it (wEMBOSS home)
	- under the document root of your Web server, where are all the files
          needed to create the Web pages (html, images, css, js, ...).
	- a fourth place could be the one where you have put all your personal
          stuff that successive installations could otherwise have erased !


The wEMBOSS.pm module has been split into 8 modules each one corresponding to
one of the 8 possible actions  (project management, menu of programs, program
page, run ...) 
Part of the code is rewritten for clarity, the others parts will be rewritten
later.

My idea is to facilitate my succession for a new wEMBOSS developer.

I am now retired so its more easy to spend time on it!

Marc








