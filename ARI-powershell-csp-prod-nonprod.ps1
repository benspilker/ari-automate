cls
Write-Host "Installing AzureResourceInventory Powershell Module"
Install-Module -Name AzureResourceInventory -Force
Import-Module AzureResourceInventory

# Define output folder
$ariFolder = Join-Path $HOME "AzureResourceInventory"

# Ensure the folder exists
if (-not (Test-Path $ariFolder)) {
    Write-Host "Creating folder: $ariFolder"
    New-Item -Path $ariFolder -ItemType Directory | Out-Null
}

# Get enabled subscriptions and build array
Write-Host "Retrieving enabled subscriptions..."
$subs = az account list --all --query "[?state=='Enabled'].{Name:name, ID:id}" -o json | ConvertFrom-Json

# Define non-production keywords (case-insensitive)
$nonProdPatterns = @('test', 'dev', 'qa', 'qua', 'nonprod', 'non-prod')

# Separate subscriptions into prod and omitted
$omittedSubs = @()
$prodSubs = @()

foreach ($sub in $subs) {
    $isNonProd = $false
    foreach ($pattern in $nonProdPatterns) {
        if ($sub.Name -match $pattern) {
            $isNonProd = $true
            break
        }
    }

    if ($isNonProd) {
        $omittedSubs += $sub
    } else {
        $prodSubs += $sub
    }
}

$totalCount = $subs.Count

# Write omitted subscriptions file (for visibility)
if ($omittedSubs.Count -gt 0) {
    $omittedLines = @('$omittedSubs = @(')
    foreach ($sub in $omittedSubs) {
        $omittedLines += "    '$($sub.ID)' # $($sub.Name)"
    }
    $omittedLines += ')'

    $omittedFile = Join-Path $ariFolder "omitted-subscriptions.txt"
    $omittedLines | Out-File -FilePath $omittedFile -Encoding utf8
    Write-Host "`nOmitted non-production subscriptions saved to: $omittedFile" -ForegroundColor Yellow
} else {
    Write-Host "`nNo non-production subscriptions found to omit." -ForegroundColor Green
}

# Determine which subscriptions to lookup
if ($totalCount -le 8) {
    Write-Host "`n8 or fewer subscriptions detected — including prod and non-prod in report." -ForegroundColor Cyan
    $subsToLookup = $subs
} else {
    Write-Host "`nMore than 8 subscriptions detected — omitting non-prod and limiting to first 8 prod subs." -ForegroundColor Cyan

    if ($prodSubs.Count -eq 0) {
        Write-Warning "No production subscriptions found! Defaulting to first 8 overall."
        $subsToLookup = $subs[0..7]
    } elseif ($prodSubs.Count -le 8) {
        $subsToLookup = $prodSubs
    } else {
        $subsToLookup = $prodSubs[0..7]
    }
}

# Build and save subscriptions.txt
$arrayLines = @('$ids = @(')
foreach ($sub in $subsToLookup) {
    $arrayLines += "    '$($sub.ID)' # $($sub.Name)"
}
$arrayLines += ')'

$subsFile = Join-Path $ariFolder "subscriptions.txt"
$arrayLines | Out-File -FilePath $subsFile -Encoding utf8

# Display the subscriptions that will be used
Write-Host "`nSubscriptions included in the ARI run:" -ForegroundColor Cyan
foreach ($sub in $subsToLookup) {
    Write-Host (" - " + $sub.ID + "  [" + $sub.Name + "]")
}
Write-Host ""

# Change directory to the folder
Set-Location -Path $ariFolder
Write-Host "Changed directory to: $(Get-Location)" -ForegroundColor Yellow
Write-Host ""

# Extract IDs for Invoke-ARI
$idsToUse = $subsToLookup.ID

# Run Azure Resource Inventory
Write-Host "Running Azure Resource Inventory..." -ForegroundColor Cyan
Invoke-ARI -SubscriptionID $idsToUse -IncludeTags

# Summary output
Write-Host "`nSubscription list saved to: $subsFile" -ForegroundColor Green
if ($omittedSubs.Count -gt 0) {
    Write-Host "Omitted subscriptions saved to: $omittedFile" -ForegroundColor Yellow
}
