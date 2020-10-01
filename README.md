# checkMultipleAccounts

Report multiple end user account on the system and take action.


1st of October 2020 - Travelling Tech Guy
Version 1.0
https://travellingtechguy.blog


### Disclaimer ###

This script is provided AS-IS, no liability or support. Please use it at you own discretion after  reviewing and testing it.

Work in progress and proof of concept. The assumptions mentioned below in the method to check the user accounts are still under evaluation.


# What am I trying to solve here?

Users with administrator rights on macOS are able to create additional local accounts and MDM restrictions to lock the Users & Groups section of the System Preferences does not block users from using command line.

Knowing that there will always be ways to work around it with admin privileges and power user knowledge, I wanted to create a script which checks if there is more than 1 local (or mobile) end user account.

This script can be used in a Jamf Pro policy at recurring check-in, or with a LaunchDaemon, to call a custom Jamf Pro policy if needed.  I also added some variants to populate an Extension Attribute.

# What is the script doing?

I've come across multiple scripts to check local accounts on the Mac, however, they always check accounts based on UID or group membership. Most scripts I've come across check for UID above 500 to exclude service/system accounts, or monitor the admin group.

The problem is that power user could change the UID of an additional account they created in System Preferences, or even create the account entirely via command line, and give it a lower UID to bypass detection.

Jamf Pro also only reports local accounts with UID above 500 in the device inventory.

In this script I'm trying to built another logic based on checking attributes via ‘dscl’.

I hereby make the following assumptions:

Local end user accounts most likely have the dsAttrTypeNative:_writers_passwd attribute
System/service account do not have the dsAttrTypeNative:_writers_passwd
End user accounts have a NFSHomeDirectory attribute which is not "/var/empty"

I'm assuming that processing the 3 criteria above, after querying the system with ‘dscl’, gives me only local accounts created by the end user (or mobile accounts).

The script uses ‘dscl’ to check all accounts on the system, excludes a set of predefined accounts, like the managed admin you created via Jamf Pro, and if more than one account is found it calls a custom policy trigger in Jamf Pro.


# How to use it?

I’ve created the 3 following scripts:

Check Multiple Accounts Custom Trigger
Check Multiple Accounts Extension Attribute
Check Multiple Accounts Extension Attribute Number

The ‘Check Multiple Accounts Custom Trigger’ script is the one which you can add to a Jamf Pro Policy or deploy with a LaunchDaemon. The only configuration in the script need is:

 - Add the accounts you want to exclude in the check to the excludedAccounts, separated with a space:

excludedAccounts=(jamfadmin anotheradmin anotheraccount)

- Define the custom Jamf Pro Policy trigger you want the script to call if multiple end user accounts are reported:

customTrigger="lockDevice"


The ‘Check Multiple Accounts Extension Attribute’ and ‘Check Multiple Accounts Extension Attribute Number’  script only need the excluded accounts to be configured. Upload them to a script based Extension Attribute in Jamf Pro.


