# =========================================
# Problem 2 (SCCM Ready): Outlook Online/Offline Mode (Auto-launch + Close)
# =========================================

try {
    $outlook = $null
    $startedOutlook = $false

    # Try to get Outlook if it's already running
    try {
        $outlook = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application")
    } catch {}

    # If Outlook not running, start it silently
    if (-not $outlook) {
        Write-Output "ℹ️ Outlook not running — launching in background..."
        Start-Process "outlook.exe" -WindowStyle Hidden
        Start-Sleep -Seconds 8  # give time to initialize
        $outlook = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application")
        $startedOutlook = $true
    }

    if (-not $outlook) {
        Write-Output "❌ Could not start or connect to Outlook COM instance."
        exit 1
    }

    $namespace = $outlook.GetNamespace("MAPI")

    if ($namespace.Offline) {
        Write-Output "🚫 Outlook is currently in **Offline Mode**."
    } else {
        Write-Output "🌐 Outlook is **Online and Connected** to the mail server."
    }

    # Cleanly quit Outlook if we started it
    if ($startedOutlook) {
        Write-Output "🛑 Closing Outlook (auto-started instance)..."
        $outlook.Quit()
    }
}
catch {
    Write-Output "❌ Error checking Outlook mode: $_"
}
 
