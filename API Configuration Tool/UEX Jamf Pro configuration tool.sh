#!/bin/bash
# set -x
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }' | grep -v root`

###################
# Variables
###################

jss_url="https://cubandave.local:8443"
jss_user="jssadmin"
jss_pass="jamf1234"

# Set the category you'd like to use for all the policies
UEXCategoryName="User Experience"

packages=(
"UEXresourcesInstaller-201903130155.pkg"
)

# This enables the interaction for Help Disk Tickets
# by default it is disabled. For more info on how to use this check the wiki in the Help Desk Ticket Section
helpTicketsEnabledViaAppRestriction=false
helpTicketsEnabledViaGeneralStaticGroup=false
restrictedAppName="User Needs Helps Clearing Space.app"

# if you use the general method of addind and removing the requiremnt for help desk support to clear
# disk space then you should leave these as is
UEXhelpticketTrigger="disk_space_help_ticket"
ClearHelpTicketRequirementTrigger="remove_from_group_for_disk_space_help_ticket"


##########################################################################################
# 								Do not change anything below!							 #
##########################################################################################

scripts=(
"00-PleaseWaitUpdater-jss"
"00-UEX-Deploy-via-Trigger"
"00-UEX-Install-Silent-via-trigger"
"00-UEX-Install-via-Self-Service"
"00-UEX-Jamf-Interaction-no-grep"
"00-UEX-Uninstall-via-Self-Service"
"00-UEX-Update-via-Self-Service"
"00-uexblockagent-jss"
"00-uexdeferralservice-jss"
"00-uexlogoutagent-jss"
"00-uexrestartagent-jss"
"00-uex_inventory_update_agent-jss"
)

triggerscripts=(
	"00-UEX-Deploy-via-Trigger"
	"00-UEX-Install-Silent-via-trigger"
	"00-UEX-Install-via-Self-Service"
	"00-UEX-Uninstall-via-Self-Service"
	"00-UEX-Update-via-Self-Service"
)

apiScripts=(
	"00-API-Add-Current-Computer-to-Static-Group.sh"
	"00-API-Remove-Current-Computer-to-Static-Group.sh"
)

UEXInteractionScripts=(
"00-UEX-Jamf-Interaction-no-grep"
)



##########################################################################################
# 										Functions										 #
##########################################################################################

FNputXML () 
	{
		# echo /usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/$2" -u "${jss_user}:${jss_pass}" -H \"Content-Type: text/xml\" -X PUT -d "$3"
		/usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/$2" -u "${jss_user}:${jss_pass}" -H "Content-Type: text/xml" -X PUT -d "$3"
    }

FNpostXML () 
	{
		# echo /usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/0" -u "${jss_user}:${jss_pass}" -H \"Content-Type: text/xml\" -X POST -d "$2"
		/usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/0" -u "${jss_user}:${jss_pass}" -H "Content-Type: text/xml" -X POST -d "$2"
    }

FNput_postXML () 
	{

	FNgetID "$1" "$2"
	pid=$retreivedID

	if [ $pid ] ; then
		echo "updating $1: ($pid) \"$2\"" 
		FNputXML $1 $pid "$3"
		echo ""
	else
		echo "creating $1: \"$2\""
		FNpostXML $1 "$3"
		echo ""
	fi

	FNtestXML $1 "$2"
	}

FNput_postXMLFile () 
	{

	FNgetID "$1" "$2"
	pid=$retreivedID

	if [ $pid ] ; then
		echo "updating $1: ($pid) \"$2\"" 
		FNputXMLFile $1 $pid "$3"
		echo ""
	else
		echo "creating $1: \"$2\""
		FNpostXMLFile $1 "$3"
		echo ""
	fi

	FNtestXML $1 "$2"
	}

FNputXMLFile () 
	{	# echo /usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/$2" -u "${jss_user}:${jss_pass}" -H \"Content-Type: text/xml\" -X PUT -d "$3"
		/usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/$2" -u "${jss_user}:${jss_pass}" -H "Content-Type: text/xml" -X PUT -T "$3"
	}


FNpostXMLFile () 
	{
		# echo /usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/0" -u "${jss_user}:${jss_pass}" -H \"Content-Type: text/xml\" -X POST -d "$2"
		/usr/bin/curl -s -k "${jss_url}/JSSResource/$1/id/0" -u "${jss_user}:${jss_pass}" -H "Content-Type: text/xml" -X POST -T "$2"
	}

FNtestXML () 
	{

	FNgetID $1 "$2"
	pid=$retreivedID

	if [ $pid ] ; then
		# echo "$1 \"$2\" exists ($pid)" 
		echo ""
	else
		echo "ERROR $1 \"$2\" does not exist" 
		exit 1
	fi
	}

