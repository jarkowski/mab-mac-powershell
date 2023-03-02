## mab-mac-powershell
**PowerShell script to add add MAC address users to Active Directory for use with RADIUS MAB**

This script takes care of adding special purpose "MAC users" to the active directory. A mac user is used for RADIUS MAC address bypass (MAB). A switch reports a MAC address seen to the RADIUS server, which then asks the Active Directory for a user matching that MAC address. Depending on the group membership of the user, a VLAN can be assigned etc.

To make this possible, a large ammount of "fake" user accounts need to be created. These users should never log in to any service on any computer. Their only purpose is to tell the RADIUS server that a MAC address is allowed, and what kind of device this MAC belongs to.

There are specific steps needed to create a correct MAC user, hence this script.
When executed, the script will:

- Pull configuration from the config.cfg file
- Ask user for a MAC, format the MAC (all uppper case, no extra chars)
- Check if a user with this MAC is existing, give option to delete it if it exists
- If no user for this MAC exists, ask the user which device type this MAC belongs to. For every device type, both an OU and a group with the same name should exist. A list of possible device types is diplayed, based on available child OUs. One must be selected.
- The script will now create a user with a random password.
- The user will be added to a "Deny logon group", defined in config.cfg
- The deny logon group will be set to be the primary group
- If the primary group is set successfull, the password is set to match the user name
- A description can now be given, which will be added to the AD user object (i.e. John Doe - Macbook air - Asset ID 12345)
- All other groups memberships (ie. Domain users) will be removed from the user object
- The user object is added to the group matching it's OU (i.e. for device type "Printer", the user object will be created in OU Printer and added to group Printer


