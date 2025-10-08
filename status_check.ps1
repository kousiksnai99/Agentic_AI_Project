# =========================================
# Problem 2 (Final Reliable): Check Outlook Online/Offline Status
# =========================================

try {
    # Try to get Outlook COM object (if Outlook is running)
    $outlook = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application") -ErrorAction SilentlyContinue

    if (-not $outlook) {
        Write-Output "⚠️ Outlook is not currently running. Please open Outlook and try again."
        exit 1
    }

    # Get the namespace object (MAPI)
    $namespace = $outlook.GetNamespace("MAPI")

    # Check if Outlook is offline
    if ($namespace.Offline) {
        Write-Output "🚫 Outlook is currently in **Offline Mode**."
    }
    else {
        # Try to detect account connection states (for multiple mailboxes)
        $stores = $namespace.Stores
        $connectedCount = 0
        $disconnectedCount = 0

        foreach ($store in $stores) {
            try {
                if ($store.IsDataFileStore -eq $false) {
                    if ($store.ExchangeStoreType -ne $null) {
                        if ($store.Connected) { $connectedCount++ } else { $disconnectedCount++ }
                    }
                }
            } catch {}
        }

        if ($connectedCount -gt 0 -and $disconnectedCount -eq 0) {
            Write-Output "🌐 Outlook is **Online and Connected** to the mail server."
        }
        elseif ($connectedCount -gt 0 -and $disconnectedCount -gt 0) {
            Write-Output "⚠️ Outlook has **some accounts online and some offline.**"
        }
        else {
            Write-Output "⚠️ Outlook appears **Disconnected** from the mail server."
        }
    }
}
catch {
    Write-Output "❌ Error checking Outlook status: $_"
}
