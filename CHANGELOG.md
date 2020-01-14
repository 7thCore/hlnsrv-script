Update 2020-01-14

-fixed change branch function
-removed old script updating code
-fixed rebuild_prefix function
-fixed script update function (bug when multiple servers/scripts are updating at the same time)

-------------------------

Update 2020-01-13

-fixed discord configuration in installation (was displaying email instead of discord)
-integrated update script to the script itself
-removed systemd timers for auto script updates

-------------------------

Update 2020-01-09

-fixed -install_packages function. Said function was not detecting the distro correctly and in turn not installing the required packages.

-------------------------

Update 2020-01-08

-added minimal discord integration. The script can now send messages using the discord webhook api on events like crashes, game updates, server startup and shutdown. Server admins can use multiple webhooks if they so desire.

-------------------------

Update 2019-12-24

-added enable services function (to enable all services to run the server, read from the config file)
-added disable services function (to disable all services to run the server, the server will not startup automaticly anymore)
-added reload services function (disables, reloads and re-enables the services. Usefull if switching from a ramdisk to a hdd or vice-versa)

-------------------------

Update 2019-11-24

-fixed rebuild functions printing out wrong information
-fixed force update function in the update script (updates main script from github)

Existing users need to stop the server with systemctl --user stop hlnsrv-tmpfs.service or hlnsrv.service
Existing users need to update the script and execute the following paramerers to rebuild updated functions:
-rebuild_services

-------------------------

Update 2019-11-11

-small systemd service changes
-added function to implement command aliases for ease of use (execute the script with the -help argument for more info)
-added backups and logs deletion/how old backups get deleted in days to config file 

Existing users need to stop the server with systemctl --user stop hlnsrv-tmpfs.service or hlnsrv.service
Existing users need to update the script and execute the following paramerers to rebuild updated functions:
-rebuild_services

-------------------------

Update 2019-01-11

-fixed package installation for arch linux. No rebuilds required.

-------------------------

Update 2019-10-26

-added a function to detect a failed steam login and ask the user for their credentials again
-added the commands wrapper script
-added a function for auto installation of required packages (only for Arch Linux & Ubuntu 19.10 and onward)

-------------------------

Update 2019-10-14

Fixed a bug when typing symbols or caps in the server console it would crash it (Credit goes to the Split Polygon Dev Team).

Existing users need to stop the server with systemctl --user stop hlnsrv-tmpfs.service or hlnsrv.service
Existing users need to update the script and execute the following paramerers to rebuild updated functions:
-rebuild_services

-------------------------

Update 2019-08-10

-fixed a few bugs in the systemd service files and added a new service for piping the console output to multiple processes

Existing users need to stop the server with systemctl --user stop hlnsrv-tmpfs.service or hlnsrv.service
Existing users need to update the script and execute the following paramerers to rebuild updated functions:
-rebuild_services

-------------------------

Update 2019-10-05

-migrated from screen to tmux due to some limitations in screen.

Existing users need to stop the server with systemctl --user stop hlnsrv-tmpfs.service or hlnsrv.service
Existing users need to install tmux
Existing users need to update the script and execute the following paramerers to rebuild updated functions:
-rebuild_services
-rebuild_tmux_config

-------------------------

Update 2019-09-13

-modified service files (for ramdisk) so the mkdir service starts before the main service (if the main is executed by the user himself or the systemd service daemon)

Existing users need to update the script and execute the following paramerers to rebuild updated functions:
-rebuild_services argument

-------------------------

Update 2019-09-10

-fixed a problem with service files.
-fixed script being encoded in dos encoding

Existing users need to update the script and execute the following paramerers to rebuild updated functions:
-rebuild_services argument

-------------------------

Update 2019-07-09
-fixed a problem with service files on ubuntu.

Existing users need to update the script and execute the following paramerers to rebuild updated functions:
-rebuild_services argument

-------------------------

Update 2019-08-20
-fixed script execution when service inactive
-fixed delete old backup function so now it actually deletes empty folders and old files
-removed systemd interaction with the script/editing it (systemd turned the script on and off), the script will now check itself if the services are running, if not it will just stand by
-added rebuild commands/arguments for the wine prefix, systemd services and the update script (the script that auto updates the main script from github) so if i update any of those the users/server admins don't have to reinstall the whole thing
-added functions to the update script so users can either check for updates, or issue a force update to download/redownload the main script. The update script will check for updates on github once a day automaticly (users will get to decide to turn this feature on or off when installing the script)

Existing users need to update the script and execute the following parameters to rebuild updated functions:
-rebuild_update_script
-rebuild_services
