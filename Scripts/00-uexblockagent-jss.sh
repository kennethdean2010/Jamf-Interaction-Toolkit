#!/bin/bash

##########################################################################################
##########################################################################################
# 
# Block script runs through plists in ../UEX/block_jss/ to kill apps during installation. 
# It run through the list of apps checks to see if they are running and then kills them.
# 
# Name: Block-notification.sh
# Version Number: 3.0
# 
# Created Jan 18, 2016 by 
# David Ramirez (David.Ramirez@adidas-group.com)
#
# Updates January 23rd, 2016 by
# DR = David Ramirez (D avid.Ramirez@adidas-group.com) 
# 
# Copyright (c) 2017 the adidas Group
# All rights reserved.
##########################################################################################
########################################################################################## 

##########################################################################################
##								STATIC VARIABLES FOR CD DIALOGS							##
##########################################################################################

CD="/Library/Application Support/JAMF/UEX/resources/cocoaDialog.app/Contents/MacOS/cocoaDialog"

##########################################################################################


##########################################################################################
##							STATIC VARIABLES FOR JH DIALOGS								##
##########################################################################################

jhPath="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
title="adidas | Global IT"
heading=$name

icondir="/Library/Application Support/JAMF/UEX/resources/adidas_company_logo_BWr.png"
woappsIcon="/Library/Application Support/adidas/World of Apps/Self Service@2x.icns"
#if the icon file doesn't exist then set to a standard icon
if [[ -e "$woappsIcon" ]]; then
	icon="$woappsIcon"
elif [ -e "$icondir" ] ; then
	icon="$icondir"
else
	icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
fi

##########################################################################################

##########################################################################################
# 										LOGGING PREP									 #
##########################################################################################
# logname=$(echo $packageName | sed 's/.\{4\}$//')
# logfilename="$logname".log
logdir="/Library/Application Support/JAMF/UEX/UEX_Logs/"
# resulttmp="$logname"_result.log
##########################################################################################

##################################
# 		Reboot Detections		 #
##################################	



lastReboot=`date -jf "%s" "$(sysctl kern.boottime | awk -F'[= |,]' '{print $6}')" "+%s"`
lastRebootFriendly=`date -r$lastReboot`

rundate=`date +%s`

blockPlists=`ls /Library/Application\ Support/JAMF/UEX/block_jss/ | grep ".plist"`

set -- "$blockPlists"
IFS=$'\n' ; declare -a blockPlists=($*)  
unset IFS

##################################
# 		PLIST PROCESSING		 #
##################################

