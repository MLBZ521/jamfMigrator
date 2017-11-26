# jamfMigrator
This project assists with migrating from one JSS to another JSS.  I will describe the setup process and logic of the script below.

The overall scope of this project is to:
  * Mark the computer in the old Jamf environment as “unmanaged” – so you can easily track what has, and has not, migrated
  * Remove the old Jamf Framework – which removes the main MDM Profile and all traces of Jamf related Config Profiles, MDM certs, etc
  * Join computer to the new Jamf environment in a clean state

In my testing, the overall process took, from policy execution to the script completing, roughly one minute and fifteen seconds.

## Setup ##

* Edit the `jamfMigrator.sh` script and modify the following values:
  * `newJSS`
  * `oldJSS`
  * `jamfAPIUser`
  * `jamfAPIPassword`
  * If you change the LaunchDaemon file and Label names, you'll need to update those in all files as well
  * If your JSS has a self signed cert, you may need to add `-k` (`--insecure`) to the `curl` command to disable SSL verification

API Permissions I needed were:
  * JSS Objects > Update > 
    * Computers
    * Users

Create a payload-free package with all three files and a QuickAdd package created for the new JSS instance
  * If using `munkipkg`, add all files into the scripts folder
  * If using Packages, add the `postinstall.sh` script as the Post-installtion script and all other files into Scripts > Additional Resources


## Logic ##

#### jamfMigrator.sh ####

This script does the heavy lifting.

  * Checks if it can contact the old JSS (uses `jamf checkJSSConnection`)
    * If successful, continues
    * If an unsuccessful attempt to connect to the old JSS, quit and try again on the next interval
  * Sends a generated xml file to the old JSS, via the API, to mark the machine as unmanaged
    * The UUID is grabbed from the machine to associate it to its' Jamf Record
  * Jamf Framework is removed
  * QuickAdd package for the new JSS is installed
  * Checks if it can contact the new JSS (uses `jamf checkJSSConnection`)
    * If successful, continues
    * If unsuccessful
      * If still attempting to connect to the old JSS, quit and try again on the next interval
      * If it attempts to connect to the new JSS, but fails, quit and try again on the next interval
  * Begins 'tearDown' -- cleans up all staged bits

After virtually every action, the Exit Code (`$?`) is checked to see if it was successful; if it isn't, the script exists and will be launched again at the next interval.

Logs each process step to `system.log`


#### com.github.mlbz521.jamfMigrator.plist ####

This is the LaunchDaemon that staged and loaded by the `postinstall.sh` script. 

 * On load, the LaunchDaemon will execute the `jamfMigrator.sh script` as a child process
 * If the script fails, the LaunchDaemon will launch again in ten minutes


#### postinstall.sh ####

This script stages the bits to do the work.  You can use it with any payload-free pkg creation method (munkipkg, Packages, etc).

* On install of the payload-free package, it will stage the bits:
  * `cp com.github.mlbz521.jamfMigrator.plist /Library/LaunchDaemons/`
  * `cp jamfMigrator.sh /private/var/tmp/`
  * `cp QuickAdd.pkg /private/var/tmp/`

* And then load the LaunchDaemon based on the OS Version
  * if >= 10.11
    * `/bin/launchctl bootstrap system $launchDaemonLocation`
    * `/bin/launchctl enable system/$launchDaemonLabel`
  * if <= 10.10
    * `/bin/launchctl load $launchDaemonLocation`
