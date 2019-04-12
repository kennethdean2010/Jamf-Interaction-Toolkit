#!/bin/bash
# set -x
jssGroupname="$4"
# jssGroupname="User Needs Help Clearing Disk Space"

# HIGHLY RECCOMEDED TO USE Encrypted-Script-Parameters
# Please check out the Encrypted-Script-Parameters Repo from jamfIT on GitHub
# https://github.com/jamfit/Encrypted-Script-Parameters
jss_url="$5"
jss_userEncrptyed="$6"
jss_passEncrptyed="$7"

# for testing
# jss_url="https://cubandave.local:8443"
# jss_userEncrptyed="U2FsdGVkX1/yDQNBhlSHn1I316TBLP9XAoQ5qBbBodE="
# jss_passEncrptyed="U2FsdGVkX1/yDQNBhlSHn65nLo71IAWNgCZ8Eae3DWY="

# DONT FORGET TO UPDATE THE SALT & PASS PHRASE
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String"
    local SALT=""
    local K=""

    # for testing
    # local SALT="f20d03418654879f"
    # local K="1761bd1ea2ccce4268c74629"
    echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "$SALT" -k "$K"
}

jss_user=$(DecryptString "$jss_userEncrptyed")
jss_pass=$(DecryptString "$jss_passEncrptyed")


computersUDID=$(system_profiler SPHardwareDataType | awk '/UUID/ { print $3; }')
# computersUDID="CA984439-6E47-5D44-B52D-C855768AC39B"
# echo computersUDID is $computersUDID

CURL_OPTIONS="--location --insecure --silent --show-error --connect-timeout 30"

groupNameIDLookup=`curl ${CURL_OPTIONS} --header "Accept: application/xml" --request "GET" --user $jss_user:$jss_pass "$jss_url/JSSResource/computergroups" | xmllint --format - | grep -B 1 '>'"$jssGroupname"'<' | /usr/bin/awk -F'<id>|</id>' '{print $2}' | sed '/^\s*$/d'`

computerIDLookup=`curl ${CURL_OPTIONS} --header "Accept:application/xml" --request "GET" --user $jss_user:$jss_pass $jss_url/JSSResource/computers/udid/$computersUDID | xpath "/computer[1]/general/id/text()" 2>/dev/null`

GROUPXML="<computer_group><computer_additions>
<computer>
<id>$computerIDLookup</id>
</computer>
</computer_additions>
</computer_group>"

# echo $GROUPXML

if [[ -z "$groupNameIDLookup" ]]; then
	#statements
	echo "groupNameIDLookup came back blank the group $jssGroupname may not exist"
	exit 1
fi

if [[ -z "$computerIDLookup" ]]; then
	#statements
	echo "computerIDLookup came back blank the computer $computersUDID may not exist"
	exit 1
fi

# echo groupNameIDLookup is $groupNameIDLookup
# echo computerIDLookup is $computerIDLookup

computerinGroup=`curl ${CURL_OPTIONS} --header "Accept:application/xml" --request "GET" --user $jss_user:$jss_pass $jss_url/JSSResource/computergroups/id/$groupNameIDLookup | grep "<id>$computerIDLookup</id>"`

if [[ "$computerinGroup" ]]; then
	echo "computer '$computerIDLookup' already in the group '$jssGroupname'"
	exit 0
else
	echo "Attempting to upload changes to group '$jssGroupname'"
	curl -s -k -u $jss_user:$jss_pass $jss_url/JSSResource/computergroups/id/$groupNameIDLookup -X PUT -H Content-type:application/xml --data "$GROUPXML"
fi

computerinGroup=`curl ${CURL_OPTIONS} --header "Accept:application/xml" --request "GET" --user $jss_user:$jss_pass $jss_url/JSSResource/computergroups/id/$groupNameIDLookup | grep "<id>$computerIDLookup</id>"`


if [ "$computerinGroup" ] ; then
	echo "comptuer '$computerIDLookup' successfully added to group '$jssGroupname'"
	exit 0
else
	echo "unable to add computer '$computerIDLookup' to group '$jssGroupname'"
	exit 1
fi
