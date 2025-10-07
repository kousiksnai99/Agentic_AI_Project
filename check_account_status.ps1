# ================================
# Script: Account Status + SCCM Integration
# ================================

$ScriptName = "TestingScript"
$ComputerName = "Client3"
$ProviderMachineName = "sccm2.intunelab.com"
$SiteCode = "PRI"

# Connect to SCCM Site if not already connected
if ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    Write-Output "🔗 Connecting to SCCM site: $ProviderMachineName ($SiteCode)"
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName
} else {
    Write-Output "✅ Already connected to SCCM site: $SiteCode"
}

# Extract username from path
$safePath = "C:\Users\vicky_admin\AppData\Local\Microsoft\WindowsApps\Microsoft.OutlookForWindows_8wekyb3d8bbwe"
$userName = ($safePath -split '\\')[2]   # e.g., "vicky_admin"

try {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue

    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        # Domain / AD check
        $user = Get-ADUser -Identity $userName -Properties LockedOut, PasswordExpired, PasswordLastSet, AccountExpirationDate

        Write-Output "🔎 Checking domain account: $userName"
        Write-Output "Locked Out: $($user.LockedOut)"
        Write-Output "Password Expired: $($user.PasswordExpired)"
        Write-Output "Password Last Set: $($user.PasswordLastSet)"
        Write-Output "Account Expiration Date: $($user.AccountExpirationDate)"
    }
    else {
        # Local account fallback
        Write-Output "ℹ️ ActiveDirectory module not available. Checking LOCAL account: $userName"
        $user = Get-LocalUser -Name $userName
        Write-Output "Account Enabled: $($user.Enabled)"

        # Parse `net user` output properly
        $netInfo = net user $userName

        $lastSet   = ($netInfo | Select-String "Password last set").ToString() -replace ".*Password last set\s+",""
        $expires   = ($netInfo | Select-String "Password expires").ToString() -replace ".*Password expires\s+",""

        Write-Output "Password Last Set: $lastSet"
        Write-Output "Password Expires: $expires"

        if ($expires -match "Never") {
            Write-Output "✅ Password does not expire."
        }
        else {
            $expiryDate = [datetime]::Parse($expires)
            $daysLeft   = ($expiryDate - (Get-Date)).Days
            Write-Output "⚠️ Password will expire on: $expiryDate ($daysLeft days remaining)"
        }
    }
}
catch {
    Write-Output "❌ Error checking account status: $_"
}
