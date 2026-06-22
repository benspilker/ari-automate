cls

Write-Host "Installing AzureResourceInventory PowerShell Module"
Install-Module -Name AzureResourceInventory -Force
Import-Module AzureResourceInventory

$ariFolder = Join-Path $HOME "AzureResourceInventory"

if (-not (Test-Path $ariFolder)) {
    Write-Host "Creating folder: $ariFolder"
    New-Item -Path $ariFolder -ItemType Directory | Out-Null
}

Write-Host "Retrieving enabled subscriptions..." -ForegroundColor Cyan

$subs = az account list --all --query "[?state=='Enabled'].{Name:name, ID:id}" -o json | ConvertFrom-Json

if (-not $subs) {
    Write-Error "No enabled subscriptions found."
    exit
}

Write-Host ""
Write-Host "Available Subscriptions:" -ForegroundColor Yellow

for ($i = 0; $i -lt $subs.Count; $i++) {
    Write-Host ("[{0}] {1}" -f ($i + 1), $subs[$i].Name)
    Write-Host ("     {0}" -f $subs[$i].ID) -ForegroundColor DarkGray
}

Write-Host ""
$selection = Read-Host "Enter subscription number(s) separated by commas, or type 'all'"

if ($selection -eq "all") {
    $selectedSubs = $subs
}
else {
    try {
        $indexes = $selection.Split(',') |
            ForEach-Object { ([int]$_.Trim()) - 1 }

        $selectedSubs = foreach ($index in $indexes) {
            if ($index -ge 0 -and $index -lt $subs.Count) {
                $subs[$index]
            }
        }

        if (-not $selectedSubs) {
            throw "No valid subscriptions selected."
        }
    }
    catch {
        Write-Error "Invalid selection."
        exit
    }
}

$idsToUse = $selectedSubs.ID

Write-Host ""
Write-Host "Selected Subscriptions:" -ForegroundColor Green
$selectedSubs | ForEach-Object {
    Write-Host " - $($_.Name)"
}

# Build subscriptions.txt content
$arrayLines = @()
$arrayLines += "Install-Module -Name AzureResourceInventory"
$arrayLines += "Import-Module AzureResourceInventory"
$arrayLines += ""
$arrayLines += '$ids = @('

foreach ($sub in $selectedSubs) {
    $arrayLines += "    '$($sub.ID)' # $($sub.Name)"
}

$arrayLines += ')'
$arrayLines += ""
$arrayLines += 'Invoke-ARI -SubscriptionID $ids -IncludeTags'

$outFile = Join-Path $ariFolder "subscriptions.txt"
$arrayLines | Out-File -FilePath $outFile -Encoding utf8

Write-Host ""
Write-Host "Subscription list saved to: $outFile" -ForegroundColor Green

Set-Location -Path $ariFolder
Write-Host "Changed directory to: $(Get-Location)" -ForegroundColor Yellow

if ($idsToUse.Count -gt 8) {
    Write-Warning "More than 8 subscriptions selected. ARI in Cloud Shell supports a maximum of 8. Only the first 8 will be used."
    $idsToUse = $idsToUse[0..7]
}

Write-Host ""
Write-Host "Running Azure Resource Inventory..." -ForegroundColor Cyan
Invoke-ARI -SubscriptionID $idsToUse -Lite