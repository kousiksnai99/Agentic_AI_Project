# =========================================

# Problem 1: Create OST Profile

# =========================================
 
param(

    [string]$ProfileName = "DiagOSTProfile"  # <-- Change this to any profile name

)
 
# Outlook executable registry paths (useful if later we need to launch Outlook)

$regPaths = @(

    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE",

    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE"

)
 
# Outlook profile registry path

$profileRoot = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles"

$newProfilePath = Join-Path $profileRoot $ProfileName
 
try {

    # Ensure Outlook Profiles root exists

    if (-not (Test-Path $profileRoot)) {

        Write-Output "No Outlook profile registry path found. Creating root..."

        New-Item -Path "HKCU:\Software\Microsoft\Office\16.0\Outlook" -Name "Profiles" -Force | Out-Null

    }
 
    # Create new profile if it doesn't exist

    if (-not (Test-Path $newProfilePath)) {

        New-Item -Path $profileRoot -Name $ProfileName -Force | Out-Null

        Write-Output "✅ Profile '$ProfileName' created in registry."

    } else {

        Write-Output "ℹ️ Profile '$ProfileName' already exists."

    }
 
    # List all profiles for confirmation

    $profiles = Get-ChildItem $profileRoot | Select-Object -ExpandProperty PSChildName

    Write-Output "📋 Existing Outlook profiles: $($profiles -join ', ')"
 
    Write-Output "👉 To generate OST, launch Outlook interactively with: outlook.exe /profile $ProfileName"

}

catch {

    Write-Output "❌ Error creating OST profile: $_"

}

 