FNgetID () 
	{
		retreivedID=""
		retreivedXML=""
		retreivedXML4ParserError=""
		name="$2"
		apiName=`/bin/echo ${2// /"%20"}`

		# retreivedXMLofResource=`/usr/bin/curl -s -k "${jss_url}/JSSResource/$1" -u "${jss_user}:${jss_pass}" -H "Accept: application/xml"`
		retreivedID=`/usr/bin/curl -s -k "${jss_url}/JSSResource/$1" -u "${jss_user}:${jss_pass}" -H "Accept: application/xml" | xmllint --format - | grep -B 1 "$name" | /usr/bin/awk -F'<id>|</id>' '{print $2}' | sed '/^\s*$/d'`
		# retreivedID=`/bin/echo $retreivedXMLofResource | xmllint --format - | grep -B 1 "$name" | /usr/bin/awk -F'<id>|</id>' '{print $2}' | sed '/^\s*$/d'`

    }

FNcreateCategory () {
	CategoryName="$1"
	newCategoryNameXML="<category><name>$CategoryName</name><priority>9</priority></category>"

	FNput_postXML categories "$CategoryName" "$newCategoryNameXML"
	FNgetID categories "$CategoryName"
}

fn_createAgentPolicy () {
	scriptID=""
	policyScript="$1"
	policyTrigger="$2"
	agentPolicyName=`echo "${policyScript//.sh}"`
	agentPolicyName+=" - Trigger"
	echo "$agentPolicyName"

	FNgetID scripts "$policyScript"
	scriptID="$retreivedID"

	agentPolicyXML="<policy>
	  <general>
	    <name>$agentPolicyName/name>
	    <enabled>true</enabled>
	    <trigger>EVENT</trigger>
	    <trigger_other>$policyTrigger</trigger_other>
	    <category>
	      <id>$UEXCategoryID</id>
	    </category>
	  </general>
	  <scope>
	    <all_computers>true</all_computers>
	  </scope>
	  <scripts>
	    <size>1</size>
	    <script>
	      <id>$scriptID</id>
	    </script>
	  </scripts>
	</policy>"

agentPolicyXML="<policy>
  <general>
    <name>$agentPolicyName</name>
    <enabled>true</enabled>
    <trigger>EVENT</trigger>
    <trigger_other>$policyTrigger</trigger_other>
    <frequency>Ongoing</frequency>
    <category>
      <id>$UEXCategoryID</id>
    </category>
  </general>
  <scope>
    <all_computers>true</all_computers>
  </scope>
  <scripts>
    <size>1</size>
    <script>
      <id>$scriptID</id>
      <priority>After</priority>
    </script>
  </scripts>
</policy>"

FNput_postXML "policies" "$agentPolicyName" "$agentPolicyXML"

}

fn_checkForSMTPServer () {
	echo $(/usr/bin/curl -s -k "${jss_url}/JSSResource/smtpserver" -u "${jss_user}:${jss_pass}" -H "Accept: application/xml" | xmllint --format - | grep -c "<enabled>true</enabled>")
}

fn_createTriggerPolicy () {
	triggerPolicyName="$1"
	policyTrigger2Run="$2"
	FNgetID "scripts" "00-UEX-Deploy-via-Trigger"
	triggerScripID="$retreivedID"
	triggerPolicyScopeXML="$3"

	triggerPolicyXML="<policy>
  <general>
    <name>$triggerPolicyName</name>
    <enabled>true</enabled>
    <trigger_checkin>true</trigger_checkin>
    <trigger_logout>true</trigger_logout>
    <frequency>Ongoing</frequency>
    <category>
      <id>$UEXCategoryID</id>
    </category>
  </general>
  <scope>
	$triggerPolicyScopeXML
  </scope>
  <scripts>
    <size>1</size>
    <script>
      <id>$triggerScripID</id>
      <priority>After</priority>
      <parameter4>$policyTrigger2Run</parameter4>
    </script>
  </scripts>
</policy>"

FNput_postXML "policies" "$triggerPolicyName" "$triggerPolicyXML"

}


fn_createTriggerPolicy4Pkg () {
	packagePolicyName="$1"
	pkg2Install="$2"
	customEventName="$3"
	FNgetID "packages" "$pkg2Install"
	policypackageID="$retreivedID"
	packagePolicyScopeXML="$4"

	packagePolicyXML="<policy>
  <general>
    <name>$packagePolicyName</name>
    <enabled>true</enabled>
    <trigger>EVENT</trigger>
    <trigger_other>$customEventName</trigger_other>
    <frequency>Ongoing</frequency>
    <category>
      <id>$UEXCategoryID</id>
    </category>
  </general>
  <scope>
	$packagePolicyScopeXML
  </scope>
  <package_configuration>
    <packages>
      <size>1</size>
      <package>
        <id>$policypackageID</id>
        <action>Install</action>
      </package>
    </packages>
  </package_configuration>
</policy>"

FNput_postXML "policies" "$packagePolicyName" "$packagePolicyXML"
}

