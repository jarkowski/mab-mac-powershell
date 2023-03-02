## mab-mac-powershell
**PowerShell script to add add MAC address users to Active Directory for use with RADIUS MAB**

This script takes care of adding special purpose "MAC users" to the active directory. A mac user is used for RADIUS MAC address bypass (MAB). A switch reports a MAC address seen to the RADIUS server, which then asks the Active Directory for a user matching that MAC address. Depending on the group membership of the user, a VLAN can be assigned etc.

To make this possible, a large ammount of "fake" user accounts need to be created. These users should never log in to any service on any computer. Their only purpose is to tell the RADIUS server that a MAC address is allowed, and what kind of device this MAC belongs to.

There are specific steps needed to create a correct MAC user, hence this script:

- 
