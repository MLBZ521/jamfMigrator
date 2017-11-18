#!/bin/bash

###################################################################################################
# Script Name:  jamf_unmanageComputer.sh
# By:  Zack Thompson / Created:  11/17/2017
# Version:  0.1 / Updated:  11/17/2017 / By:  ZT
#
# Description:  This script uses the Jamf API to mark the device as unmanaged.
#
###################################################################################################

# Define the Variables
jamfAPIUser="APIUsername"
jamfAPIPassword="APIPassword"
jamfURL="https://jss.company.com:8443/JSSResource/computers/udid/"
getUUID=$(ioreg -rd1 -c IOPlatformExpertDevice | awk '/IOPlatformUUID/ { split($0, line, "\""); printf("%s\n", line[4]); }')
unmanagePayload="/private/tmp/unmanage_UUID.xml"
enrollPkg="/private/var/tmp/QuickAdd.pkg"


# Stage the "unmanage" PUT payload
echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<computer>
<general>
<remote_management>
<managed>false</managed>
</remote_management>
</general>
</computer>" > $unmanagePayload

# Submit unamange payload to the JSS
curl -sfkuf "${jamfAPIUser}:${jamfAPIPassword}" "${jamfURL}/${getUUID}" -T $unmanagePayload -X PUT
exitCode = $?
if [ $exitCode != "0" ]; then
	echo "FAILED"
else
	# Pause for a moment to get a response back from the JSS...
		# /bin/sleep 5

	# Start tearing down...

	# Remove JAMF Binary
		jamf removeFramework

	# Unload LaunchDaemon
		/bin/launchctl unload /Library/LaunchDaemons/com.github.mlbz521.UnmanageComputer.plist

	# Remove LaunchDaemon
		/bin/rm -f /Library/LaunchDaemons/com.github.mlbz521.UnmanageComputer.plist

	# Delete Self
		/bin/rm -f "$0"

	# Enroll machine
		/usr/sbin/installer -dumplog -verbose -pkg $enrollPkg -allowUntrusted -target /

	exit 0
fi
