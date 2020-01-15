# hlnsrv-script
Bash script for running Hellion on a linux server

**Required packages**

-xvfb

-rsync

-tmux

-wine

-winetricks

-steamcmd

-curl

-wget

-cabextract

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

-send email notifications on server startup (optional)

-send email notifications on server shutdown (optional)

-send discord notifications after 3 crashes within a 5 minute time limit (optional)

-send discord notifications when server updated (optional)

-send discord notifications on server startup (optional)

-send discord notifications on server shutdown (optional)

-supports multiple discord webhooks

**Instructions:**

Log in to your server with ssh and execute:

```git clone https://github.com/7thCore/hlnsrv-script```

Make it executable:

```chmod +x ./hlnsrv-script.bash```

If you plan on using a ramdisk to run your server from, the script will give you that option.

Now for the installation.

If you wish you can have the script install the required packages with (Only for Arch Linux & Ubuntu 19.10):

```sudo ./hlnsrv-script.bash -install_packages```

After that run the script with root permitions like so (necessary for user creation):

```sudo ./hlnsrv-script.bash -install```

The script will create a new non-sudo enabled user from wich the game server will run. If you want to have multiple game servers on the same ma
chine just run the script multiple times but with a diffrent username inputted to the script.

After the installation finishes you can reboot the operating system and the service files will start the game server automaticly on boot.

You can also install bash aliases to make your life easier with the following command:

```./hlnsrv-script.bash -install_aliases```

After that relog.

Any other script commands are available with:

```./hlnsrv-script.bash -help```

That should be it.

**Known issues are:**

-Wine version 4.12 and later are fubar. Use 4.11 or lower.

-The winetricks package in ubuntu is outdated. Follow this guide to install the latest winetricks: https://wiki.winehq.org/Winetricks (needed for dotnet472)

-if for some reason systemd reports the service failed when it stops, don't worry about it, the server session shuts down gracefully. (This should be solved)
