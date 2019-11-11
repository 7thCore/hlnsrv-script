#!/bin/bash

#Interstellar Rift server script by 7thCore
#If you do not know what any of these settings are you are better off leaving them alone. One thing might brake the other if you fiddle around with it.
export VERSION="201911112020"

#Basics
export NAME="HlnSrv" #Name of the tmux session
if [ "$EUID" -ne "0" ]; then #Check if script executed as root and asign the username for the installation process, otherwise use the executing user
	USER="$(whoami)"
else
	echo "WARNING: Installation mode"
	read -p "Please enter username (leave empty for hellion):" USER #Enter desired username that will be used when creating the new user
	USER=${USER:=hellion} #If no username was given, use default
fi

#Server configuration
SERVICE_NAME="hlnsrv" #Name of the service files, script and script log
SRV_DIR="/home/$USER/server" #Location of the server located on your hdd/ssd
SCRIPT_NAME="$SERVICE_NAME-script.bash" #Script name
SCRIPT_DIR="/home/$USER/scripts" #Location of this script
UPDATE_DIR="/home/$USER/updates" #Location of update information for the script's automatic update feature

if [ -f "$SCRIPT_DIR/$SERVICE_NAME-config.conf" ] ; then
	#Steamcmd
	BETA_BRANCH_ENABLED=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep beta_branch_enabled | cut -d = -f2) #Beta branch enabled?
	BETA_BRANCH_NAME=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep beta_branch_name | cut -d = -f2) #Beta branch name

	#Email configuration
	EMAIL_SENDER=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_sender | cut -d = -f2) #Send emails from this address
	EMAIL_RECIPIENT=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_recipient | cut -d = -f2) #Send emails to this address
	EMAIL_UPDATE=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_update | cut -d = -f2) #Send emails when server updates
	EMAIL_CRASH=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_crash | cut -d = -f2) #Send emails when the server crashes
	
	#Ramdisk configuration
	TMPFS_ENABLE=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep tmpfs_enable | cut -d = -f2) #Get configuration for tmpfs
	
	#Save game configuration
	SAVE_DELOLD=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep save_delold | cut -d = -f2) #How many latest save files should the script leave when deleting them.
	
	#Backup configuration
	BCKP_DELOLD=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep bckp_delold | cut -d = -f2) #Delete old backups.
	
	#Log configuration
	LOG_DELOLD=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep log_delold | cut -d = -f2) #Delete old logs.
else
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Configuration) The configuration is missing. Did you execute script installation?"
fi

#App id of the steam game
APPID="598850"

#Wine configuration
WINE_ARCH="win64"
WINE_PREFIX_GAME_DIR="drive_c/Games/Hellion" #Server executable directory
WINE_PREFIX_GAME_EXE="HELLION_Dedicated.exe" #Server executable
WINE_PREFIX_GAME_CONFIG="drive_c/Games/Hellion" #Server save and configuration location

#Ramdisk configuration
TMPFS_ENABLE=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep tmpfs_enable | cut -d = -f2) #Get configuration for tmpfs
TMPFS_DIR="/mnt/tmpfs/$USER" #Locaton of your tmpfs partition.

if [ "$EUID" -ne "0" ]; then #Check if script executed as root and assign the backup source dir.
	#TmpFs/hdd variables
	if [[ "$TMPFS_ENABLE" == "1" ]]; then
		BCKP_SRC_DIR="$TMPFS_DIR/drive_c/Games/Hellion" #Application data of the tmpfs
		SERVICE="$SERVICE_NAME-tmpfs.service" #TmpFs service file name
	elif [[ "$TMPFS_ENABLE" == "0" ]]; then
		BCKP_SRC_DIR="$SRV_DIR/drive_c/Games/Hellion" #Application data of the hdd/ssd
		SERVICE="$SERVICE_NAME.service" #Hdd/ssd service file name
	fi
else
	BCKP_SRC_DIR="$SRV_DIR/drive_c/Games/Hellion" #Application data of the hdd/ssd
fi

#Backup configuration
BCKP_SRC="*" #What files to backup, * for all
BCKP_DIR="/home/$USER/backups" #Location of stored backups
BCKP_DEST="$BCKP_DIR/$(date +"%Y")/$(date +"%m")/$(date +"%d")" #How backups are sorted, by default it's sorted in folders by month and day

#Log configuration
export LOG_DIR="/home/$USER/logs/$(date +"%Y")/$(date +"%m")/$(date +"%d")"
export LOG_SCRIPT="$LOG_DIR/$SERVICE_NAME-script.log" #Script log
export LOG_TMP="/tmp/$USER-$SERVICE_NAME-tmux.log"

TIMEOUT=120

#-------Do not edit anything beyond this line-------

#Console collors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
LIGHTRED='\033[1;31m'
NC='\033[0m'

