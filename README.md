# Azure Resource Inventory (Cloud Shell Script)

This PowerShell script collects enabled subscriptions in your tenant and runs **Azure Resource Inventory (ARI)** for up to 8 subscriptions. 
It is designed to be run **directly in Azure Cloud Shell**.

---

## Quick Start

1. Open **Azure Cloud Shell** in your tenant and ensure that it is in powershell
2. Copy and paste the contents of the script to run it.

## NOTE 
You will get the following error when running due to a cloud shell limitation 

    "WARNING: ImportExcel Module Cannot Autosize. Please run the following command to install dependencies: apt-get -y update && apt-get install -y --no-install-recommends libgdiplus libc6-dev"

This is normal. The excel file won't have perfect formatting and auto-fitting because of this limitation, but will still get the job done enough. It does look much better when running Invoke-ARI on your local machine but this is not possible with CSP customers.

---

## Usage

1. Open **Azure Cloud Shell** in your tenant.
2. Copy the script into the shell or upload it as a `.ps1` file.
3. There are 2 versions of the script to run. The simplified version is ARI-powershell-csp.ps1 and the more advanced version is ARI-powershell-csp-prod-nonprod.ps1.
    ```powershell
    .\ARI-powershell-csp.ps1
    ```
4. Note, the script can only query up to 8 subscriptions at a time, otherwise Invoke-ARI crashes in the cloud shell. ARI-powershell-csp.ps1 will only query the first 8 subcriptions listed. 
For larger customers who have more than 8 subscriptions, consider using ARI-powershell-csp-prod-nonprod.ps1 which currently filters out non-prod subcriptions and only queries prod.
5. Check the `$HOME/subscriptions.txt` file for the formatted subscription list.
6. Inventory data will be collected automatically via `Invoke-ARI`.
7. Download files to your local computer. Manage Files, Download a File, Enter the path
    For example /home/presidio
    AzureResourceInventory/AzureResourceInventory_Report_2025-11-02_03_10.xlsx