cls
Install-Module -Name AzureResourceInventory -Force
Import-Module AzureResourceInventory

# Get enabled subscriptions and build array
$subs = az account list --all --query "[?state=='Enabled'].{Name:name, ID:id}" -o json | ConvertFrom-Json
$ids = $subs | ForEach-Object { $_.ID }

$arrayLines = @()
$arrayLines += '$ids = @('
foreach ($sub in $subs) {
    # Each line: 'ID' # Name
    $arrayLines += "    '$($sub.ID)' # $($sub.Name)"
}
$arrayLines += ')'

$arrayLines | Out-File -FilePath $HOME/AzureResourceInventory/subscriptions.txt -Encoding utf8

# Limit to 8 subscriptions if needed
if ($ids.Count -gt 8) {
    Write-Warning "More than 8 subscriptions detected! ARI in cloud shell supports a maximum of 8. Only the first 8 will be used."
    $idsToUse = $ids[0..7]
} else {
    $idsToUse = $ids
}

Invoke-ARI -SubscriptionID $idsToUse -IncludeTags

Write-Host "Subscription list saved to: $HOME/AzureResourceInventory/subscriptions.txt"