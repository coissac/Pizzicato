#!/bin/bash

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
