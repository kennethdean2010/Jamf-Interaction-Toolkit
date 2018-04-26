#!/bin/bash

##########################################################################################
##########################################################################################
# 
# Logout notification checks the plists in the ../UEX/logout_jss/ folder to notify & force a
# logout if required.
# 
# Name: logout-notification.sh
# Version Number: 3.0
# 
# Created Jan 18, 2016 by 
# David Ramirez (David.Ramirez@adidas-group.com)
#
# Updates January 23rd, 2017 by
# DR = David Ramirez (D avid.Ramirez@adidas-group.com) 
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

##########################################################################################
##								LOGIN AND PLIST PROCESSING								##
##########################################################################################

loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`

lastLogin=`syslog -F raw -k Facility com.apple.system.lastlog | grep $loggedInUser | grep -v tty | awk 'END{print}' | awk '{ print $4 }' | sed -e 's/]//g'`
lastLoginFriendly=`date -r$lastLogin`

lastReboot=`date -jf "%s" "$(sysctl kern.boottime | awk -F'[= |,]' '{print $6}')" "+%s"`
lastRebootFriendly=`date -r$lastReboot`

rundate=`date +%s`

resartPlists=`ls /Library/Application\ Support/JAMF/UEX/restart_jss/ | grep ".plist"`

set -- "$resartPlists"
IFS=$'\n' ; declare -a resartPlists=($*)  
unset IFS

logoutPlists=`ls /Library/Application\ Support/JAMF/UEX/logout_jss/ | grep ".plist"`
set -- "$logoutPlists" 
IFS=$'\n' ; declare -a logoutPlists=($*)  
unset IFS

##########################################################################################
##					Notification if there are scheduled restarts						##
##########################################################################################

sleep 15
otherJamfprocess=`ps aux | grep jamf | grep -v grep | grep -v launchDaemon | grep -v jamfAgent | grep -v uexrestartagent | grep -v uexlogoutagent`
while [ "$otherJamfprocess" ] ; do 
	sleep 15
	otherJamfprocess=`ps aux | grep jamf | grep -v grep | grep -v launchDaemon | grep -v jamfAgent | grep -v uexrestartagent | grep -v uexlogoutagent`
done

# only run the Plist processing command once all other jamf policies have completed
if [[ $otherJamfprocess == "" ]] ; then 
##########################################################################################
##########################################################################################

# check for any plist that are scheduled to have a restart
for i in "${resartPlists[@]}" ; do
	# Check all the plist in the folder for any required actions
	# if the user has already had a fresh restart then delete the plist
	# other wise the advise and schedule the logout.
	name=`/usr/libexec/PlistBuddy -c "print name" /Library/Application\ Support/JAMF/UEX/restart_jss/"$i"`
	packageName=`/usr/libexec/PlistBuddy -c "print packageName" /Library/Application\ Support/JAMF/UEX/restart_jss/"$i"`

	plistrunDate=`/usr/libexec/PlistBuddy -c "print runDate" "/Library/Application Support/JAMF/UEX/restart_jss/$i"`
	
	timeSinceReboot=`echo "${lastReboot} - ${plistrunDate}" | bc`		
	echo timeSinceReboot is $timeSinceReboot
	
	logname=$(echo $packageName | sed 's/.\{4\}$//')
	logfilename="$logname".log
	resulttmp="$logname"_result.log
	logfilepath="$logdir""$logfilename"
	resultlogfilepath="$logdir""$resulttmp"
	
	if [[ $timeSinceReboot -gt 0 ]] || [ -z "$plistrunDate" ] ; then
		# the computer has rebooted since $runDateFriendly
		#delete the plist
		sudo rm "/Library/Application Support/JAMF/UEX/restart_jss/$i"
	else 
		# the computer has NOT rebooted since $runDateFriendly
		restart="true"
		
	fi
done


# if there are no scheduled restart then proceed with logout checks and prompts
if [[ $restart != "true" ]] ; then
	
	for i in "${logoutPlists[@]}" ; do
	# Check all the plist in the folder for any required actions
	# If the plist has already been touched 
	# OR if the user has already had a fresh login then delete the plist
	# other wise the advise and schedule the logout.
		name=`/usr/libexec/PlistBuddy -c "print name" "/Library/Application Support/JAMF/UEX/logout_jss/$i"`
		packageName=`/usr/libexec/PlistBuddy -c "print packageName" "/Library/Application Support/JAMF/UEX/logout_jss/$i"`
		
		plistloggedInUser=`/usr/libexec/PlistBuddy -c "print loggedInUser" "/Library/Application Support/JAMF/UEX/logout_jss/$i"`
		
		checked=`/usr/libexec/PlistBuddy -c "print checked" "/Library/Application Support/JAMF/UEX/logout_jss/$i"`
				
		plistrunDate=`/usr/libexec/PlistBuddy -c "print runDate" "/Library/Application Support/JAMF/UEX/logout_jss/$i"`
		plistrunDateFriendly=`date -r $plistrunDate`
		
		timeSinceLogin=$((lastLogin-plistrunDate))
		timeSinceReboot=`echo "${lastReboot} - ${plistrunDate}" | bc`		
		
		#######################
		# Logging files setup #
		#######################
		logname=$(echo $packageName | sed 's/.\{4\}$//')
		logfilename="$logname".log
		resulttmp="$logname"_result.log
		logfilepath="$logdir""$logfilename"
		resultlogfilepath="$logdir""$resulttmp"
		
		
		if [[ $timeSinceReboot -gt 0 ]] || [ -z "$plistrunDate" ]  ; then
			# the computer has rebooted since $runDateFriendly
			#delete the plist
			sudo rm "/Library/Application Support/JAMF/UEX/logout_jss/$i"
			sudo echo $(date)	$compname	:	 There are no restart interactions required. >> "$logfilepath"
			sudo echo $(date)	$compname	:	 Deleted logout plist because the user has restarted already >> "$logfilepath" 
			
		elif [[ $checked == "true" ]] ; then
		# if the user has a fresh login since then delete the plist
		# if the plist has been touched once then the user has been logged out once
		# then delete the plist
			sudo rm "/Library/Application Support/JAMF/UEX/logout_jss/$i"
			sudo echo $(date)	$compname	:	 Deleted logout plist because the user has logged out already. >> "$logfilepath"
		elif [[ "$plistloggedInUser" != "$loggedInUser" ]] ; then
		# if the user in the plist is not the user as the one currently logged in do not force a logout
		# this will skip the processing of that plist
			killdaemon="false"
			sudo echo $(date)	$compname	:	 User in the logout plist is not the same user as the one currently logged in do not force a logout. >> "$logfilepath"
		else 
		# the user has NOT logged out since $plistrunDateFriendly
		# change the plist state to checked=true so that it's deleted the next time.
			sleep 1
			sudo /usr/libexec/PlistBuddy -c "set checked true" "/Library/Application Support/JAMF/UEX/logout_jss/$i"
			lastline=`awk 'END{print}' "$logfilepath"`
			if [[ "$lastline" != *"Notifying the user"* ]] ; then 
				sudo echo $(date)	$compname	:	 There are no restart interactions required. >> "$logfilepath"
				sudo echo $(date)	$compname	:	 the user has NOT logged out since "$plistrunDateFriendly" >> "$logfilepath"
				sudo echo $(date)	$compname	:	 Notifying the user that a logout is required. >> "$logfilepath"
			fi			
			# set the logout to true so that the user is prompted
			logout="true"
			sleep 1
		fi
	done
elif [[ $restart == "true" ]] ; then 
# start the restart plist so the user will prompted to restart instead
# 	sudo launchctl load -w /Library/LaunchDaemons/com.adidas-group.UEX-restart.plist > /dev/null 2>&1
	
	sudo /usr/local/bin/jamf policy -trigger uexrestartagent &
fi
unset IFS

##########################################################################################
## 							Login Check Run if no on is logged in						##
##########################################################################################
# no login  RUN NOW
# (skip to install stage)
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`