#Deletes old logs
script_logs() {
	#If there is not a folder for today, create one
	if [ ! -d "$LOG_DIR" ]; then
		mkdir -p $LOG_DIR
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete old logs) Deleting old logs: $LOG_DELOLD days old." | tee -a "$LOG_SCRIPT"
	#Delete old logs
	find $LOG_DIR/* -mtime +$LOG_DELOLD -exec rm {} \;
	#Delete empty folders
	#find $LOG_DIR -type d 2> /dev/null -empty -exec rm -rf {} \;
	find $BCKP_DIR/ -type d -empty -delete
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete old logs) Deleting old logs complete." | tee -a "$LOG_SCRIPT"
}

#Prints out if the server is running
script_status() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	fi
}

#Systemd service sends email if email notifications for crashes enabled
script_send_crash_email() {
	if [[ "$EMAIL_CRASH" == "1" ]]; then
		systemctl --user status $SERVICE > $LOG_DIR/service_log.txt
		zip -j $LOG_DIR/service_logs.zip $LOG_DIR/service_log.txt
		zip -j $LOG_DIR/script_logs.zip $LOG_SCRIPT
		mail -a $LOG_DIR/service_logs.zip -a $LOG_DIR/script_logs.zip -r "$EMAIL_SENDER ($NAME-$USER)" -s "Notification: Crash" $EMAIL_RECIPIENT <<- EOF
		The server crashed 3 times in the last 5 minutes. Automatic restart is disabled and the server is inactive. Please check the logs for more information.
		
		Attachment contents:
		service_logs.zip - Logs from the systemd service
		script_logs.zip - Logs from the script
		
		DO NOT SEND ANY OF THESE TO THE DEVS!
		
		Contact the script developer 7thCore on discord for help regarding any problems the script may have caused.
		EOF
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Crash) Server crashed. Please review your logs." | tee -a "$LOG_SCRIPT"
}

#Sync server files from ramdisk to hdd/ssd
script_sync() {
	if [[ "$TMPFS_ENABLE" == "1" ]]; then
		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Sync) Sync from tmpfs to disk has been initiated." | tee -a "$LOG_SCRIPT"
			rsync -av --info=progress2 $TMPFS_DIR/ $SRV_DIR #| sed -e "s/^/$(date +"%Y-%m-%d %H:%M:%S") [$NAME] [INFO] (Sync) Syncing: /" | tee -a "$LOG_SCRIPT"
			sleep 1
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Sync) Sync from tmpfs to disk has been completed." | tee -a "$LOG_SCRIPT"
		fi
	elif [[ "$TMPFS_ENABLE" == "0" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Sync) Server does not have tmpfs enabled." | tee -a "$LOG_SCRIPT"
	fi
}

#Start the server
script_start() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server start initialized." | tee -a "$LOG_SCRIPT"
		systemctl --user start $SERVICE
		sleep 1
		while [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; do
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server is activating. Please wait..." | tee -a "$LOG_SCRIPT"
			sleep 1
		done
		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server has been successfully activated." | tee -a "$LOG_SCRIPT"
			sleep 1
		elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "active" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server failed to activate. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
			sleep 1
		fi
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server is already running." | tee -a "$LOG_SCRIPT"
		sleep 1
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server failed to activate. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
		sleep 1
	fi
}

#Stop the server
script_stop() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Stop) Server is not running." | tee -a "$LOG_SCRIPT"
		sleep 1
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Stop) Server shutdown in progress." | tee -a "$LOG_SCRIPT"
		systemctl --user stop $SERVICE
		sleep 1
		while [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; do
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Stop) Server is deactivating. Please wait..." | tee -a "$LOG_SCRIPT"
			sleep 1
		done
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Stop) Server is deactivated." | tee -a "$LOG_SCRIPT"
	fi
}

#Restart the server
script_restart() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Restart) Server is not running. Use -start to start the server." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Restart) Server is activating. Aborting restart." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Restart) Server is in deactivating. Aborting restart." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Restart) Server is going to restart in 15-30 seconds, please wait..." | tee -a "$LOG_SCRIPT"
		sleep 1
		script_stop
		sleep 1
		script_start
		sleep 1
	fi
}

#Deletes old save games
script_deloldsavefiles() {
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete old save files) Deleting old save files: leave latest $SAVE_DELOLD save files." | tee -a "$LOG_SCRIPT"
	#Check if running on tmpfs and delete saves
	if [[ "$TMPFS_ENABLE" == "1" ]]; then
		cd "$TMPFS_DIR/drive_c/Games/Hellion" #Application data of the tmpfs
		find $TMPFS_DIR/drive_c/Games/Hellion/*.save -type f -printf '%T@\t%p\n' | sort -t $'\t' -g |  head -n -$SAVE_DELOLD | cut -d $'\t' -f 2- | xargs rm
	elif [[ "$TMPFS_ENABLE" == "0" ]]; then
		find $SRV_DIR/drive_c/Games/Hellion*.save -type f -printf '%T@\t%p\n' | sort -t $'\t' -g |  head -n -$SAVE_DELOLD | cut -d $'\t' -f 2- | xargs rm
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete old save files) Deleting old save files complete." | tee -a "$LOG_SCRIPT"
}

#Deletes old backups
script_deloldbackup() {
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete old backup) Deleting old backups: $BCKP_DELOLD days old." | tee -a "$LOG_SCRIPT"
	# Delete old backups
	find $BCKP_DIR/* -type f -mtime +$BCKP_DELOLD -exec rm {} \;
	# Delete empty folders
	#find $BCKP_DIR/ -type d 2> /dev/null -empty -exec rm -rf {} \;
	find $BCKP_DIR/ -type d -empty -delete
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete old backup) Deleting old backups complete." | tee -a "$LOG_SCRIPT"
}

#Backs up the server
script_backup() {
	#If there is not a folder for today, create one
	if [ ! -d "$BCKP_DEST" ]; then
		mkdir -p $BCKP_DEST
	fi
	#Backup source to destination
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Backup) Backup has been initiated." | tee -a "$LOG_SCRIPT"
	cd "$BCKP_SRC_DIR"
	tar -cpvzf $BCKP_DEST/$(date +"%Y%m%d%H%M").tar.gz $BCKP_SRC #| sed -e "s/^/$(date +"%Y-%m-%d %H:%M:%S") [$NAME] [INFO] (Backup) Compressing: /" | tee -a "$LOG_SCRIPT"
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Backup) Backup complete." | tee -a "$LOG_SCRIPT"
}

#Automaticly backs up the server and deletes old backups
script_autobackup() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Autobackup) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		sleep 1
		script_backup
		sleep 1
		script_deloldbackup
	fi
}

#Delete the savegame from the server
script_delete_save() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete save) WARNING! This will delete the server's save game." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to delete the server's save game? (y/n): " DELETE_SERVER_SAVE
		if [[ "$DELETE_SERVER_SAVE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			read -p "Do you also want to delete the GameServer.ini? (y/n): " DELETE_SERVER_CONFIG
			if [[ "$DELETE_SERVER_CONFIG" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				if [[ "$TMPFS_ENABLE" == "1" ]]; then
					rm -rf $TMPFS_DIR
				fi
				rm -rf $SRV_DIR/$WINE_PREFIX_GAME_CONFIG/*.save
				rm -rf $SRV_DIR/$WINE_PREFIX_GAME_CONFIG/GameServer.ini
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete save) Deletion of save files and GameServer.ini complete." | tee -a "$LOG_SCRIPT"
			elif [[ "$DELETE_SERVER_CONFIG" =~ ^([nN][oO]|[nN])$ ]]; then
				if [[ "$TMPFS_ENABLE" == "1" ]]; then
					rm -rf $TMPFS_DIR
				fi
				rm -rf $SRV_DIR/$WINE_PREFIX_GAME_CONFIG/*.save
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete save) Deletion of save files complete. GameServer.ini is untouched." | tee -a "$LOG_SCRIPT"
			fi
		elif [[ "$DELETE_SERVER_SAVE" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete save) Save deletion canceled." | tee -a "$LOG_SCRIPT"
		fi
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Clear save) The server is running. Aborting..." | tee -a "$LOG_SCRIPT"
	fi
}

#Change the steam branch of the app
script_change_branch() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Change branch) Server branch change initiated. Waiting on user configuration." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to change the server branch? (y/n): " CHANGE_SERVER_BRANCH
		if [[ "$CHANGE_SERVER_BRANCH" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			if [[ "$TMPFS_ENABLE" == "1" ]]; then
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Change branch) Clearing TmpFs directory and game installation." | tee -a "$LOG_SCRIPT"
				rm -rf $TMPFS_DIR
				rm -rf $SRV_DIR/$WINE_PREFIX_GAME_DIR/*
			elif [[ "$TMPFS_ENABLE" == "0" ]]; then
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Change branch) Clearing game installation." | tee -a "$LOG_SCRIPT"
				rm -rf $SRV_DIR/$WINE_PREFIX_GAME_DIR/*
			fi
			if [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
				PUBLIC_BRANCH="0"
			elif [[ "$BETA_BRANCH_ENABLED" == "0" ]]; then
				PUBLIC_BRANCH="1"
			fi
			echo "Current configuration:"
			echo 'Public branch: '"$PUBLIC_BRANCH"
			echo 'Beta branch enabled: '"$BETA_BRANCH_ENABLED"
			echo 'Beta branch name: '"$BETA_BRANCH_NAME"
			echo ""
			read -p "Public branch or beta branch? (public/beta): " SET_BRANCH_STATE
			echo ""
			if [[ "$SET_BRANCH_STATE" =~ ^([bB][eE][tT][aA]|[bB])$ ]]; then
				BETA_BRANCH_ENABLED="1"
				echo "Look up beta branch names at https://steamdb.info/app/$APPID/depots/"
				echo "Name example: experimental"
				read -p "Enter beta branch name: " BETA_BRANCH_NAME
			elif [[ "$SET_BRANCH_STATE" =~ ^([pP][uU][bB][lL][iI][cC]|[pP])$ ]]; then
				BETA_BRANCH_ENABLED="0"
				BETA_BRANCH_NAME="none"
			fi
			sed -i '/beta_branch_enabled/d' $SCRIPT_DIR/$SERVICE_NAME-config.conf
			sed -i '/beta_branch_enabled/d' $SCRIPT_DIR/$SERVICE_NAME-config.conf
			echo 'beta_branch_enabled='"$BETA_BRANCH_ENABLED" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
			echo 'beta_branch_name='"$BETA_BRANCH_NAME" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
			if [[ "$BETA_BRANCH_ENABLED" == "0" ]]; then
				steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.buildid
				steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.timeupdated
				steamcmd +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +app_update $APPID -beta validate +quit
			elif [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
				steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.buildid
				steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.timeupdated
				steamcmd +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +app_update $APPID -beta $BETA_BRANCH_NAME validate +quit
			fi
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Change branch) Server branch change complete." | tee -a "$LOG_SCRIPT"
		elif [[ "$CHANGE_SERVER_BRANCH" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Change branch) Server branch change canceled." | tee -a "$LOG_SCRIPT"
		fi
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Change branch) The server is running. Aborting..." | tee -a "$LOG_SCRIPT"
	fi
}

#Check for updates. If there are updates available, shut down the server, update it and restart it.
script_update() {
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Initializing update check." | tee -a "$LOG_SCRIPT"
	if [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Beta branch enabled. Branch name: $BETA_BRANCH_NAME" | tee -a "$LOG_SCRIPT"
	fi
	
	if [ ! -f $UPDATE_DIR/installed.buildid ] ; then
		touch $UPDATE_DIR/installed.buildid
		echo "0" > $UPDATE_DIR/installed.buildid
	fi
	
	if [ ! -f $UPDATE_DIR/installed.timeupdated ] ; then
		touch $UPDATE_DIR/installed.timeupdated
		echo "0" > $UPDATE_DIR/installed.timeupdated
	fi
	
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Removing Steam/appcache/appinfo.vdf" | tee -a "$LOG_SCRIPT"
	rm -rf "/home/$USER/.steam/appcache/appinfo.vdf"
	
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Connecting to steam servers." | tee -a "$LOG_SCRIPT"
	
	if [[ "$BETA_BRANCH_ENABLED" == "0" ]]; then
		steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.buildid
		steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.timeupdated
	elif [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
		steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.buildid
		steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.timeupdated
	fi
	
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Received application info data." | tee -a "$LOG_SCRIPT"
	
	INSTALLED_BUILDID=$(cat $UPDATE_DIR/installed.buildid)
	AVAILABLE_BUILDID=$(cat $UPDATE_DIR/available.buildid)
	INSTALLED_TIME=$(cat $UPDATE_DIR/installed.timeupdated)
	AVAILABLE_TIME=$(cat $UPDATE_DIR/available.timeupdated)
	
	if [ "$AVAILABLE_TIME" -gt "$INSTALLED_TIME" ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) New update detected." | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Installed: BuildID: $INSTALLED_BUILDID, TimeUpdated: $INSTALLED_TIME" | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Available: BuildID: $AVAILABLE_BUILDID, TimeUpdated: $AVAILABLE_TIME" | tee -a "$LOG_SCRIPT"
		
		sleep 1
		
		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			WAS_ACTIVE="1"
			script_stop
		fi
		
		sleep 1
		
		if [[ "$TMPFS_ENABLE" == "1" ]]; then
			rm -rf $TMPFS_DIR/$WINE_PREFIX_GAME_DIR
		fi
		
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Updating..." | tee -a "$LOG_SCRIPT"
		
		if [[ "$BETA_BRANCH_ENABLED" == "0" ]]; then
			steamcmd +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +app_update $APPID validate +quit
		elif [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
			steamcmd +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +app_update $APPID -beta $BETA_BRANCH_NAME validate +quit
		fi
		
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Update completed." | tee -a "$LOG_SCRIPT"
		echo "$AVAILABLE_BUILDID" > $UPDATE_DIR/installed.buildid
		echo "$AVAILABLE_TIME" > $UPDATE_DIR/installed.timeupdated
		
		if [ "$WAS_ACTIVE" == "1" ]; then
			if [[ "$TMPFS_ENABLE" == "1" ]]; then
				mkdir -p $TMPFS_DIR/$WINE_PREFIX_GAME_DIR/Build
				mkdir -p $SRV_DIR/$WINE_PREFIX_GAME_DIR/Build
			elif [[ "$TMPFS_ENABLE" == "0" ]]; then
				mkdir -p $SRV_DIR/$WINE_PREFIX_GAME_DIR/Build
			fi
			sleep 1
			SCRIPT_ENABLED="1"
			script_start
		fi
		
		if [[ "$EMAIL_UPDATE" == "1" ]]; then
			mail -r "$EMAIL_SENDER ($NAME-$USER)" -s "Notification: Update" $EMAIL_RECIPIENT <<- EOF
			Server was updated. Please check the update notes if there are any additional steps to take.
			EOF
		fi
		
	elif [ "$AVAILABLE_TIME" -eq "$INSTALLED_TIME" ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) No new updates detected." | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Installed: BuildID: $INSTALLED_BUILDID, TimeUpdated: $INSTALLED_TIME" | tee -a "$LOG_SCRIPT"
	fi
}

#Install aliases in .bashrc
script_install_alias(){
	if [ "$EUID" -ne "0" ]; then #Check if script executed as root and asign the username for the installation process, otherwise use the executing user
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Install .bashrc aliases) Installation of aliases in .bashrc commencing. Waiting on user configuration." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to reinstall the tmux configuration? (y/n): " INSTALL_BASHRC_ALIAS
		if [[ "$INSTALL_BASHRC_ALIAS" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			INSTALL_BASHRC_ALIAS_STATE="1"
		elif [[ "$INSTALL_BASHRC_ALIAS" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Install .bashrc aliases) Installation of aliases in .bashrc aborted." | tee -a "$LOG_SCRIPT"
			INSTALL_BASHRC_ALIAS_STATE="0"
		fi
	else
		INSTALL_BASHRC_ALIAS_STATE="1"
	fi
	
	if [[ "$INSTALL_BASHRC_ALIAS_STATE" == "1" ]]; then
		cat >> /home/$USER/.bashrc <<- EOF
			alias $SERVICE_NAME-server='tmux -L $USER-tmux.sock attach -t $NAME'
		EOF
	fi
	
	if [ "$EUID" -ne "0" ]; then
		if [[ "$INSTALL_BASHRC_ALIAS_STATE" == "1" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Install .bashrc aliases) Installation of aliases in .bashrc complete. Re-log for the changes to take effect." | tee -a "$LOG_SCRIPT"
			echo "Aliases:"
			echo "$SERVICE_NAME-server = Attaches to the server console."
		fi
	fi
}

#Install or reinstall tmux configuration
script_install_tmux_config() {
	if [ "$EUID" -ne "0" ]; then #Check if script executed as root and asign the username for the installation process, otherwise use the executing user
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall tmux configuration) Tmux configuration reinstallation commencing. Waiting on user configuration." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to reinstall the tmux configuration? (y/n): " REINSTALL_TMUX_CONFIG
		if [[ "$REINSTALL_TMUX_CONFIG" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			INSTALL_TMUX_CONFIG_STATE="1"
		elif [[ "$REINSTALL_TMUX_CONFIG" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall tmux configuration) Tmux configuration reinstallation aborted." | tee -a "$LOG_SCRIPT"
			INSTALL_TMUX_CONFIG_STATE="0"
		fi
	else
		INSTALL_TMUX_CONFIG_STATE="1"
	fi
	
	if [[ "$INSTALL_TMUX_CONFIG_STATE" == "1" ]]; then
		if [ -f "$SCRIPT_DIR/$SERVICE_NAME-tmux.conf" ]; then
			rm $SCRIPT_DIR/$SERVICE_NAME-tmux.conf
		fi
		
		cat > $SCRIPT_DIR/$SERVICE_NAME-tmux.conf <<- EOF
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
		bind-key r source-file $SCRIPT_DIR/$SERVICE_NAME-tmux.conf \; display-message "Config reloaded!"

		set-hook -g session-created 'resize-window -y 24 -x 10000'
		set-hook -g session-created "pipe-pane -o 'tee >> $LOG_TMP'"
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
	fi
	
	if [ "$EUID" -ne "0" ]; then
		if [[ "$INSTALL_TMUX_CONFIG_STATE" == "1" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall tmux configuration) Tmux configuration reinstallation complete. Restart your server for changes to take affect." | tee -a "$LOG_SCRIPT"
		fi
	fi
}

#Install or reinstall systemd services
script_install_services() {
	if [ "$EUID" -ne "0" ]; then #Check if script executed as root and asign the username for the installation process, otherwise use the executing user
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall systemd services) Systemd services reinstallation commencing. Waiting on user configuration." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to reinstall the systemd services? (y/n): " REINSTALL_SYSTEMD_SERVICES
		if [[ "$REINSTALL_SYSTEMD_SERVICES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			INSTALL_SYSTEMD_SERVICES_STATE="1"
		elif [[ "$REINSTALL_SYSTEMD_SERVICES" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall systemd services) Systemd services reinstallation aborted." | tee -a "$LOG_SCRIPT"
			INSTALL_SYSTEMD_SERVICES_STATE="0"
		fi
	else
		INSTALL_SYSTEMD_SERVICES_STATE="1"
	fi
	
	if [[ "$INSTALL_SYSTEMD_SERVICES_STATE" == "1" ]]; then		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-mkdir-tmpfs.service" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-mkdir-tmpfs.service
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-tmpfs.service" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-tmpfs.service
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME.service" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME.service
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.timer" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.timer
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.service" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.service
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.timer" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.timer
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.service" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.service
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-3.timer" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-3.timer
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-3.service" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-3.service
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-send-email.service" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-send-email.service
		fi
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-mkdir-tmpfs.service <<- EOF
		[Unit]
		Description=$NAME TmpFs dir creator
		After=mnt-tmpfs.mount
		
		[Service]
		Type=oneshot
		WorkingDirectory=/home/$USER/
		ExecStart=/bin/mkdir -p $TMPFS_DIR/$WINE_PREFIX_GAME_DIR/Build
		
		[Install]
		WantedBy=default.target
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-tmpfs.service <<- EOF
		[Unit]
		Description=$NAME TmpFs Server Service 
		After=network.target mnt-tmpfs.mount $SERVICE_NAME-mkdir-tmpfs.service
		Conflicts=$SERVICE_NAME.service
		StartLimitBurst=3
		StartLimitIntervalSec=300
		StartLimitAction=none
		OnFailure=$SERVICE_NAME-send-email.service
		
		[Service]
		Type=forking
		WorkingDirectory=$TMPFS_DIR/$WINE_PREFIX_GAME_DIR
		ExecStartPre=/usr/bin/rsync -av --info=progress2 $SRV_DIR/ $TMPFS_DIR
		ExecStart=/usr/bin/tmux -f $SCRIPT_DIR/$SERVICE_NAME-tmux.conf -L %u-tmux.sock new-session -d -s $NAME 'env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$TMPFS_DIR wineconsole --backend=curses $TMPFS_DIR/$WINE_PREFIX_GAME_DIR/$WINE_PREFIX_GAME_EXE'
		ExecStop=/usr/bin/tmux -f $SCRIPT_DIR/$SERVICE_NAME-tmux.conf -L %u-tmux.sock new-session -d -s $NAME-stop 'env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$TMPFS_DIR wineconsole --backend=curses $TMPFS_DIR/$WINE_PREFIX_GAME_DIR/$WINE_PREFIX_GAME_EXE -shutdown'
		ExecStop=/usr/bin/sleep 20
		ExecStop=/usr/bin/env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$TMPFS_DIR /usr/bin/wineserver -k
		ExecStop=/usr/bin/sleep 10
		ExecStop=/usr/bin/rsync -av --info=progress2 $TMPFS_DIR/ $SRV_DIR
		ExecStop=/usr/bin/rm $LOG_TMP
		TimeoutStartSec=infinity
		TimeoutStopSec=120
		RestartSec=10
		Restart=on-failure
		
		[Install]
		WantedBy=default.target
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME.service <<- EOF
		[Unit]
		Description=$NAME Server Service
		After=network.target
		Conflicts=$SERVICE_NAME-tmpfs.service
		StartLimitBurst=3
		StartLimitIntervalSec=300
		StartLimitAction=none
		OnFailure=$SERVICE_NAME-send-email.service
		
		[Service]
		Type=forking
		WorkingDirectory=$SRV_DIR/$WINE_PREFIX_GAME_DIR
		ExecStart=/usr/bin/tmux -f $SCRIPT_DIR/$SERVICE_NAME-tmux.conf -L %u-tmux.sock new-session -d -s $NAME env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR wineconsole --backend=curses $SRV_DIR/$WINE_PREFIX_GAME_DIR/$WINE_PREFIX_GAME_EXE
		ExecStop=/usr/bin/tmux -f $SCRIPT_DIR/$SERVICE_NAME-tmux.conf -L %u-tmux.sock new-session -d -s $NAME-stop env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR wineconsole --backend=curses $SRV_DIR/$WINE_PREFIX_GAME_DIR/$WINE_PREFIX_GAME_EXE -shutdown
		ExecStop=/usr/bin/sleep 20
		ExecStop=/usr/bin/env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR /usr/bin/wineserver -k
		ExecStop=/usr/bin/sleep 10
		ExecStop=/usr/bin/rm $LOG_TMP
		TimeoutStartSec=infinity
		TimeoutStopSec=120
		RestartSec=10
		Restart=on-failure
		
		[Install]
		WantedBy=default.target
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.timer <<- EOF
		[Unit]
		Description=$NAME Script Timer 1
		
		[Timer]
		OnCalendar=*-*-* 00:00:00
		OnCalendar=*-*-* 06:00:00
		OnCalendar=*-*-* 12:00:00
		OnCalendar=*-*-* 18:00:00
		Persistent=true
		
		[Install]
		WantedBy=timers.target
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.service <<- EOF
		[Unit]
		Description=$NAME Script Timer 1 Service
		
		[Service]
		Type=oneshot
		ExecStart=$SCRIPT_DIR/$SCRIPT_NAME -timer_one
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.timer <<- EOF
		[Unit]
		Description=$NAME Script Timer 2
		
		[Timer]
		OnCalendar=*-*-* *:15:00
		OnCalendar=*-*-* *:30:00
		OnCalendar=*-*-* *:45:00
		OnCalendar=*-*-* 01:00:00
		OnCalendar=*-*-* 02:00:00
		OnCalendar=*-*-* 03:00:00
		OnCalendar=*-*-* 04:00:00
		OnCalendar=*-*-* 05:00:00
		OnCalendar=*-*-* 07:00:00
		OnCalendar=*-*-* 08:00:00
		OnCalendar=*-*-* 09:00:00
		OnCalendar=*-*-* 10:00:00
		OnCalendar=*-*-* 11:00:00
		OnCalendar=*-*-* 13:00:00
		OnCalendar=*-*-* 14:00:00
		OnCalendar=*-*-* 15:00:00
		OnCalendar=*-*-* 16:00:00
		OnCalendar=*-*-* 17:00:00
		OnCalendar=*-*-* 19:00:00
		OnCalendar=*-*-* 20:00:00
		OnCalendar=*-*-* 21:00:00
		OnCalendar=*-*-* 22:00:00
		OnCalendar=*-*-* 23:00:00
		Persistent=true
		
		[Install]
		WantedBy=timers.target
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.service <<- EOF
		[Unit]
		Description=$NAME Script Timer 2 Service
		
		[Service]
		Type=oneshot
		ExecStart=$SCRIPT_DIR/$SCRIPT_NAME -timer_two
		EOF
			
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-3.timer <<- EOF
		[Unit]
		Description=$NAME Script Timer 3 (Auto update script from github)
		
		[Timer]
		OnCalendar=*-*-* 23:55:00
		Persistent=true
		
		[Install]
		WantedBy=timers.target
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-3.service <<- EOF
		[Unit]
		Description=$NAME Script Timer 3 Service (Auto update script from github)
		
		[Service]
		Type=oneshot
		ExecStart=$SCRIPT_DIR/$SERVICE_NAME-update.bash -update
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-send-email.service <<- EOF
		[Unit]
		Description=$NAME Script Send Email notification Service
		
		[Service]
		Type=oneshot
		ExecStart=$SCRIPT_DIR/$SCRIPT_NAME -send_crash_email
		EOF
	fi
	
	if [ "$EUID" -ne "0" ]; then
		if [[ "$INSTALL_SYSTEMD_SERVICES_STATE" == "1" ]]; then
			systemctl --user daemon-reload
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall systemd services) Systemd services reinstallation complete." | tee -a "$LOG_SCRIPT"
		fi
	fi
}

#Reinstalls the wine prefix
script_install_prefix() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall Wine prefix) Wine prefix reinstallation commencing. Waiting on user configuration." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to reinstall the wine prefix? (y/n): " REINSTALL_PREFIX
		if [[ "$REINSTALL_PREFIX" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			#If there is not a backup folder for today, create one
			if [ ! -d "$BCKP_DEST" ]; then
				mkdir -p $BCKP_DEST
			fi
			read -p "Do you want to keep the game installation and server data (saves,configs,etc.)? (y/n): " REINSTALL_PREFIX_KEEP_DATA
			if [[ "$REINSTALL_PREFIX_KEEP_DATA" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				mkdir -p $BCKP_DIR/prefix_backup/game
				mv "$SRV_DIR/$WINE_PREFIX_GAME_DIR"/* $BCKP_DIR/prefix_backup/game
			fi
			rm -rf $SRV_DIR
			Xvfb :5 -screen 0 1024x768x16 &
			env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEDLLOVERRIDES="mscoree=d" WINEPREFIX=$SRV_DIR wineboot --init /nogui
			env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR winetricks corefonts
			env DISPLAY=:5.0 WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR winetricks -q vcrun2012
			env DISPLAY=:5.0 WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR winetricks -q dotnet472
			pkill -f Xvfb
			if [[ "$REINSTALL_PREFIX_KEEP_DATA" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				mkdir -p "$SRV_DIR/$WINE_PREFIX_GAME_DIR"
				mv $BCKP_DIR/prefix_backup/game/* "$SRV_DIR/$WINE_PREFIX_GAME_DIR"
				rm -rf $BCKP_DIR/prefix_backup
			fi
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall Wine prefix) Wine prefix reinstallation complete." | tee -a "$LOG_SCRIPT"
		elif [[ "$REINSTALL_PREFIX" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall Wine prefix) Wine prefix reinstallation aborted." | tee -a "$LOG_SCRIPT"
		fi
	else
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall Wine prefix) Cannot reinstall wine prefix while server is running. Aborting..." | tee -a "$LOG_SCRIPT"
	fi
}

#Install or reinstall the update script
script_install_update_script() {
	if [ "$EUID" -ne "0" ]; then #Check if script executed as root and asign the username for the installation process, otherwise use the executing user
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall update script) Systemd services reinstallation commencing. Waiting on user configuration." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to reinstall the update script? (y/n): " REINSTALL_UPDATE_SCRIPT
		if [[ "$REINSTALL_UPDATE_SCRIPT" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			INSTALL_UPDATE_SCRIPT_STATE="1"
		elif [[ "$REINSTALL_UPDATE_SCRIPT" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall update script) Systemd services reinstallation aborted." | tee -a "$LOG_SCRIPT"
			INSTALL_UPDATE_SCRIPT_STATE="0"
		fi
	else
		INSTALL_UPDATE_SCRIPT_STATE="1"
	fi
	
	if [[ "$INSTALL_UPDATE_SCRIPT_STATE" == "1" ]]; then
		if [ -f "$SCRIPT_DIR/$SERVICE_NAME-update.bash" ]; then
			rm $SCRIPT_DIR/$SERVICE_NAME-update.bash
		fi
		
		echo '#!/bin/bash' > $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo 'NAME=$(cat '"$SCRIPT_DIR/$SCRIPT_NAME"' | grep -m 1 NAME | cut -d \" -f2)' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo 'SERVICE_NAME=$(cat '"$SCRIPT_DIR/$SCRIPT_NAME"' | grep -m 1 SERVICE_NAME | cut -d \" -f2)' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo 'LOG_DIR="/home/'"$USER"'/logs/$(date +"%Y")/$(date +"%m")/$(date +"%d")"' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo 'LOG_SCRIPT="$LOG_DIR/$SERVICE_NAME-script.log" #Script log' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo 'script_update() {' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	git clone https://github.com/7thCore/'"$SERVICE_NAME"'-script /tmp/'"$SERVICE_NAME"'-script' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	INSTALLED=$(cat '"$SCRIPT_DIR/$SCRIPT_NAME"' | grep -m 1 VERSION | cut -d \" -f2)' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	AVAILABLE=$(cat /tmp/'"$SERVICE_NAME"'-script/'"$SERVICE_NAME"'-script.bash | grep -m 1 VERSION | cut -d \" -f2)' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	if [ "$AVAILABLE" -gt "$INSTALLED" ]; then' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		echo "$(date +"%Y-%m-%d %H:%M:%S") [$INSTALLED] [$NAME] [INFO] (Script update) Script update detected." | tee -a $LOG_SCRIPT' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		echo "$(date +"%Y-%m-%d %H:%M:%S") [$INSTALLED] [$NAME] [INFO] (Script update) Installed:$INSTALLED, Available:$AVAILABLE" | tee -a $LOG_SCRIPT' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		rm /home/'"$USER"'/scripts/'"$SERVICE_NAME"'-script.bash' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		cp /tmp/'"$SERVICE_NAME"'-script/'"$SERVICE_NAME"'-script.bash /home/'"$USER"'/scripts/'"$SERVICE_NAME"'-script.bash' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		chmod +x /home/'"$USER"'/scripts/'"$SERVICE_NAME"'-script.bash' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo ''  >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		INSTALLED=$(cat '"$SCRIPT_DIR/$SCRIPT_NAME"' | grep -m 1 VERSION | cut -d \" -f2)' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		AVAILABLE=$(cat /tmp/'"$SERVICE_NAME"'-script/'"$SERVICE_NAME"'-script.bash | grep -m 1 VERSION | cut -d \" -f2)' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		if [ "$AVAILABLE" -eq "$INSTALLED" ]; then' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '			echo "$(date +"%Y-%m-%d %H:%M:%S") [$INSTALLED] [$NAME] [INFO] (Script update) Script update complete." | tee -a $LOG_SCRIPT' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		else' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '			echo "$(date +"%Y-%m-%d %H:%M:%S") [$INSTALLED] [$NAME] [INFO] (Script update) Script update failed." | tee -a $LOG_SCRIPT' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		fi' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	else' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		echo "$(date +"%Y-%m-%d %H:%M:%S") [$INSTALLED] [$NAME] [INFO] (Script update) No new script updates detected." | tee -a $LOG_SCRIPT' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		echo "$(date +"%Y-%m-%d %H:%M:%S") [$INSTALLED] [$NAME] [INFO] (Script update) Installed:$INSTALLED, Available:$AVAILABLE" | tee -a $LOG_SCRIPT' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	fi' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	rm -rf /tmp/'"$SERVICE_NAME"'-script' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo "}" >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo 'script_update_force() {' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	git clone https://github.com/7thCore/'"$SERVICE_NAME"'-script /tmp/'"$SERVICE_NAME"'-script' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	rm /home/'"$USER"'/scripts/'"$SERVICE_NAME"'-script.bash' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	cp /tmp/'"$SERVICE_NAME"'-script/'"$SERVICE_NAME"'-script.bash /home/'"$USER"'/scripts/'"$SERVICE_NAME"'-script.bash' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	chmod +x /home/'"$USER"'/scripts/'"$SERVICE_NAME"'-script.bash' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	rm -rf /tmp/'"$SERVICE_NAME"'-script' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo "}" >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo 'case "$1" in' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	-help)' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		echo -e "${CYAN}Time: $(date +"%Y-%m-%d %H:%M:%S") ${NC}"' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		echo -e "${CYAN}$NAME server script by 7thCore${NC}"' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		echo ""' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		echo -e "${LIGHTRED}The script updates the primary server script from github.${NC}"' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		echo ""' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		echo -e "${GREEN}update ${RED}- ${GREEN}Check for script updates and update if available${NC}"' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		echo -e "${GREEN}force_update ${RED}- ${GREEN}Download latest script version and install it no matter if the installed script is the same version${NC}"' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		;;' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	-update)' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		script_update' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		;;' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	-force_update)' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		script_force_update' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '		;;' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	*)' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	echo -e "${CYAN}Time: $(date +"%Y-%m-%d %H:%M:%S") ${NC}"' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	echo -e "${CYAN}$NAME update script for server script by 7thCore${NC}"' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	echo ""' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	echo "For more detailed information, execute the script with the -help argument"' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	echo ""' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	echo "Usage: $0 {update|force_update}"' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	exit 1' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo '	;;' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		echo 'esac' >> $SCRIPT_DIR/$SERVICE_NAME-update.bash
		
		chmod +x $SCRIPT_DIR/$SERVICE_NAME-update.bash
		if [ "$EUID" -ne "0" ]; then
			if [[ "$INSTALL_UPDATE_SCRIPT_STATE" == "1" ]]; then
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall update script) Update script reinstallation complete." | tee -a "$LOG_SCRIPT"
			fi
		fi
	fi
}

#First timer function for systemd timers to execute parts of the script in order without interfering with each other
script_timer_one() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server running." | tee -a "$LOG_SCRIPT"
		script_enabled
		script_logs
		script_deloldsavefiles
		script_sync
		script_autobackup
		script_update
	fi
}

#Second timer function for systemd timers to execute parts of the script in order without interfering with each other
script_timer_two() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server running." | tee -a "$LOG_SCRIPT"
		script_enabled
		script_logs
		script_deloldsavefiles
		script_sync
		script_update
	fi
}

script_install_packages() {
	if [ -f "/etc/os-release" ]; then
		#Get distro name
		DISTRO=$(cat /etc/os-release | grep "^ID" | cut -d = -f2)
		
		#Check for current distro
		if [[ "$DISTRO" == "arch" ]]; then
			#Arch distro
			
			#Add arch linux multilib repository
			echo "[multilib]" >> /mnt/etc/pacman.conf
			echo "Include = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
			
			#Install packages and enable services
			sudo pacman -Syu --noconfirm wine-staging wine-mono wine_gecko libpulse libxml2 mpg123 lcms2 giflib libpng gnutls gst-plugins-base gst-plugins-good lib32-libpulse lib32-libxml2 lib32-mpg123 lib32-lcms2 lib32-giflib lib32-libpng lib32-gnutls lib32-gst-plugins-base lib32-gst-plugins-good rsync cabextract unzip p7zip wget curl samba xorg-server-xvfb tmux postfix zip
			sudo systemctl enable smb nmb winbind
			sudo systemctl start smb nmb winbind
		elif [[ "$DISTRO" == "ubuntu" ]]; then
			#Ubuntu distro
			
			#Get codename
			UBUNTU_CODENAME=$(cat /etc/os-release | grep "^UBUNTU_CODENAME" | cut -d = -f2)
			
			#Add wine repositroy and install packages
			sudo dpkg --add-architecture i386
			wget -nc https://dl.winehq.org/wine-builds/winehq.key
			sudo apt-key add winehq.key
			sudo apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ $UBUNTU_CODENAME main"
			
			#Install packages and enable services
			sudo apt install --install-recommends winehq-staging
			sudo apt install --install-recommends steamcmd
			sudo apt install rsync cabextract unzip p7zip wget curl xvfb screen zip postfix samba winbind tmux
			sudo systemctl enable smbd nmbd winbind
			sudo systemctl start smbd nmbd winbind
		fi
			
		#Install winetricks
		wget https://raw.githubusercontent.com/Kreytricks/kreytricks/349c0afcc0b450799a812f2f8a3eb8a562465c77/src/winetricks
		sudo mv winetricks /usr/local/bin/
		sudo chmod +x /usr/local/bin/winetricks
		if [[ "$DISTRO" == "arch" ]]; then
			echo "Arch Linux users have to install SteamCMD with an AUR tool."
		fi
		echo "Package installation complete."
	else
		echo "os-release file not found. Is this distro supported?"
		echo "This script currently supports Arch Linux and Ubuntu 19.10"
		exit 1
	fi

}

script_install() {
	echo "Installation"
	echo ""
	echo "Required packages that need to be installed on the server:"
	echo "xvfb"
	echo "rsync"
	echo "wine"
	echo "winetricks"
	echo "tmux"
	echo "steamcmd"
	echo "postfix (optional/for the email feature)"
	echo "zip (optional but required if using the email feature)"
	echo ""
	echo "If these packages aren't installed, terminate this script with CTRL+C and install them."
	echo "The script will ask you for your steam username and password and will store it in a configuration file for automatic updates."
	echo "In the middle of the installation process you will be asked for a steam guard code. Also make sure your steam guard"
	echo "is set to email only (don't use the mobile app and don't use no second authentication. USE STEAM GUARD VIA EMAIL!"
	echo ""
	echo "The installation will enable linger for the user specified (allows user services to be ran on boot)."
	echo "It will also enable the services needed to run the game server by your specifications."
	echo ""
	echo "List of files that are going to be generated on the system:"
	echo ""
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-mkdir-tmpfs.service - Service to generate the folder structure once the RamDisk is started (only executes if RamDisk enabled)."
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-tmpfs.service - Server service file for use with a RamDisk (only executes if RamDisk enabled)."
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME.service - Server service file for normal hdd/ssd use."
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.timer - Timer for scheduled command execution of $SERVICE_NAME-timer-1.service"
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.service - Executes scheduled script functions: autorestart, save, sync, backup and update."
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.timer - Timer for scheduled command execution of $SERVICE_NAME-timer-2.service"
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.service - Executes scheduled script functions: autorestart, save, sync and update."
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-3.timer - Timer for scheduled command execution of $SERVICE_NAME-timer-3.service"
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-3.service - Executes scheduled update checks for this script"
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-send-email.service - If email notifications enabled, send email if server crashed 3 times in 5 minutes."
	echo "$SCRIPT_DIR/$SERVICE_NAME-script.bash - This script."
	echo "$SCRIPT_DIR/$SERVICE_NAME-update.bash - Update script for automatic updates from github."
	echo "$SCRIPT_DIR/$SERVICE_NAME-config.conf - Stores steam username and password. Also stores tmpfs/ramdisk setting."
	echo "$SCRIPT_DIR/$SERVICE_NAME-tmux.conf - Screen configuration to enable logging."
	echo "$UPDATE_DIR/installed.buildid - Information on installed buildid (AppInfo from Steamcmd)"
	echo "$UPDATE_DIR/available.buildid - Information on available buildid (AppInfo from Steamcmd)"
	echo "$UPDATE_DIR/installed.timeupdated - Information on time the server was last updated (AppInfo from Steamcmd)"
	echo "$UPDATE_DIR/available.timeupdated - Information on time the server was last updated (AppInfo from Steamcmd)"
	echo ""
	read -p "Press any key to continue" -n 1 -s -r
	echo ""
	read -p "Enter password for user $USER: " USER_PASS
	echo ""
	read -p "Enable RamDisk (y/n): " TMPFS
	echo ""
	
	sudo useradd -m -g users -s /bin/bash $USER
	echo -en "$USER_PASS\n$USER_PASS\n" | sudo passwd $USER
	
	if [[ "$TMPFS" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		TMPFS_ENABLE="1"
		read -p "Do you already have a ramdisk mounted at /mnt/tmpfs? (y/n): " TMPFS_PRESENT
		if [[ "$TMPFS_PRESENT" =~ ^([nN][oO]|[nN])$ ]]; then
			read -p "Ramdisk size (Minimum of 6G for a single server, 12G for two and so on): " TMPFS_SIZE
			echo "Installing ramdisk configuration"
			cat >> /etc/fstab <<- EOF
			
			# /mnt/tmpfs
			tmpfs				   /mnt/tmpfs		tmpfs		   rw,size=$TMPFS_SIZE,gid=$(cat /etc/group | grep users | grep -o '[[:digit:]]*'),mode=0777	0 0
			EOF
		fi
	fi
	
	echo ""
	read -p "Enable beta branch? Used for experimental and legacy versions. (y/n): " SET_BETA_BRANCH_STATE
	echo ""
	
	if [[ "$SET_BETA_BRANCH_STATE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		BETA_BRANCH_ENABLED="1"
		echo "Look up beta branch names at https://steamdb.info/app/$APPID/depots/"
		echo "Name example: experimental"
		read -p "Enter beta branch name: " BETA_BRANCH_NAME
	elif [[ "$SET_BETA_BRANCH_STATE" =~ ^([nN][oO]|[nN])$ ]]; then
		BETA_BRANCH_ENABLED="0"
		BETA_BRANCH_NAME="none"
	fi
	
	echo ""
	read -p "Enable email notifications (y/n): " POSTFIX_ENABLE
	if [[ "$POSTFIX_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo ""
		read -p "Enter the relay host (example: smtp.gmail.com): " POSTFIX_RELAY_HOST
		echo ""
		read -p "Enter the relay host port (example: 587): " POSTFIX_RELAY_HOST_PORT
		echo ""
		read -p "Enter your email address for the server (example: example@gmail.com): " POSTFIX_SENDER
		echo ""
		read -p "Enter your password for $POSTFIX_SENDER : " POSTFIX_SENDER_PSW
		echo ""
		read -p "Enter the email that will recieve the notifications (example: example2@gmail.com): " POSTFIX_RECIPIENT
		echo ""
		read -p "Email notifications for game updates? (y/n): " POSTFIX_UPDATE_ENABLE
			if [[ "$POSTFIX_UPDATE_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				POSTFIX_UPDATE="1"
			fi
		echo ""
		read -p "Email notifications for crashes? (y/n): " POSTFIX_CRASH_ENABLE
			if [[ "$POSTFIX_CRASH_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				POSTFIX_CRASH="1"
			fi
		cat >> /etc/postfix/main.cf <<- EOF
		relayhost = [$POSTFIX_RELAY_HOST]:$POSTFIX_RELAY_HOST_PORT
		smtp_sasl_auth_enable = yes
		smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
		smtp_sasl_security_options = noanonymous
		smtp_tls_CApath = /etc/ssl/certs
		smtpd_tls_CApath = /etc/ssl/certs
		smtp_use_tls = yes
		EOF

		cat > /etc/postfix/sasl_passwd <<- EOF
		[$POSTFIX_RELAY_HOST]:$POSTFIX_RELAY_HOST_PORT    $POSTFIX_SENDER:$POSTFIX_SENDER_PSW
		EOF
	
		sudo chmod 400 /etc/postfix/sasl_passwd
		sudo postmap /etc/postfix/sasl_passwd
		sudo systemctl enable postfix
	elif [[ "$POSTFIX_ENABLE" =~ ^([nN][oO]|[nN])$ ]]; then
		POSTFIX_SENDER="none"
		POSTFIX_RECIPIENT="none"
		POSTFIX_SSK="0"
		POSTFIX_UPDATE="0"
		POSTFIX_CRASH="0"
	fi
	
	echo "Enabling linger"
	sudo mkdir -p /var/lib/systemd/linger/
	sudo touch /var/lib/systemd/linger/$USER
	sudo mkdir -p /home/$USER/.config/systemd/user
	
	echo "Installing bash profile"
	cat > /home/$USER/.bash_profile <<- 'EOF'
	#
	# ~/.bash_profile
	#
	
	[[ -f ~/.bashrc ]] && . ~/.bashrc
	
	export XDG_RUNTIME_DIR="/run/user/$UID"
	export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
	EOF
	
	sudo chown $USER:users /home/$USER/.bash_profile
	
	echo "Installing service files"
	script_install_services
	
	sudo chown -R $USER:users /home/$USER/.config/systemd/user
	
	echo "Enabling services"
		
	sudo systemctl start user@$(id -u $USER).service
	
	su - $USER -c "systemctl --user enable $SERVICE_NAME-timer-1.timer"
	su - $USER -c "systemctl --user enable $SERVICE_NAME-timer-2.timer"
	
	if [[ "$SCRIPT_UPDATE_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		su - $USER -c "systemctl --user enable $SERVICE_NAME-timer-3.timer"
	fi
	
	if [[ "$TMPFS" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		su - $USER -c "systemctl --user enable $SERVICE_NAME-mkdir-tmpfs.service"
		su - $USER -c "systemctl --user enable $SERVICE_NAME-tmpfs.service"
	elif [[ "$TMPFS" =~ ^([nN][oO]|[nN])$ ]]; then
		su - $USER -c "systemctl --user enable $SERVICE_NAME.service"
	fi
	
	echo "Creating folder structure for server..."
	mkdir -p /home/$USER/{backups,logs,scripts,server,updates}
	cp "$(readlink -f $0)" $SCRIPT_DIR
	chmod +x $SCRIPT_DIR/$SCRIPT_NAME
	
	echo "Installing tmux configuration for server console and logs"
	script_install_tmux_config
	
	echo "Installing update script"
	script_install_update_script
	
	touch $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'tmpfs_enable='"$TMPFS_ENABLE" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'beta_branch_enabled='"$BETA_BRANCH_ENABLED" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'beta_branch_name='"$BETA_BRANCH_NAME" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_sender='"$POSTFIX_SENDER" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_recipient='"$POSTFIX_RECIPIENT" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_update='"$POSTFIX_UPDATE" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_crash='"$POSTFIX_CRASH" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'save_delold=10' >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'bckp_delold=14' >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'log_delold=7' >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	
	
	sudo chown -R $USER:users /home/$USER/{backups,logs,scripts,server,updates}
	
	echo "Generating wine prefix"
	
	su - $USER <<- EOF
	Xvfb :5 -screen 0 1024x768x16 &
	env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEDLLOVERRIDES="mscoree=d" WINEPREFIX=$SRV_DIR wineboot --init /nogui
	env WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR winetricks corefonts
	env DISPLAY=:5.0 WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR winetricks -q vcrun2012
	env DISPLAY=:5.0 WINEARCH=$WINE_ARCH WINEDEBUG=-all WINEPREFIX=$SRV_DIR winetricks -q dotnet472
	pkill -f Xvfb
	EOF
	
	echo "Updating and logging in to Steam..."
	
	su - $USER -c "steamcmd +login anonymous +quit"
	
	echo "Installing game..."
	
	if [[ "$BETA_BRANCH_ENABLED" == "0" ]]; then
		su - $USER <<- EOF
		steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/installed.buildid
		EOF
	
		su - $USER <<- EOF
		steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/installed.timeupdated
		EOF
		
		su - $USER -c "steamcmd +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +app_update $APPID validate +quit"
	elif [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
		su - $USER <<- EOF
		steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/installed.buildid
		EOF
	
		su - $USER <<- EOF
		steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/installed.timeupdated
		EOF
		
		su - $USER -c "steamcmd +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +app_update $APPID -beta $BETA_BRANCH_NAME validate +quit"
	fi
	
	mkdir -p $BCKP_SRC_DIR
	chown -R $USER:users $BCKP_SRC_DIR
	
	
	echo "Installation complete"
	echo ""
	echo "You can login to your the $USER account with <sudo -i -u $USER> from your primary account or root account."
	echo "The script was automaticly copied to the scripts folder located at $SCRIPT_DIR"
	echo "For any settings you'll want to change, edit the $SCRIPT_DIR/$SERVICE_NAME-config.conf file."
	echo ""
}

#Do not allow for another instance of this script to run to prevent data loss
if [[ $(pidof -o %PPID -x $0) -gt "0" ]]; then
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$NAME] [INFO] Another instance of this script is already running. Exiting to prevent data loss."
	exit 0
fi

case "$1" in
	-help)
		echo -e "${CYAN}Time: $(date +"%Y-%m-%d %H:%M:%S") ${NC}"
		echo -e "${CYAN}$NAME server script by 7thCore${NC}"
		echo "Version: $VERSION"
		echo ""
		echo -e "${GREEN}start ${RED}- ${GREEN}Start the server${NC}"
		echo -e "${GREEN}stop ${RED}- ${GREEN}Stop the server${NC}"
		echo -e "${GREEN}restart ${RED}- ${GREEN}Restart the server${NC}"
		echo -e "${GREEN}sync ${RED}- ${GREEN}Sync from tmpfs to hdd/ssd${NC}"
		echo -e "${GREEN}backup ${RED}- ${GREEN}Backup files, if server running or not.${NC}"
		echo -e "${GREEN}autobackup ${RED}- ${GREEN}Automaticly backup files when server running${NC}"
		echo -e "${GREEN}deloldbackup ${RED}- ${GREEN}Delete old backups${NC}"
		echo -e "${GREEN}delete_save ${RED}- ${GREEN}Delete the server's save game with the option for deleting/keeping the server.json and SSK.txt files.${NC}"
		echo -e "${GREEN}deloldsavefiles ${RED}- ${GREEN}Delete the server's save game (leaves the latest number files specefied in the script conf file.${NC}"
		echo -e "${GREEN}change_branch ${RED}- ${GREEN}Changes the game branch in use by the server (public,experimental,legacy and so on).${NC}"
		echo -e "${GREEN}install_aliases ${RED}- ${GREEN}Installs .bashrc aliases for easy access to the server tmux session.${NC}"
		echo -e "${GREEN}rebuild_tmux_config ${RED}- ${GREEN}Reinstalls the tmux configuration file from the script. Usefull if any tmux configuration updates occoured.${NC}"
		echo -e "${GREEN}rebuild_services ${RED}- ${GREEN}Reinstalls the systemd services from the script. Usefull if any service updates occoured.${NC}"
		echo -e "${GREEN}rebuild_prefix ${RED}- ${GREEN}Reinstalls the wine prefix. Usefull if any wine prefix updates occoured.${NC}"
		echo -e "${GREEN}rebuild_update_script ${RED}- ${GREEN}Reinstalls the update script that keeps the primary script up-to-date from github.${NC}"
		echo -e "${GREEN}update ${RED}- ${GREEN}Update the server, if the server is running it wil save it, shut it down, update it and restart it.${NC}"
		echo -e "${GREEN}status ${RED}- ${GREEN}Display status of server${NC}"
		echo -e "${GREEN}install ${RED}- ${GREEN}Installs all the needed files for the script to run, the wine prefix and the game.${NC}"
		echo -e "${GREEN}install_packages ${RED}- ${GREEN}Installs all the needed packages (Supports only Arch linux & Ubuntu 19.10 and onward)"
		echo ""
		echo -e "${LIGHTRED}If this is your first time running the script:${NC}"
		echo -e "${LIGHTRED}Use the -install argument (run only this command as root) and follow the instructions${NC}"
		echo ""
		echo -e "${LIGHTRED}Example usage: ./$SCRIPT_NAME -start${NC}"
		echo ""
		echo -e "${CYAN}Have a nice day!${NC}"
		echo ""
		;;
	-start)
		script_start
		;;
	-stop)
		script_stop
		;;
	-restart)
		script_restart
		;;
	-sync)
		script_sync
		;;
	-backup)
		script_backup
		;;
	-autobackup)
		script_autobackup
		;;
	-deloldbackup)
		script_deloldbackup
		;;
	-deloldsavefiles)
		script_deloldsavefiles
		;;
	-update)
		script_update
		;;
	-status)
		script_status
		;;
	-install_packages)
		script_install_packages
		;;
	-install)
		script_install
		;;
	-delete_save)
		script_delete_save
		;;
	-change_branch)
		script_change_branch
		;;
	-send_crash_email)
		script_send_crash_email
		;;
	-install_aliases)
		script_install_alias
		;;
	-rebuild_tmux_config)
		script_install_tmux_config
		;;
	-rebuild_services)
		script_install_services
		;;
	-rebuild_prefix)
		script_install_prefix
		;;
	-rebuild_update_script)
		script_install_update_script
		;;
	-timer_one)
		script_timer_one
		;;
	-timer_two)
		script_timer_two
		;;
	*)
	echo -e "${CYAN}Time: $(date +"%Y-%m-%d %H:%M:%S") ${NC}"
	echo -e "${CYAN}$NAME server script by 7thCore${NC}"
	echo ""
	echo "For more detailed information, execute the script with the -help argument"
	echo ""
	echo "Usage: $0 {start|stop|restart|sync|backup|autobackup|deloldbackup|deloldsavefiles|delete_save|change_branch|install_aliases|rebuild_tmux_config|rebuild_services|rebuild_prefix|rebuild_update_script|update|status|install|install_packages}"
	exit 1
	;;
esac

exit 0
