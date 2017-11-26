#!/bin/bash

###################################################################################################
# Script Name:  jamfMigrator.sh
# By:  Zack Thompson / Created:  11/17/2017
# Version:  0.5 / Updated:  11/21/2017 / By:  ZT
#
# Description:  This script uses the Jamf API to mark the device as unmanaged, remove the current Jamf Framework, then install a new QuickAdd package, and finally cleanup after itself.
#
###################################################################################################

/usr/bin/logger -s "*****  jssMigrator process:  START  *****"

##################################################
# Define Variables
	newJSS="https://newjss.company.com:8443"
	oldJSS="https://oldjss.company.com.edu:8443"
	jamfAPIUser="APIUsername"
	jamfAPIPassword="APIPassword"
	jamfURL="${oldJSS}/JSSResource/computers/udid/"
	jamfBinary="/usr/local/bin/jamf"
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
		if [[ -e $jamfBinary ]]; then
			/usr/bin/logger -s "Checking if current JSS instance is available..."
			checkAvailablity=$(${jamfBinary} checkJSSConnection)
				# Function exitStatus
					exitStatus $? "${1} is unavailable at this time.  Suspending until next interval..."

			if [[ $checkAvailablity == *"${1}"* ]]; then
				# If the check contains the JSS we're expecting...
				if [[ $checkAvailablity != *"The JSS is available"* ]]; then
					# If the JSS is unavailable, suspend further processing...
					/usr/bin/logger -s "${1} is unavailable at this time.  Suspending until next interval..."
					exit 1
				else
					# If the JSS is available, then continue...
					/usr/bin/logger -s "${1} is available, continuing..."
				fi
			elif [[ $checkAvailablity == *"${oldJSS}"* ]]; then
				# If the check is the oldJSS when we're expecting the newJSS, something went wrong, suspend further processing... 
				/usr/bin/logger -s "Failed -- still pointing to the old JSS Server...  Suspending until next interval..."
				exit 1
			elif [[ $checkAvailablity == *"${newJSS}"* ]]; then
				# This elif is for, if somehow on the first checkJSSConnection run, it's connected to the new JSS, then we're good to go.
				/usr/bin/logger -s "Connected to the new JSS instance!"
				exit 0
				/usr/bin/logger -s "*****  jssMigrator process:  COMPLETE  *****"
			fi
		else
			/usr/bin/logger -s "Unable to run \`jamf checkJSSConnection\`"
			/usr/bin/logger -s "Assuming Jamf Framework has been removed..."
			# Function enrollMachine
				enrollMachine
		fi
	}

	function enrollMachine {
		# Enroll machine
			/usr/bin/logger -s "Installing QuickAdd package"
			/usr/sbin/installer -dumplog -verbose -pkg $enrollPkg -allowUntrusted -target /
				# Function exitStatus
					exitStatus $?
	}

	function tearDown {
		# Unload LaunchDaemon
			/usr/bin/logger -s "Unloading LaunchDaemon"
			/bin/launchctl unload $launchDaemonLocation
				# Function exitStatus
					exitStatus $?

		# Remove LaunchDaemon
			/usr/bin/logger -s "Deleting LaunchDaemon"
			/bin/rm -f $launchDaemonLocation
				# Function exitStatus
					exitStatus $?

		# Delete QuickAdd Package
			/usr/bin/logger -s "Deleting QuickAdd Package"
			/bin/rm -f $enrollPkg
				# Function exitStatus
					exitStatus $?

		# Delete Self
			/usr/bin/logger -s "Deleting Script"
			/bin/rm -f "$0"
				# Function exitStatus
					exitStatus $?
	}

	function exitStatus {
		if [[ $1 != "0" ]]; then
			/usr/bin/logger -s " -> Failed"
				if [[ -e $2 ]]; then
					/usr/bin/logger -s "Error:  ${2}"
				fi
				exit 1
		else
			/usr/bin/logger -s " -> Success!"
		fi
	}

##################################################
# Now that we have our work setup... 

# Function checkJSSConnection
	checkJSSConnection $oldJSS

# Submit unamange payload to the JSS (add -k, --insecure to disabled SSL verification)
	/usr/bin/logger -s "Sending API Payload to Unmanage Computer"
	/usr/bin/curl --silent --show-error --fail --user "${jamfAPIUser}:${jamfAPIPassword}" "${jamfURL}/${getUUID}" --header "Content-Type: text/xml" --upload-file $unmanagePayload --request PUT
		# Function exitStatus
		exitStatus $?

# Remove JAMF Binary
	/usr/bin/logger -s "Removing Framework"
	$jamfBinary removeFramework
		# Function exitStatus
			exitStatus $?

# Function enrollMachine
	enrollMachine

# Function checkJSSConnection
	checkJSSConnection $newJSS

# Function tearDown
	tearDown

/usr/bin/logger -s "*****  jssMigrator process:  COMPLETE  *****"

exit 0
