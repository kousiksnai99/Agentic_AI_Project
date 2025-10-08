# =========================================
# Problem 2: Check Outlook Online/Offline Status
# =========================================

param(
    [string]$ProfileName = "DiagOSTProfile"  # <-- Change if needed
)

# Outlook profile registry base path
$profileRoot = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles"
$newProfilePath = Join-Path $profileRoot $ProfileName

try {
    # Verify if the Outlook profile exists
    if (-not (Test-Path $newProfilePath)) {
        Write-Output "⚠️ Outlook profile '$ProfileName' not found in registry."
        Write-Output "Please ensure Outlook profile exists before checking online/offline status."
        exit 1
    }

    # Path to the "Connect Mode" registry key which stores online/offline status
    # Mode:
    #   0x00000000 = Online Mode
    #   0x00000001 = Cached Exchange Mode (OST - online with cache)
    #   0x00000002 = Offline Mode
    #
    # Registry path can differ slightly, but “9375CFF0413111d3B88A00104B2A6676” is the Accounts container for Outlook profiles
    $accountsPath = Join-Path $newProfilePath "9375CFF0413111d3B88A00104B2A6676"

    if (-not (Test-Path $accountsPath)) {
        Write-Output "⚠️ No account settings found under profile '$ProfileName'."
        exit 1
    }

    # Find the actual account subkey
    $accountKeys = Get-ChildItem -Path $accountsPath
    $foundMode = $false

    foreach ($key in $accountKeys) {
        $fullKey = $key.PSPath
        $connectMode = (Get-ItemProperty -Path $fullKey -ErrorAction SilentlyContinue).ConnectMode

        if ($null -ne $connectMode) {
            $foundMode = $true
            switch ($connectMode) {
                0 { Write-Output "🌐 Outlook is in **Online Mode**." }
                1 { Write-Output "🗂️ Outlook is in **Cached (Online with OST)** mode." }
                2 { Write-Output "🚫 Outlook is in **Offline Mode**." }
                default { Write-Output "❓ Unknown ConnectMode value: $connectMode" }
            }
        }
    }

    if (-not $foundMode) {
        Write-Output "⚠️ Could not determine ConnectMode for profile '$ProfileName'."
    }

}
catch {
    Write-Output "❌ Error checking Outlook mode: $_"
}