##########################################################################################
##					Notification if there are scheduled logouts							##
##########################################################################################
if [ $loggedInUser ] ; then
    if [[ "$logout" == "true" ]] ; then
    # message
    notice='In order for the changes to complete you must logout of your computer. Please save your work and click "Logout Now" within the allotted time.
 
    Your user will be automatically logged out at the end of the countdown.'
 
        # dialog with 10 minute countdown
        logoutclickbutton=`"$jhPath" -windowType hud -lockHUD -windowPostion lr -title "$title" -description "$notice" -icon "$icon" -timeout 3600 -countdown -alignCountdown center -button1 "Logout Now"`
     
        # Force logout by killing the login window for that user
        # messylogout`ps -Ajc | grep loginwindow | grep "$loggedInUser" | grep -v grep | awk '{print $2}' | sudo xargs kill`
        # Nicer logout (http://apple.stackexchange.com/questions/103571/using-the-terminal-command-to-shutdown-restart-and-sleep-my-mac)
		osascript -e 'tell application "loginwindow" to «event aevtrlgo»'
   #  elif [[ "$killdaemon" != "false" ]] ; then
#         # $killdaemon is only set to false if there are more plist 
#         sudo launchctl unload -w /Library/LaunchDaemons/com.adidas-group.UEX-logout.plist > /dev/null 2>&1
        
    fi
else
    rm /Library/Application Support/JAMF/UEX/logout_jss/*
fi
	
##########################################################################################
##########################################################################################
fi #other jamf processes
##########################################################################################
##########################################################################################

exit 0

##########################################################################################
##					CLEANUP IF THERE ARE NO MORE SCHEDULED LOGOUTS						##
##########################################################################################

# morelogout=`ls /Library/Application\ Support/JAMF/UEX/logout_jss/ | grep .plist`
# if [[ $morelogout == "" ]] ; then 
# 	# no more plists exits
# 	
# 	# stop the daemon from running so luanchd is clear
# # 	sudo launchctl unload -w /Library/LaunchDaemons/com.adidas-group.UEX-logout.plist > /dev/null 2>&1
# 	# delete the daemon for clean up
# # 	sudo rm /Library/LaunchDaemons/com.adidas-group.UEX-logout.plist > /dev/null 2>&1
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
