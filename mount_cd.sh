#!/bin/bash

home=$(awk -F: -v v=$(id -u) '($3==v) {print $6}' /etc/passwd)

cddb_serveur="http://gnudb.gnudb.org/~cddb/cddb.cgi" 

cdinfo=( $(cddb-tool query \
                   "${cddb_serveur}" \
                   6 $(whoami) $(hostname) $(cd-discid)) )

code="${cdinfo[0]}"
genre="${cdinfo[1]}"
cdid="${cdinfo[2]}"

if (( code == 200 )) ; then
  cdescr=$(cddb-tool read "${cddb_serveur}" \
                   6 $(whoami) $(hostname) $genre $cdid)
else

gio mount cdda://sr0
