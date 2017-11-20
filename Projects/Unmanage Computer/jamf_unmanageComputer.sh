#!/bin/bash

###################################################################################################
# Script Name:  jamf_unmanageComputer.sh
# By:  Zack Thompson / Created:  11/17/2017
# Version:  0.3 / Updated:  11/20/2017 / By:  ZT
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

	function exitStatus {
		if [ $1 != "0" ]; then
			echo "Failed at step:  ${2}"
			exit $1
		fi
	}

	function tearDown {
		# Unload LaunchDaemon
			/bin/launchctl unload /Library/LaunchDaemons/com.github.mlbz521.UnmanageComputer.plist
				# Function exitStatus
					exitStatus $? "Unloading LaunchDaemon"
		# Remove LaunchDaemon
			/bin/rm -f /Library/LaunchDaemons/com.github.mlbz521.UnmanageComputer.plist
				# Function exitStatus
					exitStatus $? "Deleting LaunchDaemon"
		# Delete Self
			/bin/rm -f "$0"
				# Function exitStatus
					exitStatus $? "Deleting Script"
	}

##################################################
# Now that we have our work setup... 

# Submit unamange payload to the JSS
/usr/bin/curl -sfkuf "${jamfAPIUser}:${jamfAPIPassword}" "${jamfURL}/${getUUID}" -T $unmanagePayload -X PUT
	# Function exitStatus
		exitStatus $? "Sending API Payload to Unmanage Computer"

# Pause for a moment to get a response back from the JSS...
	# sleep 5

# Remove JAMF Binary
	/usr/local/bin/jamf removeFramework
		# Function exitStatus
			exitStatus $? "Removing Framework"

# Enroll machine
	/usr/sbin/installer -dumplog -verbose -pkg $enrollPkg -allowUntrusted -target /
		# Function exitStatus
			exitStatus $? "Sending API Payload to Unmanage Computer"

# Function tearDown
	tearDown

exit 0

