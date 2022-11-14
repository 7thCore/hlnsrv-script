#!/bin/bash

#    Copyright (C) 2022 7thCore
#    This file is part of HlnSrv-Script.
#
#    HlnSrv-Script is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    HlnSrv-Script is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#Hellion server script by 7thCore
#If you do not know what any of these settings are you are better off leaving them alone. One thing might brake the other if you fiddle around with it.

#Static script variables
export NAME="HlnSrv" #Name of the tmux session.
export VERSION="1.3-6" #Package and script version.
export SERVICE_NAME="hlnsrv" #Name of the service files, user, script and script log.
export LOG_DIR="/srv/$SERVICE_NAME/logs" #Location of the script's log files.
export LOG_STRUCTURE="$LOG_DIR/$(date +"%Y")/$(date +"%m")/$(date +"%d")" #Folder structure of the script's log files.
export LOG_SCRIPT="$LOG_STRUCTURE/$SERVICE_NAME-script.log" #Script log.
SRV_DIR="/srv/$SERVICE_NAME/server" #Location of the server located on your hdd/ssd.
TMPFS_DIR="/srv/$SERVICE_NAME/tmpfs" #Locaton of your tmpfs partition.
CONFIG_DIR="/srv/$SERVICE_NAME/config" #Location of this script's configuration.
UPDATE_DIR="/srv/$SERVICE_NAME/updates" #Location of update information for the script's automatic update feature.
BCKP_DIR="/srv/$SERVICE_NAME/backups" #Location of stored backups.
BCKP_STRUCTURE="$(date +"%Y")/$(date +"%m")/$(date +"%d")" #How backups are sorted, by default it's sorted in folders by month and day.

#Static wine variables
WINE_ARCH="win64"
WINE_PREFIX_GAME_DIR="drive_c/Games/Hellion" #Server executable directory.
WINE_PREFIX_GAME_CONFIG="drive_c/Games/Hellion" #Server save and configuration location.
WINE_PREFIX_GAME_EXE="HELLION_Dedicated.exe" #Server executable.
APPID="598850" #Steam app id for the server

#Script config file variables
TMPFS_ENABLE=$(cat $CONFIG_DIR/$SERVICE_NAME-script.conf 2> /dev/null | grep script_tmpfs= | cut -d = -f2) #Get configuration for tmpfs.
BCKP_DELOLD=$(cat $CONFIG_DIR/$SERVICE_NAME-script.conf 2> /dev/null | grep script_bckp_delold= | cut -d = -f2) #Defines how many days old backups are deleted.
LOG_DELOLD=$(cat $CONFIG_DIR/$SERVICE_NAME-script.conf 2> /dev/null | grep script_log_delold= | cut -d = -f2) #Defines how many days old logs are deleted.
SAVE_DELOLD=$(cat $CONFIG_DIR/$SERVICE_NAME-script.conf 2> /dev/null | grep script_save_delold= | cut -d = -f2) #Delete old game logs.
UPDATE_IGNORE_FAILED_ACTIVATIONS=$(cat $CONFIG_DIR/$SERVICE_NAME-script.conf 2> /dev/null | grep script_update_ignore_failed_startups= | cut -d = -f2) #Defines if errors during startup after updates should be ignored.
TMPFS_SPACE=$(cat $CONFIG_DIR/$SERVICE_NAME-script.conf 2> /dev/null | grep script_tmpfs_space= | cut -d = -f2) #Defines how much can the tmpfs parition be filled until an automatic server shutdown is issued.

#Script config variables if config doesn't exist
TMPFS_ENABLE=${TMPFS_ENABLE:="0"} #If the variable for tmpfs is not defined, assign a default value.
BCKP_DELOLD=${BCKP_DELOLD:="7"} #If the variable for old backup deletion is not defined, assign a default value.
LOG_DELOLD=${LOG_DELOLD:="7"} #If the variable for old log deletion is not defined, assign a default value.
SAVE_DELOLD=${SAVE_DELOLD:="7"} #If the variable for save timeout is not defined, assign a default value.
UPDATE_IGNORE_FAILED_ACTIVATIONS=${UPDATE_IGNORE_FAILED_ACTIVATIONS:="0"} #If the variable for ignoring errors after updates is not defined, assign a default value.
TMPFS_SPACE=${TMPFS_SPACE:="90"} #If the variable for tmpfs space is not defined, assign a default value.

#Steamcmd config file variables
STEAMCMD_BETA_BRANCH=$(cat $CONFIG_DIR/$SERVICE_NAME-steam.conf 2> /dev/null | grep steamcmd_beta_branch= | cut -d = -f2) #Defines if the beta branch is enabled
STEAMCMD_BETA_BRANCH_NAME=$(cat $CONFIG_DIR/$SERVICE_NAME-steam.conf 2> /dev/null | grep steamcmd_beta_branch_name= | cut -d = -f2) #Defines the beta branch name

#Steamcmd config variables if config doesn't exist
STEAMCMD_BETA_BRANCH=${STEAMCMD_BETA_BRANCH:="0"} #If the variable for steam beta branch selection is not defined, assign a default value.
STEAMCMD_BETA_BRANCH_NAME=${STEAMCMD_BETA_BRANCH_NAME:="none"} #If the variable for steam beta branch name is not defined, assign a default value.

#Discord config file variables
DISCORD_UPDATE=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_update= | cut -d = -f2) #Send notification when the server updates.
DISCORD_START=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_start= | cut -d = -f2) #Send notifications when the server starts.
DISCORD_STOP=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_stop= | cut -d = -f2) #Send notifications when the server stops.
DISCORD_CRASH=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_crash= | cut -d = -f2) #Send notifications when the server crashes.
DISCORD_TMPFS_SPACE=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_tmpfs_space= | cut -d = -f2) #Send notifications if tmpfs space is over the designated percentage.
DISCORD_COLOR_PRESTART=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_prestart= | cut -d = -f2) #Discord embed color for prestart.
DISCORD_COLOR_POSTSTART=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_poststart= | cut -d = -f2) #Discord embed color for poststart.
DISCORD_COLOR_PRESTOP=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_prestop= | cut -d = -f2) #Discord embed color for prestop.
DISCORD_COLOR_POSTSTOP=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_poststop= | cut -d = -f2) #Discord embed color for poststop.
DISCORD_COLOR_UPDATE=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_update= | cut -d = -f2) #Discord embed color for update.
DISCORD_COLOR_CRASH=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_crash= | cut -d = -f2) #Discord embed color for crash.
DISCORD_COLOR_TMPFS_SPACE=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_tmpfs_space= | cut -d = -f2) #Discord embed color for tmpfs space.

#Discord config variables if config doesn't exist
DISCORD_UPDATE=${DISCORD_UPDATE:="0"} #If the variable for discord update is not defined, assign a default value.
DISCORD_START=${DISCORD_START:="0"} #If the variable for discord start is not defined, assign a default value.
DISCORD_STOP=${DISCORD_STOP:="0"} #If the variable for discord stop is not defined, assign a default value.
DISCORD_CRASH=${DISCORD_CRASH:="0"} #If the variable for discord crash is not defined, assign a default value.
DISCORD_TMPFS_SPACE=${DISCORD_TMPFS_SPACE:="0"} #If the variable for discord tmpfs space is not defined, assign a default value.
DISCORD_COLOR_PRESTART=${DISCORD_COLOR_PRESTART:="16776960"} #If the variable discord pre-start color is not defined, assign a default value.
DISCORD_COLOR_POSTSTART=${DISCORD_COLOR_POSTSTART:="65280"} #If the variable discord post-start color is not defined, assign a default value.
DISCORD_COLOR_PRESTOP=${DISCORD_COLOR_PRESTOP:="16776960"} #If the variable discord pre-stop color is not defined, assign a default value.
DISCORD_COLOR_POSTSTOP=${DISCORD_COLOR_POSTSTOP:="65280"} #If the variable discord post-stop color is not defined, assign a default value.
DISCORD_COLOR_UPDATE=${DISCORD_COLOR_UPDATE:="47083"} #If the variable discord update color is not defined, assign a default value.
DISCORD_COLOR_CRASH=${DISCORD_COLOR_CRASH:="16711680"} #If the variable for discord crash color is not defined, assign a default value.
DISCORD_COLOR_TMPFS_SPACE=${DISCORD_COLOR_TMPFS_SPACE:="16711680"} #If the variable for discord tmpfs space color is not defined, assign a default value.

#Email config file variables
EMAIL_SENDER=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_sender= | cut -d = -f2) #Send emails from this address.
EMAIL_RECIPIENT=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_recipient= | cut -d = -f2) #Send emails to this address.
EMAIL_UPDATE=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_update= | cut -d = -f2) #Send emails when server updates.
EMAIL_START=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_start= | cut -d = -f2) #Send emails when the server starts up.
EMAIL_STOP=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_stop= | cut -d = -f2) #Send emails when the server shuts down.
EMAIL_CRASH=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_crash= | cut -d = -f2) #Send emails when the server crashes.
EMAIL_TMPFS_SPACE=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_tmpfs_space= | cut -d = -f2) #Send emails if tmpfs space is over the designated percentage.

#Email config variables if config doesn't exist
EMAIL_SENDER=${EMAIL_SENDER:="none"} #If the variable for email sender is not defined, assign a default value.
EMAIL_RECIPIENT=${EMAIL_RECIPIENT:="none"} #If the variable for email recipient is not defined, assign a default value.
EMAIL_UPDATE=${EMAIL_UPDATE:="0"} #If the variable for email update is not defined, assign a default value.
EMAIL_START=${EMAIL_START:="0"} #If the variable for email start is not defined, assign a default value.
EMAIL_STOP=${EMAIL_STOP:="0"} #If the variable for email stop is not defined, assign a default value.
EMAIL_CRASH=${EMAIL_CRASH:="0"} #If the variable for email crash is not defined, assign a default value.
EMAIL_TMPFS_SPACE=${EMAIL_TMPFS_SPACE:="0"} #If the variable for email tmpfs space is not defined, assign a default value.

