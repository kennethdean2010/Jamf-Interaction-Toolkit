#!/bin/bash
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`
loggedInUserHome=`dscl . read /Users/$loggedInUser NFSHomeDirectory | awk '{ print $2 }'`

##########################################################################################
##								Paramaters for Customization 							##
##########################################################################################

title="Your IT Department"

# Jamf Pro 10 icon if you want another custom one then please update it here.
# or you can customize this with an image you've included in UEX resources or is already local on the computer
customLogo="/Library/Application Support/JAMF/Jamf.app/Contents/Resources/AppIcon.icns"

# if you you jamf Pro 10 to brand the image with your self sevice icon will be here
# or you can customize this with an image you've included in UEX resources or is already local on the computer
SelfServiceIcon="$loggedInUserHome/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"


enable_filevault_reboot=false

##########################################################################################
##########################################################################################
##							DO NOT MAKE ANY CHANGES BELOW								##
##########################################################################################
##########################################################################################
# 
# Restart notification checks the plists in the ../UEX/logout2.0/ folder to notify & force a
# restart if required.
# 
# Name: restart-notification.sh
# Version Number: 4.1
# 
# Created Jan 18, 2016 by 
# David Ramirez (David.Ramirez@adidas.com)
#
# Updates January 23rd, 2017 by
# DR = David Ramirez (David.Ramirez@adidas.com) 
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

fn_getPassword () {
	"$CocoaDialog" standard-inputbox --no-show --title "$title" --informative-text "Please enter in your password" -no-newline --icon-file "$icon" | tail +2
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
	
	name=$(fn_getPlistValue "name" "restart_jss" "$i")
	packageName=$(fn_getPlistValue "packageName" "restart_jss" "$i")
	plistrunDate=$(fn_getPlistValue "runDate" "restart_jss" "$i")
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

osMajor=$( /usr/bin/sw_vers -productVersion | awk -F. {'print $2'} )

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


##########################################################################################
##						FileVautl Authenticated reboot									##
##########################################################################################

		fvUsers=($(fdesetup list | awk -F',' '{ print $1}'))
		fvAutrestartSupported=`fdesetup supportsauthrestart`

		for user2Check in "${fvUsers[@]}"; do
			# Check if the logged in user can unlock the disk by lopping through the user that are abel to unlock it

			if [[ "$loggedInUser" == "$user2Check" ]]; then
				# set the unlock disk variable so that the user can be proompted if they want to do an authenticated restart
				userCanUnLockDisk=true
				break
			fi
		done

		# only if some one is logged in and can unlock the disk and it's supported
		if [[ $loggedInUser ]] && [[ "$userCanUnLockDisk" = true ]] && [[ "$fvAutrestartSupported" = true ]] && [[ "$enable_filevault_reboot" = true ]] ; then
	
			fvUnlockHeading="FileVault Authorized Restart"
			fvUnlockNotice='In order for the changes to complete you must restart your computer. Please save your work. 
	
Would you like enter your password to have the computer unlock the disk automatically? 
Note: Automatic does not always occur.'
	
		#notice
		fvUnlockButton=`"$jhPath" -windowType hud -lockHUD -heading "$fvUnlockHeading" -windowPostion lr -title "$title" -description "$fvUnlockNotice" -icon "$icon" -timeout 300 -countdown -alignCountdown center -button1 "No" -button2 "Yes" `
		
			if [[ "$fvUnlockButton" = 2 ]]; then
				log4_JSS "User chose to restart with an authenticatedRestart"
				authenticatedRestart=true
				passwordLooper=0
				while [[ "$passwordLooper" = 0 ]]; do
					#statements
					userPassword=""
					userPassword="$(fn_getPassword)"

				if [[ "$userPassword" ]]; then
					#statements
					authenticatedRestart=true
					expect -c "
					log_user 0
					spawn fdesetup authrestart
					expect \"Enter the user name:\"
					send {${loggedInUser}}
					send \r
					expect \"Enter the password for user '{${loggedInUser}}':\"
					send {${userPassword}}
					send \r
					log_user 1
					expect eof
					"
				fi # if there is a userPassword entered

				fvUnlockErrorNotice='There was error with the authorized restart. Your password may be incorrect, out of sync, or blank.

	Click "Try Again" or "Cancel".'
		
				#notice
				fvUnlockErrorButton=`"$jhPath" -windowType hud -lockHUD -heading "$fvUnlockHeading" -windowPostion lr -title "$title" -description "$fvUnlockErrorNotice" -icon "$icon" -timeout 300 -countdown -alignCountdown center -button1 "Cancel" -button2 "Try Again" `
				if [[ "$fvUnlockErrorButton" = 2 ]]; then
					#statements
					passwordLooper=0
				else
					authenticatedRestart=false
					passwordLooper=1
				fi # user chose to try again

				done 

			fi # if the user chose to try an authenticated restart

		fi # if user can unlock a disk supporting autheciated restart

##########################################################################################
##									Standard reboot										##
##########################################################################################
		
		if [ $loggedInUser ] && [[ "$authenticatedRestart" != true ]] ; then
		# message
		notice='In order for the changes to complete you must restart your computer. Please save your work and click "Restart Now" within the allotted time. 
	
Your computer will be automatically restarted at the end of the countdown.'
	
		#notice
		restartclickbutton=`"$jhPath" -windowType hud -lockHUD -windowPostion lr -title "$title" -description "$notice" -icon "$icon" -timeout 3600 -countdown -alignCountdown center -button1 "Restart Now"`
	
			if [[ "$authenticatedRestart" = true ]] ;then
				log4_JSS "ENTRY 2: User chose to restart with an authenticatedRestart"

			elif [[ "$osMajor" -ge 14 ]]; then
				#statements
				shutdown -r now
			else
				# Nicer restart (http://apple.stackexchange.com/questions/103571/using-the-terminal-command-to-shutdown-restart-and-sleep-my-mac)
				osascript -e 'tell app "System Events" to restart'
			fi # OS is ge 14

		else # no one is logged in
			# force restart
			# while no on eis logged in you can do a force shutdown

			logInUEX "no one is logged in forcing a restart."
			shutdown -r now
			# Nicer restart (http://apple.stackexchange.com/questions/103571/using-the-terminal-command-to-shutdown-restart-and-sleep-my-mac)
# 			osascript -e 'tell app "System Events" to restart'
		fi
	fi
fi

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
