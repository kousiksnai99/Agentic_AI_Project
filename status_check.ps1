# =========================================
# Problem 2 (Enhanced): Check Outlook Online/Offline Status
# =========================================

param(
    [string]$ProfileName = "DiagOSTProfile"  # <-- Change if needed
)

try {
    # Detect installed Outlook version dynamically
    $officeRoot = "HKCU:\Software\Microsoft\Office"
    $versionKey = (Get-ChildItem $officeRoot -ErrorAction SilentlyContinue | 
                  Where-Object { $_.PSChildName -match '^(15\.0|16\.0)$' } |
                  Sort-Object PSChildName -Descending | Select-Object -First 1).PSChildName

    if (-not $versionKey) {
        Write-Output "❌ Could not detect Outlook version (15.0/16.0)."
        exit 1
    }

    $profileRoot = "HKCU:\Software\Microsoft\Office\$versionKey\Outlook\Profiles"
    $newProfilePath = Join-Path $profileRoot $ProfileName

    if (-not (Test-Path $newProfilePath)) {
        Write-Output "⚠️ Outlook profile '$ProfileName' not found under version $versionKey."
        Write-Output "Existing profiles:"
        Get-ChildItem $profileRoot -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSChildName
        exit 1
    }

    Write-Output "🔍 Searching registry for ConnectMode under profile '$ProfileName'..."

    # Recursively search for ConnectMode key
    $connectKeys = Get-ChildItem -Path $newProfilePath -Recurse -ErrorAction SilentlyContinue |
                   ForEach-Object {
                       try {
                           Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue |
                           Select-Object PSPath, ConnectMode
                       } catch {}
                   } | Where-Object { $_.ConnectMode -ne $null }

    if ($connectKeys.Count -eq 0) {
        Write-Output "⚠️ Could not find any ConnectMode value for profile '$ProfileName'."
        Write-Output "Tip: Open Outlook once using this profile to initialize connection settings."
        exit 0
    }

    # Show status for each ConnectMode found
    foreach ($key in $connectKeys) {
        $mode = $key.ConnectMode
        switch ($mode) {
            0 { $status = "🌐 Online Mode" }
            1 { $status = "🗂️ Cached (Online with OST)" }
            2 { $status = "🚫 Offline Mode" }
            default { $status = "❓ Unknown Mode ($mode)" }
        }
        Write-Output "✅ Found ConnectMode = $mode → $status (Path: $($key.PSPath))"
    }
}
catch {
    Write-Output "❌ Error checking Outlook mode: $_"
}
