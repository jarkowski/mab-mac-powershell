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
    $delete = Read-Host "User already exists. Do you want to delete it? (Y/N)"
    if ($delete -eq "Y") {
        Remove-ADUser -Identity $existingUser -Confirm:$false
        Write-Host "User deleted"
    } else {
        Write-Host "User not deleted"
    }
} else {
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
        Path = $mabUserOU
    }
    Write-Host "UserParams set."

    try {
        $newUser = New-ADUser @userParams -ErrorAction Stop
    } catch {
        Write-Host "Error creating user: $_"
        exit 1
    }
    Write-Host "User creation done."

    # Set password to match username
    Write-Host "This is the password that will be used: $mac"
    $newPassword = (ConvertTo-SecureString -String $mac -AsPlainText -Force)
    Set-ADAccountPassword -Identity $mac -NewPassword (ConvertTo-SecureString -String $mac -AsPlainText -Force) -Reset
    
    # Add user to MAB-Deny-Logon group
    Add-ADGroupMember -Identity $mabDenyLogonGroup -Members $mac
    
    # Make this the primary group (otherwise the original primary group can't be deleted)

    $group = Get-ADGroup $mabDenyLogonGroup -Properties PrimaryGroupToken
    $primaryGroupToken = $group.PrimaryGroupToken
    Write-Host "The Token of group $mabDenyLogonGroup is $primaryGroupToken"
    Set-aduser -identity $mac -Replace @{PrimaryGroupID=$primaryGroupToken}

    # Check for success
    $user = Get-ADUser -Identity $mac -Properties PrimaryGroupID
    Write-Host "The users primary group ID is $user.PrimaryGroupID"
    if ($user.PrimaryGroupID -eq $primaryGroupToken) {
    Write-Host "OK, primary group is set correctly."
    } 
    else {
    Write-Host "Error: PrimaryGroup does not match, stopping"
    Exit
    }

}
