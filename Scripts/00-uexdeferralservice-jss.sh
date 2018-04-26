#!/bin/bash

##########################################################################################
##########################################################################################
# 
# Run Deferred checks the plists in ../UEX/defer_jss/ folder for any installs that any
# PKGs that have been deferred once enough time has elapsed OR if no one is logged in.
# 
# Name: deferral-service
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
# 										LOGGING PREP									 #
##########################################################################################
# logname=$(echo $packageName | sed 's/.\{4\}$//')
# logfilename="$logname".log
logdir="/Library/Application Support/JAMF/UEX/UEX_Logs/"
# resulttmp="$logname"_result.log
##########################################################################################

##########################################################################################
##					PROCESS PLISTS AND RESTARTING INSTALLS IF READY						##
##########################################################################################

loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`
logoutHookRunning=`ps aux | grep "JAMF/ManagementFrameworkScripts/logouthook.sh" | grep -v grep`

if [ "$logoutHookRunning" ] ; then 
	loggedInUser=""
fi

plists=`ls /Library/Application\ Support/JAMF/UEX/defer_jss/ | grep ".plist"`
runDate=`date +%s`

IFS=$'\n'
for i in $plists ; do
	BatteryTest=`pmset -g batt`
	loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`
	logoutHookRunning=`ps aux | grep "JAMF/ManagementFrameworkScripts/logouthook.sh" | grep -v grep`

	if [ "$logoutHookRunning" ] ; then 
		loggedInUser=""
	fi
	
	# Process the plist	
	delayDate=`/usr/libexec/PlistBuddy -c "print delayDate" /Library/Application\ Support/JAMF/UEX/defer_jss/"$i"`
	packagename=`/usr/libexec/PlistBuddy -c "print package" /Library/Application\ Support/JAMF/UEX/defer_jss/$i`
	folder=`/usr/libexec/PlistBuddy -c "print folder" /Library/Application\ Support/JAMF/UEX/defer_jss/"$i"`
	loginscreeninstall=`/usr/libexec/PlistBuddy -c "print loginscreeninstall" /Library/Application\ Support/JAMF/UEX/defer_jss/"$i"`
	checks=`/usr/libexec/PlistBuddy -c "print checks" /Library/Application\ Support/JAMF/UEX/defer_jss/"$i"`
	policyTrigger=`/usr/libexec/PlistBuddy -c "print policyTrigger" /Library/Application\ Support/JAMF/UEX/defer_jss/"$i"`

	#######################
	# Logging files setup #
	#######################
	logname=$(echo $packageName | sed 's/.\{4\}$//')
	logfilename="$logname".log
	resulttmp="$logname"_result.log
	logfilepath="$logdir""$logfilename"
	resultlogfilepath="$logdir""$resulttmp"
	
	# calculate the time elapsed
	timeelapsed=$((delayDate-runDate))
	if [ $loggedInUser ] ; then
		# string contains a user ID therefore someone is logged in
		if [ "$timeelapsed" -lt 0 ] ; then
		# Enough time has passed 
		# start the install
			sudo echo $(date)	$compname	:	 Enough time has passed starting the install. | tee -a "$logfilepath"
			sudo /usr/local/bin/jamf policy -trigger "$policyTrigger"
		fi
	elif [[ $loggedInUser == "" ]] && [[ $loginscreeninstall == false ]] ; then
		echo skipping install
	elif [[ $loggedInUser == "" ]] && [[ $loginscreeninstall == true ]] && [[ $checks == *"power"* ]] && [[ "$BatteryTest" != *"AC"* ]] ; then
		echo skipping install
	else 
	# loggedInUser is null therefore no one is logged in
	# start the install
		sudo echo $(date)	$compname	:	 No one is logged. >> "$logfilepath"
		sudo echo $(date)	$compname	:	 Login screen install permitted. >> "$logfilepath"
		sudo echo $(date)	$compname	:	 All requrements met. >> "$logfilepath"
		sudo echo $(date)	$compname	:	 Starting Install >> "$logfilepath"
		
		sudo killall loginwindow
		sudo /usr/local/bin/jamf policy -trigger "$policyTrigger"
	fi
	
done
unset IFS

##########################################################################################
##										Clean Up										##
##########################################################################################
# deferPackagesDIR="/Library/Application Support/JAMF/UEX/deferPKGs/"
# 
# pkgs=`ls "$deferPackagesDIR" | grep ".pkg"`
# plists=`ls /Library/Application\ Support/JAMF/UEX/defer_jss/ | grep ".plist"`
# 
# IFS=$'\n'
# for i in $pkgs ; do
# 	if [[ "$plists" != *"$i"* ]] ; then
# 		sudo chflags -R nouchg "$deferPackagesDIR""$i"
# 		sudo chflags -R noschg "$deferPackagesDIR""$i"
# 		rm "$deferPackagesDIR""$i"
# 		echo deleting "$i"
# 	fi
# done
# unset IFS



##########################################################################################
##									Version History										##
##########################################################################################
# 
# 
# Jan 18, 2016 	v1.0	--DR--	Stage 1 Delivered
# May 22, 2016 	v1.3	--DR--	added considerations for loginscreeninstall (power reqs & time etc.)
# Sep 5, 2016 	v2.0	--DR--	Logging added
# Sep 5, 2016 	v2.0	--DR--	Debug mode added
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
