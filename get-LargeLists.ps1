 $siteUrl = "https://<Tenant>-admin.sharepoint.com/"
 $creds = Get-Credential

 Connect-SPOService -url $siteUrl -Credential $creds

 $sites= Get-SPOSite -Limit ALL

$FoundLists = @{}

foreach($site in $sites)
{

    Connect-PnPOnline -Url $site.Url -UseWebLogin #-Credentials $creds
    Write-Host $site.Url
    $pnpsite = Get-PnpSite -ErrorAction Ignore
    $lists = Get-PnPList
    foreach($list in $lists)
    {
        if($list.ItemCount -gt 5000)
        {
            Write-Host "Large List"
            $FoundLists.Add($list.Path)
        }
    }
    Disconnect-PnPOnline
}

$FoundLists | Export-Csv C:\Temp\LargeLists.csv