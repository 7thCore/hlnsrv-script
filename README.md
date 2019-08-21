# hlnsrv-script
Bash script for running Hellion on a linux server

**Required packages**

-xvfb

-screen

-wine

-winetricks

-steamcmd

-postfix (optional for email notifications)

-zip (optional but required if using the email feature)

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

-script auto update from github

-send email notifications after 3 crashes within a 5 minute time limit (optional)

-send email notifications when server updated (optional)

**Instructions:**

Log in to your server with ssh and execute:

git clone https://github.com/7thCore/hlnsrv-script

Make it executable:

chmod +x ./hlnsrv-script.bash

If you plan on using a ramdisk to run your server from, the script will give you that option.

Now for the installation.

Run the script with root permitions like so (necessary for user creation):

sudo ./hlnsrv-script.bash -install

The script will create a new non-sudo enabled user from wich the game server will run. If you want to have multiple game servers on the same ma
chine just run the script multiple times but with a diffrent username inputted to the script.

After the installation finishes you can reboot the operating system and the service files will start the game server automaticly on boot.

That should be it.

**Known issues are:**

-wine version 4.12 and 4.13 are fubar. Use 4.11

-if for some reason systemd reports the service failed when it stops, don't worry about it, the server session shuts down gracefully. (This should be solved)
