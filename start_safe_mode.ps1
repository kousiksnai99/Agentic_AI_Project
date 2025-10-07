
# ================================
# Script: Start Outlook in Safe Mode + SCCM Integration
# ================================

$ScriptName = "StartOutlookSafeMode"
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
        "$env:ProgramFiles\Microsoft Office
oot\Office16\OUTLOOK.EXE",
        "$env:ProgramFiles (x86)\Microsoft Office
oot\Office16\OUTLOOK.EXE",
        "$env:ProgramFiles\Microsoft Office\Office16\OUTLOOK.EXE",
        "$env:ProgramFiles (x86)\Microsoft Office\Office16\OUTLOOK.EXE"
    )
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

$outlookPath = Get-OutlookPath

if (-not $outlookPath) {
    Write-Host "❌ Outlook executable not found. Please check your installation." -ForegroundColor Red
    exit 1
}

# Start Outlook in Safe Mode
Start-Process -FilePath $outlookPath -ArgumentList "/safe"
Write-Host "✅ Outlook is starting in Safe Mode..." -ForegroundColor Green
