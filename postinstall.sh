#!/bin/bash

###################################################################################################
# Script Name:  postinstall.sh
# By:  Zack Thompson / Created:  11/20/2017
# Version:  0.1 / Updated:  11/20/2017 / By:  ZT
#
# Description:  This script loads the LaunchDaemon.
#
###################################################################################################

# Define the Variables
	launchDaemonLabel="com.github.mlbz521.jamfMigrator"
	launchDaemonLocation="/Library/LaunchDaemons/${launchDaemonLabel}.plist"

# Load the LaunchDaemon
	/bin/launchctl bootstrap system $launchDaemonLocation
	/bin/launchctl enable system/$launchDaemonLabel

exit 0