# jamfMigrator
This project assists with migrating from one JSS to another JSS.  I will describe the setup process and logic of the script below.

I've added an additional workflow to this project to include some kind of option for 'migrating' FileVault keys to the new JSS.

The overall scope of this project is to:
  * Mark the computer in the old Jamf environment as “unmanaged” – so you can easily track what has, and has not, migrated
  * Remove the old Jamf Framework – which removes the main MDM Profile and all traces of Jamf related Config Profiles, MDM certs, etc
  * Join computer to the new Jamf environment in a clean state
  * Reissue a new FileVault Personal Recovery Key (requires a known FileVault Unlock Key)

In my testing, the overall process took, from policy execution to the script completing, roughly one minute and fifteen seconds.

**Inspired by several discussions on JamfNation:**
* https://www.jamf.com/jamf-nation/discussions/10866/un-manage-and-keep-in-inventory
* https://www.jamf.com/jamf-nation/discussions/10456/remove-framework-after-imaging
* And several other threads I've read regarding Jamf managed state recovery methods (See:  rtrouton's CasperCheck)

#### WorkFlow ####

![Flow Chart](https://github.com/MLBZ521/jamfMigrator/blob/master/jamfMigrator.png "JamfMigrator Flow Chart")

## Setup ##

Edit the `jamfMigrator.sh` script and modify the following values:
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
  * If using Packages, add the `postinstall.sh` script as the Post-installation script and all other files into Scripts > Additional Resources

Grab the `reissue_FileVaultPRK.sh` script [here](https://github.com/MLBZ521/macOS.JAMF/blob/master/Scripts/reissue_FileVaultPRK.sh)

Upload these items:
  * `jamfMigrator.pkg` to the old JSS
  * `reissue_FileVaultPRK.sh` to the new JSS

Create the following Policies:
  * In the Old JSS
    * *(If needed)* Policy to Create a FileVault Enabled User.  [Example](https://github.com/MLBZ521/jamfMigrator/blob/master/Create%20FV_enabled%20User.png)
    * Policy to deploy the `jamfMigrator.pkg` Package
  * In the New JSS
    * Policy with the `reissue_FileVaultPRK.sh` with a known FileVault Unlock Key.  [Example](https://github.com/MLBZ521/jamfMigrator/blob/master/FV2%20Reissue%20Script.png)


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


#### reissue_FileVaultPRK.sh ####

This script issues a new FileVault Personal Recovery Key.  It will require a known FileVault Unlock Key, which can be one of the following:
  * A FileVault Enable Account with a known password
  * Current FileVault Personal Recovery Key

Obviously, the easiest and most 'scopable' way to do this to have a FileVault Enabled Account.  If you do not have a known FileVault Enable Account with a known password, then on ≤10.12, you can easily create one via Jamf before migrating to the new JSS.  (Jamf cannot create a FV_Enabled account on 10.13+ machines currently.)  

Add the script to a Policy in the new JSS and enter the known Unlock Key in the Script Parameter.

After migrating and after this policy successfully runs (i.e. the new JSS has a **valid** FileVault Recovery Key) the account can be FV disabled or deleted.