fn_createSmartGroup () {
	smartGroupName="$1"
	smartGroupCriteriaSize="$2"
	smartGroupCriterionXML="$3"

	SmartGroupXML="<computer_group>
	  <name>$smartGroupName</name>
	  <is_smart>true</is_smart>
	  <site>
	    <id>-1</id>
	    <name>None</name>
	  </site>
	  <criteria>
	    <size>$smartGroupCriteriaSize</size>
	    $smartGroupCriterionXML
	  </criteria>
	  </computer_group>"

	  FNput_postXML "computergroups" "$1" "$SmartGroupXML"
}


fn_updateCategory () {
	resourceID="$1"
	xmlStart="$2"
	categoryName="$3"
	JSSResourceName="$4"

	categoryXML="<$xmlStart>
		<category>$categoryName</category>
		</$xmlStart>"

		FNputXML "$JSSResourceName" "$resourceID" "$categoryXML"
}

fn_setScriptParameters () {
	scriptName=""
	parameter4=""
	parameter5=""
	parameter6=""
	parameter7=""
	parameter8=""
	parameter9=""
	parameter10=""
	parameter11=""

	scriptName="$1"
	parameter4="$2"
	parameter5="$3"
	parameter6="$4"
	parameter7="$5"
	parameter8="$6"
	parameter9="$7"
	parameter10="$8"
	parameter11="$9"

	scriptParameterXML="<script>
	<parameters>
<parameter4>$parameter4</parameter4>
<parameter5>$parameter5</parameter5>
<parameter6>$parameter6</parameter6>
<parameter7>$parameter7</parameter7>
<parameter8>$parameter8</parameter8>
<parameter9>$parameter9</parameter9>
<parameter10>$parameter10</parameter10>
<parameter11>$parameter11</parameter11>
</parameters>
 </script>"


	FNput_postXML scripts "$scriptName" "$scriptParameterXML"
}


fn_CreateAppRestrictionPolicy () {


restrictedsoftwareXML="<restricted_software>
  <general>
    <name>User Needs Help Clearing Disk Space</name>
    <process_name>$restrictedAppName</process_name>
    <match_exact_process_name>true</match_exact_process_name>
    <send_notification>true</send_notification>
    <kill_process>true</kill_process>
    <delete_executable>false</delete_executable>
    <display_message/>
    <site>
      <id>-1</id>
      <name>None</name>
    </site>
  </general>
  <scope>
    <all_computers>true</all_computers>
    <computers/>
    <computer_groups/>
    <buildings/>
    <departments/>
    <exclusions>
      <computers/>
      <computer_groups/>
      <buildings/>
      <departments/>
      <users/>
    </exclusions>
  </scope>
</restricted_software>"

	FNput_postXML restrictedsoftware "User Needs Help Clearing Disk Space" "$restrictedsoftwareXML"


}

fn_create_staticGroup_for_Disk_Space () {
	StaticGroupXMLForDiskSpace="<computer_group>
  <name>User Needs Help Clearing Disk Space</name>
  <is_smart>false</is_smart>
  <site>
    <id>-1</id>
    <name>None</name>
  </site>
</computer_group>"

	FNput_postXML "computergroups" "User Needs Help Clearing Disk Space" "$StaticGroupXMLForDiskSpace"
}

fn_create_MonititoringSmartGroup_for_Disk_Space () {
	SmartGroupXMLForDiskSpace="<computer_group>
  <name>Monitoring - UEX - Help User Clearing Disk Space</name>
  <is_smart>true</is_smart>
  <site>
    <id>-1</id>
    <name>None</name>
  </site>
  <criteria>
    <size>1</size>
    <criterion>
      <name>Computer Group</name>
      <priority>0</priority>
      <and_or>and</and_or>
      <search_type>member of</search_type>
      <value>User Needs Help Clearing Disk Space</value>
      <opening_paren>false</opening_paren>
      <closing_paren>false</closing_paren>
    </criterion>
  </criteria>
</computer_group>"

	FNput_postXML "computergroups" "Monitoring - UEX - Help User Clearing Disk Space" "$SmartGroupXMLForDiskSpace"
}

fn_openMonitoringSmartGroup () {
	FNgetID "computergroups" "Monitoring - UEX - Help User Clearing Disk Space"
	MonitoringGroupID="$retreivedID"
	sudo -u "$loggedInUser" -H open "$jss_url/smartComputerGroups.html?id=$MonitoringGroupID&o=u"
}

##########################################################################################
# 								Script Starts Here										 #
##########################################################################################

