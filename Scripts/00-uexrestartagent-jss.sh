#!/bin/bash

##########################################################################################
##########################################################################################
# 
# Restart notification checks the plists in the ../UEX/logout2.0/ folder to notify & force a
# restart if required.
# 
# Name: restart-notification.sh
# Version Number: 3.0
# 
# Created Jan 18, 2016 by 
# David Ramirez (David.Ramirez@adidas-group.com)
#
# Updates January 23rd, 2017 by
# DR = David Ramirez (David.Ramirez@adidas-group.com) 
# 
# Copyright (c) 2017 the adidas Group
# All rights reserved.
##########################################################################################
########################################################################################## 

##########################################################################################
##								STATIC VARIABLES FOR CD DIALOGS							##
##########################################################################################

CD="/Library/Application Support/JAMF/UEX/resources/CocoaDialog.app/Contents/MacOS/CocoaDialog"

##########################################################################################


##########################################################################################
##							STATIC VARIABLES FOR JH DIALOGS								##
##########################################################################################

jhPath="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
title="adidas | Global IT"
heading=$name

icondir="/Library/Application Support/JAMF/UEX/resources/adidas_company_logo_BWr.png"
woappsIcon="/Library/Application Support/JAMF/UEX/resources/Self Service@2x.icns"
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

##########################################################################################
##			CALCULATIONS TO SEE IF A RESTART HAS OCCURRED SINCE BEING REQUIRED			##
##########################################################################################

lastReboot=`date -jf "%s" "$(sysctl kern.boottime | awk -F'[= |,]' '{print $6}')" "+%s"`
lastRebootFriendly=`date -r$lastReboot`

rundate=`date +%s`

plists=`ls /Library/Application\ Support/JAMF/UEX/restart_jss/ | grep ".plist"`

set -- "$plists" 
IFS=$'\n' ; declare -a plists=($*)  
unset IFS

for i in "${plists[@]}" ; do
	# Check all the plist in the folder for any required actions
	# if the user has already had a fresh restart then delete the plist
	# other wise the advise and schedule the logout.
	name=`/usr/libexec/PlistBuddy -c "print name" "/Library/Application Support/JAMF/UEX/restart_jss/$i"`
	packageName=`/usr/libexec/PlistBuddy -c "print packageName" "/Library/Application Support/JAMF/UEX/restart_jss/$i"`

	plistrunDate=`/usr/libexec/PlistBuddy -c "print runDate" "/Library/Application Support/JAMF/UEX/restart_jss/$i"`
	runDateFriendly=`date -r $plistrunDate`
	
# 	echo lastReboot is $lastReboot
# 	echo plistRunDate is $plistRunDate
	
	timeSinceReboot=`echo "${lastReboot} - ${plistrunDate}" | bc`
	
	#######################
	# Logging files setup #
	#######################
	logname=$(echo $packageName | sed 's/.\{4\}$//')
	logfilename="$logname".log
	resulttmp="$logname"_result.log
	logfilepath="$logdir""$logfilename"
	resultlogfilepath="$logdir""$resulttmp"
	
# 	echo timeSinceReboot is $timeSinceReboot
	if [[ $timeSinceReboot -gt 0 ]] || [ -z "$plistrunDate" ]  ; then
		# the computer has rebooted since $runDateFriendly
		#delete the plist
		sudo echo $(date)	$compname	:	 Deleting the restart plsit "$i" because the computer has rebooted since "$runDateFriendly" >> "$logfilepath"
		sudo rm "/Library/Application Support/JAMF/UEX/restart_jss/$i"
	else 
		# the computer has NOT rebooted since $runDateFriendly
		lastline=`awk 'END{print}' "$logfilepath"`
		if [[ "$lastline" != *"Prompting the user"* ]] ; then 
			sudo echo $(date)	$compname	:	 The computer has NOT rebooted since "$runDateFriendly" >> "$logfilepath"
			sudo echo $(date)	$compname	:	 Prompting the user that a restart is required. >> "$logfilepath"
		fi
		restart="true"
	fi
done

##########################################################################################

##########################################################################################
## 							Login Check Run if no on is logged in						##
##########################################################################################
# no login  RUN NOW
# (skip to install stage)
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`

##########################################################################################
##					Notification if there are scheduled restarts						##
##########################################################################################

sleep 15
otherJamfprocess=`ps aux | grep jamf | grep -v grep | grep -v launchDaemon | grep -v jamfAgent | grep -v uexrestartagent`
otherJamfprocess+=`ps aux | grep [Ss]plashBuddy`
if [[ "$restart" == "true" ]] ; then
	while [[ $otherJamfprocess != "" ]] ; do 
		sleep 15
		otherJamfprocess=`ps aux | grep jamf | grep -v grep | grep -v launchDaemon | grep -v jamfAgent | grep -v uexrestartagent`
		otherJamfprocess+=`ps aux | grep [Ss]plashBuddy`
	done
fi

# only run the restart command once all other jamf policies have completed
if [[ $otherJamfprocess == "" ]] ; then 
	if [[ "$restart" == "true" ]] ; then
		
		if [ $loggedInUser ] ; then
		# message
		notice='In order for the changes to complete you must restart your computer. Please save your work and click "Restart Now" within the allotted time. 
	
Your computer will be automatically restarted at the end of the countdown.'
	
		#notice
		restartclickbutton=`"$jhPath" -windowType hud -lockHUD -windowPostion lr -title "$title" -description "$notice" -icon "$icon" -timeout 3600 -countdown -alignCountdown center -button1 "Restart Now"`
	
			# force restart
# 			sudo shutdown -r now
			
			# Nicer restart (http://apple.stackexchange.com/questions/103571/using-the-terminal-command-to-shutdown-restart-and-sleep-my-mac)
			osascript -e 'tell app "System Events" to restart'
		else
			# force restart
			echo restart required
			
			# while no on eis logged in you can do a force shutdown
			sudo shutdown -r now
			# Nicer restart (http://apple.stackexchange.com/questions/103571/using-the-terminal-command-to-shutdown-restart-and-sleep-my-mac)
# 			osascript -e 'tell app "System Events" to restart'
		fi
	fi
fi

##########################################################################################

exit 0

##########################################################################################
##					CLEANUP IF THERE ARE NO MORE SCHEDULED RESTARTS						##
##########################################################################################

morerestart=`ls /Library/Application\ Support/JAMF/UEX/restart_jss/ | grep .plist`
# if [[ $morerestart = "" ]] ; then 
	# no more plists exits
	
	# stop the daemon from running so luanchd is clear
# 	sudo launchctl unload -w /Library/LaunchDaemons/com.adidas-group.UEX-restart2.0.plist  > /dev/null 2>&1
	# delete the daemon for clean up
# 	sudo rm /Library/LaunchDaemons/com.adidas-group.UEX-restart2.0.plist  > /dev/null 2>&1
# fi

##########################################################################################
##									Version History										##
##########################################################################################
# 
# 
# Jan 18, 2016 	v1.0	--DR--	Stage 1 Delivered
# Sep 5, 2016 	v2.0	--DR--	Logging added
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
