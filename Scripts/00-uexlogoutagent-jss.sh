#!/bin/bash
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`

##########################################################################################
##								Paramaters for Branding									##
##########################################################################################

title="Your IT Department"

# Jamf Pro 10 icon if you want another custom one then please update it here.
# or you can customize this with an image you've included in UEX resources or is already local on the computer
customLogo="/Library/Application Support/JAMF/Jamf.app/Contents/Resources/AppIcon.icns"

# if you you jamf Pro 10 to brand the image for you self sevice icon will be here
# or you can customize this with an image you've included in UEX resources or is already local on the computer
SelfServiceIcon="/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"

##########################################################################################
##########################################################################################
##							DO NOT MAKE ANY CHANGES BELOW								##
##########################################################################################
##########################################################################################
# 
# Logout notification checks the plists in the ../UEX/logout_jss/ folder to notify & force a
# logout if required.
# 
# Name: logout-notification.sh
# Version Number: 4.1
# 
# Created Jan 18, 2016 by 
# David Ramirez (David.Ramirez@adidas.com)
#
# Updates January 23rd, 2017 by
# DR = David Ramirez (D avid.Ramirez@adidas-group.com) 
# 
# Copyright (c) 2018 the adidas Group
# All rights reserved.
##########################################################################################
########################################################################################## 

##########################################################################################
##						STATIC VARIABLES FOR CocoaDialog DIALOGS						##
##########################################################################################

CocoaDialog="/Library/Application Support/JAMF/UEX/resources/cocoaDialog.app/Contents/MacOS/CocoaDialog"

##########################################################################################


##########################################################################################
##							STATIC VARIABLES FOR JH DIALOGS								##
##########################################################################################

jhPath="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

#if the icon file doesn't exist then set to a standard icon
if [[ -e "$SelfServiceIcon" ]]; then
	icon="$SelfServiceIcon"
elif [ -e "$customLogo" ] ; then
	icon="$customLogo"
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
# 										Functions										 #
##########################################################################################

fn_getPlistValue () {
	/usr/libexec/PlistBuddy -c "print $1" /Library/Application\ Support/JAMF/UEX/$2/"$3"
}

logInUEX () {
	echo $(date)	$compname	:	"$1" >> "$logfilepath"
}

logInUEX4DebugMode () {
	if [ $debug = true ] ; then	
		logMessage="-DEBUG- $1"
		logInUEX $logMessage
	fi
}

log4_JSS () {
	echo $(date)	$compname	:	"$1"  | tee -a "$logfilepath"
}

##########################################################################################
##								USER AND PLIST PROCESSING								##
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

	name=$(fn_getPlistValue "name" "restart_jss" "$i")
	packageName=$(fn_getPlistValue "packageName" "restart_jss" "$i")
	plistrunDate=$(fn_getPlistValue "runDate" "restart_jss" "$i")

	timeSinceReboot=`echo "${lastReboot} - ${plistrunDate}" | bc`		
	echo timeSinceReboot is $timeSinceReboot
	
	logname=$(echo $packageName | sed 's/.\{4\}$//')
	logfilename="$logname".log
	resulttmp="$logname"_result.log
	logfilepath="$logdir""$logfilename"
	resultlogfilepath="$logdir""$resulttmp"
	
	if [[ $timeSinceReboot -gt 0 ]] || [ -z "$plistrunDate" ]  ; then
		# the computer has rebooted since $runDateFriendly
		#delete the plist
		logInUEX "Deleting the restart plsit $i because the computer has rebooted since $runDateFriendly"
		rm "/Library/Application Support/JAMF/UEX/restart_jss/$i"
	else 
		# the computer has NOT rebooted since $runDateFriendly
		lastline=`awk 'END{print}' "$logfilepath"`
		if [[ "$lastline" != *"Prompting the user"* ]] ; then 
			logInUEX "The computer has NOT rebooted since $runDateFriendly"
			logInUEX "Prompting the user that a restart is required"
		fi
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

		name=$(fn_getPlistValue "name" "logout_jss" "$i")
		packageName=$(fn_getPlistValue "packageName" "logout_jss" "$i")
		plistloggedInUser=$(fn_getPlistValue "loggedInUser" "logout_jss" "$i")
		checked=$(fn_getPlistValue "checked" "logout_jss" "$i")
		plistrunDate=$(fn_getPlistValue "runDate" "logout_jss" "$i")

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
			rm "/Library/Application Support/JAMF/UEX/logout_jss/$i"
			logInUEX "There are no restart interactions required"
			logInUEX "Deleted logout plist because the user has restarted already"
			
		elif [[ $checked == "true" ]] ; then
		# if the user has a fresh login since then delete the plist
		# if the plist has been touched once then the user has been logged out once
		# then delete the plist
			rm "/Library/Application Support/JAMF/UEX/logout_jss/$i"
			logInUEX "Deleted logout plist because the user has logged out already"
		elif [[ "$plistloggedInUser" != "$loggedInUser" ]] ; then
		# if the user in the plist is not the user as the one currently logged in do not force a logout
		# this will skip the processing of that plist
			logInUEX "User in the logout plist is not the same user as the one currently logged in do not force a logout"
		else 
		# the user has NOT logged out since $plistrunDateFriendly
		# change the plist state to checked=true so that it's deleted the next time.
			sleep 1
			/usr/libexec/PlistBuddy -c "set checked true" "/Library/Application Support/JAMF/UEX/logout_jss/$i"
			lastline=`awk 'END{print}' "$logfilepath"`
			if [[ "$lastline" != *"Notifying the user"* ]] ; then 
				logInUEX "There are no restart interactions required."
				logInUEX "the user has NOT logged out since $plistrunDateFriendly"
				logInUEX "Notifying the user that a logout is required."
			fi			
			# set the logout to true so that the user is prompted
			logout="true"
			sleep 1
		fi
	done
elif [[ $restart == "true" ]] ; then 
# start the restart plist so the user will prompted to restart instead
# 	launchctl load -w /Library/LaunchDaemons/com.adidas-group.UEX-restart.plist > /dev/null 2>&1
	
	/usr/local/bin/jamf policy -trigger uexrestartagent &
fi
unset IFS

##########################################################################################
## 							Login Check Run if no on is logged in						##
##########################################################################################
# no login  RUN NOW
# (skip to install stage)
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`
osMajor=$( /usr/bin/sw_vers -productVersion | awk -F. {'print $2'} )
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
     
       
        if [[ "$osMajor" -ge 14 ]]; then
	        # Force logout by killing the login window for that user
	        messylogout`ps -Ajc | grep loginwindow | grep "$loggedInUser" | grep -v grep | awk '{print $2}' | xargs kill`
		else
			 # Nicer logout (http://apple.stackexchange.com/questions/103571/using-the-terminal-command-to-shutdown-restart-and-sleep-my-mac)
			osascript -e 'tell application "loginwindow" to «event aevtrlgo»'
		fi # OS is ge 14
    fi
else
    rm /Library/Application\ Support/JAMF/UEX/logout_jss/*
fi
	
##########################################################################################
##########################################################################################
fi #other jamf processes
##########################################################################################
##########################################################################################

exit 0

##########################################################################################
##									Version History										##
##########################################################################################
# 
# 
# Jan 18, 2016 	v1.0	--DR--	Stage 1 Delivered
# Sep 5, 2016 	v2.0	--DR--	Logging added
# Apr 24, 2018 	v3.7	--DR--	Funtctions added
# Oct 24, 2018 	v4.0	--DR--	All Change logs are available now in the release notes on GITHUB
# 
