#!/bin/bash
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`

##########################################################################################
##								Paramaters for Branding									##
##########################################################################################

<<<<<<< HEAD
title="Your IT Deparment"

#Jamf Pro 10 icon if you want another custom one then please update it here.
customLogo="/Library/Application Support/JAMF/Jamf.app/Contents/Resources/AppIcon.icns"

#if you you jamf Pro 10 to brand the image for you self sevice icon will be here
SelfServiceIcon="/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"
=======
title="adidas | Global IT"
customLogo="/Library/Application Support/JAMF/UEX/resources/adidas_company_logo_BWr.png"
SelfServiceIcon="/Library/Application Support/JAMF/UEX/resources/Self Service@2x.icns"
>>>>>>> 96324362ca5bc9fb8f5d7b33ac7cdc8aa6f36e7b

##########################################################################################
##########################################################################################
##							Do not make any changes below								##
##########################################################################################
##########################################################################################
# 
# Block script runs through plists in ../UEX/block_jss/ to kill apps during installation. 
# It run through the list of apps checks to see if they are running and then kills them.
# 
# Name: Block-notification.sh
# Version Number: 3.7
# 
# Created Jan 18, 2016 by 
# David Ramirez (David.Ramirez@adidas-group.com)
#
# Updates January 23rd, 2016 by
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
	sudo echo $(date)	$compname	:	"$1" >> "$logfilepath"
}

logInUEX4DebugMode () {
	if [ $debug = true ] ; then	
		logMessage="-DEBUG- $1"
		logInUEX $logMessage
	fi
}

log4_JSS () {
	sudo echo $(date)	$compname	:	"$1"  | tee -a "$logfilepath"
}

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
		# name=`/usr/libexec/PlistBuddy -c "print name" "/Library/Application Support/JAMF/UEX/block_jss/$i"`
		# packageName=`/usr/libexec/PlistBuddy -c "print packageName" "/Library/Application Support/JAMF/UEX/block_jss/$i"`
		# apps=`/usr/libexec/PlistBuddy -c "print apps2block" "/Library/Application Support/JAMF/UEX/block_jss/$i"`
		# checks=`/usr/libexec/PlistBuddy -c "print checks" "/Library/Application Support/JAMF/UEX/block_jss/$i"`	
		# runDate=`/usr/libexec/PlistBuddy -c "print runDate" "/Library/Application Support/JAMF/UEX/block_jss/$i"`

		name=$(fn_getPlistValue "name" "block_jss" "$i")
		packageName=$(fn_getPlistValue "packageName" "block_jss" "$i")
		apps=$(fn_getPlistValue "apps2block" "block_jss" "$i")
		checks=$(fn_getPlistValue "checks" "block_jss" "$i"	)
		runDate=$(fn_getPlistValue "runDate" "block_jss" "$i")


		runDateFriendly=`date -r$runDate`
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
"$CocoaDialog" bubble \
--title "$actioncap in progress..." --x-placement center --y-placement center \
--text "The application ${appName} cannot be opened while the $action is still in progress.

Please wait for it to complete before attempting to open it." \
	--icon-file "$icon" --icon-size 64 --independent --timeout 30


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
# Apr 24, 2018 	v3.7	--DR--	Funtctions added
# 
