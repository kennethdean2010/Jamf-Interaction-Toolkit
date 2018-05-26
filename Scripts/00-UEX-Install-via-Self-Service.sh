#!/bin/sh

jamfBinary="/usr/local/jamf/bin/jamf"

##########################################################################################
##########################################################################################
# 
# This can be used for UEX and non-UEX Policies to trigger the install policy.
# 
# Version Number: 3.7
# 
# Created January 31st, 2017 by
# DR = David Ramirez (David.Ramirez@adidas-group.com) 
# 
# Updated September 2tth, 2017 by
# DR = David Ramirez (David.Ramirez@adidas-group.com) 
# 
# Copyright (c) 2018 the adidas Group
# All rights reserved.
##########################################################################################
########################################################################################## 

triggers="$4"

IFS=";"
set -- "$triggers" 
declare -a triggers=($*)
unset IFS



for triggerName in ${triggers[@]} ; do

	sudo "$jamfBinary" policy -forceNoRecon -trigger "$triggerName"

	if [[ $? != 0 ]]; then
		echo The policy for trigger "$triggerName" exited in a non-zero status
		failedInstall=true
	fi
done


if [ "$failedInstall" = true ] ; then 
	exit 1
else
	exit 0
fi

##########################################################################################
##									Version History										##
##########################################################################################
# 
# 
# Jan 31, 2017 	v1.0	--DR--	Version 1 Created
# Sep 11, 2017 	v2.0	--DR--	Added checking for status of installation
# Sep 26, 2017 	v3.2	--DR--	Added Support for multiple trigger names seperated by ;