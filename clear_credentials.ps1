# =========================================
# Problem 3: Clear Outlook Credentials (Specific User)
# =========================================

param (
    [string]$TargetUser = "vicky_admin"   # 👈 Change username here if needed
)

Write-Output "🔎 Searching for stored Outlook/Office credentials in Credential Manager for user: $TargetUser"

# Build path to user's Credential Manager files
$userProfile = (Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like "*$TargetUser" }).LocalPath

if (-not $userProfile) {
    Write-Output "❌ Could not find profile path for $TargetUser"
    exit 1
}

$credFolder = Join-Path $userProfile "AppData\Roaming\Microsoft\Credentials"

if (-not (Test-Path $credFolder)) {
    Write-Output "✅ No credential store found for $TargetUser"
    exit 0
}

Write-Output "📂 Found Credential Manager store at: $credFolder"
Write-Output "⚠️ Note: Credentials are DPAPI-protected and can only be read/removed as that user."

# --- SAFE MODE: Just list matching credentials ---
$files = Get-ChildItem $credFolder -Force -ErrorAction SilentlyContinue

if (-not $files) {
    Write-Output "✅ No stored credentials found."
}
else {
    Write-Output "⚠️ Credential blob files detected:"
    $files | ForEach-Object { Write-Output " - $($_.FullName)" }

    # --- DESTRUCTIVE OPTION: Uncomment to delete files ---
    <#
    foreach ($file in $files) {
        try {
            Remove-Item $file.FullName -Force
            Write-Output "🗑️ Deleted credential file: $($file.FullName)"
        }
        catch {
            Write-Output "❌ Failed to remove $($file.FullName): $_"
        }
    }
    #>
}
 