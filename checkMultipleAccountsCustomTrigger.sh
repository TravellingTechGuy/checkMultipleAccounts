#!/bin/bash

#######################################################################################################################
# Disclaimer 
# This script is provided AS IS and is a work in progress
# No support will be provided
# No liability will result from using this script, use at your own discretion after validating and testing
#######################################################################################################################

# 1st of October 2020 - Travelling Tech Guy
# Version 1.0 - Custom Trigger Version
# https://travellingtechguy.blog

##########################################################################################################################
# What are we trying to solve here?
# ---------------------------------
# Users with administrator rights on macOS are able to create additional local accounts.
# MDM restrictions to the Users & Groups section of the System Preferences does not block users from using command line.
# Knowing that there will always be ways to work around it with admin privileges and power user knowledge, 
# I want to create a script which checks if there is more than 1 local (or mobile) end user account.
# This script can be used by a LaunchDeamon to call a custom Jamf Pro policy if needed, or populate an Extension Attribute
##########################################################################################################################

##########################################################################################################################
# What is the script doing?
# -------------------------
# I've come across multiple scripts to check local accounts on the Mac, however, they always check based on UID.
# Most scripts I've come across check for UID above 500 to exclude service/system accounts.
# The problem is that power user could change the UID of the account they created in System Preferences, or even
# create the account entirely via command line, and give it a lower UID to bypass detection.
# Jamf Pro also only reports local accounts with UID above 500 in the device inventory.
#
# In this script I'm trying to built another logic based on checking attributes via 'dscl'
#
# I hereby make the following assumptions:
# 1) With the exception of _mbsetupuser (?) only local end user accounts have the dsAttrTypeNative:_writers_passwd attribute
# 2) End user accounts have a NFSHomeDirectory attribute which is not "/var/empty"
# 
# I'm assuming that combining the 2 criteria above gives me only local accounts created by the end user (or mobile accounts).
#
# The script uses dscl to check for the multiple accounts, excludes a set of predefined accounts, like the managed admin, 
# and if more than one account is found it calls a custom policy trigger to Jamf.
##########################################################################################################################

############################# CONFIGURATION ################################
# add the accounts you want to exclude in the check in the array below

# accounts to exclude - add accounts separated by a space in the array below
excludedAccounts=(jamfadmin anotheradmin anotheraccount)

# custom Jamf Pro Policy trigger
customTrigger="lockDevice"

############################################################################

listWriterspasswd=()
listHomeDir=()
localAccounts=()

echo "#######################################################################"
echo " "

echo "Found the following accounts with 'dsAttrTypeNative:_writers_passwd':"
for writersPasswd in $(dscl . list /Users dsAttrTypeNative:_writers_passwd | awk '{ print $2 }'); do

	listWritersPasswd+=("$writersPasswd")
	
done

echo ${listWritersPasswd[@]}
echo " "

echo "Found the following accounts with homedir:"

for writersPasswdAccount in ${listWritersPasswd[@]}; do
		
		if [[ $(dscl . read /Users/$writersPasswdAccount NFSHomeDirectory | awk '{ print $2 }') != "/var/empty" ]]; then
		
		#echo $writersPasswdAccount
		
		listHomeDir+=("${writersPasswdAccount}")

		fi
	
done

echo ${listHomeDir[@]}
echo " "

echo "Excluding accounts: _mbsetupuser ${excludedAccounts[@]}"

for del in ${excludedAccounts[@]}
do
	listHomeDir=("${listHomeDir[@]/$del}")
	localAccounts=(${listHomeDir[@]})
done

#excluding _mbsetupuser

	localAccounts=("${localAccounts[@]/"_mbsetupuser"}")
	localAccounts=(${localAccounts[@]})

	numberOfAccounts=${#localAccounts[@]}


if [ $numberOfAccounts -gt 1 ]
then
echo " "
echo "Multiple End User Accounts Found: ${localAccounts[@]}"
echo "Number of accounts: ${#localAccounts[@]}"

echo " "
echo "Executing Jamf Pro Custom Trigger"

jamf policy -event $customTrigger

else
	
echo " "
echo "No additional End User Accounts Found"
echo "Number of accounts: ${#localAccounts[@]}"
echo "End user: ${localAccounts[@]}"

fi

echo " "
echo "#######################################################################"
echo " "
