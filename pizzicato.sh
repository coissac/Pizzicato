#!/bin/bash

#####################
#
# Options de configuration
#
#####################


##
## Paramettre system
##

HOSTNAME=pizzicato           # Nom de la machine sur le réseau local
ACTIVER_SSH_SERVEUR=1        # Si 1 le serveur ssh d'acces distant est activé

#####################
#
# fonctions utilitaires
#
#####################

function change_hostname() {
  local newname=$1
  local tmp=$(mktemp)
  
  echo "$newname" > /etc/hostname
  
  sudo cp /etc/hosts /etc/hosts.ori.$(date '+%Y%m%d_%k%M')
  
  awk -v hostname="$newname" \
      'BEGIN        {OFS="\t"} \
       /^127.0.1.1/ {$NF=hostname} \
                    {print $0}' /etc/hosts \
    > "$tmp"
    
  mv "$tmp" /etc/hosts
}

function edit_config() {
  local parametre=$1
  shift
  local value=$*
  local tmp=$(mktemp)

  awk -v date="$(date '+%d/%m/%Y at %k:%M')" \
          '/^ *'${parametre}' *=.*$/ {print; \
                                      print "# commented out by Jukebox.sh on",date; \
                                      printf("# ")} \
           {print $0}' /boot/config.txt \
    | awk -v date="$(date '+%d/%m/%Y at %k:%M')" \
          -v param="${parametre}" \
          -v value="${value}" \
          '{print $0} \
           END {print "#"; \
                print "# Edited on",date,"by Jukebox.sh"; \
                print "#"; \
                print param"="value; \
                print }' > "${tmp}"
                
  mv "${tmp}" /boot/config.txt
  chown root:root /boot/config.txt
}


function download_url() {
  local url="$1"
  local tmp=$(mktemp)
  
  local filename=$(basename "$url")
  
  if [[ "$filename" == "download" ]] ; then
    filename=$(basename $(dirname $SQUEEZE_URL) )
  fi
  
  wget -O "${filename}" "$url" 
  
  echo ${filename}
}


#####################
#
# Update the system with the latest version
# of every packages
#
#####################

echo "Updating the Raspberry PI OS system" 1>&2

#
# Add the repository for the latest version of
# upmpdcli family software
#
# https://www.lesbonscomptes.com/upmpdcli/pages/downloads.html#debian
#

echo "  - Register the lesbonscomptes package signature..." 1>&2

tmpkeydir=$(mktemp -d /tmp/tmp.keyring.XXXXXXXX)
gpg --no-default-keyring \
    --homedir $tmpkeydir \
    --keyring /usr/share/keyrings/lesbonscomptes.gpg \
    --keyserver hkp://keyserver.ubuntu.com:80 \
    --recv-keys F8E3347256922A8AE767605B7808CE96D38B9201
rm -rf $tmpkeydir

echo "    Done." 1>&2
echo

echo "  - Register the lesbonscomptes package repository..." 1>&2

curl https://www.lesbonscomptes.com/upmpdcli/pages/upmpdcli-rbuster.list \
    > /etc/apt/sources.list.d/upmpdcli-rbuster.list
    
echo "    Done." 1>&2
echo

#
# Update of the package repository
#

echo "  - Update the package repository..." 1>&2

apt-get update

echo "    Done." 1>&2
echo

#
# Upgrade of the packages
#


echo "  - Upgrade every packages..." 1>&2

apt-get dist-upgrade --assume-yes

echo "    Done." 1>&2
echo

echo "Done." 1>&2


#####################
#
# Configure the system
#
#####################

#
# Change the hostname
#

echo "  - changing the host name from $(hostname) to ${HOSTNAME}..." 1>&2
change_hostname "${HOSTNAME}"
echo "    Done." 1>&2

#
# Activate the SSH server
#

if (( ACTIVER_SSH_SERVEUR == 1 )) ; then
  echo "  - Activating the ssh server..." 1>&2
  systemctl enable ssh
  echo "    Done." 1>&2
fi  

echo "Done." 1>&2

#####################
#
# Configuration of the Touch screen HDMI 5'' Display.
#
# Configuration follows instructions from the provider
# available on the following web site:
#     https://www.waveshare.com/wiki/5inch_HDMI_LCD_(H)
#
#####################

echo "Configuring the HDMI 5'' Display" 1>&2

#
# Edit the /boot/config file for the HDMI display
#

echo "  - Editing the /boot/config.txt file..." 1>&2

cp /boot/config.txt /boot/config.txt.ori.$(date '+%Y%m%d_%k%M')

if [ ! -z "${GPU_MEMORY}" ] ; then
   edit_config gpu_mem "${GPU_MEMORY}"
fi
   
if [ ! -z "${DECODE_MPG2}" ] ; then
   edit_config decode_MPG2 "${GPU_MEMORY}"
fi

if [ ! -z "${DECODE_WVC1}" ] ; then
   edit_config decode_WVC1 "${GPU_MEMORY}"
fi  

cp /boot/config.txt /boot/config.txt.pizzicato_orig
(grep -E -v 'hdmi_(group|mode|cvt)' /boot/config.txt.pizzicato_orig \
 | grep -E -v 'max_usb_current' \
 | grep -E -v '^##@'; \
 cat << EOF
##@
##@ Pizzicato setup
##@
max_usb_current=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
EOF
) > /boot/config.txt

echo "    Done." 1>&2
echo

#
# Setup the touchscreen
#

echo "  - Installing the libinput library for the touch screen..." 1>&2
apt-get install xserver-xorg-input-libinput
echo "    Done." 1>&2
echo

echo "  - Installing the config file for the touch screen..." 1>&2
mkdir -p /etc/X11/xorg.conf.d
cp /usr/share/X11/xorg.conf.d/40-libinput.conf /etc/X11/xorg.conf.d/
echo "    Done." 1>&2
echo

echo "Done." 1>&2
