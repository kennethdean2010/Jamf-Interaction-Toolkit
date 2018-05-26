#!/bin/bash

###################
# Variables
###################

<<<<<<< HEAD
jss_url="https://192.168.31.128:8443"
jss_user="jssadmin"
jss_pass="jamf1234"
=======
jss_url="https://jss_url"
jss_user="jss_user"
jss_pass="jss_pass"
>>>>>>> 96324362ca5bc9fb8f5d7b33ac7cdc8aa6f36e7b

# Set the category you'd like to use for all the policies
UEXCategoryName="User Experience"

<<<<<<< HEAD
packages=(
"UEXresourcesInstaller-201805252201.pkg"
)

=======
>>>>>>> 96324362ca5bc9fb8f5d7b33ac7cdc8aa6f36e7b
##########################################################################################
# 								Do not change anything below!							 #
##########################################################################################

scripts=(
"00-PleaseWaitUpdater-jss.sh"
"00-UEX-Deploy-via-Trigger.sh"
"00-UEX-Install-Silent-via-trigger.sh"
"00-UEX-Install-via-Self-Service.sh"
<<<<<<< HEAD
"00-UEX-Jamf-Interaction-no-grep.sh"
=======
"00-UEX-Jamf-Interaction.sh"
>>>>>>> 96324362ca5bc9fb8f5d7b33ac7cdc8aa6f36e7b
"00-UEX-Uninstall-via-Self-Service.sh"
"00-UEX-Update-via-Self-Service.sh"
"00-uexblockagent-jss.sh"
"00-uexdeferralservice-jss.sh"
"00-uexlogoutagent-jss.sh"
"00-uexrestartagent-jss.sh"
"00-uex_inventory_update_agent-jss.sh"
)

triggerscripts=(
	"00-UEX-Deploy-via-Trigger.sh"
	"00-UEX-Install-Silent-via-trigger.sh"
	"00-UEX-Install-via-Self-Service.sh"
	"00-UEX-Uninstall-via-Self-Service.sh"
	"00-UEX-Update-via-Self-Service.sh"
)

UEXInteractionScripts=(
<<<<<<< HEAD
"00-UEX-Jamf-Interaction-no-grep.sh"
)


=======
"00-UEX-Jamf-Interaction.sh"
)

packages=(
"aG-adidas-UEXresources-3.6.pkg"
)
>>>>>>> 96324362ca5bc9fb8f5d7b33ac7cdc8aa6f36e7b

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
      <name>$policyScript</name>
      <priority>After</priority>
    </script>
  </scripts>
</policy>"

FNput_postXML "policies" "$agentPolicyName" "$agentPolicyXML"

}

fn_createTriggerPolicy () {
	triggerPolicyName="$1"
	policyTrigger2Run="$2"
	FNgetID "scripts" "00-UEX-Deploy-via-Trigger.sh"
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
    <parameter4>Trigger names separated by semi-colon</parameter4>
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

##########################################################################################
# 								Script Starts Here										 #
##########################################################################################


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
	fn_createAgentPolicy "00-uexblockagent-jss.sh" "uexblockagent"
	fn_createAgentPolicy "00-uexlogoutagent-jss.sh" "uexlogoutagent"
	fn_createAgentPolicy "00-uexrestartagent-jss.sh" "uexrestartagent"
	fn_createAgentPolicy "00-uex_inventory_update_agent-jss.sh" "uex_inventory_update_agent"
	fn_createAgentPolicy "00-uexdeferralservice-jss.sh" "uexdeferralservice"
	fn_createAgentPolicy "00-PleaseWaitUpdater-jss.sh" "PleaseWaitUpdater"


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


##########################################################################################
exit 0
