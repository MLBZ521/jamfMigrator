#!/bin/bash

###################################################################################################
# Script Name:  postinstall.sh
# By:  Zack Thompson / Created:  11/20/2017
# Version:  0.2 / Updated:  11/21/2017 / By:  ZT
#
# Description:  This script stages files and loads a LaunchDaemon.
#
###################################################################################################

# Define the Variables
	pkgDir=$(/usr/bin/dirname $0)
	launchDaemonLabel="com.github.mlbz521.jamfMigrator"
	launchDaemonLocation="/Library/LaunchDaemons/${launchDaemonLabel}.plist"

# Stages the bits
	cp "${pkgDir}/${launchDaemonLabel}.plist" $launchDaemonLocation
	cp -R "${pkgDir}/jamfMigrator.sh" /private/var/tmp/
	cp -R "${pkgDir}/QuickAdd.pkg" /private/var/tmp/

# Load the LaunchDaemon
	/bin/launchctl bootstrap system $launchDaemonLocation
	/bin/launchctl enable system/$launchDaemonLabel

exit 0
