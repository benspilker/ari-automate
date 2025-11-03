cls
Install-Module -Name AzureResourceInventory -Force
Import-Module AzureResourceInventory

# Get enabled subscriptions and build array
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
    $omittedLines | Out-File -FilePath "$HOME/AzureResourceInventory/omitted-subscriptions.txt" -Encoding utf8
    Write-Host "`nOmitted non-production subscriptions saved to: $HOME/AzureResourceInventory/omitted-subscriptions.txt" -ForegroundColor Yellow
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
$arrayLines | Out-File -FilePath "$HOME/AzureResourceInventory/subscriptions.txt" -Encoding utf8

# Extract IDs for Invoke-ARI
$idsToUse = $subsToLookup.ID

Invoke-ARI -SubscriptionID $idsToUse -IncludeTags

Write-Host "`nSubscription list saved to: $HOME/AzureResourceInventory/subscriptions.txt"
if ($omittedSubs.Count -gt 0) {
    Write-Host "Omitted subscriptions saved to: $HOME/AzureResourceInventory/omitted-subscriptions.txt"
}