if [[ "$helpTicketsEnabledViaAppRestriction" = true ]] || [[ "$helpTicketsEnabledViaGeneralStaticGroup" = true ]] ;then
	if [[ $(fn_checkForSMTPServer) -eq 0 ]] ; then
		echo "no SMTP server configured." 
		echo "Please check your Jamf Pro server or disbale helpTicketsEnabledViaAppRestriction or helpTicketsEnabledViaGeneralStaticGroup"
		exit 1
	fi
fi

if [[ "$helpTicketsEnabledViaAppRestriction" = true ]]; then
	#statements
	fn_CreateAppRestrictionPolicy
fi


if [[ "$helpTicketsEnabledViaGeneralStaticGroup" = true ]]; then
	#statements
	fn_create_staticGroup_for_Disk_Space
	fn_create_MonititoringSmartGroup_for_Disk_Space
	# fn_openMonitoringSmartGroup
fi


# create category
	FNcreateCategory "$UEXCategoryName"
	UEXCategoryID="$retreivedID"
	echo $UEXCategoryID

# check for all copmonents and update their category 
	for script in "${scripts[@]}" ; do 
		FNgetID "scripts" "$script" 
		if [ -z "$retreivedID" ] ; then
			echo ERROR: Script "$script" not found on jamf server "$jss_url"
			exit 1
		else
			fn_updateCategory "$retreivedID" "script" "$UEXCategoryName" "scripts"
		fi
	done

	for package in "${packages[@]}" ; do 
		FNgetID "packages" "$package" 
		if [ -z "$retreivedID" ] ; then
			echo ERROR: Package "$package" not found on jamf server "$jss_url"
			exit 1
		else
			fn_updateCategory "$retreivedID" "package" "$UEXCategoryName" "packages"
		fi
	done

# update scripts paramters
	for triggerscript in "${triggerscripts[@]}" ; do
		fn_setScriptParameters "$triggerscript" "Trigger names separated by semi-colon"
	done

	# "Vendor;AppName;Version;SpaceReq"
	# "Checks"
	# "Apps for Quick and Block"
	# "InstallDuration - Must be integer"
	# "maximum deferral - Must be integer"
	# "Packages separated by semi-colon"
	# "Trigger Names separated by semi-colon"
	# "Custom Message - optional"

	for UEXInteractionScript in "${UEXInteractionScripts[@]}" ; do
		fn_setScriptParameters "$UEXInteractionScript" "Vendor;AppName;Version;SpaceReq" "Checks" "Apps for Quick and Block" "InstallDuration - Must be integer" "maximum deferral - Must be integer" "Packages separated by semi-colon" "Trigger Names separated by semi-colon" "Custom Message - optional"
	done


# create agent policies
	fn_createAgentPolicy "00-uexblockagent-jss" "uexblockagent"
	fn_createAgentPolicy "00-uexlogoutagent-jss" "uexlogoutagent"
	fn_createAgentPolicy "00-uexrestartagent-jss" "uexrestartagent"
	fn_createAgentPolicy "00-uex_inventory_update_agent-jss" "uex_inventory_update_agent"
	fn_createAgentPolicy "00-uexdeferralservice-jss" "uexdeferralservice"
	fn_createAgentPolicy "00-PleaseWaitUpdater-jss" "PleaseWaitUpdater"


# Check for EA
	extAttrName="UEX - Deferral Detection"
	FNgetID computerextensionattributes "$extAttrName"
	if [ -z "$retreivedID" ] ;then
		echo ERROR: Exentsion Attribute "$extAttrName" not found on jamf server "$jss_url"
		exit 1
	fi

# Create smart group
	smartGroupName="UEX - Active Deferrals"

	criterionXML="<criterion>
	      <name>$extAttrName</name>
	      <priority>0</priority>
	      <and_or>and</and_or>
	      <search_type>like</search_type>
	      <value>active</value>
	      <opening_paren>false</opening_paren>
	      <closing_paren>false</closing_paren>
	    </criterion>"

	fn_createSmartGroup "$smartGroupName" "1" "$criterionXML"
	SmargroupID="$retreivedID"
	echo "$SmargroupID"

# create deferal policy
defferalPolicyScopeXML="<all_computers>false</all_computers>
    <computers/>
    <computer_groups>
      <computer_group>
        <id>$SmargroupID</id>
      </computer_group>
    </computer_groups>"

fn_createTriggerPolicy "00-uexdeferralservice-jss - Checkin and Logout" "uexdeferralservice" "$defferalPolicyScopeXML"

# create UEX resources policy
fn_createTriggerPolicy4Pkg "00-uexresources-jss - Trigger" "${packages[0]}" "uexresources" "<all_computers>true</all_computers>"

if [[ "$helpTicketsEnabledViaGeneralStaticGroup" = true ]]; then
	echo "Now Opening the Monitoring Smart Group"
	echo "Make sure the Notification Setting is on"
	sleep 3
	fn_openMonitoringSmartGroup
fi

echo "The world is now your burrito!"


##########################################################################################
exit 0
