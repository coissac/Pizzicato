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
ACTIVATE_WIFI=1              # Activate the wifi on the next reboot
COUNTRY=FR                   # The country code to use for setting up the correct frequency
                             # for the 5MHz WIFI interface

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

function edit_config_file() {
  local filename=$1
  local parametre=$2
  shift
  shift
  local value=$*
  local tmp=$(mktemp)

  awk -v date="$(date '+%d/%m/%Y at %k:%M')" \
          '/^ *'${parametre}' *=.*$/ {print; \
                                      print "# commented out by Pizzicato.sh on",date; \
                                      printf("# ")} \
           {print $0}' $filename \
    | awk -v date="$(date '+%d/%m/%Y at %k:%M')" \
          -v param="${parametre}" \
          -v value="${value}" \
          '{print $0} \
           END {print "#"; \
                print "# Edited on",date,"by Pizzicato.sh"; \
                print "#"; \
                print param"="value; \
                print }' > "${tmp}"
                
  mv "${tmp}" $filename
  chown root:root $filename
}

function edit_boot_config() {
  edit_config_file /boot/config.txt $*
}

function edit_wpa_supplicant_config() {
  edit_config_file /etc/wpa_supplicant/wpa_supplicant.conf $*
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
# Save the originals config files
#

cp /boot/config.txt /boot/config.txt.ori.$(date '+%Y%m%d_%k%M')
cp /etc/wpa_supplicant/wpa_supplicant.conf \
   /etc/wpa_supplicant/wpa_supplicant.conf.ori.$(date '+%Y%m%d_%k%M')


#
# Change the hostname
#

echo "  - changing the host name from $(hostname) to ${HOSTNAME}..." 1>&2
change_hostname "${HOSTNAME}"
echo "    Done." 1>&2
echo 1>&2

#
# Activate the SSH server
#

if (( ACTIVER_SSH_SERVEUR == 1 )) ; then
  echo "  - Activating the ssh server..." 1>&2
  systemctl enable ssh
  echo "    Done." 1>&2
  echo 1>&2
fi  

#
# Edit GPU memory setting
#


if [ ! -z "${GPU_MEMORY}" ] ; then
   echo "  - Change GPU memory to ${GPU_MEMORY}..." 1>&2
   edit_boot_config gpu_mem "${GPU_MEMORY}"
   echo "    Done." 1>&2
   echo 1>&2
fi
   
#
# Add hardware video decoding licence
#

if [ ! -z "${DECODE_MPG2}" ] ; then
   echo "  - Install MPG2 hardware decoding licence..." 1>&2
   edit_boot_config decode_MPG2 "${DECODE_MPG2}"
   echo "    Done." 1>&2
   echo 1>&2
fi

if [ ! -z "${DECODE_WVC1}" ] ; then
   echo "  - Install WVC1 hardware decoding licence..." 1>&2
   edit_boot_config decode_WVC1 "${DECODE_WVC1}"
   echo "    Done." 1>&2
   echo 1>&2
fi  


if [ ! -z "${ACTIVATE_WIFI}" ] ; then
   echo "  - Declare the country for the WIFI interface..." 1>&2
   edit_wpa_supplicant_config ctrl_interface "DIR=/var/run/wpa_supplicant GROUP=netdev"
   edit_wpa_supplicant_config update_config "1"
   edit_wpa_supplicant_config country "$COUNTRY"
   echo "    Done." 1>&2
   echo 1>&2
   
   echo "  - Unlock the WIFI interface..." 1>&2
   rfkill unblock $(rfkill list | awk -F ':' '/Wireless LAN/ {print $1}')
   echo "    Done." 1>&2
   echo 1>&2
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

edit_boot_config max_usb_current 1
edit_boot_config hdmi_group 2
edit_boot_config hdmi_mode 87
edit_boot_config hdmi_cvt 800 480 60 6 0 0 0

echo "    Done." 1>&2
echo 1>&2

#
# Setup the touchscreen
#

echo "  - Installing the libinput library for the touch screen..." 1>&2
apt-get install \
        --assume-yes \
        --install-suggests \
        xserver-xorg-input-libinput
echo "    Done." 1>&2
echo

echo "  - Installing the config file for the touch screen..." 1>&2
mkdir -p /etc/X11/xorg.conf.d
cp /usr/share/X11/xorg.conf.d/40-libinput.conf /etc/X11/xorg.conf.d/
echo "    Done." 1>&2
echo 1>&2

echo "Done." 1>&2


##
## Création de l'utilisateur system qui exécutera les daemons 
##

adduser --system  pizzicato
addgroup pizzicato users
addgroup pizzicato audio
addgroup pizzicato tty
addgroup pizzicato video
addgroup pizzicato dialout



echo "  - Installing the minimum X11 ressources for running chromium..." 1>&2

apt-get install \
        --assume-yes \
        --no-install-recommends \
        xserver-xorg x11-xserver-utils xinit openbox
echo "    Done." 1>&2
echo 1>&2
        
echo "  - Installing chromium..." 1>&2

sudo apt-get install  \
        --assume-yes \
        --no-install-recommends \
        chromium-browser
        
echo "    Done." 1>&2
echo 1>&2

cp /etc/xdg/openbox/autostart /etc/xdg/openbox/autostart.ori.$(date '+%Y%m%d_%k%M')

cat > /etc/xdg/openbox/autostart << EOF
# Disable any form of screen saver / screen blanking / power management
xset s off
xset s noblank
xset -dpms

# Allow quitting the X server with CTRL-ATL-Backspace
setxkbmap -option terminate:ctrl_alt_bksp

# Start Chromium in kiosk mode
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/'Local State'
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences
chromium-browser --disable-infobars --kiosk 'http://your-url-here'
EOF

if [[ -f /home/pizzicato/.bash_profile ]]
  cp /home/pizzicato/.bash_profile /home/pizzicato/.bash_profile.ori.$(date '+%Y%m%d_%k%M')
fi

cat >> /home/pizzicato/.bash_profile << EOF
###
#
# Added by the pizzicato.sh script
#
###
[[ -z \$DISPLAY && \$XDG_VTNR -eq 1 ]] && startx -- -nocursor
EOF

chown pizzicato:users /home/pizzicato/.bash_profile

cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pizzicato --noclear %I
EOF