#TmpFs/hdd variables
if [[ "$TMPFS_ENABLE" == "1" ]]; then
	BCKP_SRC_DIR="$TMPFS_DIR/drive_c/Games/Hellion" #Application data of the tmpfs
	SERVICE="$SERVICE_NAME-tmpfs" #TmpFs service file name
else
	BCKP_SRC_DIR="$SRV_DIR/drive_c/Games/Hellion" #Application data of the hdd/ssd
	SERVICE="$SERVICE_NAME" #Hdd/ssd service file name
fi

#Console collors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
LIGHTRED='\033[1;31m'
NC='\033[0m'

#--------------------------
#-- End of configuration --
#--------------------------

#Generate log folder structure
script_logs() {
	#If there is not a folder for today, create one
	if [ ! -d "$LOG_STRUCTURE" ]; then
		mkdir -p $LOG_STRUCTURE
	fi
}

#--------------------------

#Discord webhook message send
script_discord_message() {
	while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
		curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"author\": { \"name\": \"$NAME Script\", \"url\": \"https://github.com/7thCore/$SERVICE_NAME-script\" }, \"color\": \"$1\", \"description\": \"$2\", \"footer\": {\"text\": \"Version $VERSION\"}, \"timestamp\": \"$(date -u --iso-8601=seconds)\"}] }" "$DISCORD_WEBHOOK"
	done < $CONFIG_DIR/discord_webhooks.txt
}

#--------------------------

#Send email message
script_email_message() {
	mail -r "$EMAIL_SENDER ($1)" -s "$2" $EMAIL_RECIPIENT <<- EOF
	$3
	EOF
}

#--------------------------

