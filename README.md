# isrsrv-script
Bash script for running Hellion on a linux server

**Required packages**

-xvfb

-screen

-wine

-winetricks

-steamcmd

**Features:**

-auto backups

-auto updates

-script logging

-auto restart if crashed

-delete old backups

-delete old logs

-run from ramdisk

-sync from ramdisk to hdd/ssd

-start on os boot

-shutdown gracefully on os shutdown

-script auto update from github (not working atm)

**Instructions:**

Log in to your server with ssh and execute:

git clone https://github.com/7thCore/hlnsrv-script

If you plan to use a ramdisk change the variable:

TMPFS_ENABLE="0"

to

TMPFS_ENABLE="1"

Sometime between the insallation process you will be prompted for steam's two factor authentication code and after that steamcmd will not ask you for another code once it runs if you are using steam guard via email.

Now for the installation.

First use the -install argument (run only this command as root) and follow the instructions.

That should be it.

**Known issues are:**
-if for some reason systemd reports the service failed when it stops, don't worry about it, the server session shuts down gracefully.
