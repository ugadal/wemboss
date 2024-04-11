/*************************************************************************

 Copyright (C) 2003, 2004, 2005 Marc Colet, Martin Sarachu

 This file is part of wEMBOSS.

 wEMBOSS is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 wEMBOSS is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Foobar; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <pwd.h>
#include <sys/types.h>
#include <errno.h>
#define NOBODY "nobody"
char *user;
int  userid;  

void print_error( char *error_context, char *error_message) {
 int cl;
  printf("Content-type: text/html\n\n");
  printf("error, %s <P>", error_context);
    printf("%s", error_message);
  exit(1);
} 

main(int argc, char *argv[]) {

  if (getuid() !=  getpwnam(NOBODY)->pw_uid) {
    print_error("catch:", "Sorry, the owner of this process is not allowed to run catch program, ask wEMBOSS  manager! ");
  }
                        /*  Identifying the user, he becomes the owner of the process */
  user = getenv("REMOTE_USER");
  if (userid = getpwnam(user)->pw_uid ){
    if (setgid(getpwnam(user)->pw_gid) < 0){
      print_error("catch	", "can't reset GID ") ;
    }
    if (setuid(userid) < 0){
      print_error("catch", "can't reset UID ") ;
    }
  }
  else {
    print_error("getit, unknown user:", user);
  }
  

                        /* Identifying wEMBOSS HOME and EMBOSS HOME */
   fflush(NULL);
   execv ("./catch.pl", argv, NULL);
   print_error("catch: can't execute catch.pl", "catch.pl");
} /* main */
