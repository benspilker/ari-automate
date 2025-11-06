cls
Write-Host "Installing AzureResourceInventory PowerShell Module"
Install-Module -Name AzureResourceInventory -Force
Import-Module AzureResourceInventory

$ariFolder = Join-Path $HOME "AzureResourceInventory"

if (-not (Test-Path $ariFolder)) {
    Write-Host "Creating folder: $ariFolder"
    New-Item -Path $ariFolder -ItemType Directory | Out-Null
}

# Get enabled subscriptions and build array
Write-Host "Retrieving enabled subscriptions..."
$subs = az account list --all --query "[?state=='Enabled'].{Name:name, ID:id}" -o json | ConvertFrom-Json
$ids = $subs | ForEach-Object { $_.ID }

# Build subscriptions.txt content
$arrayLines = @()
$arrayLines += "Install-Module -Name AzureResourceInventory"
$arrayLines += "Import-Module AzureResourceInventory"
$arrayLines += ""
$arrayLines += '$ids = @('

foreach ($sub in $subs) {
    $arrayLines += "    '$($sub.ID)' # $($sub.Name)"
}

$arrayLines += ')'
$arrayLines += ""
$arrayLines += "Invoke-ARI -SubscriptionID \$ids -IncludeTags"

$outFile = Join-Path $ariFolder "subscriptions.txt"
$arrayLines | Out-File -FilePath $outFile -Encoding utf8

Write-Host ""
Write-Host "Subscription list saved to: $outFile" -ForegroundColor Green
Write-Host ""

Write-Host "Enabled Subscriptions Detected:" -ForegroundColor Cyan
foreach ($sub in $subs) {
    Write-Host (" - " + $sub.ID + "  [" + $sub.Name + "]")
}

sleep 3

Set-Location -Path $ariFolder
Write-Host "Changed directory to: $(Get-Location)" -ForegroundColor Yellow

# Limit to 8 subscriptions if needed
if ($ids.Count -gt 8) {
    Write-Warning "More than 8 subscriptions detected! ARI in Cloud Shell supports a maximum of 8. Only the first 8 will be used."
    $idsToUse = $ids[0..7]
} else {
    $idsToUse = $ids
}

Write-Host "Running Azure Resource Inventory..." -ForegroundColor Cyan
Invoke-ARI -SubscriptionID $idsToUse -IncludeTags