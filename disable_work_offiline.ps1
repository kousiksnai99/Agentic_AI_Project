# ================================
# Script: Disable Work Offline in Outlook + SCCM Integration
# ================================

$ScriptName = "DisableWorkOfflineScript"
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

function Get-OutlookPath {
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE"
    )

    foreach ($regPath in $regPaths) {
        try {
            $outlookPath = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).'(Default)'
            if ($outlookPath -and (Test-Path $outlookPath)) {
                return $outlookPath
            }
        } catch {}
    }

    $possiblePaths = @(
        "$env:ProgramFiles\Microsoft Office\root\Office16\OUTLOOK.EXE",
        "$env:ProgramFiles (x86)\Microsoft Office\root\Office16\OUTLOOK.EXE",
        "$env:ProgramFiles\Microsoft Office\Office16\OUTLOOK.EXE",
        "$env:ProgramFiles (x86)\Microsoft Office\Office16\OUTLOOK.EXE",
        "C:\Users\vicky_admin\AppData\Local\Microsoft\WindowsApps\Microsoft.OutlookForWindows_8wekyb3d8bbwe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) { return $path }
    }

    return $null
}

# Registry path where "Work Offline" state is stored
$workOfflineKey = "HKCU:\Software\Microsoft\Office\16.0\Outlook\RPC"
$workOfflineValue = "Offline"

# Check if registry key exists
if (Test-Path $workOfflineKey) {
    $offlineState = (Get-ItemProperty -Path $workOfflineKey -Name $workOfflineValue -ErrorAction SilentlyContinue).$workOfflineValue

    if ($offlineState -eq 1) {
        Write-Output "⚠️ Outlook is currently set to Work Offline."
        try {
            Set-ItemProperty -Path $workOfflineKey -Name $workOfflineValue -Value 0
            Write-Output "✅ Work Offline has been disabled."
        }
        catch {
            Write-Output "❌ Failed to update Work Offline setting: $_"
        }
    }
    else {
        Write-Output "✅ Outlook is already Online (Work Offline not set)."
    }
}
else {
    Write-Output "ℹ️ No Work Offline setting found in registry."
}

# Attempt to restart Outlook (optional)
$outlookPath = Get-OutlookPath
if ($outlookPath) {
    Write-Output "🔄 Restarting Outlook to apply changes..."
    Stop-Process -Name OUTLOOK -ErrorAction SilentlyContinue
    Start-Process -FilePath $outlookPath
    Write-Output "✅ Outlook restarted in Online mode."
}
else {
    Write-Output "❌ Outlook executable not found. Please check installation."
}
