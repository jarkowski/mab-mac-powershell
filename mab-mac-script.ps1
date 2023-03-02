# Clear screen

Clear-Host

# Get config from file

$config = Get-Content ".\config.cfg" | ConvertFrom-StringData
$domain = $config.domain
$radiusOU = $config.radiusOU
$groupsOU = $config.groupsOU
$mabUserOU = $config.mabUserOU
$mabDenyLogonGroup = $config.mabDenyLogonGroup


# Get MAC address from user input and format it

    Write-Host " "
    Write-Host "Provide a MAC address in any format you like"
    Write-Host "Special charcters - and : will be removed"
    Write-Host "All letters will be converted to upper case letters"
    Write-Host " "

do {

    $mac = Read-Host "Please enter MAC address"
    $mac = $mac.Replace("-", "").Replace(":", "").Trim().ToUpper()
    if ($mac -match "^[0-9A-F]{12}$") {
        break
    } else {
        Write-Host "Invalid MAC address. Please try again."
    }
} while ($true)

# Check if MAC user already exists

$existingUser = Get-ADUser -Filter {Name -like $mac} -SearchBase $mabUserOU -ErrorAction SilentlyContinue
if ($existingUser) {
    # User already exists
    $delete = Read-Host "$mac already exists. Do you want to delete the user object from active directory? (Y/N)"
    if ($delete -eq "Y") {
        Remove-ADUser -Identity $existingUser -Confirm:$false
        Write-Host "User deleted from active directory"
    } else {
        Write-Host "User not deleted - No changes made."
    }
} 

else {
    
    
    # Clear screen

Clear-Host

# Get config from file

$config = Get-Content ".\config.cfg" | ConvertFrom-StringData
$domain = $config.domain
$radiusOU = $config.radiusOU
$groupsOU = $config.groupsOU
$mabUserOU = $config.mabUserOU
$mabDenyLogonGroup = $config.mabDenyLogonGroup




# Check for available OUs below mabUserOU
try {
$mabSubOUs = Get-ADOrganizationalUnit -SearchScope OneLevel -SearchBase "$mabUserOU" -Filter * | Select-Object Name, DistinguishedName
} catch {
Write-Host "Can't list child OUs."
Exit 1
}




if ($mabSubOUs) {
    # Prompt user to select an OU to create the new user in
    Write-Host "The following sub OUs are available under $mabUserOU "
    $mabSubOUs | Format-Table -AutoSize
    do {
        $selectedOU = Read-Host "Please enter the name of the sub OU to create the new user in"
        if ($selectedOU -in $mabSubOUs.Name) {
            $targetOU = "OU=" + $selectedOU + "," + $mabUserOU
            break
        } else {
            Write-Host "Invalid selection. Please try again."
        }
    } while ($true)
} else {
    # No child OUs found under mabUserOU, exit script
    Write-Host "No child OUs found under $mabUserOU. Exiting script."
    Exit
}

Write-Host "This is the OU that will be used: "
Write-Host $targetOU
        
    # User does not exist, create new user
    Write-Host "Creating new user for MAC address $mac"
    
    # Generate random password
    $password = ConvertTo-SecureString -String (New-Guid) -AsPlainText -Force
    
    # Create new user with random password
    $userParams = @{
        Name = $mac
        SamAccountName = $mac
        UserPrincipalName = $mac + "@" + $domain
        AccountPassword = $password
        PasswordNeverExpires = $true
        PasswordNotRequired = $false
        CannotChangePassword = $true
        AllowReversiblePasswordEncryption = $true
        Enabled = $true
        Path = $targetOU
    }
    Write-Host "UserParams set."

    try {
        $newUser = New-ADUser @userParams -ErrorAction Stop
    } catch {
        Write-Host "Error creating user: $_"
        exit 1
    }
    Write-Host "User creation done."

 
    
    # Add user to MAB-Deny-Logon group
    Add-ADGroupMember -Identity $mabDenyLogonGroup -Members $mac
    
    # Make this the primary group (otherwise the original primary group can't be deleted)

    $group = Get-ADGroup $mabDenyLogonGroup -Properties PrimaryGroupToken
    $primaryGroupToken = $group.PrimaryGroupToken
    Write-Host "The Token of group $mabDenyLogonGroup is $primaryGroupToken"
    Set-aduser -identity $mac -Replace @{PrimaryGroupID=$primaryGroupToken}

    # Check for success. If the primary group is not set to the DenyLogonGroup,
    # the script must stop BEFORE setting the password to match the username.
    $user = Get-ADUser -Identity $mac -Properties PrimaryGroupID
    $id = $user.PrimaryGroupID 
    Write-Host "The users primary group ID is $id." 
    if ($user.PrimaryGroupID -eq $primaryGroupToken) {
    Write-Host "OK, primary group is set correctly."
    } 
    else {
    Write-Host "Error: PrimaryGroup does not match, stopping"
    Exit
    }

    # Set password to match username

    Write-Host "Setting matching mpassword to: $mac"
    $newPassword = (ConvertTo-SecureString -String $mac -AsPlainText -Force)
    Set-ADAccountPassword -Identity $mac -NewPassword (ConvertTo-SecureString -String $mac -AsPlainText -Force) -Reset
}
Write-Host "End of script"