#Attaches to the server tmux session
script_attach() {
	script_logs
	tmux -L $SERVICE_NAME-tmux.sock has-session -t $NAME 2>/dev/null
	if [ $? == 0 ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Attach) User attached to server session with ID: $1" | tee -a "$LOG_SCRIPT"
		tmux -L $SERVICE_NAME-tmux.sock attach -t $NAME
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Attach) User deattached from server session with ID: $1" | tee -a "$LOG_SCRIPT"
	else
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Attach) Failed to attach to server session with ID: $1" | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Deletes old files
script_remove_old_files() {
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Remove old files) Beginning removal of old files." | tee -a "$LOG_SCRIPT"
	#Delete old logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Remove old files) Removing old script logs: $LOG_DELOLD days old." | tee -a "$LOG_SCRIPT"
	find $LOG_DIR/* -mtime +$LOG_DELOLD -delete
	#Delete old game logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Remove old files) Removing old game saves: leave latest $SAVE_DELOLD save files." | tee -a "$LOG_SCRIPT"
	#Check if running on tmpfs and delete saves
	if [[ "$TMPFS_ENABLE" == "1" ]]; then
		find $TMPFS_DIR/drive_c/Games/Hellion/*.save -type f -printf '%T@\t%p\n' | sort -t $'\t' -g |  head -n -$SAVE_DELOLD | cut -d $'\t' -f 2- | xargs rm
	fi
	find $SRV_DIR/drive_c/Games/Hellion/*.save -type f -printf '%T@\t%p\n' | sort -t $'\t' -g |  head -n -$SAVE_DELOLD | cut -d $'\t' -f 2- | xargs rm
	#Delete empty folders
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Remove old files) Removing empty script log folders." | tee -a "$LOG_SCRIPT"
	find $LOG_DIR/ -type d -empty -delete
	# Delete old backups
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Remove old files) Deleting old backups for $SERVER_INSTANCE: $BCKP_DELOLD days old." | tee -a "$LOG_SCRIPT"
	find $BCKP_DIR/* -type f -mtime +$BCKP_DELOLD -delete
	# Delete empty folders
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Remove old files) Deleting empty backup folders for $SERVER_INSTANCE." | tee -a "$LOG_SCRIPT"
	find $BCKP_DIR/ -type d -empty -delete
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Remove old files) Removal of old files complete." | tee -a "$LOG_SCRIPT"
}

#--------------------------

#Prints out if the server is running
script_status() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Disable all script services
script_disable_services() {
	script_logs
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-mkdir-tmpfs.service)" == "enabled" ]]; then
		systemctl --user disable $SERVICE_NAME-mkdir-tmpfs.service
	fi
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-tmpfs.service)" == "enabled" ]]; then
		systemctl --user disable $SERVICE_NAME-tmpfs.service
	fi
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME.service)" == "enabled" ]]; then
		systemctl --user disable $SERVICE_NAME.service
	fi
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-timer-1.timer)" == "enabled" ]]; then
		systemctl --user disable $SERVICE_NAME-timer-1.timer
	fi
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-timer-2.timer)" == "enabled" ]]; then
		systemctl --user disable $SERVICE_NAME-timer-2.timer
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Disable services) Services successfully disabled." | tee -a "$LOG_SCRIPT"
}

#--------------------------

#Disables all script services, available to the user
script_disable_services_manual() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Disable services) WARNING: This will disable all script services. The server will be disabled." | tee -a "$LOG_SCRIPT"
	read -p "Are you sure you want to disable all services? (y/n): " DISABLE_SCRIPT_SERVICES
	if [[ "$DISABLE_SCRIPT_SERVICES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		script_disable_services
	elif [[ "$DISABLE_SCRIPT_SERVICES" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Disable services) Disable services canceled." | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

# Enable script services by reading the configuration file
script_enable_services() {
	script_logs
	if [[ "$TMPFS_ENABLE" == "1" ]]; then
		if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-mkdir-tmpfs.service)" == "disabled" ]]; then
			systemctl --user enable $SERVICE_NAME-mkdir-tmpfs.service
		fi
		if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-tmpfs.service)" == "disabled" ]]; then
			systemctl --user enable $SERVICE_NAME-tmpfs.service
		fi
	else
		if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME.service)" == "disabled" ]]; then
			systemctl --user enable $SERVICE_NAME.service
		fi
	fi
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-timer-1.timer)" == "disabled" ]]; then
		systemctl --user enable $SERVICE_NAME-timer-1.timer
	fi
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-timer-2.timer)" == "disabled" ]]; then
		systemctl --user enable $SERVICE_NAME-timer-2.timer
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Enable services) Services successfully Enabled." | tee -a "$LOG_SCRIPT"
}

#--------------------------

# Enable script services by reading the configuration file, available to the user
script_enable_services_manual() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Enable services) This will enable all script services. The server will be enabled." | tee -a "$LOG_SCRIPT"
	read -p "Are you sure you want to enable all services? (y/n): " ENABLE_SCRIPT_SERVICES
	if [[ "$ENABLE_SCRIPT_SERVICES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		script_enable_services
	elif [[ "$ENABLE_SCRIPT_SERVICES" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Enable services) Enable services canceled." | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Disables all script services an re-enables them by reading the configuration file
script_reload_services() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Reload services) This will reload all script services." | tee -a "$LOG_SCRIPT"
	read -p "Are you sure you want to reload all services? (y/n): " RELOAD_SCRIPT_SERVICES
	if [[ "$RELOAD_SCRIPT_SERVICES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		script_disable_services
		systemctl --user daemon-reload
		script_enable_services
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Reload services) Reload services complete." | tee -a "$LOG_SCRIPT"
	elif [[ "$RELOAD_SCRIPT_SERVICES" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Reload services) Reload services canceled." | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Pre-start functions to be called by the systemd service
script_prestart() {
	script_logs
	if [[ "$DISCORD_START" == "1" ]]; then
		script_discord_message "$DISCORD_COLOR_PRESTART" "Server startup for $1 was initialized."
	fi
	if [[ "$EMAIL_START" == "1" ]]; then
		script_email_message "$NAME-$1" "Notification: Server startup $1" "Server startup for $1 was initialized at $(date +"%d.%m.%Y %H:%M:%S")"
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server startup was initialized." | tee -a "$LOG_SCRIPT"

	if [[ "$TMPFS_ENABLE" == "1" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Sync from disk to tmpfs has been initiated." | tee -a "$LOG_SCRIPT"
		if [ -d "$SRV_DIR" ]; then
			rsync -aAX --info=progress2 $SRV_DIR/ $TMPFS_DIR
		fi
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Sync from disk to tmpfs complete." | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Post-start functions to be called by the systemd service
script_poststart() {
	script_logs
	if [[ "$DISCORD_START" == "1" ]]; then
		script_discord_message "$DISCORD_COLOR_POSTSTART" "Server startup for $1 complete."
	fi
	if [[ "$EMAIL_START" == "1" ]]; then
		script_email_message "$NAME-$1" "Notification: Server startup $1" "Server startup for $1 was completed at $(date +"%d.%m.%Y %H:%M:%S")"
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server startup complete." | tee -a "$LOG_SCRIPT"
}

#--------------------------

#Pre-stop functions to be called by the systemd service
script_prestop() {
	script_logs
	if [[ "$DISCORD_STOP" == "1" ]]; then
		script_discord_message "$DISCORD_COLOR_PRESTOP" "Server shutdown for $1 was initialized."
	fi
	if [[ "$EMAIL_STOP" == "1" ]]; then
		script_email_message "$NAME-$1" "Notification: Server shutdown $1" "Server shutdown was initiated at $(date +"%d.%m.%Y %H:%M:%S")"
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server shutdown was initialized." | tee -a "$LOG_SCRIPT"
}

#--------------------------

#Post-stop functions to be called by the systemd service
script_poststop() {
	script_logs

	#Check if the server is still running, if it is wait for it to stop.
	while true; do
		tmux -L $SERVICE_NAME-tmux.sock has-session -t $NAME 2>/dev/null
		if [ $? -eq 1 ]; then
			break
		fi
		sleep 1
	done

	if [[ "$TMPFS_ENABLE" == "1" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Sync from tmpfs to disk has been initiated." | tee -a "$LOG_SCRIPT"
		if [ -f "$TMPFS_DIR" ]; then
			rsync -aAX --info=progress2 $TMPFS_DIR/ $SRV_DIR
		fi
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Sync from tmpfs to disk complete." | tee -a "$LOG_SCRIPT"
	fi

	if [ -f "/tmp/$SERVICE_NAME-tmux.log" ]; then
		rm /tmp/$SERVICE_NAME-tmux.log
	fi

	if [ -f "/tmp/$SERVICE_NAME-tmux.conf" ]; then
		rm /tmp/$SERVICE_NAME-tmux.conf
	fi

	if [ -f "$LOG_DIR/$SERVICE_NAME-wine.log" ]; then
		mv $LOG_DIR/$SERVICE_NAME-wine.log $LOG_STRUCTURE/$SERVICE_NAME-wine-$(date +"%Y-%m-%d_%H-%M").log
	else
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Move wine log) Nothing to move." | tee -a "$LOG_SCRIPT"
	fi

	if [[ "$DISCORD_STOP" == "1" ]]; then
		script_discord_message "$DISCORD_COLOR_POSTSTOP" "Server shutdown for $1 complete."
	fi
	if [[ "$EMAIL_STOP" == "1" ]]; then
		script_email_message "$NAME-$1" "Notification: Server shutdown $1" "Server shutdown was complete at $(date +"%d.%m.%Y %H:%M:%S")"
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server shutdown complete." | tee -a "$LOG_SCRIPT"
}

#--------------------------

#Sync server files from ramdisk to hdd/ssd
script_sync() {
	script_logs
	if [[ "$TMPFS_ENABLE" == "1" ]]; then
		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Sync) Sync from tmpfs to disk has been initiated." | tee -a "$LOG_SCRIPT"
			rsync -aAX --info=progress2 $TMPFS_DIR/ $SRV_DIR #| sed -e "s/^/$(date +"%Y-%m-%d %H:%M:%S") [$NAME] [INFO] (Sync) Syncing: /" | tee -a "$LOG_SCRIPT"
			sleep 1
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Sync) Sync from tmpfs to disk has been completed." | tee -a "$LOG_SCRIPT"
		fi
	elif [[ "$TMPFS_ENABLE" == "0" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Sync) Server does not have tmpfs enabled." | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Checks the space occupied on the tmpfs partition and if it's over the user designated value, shuts down tmpfs servers
script_tmpfs_space_check() {
	script_logs
	CURRENT_TMPFS_SPACE=$(df -H | grep "$TMPFS_DIR" | awk '{print $5}' | cut -d'%' -f1)
	if [ $CURRENT_TMPFS_SPACE -ge $TMPFS_SPACE ] ; then
		if [[ "$DISCORD_TMPFS_SPACE" == "1" ]]; then
			script_discord_message "$DISCORD_COLOR_TMPFS_SPACE" "The tmpfs partition is $CURRENT_TMPFS_SPACE percent filled. Automatic shutdown of the tmpfs server has been initiated."
		fi
		if [[ "$EMAIL_TMPFS_SPACE" == "1" ]]; then
			script_email_message "$NAME" "Notification: Tmpfs running out of space" "The tmpfs partition is $CURRENT_TMPFS_SPACE percent filled. Automatic shutdown of the tmpfs server has been initiated."
		fi
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Tmpfs space check) The tmpfs partition is at $CURRENT_TMPFS_SPACE percent filled.  Automatic shutdown of the tmpfs server has been initiated." | tee -a "$LOG_SCRIPT"
		if [[ "$(systemctl --user show -p ActiveState --value $SERVER_SERVICE)" == "active" ]] && [[ "$(systemctl --user show -p UnitFileState --value $SERVER_SERVICE)" == "enabled" ]]; then
				script_stop
		fi
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Tmpfs space check) Shutdown of tmpfs servers complete." | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Start the server
script_start() {
	script_logs

	#Loop until the server is active and output the state of it
	script_start_loop() {
		while [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; do
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server is activating. Please wait..." | tee -a "$LOG_SCRIPT"
			sleep 1
		done
		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server has been successfully activated." | tee -a "$LOG_SCRIPT"
			sleep 1
		elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server failed to activate. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
			sleep 1
		fi
	}

	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server start initialized." | tee -a "$LOG_SCRIPT"
		systemctl --user start $SERVICE
		script_start_loop
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server is already running." | tee -a "$LOG_SCRIPT"
		sleep 1
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server is in failed state. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
		if [[ "$1" == "ignore" ]]; then
			systemctl --user start $SERVER_SERVICE
			script_start_loop $SERVER_SERVICE
		else
			read -p "Do you still want to start the server? (y/n): " FORCE_START
			if [[ "$FORCE_START" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				systemctl --user start $SERVER_SERVICE
				script_start_loop $SERVER_SERVICE
			fi
		fi
	fi
}

#--------------------------

#Stop the server
script_stop() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server is not running." | tee -a "$LOG_SCRIPT"
		sleep 1
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server shutdown in progress." | tee -a "$LOG_SCRIPT"
		systemctl --user stop $SERVICE
		sleep 1
		while [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; do
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server is deactivating. Please wait..." | tee -a "$LOG_SCRIPT"
			sleep 1
		done
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server is deactivated." | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Restart the server
script_restart() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Restart) Server is not running. Use -start to start the server." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Restart) Server is activating. Aborting restart." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Restart) Server is in deactivating. Aborting restart." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Restart) Server is going to restart in 15-30 seconds, please wait..." | tee -a "$LOG_SCRIPT"
		sleep 1
		script_stop
		sleep 1
		script_start
		sleep 1
	fi
}

#--------------------------

#Systemd service sends email if email notifications for crashes enabled
script_send_notification_crash() {
	script_logs
	CRASH_TIME=$(date +"%Y-%m-%d_%H-%M")
	if [ ! -d "$LOG_STRUCTURE/Server-crash_$CRASH_TIME" ]; then
		mkdir -p "$LOG_STRUCTURE/Server-crash_$CRASH_TIME"
	fi

	systemctl --user status $SERVICE > $LOG_STRUCTURE/Server-crash_$CRASH_TIME/service_log.txt
	zip -j $LOG_STRUCTURE/Server-crash_$CRASH_TIME/service_logs.zip $LOG_STRUCTURE/Server-crash_$CRASH_TIME/service_log.txt
	zip -j $LOG_STRUCTURE/Server-crash_$CRASH_TIME/script_logs.zip $LOG_SCRIPT
	zip -j $LOG_STRUCTURE/Server-crash_$CRASH_TIME/wine_logs.zip "$(find $LOG_STRUCTURE/$SERVICE_NAME-wine*.log -type f -printf '%T@\t%p\n' | sort -t $'\t' -g | tail -n -1 | cut -d $'\t' -f 2-)"
	rm $LOG_STRUCTURE/Server-crash_$CRASH_TIME/service_log.txt

	if [[ "$EMAIL_CRASH" == "1" ]]; then
		mail -a $LOG_STRUCTURE/Server-crash_$CRASH_TIME/service_logs.zip -a $LOG_STRUCTURE/Server-crash_$CRASH_TIME/script_logs.zip -a $LOG_STRUCTURE/Server-crash_$CRASH_TIME/wine_logs.zip -r "$EMAIL_SENDER ($NAME-$SERVICE_NAME)" -s "Notification: Crash" $EMAIL_RECIPIENT <<- EOF
		The server crashed 3 times in the last 5 minutes. Automatic restart is disabled and the server is inactive. Please check the logs for more information.

		Attachment contents:
		service_logs.zip - Logs from the systemd service
		script_logs.zip - Logs from the script
		wine_logs.zip - Logs from the wine compatibility layer

		DO NOT SEND ANY OF THESE TO THE DEVS!
		EOF
	fi

	if [[ "$DISCORD_CRASH" == "1" ]]; then
		script_discord_message "$DISCORD_COLOR_CRASH" "Server $1 crashed 3 times in the last 5 minutes.\nAutomatic restart is disabled and the server is inactive.\n\nPlease review your logs located in $LOG_STRUCTURE/Server-crash_$CRASH_TIME."
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Crash) Server crashed. Please review your logs located in $LOG_STRUCTURE/Server-crash_$CRASH_TIME." | tee -a "$LOG_SCRIPT"
}

#--------------------------

#Creates a backup of the server
script_backup() {
	script_logs

	#If there is not a folder for today, create one
	script_backup_create_folder() {
		if [ ! -d "$BCKP_DIR/$BCKP_STRUCTURE" ]; then
			mkdir -p "$BCKP_DIR/$BCKP_STRUCTURE"
		fi
	}

	#Backup source to destination
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Backup) Backup has been initiated." | tee -a  "$LOG_SCRIPT"
	if [[ "$(systemctl --user show -p ActiveState --value $SERVER_SERVICE-tmpfs)" != "active" ]] && [[ "$(systemctl --user show -p UnitFileState --value $SERVER_SERVICE)" == "enabled" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Autobackup) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVER_SERVICE)" == "active" ]] && [[ "$(systemctl --user show -p UnitFileState --value $SERVER_SERVICE)" == "enabled" ]]; then
		script_backup_create_folder
		cd "$TMPFS_DIR/$WINE_PREFIX_GAME_CONFIG"
		tar -cpvzf $BCKP_DIR/$BCKP_STRUCTURE/$(date +"%Y%m%d%H%M").tar.gz $TMPFS_DIR/$WINE_PREFIX_GAME_CONFIG/*.save $SRV_DIR/$WINE_PREFIX_GAME_CONFIG/GameServer.ini
	fi
	if [[ "$(systemctl --user show -p ActiveState --value $SERVER_SERVICE)" != "active" ]] && [[ "$(systemctl --user show -p UnitFileState --value $SERVER_SERVICE)" == "enabled" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Autobackup) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVER_SERVICE)" == "active" ]] && [[ "$(systemctl --user show -p UnitFileState --value $SERVER_SERVICE)" == "enabled" ]]; then
		script_backup_create_folder
		cd "$SRV_DIR/$WINE_PREFIX_GAME_CONFIG"
		tar -cpvzf $BCKP_DIR/$BCKP_STRUCTURE/$(date +"%Y%m%d%H%M").tar.gz $SRV_DIR/$WINE_PREFIX_GAME_CONFIG/*.save $SRV_DIR/$WINE_PREFIX_GAME_CONFIG/GameServer.ini
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Backup) Backup complete." | tee -a  "$LOG_SCRIPT"
}

#--------------------------

#Change the steam branch of the app
script_change_branch() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Change branch) Server branch change initiated. Waiting on user configuration." | tee -a "$LOG_SCRIPT"

	read -p "Are you sure you want to change the server branch? (y/n): " CHANGE_SERVER_BRANCH
	if [[ "$CHANGE_SERVER_BRANCH" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo "Current configuration:"
		echo 'Beta branch enabled: '"$STEAMCMD_BETA_BRANCH"
		echo 'Beta branch name: '"$STEAMCMD_BETA_BRANCH_NAME"
		echo ""
		read -p "Public branch or beta branch? (public/beta): " SET_BRANCH_STATE
		echo ""
		if [[ "$SET_BRANCH_STATE" =~ ^([bB][eE][tT][aA]|[bB])$ ]]; then
			STEAMCMD_BETA_BRANCH="1"
			echo "Look up beta branch names at https://steamdb.info/app/$APPID/depots/"
			echo "Name example: experimental"
			read -p "Enter beta branch name: " STEAMCMD_BETA_BRANCH_NAME
		elif [[ "$SET_BRANCH_STATE" =~ ^([pP][uU][bB][lL][iI][cC]|[pP])$ ]]; then
			STEAMCMD_BETA_BRANCH="0"
			STEAMCMD_BETA_BRANCH_NAME="none"
		fi
		sed -i '/beta_branch_enabled/d' $CONFIG_DIR/$SERVICE_NAME-config.conf
		sed -i '/beta_branch_name/d' $CONFIG_DIR/$SERVICE_NAME-config.conf
		echo 'beta_branch_enabled='"$STEAMCMD_BETA_BRANCH" >> $CONFIG_DIR/$SERVICE_NAME-config.conf
		echo 'beta_branch_name='"$STEAMCMD_BETA_BRANCH_NAME" >> $CONFIG_DIR/$SERVICE_NAME-config.conf

		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			script_stop
			WAS_ACTIVE="1"
		fi

		if [[ "$TMPFS_ENABLE" == "1" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Change branch) Clearing TmpFs directory and game installation." | tee -a "$LOG_SCRIPT"
			rm -rf $TMPFS_DIR
		fi

		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Change branch) Clearing game installation." | tee -a "$LOG_SCRIPT"
		rm -rf $SRV_DIR/$WINE_PREFIX_GAME_DIR/*

		if [[ "$STEAMCMD_BETA_BRANCH" == "0" ]]; then
			INSTALLED_BUILDID=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
			echo "$INSTALLED_BUILDID" > $UPDATE_DIR/installed.buildid

			INSTALLED_TIME=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
			echo "$INSTALLED_TIME" > $UPDATE_DIR/installed.timeupdated

			steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login anonymous +app_update $APPID validate +quit
		elif [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
			INSTALLED_BUILDID=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
			echo "$INSTALLED_BUILDID" > $UPDATE_DIR/installed.buildid

			INSTALLED_TIME=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
			echo "$INSTALLED_TIME" > $UPDATE_DIR/installed.timeupdated

			steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login anonymous +app_update $APPID -beta $STEAMCMD_BETA_BRANCH_NAME validate +quit
		fi

		if [[ "$WAS_ACTIVE" == "1" ]]; then
			if [[ "$UPDATE_IGNORE_FAILED_ACTIVATIONS" == "1" ]]; then
				script_start "ignore"
			else
				script_start
			fi
		fi
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Change branch) Server branch change complete." | tee -a "$LOG_SCRIPT"
	elif [[ "$CHANGE_SERVER_BRANCH" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Change branch) Server branch change canceled." | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Check for updates. If there are updates available, shut down the server, update it and restart it.
script_update() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Initializing update check." | tee -a "$LOG_SCRIPT"
	if [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Beta branch enabled. Branch name: $STEAMCMD_BETA_BRANCH_NAME" | tee -a "$LOG_SCRIPT"
	fi

	if [ ! -f $UPDATE_DIR/installed.buildid ] ; then
		touch $UPDATE_DIR/installed.buildid
		echo "0" > $UPDATE_DIR/installed.buildid
	fi

	if [ ! -f $UPDATE_DIR/installed.timeupdated ] ; then
		touch $UPDATE_DIR/installed.timeupdated
		echo "0" > $UPDATE_DIR/installed.timeupdated
	fi

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Removing Steam/appcache/appinfo.vdf" | tee -a "$LOG_SCRIPT"
	rm -rf "/srv/$SERVICE_NAME/.steam/appcache/appinfo.vdf"

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Connecting to steam servers." | tee -a "$LOG_SCRIPT"

	if [[ "$STEAMCMD_BETA_BRANCH" == "0" ]]; then
		AVAILABLE_BUILDID=$(steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
		AVAILABLE_TIME=$(steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
	elif [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
		AVAILABLE_BUILDID=$(steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
		AVAILABLE_TIME=$(steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
	fi

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Received application info data." | tee -a "$LOG_SCRIPT"

	INSTALLED_BUILDID=$(cat $UPDATE_DIR/installed.buildid)
	INSTALLED_TIME=$(cat $UPDATE_DIR/installed.timeupdated)

	if [ "$AVAILABLE_TIME" -gt "$INSTALLED_TIME" ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) New update detected." | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Installed: BuildID: $INSTALLED_BUILDID, TimeUpdated: $INSTALLED_TIME" | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Available: BuildID: $AVAILABLE_BUILDID, TimeUpdated: $AVAILABLE_TIME" | tee -a "$LOG_SCRIPT"

		if [[ "$DISCORD_UPDATE" == "1" ]]; then
			script_discord_message "$DISCORD_COLOR_UPDATE" "New update detected. Installing update."
		fi

		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			script_stop
			WAS_ACTIVE="1"
		fi

		if [[ "$TMPFS_ENABLE" == "1" ]]; then
			rsync -aAX --info=progress2 $TMPFS_DIR/ $SRV_DIR
			rm -rf $TMPFS_DIR/$WINE_PREFIX_GAME_DIR
		fi

		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Updating..." | tee -a "$LOG_SCRIPT"

		if [[ "$STEAMCMD_BETA_BRANCH" == "0" ]]; then
			steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login anonymous +app_update $APPID validate +quit
		elif [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
			steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login anonymous +app_update $APPID -beta $STEAMCMD_BETA_BRANCH_NAME validate +quit
		fi

		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Update completed." | tee -a "$LOG_SCRIPT"
		echo "$AVAILABLE_BUILDID" > $UPDATE_DIR/installed.buildid
		echo "$AVAILABLE_TIME" > $UPDATE_DIR/installed.timeupdated

		if [[ "$TMPFS_ENABLE" == "1" ]]; then
			mkdir -p $TMPFS_DIR/$WINE_PREFIX_GAME_DIR
			rsync -aAX --info=progress2 $SRV_DIR/ $TMPFS_DIR
		fi

		if [[ "$WAS_ACTIVE" == "1" ]]; then
			if [[ "$UPDATE_IGNORE_FAILED_ACTIVATIONS" == "1" ]]; then
				script_start "ignore"
			else
				script_start
			fi
		fi

		if [[ "$DISCORD_UPDATE" == "1" ]]; then
			script_discord_message "$DISCORD_COLOR_UPDATE" "Server update complete."
		fi
		if [[ "$EMAIL_UPDATE" == "1" ]]; then
			script_email_message "$NAME" "Notification: Update" "Server was updated. Please check the update notes if there are any additional steps to take."
		fi
	elif [ "$AVAILABLE_TIME" -eq "$INSTALLED_TIME" ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) No new updates detected." | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Installed: BuildID: $INSTALLED_BUILDID, TimeUpdated: $INSTALLED_TIME" | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Shutdown any active servers, check the integrity of the server files and restart the servers.
script_verify_game_integrity() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Integrity check) Initializing integrity check." | tee -a "$LOG_SCRIPT"
	if [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Integrity check) Beta branch enabled. Branch name: $STEAMCMD_BETA_BRANCH_NAME" | tee -a "$LOG_SCRIPT"
	fi

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Integrity check) Removing Steam/appcache/appinfo.vdf" | tee -a "$LOG_SCRIPT"
	rm -rf "/srv/$SERVICE_NAME/.steam/appcache/appinfo.vdf"

	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		script_stop
		WAS_ACTIVE="1"
	fi

	if [[ "$TMPFS_ENABLE" == "1" ]]; then
		rsync -aAX --info=progress2 $TMPFS_DIR/ $SRV_DIR
		rm -rf $TMPFS_DIR/$WINE_PREFIX_GAME_DIR
	fi

	if [[ "$STEAMCMD_BETA_BRANCH" == "0" ]]; then
		steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login anonymous +app_update $APPID validate +quit
	elif [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
		steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login anonymous +app_update $APPID -beta $STEAMCMD_BETA_BRANCH_NAME validate +quit
	fi

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Integrity check) Integrity check completed." | tee -a "$LOG_SCRIPT"

	if [[ "$TMPFS_ENABLE" == "1" ]]; then
		mkdir -p $TMPFS_DIR/$WINE_PREFIX_GAME_DIR
		rsync -aAX --info=progress2 $SRV_DIR/ $TMPFS_DIR
	fi

	if [[ "$WAS_ACTIVE" == "1" ]]; then
		if [[ "$UPDATE_IGNORE_FAILED_ACTIVATIONS" == "1" ]]; then
			script_start "ignore"
		else
			script_start
		fi
	fi
}

#--------------------------

#First timer function for systemd timers to execute parts of the script in order without interfering with each other
script_timer_one() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server running." | tee -a "$LOG_SCRIPT"
		script_remove_old_files
		script_sync
		script_backup
		script_update
		script_update_github
	fi
}

#--------------------------

#Second timer function for systemd timers to execute parts of the script in order without interfering with each other
script_timer_two() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server running." | tee -a "$LOG_SCRIPT"
		script_remove_old_files
		script_sync
		script_update
		script_update_github
	fi
}

#--------------------------

#Runs the diagnostics
script_diagnostics() {
	echo "Initializing diagnostics. Please wait..."
	echo ""
	sleep 3

	#Check package versions
	echo "Checkign package versions:"
	if [ -f "/usr/bin/pacman" ]; then
		echo "bash version:$(pacman -Qi bash | grep "^Version" | cut -d : -f2)"
		echo "coreutils version:$(pacman -Qi coreutils | grep "^Version" | cut -d : -f2)"
		echo "sudo version:$(pacman -Qi sudo | grep "^Version" | cut -d : -f2)"
		echo "grep version:$(pacman -Qi grep | grep "^Version" | cut -d : -f2)"
		echo "sed version:$(pacman -Qi sed | grep "^Version" | cut -d : -f2)"
		echo "awk version:$(pacman -Qi awk | grep "^Version" | cut -d : -f2)"
		echo "curl version:$(pacman -Qi curl | grep "^Version" | cut -d : -f2)"
		echo "rsync version:$(pacman -Qi rsync | grep "^Version" | cut -d : -f2)"
		echo "wget version:$(pacman -Qi wget | grep "^Version" | cut -d : -f2)"
		echo "findutils version:$(pacman -Qi findutils | grep "^Version" | cut -d : -f2)"
		echo "tmux version:$(pacman -Qi tmux | grep "^Version" | cut -d : -f2)"
		echo "jq version:$(pacman -Qi jq | grep "^Version" | cut -d : -f2)"
		echo "zip version:$(pacman -Qi zip | grep "^Version" | cut -d : -f2)"
		echo "unzip version:$(pacman -Qi unzip | grep "^Version" | cut -d : -f2)"
		echo "p7zip version:$(pacman -Qi p7zip | grep "^Version" | cut -d : -f2)"
		echo "postfix version:$(pacman -Qi postfix | grep "^Version" | cut -d : -f2)"
		echo "samba version:$(pacman -Qi samba | grep "^Version" | cut -d : -f2)"
		echo "cabextract version:$(pacman -Qi cabextract | grep "^Version" | cut -d : -f2)"
		echo "xvfb version:$(pacman -Qi xorg-server-xvfb | grep "^Version" | cut -d : -f2)"
		echo "wine version:$(pacman -Qi wine | grep "^Version" | cut -d : -f2)"
		echo "wine-mono version:$(pacman -Qi wine-mono | grep "^Version" | cut -d : -f2)"
		echo "wine_gecko version:$(pacman -Qi wine_gecko | grep "^Version" | cut -d : -f2)"
		echo "winetricks version:$(pacman -Qi winetricks | grep "^Version" | cut -d : -f2)"
		echo "steamcmd version:$(pacman -Qi steamcmd | grep "^Version" | cut -d : -f2)"
	elif [ -f "/usr/bin/dpkg" ]; then
		echo "bash version:$(dpkg -s bash | grep "^Version" | cut -d : -f2)"
		echo "coreutils version:$(dpkg -s coreutils | grep "^Version" | cut -d : -f2)"
		echo "sudo version:$(dpkg -s sudo | grep "^Version" | cut -d : -f2)"
		echo "libpam-systemd version:$(dpkg -s libpam-systemd | grep "^Version" | cut -d : -f2)"
		echo "grep version:$(dpkg -s grep | grep "^Version" | cut -d : -f2)"
		echo "sed version:$(dpkg -s sed | grep "^Version" | cut -d : -f2)"
		echo "gawk version:$(dpkg -s gawk | grep "^Version" | cut -d : -f2)"
		echo "curl version:$(dpkg -s curl | grep "^Version" | cut -d : -f2)"
		echo "rsync version:$(dpkg -s rsync | grep "^Version" | cut -d : -f2)"
		echo "wget version:$(dpkg -s wget | grep "^Version" | cut -d : -f2)"
		echo "findutils version:$(dpkg -s findutils | grep "^Version" | cut -d : -f2)"
		echo "tmux version:$(dpkg -s tmux | grep "^Version" | cut -d : -f2)"
		echo "jq version:$(dpkg -s jq | grep "^Version" | cut -d : -f2)"
		echo "zip version:$(dpkg -s zip | grep "^Version" | cut -d : -f2)"
		echo "unzip version:$(dpkg -s unzip | grep "^Version" | cut -d : -f2)"
		echo "p7zip version:$(dpkg -s p7zip | grep "^Version" | cut -d : -f2)"
		echo "postfix version:$(dpkg -s postfix | grep "^Version" | cut -d : -f2)"
		echo "cabextract version:$(dpkg -s cabextract | grep "^Version" | cut -d : -f2)"
		echo "xvfb version:$(dpkg -s xvfb | grep "^Version" | cut -d : -f2)"
		echo "winehq-staging version:$(dpkg -s winehq-staging | grep "^Version" | cut -d : -f2)"
		echo "winetricks version: $(winetricks --version)"
		echo "steamcmd version:$(dpkg -s steamcmd | grep "^Version" | cut -d : -f2)"
	fi
	echo ""

	echo "Checking if files and folders present:"
	#Check if files/folders present
	if [ -f "/usr/bin/$SERVICE_NAME-script" ] ; then
		echo "Script present: Yes"
	else
		echo "Script present: No"
	fi

	if [ -d "$CONFIG_DIR" ]; then
		echo "Configuration folder present: Yes"
	else
		echo "Configuration folder present: No"
	fi

	if [ -d "$BCKP_DIR" ]; then
		echo "Backups folder present: Yes"
	else
		echo "Backups folder present: No"
	fi

	if [ -d "/srv/$SERVICE_NAME/logs" ]; then
		echo "Logs folder present: Yes"
	else
		echo "Logs folder present: No"
	fi

	if [ -d "$SRV_DIR" ]; then
		echo "Server folder present: Yes"
		echo ""
		echo "List of installed applications in the prefix:"
		env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR wine uninstaller --list
		echo ""
	else
		echo "Server folder present: No"
	fi

	if [ -d "$UPDATE_DIR" ]; then
		echo "Updates folder present: Yes"
	else
		echo "Updates folder present: No"
	fi

	if [ -f "$CONFIG_DIR/$SERVICE_NAME-script.conf" ] ; then
		echo "Script configuration file present: Yes"
	else
		echo "Script configuration file present: No"
	fi

	if [ -f "$CONFIG_DIR/$SERVICE_NAME-steam.conf" ] ; then
		echo "Steam configuration file present: Yes"
	else
		echo "Steam configuration file present: No"
	fi

	if [ -f "$CONFIG_DIR/$SERVICE_NAME-discord.conf" ] ; then
		echo "Discord configuration file present: Yes"
	else
		echo "Discord configuration file present: No"
	fi

	if [ -f "$CONFIG_DIR/$SERVICE_NAME-email.conf" ] ; then
		echo "Email configuration file present: Yes"
	else
		echo "Email configuration file present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-mkdir-tmpfs.service" ]; then
		echo "Tmpfs mkdir service present: Yes"
	else
		echo "Tmpfs mkdir service present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-tmpfs.service" ]; then
		echo "Tmpfs service present: Yes"
	else
		echo "Tmpfs service present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME.service" ]; then
		echo "Basic service present: Yes"
	else
		echo "Basic service present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-timer-1.timer" ]; then
		echo "Timer 1 timer present: Yes"
	else
		echo "Timer 1 timer present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-timer-1.service" ]; then
		echo "Timer 1 service present: Yes"
	else
		echo "Timer 1 service present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-timer-2.timer" ]; then
		echo "Timer 2 timer present: Yes"
	else
		echo "Timer 2 timer present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-timer-2.service" ]; then
		echo "Timer 2 service present: Yes"
	else
		echo "Timer 2 service present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-send-notification.service" ]; then
		echo "Notification sending service present: Yes"
	else
		echo "Notification sending service present: No"
	fi

	if [ -f "$SRV_DIR/$WINE_PREFIX_GAME_DIR/$WINE_PREFIX_GAME_EXE" ]; then
		echo "Game executable present: Yes"
	else
		echo "Game executable present: No"
	fi

	echo "Diagnostics complete."
}

#--------------------------

#Install tmux configuration for specific server when first ran
script_server_tmux_install() {
	if [ -z "$1" ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Server tmux configuration) Installing tmux configuration for server." | tee -a "$LOG_SCRIPT"
		TMUX_CONFIG_FILE="/tmp/$SERVICE_NAME-tmux.conf"
	elif [[ "$1" == "override" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Server tmux configuration) Installing tmux override configuration for server." | tee -a "$LOG_SCRIPT"
		TMUX_CONFIG_FILE="$CONFIG_DIR/$SERVICE_NAME-tmux.conf"
	fi

	if [ -f $CONFIG_DIR/$SERVICE_NAME-tmux.conf ]; then
		cp $CONFIG_DIR/$SERVICE_NAME-tmux.conf /tmp/$SERVICE_NAME-tmux.conf
	else
		if [ ! -f $TMUX_CONFIG_FILE ]; then
			touch $TMUX_CONFIG_FILE
			cat > $TMUX_CONFIG_FILE <<- EOF
			#Tmux configuration
			set -g activity-action other
			set -g allow-rename off
			set -g assume-paste-time 1
			set -g base-index 0
			set -g bell-action any
			set -g default-command "${SHELL}"
			set -g default-terminal "tmux-256color"
			set -g default-shell "/bin/bash"
			set -g default-size "132x42"
			set -g destroy-unattached off
			set -g detach-on-destroy on
			set -g display-panes-active-colour red
			set -g display-panes-colour blue
			set -g display-panes-time 1000
			set -g display-time 3000
			set -g history-limit 10000
			set -g key-table "root"
			set -g lock-after-time 0
			set -g lock-command "lock -np"
			set -g message-command-style fg=yellow,bg=black
			set -g message-style fg=black,bg=yellow
			set -g mouse on
			#set -g prefix C-b
			set -g prefix2 None
			set -g renumber-windows off
			set -g repeat-time 500
			set -g set-titles off
			set -g set-titles-string "#S:#I:#W - \"#T\" #{session_alerts}"
			set -g silence-action other
			set -g status on
			set -g status-bg green
			set -g status-fg black
			set -g status-format[0] "#[align=left range=left #{status-left-style}]#{T;=/#{status-left-length}:status-left}#[norange default]#[list=on align=#{status-justify}]#[list=left-marker]<#[list=right-marker]>#[list=on]#{W:#[range=window|#{window_index} #{window-status-style}#{?#{&&:#{window_last_flag},#{!=:#{window-status-last-style},default}}, #{window-status-last-style},}#{?#{&&:#{window_bell_flag},#{!=:#{window-status-bell-style},default}}, #{window-status-bell-style},#{?#{&&:#{||:#{window_activity_flag},#{window_silence_flag}},#{!=:#{window-status-activity-style},default}}, #{window-status-activity-style},}}]#{T:window-status-format}#[norange default]#{?window_end_flag,,#{window-status-separator}},#[range=window|#{window_index} list=focus #{?#{!=:#{window-status-current-style},default},#{window-status-current-style},#{window-status-style}}#{?#{&&:#{window_last_flag},#{!=:#{window-status-last-style},default}}, #{window-status-last-style},}#{?#{&&:#{window_bell_flag},#{!=:#{window-status-bell-style},default}}, #{window-status-bell-style},#{?#{&&:#{||:#{window_activity_flag},#{window_silence_flag}},#{!=:#{window-status-activity-style},default}}, #{window-status-activity-style},}}]#{T:window-status-current-format}#[norange list=on default]#{?window_end_flag,,#{window-status-separator}}}#[nolist align=right range=right #{status-right-style}]#{T;=/#{status-right-length}:status-right}#[norange default]"
			set -g status-format[1] "#[align=centre]#{P:#{?pane_active,#[reverse],}#{pane_index}[#{pane_width}x#{pane_height}]#[default] }"
			set -g status-interval 15
			set -g status-justify left
			set -g status-keys emacs
			set -g status-left "[#S] "
			set -g status-left-length 10
			set -g status-left-style default
			set -g status-position bottom
			set -g status-right "#{?window_bigger,[#{window_offset_x}#,#{window_offset_y}] ,}\"#{=21:pane_title}\" %H:%M %d-%b-%y"
			set -g status-right-length 40
			set -g status-right-style default
			set -g status-style fg=black,bg=green
			set -g update-environment[0] "DISPLAY"
			set -g update-environment[1] "KRB5CCNAME"
			set -g update-environment[2] "SSH_ASKPASS"
			set -g update-environment[3] "SSH_AUTH_SOCK"
			set -g update-environment[4] "SSH_AGENT_PID"
			set -g update-environment[5] "SSH_CONNECTION"
			set -g update-environment[6] "WINDOWID"
			set -g update-environment[7] "XAUTHORITY"
			set -g visual-activity off
			set -g visual-bell off
			set -g visual-silence off
			set -g word-separators " -_@"

			#Change prefix key from ctrl+b to ctrl+a
			unbind C-b
			set -g prefix C-a
			bind C-a send-prefix

			#Bind C-a r to reload the config file
			bind-key r source-file /tmp/$SERVICE_NAME-tmux.conf \; display-message "Config reloaded!"

			set-hook -g session-created 'resize-window -y 24 -x 10000'
			set-hook -g client-attached 'resize-window -y 24 -x 10000'
			set-hook -g client-detached 'resize-window -y 24 -x 10000'
			set-hook -g client-resized 'resize-window -y 24 -x 10000'

			#Default key bindings (only here for info)
			#Ctrl-b l (Move to the previously selected window)
			#Ctrl-b w (List all windows / window numbers)
			#Ctrl-b <window number> (Move to the specified window number, the default bindings are from 0 – 9)
			#Ctrl-b q  (Show pane numbers, when the numbers show up type the key to goto that pane)

			#Ctrl-b f <window name> (Search for window name)
			#Ctrl-b w (Select from interactive list of windows)

			#Copy/ scroll mode
			#Ctrl-b [ (in copy mode you can navigate the buffer including scrolling the history. Use vi or emacs-style key bindings in copy mode. The default is emacs. To exit copy mode use one of the following keybindings: vi q emacs Esc)
			EOF
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Server tmux configuration) Tmux configuration for server installed successfully." | tee -a "$LOG_SCRIPT"
		fi
	fi
}

#--------------------------

#Generates the wine prefix
script_generate_wine_prefix() {
	Xvfb :5 -screen 0 1024x768x16 &
	env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEDLLOVERRIDES="mscoree=d" WINEPREFIX=$SRV_DIR wineboot --init /nogui
	env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR winetricks corefonts
	env DISPLAY=:5.0 WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR winetricks -q vcrun2015
	env DISPLAY=:5.0 WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR winetricks -q --force dotnet48
	env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR winetricks sound=disabled
	pkill -f Xvfb
}

#--------------------------

#Reinstalls the wine prefix
script_install_prefix() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "active" ]] && [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "activating" ]] && [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Reinstall Wine prefix) Wine prefix reinstallation commencing. Waiting on user configuration." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to reinstall the wine prefix? (y/n): " REINSTALL_PREFIX
		if [[ "$REINSTALL_PREFIX" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			#If there is not a backup folder for today, create one
			if [ ! -d "$BCKP_STRUCTURE" ]; then
				mkdir -p $BCKP_STRUCTURE
			fi
			read -p "Do you want to keep the game installation and server data (saves,configs,etc.)? (y/n): " REINSTALL_PREFIX_KEEP_DATA
			if [[ "$REINSTALL_PREFIX_KEEP_DATA" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				mkdir -p $BCKP_DIR/prefix_backup/game
				mv "$SRV_DIR/$WINE_PREFIX_GAME_DIR"/* $BCKP_DIR/prefix_backup/game
			fi
			rm -rf $SRV_DIR
			script_generate_wine_prefix
			if [[ "$REINSTALL_PREFIX_KEEP_DATA" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				mkdir -p "$SRV_DIR/$WINE_PREFIX_GAME_DIR"
				mv $BCKP_DIR/prefix_backup/game/* "$SRV_DIR/$WINE_PREFIX_GAME_DIR"
				rm -rf $BCKP_DIR/prefix_backup
			fi
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Reinstall Wine prefix) Wine prefix reinstallation complete." | tee -a "$LOG_SCRIPT"
		elif [[ "$REINSTALL_PREFIX" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Reinstall Wine prefix) Wine prefix reinstallation aborted." | tee -a "$LOG_SCRIPT"
		fi
	else
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Reinstall Wine prefix) Cannot reinstall wine prefix while server is running. Aborting..." | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Installs the steam configuration files and the game if the user so chooses
script_config_steam() {
	echo ""
	read -p "Do you want to use steam to download the game files and be resposible for maintaining them? (y/n): " INSTALL_STEAMCMD_ENABLE
	if [[ "$INSTALL_STEAMCMD_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo ""
		read -p "Enable beta branch? Used for experimental and legacy versions. (y/n): " INSTALL_STEAMCMD_BETA_BRANCH_ENABLE
		if [[ "$INSTALL_STEAMCMD_BETA_BRANCH_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			INSTALL_STEAMCMD_BETA_BRANCH="1"
			echo "Look up beta branch names at https://steamdb.info/app/$APPID/depots/"
			echo "Name example: experimental"
			read -p "Enter beta branch name: " INSTALL_STEAMCMD_BETA_BRANCH_NAME
		elif [[ "$INSTALL_STEAMCMD_BETA_BRANCH_ENABLE" =~ ^([nN][oO]|[nN])$ ]]; then
			INSTALL_STEAMCMD_BETA_BRANCH="0"
			INSTALL_STEAMCMD_BETA_BRANCH_NAME="none"
		fi

		read -p "Do you want to install the server files with steam now? (y/n): " INSTALL_STEAMCMD_GAME_FILES_ENABLE
		if [[ "$INSTALL_STEAMCMD_GAME_FILES_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			echo "Installing game..."
			steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit > $UPDATE_DIR/steam_app_data.txt

			if [[ "$INSTALL_STEAMCMD_BETA_BRANCH" == "0" ]]; then
				INSTALLED_BUILDID=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
				echo "$INSTALLED_BUILDID" > $UPDATE_DIR/installed.buildid

				INSTALLED_TIME=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
				echo "$INSTALLED_TIME" > $UPDATE_DIR/installed.timeupdated

				steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login anonymous +app_update $APPID validate +quit
			elif [[ "$INSTALL_STEAMCMD_BETA_BRANCH" == "1" ]]; then
				INSTALLED_BUILDID=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$INSTALL_STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
				echo "$INSTALLED_BUILDID" > $UPDATE_DIR/installed.buildid

				INSTALLED_TIME=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$INSTALL_STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
				echo "$INSTALLED_TIME" > $UPDATE_DIR/installed.timeupdated

				steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login anonymous +app_update $APPID -beta $INSTALL_STEAMCMD_BETA_BRANCH_NAME validate +quit
			fi
		else
			echo "Manual game installation selected. Copy your game files to $SRV_DIR/$WINE_PREFIX_GAME_DIR after installation."
		fi
	else
		echo ""
		echo "Manual game installation selected. Copy your game files to $SRV_DIR/$WINE_PREFIX_GAME_DIR after installation."
		INSTALL_STEAMCMD_BETA_BRANCH="0"
		INSTALL_STEAMCMD_BETA_BRANCH_NAME="none"
	fi

	echo "Writing configuration file..."
	touch $CONFIG_DIR/$SERVICE_NAME-steam.conf
	echo 'steamcmd_beta_branch='"$INSTALL_STEAMCMD_BETA_BRANCH" >> $CONFIG_DIR/$SERVICE_NAME-steam.conf
	echo 'steamcmd_beta_branch_name='"$INSTALL_STEAMCMD_BETA_BRANCH_NAME" >> $CONFIG_DIR/$SERVICE_NAME-steam.conf
	echo "Done"
}

#--------------------------

#Configures discord integration
script_config_discord() {
	echo ""
	read -p "Enable discord notifications (y/n): " INSTALL_DISCORD_ENABLE
	if [[ "$INSTALL_DISCORD_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo ""
		echo "You are able to add multiple webhooks for the script to use in the discord_webhooks.txt file located in the config folder."
		echo "EACH ONE HAS TO BE IN IT'S OWN LINE!"
		echo ""
		read -p "Enter your first webhook for the server: " INSTALL_DISCORD_WEBHOOK
		if [[ "$INSTALL_DISCORD_WEBHOOK" == "" ]]; then
			INSTALL_DISCORD_WEBHOOK="none"
		fi
		echo ""
		read -p "Discord notifications for game updates? (y/n): " INSTALL_DISCORD_UPDATE_ENABLE
			if [[ "$INSTALL_DISCORD_UPDATE_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_DISCORD_UPDATE="1"
			else
				INSTALL_DISCORD_UPDATE="0"
			fi
		echo ""
		read -p "Discord notifications for server startup? (y/n): " INSTALL_DISCORD_START_ENABLE
			if [[ "$INSTALL_DISCORD_START_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_DISCORD_START="1"
			else
				INSTALL_DISCORD_START="0"
			fi
		echo ""
		read -p "Discord notifications for server shutdown? (y/n): " INSTALL_DISCORD_STOP_ENABLE
			if [[ "$INSTALL_DISCORD_STOP_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_DISCORD_STOP="1"
			else
				INSTALL_DISCORD_STOP="0"
			fi
		echo ""
		read -p "Discord notifications for crashes? (y/n): " INSTALL_DISCORD_CRASH_ENABLE
			if [[ "$INSTALL_DISCORD_CRASH_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_DISCORD_CRASH="1"
			else
				INSTALL_DISCORD_CRASH="0"
			fi
		echo ""
		read -p "Discord notifications for tmpfs partition being close to full? (y/n): " INSTALL_DISCORD_TMPFS_SPACE_ENABLE
			if [[ "$INSTALL_DISCORD_TMPFS_SPACE_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_DISCORD_TMPFS_SPACE="1"
			else
				INSTALL_DISCORD_TMPFS_SPACE="0"
			fi
	elif [[ "$INSTALL_DISCORD_ENABLE" =~ ^([nN][oO]|[nN])$ ]]; then
		INSTALL_DISCORD_UPDATE="0"
		INSTALL_DISCORD_START="0"
		INSTALL_DISCORD_STOP="0"
		INSTALL_DISCORD_CRASH="0"
		INSTALL_DISCORD_TMPFS_SPACE="0"
	fi

	echo "Writing configuration file..."
	touch $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_update='"$INSTALL_DISCORD_UPDATE" > $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_start='"$INSTALL_DISCORD_START" >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_stop='"$INSTALL_DISCORD_STOP" >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_crash='"$INSTALL_DISCORD_CRASH" >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_tmpfs_space='"$INSTALL_DISCORD_TMPFS_SPACE" >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_color_prestart=16776960' >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_color_poststart=65280' >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_color_prestop=16776960' >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_color_poststop=65280' >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_color_update=47083' >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_color_crash=16711680' >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_color_tmpfs_space=16711680' >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo "$INSTALL_DISCORD_WEBHOOK" > $CONFIG_DIR/discord_webhooks.txt
	echo "Done"
}

#--------------------------

#Configures email integration
script_config_email() {
	echo ""
	read -p "Enable email notifications (y/n): " INSTALL_EMAIL_ENABLE
	if [[ "$INSTALL_EMAIL_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo ""
		read -p "Enter the email that will send the notifications (example: sender@gmail.com): " INSTALL_EMAIL_SENDER
		echo ""
		read -p "Enter the email that will recieve the notifications (example: recipient@gmail.com): " INSTALL_EMAIL_RECIPIENT
		echo ""
		read -p "Email notifications for game updates? (y/n): " INSTALL_EMAIL_UPDATE_ENABLE
			if [[ "$INSTALL_EMAIL_UPDATE_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_EMAIL_UPDATE="1"
			else
				INSTALL_EMAIL_UPDATE="0"
			fi
		echo ""
		read -p "Email notifications for server startup? (WARNING: this can be anoying) (y/n): " INSTALL_EMAIL_START_ENABLE
			if [[ "$INSTALL_EMAIL_START_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_EMAIL_START="1"
			else
				INSTALL_EMAIL_START="0"
			fi
		echo ""
		read -p "Email notifications for server shutdown? (WARNING: this can be anoying) (y/n): " INSTALL_EMAIL_STOP_ENABLE
			if [[ "$INSTALL_EMAIL_STOP_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_EMAIL_STOP="1"
			else
				INSTALL_EMAIL_STOP="0"
			fi
		echo ""
		read -p "Email notifications for crashes? (y/n): " INSTALL_EMAIL_CRASH_ENABLE
			if [[ "$INSTALL_EMAIL_CRASH_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_EMAIL_CRASH="1"
			else
				INSTALL_EMAIL_CRASH="0"
			fi
		echo ""
		read -p "Email notifications for tmpfs partition being close to full? (y/n): " INSTALL_EMAIL_TMPFS_SPACE_ENABLE
			if [[ "$INSTALL_EMAIL_TMPFS_SPACE_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_EMAIL_TMPFS_SPACE="1"
			else
				INSTALL_EMAIL_TMPFS_SPACE="0"
			fi
		if [[ "$EUID" == "$(id -u root)" ]]; then
			read -p "Configure postfix? (y/n): " INSTALL_EMAIL_CONFIGURE
			if [[ "$INSTALL_EMAIL_CONFIGURE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				echo ""
				read -p "Enter the relay host (example: smtp.gmail.com): " INSTALL_EMAIL_RELAY_HOST
				echo ""
				read -p "Enter the relay host port (example: 587): " INSTALL_EMAIL_RELAY_PORT
				echo ""
				read -p "Enter your password for $INSTALL_EMAIL_SENDER : " INSTALL_EMAIL_SENDER_PSW

				cat >> /etc/postfix/main.cf <<- EOF
				relayhost = [$INSTALL_EMAIL_RELAY_HOST]:$INSTALL_EMAIL_RELAY_PORT
				smtp_sasl_auth_enable = yes
				smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
				smtp_sasl_security_options = noanonymous
				smtp_tls_CApath = /etc/ssl/certs
				smtpd_tls_CApath = /etc/ssl/certs
				smtp_use_tls = yes
				EOF

				cat > /etc/postfix/sasl_passwd <<- EOF
				[$INSTALL_EMAIL_RELAY_HOST]:$INSTALL_EMAIL_RELAY_PORT    $INSTALL_EMAIL_SENDER:$INSTALL_EMAIL_SENDER_PSW
				EOF

				sudo chmod 400 /etc/postfix/sasl_passwd
				sudo postmap /etc/postfix/sasl_passwd
				sudo systemctl enable --now postfix
			fi
		else
			echo "Add the following lines to /etc/postfix/main.cf"
			echo "relayhost = [$INSTALL_EMAIL_RELAY_HOST]:$INSTALL_EMAIL_RELAY_HOST_PORT"
			echo "smtp_sasl_auth_enable = yes"
			echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
			echo "smtp_sasl_security_options = noanonymous"
			echo "smtp_tls_CApath = /etc/ssl/certs"
			echo "smtpd_tls_CApath = /etc/ssl/certs"
			echo "smtp_use_tls = yes"
			echo ""
			echo "Add the following line to /etc/postfix/sasl_passwd"
			echo "[$INSTALL_EMAIL_RELAY_HOST]:$INSTALL_EMAIL_RELAY_HOST_PORT    $INSTALL_EMAIL_SENDER:$INSTALL_EMAIL_SENDER_PSW"
			echo ""
			echo "Execute the following commands:"
			echo "sudo chmod 400 /etc/postfix/sasl_passwd"
			echo "sudo postmap /etc/postfix/sasl_passwd"
			echo "sudo systemctl enable postfix"
		fi
	elif [[ "$INSTALL_EMAIL_ENABLE" =~ ^([nN][oO]|[nN])$ ]]; then
		INSTALL_EMAIL_SENDER="none"
		INSTALL_EMAIL_RECIPIENT="none"
		INSTALL_EMAIL_UPDATE="0"
		INSTALL_EMAIL_START="0"
		INSTALL_EMAIL_STOP="0"
		INSTALL_EMAIL_CRASH="0"
		INSTALL_EMAIL_TMPFS_SPACE="0"
	fi

	echo "Writing configuration file..."
	echo 'email_sender='"$INSTALL_EMAIL_SENDER" > $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo 'email_recipient='"$INSTALL_EMAIL_RECIPIENT" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo 'email_update='"$INSTALL_EMAIL_UPDATE" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo 'email_start='"$INSTALL_EMAIL_START" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo 'email_stop='"$INSTALL_EMAIL_STOP" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo 'email_crash='"$INSTALL_EMAIL_CRASH" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo 'email_tmpfs_space='"$INSTALL_EMAIL_TMPFS_SPACE" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	chown $SERVICE_NAME:$SERVICE_NAME $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo "Done"
}

#--------------------------

#Configures tmpfs integration
script_config_tmpfs() {
	echo ""
	read -p "Install tmpfs? (y/n): " INSTALL_TMPFS
	echo ""
	if [[ "$INSTALL_TMPFS" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		read -p "Ramdisk size (I recommend at least 8GB): " INSTALL_TMPFS_SIZE
		echo "Installing ramdisk configuration"
		if [[ "$EUID" == "$(id -u root)" ]] ; then
			cat >> /etc/fstab <<- EOF

			# $TMPFS_DIR
			tmpfs				   $TMPFS_DIR		tmpfs		   rw,size=$INSTALL_TMPFS_SIZE,uid=$(id -u $SERVICE_NAME),mode=0777	0 0
			EOF
		else
			echo "Add the following line to /etc/fstab:"
			echo "tmpfs				   $TMPFS_DIR		tmpfs		   rw,size=$INSTALL_TMPFS_SIZE,uid=$(id -u $SERVICE_NAME),mode=0777	0 0"
		fi
	fi
}

#--------------------------

#Configures the script
script_config_script() {
	echo -e "${CYAN}Script configuration${NC}"
	echo -e ""
	echo -e "The script uses steam to download the game server files, however you have the option to manualy copy the files yourself."
	echo -e ""
	echo -e "The script can work either way. The $SERVICE_NAME user's home directory is located in /srv/$SERVICE_NAME and all files are located there."
	echo -e "This configuration installation will only install the essential configuration. No steam, discord, email or tmpfs/ramdisk"
	echo -e "Default configuration will be applied and it can work without it. You can run the optional configuration for each using the"
	echo -e "following arguments with the script:"
	echo -e ""
	echo -e "${GREEN}config_steam   ${RED}- ${GREEN}Configures steamcmd, automatic updates and installs the game server files.${NC}"
	echo -e "${GREEN}config_discord ${RED}- ${GREEN}Configures discord integration.${NC}"
	echo -e "${GREEN}config_email   ${RED}- ${GREEN}Configures email integration. Due to postfix configuration files being in /etc this has to be executed as root.${NC}"
	echo -e "${GREEN}config_tmpfs   ${RED}- ${GREEN}Configures tmpfs/ramdisk. Due to it adding a line to /etc/fstab this has to be executed as root.${NC}"
	echo -e ""
	echo -e ""
	read -p "Press any key to continue" -n 1 -s -r
	echo ""

	echo "Enable services"

	systemctl --user enable $SERVICE_NAME.service
	systemctl --user enable --now $SERVICE_NAME-timer-1.timer
	systemctl --user enable --now $SERVICE_NAME-timer-2.timer

	echo "Writing config files"

	if [ -f "$CONFIG_DIR/$SERVICE_NAME-script.conf" ]; then
		rm $CONFIG_DIR/$SERVICE_NAME-script.conf
	fi

	touch $CONFIG_DIR/$SERVICE_NAME-script.conf
	echo 'script_tmpfs=0' >> $CONFIG_DIR/$SERVICE_NAME-script.conf
	echo 'script_bckp_delold=14' >> $CONFIG_DIR/$SERVICE_NAME-script.conf
	echo 'script_log_delold=7' >> $CONFIG_DIR/$SERVICE_NAME-script.conf
	echo 'script_save_delold=7' >> $CONFIG_DIR/$SERVICE_NAME-script.conf
	echo 'script_update_ignore_failed_startups=0' >> $CONFIG_DIR/$SERVICE_NAME-script.conf
	echo 'script_tmpfs_space=90' >> $CONFIG_DIR/$SERVICE_NAME-script.conf

	echo "Generating wine prefix"
	script_generate_wine_prefix

	if [ ! -d "$BCKP_SRC_DIR" ]; then
		mkdir -p "$BCKP_SRC_DIR"
	fi

	echo "Configuration complete"
	echo "For any settings you'll want to change, edit the files located in $CONFIG_DIR/"
	echo "To enable additional fuctions like steam, discord, email and tmpfs execute the script with the help argument."
}

#--------------------------

#Do not allow for another instance of this script to run to prevent data loss
if [[ "pre-start" != "$1" ]] && [[ "post-start" != "$1" ]] && [[ "pre-stop" != "$1" ]] && [[ "post-stop" != "$1" ]] && [[ "send_notification_crash" != "$1" ]] && [[ "server_tmux_install" != "$1" ]] && [[ "attach" != "$1" ]] && [[ "status" != "$1" ]]; then
	SCRIPT_PID_CHECK=$(basename -- "$0")
	if pidof -x "$SCRIPT_PID_CHECK" -o $$ > /dev/null; then
		echo "An another instance of this script is already running, please clear all the sessions of this script before starting a new session"
		exit 2
	fi
fi

#--------------------------

#Check what user is executing the script and allow root to execute certain functions.
if [[ "$EUID" != "$(id -u $SERVICE_NAME)" ]] && [[ "install_email" != "$1" ]] && [[ "install_tmpfs" != "$1" ]]; then
	echo "This script is only able to be executed by the $SERVICE_NAME user."
	echo "The following functions can also be executed as root: config_email, config_tmpfs"
	exit 3
fi

#--------------------------

#Script help page
case "$1" in
	help)
		echo -e "${CYAN}Time: $(date +"%Y-%m-%d %H:%M:%S") ${NC}"
		echo -e "${CYAN}$NAME server script by 7thCore${NC}"
		echo "Version: $VERSION"
		echo ""
		echo "Basic script commands:"
		echo -e "${GREEN}diag   ${RED}- ${GREEN}Prints out package versions and if script files are installed.${NC}"
		echo -e "${GREEN}status ${RED}- ${GREEN}Display status of server.${NC}"
		echo ""
		echo "Configuration and installation:"
		echo -e "${GREEN}config_script  ${RED}- ${GREEN}Configures the script, enables the systemd services and installs the wine prefix.${NC}"
		echo -e "${GREEN}config_steam   ${RED}- ${GREEN}Configures steamcmd, automatic updates and installs the game server files.${NC}"
		echo -e "${GREEN}config_discord ${RED}- ${GREEN}Configures discord integration.${NC}"
		echo -e "${GREEN}config_email   ${RED}- ${GREEN}Configures email integration. Due to postfix configuration files being in /etc this has to be executed as root.${NC}"
		echo -e "${GREEN}config_tmpfs   ${RED}- ${GREEN}Configures tmpfs/ramdisk. Due to it adding a line to /etc/fstab this has to be executed as root.${NC}"
		echo ""
		echo "Server services managment:"
		echo -e "${GREEN}enable_services  ${RED}- ${GREEN}Enables all services dependant on the configuration file of the script.${NC}"
		echo -e "${GREEN}disable_services ${RED}- ${GREEN}Disables all services. The server and the script will not start up on boot anymore.${NC}"
		echo -e "${GREEN}reload_services  ${RED}- ${GREEN}Reloads all services, dependant on the configuration file.${NC}"
		echo ""
		echo "Server and console managment:"
		echo -e "${GREEN}start            ${RED}- ${GREEN}Start the server. If the server number is not specified the function will start all servers.${NC}"
		echo -e "${GREEN}stop             ${RED}- ${GREEN}Stop the server. If the server number is not specified the function will stop all servers.${NC}"
		echo -e "${GREEN}restart          ${RED}- ${GREEN}Restart the server. If the server number is not specified the function will restart all servers.${NC}"
		echo -e "${GREEN}save             ${RED}- ${GREEN}Issue the save command to the server.${NC}"
		echo -e "${GREEN}sync             ${RED}- ${GREEN}Sync from tmpfs to hdd/ssd.${NC}"
		echo -e "${GREEN}attach           ${RED}- ${GREEN}Attaches to the tmux session of the specified server.${NC}"
		echo ""
		echo "Backup managment:"
		echo -e "${GREEN}backup        ${RED}- ${GREEN}Backup files, if server running or not.${NC}"
		echo ""
		echo "Steam managment:"
		echo -e "${GREEN}update        ${RED}- ${GREEN}Update the server, if the server is running it will save it, shut it down, update it and restart it.${NC}"
		echo -e "${GREEN}verify        ${RED}- ${GREEN}Verifiy game server files, if the server is running it will save it, shut it down, verify it and restart it.${NC}"
		echo -e "${GREEN}change_branch ${RED}- ${GREEN}Changes the game branch in use by the server (public,experimental,legacy and so on).${NC}"
		echo ""
		echo "Wine functions:"
		echo -e "${GREEN}rebuild_prefix ${RED}- ${GREEN}Reinstalls the wine prefix. Usefull if any wine prefix updates occoured.${NC}"
		echo ""
		;;
#--------------------------
#Basic script functions
	diag)
		script_diagnostics
		;;
	status)
		script_status
		;;
#--------------------------
#Configuration and installation
	config_script)
		script_config_script
		;;
	config_steam)
		script_config_steam
		;;
	config_discord)
		script_config_discord
		;;
	config_email)
		script_config_email
		;;
	config_tmpfs)
		script_config_tmpfs
		;;
#--------------------------
#Server services managment
	enable_services)
		script_enable_services_manual
		;;
	disable_services)
		script_disable_services_manual
		;;
	reload_services)
		script_reload_services
		;;
#--------------------------
#Server and console managment
	start)
		script_start $2
		;;
	stop)
		script_stop
		;;
	restart)
		script_restart
		;;
	save)
		script_save
		;;
	sync)
		script_sync
		;;
	attach)
		script_attach
		;;
#--------------------------
#Backup managment
	backup)
		script_backup
		;;
#--------------------------
#Steam managment
	update)
		script_update
		;;
	verify)
		script_verify_game_integrity
		;;
	change_branch)
		script_change_branch
		;;
#--------------------------
#Wine functions
	rebuild_prefix)
		script_install_prefix
		;;
#--------------------------
#Hidden functions meant for systemd service use
	pre-start)
		script_prestart
		;;
	post-start)
		script_poststart
		;;
	pre-stop)
		script_prestop
		;;
	post-stop)
		script_poststop
		;;
	send_notification_crash)
		script_send_notification_crash
		;;
	server_tmux_install)
		script_server_tmux_install $2 $3
		;;
	timer_one)
		script_timer_one
		;;
	timer_two)
		script_timer_two
		;;
	*)
#--------------------------
#General output if the script does not recognise the argument provided
	echo -e "${CYAN}Time: $(date +"%Y-%m-%d %H:%M:%S") ${NC}"
	echo -e "${CYAN}$NAME server script by 7thCore${NC}"
	echo ""
	echo "For more detailed information, execute the script with the -help argument"
	echo ""
	echo -e "${GREEN}Basic script commands${RED}: ${GREEN}help, diag, status${NC}"
	echo -e "${GREEN}Configuration and installation${RED}: ${GREEN}config_script, config_steam, config_discord, config_email, config_tmpfs${NC}"
	echo -e "${GREEN}Server services managment${RED}: ${GREEN}enable_services, disable_services, reload_services${NC}"
	echo -e "${GREEN}Server and console managment${RED}: ${GREEN}start, stop,restart, save, sync, attach${NC}"
	echo -e "${GREEN}Backup managment${RED}: ${GREEN}backup${NC}"
	echo -e "${GREEN}Steam managment${RED}: ${GREEN}update, verify, change_branch${NC}"
	echo -e "${GREEN}Game specific functions${RED}: ${GREEN}delete_save${NC}"
	echo -e "${GREEN}Wine functions${RED}: ${GREEN}rebuild_prefix${NC}"
	exit 1
	;;
esac

exit 0
