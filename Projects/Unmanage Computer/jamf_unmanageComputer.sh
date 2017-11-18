#!/bin/bash

###################################################################################################
# Script Name:  jamf_unmanageComputer.sh
# By:  Zack Thompson / Created:  11/17/2017
# Version:  0.2 / Updated:  11/17/2017 / By:  ZT
#
# Description:  This script uses the Jamf API to mark the device as unmanaged.
#
###################################################################################################

/bin/echo "Starting unmanage script..."

##################################################
# Define Variables
	jamfAPIUser="APIUsername"
	jamfAPIPassword="APIPassword"
	jamfURL="https://jss.company.com:8443/JSSResource/computers/udid/"
	getUUID=$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice | /usr/bin/awk '/IOPlatformUUID/ { split($0, line, "\""); printf("%s\n", line[4]); }')
	unmanagePayload="/private/tmp/unmanage_UUID.xml"
	enrollPkg="/private/var/tmp/QuickAdd.pkg"

# Stage the "unmanage" PUT payload
/bin/echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<computer>
<general>
<remote_management>
<managed>false</managed>
</remote_management>
</general>
</computer>" > $unmanagePayload

##################################################
# Setup Functions

	function tearDown {
	# Remove JAMF Binary
		/usr/local/bin/jamf removeFramework
	# Unload LaunchDaemon
		/bin/launchctl unload //Library/LaunchDaemons/com.github.mlbz521.UnmanageComputer.plist
	# Remove LaunchDaemon
		/bin/rm -f /Library/LaunchDaemons/com.github.mlbz521.UnmanageComputer.plist
	# Delete Self
		/bin/rm -f "$0"
	}

##################################################
# Now that we have our work setup... 

# Submit unamange payload to the JSS
/usr/bin/curl -sfkuf "${jamfAPIUser}:${jamfAPIPassword}" "${jamfURL}/${getUUID}" -T $unmanagePayload -X PUT
exitCode = $?
if [ $exitCode != "0" ]; then
	echo "FAILED"
else
	# Pause for a moment to get a response back from the JSS...
		# /bin/sleep 5
	# Function tearDown
		tearDown
	# Enroll machine
		/usr/sbin/installer -dumplog -verbose -pkg $enrollPkg -allowUntrusted -target /

	exit 0
fi
