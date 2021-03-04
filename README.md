# Pizzicato
New version of my Raspberry pi 3B+ sound system

The configuration is based on a `Raspberry Pi OS lite 32-bits`

# Installation of the system

I'm running on a Mac therefore instructions correspond to that system.

First download the installer from the `Raspberry Pi OS` web site.

    https://www.raspberrypi.org/software/
    
Once the software dowloaded and installed run it and select from the 
`Raspberry Pi OS (Other)`sub menu the `Raspberry Pi OS lite (32-bits)`
item.

Select the SD card where you want to burn the system and click on the
write button.

Once the system is installed add at the root of the SD card an empty file
named `ssh` to activate the ssh server on the Pi.

```bash
touch /Volumes/boot/ssh
```

# Boot the Pi

If needed switch off your Pi and install the new SD card.
Switch on the Pi and wait for the boot time.

# Connection to the Pi

We can now connect to the Pi using ssh. From a unix terminal the command is

```bash
ssh pi@raspberrypi.local
```

remember that after a fresh install of `Raspberry Pi OS` :
- the default hostname is `raspberrypi`
- the defaut user name is `pi`
- the default password is `raspberry`





