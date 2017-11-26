#!/bin/bash

###################################################################################################
# Script Name:  postinstall.sh
# By:  Zack Thompson / Created:  11/20/2017
# Version:  1.0 / Updated:  11/21/2017 / By:  ZT
#
# Description:  This script stages files and loads a LaunchDaemon.
#
###################################################################################################

# Define the Variables
	pkgDir=$(/usr/bin/dirname $0)
	launchDaemonLabel="com.github.mlbz521.jamfMigrator"
	osVersion=$(sw_vers -productVersion | /usr/bin/awk -F '.' '{print $2}')
	launchDaemonLocation="/Library/LaunchDaemons/${launchDaemonLabel}.plist"

# Stages the bits
	cp "${pkgDir}/${launchDaemonLabel}.plist" $launchDaemonLocation
	cp -R "${pkgDir}/jamfMigrator.sh" /private/var/tmp/
	cp -R "${pkgDir}/QuickAdd.pkg" /private/var/tmp/

# Determine proper launchctl syntax based on OS Version 
	if [[ ${osVersion} -ge 11 ]]; then
		/bin/launchctl bootstrap system $launchDaemonLocation
		/bin/launchctl enable system/$launchDaemonLabel
	elif [[ ${osVersion} -le 10 ]]; then
		/bin/launchctl load $launchDaemonLocation
	fi

exit 0
