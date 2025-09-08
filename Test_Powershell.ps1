$Server = "ilsdtapp01t.test.lab"
$Username = "Testlab\ADMagenticaiPOC"
$Password = ConvertTo-SecureString "Welcome@Teva@2025" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)

try {
    Write-Host "Testing connection to $Server"
    Test-NetConnection -ComputerName $Server -Port 135
    
    Write-Host "Connecting to SCCM WMI namespace"
    $SccmNamespace = Get-WmiObject -Namespace "root\SMS" -Class "SMS_ProviderLocation" -ComputerName $Server -Credential $Credential
    
    if ($SccmNamespace) {
        $SiteCode = $SccmNamespace.SiteCode
        Write-Host "Found SCCM site: $SiteCode"
        
        $Collections = Get-WmiObject -Namespace "root\SMS\site_$SiteCode" -Class "SMS_Collection" -ComputerName $Server -Credential $Credential
        Write-Host "Found $($Collections.Count) collections"
    }
}
catch {
    Write-Error "Connection failed: $($_.Exception.Message)"
}
