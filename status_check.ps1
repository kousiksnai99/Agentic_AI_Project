# =========================================
# Problem 2 (SCCM-Safe): Check Outlook Work Offline Registry Status
# =========================================

try {
    $officeRoot = "HKCU:\Software\Microsoft\Office"
    $versionKey = (Get-ChildItem $officeRoot -ErrorAction SilentlyContinue |
                   Where-Object { $_.PSChildName -match '^(15\.0|16\.0)$' } |
                   Sort-Object PSChildName -Descending | Select-Object -First 1).PSChildName

    if (-not $versionKey) {
        Write-Output "❌ Could not detect Outlook version (15.0/16.0)."
        exit 1
    }

    $offlineKey = "HKCU:\Software\Microsoft\Office\$versionKey\Outlook\RPC"
    $workOffline = (Get-ItemProperty -Path $offlineKey -ErrorAction SilentlyContinue).Offline

    if ($null -eq $workOffline) {
        Write-Output "⚠️ Outlook Offline flag not found — Outlook may not have been launched yet."
    }
    elseif ($workOffline -eq 1) {
        Write-Output "🚫 Outlook is set to **Work Offline** mode (registry flag = 1)."
    }
    else {
        Write-Output "🌐 Outlook is set to **Online Mode** (registry flag = 0)."
    }
}
catch {
    Write-Output "❌ Error reading Outlook registry status: $_"
}
