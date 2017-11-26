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
	unManageComputer="com.github.mlbz521.UnmanageComputer"
	unmanageLaunchDaemon="/Library/LaunchDaemons/${unManageComputer}.plist"

# Load the LaunchDaemon
	/bin/launchctl bootstrap system $unmanageLaunchDaemon
	/bin/launchctl enable system/$unManageComputer

exit 0