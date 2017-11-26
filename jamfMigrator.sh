#!/bin/bash

###################################################################################################
# Script Name:  jamfMigrator.sh
# By:  Zack Thompson / Created:  11/17/2017
# Version:  0.4 / Updated:  11/20/2017 / By:  ZT
#
# Description:  This script uses the Jamf API to mark the device as unmanaged, remove the current Jamf Framework, then install a new QuickAdd package, and finally cleanup after itself.
#
###################################################################################################

/bin/echo "Starting jamfMigrator script..."

##################################################
# Define Variables
	newJSS="https://newjss.company.com:8443"
	oldJSS="https://oldjss.company.com.edu:8443"
	jamfAPIUser="APIUsername"
	jamfAPIPassword="APIPassword"
	jamfURL="${oldJSS}/JSSResource/computers/udid/"
	getUUID=$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice | /usr/bin/awk '/IOPlatformUUID/ { split($0, line, "\""); printf("%s\n", line[4]); }')
	unmanagePayload="/private/tmp/unmanage_UUID.xml"
	launchDaemonLabel="com.github.mlbz521.jamfMigrator"
	launchDaemonLocation="/Library/LaunchDaemons/${launchDaemonLabel}.plist"
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

	function checkJSSConnection {
		checkAvailablity=$(/usr/local/bin/jamf checkJSSConnection)
			# Function exitStatus
				exitStatus $? "Unable to run \`jamf checkJSSConnection\`"

		if [[ $checkAvailablity == *"${1}"* ]]; then
			if ![[ $checkAvailablity == *"The JSS is available"* ]]; then
				/bin/echo "${1} is unavailable at this time.  Suspending until next interval..."
				exit 1
			else
				/bin/echo "${1} is available, continuing..."
			fi
		elif [[ $checkAvailablity == $oldJSS ]]; then
			/bin/echo "Failed -- still pointing to the old JSS Server...  Suspending until next interval..."
			exit 1
		fi

	}

	function exitStatus {
		if [[ $1 != "0" ]]; then
			/bin/echo "Failed at stage:  ${2}"
			exit $1
		fi
	}

	function tearDown {
		# Unload LaunchDaemon
			/bin/launchctl unload $launchDaemonLocation
				# Function exitStatus
					exitStatus $? "Unloading LaunchDaemon"

		# Remove LaunchDaemon
			/bin/rm -f $launchDaemonLocation
				# Function exitStatus
					exitStatus $? "Deleting LaunchDaemon"

		# Delete QuickAdd Package
			/bin/rm -f $enrollPkg
				# Function exitStatus
					exitStatus $? "Deleting LaunchDaemon"

		# Delete Self
			/bin/rm -f "$0"
				# Function exitStatus
					exitStatus $? "Deleting Script"
	}

##################################################
# Now that we have our work setup... 

# Function checkJSSConnection
	checkJSSConnection $oldJSS

# Submit unamange payload to the JSS
/usr/bin/curl -sfkuf "${jamfAPIUser}:${jamfAPIPassword}" "${jamfURL}/${getUUID}" -T $unmanagePayload -X PUT
	# Function exitStatus
		exitStatus $? "Sending API Payload to Unmanage Computer"

# Pause for a moment to get a response back from the JSS...
	# /bin/sleep 5

# Remove JAMF Binary
	/usr/local/bin/jamf removeFramework
		# Function exitStatus
			exitStatus $? "Removing Framework"

# Enroll machine
	/usr/sbin/installer -dumplog -verbose -pkg $enrollPkg -allowUntrusted -target /
		# Function exitStatus
			exitStatus $? "Sending API Payload to Unmanage Computer"

# Function checkJSSConnection
	checkJSSConnection $newJSS


# Function tearDown
	tearDown

exit 0