runBlocking=`ls /Library/Application\ Support/JAMF/UEX/block_jss/ | grep ".plist"`
	while [ "$runBlocking" ] ; do
	 
	runBlocking=`ls /Library/Application\ Support/JAMF/UEX/block_jss/ | grep ".plist"`
	blockPlists=`ls /Library/Application\ Support/JAMF/UEX/block_jss/ | grep ".plist"`
	
	set -- "$blockPlists"
	IFS=$'\n' ; declare -a blockPlists=($*)  
	unset IFS
	
	for i in "${blockPlists[@]}" ; do
	# Run through the plists and check for app blocking requirements
		name=`/usr/libexec/PlistBuddy -c "print name" "/Library/Application Support/JAMF/UEX/block_jss/$i"`
		packageName=`/usr/libexec/PlistBuddy -c "print packageName" "/Library/Application Support/JAMF/UEX/block_jss/$i"`
	
		runDate=`/usr/libexec/PlistBuddy -c "print runDate" "/Library/Application Support/JAMF/UEX/block_jss/$i"`
		runDateFriendly=`date -r$runDate`
		apps=`/usr/libexec/PlistBuddy -c "print apps2block" "/Library/Application Support/JAMF/UEX/block_jss/$i"`
		checks=`/usr/libexec/PlistBuddy -c "print checks" "/Library/Application Support/JAMF/UEX/block_jss/$i"`
		
		timeSinceReboot=$((lastReboot-runDate))
		
		##########################################################################################
		##									SETTING FOR ACTIONS									##
		##########################################################################################
		if [[ "$checks" == *"install"* ]] && [[ "$checks" != *"uninstall"* ]] ; then
			action="install"
			actioncap="Install"
			actioning="installing"
		elif [[ "$checks" == *"update"* ]] ; then
			action="update"
			actioncap="Update"
			actioning="updating"
		elif [[ "$checks" == *"uninstall"* ]] ; then
			action="uninstall"
			actioncap="Uninstall"
			actioning="uninstalling"
		else
			action="install"
			actioncap="Install"
			actioning="installing"
		fi
	
		##########################################################################################
		##									SETTING FOR DEBUG MODE								##
		##########################################################################################

		debugDIR="/Library/Application Support/JAMF/UEX/debug/"

		if [ -e "$debugDIR""$packageName" ] ; then 
			debug=true
		else
			debug=false
		fi
	
		##########################################################################################
	
	
		#######################
		# Logging files setup #
		#######################
		logname=$(echo $packageName | sed 's/.\{4\}$//')
		logfilename="$logname".log
		resulttmp="$logname"_result.log
		logfilepath="$logdir""$logfilename"
		resultlogfilepath="$logdir""$resulttmp"
	
		# Create array of apps to run through checks
		set -- "$apps" 
		IFS=";"; declare -a apps=($*)  
		unset IFS

		if [[ timeSinceReboot -gt 0 ]] ; then
			# the computer has rebooted since $runDateFriendly
			# Delete block requirement plist
			sudo rm /Library/Application\ Support/JAMF/UEX/block_jss/"$i"
		else 
			# the computer has NOT rebooted since $runDateFriendly
			# Process the apps in the plist and kill and notify
			for app in "${apps[@]}" ; do
				IFS=$'\n'
				appid=`ps aux | grep "$app"/Contents/MacOS/ | grep -v grep | grep -v PleaseWaitUpdater.sh | grep -v PleaseWait | grep -v sed | grep -v jamf | grep -v cocoaDialog | awk {'print $2'}`
	# 			echo Processing application $app
					if  [[ $appid != "" ]] ; then
						# app was running so kill it then give the notification
					
						################################
						# Debugging applications kills #
						################################
						processData=`ps aux | grep "$app"/Contents/MacOS/ | grep -v grep | grep -v PleaseWaitUpdater.sh | grep -v PleaseWait | grep -v sed | grep -v jamf | grep -v cocoaDialog `
						for process in $processData ; do
							if [ $debug = true ] ; then	sudo echo $(date)	$compname	:	-DEBUG-	 '*****' PROCESSS FOUND MATCHING CRITERIA '******' | /usr/bin/tee -a "$logfilepath" ; fi
							if [ $debug = true ] ; then	sudo echo $(date)	$compname	:	-DEBUG-	 "$process" | /usr/bin/tee -a "$logfilepath" ; fi
						done
						####################################
						# Debugging applications kills END #
						####################################
					
						for id in $appid; do
	# 						echo Killing $app. pid is $id 
							sudo echo $(date)	$compname	:	App "$app" was found running, killing process. pid is $id | /usr/bin/tee -a "$logfilepath"
							kill $id
						done 
#################
# MESSAGE START #
#################
appName=`echo $app | sed 's/.\{4\}$//'`

# Use cocoaDialog so that it appears in front 
"$CD" bubble \
--title "$actioncap in progress..." --x-placement center --y-placement center \
--text "The application ${appName} cannot be opened while the $action is still in progress.

Please wait for it to complete before attempting to open it." \
	--icon-file "$icon" --icon-size 64 --independent --timeout 30


# echo "/Library/Application Support/JAMF/UEX/scripts/cdforblock.sh" $name $app

#     sleep 1
###############
# MESSAGE END #
###############
	
					fi
				done
				unset IFS	
		fi
	done
done

##########################################################################################
##			CLEANUP IF THERE ARE NO MORE APPLICATIONS THAT NEED TO BE BLOCKED			##
##########################################################################################

# Plist get cleaned by Postinstall script in the PKG once the installation is complete 
# OR if the computer has restarted since the plist was created. 

# moreblock=`ls /Library/Application\ Support/JAMF/UEX/block_jss/ | grep .plist`
# if [[ $moreblock = "" ]] ; then 
# 	# no more plists
# 	
# 	# stop the daemon to clear launchd
# 	sudo launchctl unload -w /Library/LaunchDaemons/com.adidas-group.UEX-block2.0.plist  > /dev/null 2>&1
# 	# Delete the daemon for cleanup
# 	sudo rm /Library/LaunchDaemons/com.adidas-group.UEX-block2.0.plist  > /dev/null 2>&1
# fi


exit 0

##########################################################################################
##									Version History										##
##########################################################################################
# 
# 
# Jan 18, 2016 	v1.0	--DR--	Stage 1 Delivered
# Sep 1, 2016 	v2.0	--DR--	Logging added
# Sep 1, 2016 	v2.0	--DR--	Debug mode added
# Sep 7, 2016 	v2.0	--DR--	Updated to clean up Application quitting and only target process from /$app/Contents/MacOS/
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
